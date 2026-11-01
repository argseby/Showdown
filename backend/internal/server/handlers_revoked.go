package server

import (
	"crypto/subtle"
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

// How long each half of the sign-in may take. The first is the player's
// time: find the phone, approve, come back. The second is a redirect and a
// fetch by a page that is already open, so it is short on purpose — the
// handoff code rides in a URL the browser keeps in its history.
const (
	revokedFlowLifetime    = 10 * time.Minute
	revokedHandoffLifetime = 2 * time.Minute
	// revokedCookie carries the state so the callback can tell that the
	// browser coming back is the one that left. The revoked spec asks for
	// exactly this; it is the only cookie this server sets.
	revokedCookie = "showdown_revoked"
)

// revokedScopes: the subject is what a profile is keyed on and the name is
// only a suggested handle. No email is asked for — this server sends none,
// and a profile that needs no address should not collect one.
var revokedScopes = []string{"openid", "profile"}

// revokedFlow is a sign-in that has been started and not yet come back.
type revokedFlow struct {
	issuer   string
	nonce    string
	verifier string
	expires  time.Time
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
	handoffs map[string]*revokedHandoff
}

func newRevokedFlows() *revokedFlows {
	return &revokedFlows{flows: map[string]*revokedFlow{}, handoffs: map[string]*revokedHandoff{}}
}

func (f *revokedFlows) startFlow(state string, fl *revokedFlow) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sweep()
	f.flows[state] = fl
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

// handleRevokedStart turns the address a player typed into the link their
// browser follows. Nothing is created here: the profile, if there is to be
// one, is made when the revoked server vouches for them.
func (s *Server) handleRevokedStart(w http.ResponseWriter, r *http.Request) {
	if !s.revokedOn(w) {
		return
	}
	var req revokedStartRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	// No address is the ordinary case: the app knows which server the
	// person uses, and says so in the iss of the answer. An address is
	// the fallback, for a player who wants a particular server or whose
	// app is not on this device.
	var issuer string
	var md revokedauth.Metadata
	if strings.TrimSpace(req.Issuer) != "" {
		var err error
		if issuer, err = revokedauth.NormalizeIssuer(req.Issuer); err != nil {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
			return
		}
		if md, err = s.revoked.Discover(r.Context(), issuer); err != nil {
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
	state, nonce := newToken(), newToken()
	challenge := revokedauth.Challenge(verifier)
	// The app link needs no server: it carries the request itself.
	appLink := revokedauth.AppLink(
		s.cfg.PublicOrigin, s.revokedRedirectURI(), state, nonce, challenge, revokedScopes)
	var authURL string
	if issuer != "" {
		var err error
		authURL, err = revokedauth.AuthorizeURL(
			md, s.cfg.PublicOrigin, s.revokedRedirectURI(), state, nonce, challenge, revokedScopes)
		if err != nil {
			s.log.Error("revoked authorize url", "issuer", issuer, "err", err)
			writeError(w, http.StatusBadGateway, protocol.ErrRevokedServer, "that server published an unusable address")
			return
		}
	}
	s.revokedFlows.startFlow(state, &revokedFlow{
		issuer: issuer, nonce: nonce, verifier: verifier,
		expires: s.now().Add(revokedFlowLifetime),
	})
	http.SetCookie(w, &http.Cookie{
		Name:     revokedCookie,
		Value:    state,
		Path:     "/api/accounts/revoked",
		MaxAge:   int(revokedFlowLifetime / time.Second),
		HttpOnly: true,
		Secure:   strings.HasPrefix(s.cfg.PublicOrigin, "https://"),
		// Lax, not Strict: the player comes back by following a link from
		// the revoked app, and Strict would withhold the cookie exactly
		// then. Lax still keeps it off cross-site POSTs.
		SameSite: http.SameSiteLaxMode,
	})
	writeJSON(w, http.StatusOK, map[string]any{
		// The app link always works; authorize_url is set only when the
		// player named a server, and sends the browser there instead.
		"app_link":      appLink,
		"authorize_url": authURL,
		"issuer":        issuer,
		// Shown next to the prompt in the app, so the player can see the
		// request they are approving is this one.
		"check_code": revokedauth.CheckCode(challenge),
	})
}

// revokedRedirectURI is where the revoked server sends the player back. It
// must sit on PublicOrigin, which is also this instance's client id.
func (s *Server) revokedRedirectURI() string {
	return s.cfg.PublicOrigin + "/api/accounts/revoked/callback"
}

// handleRevokedCallback is the address the revoked app returns to. It is a
// browser navigation, not an API call, so every outcome ends in a redirect
// back to the app with a code it can exchange.
func (s *Server) handleRevokedCallback(w http.ResponseWriter, r *http.Request) {
	if s.revoked == nil || !s.cfg.Accounts {
		http.NotFound(w, r)
		return
	}
	q := r.URL.Query()
	// A refusal comes back here too; the app says so and offers to retry.
	if e := q.Get("error"); e != "" {
		s.revokedFail(w, r, e)
		return
	}
	state, code, iss := q.Get("state"), q.Get("code"), q.Get("iss")
	cookie, err := r.Cookie(revokedCookie)
	s.clearRevokedCookie(w)
	if err != nil || state == "" || subtle.ConstantTimeCompare([]byte(cookie.Value), []byte(state)) != 1 {
		s.revokedFail(w, r, "state_mismatch")
		return
	}
	flow, ok := s.revokedFlows.takeFlow(state, s.now())
	if !ok {
		s.revokedFail(w, r, "expired")
		return
	}
	// RFC 9207: the server names itself in the redirect.
	issuer := flow.issuer
	switch {
	case issuer != "":
		// Started against a named server, so it has to be that one. A
		// second revoked server must not answer a code meant for the
		// first.
		if iss != "" && iss != issuer {
			s.revokedFail(w, r, "issuer_mismatch")
			return
		}
	default:
		// Started through the app, so iss is the only thing that says
		// which server this is: it is required, and it is judged like
		// any address a player could have typed.
		norm, err := revokedauth.NormalizeIssuer(iss)
		if err != nil || norm != iss {
			s.revokedFail(w, r, "issuer_mismatch")
			return
		}
		// Discover checks the allow-list, refuses a private address and
		// an issuer that does not name itself, and pins every endpoint
		// to it.
		if _, err := s.revoked.Discover(r.Context(), norm); err != nil {
			s.log.Warn("revoked discovery from iss", "iss", norm, "err", err)
			s.revokedFail(w, r, "unknown_server")
			return
		}
		issuer = norm
	}
	if code == "" {
		s.revokedFail(w, r, "no_code")
		return
	}

	tokens, err := s.revoked.Exchange(r.Context(), issuer, code, s.cfg.PublicOrigin, s.revokedRedirectURI(), flow.verifier)
	if err != nil {
		s.log.Warn("revoked exchange", "issuer", issuer, "err", err)
		s.revokedFail(w, r, "exchange_failed")
		return
	}
	claims, err := s.revoked.VerifyIDToken(r.Context(), issuer, tokens.IDToken, s.cfg.PublicOrigin, flow.nonce)
	if err != nil {
		s.log.Warn("revoked id_token", "issuer", issuer, "err", err)
		s.revokedFail(w, r, "bad_identity")
		return
	}

	handoff := &revokedHandoff{expires: s.now().Add(revokedHandoffLifetime)}
	a, err := s.store.GetAccountByIdentity(r.Context(), claims.Issuer, claims.Subject)
	switch {
	case err == nil:
		token, err := s.createAccountSession(r.Context(), a.ID)
		if err != nil {
			s.log.Error("create account session", "err", err)
			s.revokedFail(w, r, "internal")
			return
		}
		handoff.token, handoff.account = token, a
	case errors.Is(err, store.ErrNotFound):
		// Nobody here yet. The profile is not created behind their back:
		// the app asks for a handle first, and that call makes it.
		handoff.issuer, handoff.subject = claims.Issuer, claims.Subject
		handoff.name = claims.Name
		handoff.suggested = s.suggestHandle(r, claims.Name)
	default:
		s.log.Error("account by identity", "err", err)
		s.revokedFail(w, r, "internal")
		return
	}

	hc := newToken()
	s.revokedFlows.putHandoff(hc, handoff)
	s.revokedRedirect(w, r, url.Values{"revoked": {hc}})
}

func (s *Server) revokedFail(w http.ResponseWriter, r *http.Request, reason string) {
	s.revokedRedirect(w, r, url.Values{"revoked_error": {reason}})
}

// revokedRedirect sends the browser back to the app. The app reads the
// parameter, acts on it and takes it out of the address bar.
func (s *Server) revokedRedirect(w http.ResponseWriter, r *http.Request, q url.Values) {
	http.Redirect(w, r, s.cfg.PublicOrigin+"/?"+q.Encode(), http.StatusSeeOther)
}

func (s *Server) clearRevokedCookie(w http.ResponseWriter) {
	http.SetCookie(w, &http.Cookie{
		Name: revokedCookie, Value: "", Path: "/api/accounts/revoked", MaxAge: -1,
		HttpOnly: true, Secure: strings.HasPrefix(s.cfg.PublicOrigin, "https://"),
		SameSite: http.SameSiteLaxMode,
	})
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
