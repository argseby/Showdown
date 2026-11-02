package server

import (
	"errors"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
	"unicode"

	"showdown/internal/account"
	"showdown/internal/protocol"
	"showdown/internal/revokedauth"
	"showdown/internal/store"
	"showdown/internal/table"
)

// revokedFlowLifetime is the player's time: find the phone, approve, come
// back. The page keeps asking for that long, and a phone browser that was
// put to sleep while the app was open may only ask again at the end of it.
const revokedFlowLifetime = 10 * time.Minute

// revokedScopes: the subject is what a profile is keyed on. No email is asked
// for — this server sends none, and a profile that needs no address should not
// collect one.
var revokedScopes = []string{"openid"}

// revokedNameKey is the vault entry asked for at sign-in. It is only a suggested
// handle, so a player who shares none is simply asked to type one.
const revokedNameKey = "showdown_name"

// revokedFlow is a sign-in that has been started and not yet come back.
type revokedFlow struct {
	issuer   string
	nonce    string
	verifier string
	wait     string
	expires  time.Time
}

// revokedWait is the page that started a sign-in, waiting for its result.
// The answer arrives from the Revoked app, usually on another device, so no
// cookie can tie the two together. The key does instead: state travels
// through the QR code and the phone, this one only ever goes to the page, so
// whoever reads the code off the screen can answer but cannot collect.
type revokedWait struct {
	done    bool
	code    string
	reason  string
	expires time.Time
}

// revokedHandoff is the finished sign-in waiting to be picked up by the
// page that started it. Either a session is ready, or the person has no
// profile here yet and has to choose a handle first.
type revokedHandoff struct {
	token   string // set when the identity is already linked
	account store.AccountRow

	// Set instead when this identity is new here.
	issuer    string
	subject   string
	name      string
	suggested string

	expires time.Time
}

// revokedFlows keeps both halves in memory. They live for minutes and a
// restart mid-sign-in costs the player one more tap, so they are not worth
// a table: nothing here outlives the flow it belongs to.
type revokedFlows struct {
	mu       sync.Mutex
	flows    map[string]*revokedFlow
	waits    map[string]*revokedWait
	handoffs map[string]*revokedHandoff
}

func newRevokedFlows() *revokedFlows {
	return &revokedFlows{
		flows:    map[string]*revokedFlow{},
		waits:    map[string]*revokedWait{},
		handoffs: map[string]*revokedHandoff{},
	}
}

func (f *revokedFlows) startFlow(state string, fl *revokedFlow) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sweep()
	f.flows[state] = fl
	f.waits[fl.wait] = &revokedWait{expires: fl.expires}
}

// takeFlow returns a flow and removes it: a state is good for one callback.
func (f *revokedFlows) takeFlow(state string, now time.Time) (*revokedFlow, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	fl, ok := f.flows[state]
	if !ok {
		return nil, false
	}
	delete(f.flows, state)
	if now.After(fl.expires) {
		return nil, false
	}
	return fl, true
}

// finishWait leaves the result for the page: a handoff code, or the reason
// there is none.
func (f *revokedFlows) finishWait(wait, code, reason string) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if w, ok := f.waits[wait]; ok {
		w.done, w.code, w.reason = true, code, reason
	}
}

// takeWait reports how a sign-in stands. A finished one is handed over once.
func (f *revokedFlows) takeWait(wait string, now time.Time) (revokedWait, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	w, ok := f.waits[wait]
	if !ok {
		return revokedWait{}, false
	}
	if now.After(w.expires) {
		delete(f.waits, wait)
		return revokedWait{}, false
	}
	if w.done {
		delete(f.waits, wait)
	}
	return *w, true
}

func (f *revokedFlows) putHandoff(code string, h *revokedHandoff) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sweep()
	f.handoffs[code] = h
}

// takeHandoff is single use, which is what keeps a code in a browser's
// history or a server log from signing anyone in a second time.
func (f *revokedFlows) takeHandoff(code string, now time.Time) (*revokedHandoff, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	h, ok := f.handoffs[code]
	if !ok {
		return nil, false
	}
	delete(f.handoffs, code)
	if now.After(h.expires) {
		return nil, false
	}
	return h, true
}

// peekHandoff reads without spending. The claim call uses it so that a
// handle somebody else already has costs the player a retype and not the
// whole sign-in.
func (f *revokedFlows) peekHandoff(code string, now time.Time) (*revokedHandoff, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	h, ok := f.handoffs[code]
	if !ok || now.After(h.expires) {
		return nil, false
	}
	return h, true
}

