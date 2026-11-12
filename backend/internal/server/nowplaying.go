package server

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"showdown/internal/protocol"
	"showdown/internal/revokedauth"
	"showdown/internal/store"
	"showdown/internal/table"
)

// The entry this instance keeps in the player's vault. One entry, one
// line: a reader of the share sees where the player is and can click
// straight into it.
const (
	nowPlayingKey   = "now_playing"
	nowPlayingLabel = "Now playing"
	nowPlayingShare = "Showdown — now playing"
	// nowPlayingIdle is what the entry says between tables. It is written
	// rather than deleted, so the link stays good and simply goes quiet.
	nowPlayingIdle = "Not at a table"
)

// How often the tables are looked over. Sitting down nudges the loop at
// once; standing up, busting out and the table ending are all noticed on
// the next pass, which is why there is one.
const (
	nowPlayingEvery = 30 * time.Second
	// A nudge is not acted on immediately: a player who sits down, picks
	// another seat and reconnects is one write, not three.
	nowPlayingDebounce = 3 * time.Second
	// A paused tool refuses every request. It is asked again this often,
	// so that resuming it is noticed without spending a request a tick.
	nowPlayingRetry = 5 * time.Minute
)

// revokedConnect is a connection the player has started and not yet
// approved. It carries the profile, because the answer comes back from
// the app — possibly through another browser — and nothing else would say
// whose vault this is about.
type revokedConnect struct {
	accountID string
	server    string
	verifier  string
	wait      string
	expires   time.Time
}

// revokedConnects holds those, and the result each waiting page collects.
// Like a sign-in, none of it outlives the flow: a restart mid-approval
// costs the player one more tap.
type revokedConnects struct {
	mu    sync.Mutex
	flows map[string]*revokedConnect
	waits map[string]*revokedWait
}

func newRevokedConnects() *revokedConnects {
	return &revokedConnects{flows: map[string]*revokedConnect{}, waits: map[string]*revokedWait{}}
}

func (c *revokedConnects) start(state string, fl *revokedConnect) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.sweep()
	c.flows[state] = fl
	c.waits[fl.wait] = &revokedWait{expires: fl.expires}
}

// take returns a flow and removes it: a state answers once.
func (c *revokedConnects) take(state string, now time.Time) (*revokedConnect, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	fl, ok := c.flows[state]
	if !ok {
		return nil, false
	}
	delete(c.flows, state)
	if now.After(fl.expires) {
		return nil, false
	}
	return fl, true
}

func (c *revokedConnects) finish(wait, reason string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if w, ok := c.waits[wait]; ok {
		w.done, w.reason = true, reason
	}
}

func (c *revokedConnects) collect(wait string, now time.Time) (revokedWait, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	w, ok := c.waits[wait]
	if !ok {
		return revokedWait{}, false
	}
	if now.After(w.expires) {
		delete(c.waits, wait)
		return revokedWait{}, false
	}
	if w.done {
		delete(c.waits, wait)
	}
	return *w, true
}

func (c *revokedConnects) sweep() {
	now := time.Now()
	for k, v := range c.flows {
		if now.After(v.expires) {
			delete(c.flows, k)
		}
	}
	for k, v := range c.waits {
		if now.After(v.expires) {
			delete(c.waits, k)
		}
	}
}

// nowPlayingOn reports whether this instance offers the vault entry at
// all. It needs the sign-in, because the vault written to is always a
// server the profile already signs in with.
func (s *Server) nowPlayingOn() bool {
	return s.revoked != nil && s.cfg.RevokedNowPlaying && s.revokedConnects != nil
}

func (s *Server) requireNowPlaying(w http.ResponseWriter) bool {
	if !s.accountsOn(w) {
		return false
	}
	if s.nowPlayingOn() {
		return true
	}
	writeError(w, http.StatusNotFound, protocol.ErrNowPlayingOff,
		"this instance does not keep your table link in your revoked vault")
	return false
}

// nowPlayingRedirectURI is where the app delivers the answer. It sits on
// PublicOrigin, which is also the client id the connection is made for.
func (s *Server) nowPlayingRedirectURI() string {
	return s.cfg.PublicOrigin + "/api/accounts/revoked/connect/callback"
}

type revokedConnectRequest struct {
	Server string `json:"server"`
}

