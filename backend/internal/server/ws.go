package server

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"sync"
	"time"

	"github.com/coder/websocket"

	"showdown/internal/poker"
	"showdown/internal/protocol"
	"showdown/internal/table"
)

const (
	helloTimeout    = 5 * time.Second
	wsPingInterval  = 20 * time.Second
	wsWriteTimeout  = 10 * time.Second
	wsReadLimit     = 8 << 10
	wsOutboundQueue = 64
	wsCommandRate   = 20 // commands per second per connection
	wsChatRate      = 1  // chat lines per second
	wsChatBurst     = 5
)

// outbound is one item of the writer queue: a message or a close request.
type outbound struct {
	env   *protocol.Envelope
	close *closeReq
}

type closeReq struct {
	code   int
	reason string
}

// wsConn implements table.Conn: one writer goroutine drains a bounded queue;
// a full queue closes the connection with 1008.
type wsConn struct {
	c      *websocket.Conn
	queue  chan outbound
	done   chan struct{} // closed when the writer exits
	once   sync.Once
	closed chan struct{} // closed once a close was requested
}

func newWSConn(c *websocket.Conn) *wsConn {
	w := &wsConn{c: c, queue: make(chan outbound, wsOutboundQueue), done: make(chan struct{}), closed: make(chan struct{})}
	go w.writer()
	return w
}

func (w *wsConn) writer() {
	defer close(w.done)
	ticker := time.NewTicker(wsPingInterval)
	defer ticker.Stop()
	for {
		select {
		case item := <-w.queue:
			if item.close != nil {
				w.drain()
				_ = w.c.Close(websocket.StatusCode(item.close.code), item.close.reason)
				return
			}
			if !w.write(item.env) {
				return
			}
		case <-ticker.C:
			ctx, cancel := context.WithTimeout(context.Background(), wsWriteTimeout)
			err := w.c.Ping(ctx)
			cancel()
			if err != nil {
				_ = w.c.Close(websocket.StatusPolicyViolation, "ping timeout")
				return
			}
		}
	}
}

// drain writes whatever is still queued before a close.
func (w *wsConn) drain() {
	for {
		select {
		case item := <-w.queue:
			if item.env != nil && !w.write(item.env) {
				return
			}
		default:
			return
		}
	}
}

func (w *wsConn) write(env *protocol.Envelope) bool {
	b, err := json.Marshal(env)
	if err != nil {
		return true
	}
	ctx, cancel := context.WithTimeout(context.Background(), wsWriteTimeout)
	defer cancel()
	return w.c.Write(ctx, websocket.MessageText, b) == nil
}

// Send enqueues without blocking; a full queue closes the connection.
func (w *wsConn) Send(env protocol.Envelope) bool {
	select {
	case <-w.closed:
		return false
	default:
	}
	select {
	case w.queue <- outbound{env: &env}:
		return true
	default:
		w.Close(protocol.ClosePolicy, "slow consumer")
		return false
	}
}

// Close requests a close after all queued messages were written.
func (w *wsConn) Close(code int, reason string) {
	w.once.Do(func() {
		close(w.closed)
		select {
		case w.queue <- outbound{close: &closeReq{code: code, reason: reason}}:
		default:
			// Queue full: the writer is stuck or slow; close hard.
			_ = w.c.Close(websocket.StatusCode(code), reason)
		}
	})
}

// wait blocks until the writer goroutine finished.
func (w *wsConn) wait() { <-w.done }

func (s *Server) originPatterns() []string {
	if s.cfg.DevCORSOrigin == "" {
		return nil
	}
	u, err := url.Parse(s.cfg.DevCORSOrigin)
	if err != nil {
		return nil
	}
	return []string{u.Host}
}

func (s *Server) acquireConn(ip string) bool {
	s.connMu.Lock()
	defer s.connMu.Unlock()
	if s.connsByIP[ip] >= s.cfg.MaxConnectionsPerIP {
		return false
	}
	s.connsByIP[ip]++
	return true
}

func (s *Server) releaseConn(ip string) {
	s.connMu.Lock()
	defer s.connMu.Unlock()
	if s.connsByIP[ip] <= 1 {
		delete(s.connsByIP, ip)
	} else {
		s.connsByIP[ip]--
	}
}