func (f *revokedFlows) dropHandoff(code string) {
	f.mu.Lock()
	defer f.mu.Unlock()
	delete(f.handoffs, code)
}

// sweep drops what has expired. Called under the lock on every write, so
// an abandoned sign-in cannot pile up.
func (f *revokedFlows) sweep() {
	now := time.Now()
	for k, v := range f.flows {
		if now.After(v.expires) {
			delete(f.flows, k)
		}
	}
	for k, v := range f.waits {
		if now.After(v.expires) {
			delete(f.waits, k)
		}
	}
	for k, v := range f.handoffs {
		if now.After(v.expires) {
			delete(f.handoffs, k)
		}
	}
}

// revokedOn refuses every route below on an instance that does not offer
// the sign-in.
func (s *Server) revokedOn(w http.ResponseWriter) bool {
	if !s.accountsOn(w) {
		return false
	}
	if s.revoked != nil {
		return true
	}
	writeError(w, http.StatusNotFound, protocol.ErrRevokedOff, "this instance does not offer sign-in with revoked")
	return false
}

type revokedStartRequest struct {
	Issuer string `json:"issuer"`
}

// handleRevokedStart prepares a sign-in for the page to show: a link that
// opens the Revoked app, on this device or as a QR code on a phone, and the
// key the page collects the result with. Nothing is created here: the
// profile, if there is to be one, is made when the revoked server vouches
// for them.
func (s *Server) handleRevokedStart(w http.ResponseWriter, r *http.Request) {
	if !s.revokedOn(w) {
		return
	}
	var req revokedStartRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	// No address is the ordinary case: the app knows which server the
	// person uses, and says so in the iss of the answer. An address only
	// narrows it: the answer then has to come from that server.
	var issuer string
	if strings.TrimSpace(req.Issuer) != "" {
		var err error
		if issuer, err = revokedauth.NormalizeIssuer(req.Issuer); err != nil {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
			return
		}
		if _, err = s.revoked.Discover(r.Context(), issuer); err != nil {
			var re *revokedauth.Error
			if errors.As(err, &re) {
				writeError(w, http.StatusBadGateway, protocol.ErrRevokedServer, re.Reason)
				return
			}
			s.log.Error("revoked discovery", "issuer", issuer, "err", err)
			writeError(w, http.StatusBadGateway, protocol.ErrRevokedServer, "that server could not be reached")
			return
		}
	}

	verifier, err := revokedauth.NewVerifier()
	if err != nil {
		s.log.Error("revoked verifier", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not start the sign-in")
		return
	}
	state, nonce, wait := newToken(), newToken(), newToken()
	challenge := revokedauth.Challenge(verifier)
	s.revokedFlows.startFlow(state, &revokedFlow{
		issuer: issuer, nonce: nonce, verifier: verifier, wait: wait,
		expires: s.now().Add(revokedFlowLifetime),
	})
	writeJSON(w, http.StatusOK, map[string]any{
		"app_link": revokedauth.AppLink(
			s.cfg.PublicOrigin, s.revokedRedirectURI(), state, nonce, challenge, revokedScopes, []string{revokedNameKey}),
		"wait":   wait,
		"issuer": issuer,
		// Shown next to the prompt in the app, so the player can see the
		// request they are approving is this one.
		"check_code": revokedauth.CheckCode(challenge),
	})
}

// revokedRedirectURI is where the Revoked app delivers its answer. It must
// sit on PublicOrigin, which is also this instance's client id.
func (s *Server) revokedRedirectURI() string {
	return s.cfg.PublicOrigin + "/api/accounts/revoked/callback"
}

// handleRevokedCallback takes the answer from the Revoked app and leaves the
// result for the page that is waiting. The app does not follow the redirect;
// it only matters if the app could not reach this server and handed the
// address to a browser instead, which then lands somewhere readable.
func (s *Server) handleRevokedCallback(w http.ResponseWriter, r *http.Request) {
	if s.revoked == nil || !s.cfg.Accounts {
		http.NotFound(w, r)
		return
	}
	q := r.URL.Query()
	flow, ok := s.revokedFlows.takeFlow(q.Get("state"), s.now())
	if !ok {
		s.revokedRedirect(w, r, url.Values{"revoked_error": {"state_mismatch"}})
		return
	}
	code, reason := s.revokedAnswer(r, flow, q)
	s.revokedFlows.finishWait(flow.wait, code, reason)
	if reason != "" {
		s.revokedRedirect(w, r, url.Values{"revoked_error": {reason}})
		return
	}
	s.revokedRedirect(w, r, nil)
}

// revokedAnswer turns the app's answer into a handoff code, or into the
// reason there is none.
func (s *Server) revokedAnswer(r *http.Request, flow *revokedFlow, q url.Values) (code, reason string) {
	// A refusal comes back here too; the page says so and offers to retry.
	if e := q.Get("error"); e != "" {
		return "", e
	}
	iss := q.Get("iss")
	// RFC 9207: the server names itself in the redirect.
	issuer := flow.issuer
	switch {
	case issuer != "":
		// Started against a named server, so it has to be that one. A
		// second revoked server must not answer a code meant for the
		// first.
		if iss != "" && iss != issuer {
			return "", "issuer_mismatch"
		}
	default:
		// Started through the app, so iss is the only thing that says
		// which server this is: it is required, and it is judged like
		// any address a player could have typed.
		norm, err := revokedauth.NormalizeIssuer(iss)
		if err != nil || norm != iss {
			return "", "issuer_mismatch"
		}
		// Discover checks the allow-list, refuses a private address and
		// an issuer that does not name itself, and pins every endpoint
		// to it.
		if _, err := s.revoked.Discover(r.Context(), norm); err != nil {
			s.log.Warn("revoked discovery from iss", "iss", norm, "err", err)
			return "", "unknown_server"
		}
		issuer = norm
	}
	authCode := q.Get("code")
	if authCode == "" {
		return "", "no_code"
	}

	tokens, err := s.revoked.Exchange(r.Context(), issuer, authCode, s.cfg.PublicOrigin, s.revokedRedirectURI(), flow.verifier)
	if err != nil {
		s.log.Warn("revoked exchange", "issuer", issuer, "err", err)
		return "", "exchange_failed"
	}
	claims, err := s.revoked.VerifyIDToken(r.Context(), issuer, tokens.IDToken, s.cfg.PublicOrigin, flow.nonce)
	if err != nil {
		s.log.Warn("revoked id_token", "issuer", issuer, "err", err)
		return "", "bad_identity"
	}

	handoff := &revokedHandoff{expires: s.now().Add(revokedFlowLifetime)}
	a, err := s.store.GetAccountByIdentity(r.Context(), claims.Issuer, claims.Subject)
	switch {
	case err == nil:
		token, err := s.createAccountSession(r.Context(), a.ID)
		if err != nil {
			s.log.Error("create account session", "err", err)
			return "", "internal"
		}
		handoff.token, handoff.account = token, a
	case errors.Is(err, store.ErrNotFound):
		// Nobody here yet. The profile is not created behind their back:
		// the app asks for a handle first, and that call makes it.
		handoff.issuer, handoff.subject = claims.Issuer, claims.Subject
		name, err := s.revoked.ReadEntry(r.Context(), issuer, tokens.AccessToken, revokedNameKey)
		if err != nil {
			s.log.Warn("revoked name entry", "issuer", issuer, "err", err)
		}
		handoff.name = name
		handoff.suggested = s.suggestHandle(r, name)
	default:
		s.log.Error("account by identity", "err", err)
		return "", "internal"
	}

	code = newToken()
	s.revokedFlows.putHandoff(code, handoff)
	return code, ""
}

func (s *Server) revokedRedirect(w http.ResponseWriter, r *http.Request, q url.Values) {
	target := s.cfg.PublicOrigin + "/"
	if len(q) > 0 {
		target += "?" + q.Encode()
	}
	http.Redirect(w, r, target, http.StatusSeeOther)
}

type revokedWaitRequest struct {
	Wait string `json:"wait"`
}

// handleRevokedWait is what the page asks while it shows the QR code.
func (s *Server) handleRevokedWait(w http.ResponseWriter, r *http.Request) {
	if !s.revokedOn(w) {
		return
	}
	var req revokedWaitRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	res, ok := s.revokedFlows.takeWait(req.Wait, s.now())
	if !ok {
		writeError(w, http.StatusUnauthorized, protocol.ErrRevokedState, "that sign-in is no longer valid")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"done": res.done, "code": res.code, "error": res.reason})
}