// handleRevokedConnectStart prepares the connection for the page to show:
// a revoked://connect link as a QR code or a link for this device, and the
// key the page collects the answer with.
//
// The vault must be on a server this profile already signs in with. That
// is not a formality: without it, somebody who read the link off the
// player's screen could attach their own vault to this profile and be
// told where that player is playing.
func (s *Server) handleRevokedConnectStart(w http.ResponseWriter, r *http.Request) {
	if !s.requireNowPlaying(w) {
		return
	}
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	var req revokedConnectRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	server, ok := s.revokedVaultServer(w, r, a.ID, req.Server)
	if !ok {
		return
	}
	verifier, err := revokedauth.NewVerifier()
	if err != nil {
		s.log.Error("revoked verifier", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not start the connection")
		return
	}
	state, wait := newToken(), newToken()
	challenge := revokedauth.Challenge(verifier)
	s.revokedConnects.start(state, &revokedConnect{
		accountID: a.ID, server: server, verifier: verifier, wait: wait,
		expires: s.now().Add(revokedFlowLifetime),
	})
	writeJSON(w, http.StatusOK, map[string]any{
		"app_link": revokedauth.ConnectLink(
			s.cfg.PublicOrigin, s.nowPlayingName(), s.nowPlayingRedirectURI(), state, challenge,
			"To keep one entry saying which table you are at"),
		"wait":       wait,
		"server":     server,
		"check_code": revokedauth.CheckCode(challenge),
	})
}

// nowPlayingName is what this instance calls itself in the player's app
// and in their vault: the host they reach it at, which is the one name
// they can check.
func (s *Server) nowPlayingName() string {
	if u, err := url.Parse(s.cfg.PublicOrigin); err == nil && u.Host != "" {
		return "Showdown (" + u.Host + ")"
	}
	return "Showdown"
}

// revokedVaultServer picks the vault to write to: the one this profile is
// already connected to, or one of the revoked servers it signs in with.
func (s *Server) revokedVaultServer(w http.ResponseWriter, r *http.Request, accountID, asked string) (string, bool) {
	idents, err := s.store.AccountIdentities(r.Context(), accountID)
	if err != nil {
		s.log.Error("account identities", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read your profile")
		return "", false
	}
	if len(idents) == 0 {
		writeError(w, http.StatusConflict, protocol.ErrRevokedIdentity,
			"sign in with revoked first: the vault written to is the server you sign in with")
		return "", false
	}
	if strings.TrimSpace(asked) != "" {
		want, err := revokedauth.NormalizeIssuer(asked)
		if err != nil {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
			return "", false
		}
		for _, i := range idents {
			if i.Issuer == want {
				return want, true
			}
		}
		writeError(w, http.StatusConflict, protocol.ErrRevokedIdentity,
			"you do not sign in with that server")
		return "", false
	}
	// The most recently linked identity: the one they just used.
	return idents[len(idents)-1].Issuer, true
}

// handleRevokedConnectCallback takes the app's answer and leaves the
// result for the page. The app opens this address in whichever browser the
// system picks, so the state is the only thing tying an answer to the flow
// that asked — and the code it carries is useless without the verifier
// this server kept.
func (s *Server) handleRevokedConnectCallback(w http.ResponseWriter, r *http.Request) {
	if !s.nowPlayingOn() || !s.cfg.Accounts {
		http.NotFound(w, r)
		return
	}
	q := r.URL.Query()
	fl, ok := s.revokedConnects.take(q.Get("state"), s.now())
	if !ok {
		s.revokedRedirect(w, r, url.Values{"revoked_error": {"state_mismatch"}})
		return
	}
	reason := s.revokedConnectAnswer(r, fl, q)
	s.revokedConnects.finish(fl.wait, reason)
	if reason != "" {
		s.revokedRedirect(w, r, url.Values{"revoked_error": {reason}})
		return
	}
	s.revokedRedirect(w, r, nil)
}

// revokedConnectAnswer turns the app's answer into a saved connection, or
// into the reason there is none.
func (s *Server) revokedConnectAnswer(r *http.Request, fl *revokedConnect, q url.Values) string {
	if q.Get("status") == "declined" {
		return "access_denied"
	}
	// The app names the server it answered on. It has to be the one this
	// flow was started against, which is a server the profile signs in
	// with: another server's vault is not this player's.
	if named := q.Get("server"); named != "" {
		norm, err := revokedauth.NormalizeIssuer(named)
		if err != nil || norm != fl.server {
			return "issuer_mismatch"
		}
	}
	code := q.Get("code")
	if code == "" {
		return "no_code"
	}
	ctx := r.Context()
	token, conn, err := s.revoked.ConnectToken(ctx, fl.server, code, fl.verifier, s.nowPlayingRedirectURI())
	if err != nil {
		s.log.Warn("revoked connect token", "server", fl.server, "err", err)
		return "exchange_failed"
	}
	// The player decides in the app what to allow, and may well have
	// unticked something. Without a section of its own to write there is
	// nothing to keep, so say so rather than hold a useless token.
	if !conn.Writable() || !conn.CanShare() {
		if err := s.revoked.Disconnect(ctx, fl.server, token); err != nil {
			s.log.Debug("revoked disconnect", "server", fl.server, "err", err)
		}
		return "not_permitted"
	}
	now := s.now()
	row := store.RevokedLinkRow{
		AccountID: fl.accountID, Server: fl.server, ConnectionID: conn.ID, Token: token,
		Section: conn.Section, CreatedAt: now.UnixMilli(),
		ExpiresAt: conn.Expires(now).UnixMilli(), UpdatedAt: now.UnixMilli(),
	}
	if err := s.store.SaveRevokedLink(ctx, row); err != nil {
		s.log.Error("save revoked link", "err", err)
		return "internal"
	}
	s.audit(r, "revoked_now_playing_connected", "", "",
		map[string]any{"account": fl.accountID, "server": fl.server})
	// The entry and the share are made now, so the page that comes back
	// has a link to show rather than a promise of one.
	if _, err := s.provisionNowPlaying(ctx, row); err != nil {
		s.log.Warn("provision now playing", "server", fl.server, "err", err)
	}
	s.nowPlayingChanged(fl.accountID)
	return ""
}

// handleRevokedConnectWait is what the page asks while it shows the code.
func (s *Server) handleRevokedConnectWait(w http.ResponseWriter, r *http.Request) {
	if !s.requireNowPlaying(w) {
		return
	}
	if _, ok := s.requireAccount(w, r); !ok {
		return
	}
	var req revokedWaitRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	res, ok := s.revokedConnects.collect(req.Wait, s.now())
	if !ok {
		writeError(w, http.StatusUnauthorized, protocol.ErrRevokedState, "that connection is no longer valid")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"done": res.done, "error": res.reason})
}

// handleNowPlaying says where this profile's link stands: whether there is
// one, what it is, and what it currently says.
func (s *Server) handleNowPlaying(w http.ResponseWriter, r *http.Request) {
	if !s.requireNowPlaying(w) {
		return
	}
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	out := map[string]any{"connected": false, "playing": s.nowPlayingValue(a.ID)}
	row, err := s.store.RevokedLink(r.Context(), a.ID)
	switch {
	case errors.Is(err, store.ErrNotFound):
		writeJSON(w, http.StatusOK, out)
		return
	case err != nil:
		s.log.Error("revoked link", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the connection")
		return
	}
	out["connected"] = true
	out["server"] = row.Server
	out["url"] = row.LinkURL
	out["published"] = row.Published
	out["trouble"] = row.Trouble
	out["expires_at"] = row.ExpiresAt
	writeJSON(w, http.StatusOK, out)
}

// handleNowPlayingOff takes the link down: the share is revoked and the
// connection given up, so nothing here can write to that vault again. The
// entry stays in the player's vault, because it is theirs.
func (s *Server) handleNowPlayingOff(w http.ResponseWriter, r *http.Request) {
	if !s.requireNowPlaying(w) {
		return
	}
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	row, err := s.store.RevokedLink(r.Context(), a.ID)
	switch {
	case errors.Is(err, store.ErrNotFound):
		w.WriteHeader(http.StatusNoContent)
		return
	case err != nil:
		s.log.Error("revoked link", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the connection")
		return
	}
	if row.LinkID != "" {
		if err := s.revoked.RevokeShare(r.Context(), row.Server, row.Token, row.LinkID); err != nil {
			// Worth a line, never worth refusing: the player asked for
			// this to stop, and the row goes either way. Whatever is
			// left they can end from their app.
			s.log.Warn("revoke now playing share", "server", row.Server, "err", err)
		}
	}
	if err := s.revoked.Disconnect(r.Context(), row.Server, row.Token); err != nil {
		s.log.Debug("revoked disconnect", "server", row.Server, "err", err)
	}
	if err := s.store.DeleteRevokedLink(r.Context(), a.ID); err != nil {
		s.log.Error("delete revoked link", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not end the connection")
		return
	}
	s.audit(r, "revoked_now_playing_off", "", "", map[string]any{"account": a.ID, "server": row.Server})
	w.WriteHeader(http.StatusNoContent)
}

// nowPlayingValue is the line written into the vault: where this profile
// is sitting, as a reader of the share should see it.
//
// A table nobody can walk into is named without its address. The link is
// an invitation, and a password-protected or closed table is not one; the
// password itself is of course never written anywhere.
func (s *Server) nowPlayingValue(accountID string) string {
	for _, t := range s.registry.List() {
		info := t.Info()
		if info.State == table.StateEnded {
			continue
		}
		seated, free := t.Profiles()
		here := false
		for _, p := range seated {
			if p.AccountID == accountID {
				here = true
				break
			}
		}
		if !here {
			continue
		}
		parts := []string{
			info.Name,
			fmt.Sprintf("%d/%d", info.SmallBlind, info.BigBlind),
			fmt.Sprintf("%d/%d seats", info.Seated, info.MaxPlayers),
		}
		if info.Tournament {
			parts = append(parts, "tournament")
		}
		switch {
		case info.RequiresPassword, info.JoinPolicy == table.JoinClosed, free == 0:
			// Nothing to click: say so rather than hand out an address
			// that turns somebody away at the door.
			parts = append(parts, "closed table")
		default:
			parts = append(parts, s.cfg.PublicOrigin+"/t/"+info.ID)
		}
		return strings.Join(parts, " · ")
	}
	return nowPlayingIdle
}

// nowPlayingChanged says that a profile may have moved. It never blocks:
// the publisher wakes up, waits a moment for the rest of a sit-down to
// settle, and writes once.
func (s *Server) nowPlayingChanged(accountID string) {
	if !s.nowPlayingOn() || accountID == "" {
		return
	}
	s.npMu.Lock()
	if s.npDirty == nil {
		s.npDirty = map[string]bool{}
	}
	s.npDirty[accountID] = true
	s.npMu.Unlock()
	select {
	case s.npWake <- struct{}{}:
	default:
	}
}

// takeDirty hands over the profiles that were nudged.
func (s *Server) takeDirty() map[string]bool {
	s.npMu.Lock()
	defer s.npMu.Unlock()
	dirty := s.npDirty
	s.npDirty = nil
	return dirty
}

// RunNowPlaying keeps the vault entries current until ctx is done. It is
// started by the binary, like retention, and does nothing on an instance
// that does not offer the feature.
//
// Sitting down nudges it; everything else — standing up, busting out, the
// table ending, this server restarting — is noticed on the next pass.
// That is deliberate: a seat has many ways to empty, and a loop that
// looks at what is actually there cannot miss one of them.
func (s *Server) RunNowPlaying(ctx context.Context) {
	if !s.nowPlayingOn() {
		return
	}
	ticker := time.NewTicker(nowPlayingEvery)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.publishNowPlaying(ctx, nil)
		case <-s.npWake:
			select {
			case <-ctx.Done():
				return
			case <-time.After(nowPlayingDebounce):
			}
			s.publishNowPlaying(ctx, s.takeDirty())
		}
	}
}

// publishNowPlaying writes what has changed. With only non-nil it looks at
// those profiles alone; with nil it looks at every connection there is.
func (s *Server) publishNowPlaying(ctx context.Context, only map[string]bool) {
	if !s.nowPlayingOn() {
		return
	}
	now := s.now()
	rows, err := s.store.RevokedLinks(ctx, now.UnixMilli())
	if err != nil {
		s.log.Error("revoked links", "err", err)
		return
	}
	for _, row := range rows {
		if only != nil && !only[row.AccountID] {
			continue
		}
		// A paused tool refuses everything. It is asked again now and
		// then, because resuming it is the player's doing and this is
		// the only way to notice.
		if row.Trouble == revokedauth.TroublePaused &&
			now.Sub(time.UnixMilli(row.UpdatedAt)) < nowPlayingRetry {
			continue
		}
		s.publishOne(ctx, row, now)
	}
}

// publishOne brings one profile's entry up to date, making it and its
// share first if they are not there yet.
func (s *Server) publishOne(ctx context.Context, row store.RevokedLinkRow, now time.Time) {
	value := s.nowPlayingValue(row.AccountID)
	// Not only when there is nothing yet: a share granting a set of
	// entries other than the one this instance keeps serves the wrong
	// thing — an empty link, where it grants none — and is replaced.
	if row.RecordID == "" || row.LinkID == "" || row.LinkRecords != row.RecordID {
		updated, err := s.provisionNowPlaying(ctx, row)
		if err != nil {
			s.nowPlayingTrouble(ctx, row, err, now)
			return
		}
		row = updated
	}
	// Nothing new to say: the player has not moved, and their server is
	// asked nothing at all.
	if value == row.Published && row.Trouble == "" {
		return
	}
	if err := s.revoked.UpdateEntry(ctx, row.Server, row.Token, row.RecordID, value); err != nil {
		s.nowPlayingTrouble(ctx, row, err, now)
		return
	}
	row.Published, row.UpdatedAt = value, now.UnixMilli()
	if err := s.store.UpdateRevokedLinkEntry(ctx, row); err != nil {
		s.log.Error("update revoked link entry", "err", err)
	}
}

// provisionNowPlaying makes the entry and the share over it.
//
// A share serves the records it names and nothing else — a section on a
// link only groups them for whoever reads it — so the entry is named
// outright. A share that grants the wrong set is replaced rather than
// left to serve the wrong thing: that is what link_records is for, and it
// is how a link made before this was understood, granting nothing at all,
// repairs itself without the player being asked to approve anything again.
func (s *Server) provisionNowPlaying(ctx context.Context, row store.RevokedLinkRow) (store.RevokedLinkRow, error) {
	now := s.now()
	if row.RecordID == "" {
		key, value := nowPlayingKey, s.nowPlayingValue(row.AccountID)
		id, err := s.revoked.WriteEntry(ctx, row.Server, row.Token, key, nowPlayingLabel, value)
		if revokedauth.KeyTaken(err) {
			// The player already has an entry under that key, and an
			// entry this instance did not write is not its to change.
			key = nowPlayingKey + "_" + nowPlayingSuffix(s.cfg.PublicOrigin)
			id, err = s.revoked.WriteEntry(ctx, row.Server, row.Token, key, nowPlayingLabel, value)
		}
		if err != nil {
			return row, err
		}
		row.RecordID, row.RecordKey, row.Published = id, key, value
	}
	grants := row.RecordID
	if row.LinkID == "" || row.LinkRecords != grants {
		if row.LinkID != "" {
			// The old share stays in the player's app as a revoked one,
			// which is the honest record of what happened to it.
			if err := s.revoked.RevokeShare(ctx, row.Server, row.Token, row.LinkID); err != nil {
				s.log.Warn("revoke a now playing share that granted the wrong entries",
					"server", row.Server, "err", err)
			}
			row.LinkID, row.LinkURL = "", ""
		}
		id, link, err := s.revoked.CreateShare(ctx, row.Server, row.Token, nowPlayingShare,
			[]string{row.RecordID}, row.Section, row.AccountID)
		if err != nil {
			return row, err
		}
		row.LinkID, row.LinkURL, row.LinkRecords = id, link, grants
	}
	row.UpdatedAt = now.UnixMilli()
	if err := s.store.UpdateRevokedLinkEntry(ctx, row); err != nil {
		s.log.Error("update revoked link entry", "err", err)
		return row, err
	}
	return row, nil
}

// nowPlayingSuffix is what a key gets when the plain one is taken: this
// instance's host, folded to what a vault key may hold.
func nowPlayingSuffix(origin string) string {
	host := origin
	if u, err := url.Parse(origin); err == nil && u.Hostname() != "" {
		host = u.Hostname()
	}
	var b strings.Builder
	for _, c := range strings.ToLower(host) {
		switch {
		case c >= 'a' && c <= 'z', c >= '0' && c <= '9':
			b.WriteRune(c)
		case c == '.' || c == '-' || c == '_':
			b.WriteRune('_')
		}
	}
	key := strings.Trim(b.String(), "_")
	if key == "" {
		return "here"
	}
	return key
}

// nowPlayingTrouble writes down why a connection stopped working. A
// passing failure — their server is down, the network is out — is only
// logged: it will be tried again on the next pass.
func (s *Server) nowPlayingTrouble(ctx context.Context, row store.RevokedLinkRow, err error, now time.Time) {
	trouble := revokedauth.Trouble(err)
	if trouble == "" {
		s.log.Debug("now playing not written", "server", row.Server, "err", err)
		return
	}
	s.log.Info("now playing stopped", "server", row.Server, "trouble", trouble)
	if err := s.store.MarkRevokedLinkTrouble(ctx, row.AccountID, trouble, now.UnixMilli()); err != nil {
		s.log.Error("mark revoked link trouble", "err", err)
	}
}
