package server

import (
	"context"
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"

	"showdown/internal/protocol"
)

// userSocketLimit is how many devices one profile may hold open at once.
// A phone, a laptop and a spare tab is three; beyond that the oldest goes.
const userSocketLimit = 4

// userHub keeps the open user sockets, keyed by profile. It is the only
// way the server reaches a person rather than a seat: a friend request is
// about the player, not about the table they happen to be sitting at.
type userHub struct {
	mu    sync.Mutex
	conns map[string][]*wsConn
}

func newUserHub() *userHub { return &userHub{conns: map[string][]*wsConn{}} }

func (h *userHub) add(accountID string, c *wsConn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	list := append(h.conns[accountID], c)
	// Oldest first: the ones over the limit are dropped, not refused, so a
	// reconnecting device never finds itself locked out by its own ghost.
	for len(list) > userSocketLimit {
		list[0].Close(protocol.CloseReplaced, "too many connections")
		list = list[1:]
	}
	h.conns[accountID] = list
}

func (h *userHub) remove(accountID string, c *wsConn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	list := h.conns[accountID]
	for i, other := range list {
		if other == c {
			list = append(list[:i], list[i+1:]...)
			break
		}
	}
	if len(list) == 0 {
		delete(h.conns, accountID)
		return
	}
	h.conns[accountID] = list
}

// send pushes an event to every device of one profile. A profile with
// nothing open simply misses it: everything a user event announces is also
// readable over REST when they come back.
func (h *userHub) send(accountID string, env protocol.Envelope) {
	h.mu.Lock()
	conns := make([]*wsConn, len(h.conns[accountID]))
	copy(conns, h.conns[accountID])
	h.mu.Unlock()
	for _, c := range conns {
		c.Send(env)
	}
}

// online reports whether a profile has a user socket open anywhere.
func (h *userHub) online(accountID string) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.conns[accountID]) > 0
}

// notify sends one event to a profile.
func (s *Server) notify(accountID string, e protocol.UserEvent) {
	if accountID == "" || s.users == nil {
		return
	}
	if e.At == 0 {
		e.At = s.now().UnixMilli()
	}
	payload, err := json.Marshal(e)
	if err != nil {
		s.log.Error("marshal user event", "err", err)
		return
	}
	s.users.send(accountID, protocol.Envelope{Type: protocol.TypeUserEvent, Payload: payload})
}

// handleUserWS is the user socket (docs/protocol.md): one connection per
// device for the signed-in profile, carrying what happens away from the
// table. It takes no commands — a client that sends anything but a ping is
// closed — so nothing can be done through it that REST does not do.
func (s *Server) handleUserWS(w http.ResponseWriter, r *http.Request) {
	if !s.cfg.Accounts {
		writeError(w, http.StatusNotFound, protocol.ErrAccountsOff, "this instance has no player profiles")
		return
	}
	ip := s.clientIP(r)
	if !s.limWS.allow(ip, s.now()) {
		writeError(w, http.StatusTooManyRequests, protocol.ErrRateLimited, "too many connections")
		return
	}
	if !s.acquireConn(ip) {
		writeError(w, http.StatusTooManyRequests, protocol.ErrRateLimited, "connection limit reached")
		return
	}
	defer s.releaseConn(ip)

	raw, err := websocket.Accept(w, r, &websocket.AcceptOptions{OriginPatterns: s.originPatterns()})
	if err != nil {
		s.log.Debug("user websocket accept failed", "err", err, "ip", ip)
		return
	}
	raw.SetReadLimit(wsReadLimit)
	conn := newWSConn(raw)
	defer conn.wait()

	ctx := r.Context()
	helloCtx, cancel := context.WithTimeout(ctx, helloTimeout)
	env, size, err := readEnvelope(helloCtx, raw)
	cancel()
	if err == nil && size > wsMessageLimit {
		conn.Close(protocol.ClosePolicy, "message too large")
		return
	}
	if err != nil || env.Type != protocol.TypeHello {
		conn.Close(protocol.ClosePolicy, "hello expected")
		return
	}
	var hello protocol.Hello
	if err := json.Unmarshal(env.Payload, &hello); err != nil {
		conn.Close(protocol.ClosePolicy, "bad hello")
		return
	}
	if hello.V != protocol.Version {
		conn.Close(protocol.CloseUnsupportedVersion, "unsupported protocol version")
		return
	}
	a, err := s.store.AccountForSession(ctx, hashToken(hello.Token), s.now().UnixMilli())
	if err != nil {
		conn.Close(protocol.CloseBadToken, "bad token")
		return
	}
	s.users.add(a.ID, conn)
	defer s.users.remove(a.ID, conn)
	conn.Send(protocol.Envelope{Type: protocol.TypeWelcome, Payload: json.RawMessage(`{"v":1}`)})
	s.friendsChanged(a.ID)

	// Reads exist only to notice the connection going away and to answer a
	// ping; anything else closes it.
	limiter := newRateBucket(wsCommandRate, wsCommandRate, s.now())
	for {
		env, size, err := readEnvelope(ctx, raw)
		if err != nil {
			return
		}
		if size > wsMessageLimit {
			conn.Close(protocol.ClosePolicy, "message too large")
			return
		}
		if !limiter.allow(s.now()) {
			conn.Close(protocol.ClosePolicy, "rate limit")
			return
		}
		if env.Type != protocol.TypePing {
			conn.Close(protocol.ClosePolicy, "user socket takes no commands")
			return
		}
		conn.Send(protocol.Envelope{Type: protocol.TypePong, ID: env.ID})
	}
}

// friendsChanged tells a profile's friends that something about them
// changed — coming online is the first such thing.
func (s *Server) friendsChanged(accountID string) {
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		friends, err := s.store.Friends(ctx, accountID)
		if err != nil {
			s.log.Debug("friends changed", "err", err)
			return
		}
		for _, f := range friends {
			s.notify(f.ID, protocol.UserEvent{Kind: protocol.UserFriendsPlaying})
		}
	}()
}