type revokedFinishRequest struct {
	Code string `json:"code"`
}

// handleRevokedFinish exchanges the handoff code for a session, or tells
// the app that this identity needs a handle before there is a profile.
func (s *Server) handleRevokedFinish(w http.ResponseWriter, r *http.Request) {
	if !s.revokedOn(w) {
		return
	}
	var req revokedFinishRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	h, ok := s.revokedFlows.takeHandoff(req.Code, s.now())
	if !ok {
		writeError(w, http.StatusUnauthorized, protocol.ErrRevokedState, "that sign-in is no longer valid")
		return
	}
	if h.token != "" {
		writeJSON(w, http.StatusOK, map[string]any{"token": h.token, "account": viewOf(h.account)})
		return
	}
	// Still unclaimed: hand the code straight back so the app can post it
	// again with the chosen handle.
	claim := newToken()
	h.expires = s.now().Add(revokedFlowLifetime)
	s.revokedFlows.putHandoff(claim, h)
	writeJSON(w, http.StatusOK, map[string]any{
		"pending":          true,
		"claim":            claim,
		"issuer":           h.issuer,
		"suggested_handle": h.suggested,
		"name":             h.name,
	})
}

type revokedClaimRequest struct {
	Claim       string `json:"claim"`
	Handle      string `json:"handle"`
	DisplayName string `json:"display_name"`
}

