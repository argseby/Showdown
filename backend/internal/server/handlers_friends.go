package server

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"showdown/internal/account"
	"showdown/internal/protocol"
	"showdown/internal/store"
	"showdown/internal/table"
)

// searchLimit caps a name search. Finding a friend takes a few letters;
// listing the instance is not what this is for.
const searchLimit = 20

// relations a profile can stand in to another, as the app names them.
const (
	relNone       = "none"
	relFriend     = "friend"
	relPendingOut = "pending_out"
	relPendingIn  = "pending_in"
	relBlocked    = "blocked"
)

func friendView(f store.FriendRow, relation string) map[string]any {
	return map[string]any{
		"id": f.ID, "handle": f.Handle, "display_name": f.DisplayName,
		"since": f.Since, "relation": relation,
	}
}

type handleRequest struct {
	Handle string `json:"handle"`
}

// handleFriends answers the whole friends screen in one call: the friends,
// the asks in both directions, the blocked profiles and the invitations
// waiting to be answered.
func (s *Server) handleFriends(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	ctx := r.Context()
	friends, err := s.store.Friends(ctx, a.ID)
	if err != nil {
		s.log.Error("friends", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the friends")
		return
	}
	incoming, outgoing, err := s.store.PendingRequests(ctx, a.ID)
	if err != nil {
		s.log.Error("friend requests", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the requests")
		return
	}
	blocked, err := s.store.Blocked(ctx, a.ID)
	if err != nil {
		s.log.Error("blocked", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the blocks")
		return
	}
	invites, err := s.store.Invites(ctx, a.ID, s.now().UnixMilli())
	if err != nil {
		s.log.Error("invites", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the invitations")
		return
	}
	list := func(rows []store.FriendRow, relation string) []map[string]any {
		out := make([]map[string]any, 0, len(rows))
		for _, f := range rows {
			out = append(out, friendView(f, relation))
		}
		return out
	}
	asks := func(rows []store.RequestRow, relation string) []map[string]any {
		out := make([]map[string]any, 0, len(rows))
		for _, rq := range rows {
			out = append(out, friendView(store.FriendRow{
				ID: rq.ID, Handle: rq.Handle, DisplayName: rq.DisplayName, Since: rq.CreatedAt,
			}, relation))
		}
		return out
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"friends":  list(friends, relFriend),
		"incoming": asks(incoming, relPendingIn),
		"outgoing": asks(outgoing, relPendingOut),
		"blocked":  list(blocked, relBlocked),
		"invites":  inviteViews(invites),
	})
}

func inviteViews(rows []store.InviteRow) []map[string]any {
	out := make([]map[string]any, 0, len(rows))
	for _, i := range rows {
		out = append(out, map[string]any{
			"id": i.ID, "table_id": i.TableID, "table_name": i.TableName,
			"from": i.FromName, "created_at": i.CreatedAt, "expires_at": i.ExpiresAt,
		})
	}
	return out
}

// handleFriendSearch finds profiles by the start of a handle or a name,
// each with how it already stands to the searcher.
func (s *Server) handleFriendSearch(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	query := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))
	if query == "" {
		writeJSON(w, http.StatusOK, map[string]any{"results": []any{}})
		return
	}
	ctx := r.Context()
	found, err := s.store.SearchAccounts(ctx, a.ID, query, searchLimit)
	if err != nil {
		s.log.Error("search accounts", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not search")
		return
	}
	friends, err := s.store.Friends(ctx, a.ID)
	if err != nil {
		s.log.Error("friends", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not search")
		return
	}
	incoming, outgoing, err := s.store.PendingRequests(ctx, a.ID)
	if err != nil {
		s.log.Error("friend requests", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not search")
		return
	}
	relation := map[string]string{}
	for _, f := range friends {
		relation[f.ID] = relFriend
	}
	for _, rq := range incoming {
		relation[rq.ID] = relPendingIn
	}
	for _, rq := range outgoing {
		relation[rq.ID] = relPendingOut
	}
	results := make([]map[string]any, 0, len(found))
	for _, f := range found {
		rel, has := relation[f.ID]
		if !has {
			rel = relNone
		}
		results = append(results, friendView(f, rel))
	}
	writeJSON(w, http.StatusOK, map[string]any{"results": results})
}

// handleFriendRequest asks another profile to be friends. Two profiles
// that have each asked the other are friends straight away.
func (s *Server) handleFriendRequest(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	var req handleRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	other, err := s.store.GetAccountByHandle(r.Context(), account.Key(req.Handle))
	if err != nil {
		writeError(w, http.StatusNotFound, protocol.ErrNotFound, "no such profile")
		return
	}
	mutual, err := s.store.RequestFriend(r.Context(), a.ID, other.ID, s.now().UnixMilli())
	switch {
	case errors.Is(err, store.ErrSelf):
		writeError(w, http.StatusBadRequest, protocol.ErrValidation, "that is you")
		return
	case errors.Is(err, store.ErrAlreadyFriends):
		writeError(w, http.StatusConflict, protocol.ErrValidation, "already friends")
		return
	case errors.Is(err, store.ErrBlocked):
		// Say no more than "no": a block is not announced.
		writeError(w, http.StatusForbidden, protocol.ErrForbidden, "cannot ask this profile")
		return
	case err != nil:
		s.log.Error("request friend", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not send the request")
		return
	}
	if mutual {
		s.notifyFriendship(a, other)
		writeJSON(w, http.StatusOK, map[string]any{"state": relFriend})
		return
	}
	s.notify(other.ID, protocol.UserEvent{
		Kind: protocol.UserFriendRequest, Handle: a.Handle, DisplayName: a.DisplayName,
	})
	writeJSON(w, http.StatusOK, map[string]any{"state": relPendingOut})
}

// handleFriendAnswer accepts, declines or blocks an incoming request. The
// asker hears about an accepted request and nothing else: a decline and an
// unanswered ask look the same from the outside.
func (s *Server) handleFriendAnswer(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	other, ok := s.profileByHandle(w, r, r.PathValue("handle"))
	if !ok {
		return
	}
	now := s.now().UnixMilli()
	switch r.PathValue("answer") {
	case "accept":
		done, err := s.store.AcceptRequest(r.Context(), a.ID, other.ID, now)
		if err != nil {
			s.log.Error("accept request", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not accept")
			return
		}
		if !done {
			writeError(w, http.StatusNotFound, protocol.ErrNotFound, "no such request")
			return
		}
		s.notifyFriendship(a, other)
		writeJSON(w, http.StatusOK, map[string]any{"state": relFriend})
	case "decline":
		if _, err := s.store.DeclineRequest(r.Context(), a.ID, other.ID); err != nil {
			s.log.Error("decline request", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not decline")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"state": relNone})
	case "block":
		if err := s.store.BlockAccount(r.Context(), a.ID, other.ID, now); err != nil {
			s.log.Error("block", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not block")
			return
		}
		s.audit(r, "account_blocked", "", "", map[string]any{"handle": other.Handle})
		writeJSON(w, http.StatusOK, map[string]any{"state": relBlocked})
	default:
		writeError(w, http.StatusBadRequest, protocol.ErrValidation, "unknown answer")
	}
}

// handleUnfriend ends a friendship. Both sides lose it at once.
func (s *Server) handleUnfriend(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	other, ok := s.profileByHandle(w, r, r.PathValue("handle"))
	if !ok {
		return
	}
	if err := s.store.Unfriend(r.Context(), a.ID, other.ID); err != nil {
		s.log.Error("unfriend", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not remove the friend")
		return
	}
	s.notify(other.ID, protocol.UserEvent{Kind: protocol.UserFriendsChanged})
	writeJSON(w, http.StatusOK, map[string]any{"state": relNone})
}

// handleUnblock lifts a block. The friendship does not come back with it.
func (s *Server) handleUnblock(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	other, ok := s.profileByHandle(w, r, r.PathValue("handle"))
	if !ok {
		return
	}
	if err := s.store.UnblockAccount(r.Context(), a.ID, other.ID); err != nil {
		s.log.Error("unblock", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not unblock")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"state": relNone})
}

// profileByHandle resolves a handle from the path.
func (s *Server) profileByHandle(w http.ResponseWriter, r *http.Request, handle string) (store.AccountRow, bool) {
	other, err := s.store.GetAccountByHandle(r.Context(), account.Key(handle))
	if err != nil {
		writeError(w, http.StatusNotFound, protocol.ErrNotFound, "no such profile")
		return store.AccountRow{}, false
	}
	return other, true
}

// inviteLifetime is how long an invitation to a table stays good. Long
// enough to come back from the kitchen, short enough that a link to a
// table that has long since ended does not linger.
const inviteLifetime = 2 * time.Hour

// handleFriendsPlaying lists the tables friends are sitting at, with what
// somebody needs to decide whether to join: the stakes, the free seats and
// whether the door is open.
func (s *Server) handleFriendsPlaying(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	friends, err := s.store.Friends(r.Context(), a.ID)
	if err != nil {
		s.log.Error("friends", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the friends")
		return
	}
	byID := make(map[string]store.FriendRow, len(friends))
	for _, f := range friends {
		byID[f.ID] = f
	}
	tables := make([]map[string]any, 0)
	for _, t := range s.registry.List() {
		info := t.Info()
		if info.State == table.StateEnded {
			continue
		}
		seated, free := t.Profiles()
		here := make([]map[string]any, 0, len(seated))
		for _, p := range seated {
			f, ok := byID[p.AccountID]
			if !ok {
				continue
			}
			here = append(here, map[string]any{
				"handle": f.Handle, "display_name": f.DisplayName,
				"name": p.Name, "connected": p.Connected,
			})
		}
		if len(here) == 0 {
			continue
		}
		tables = append(tables, map[string]any{
			"id": info.ID, "name": info.Name, "state": info.State,
			"blinds":      blinds{Small: info.SmallBlind, Big: info.BigBlind},
			"seated":      info.Seated,
			"max_players": info.MaxPlayers, "free_seats": free,
			"requires_password": info.RequiresPassword, "join_policy": info.JoinPolicy,
			"allow_spectators": info.AllowSpectators, "variant": info.Variant,
			"tournament": info.Tournament, "friends": here,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"tables": tables})
}

// handleInvite asks a friend to a table. Only a friend, and only a table
// the asker is sitting at: an invitation is a person saying "come and
// play", not a way to push a link at somebody.
func (s *Server) handleInvite(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	info := t.Info()
	if info.State == table.StateEnded {
		writeError(w, http.StatusGone, protocol.ErrTableEnded, "table has ended")
		return
	}
	seated, _ := t.Profiles()
	atTable := false
	for _, p := range seated {
		if p.AccountID == a.ID {
			atTable = true
			break
		}
	}
	if !atTable {
		writeError(w, http.StatusForbidden, protocol.ErrForbidden, "you are not at this table")
		return
	}
	var req handleRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	other, err := s.store.GetAccountByHandle(r.Context(), account.Key(req.Handle))
	if err != nil {
		writeError(w, http.StatusNotFound, protocol.ErrNotFound, "no such profile")
		return
	}
	friends, err := s.store.AreFriends(r.Context(), a.ID, other.ID)
	if err != nil {
		s.log.Error("are friends", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not invite")
		return
	}
	if !friends {
		writeError(w, http.StatusForbidden, protocol.ErrForbidden, "only friends can be invited")
		return
	}
	now := s.now()
	row := store.InviteRow{
		ID: "i" + newToken()[:16], TableID: t.ID, TableName: info.Name,
		FromID: a.ID, FromName: a.Handle, ToID: other.ID,
		CreatedAt: now.UnixMilli(), ExpiresAt: now.Add(inviteLifetime).UnixMilli(),
	}
	if err := s.store.CreateInvite(r.Context(), row); err != nil {
		s.log.Error("create invite", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not invite")
		return
	}
	s.notify(other.ID, protocol.UserEvent{
		Kind: protocol.UserTableInvite, Handle: a.Handle, DisplayName: a.DisplayName,
		InviteID: row.ID, TableID: t.ID, TableName: info.Name,
	})
	writeJSON(w, http.StatusCreated, map[string]any{"invite_id": row.ID})
}

// handleInviteDismiss drops an invitation once it has been taken up or
// turned down.
func (s *Server) handleInviteDismiss(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	if err := s.store.DeleteInvite(r.Context(), a.ID, r.PathValue("id")); err != nil {
		s.log.Error("delete invite", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not dismiss")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// notifyFriendship tells both sides that they are now friends.
func (s *Server) notifyFriendship(a, b store.AccountRow) {
	s.notify(b.ID, protocol.UserEvent{
		Kind: protocol.UserFriendAccepted, Handle: a.Handle, DisplayName: a.DisplayName,
	})
	s.notify(a.ID, protocol.UserEvent{
		Kind: protocol.UserFriendAccepted, Handle: b.Handle, DisplayName: b.DisplayName,
	})
}