// handleWS is the game connection (docs/protocol.md).
func (s *Server) handleWS(w http.ResponseWriter, r *http.Request) {
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
		s.log.Debug("websocket accept failed", "err", err, "ip", ip)
		return
	}
	raw.SetReadLimit(wsReadLimit)
	conn := newWSConn(raw)
	defer conn.wait()

	tableID := r.PathValue("id")
	t, ok := s.registry.Get(tableID)
	if !ok {
		conn.Close(protocol.CloseTableGone, "table not found")
		return
	}

	// First message must be hello.
	ctx := r.Context()
	helloCtx, cancel := context.WithTimeout(ctx, helloTimeout)
	env, err := readEnvelope(helloCtx, raw)
	cancel()
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
	client, code, reason := s.resolveClient(ctx, conn, t, hello)
	if client == nil {
		conn.Close(code, reason)
		return
	}
	if err := t.Attach(client); err != nil {
		code, reason := protocol.CloseBadToken, "not seated"
		if errors.Is(err, table.ErrTableEnded) {
			code, reason = protocol.CloseTableGone, "table ended"
		} else if errors.Is(err, table.ErrSpectatorsDisabled) {
			code, reason = protocol.ClosePolicy, "spectators disabled"
		}
		conn.Close(code, reason)
		return
	}
	defer t.Detach(client)
	s.readLoop(ctx, raw, conn, t, client)
}

// resolveClient turns a hello into a client identity. The token is a player
// or spectator session of this table, or the table's admin token (a live
// view without a seat). A session holder who also presents the admin token
// in admin_token is flagged as admin.
func (s *Server) resolveClient(ctx context.Context, conn *wsConn, t *table.Table, hello protocol.Hello) (*table.Client, int, string) {
	if hello.Token == "" {
		return nil, protocol.CloseBadToken, "token required"
	}
	if isTableAdmin(t, hello.Token) {
		return &table.Client{Conn: conn, Role: table.RoleAdmin, Name: "admin", Admin: true}, 0, ""
	}
	sess, err := s.lookupSession(ctx, hello.Token)
	if err != nil || sess.TableID != t.ID {
		return nil, protocol.CloseBadToken, "bad token"
	}
	admin := isTableAdmin(t, hello.AdminToken)
	switch sess.Kind {
	case table.RolePlayer:
		return &table.Client{Conn: conn, Role: table.RolePlayer, PlayerID: sess.PlayerID, Name: sess.Name, Admin: admin}, 0, ""
	case table.RoleSpectator:
		return &table.Client{Conn: conn, Role: table.RoleSpectator, Name: sess.Name, Admin: admin}, 0, ""
	}
	return nil, protocol.CloseBadToken, "bad token"
}

func readEnvelope(ctx context.Context, c *websocket.Conn) (protocol.Envelope, error) {
	var env protocol.Envelope
	_, data, err := c.Read(ctx)
	if err != nil {
		return env, err
	}
	if err := json.Unmarshal(data, &env); err != nil {
		return env, err
	}
	return env, nil
}