// handleRevokedClaim makes the profile for a revoked identity that has
// none here. It is the same profile a sign-up makes, minus the password:
// the revoked server is how this person proves who they are, so there is
// nothing here to forget and no recovery code to lose.
func (s *Server) handleRevokedClaim(w http.ResponseWriter, r *http.Request) {
	if !s.revokedOn(w) {
		return
	}
	var req revokedClaimRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := account.ValidateHandle(req.Handle); err != nil {
		writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
		return
	}
	h, ok := s.revokedFlows.peekHandoff(req.Claim, s.now())
	if !ok || h.subject == "" {
		writeError(w, http.StatusUnauthorized, protocol.ErrRevokedState, "that sign-in is no longer valid")
		return
	}
	display := req.Handle
	if req.DisplayName != "" {
		name, err := table.NormalizeName(req.DisplayName)
		if err != nil {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, "invalid display name")
			return
		}
		display = name
	}
	now := s.now().UnixMilli()
	row := store.AccountRow{
		ID: account.NewID(), Handle: req.Handle, HandleKey: account.Key(req.Handle),
		DisplayName: display,
		// No password and no recovery code: internal/server refuses a
		// password sign-in for a row with an empty hash, so this profile
		// is reachable only through the revoked server that vouched.
		PasswordHash: "", RecoveryHash: "",
		CreatedAt:  now,
		VisProfile: visFriends, VisWinnings: visFriends, VisBestHands: visFriends,
		VisAchievements: visFriends, VisActivity: visFriends,
	}
	ident := store.AccountIdentityRow{
		Issuer: h.issuer, Subject: h.subject, CreatedAt: now, Name: h.name,
	}
	if err := s.store.CreateAccountWithIdentity(r.Context(), row, ident); err != nil {
		switch {
		case errors.Is(err, store.ErrHandleTaken):
			// The claim is still good: the player picks another name
			// without signing in again.
			writeError(w, http.StatusConflict, protocol.ErrHandleTaken, "that name is taken")
		case errors.Is(err, store.ErrIdentityLinked):
			s.revokedFlows.dropHandoff(req.Claim)
			writeError(w, http.StatusConflict, protocol.ErrRevokedState, "that identity already has a profile here")
		default:
			s.log.Error("create account with identity", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not create the profile")
		}
		return
	}
	s.revokedFlows.dropHandoff(req.Claim)
	token, err := s.createAccountSession(r.Context(), row.ID)
	if err != nil {
		s.log.Error("create account session", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not sign in")
		return
	}
	s.audit(r, "account_created", "", "", map[string]any{"handle": row.Handle, "revoked": h.issuer})
	writeJSON(w, http.StatusCreated, map[string]any{"token": token, "account": viewOf(row)})
}

// suggestHandle turns the name the revoked server shared into something a
// handle may be: a–z, 0–9 and _, three to twenty of them. It is only a
// suggestion — the player sees it in a field and can replace it — so a
// name that survives none of this simply yields nothing.
func (s *Server) suggestHandle(r *http.Request, name string) string {
	var b strings.Builder
	for _, c := range strings.ToLower(name) {
		switch {
		case c >= 'a' && c <= 'z', unicode.IsDigit(c):
			b.WriteRune(c)
		case c == ' ' || c == '_' || c == '-' || c == '.':
			if b.Len() > 0 && !strings.HasSuffix(b.String(), "_") {
				b.WriteRune('_')
			}
		}
		if b.Len() >= account.HandleMaxLen {
			break
		}
	}
	h := strings.Trim(b.String(), "_")
	if account.ValidateHandle(h) != nil {
		return ""
	}
	// Taken is not an error here; the field just comes up empty rather
	// than suggesting something the player cannot have.
	if _, err := s.store.GetAccountByHandle(r.Context(), account.Key(h)); err == nil {
		return ""
	}
	return h
}