func (s *Server) readLoop(ctx context.Context, raw *websocket.Conn, conn *wsConn, t *table.Table, client *table.Client) {
	cmdBucket := newRateBucket(wsCommandRate, wsCommandRate, s.now())
	chatBucket := newRateBucket(wsChatRate, wsChatBurst, s.now())
	send := func(typ, id string, payload any) { conn.Send(protocol.MustEncode(typ, id, payload)) }
	fail := func(id string, err error) {
		code, _ := wsErrorCode(err)
		send(protocol.TypeError, id, protocol.ErrorPayload{ID: id, Code: code, Message: err.Error()})
	}
	for {
		env, err := readEnvelope(ctx, raw)
		if err != nil {
			var ce websocket.CloseError
			if errors.As(err, &ce) || errors.Is(err, context.Canceled) {
				return
			}
			if errors.Is(err, context.DeadlineExceeded) {
				return
			}
			// Malformed JSON or read error: policy close.
			conn.Close(protocol.ClosePolicy, "bad message")
			return
		}
		if !cmdBucket.allow(s.now()) {
			conn.Close(protocol.ClosePolicy, "rate limit")
			return
		}
		if env.Type == protocol.TypePing {
			send(protocol.TypePong, env.ID, protocol.Pong{ServerTS: s.now().UnixMilli()})
			continue
		}
		var err2 error
		switch env.Type {
		case protocol.TypeAction:
			var a protocol.ActionPayload
			if json.Unmarshal(env.Payload, &a) != nil {
				err2 = poker.ErrIllegalAction
				break
			}
			if client.Role != table.RolePlayer {
				err2 = table.ErrNotSeated
				break
			}
			err2 = t.Action(client.PlayerID, poker.Action{Kind: poker.ActionKind(a.Kind), Amount: a.Amount})
		case protocol.TypeSitOut, protocol.TypeSitIn, protocol.TypeRebuy, protocol.TypeLeave, protocol.TypeShowCards,
			protocol.TypePreAction, protocol.TypeRabbit, protocol.TypeChangeSeat, protocol.TypeVoice, protocol.TypeVoiceSignal,
			protocol.TypeStraddle, protocol.TypeRunTwice:
			if client.Role != table.RolePlayer {
				err2 = table.ErrNotSeated
				break
			}
			switch env.Type {
			case protocol.TypeSitOut:
				err2 = t.SitOut(client.PlayerID)
			case protocol.TypeSitIn:
				err2 = t.SitIn(client.PlayerID)
			case protocol.TypeRebuy:
				err2 = t.Rebuy(client.PlayerID)
			case protocol.TypeLeave:
				err2 = t.Leave(client.PlayerID)
			case protocol.TypeShowCards:
				var sc protocol.ShowCardsPayload
				if len(env.Payload) > 0 {
					_ = json.Unmarshal(env.Payload, &sc)
				}
				err2 = t.ShowCards(client.PlayerID, sc.Cards)
			case protocol.TypePreAction:
				var pa protocol.PreActionPayload
				if json.Unmarshal(env.Payload, &pa) != nil {
					err2 = table.ErrIllegalAction
					break
				}
				err2 = t.SetPreAction(client.PlayerID, pa.Kind)
			case protocol.TypeRabbit:
				err2 = t.RabbitHunt(client.PlayerID)
			case protocol.TypeChangeSeat:
				var cs protocol.ChangeSeatPayload
				if json.Unmarshal(env.Payload, &cs) != nil {
					err2 = table.ErrIllegalAction
					break
				}
				err2 = t.ChangeSeat(client.PlayerID, cs.Seat)
			case protocol.TypeVoice:
				var v protocol.VoicePayload
				if json.Unmarshal(env.Payload, &v) != nil {
					err2 = table.ErrIllegalAction
					break
				}
				err2 = t.SetVoice(client.PlayerID, v.State, v.Camera)
			case protocol.TypeStraddle:
				var sp protocol.StraddlePayload
				if json.Unmarshal(env.Payload, &sp) != nil {
					err2 = table.ErrIllegalAction
					break
				}
				err2 = t.SetStraddle(client.PlayerID, sp.On)
			case protocol.TypeRunTwice:
				var rt protocol.RunTwicePayload
				if json.Unmarshal(env.Payload, &rt) != nil {
					err2 = table.ErrIllegalAction
					break
				}
				err2 = t.RunTwice(client.PlayerID, rt.Agree)
			case protocol.TypeVoiceSignal:
				var sig protocol.VoiceSignal
				if json.Unmarshal(env.Payload, &sig) != nil || sig.To == "" || len(sig.Data) > 6000 {
					err2 = table.ErrIllegalAction
					break
				}
				err2 = t.RelayVoice(client, sig.To, sig)
			}
		case protocol.TypeSay:
			var sp protocol.SayPayload
			if json.Unmarshal(env.Payload, &sp) != nil {
				err2 = table.ErrIllegalAction
				break
			}
			err2 = t.Say(client, sp.Phrase)
		case protocol.TypeChat:
			var c protocol.ChatPayload
			if json.Unmarshal(env.Payload, &c) != nil {
				err2 = table.ErrInvalidText
				break
			}
			if !chatBucket.allow(s.now()) {
				send(protocol.TypeError, env.ID, protocol.ErrorPayload{ID: env.ID, Code: protocol.ErrRateLimited, Message: "chat rate limit"})
				continue
			}
			err2 = t.Chat(client, c.Text)
		case protocol.TypeHello:
			err2 = errors.New("hello already received")
		default:
			send(protocol.TypeError, env.ID, protocol.ErrorPayload{ID: env.ID, Code: protocol.ErrUnknownType, Message: "unknown message type"})
			continue
		}
		if err2 != nil {
			fail(env.ID, err2)
			continue
		}
		send(protocol.TypeAck, env.ID, protocol.Ack{ID: env.ID})
		if env.Type == protocol.TypeLeave {
			// The seat is gone; close after the ack has been flushed.
			conn.Close(1000, "left")
			return
		}
	}
}
