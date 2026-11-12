package server

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"
)

// revokedOn is the configuration of an instance that offers the sign-in.
// PUBLIC_ORIGIN is this instance's client id; the revoked server checks
// that the address it returns to sits on it.
var revokedOn = map[string]string{
	"ACCOUNTS":        "true",
	"REVOKED_SIGN_IN": "true",
	"PUBLIC_ORIGIN":   "https://poker.example",
}

func errCode(out map[string]any) string {
	e, ok := out["error"].(map[string]any)
	if !ok {
		return ""
	}
	code, _ := e["code"].(string)
	return code
}

func TestRevokedSignInOffByDefault(t *testing.T) {
	t.Parallel()
	// Profiles on, revoked off: the routes are not there and the client
	// is told so by /api/config rather than by a failed attempt.
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()

	status, cfg := h.request(http.MethodGet, "/api/config", "", nil)
	if status != http.StatusOK || cfg["revoked_sign_in"] != false {
		t.Fatalf("config: %d %v", status, cfg)
	}
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{
		"issuer": "revoked.example",
	})
	if status != http.StatusNotFound || errCode(out) != "revoked_sign_in_disabled" {
		t.Fatalf("start with revoked off: %d %v", status, out)
	}
}

func TestRevokedSignInAdvertised(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	status, cfg := h.request(http.MethodGet, "/api/config", "", nil)
	if status != http.StatusOK || cfg["revoked_sign_in"] != true {
		t.Fatalf("config: %d %v", status, cfg)
	}
	if cfg["revoked_default_server"] != "https://api.revoked.link" {
		t.Fatalf("default server: %v", cfg["revoked_default_server"])
	}
}

func TestRevokedStartRefusesBadAddresses(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	// Not an origin at all: refused before anything is fetched. An empty
	// address is not in the list - that is the app-link case, which is
	// the ordinary way in and needs no server.
	for _, issuer := range []string{"nope://a.example", "https://a.example/oidc", "ftp://a.example"} {
		status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{
			"issuer": issuer,
		})
		if status != http.StatusBadRequest || errCode(out) != "validation_failed" {
			t.Errorf("start %q: %d %v, want 400 validation_failed", issuer, status, out)
		}
	}
	// A private address is refused too: the player picks it, so without
	// this the form is a way to ask the server what it can reach.
	for _, issuer := range []string{"https://127.0.0.1", "https://10.0.0.1", "http://localhost:9"} {
		status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{
			"issuer": issuer,
		})
		if status != http.StatusBadGateway || errCode(out) != "revoked_server_unusable" {
			t.Errorf("start %q: %d %v, want 502 revoked_server_unusable", issuer, status, out)
		}
	}
}

func TestRevokedStartHonoursTheAllowList(t *testing.T) {
	t.Parallel()
	env := map[string]string{"REVOKED_ISSUERS": "https://only.example"}
	for k, v := range revokedOn {
		env[k] = v
	}
	h := newHarness(t, t.TempDir(), "", env)
	defer h.stop()

	status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{
		"issuer": "https://other.example",
	})
	if status != http.StatusBadGateway || errCode(out) != "revoked_server_unusable" {
		t.Fatalf("start off the allow-list: %d %v", status, out)
	}
}

// TestRevokedStartTakesTheServerFromTheQuery covers the official button,
// which posts a body of its own: the page that offers a choice of server
// puts the one the player picked in the start URL it hands the button, and
// it is judged exactly like one that came in the body.
func TestRevokedStartTakesTheServerFromTheQuery(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	status, out := h.request(http.MethodPost,
		"/api/accounts/revoked/start?issuer=nope%3A%2F%2Fa.example", "", map[string]string{})
	if status != http.StatusBadRequest || errCode(out) != "validation_failed" {
		t.Fatalf("start with a bad address in the query: %d %v", status, out)
	}

	status, out = h.request(http.MethodPost,
		"/api/accounts/revoked/start?issuer=https%3A%2F%2F127.0.0.1", "", map[string]string{})
	if status != http.StatusBadGateway || errCode(out) != "revoked_server_unusable" {
		t.Fatalf("start with a private address in the query: %d %v", status, out)
	}

	// A body that names one wins: the query is only there for a caller
	// that cannot write a body.
	status, out = h.request(http.MethodPost,
		"/api/accounts/revoked/start?issuer=https%3A%2F%2Fquery.example", "",
		map[string]string{"issuer": "nope://a.example"})
	if status != http.StatusBadRequest || errCode(out) != "validation_failed" {
		t.Fatalf("start with both: %d %v", status, out)
	}

	// Nothing either way is still the ordinary way in.
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/start?issuer=", "", map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("start with an empty query: %d %v", status, out)
	}
	if out["issuer"] != "" {
		t.Fatalf("issuer = %v, want empty", out["issuer"])
	}
}

func TestRevokedFinishAndClaimRefuseUnknownCodes(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	// A code that was never issued, or one already spent, is the same
	// answer: there is nothing to sign in to.
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/finish", "", map[string]string{
		"code": "not-a-real-code",
	})
	if status != http.StatusUnauthorized || errCode(out) != "revoked_sign_in_expired" {
		t.Fatalf("finish with an unknown code: %d %v", status, out)
	}
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/claim", "", map[string]string{
		"claim": "not-a-real-claim", "handle": "robin",
	})
	if status != http.StatusUnauthorized || errCode(out) != "revoked_sign_in_expired" {
		t.Fatalf("claim with an unknown claim: %d %v", status, out)
	}
	// The handle is checked before the claim is looked up, so a bad one
	// is a plain validation failure.
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/claim", "", map[string]string{
		"claim": "whatever", "handle": "no",
	})
	if status != http.StatusBadRequest || errCode(out) != "validation_failed" {
		t.Fatalf("claim with a short handle: %d %v", status, out)
	}
}

// TestRevokedCallbackWithoutAStateGoesBack checks the browser leg: every
// outcome is a redirect carrying a reason, never a bare error page.
func TestRevokedCallbackWithoutAStateGoesBack(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	client := &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	res, err := client.Get(h.base + "/api/accounts/revoked/callback?code=x&state=y")
	if err != nil {
		t.Fatalf("callback: %v", err)
	}
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode != http.StatusSeeOther {
		t.Fatalf("callback status = %d, want 303", res.StatusCode)
	}
	loc := res.Header.Get("Location")
	if want := "https://poker.example/?revoked_error=state_mismatch"; loc != want {
		t.Fatalf("Location = %q, want %q", loc, want)
	}
}

// TestRevokedStartWithoutAServer covers the ordinary way in: the player
// names no server, the app opens the request on whichever one they use,
// and the answer says which that was.
func TestRevokedStartWithoutAServer(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	for _, body := range []map[string]string{{}, {"issuer": ""}, {"issuer": "   "}} {
		status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", body)
		if status != http.StatusOK {
			t.Fatalf("start %v: %d %v", body, status, out)
		}
		link, _ := out["app_link"].(string)
		if !strings.HasPrefix(link, "revoked://signin?") {
			t.Fatalf("app_link = %q", link)
		}
		u, err := url.Parse(link)
		if err != nil {
			t.Fatalf("app_link does not parse: %v", err)
		}
		q := u.Query()
		want := map[string]string{
			"client_id":             "https://poker.example",
			"redirect_uri":          "https://poker.example/api/accounts/revoked/callback",
			"response_type":         "code",
			"scope":                 "openid",
			"claims":                `{"userinfo":{"revoked_links":{"values":["showdown_name"]}}}`,
			"code_challenge_method": "S256",
		}
		for k, v := range want {
			if q.Get(k) != v {
				t.Errorf("app_link %s = %q, want %q", k, q.Get(k), v)
			}
		}
		for _, k := range []string{"state", "nonce", "code_challenge"} {
			if q.Get(k) == "" {
				t.Errorf("app_link has no %s", k)
			}
		}
		// The page may be on another device, so the app must hand the
		// answer over itself.
		if q.Get("revoked_return") != "background" {
			t.Errorf("app_link revoked_return = %q", q.Get("revoked_return"))
		}
		// The key is the page's alone: nothing that travels through the QR
		// code may be enough to collect the result.
		wait, _ := out["wait"].(string)
		if wait == "" || strings.Contains(link, wait) {
			t.Errorf("wait = %q, link = %q", wait, link)
		}
		// Nothing was discovered, so no server is named yet.
		if out["issuer"] != "" {
			t.Errorf("start without a server named one: %v", out)
		}
		if code, _ := out["check_code"].(string); len(code) != 7 {
			t.Errorf("check_code = %q", code)
		}
	}
}

// TestRevokedCallbackNeedsAKnownIssuer: a sign-in started through the app
// learns its server from iss alone, so a missing or unusable iss must not
// get anywhere.
func TestRevokedCallbackNeedsAKnownIssuer(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	for _, iss := range []string{"", "not-an-origin", "https://a.example/path", "http://10.0.0.1"} {
		state, wait := startRevoked(t, h)
		code, loc := deliverRevoked(t, h, url.Values{"code": {"x"}, "state": {state}, "iss": {iss}})
		if code != http.StatusSeeOther || !strings.Contains(loc, "revoked_error=") {
			t.Errorf("iss %q: %d %s", iss, code, loc)
		}
		// The page hears the same, and no code to spend.
		status, out := h.request(http.MethodPost, "/api/accounts/revoked/wait", "", map[string]string{"wait": wait})
		if status != http.StatusOK || out["done"] != true || out["code"] != "" || out["error"] == "" {
			t.Errorf("iss %q: wait: %d %v", iss, status, out)
		}
	}
}

func startRevoked(t *testing.T, h *harness) (state, wait string) {
	t.Helper()
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("start: %d %v", status, out)
	}
	u, err := url.Parse(out["app_link"].(string))
	if err != nil {
		t.Fatalf("app_link: %v", err)
	}
	return u.Query().Get("state"), out["wait"].(string)
}

// deliverRevoked answers the way the Revoked app does from a phone: no
// cookies, and without following the redirect.
func deliverRevoked(t *testing.T, h *harness, q url.Values) (status int, location string) {
	t.Helper()
	client := &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	res, err := client.Get(h.base + "/api/accounts/revoked/callback?" + q.Encode())
	if err != nil {
		t.Fatalf("callback: %v", err)
	}
	defer func() { _ = res.Body.Close() }()
	return res.StatusCode, res.Header.Get("Location")
}

// TestRevokedPageWaitsForTheAnswer is the sign-in from a computer with the
// app on a phone. The two share nothing but the link in the QR code.
func TestRevokedPageWaitsForTheAnswer(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	env := map[string]string{"REVOKED_ALLOW_PRIVATE_NETWORK": "true"}
	for k, v := range revokedOn {
		env[k] = v
	}
	h := newHarness(t, t.TempDir(), "", env)
	defer h.stop()

	status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("start: %d %v", status, out)
	}
	wait := out["wait"].(string)
	link, _ := url.Parse(out["app_link"].(string))
	state := link.Query().Get("state")
	issuer.nonce = link.Query().Get("nonce")

	ask := func(key string) (int, map[string]any) {
		return h.request(http.MethodPost, "/api/accounts/revoked/wait", "", map[string]string{"wait": key})
	}
	if status, out := ask(wait); status != http.StatusOK || out["done"] != false {
		t.Fatalf("before the answer: %d %v", status, out)
	}
	// Reading the QR code off the screen is enough to answer, never to
	// collect: otherwise anyone behind the player could take the session.
	if status, out := ask(state); status != http.StatusUnauthorized || errCode(out) != "revoked_sign_in_expired" {
		t.Fatalf("collecting with the state: %d %v", status, out)
	}

	answer := url.Values{"code": {"auth-code"}, "state": {state}, "iss": {issuer.URL}}
	delivered, loc := deliverRevoked(t, h, answer)
	if delivered >= 400 || strings.Contains(loc, "revoked_error") {
		t.Fatalf("delivery: %d %s", delivered, loc)
	}
	// An answer is good once.
	if _, loc = deliverRevoked(t, h, answer); !strings.Contains(loc, "revoked_error=state_mismatch") {
		t.Fatalf("second delivery: %s", loc)
	}

	status, out = ask(wait)
	code, _ := out["code"].(string)
	if status != http.StatusOK || out["done"] != true || code == "" {
		t.Fatalf("after the answer: %d %v", status, out)
	}
	// The result is handed over once.
	if status, _ := ask(wait); status != http.StatusUnauthorized {
		t.Fatalf("collecting twice: %d", status)
	}

	status, out = h.request(http.MethodPost, "/api/accounts/revoked/finish", "", map[string]string{"code": code})
	if status != http.StatusOK || out["pending"] != true || out["issuer"] != issuer.URL {
		t.Fatalf("finish: %d %v", status, out)
	}
	if out["suggested_handle"] != "robin" || out["name"] != "Robin" {
		t.Errorf("the shared showdown_name did not reach the handle prompt: %v", out)
	}
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/claim", "", map[string]string{
		"claim": out["claim"].(string), "handle": "robin",
	})
	if status != http.StatusCreated || out["token"] == "" {
		t.Fatalf("claim: %d %v", status, out)
	}
}

// TestRevokedPageHearsADecline: declining from the phone must end the wait.
func TestRevokedPageHearsADecline(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	state, wait := startRevoked(t, h)
	deliverRevoked(t, h, url.Values{"error": {"access_denied"}, "state": {state}})
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/wait", "", map[string]string{"wait": wait})
	if status != http.StatusOK || out["done"] != true || out["error"] != "access_denied" {
		t.Fatalf("wait: %d %v", status, out)
	}
}

type fakeRevoked struct {
	*httptest.Server
	key   *rsa.PrivateKey
	nonce string

	// The connected-tool side: what a player's vault did with what this
	// instance wrote to it.
	mu sync.Mutex
	// connToken is handed out by /api/connect/token and expected back in
	// X-Revoked-Connection.
	connToken string
	// records are the entries written, by id, and keys says which key
	// each one was written under.
	records map[string]string
	keys    map[string]string
	// shares are the links made, by id: the address each one got, and the
	// record ids it grants. A share serves the records it names and
	// nothing else — naming a section only groups them for whoever reads
	// it — so the fake holds a link to exactly that, as the real server
	// does.
	shares  map[string]string
	grants  map[string][]string
	revoked map[string]bool
	// Switches a test flips to make the vault behave as a real one can.
	keyTaken     bool
	paused       bool
	noSection    bool
	disconnected bool
}

// vaultRecord is what the vault holds under the given key, for a test to
// check without reaching into the maps.
func (f *fakeRevoked) vaultRecord(key string) (string, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	for id, k := range f.keys {
		if k == key {
			return f.records[id], true
		}
	}
	return "", false
}

func (f *fakeRevoked) shareCount() (made, ended int) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.shares), len(f.revoked)
}

// resolve is what somebody opening a share's address is served: the values
// of the records it grants, in order. A revoked share serves nothing, and
// neither does one that granted nothing in the first place.
func (f *fakeRevoked) resolve(url string) []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	for id, address := range f.shares {
		if address != url || f.revoked[id] {
			continue
		}
		var out []string
		for _, rid := range f.grants[id] {
			if v, ok := f.records[rid]; ok {
				out = append(out, v)
			}
		}
		return out
	}
	return nil
}

// liveShare is the address of the one share that has not been revoked.
func (f *fakeRevoked) liveShare() string {
	f.mu.Lock()
	defer f.mu.Unlock()
	for id, address := range f.shares {
		if !f.revoked[id] {
			return address
		}
	}
	return ""
}

// newFakeRevoked stands in for a revoked instance: discovery, keys and a
// token endpoint that signs whatever nonce the sign-in started with.
func newFakeRevoked(t *testing.T) *fakeRevoked {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	f := &fakeRevoked{
		key: key, connToken: "connection-token",
		records: map[string]string{}, keys: map[string]string{},
		shares: map[string]string{}, grants: map[string][]string{}, revoked: map[string]bool{},
	}
	respond := func(w http.ResponseWriter, v any) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(v)
	}
	enc := func(v any) string {
		b, _ := json.Marshal(v)
		return base64.RawURLEncoding.EncodeToString(b)
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/openid-configuration", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, map[string]any{
			"issuer":                           f.URL,
			"authorization_endpoint":           f.URL + "/oidc/authorize",
			"token_endpoint":                   f.URL + "/oidc/token",
			"userinfo_endpoint":                f.URL + "/oidc/userinfo",
			"jwks_uri":                         f.URL + "/oidc/jwks",
			"code_challenge_methods_supported": []string{"S256"},
		})
	})
	mux.HandleFunc("/oidc/jwks", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, map[string]any{"keys": []map[string]any{{
			"kty": "RSA", "alg": "RS256", "use": "sig", "kid": "k",
			"n": base64.RawURLEncoding.EncodeToString(key.N.Bytes()),
			"e": base64.RawURLEncoding.EncodeToString([]byte{1, 0, 1}),
		}}})
	})
	mux.HandleFunc("/oidc/token", func(w http.ResponseWriter, _ *http.Request) {
		now := time.Now().Unix()
		signing := enc(map[string]any{"alg": "RS256", "typ": "JWT", "kid": "k"}) + "." + enc(map[string]any{
			"iss": f.URL, "sub": "subject-1", "aud": revokedOn["PUBLIC_ORIGIN"], "nonce": f.nonce,
			"iat": now, "exp": now + 300,
		})
		sum := sha256.Sum256([]byte(signing))
		sig, err := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, sum[:])
		if err != nil {
			t.Error(err)
		}
		respond(w, map[string]any{
			"access_token": "a", "token_type": "Bearer",
			"id_token": signing + "." + base64.RawURLEncoding.EncodeToString(sig),
		})
	})
	mux.HandleFunc("/oidc/userinfo", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, map[string]any{"sub": "subject-1", "revoked_links": map[string]any{
			"endpoint": f.URL + "/api/grants/resolve",
			"grants":   []map[string]any{{"id": "g1", "token": "t1", "keys": []string{"showdown_name"}}},
		}})
	})
	mux.HandleFunc("/api/grants/resolve", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, map[string]any{"items": []map[string]any{
			{"id": "g1", "status": "active", "values": map[string]string{"showdown_name": "Robin"}},
		}})
	})
	// ---- the connected-tool side ------------------------------------------
	//
	// A connection token is not a session: it is sent in its own header,
	// writes the section the tool was given, and manages the shares it
	// made. The fake holds it to exactly that.
	fail := func(w http.ResponseWriter, status int, code string) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_ = json.NewEncoder(w).Encode(map[string]any{"code": code, "message": code, "status": status})
	}
	// tool checks the token the way the real server does, including the
	// states a player can put the connection into from their app.
	tool := func(w http.ResponseWriter, r *http.Request) bool {
		if r.Header.Get("Authorization") != "" {
			t.Errorf("a connection token must not travel in Authorization")
		}
		f.mu.Lock()
		token, paused, gone := f.connToken, f.paused, f.disconnected
		f.mu.Unlock()
		switch {
		case r.Header.Get("X-Revoked-Connection") != token, gone:
			fail(w, http.StatusUnauthorized, "connection_unauthorized")
			return false
		case paused:
			fail(w, http.StatusForbidden, "connection_paused")
			return false
		}
		return true
	}
	connection := func() map[string]any {
		f.mu.Lock()
		defer f.mu.Unlock()
		section := "section-1"
		if f.noSection {
			section = ""
		}
		return map[string]any{
			"id": "conn-1", "clientId": revokedOn["PUBLIC_ORIGIN"], "clientName": "Showdown",
			"expiresAt":   time.Now().Add(90 * 24 * time.Hour).Format(time.RFC3339),
			"permissions": []string{"vault:write", "shares:manage"},
			"vaultAccess": "write", "section": section,
		}
	}
	mux.HandleFunc("POST /api/connect/token", func(w http.ResponseWriter, r *http.Request) {
		var body struct {
			Code, Verifier, RedirectURI string
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		if body.Code == "" || body.Verifier == "" {
			fail(w, http.StatusBadRequest, "connection_grant_invalid")
			return
		}
		f.mu.Lock()
		token := f.connToken
		f.mu.Unlock()
		respond(w, map[string]any{"token": token, "connection": connection()})
	})
	mux.HandleFunc("GET /api/connection", func(w http.ResponseWriter, r *http.Request) {
		if !tool(w, r) {
			return
		}
		respond(w, connection())
	})
	mux.HandleFunc("DELETE /api/connection", func(w http.ResponseWriter, r *http.Request) {
		if !tool(w, r) {
			return
		}
		f.mu.Lock()
		f.disconnected = true
		f.mu.Unlock()
		w.WriteHeader(http.StatusNoContent)
	})
	mux.HandleFunc("POST /api/vault", func(w http.ResponseWriter, r *http.Request) {
		if !tool(w, r) {
			return
		}
		var body struct {
			Key, Label, Value string
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		f.mu.Lock()
		// A key the player already uses is refused: an entry the tool did
		// not write is not its to take over.
		taken := f.keyTaken && body.Key == nowPlayingKey
		var id string
		if !taken {
			id = fmt.Sprintf("rec-%d", len(f.records)+1)
			f.records[id], f.keys[id] = body.Value, body.Key
		}
		f.mu.Unlock()
		if taken {
			fail(w, http.StatusConflict, "vault_key_taken")
			return
		}
		respond(w, map[string]any{"id": id, "key": body.Key, "label": body.Label})
	})
	mux.HandleFunc("PATCH /api/vault/{id}", func(w http.ResponseWriter, r *http.Request) {
		if !tool(w, r) {
			return
		}
		var body struct{ Value string }
		_ = json.NewDecoder(r.Body).Decode(&body)
		id := r.PathValue("id")
		f.mu.Lock()
		_, known := f.records[id]
		if known {
			f.records[id] = body.Value
		}
		f.mu.Unlock()
		if !known {
			fail(w, http.StatusNotFound, "record_not_found")
			return
		}
		respond(w, map[string]any{"id": id})
	})
	mux.HandleFunc("POST /api/connection/links", func(w http.ResponseWriter, r *http.Request) {
		if !tool(w, r) {
			return
		}
		var body struct {
			Label, Ref string
			Sections   []string
			Records    []string
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		f.mu.Lock()
		// A record out of reach answers 404, like a missing one.
		missing := false
		for _, rid := range body.Records {
			if _, ok := f.records[rid]; !ok {
				missing = true
			}
		}
		var id, address string
		if !missing {
			id = fmt.Sprintf("link-%d", len(f.shares)+1)
			address = fmt.Sprintf("%s/s/slug%d", f.URL, len(f.shares)+1)
			f.shares[id] = address
			f.grants[id] = append([]string{}, body.Records...)
		}
		f.mu.Unlock()
		if missing {
			fail(w, http.StatusNotFound, "record_not_found")
			return
		}
		respond(w, map[string]any{"id": id, "url": address, "label": body.Label, "ref": body.Ref})
	})
	mux.HandleFunc("POST /api/connection/links/{id}/revoke", func(w http.ResponseWriter, r *http.Request) {
		if !tool(w, r) {
			return
		}
		f.mu.Lock()
		defer f.mu.Unlock()
		f.revoked[r.PathValue("id")] = true
		respond(w, map[string]any{"id": r.PathValue("id"), "status": "revoked"})
	})

	f.Server = httptest.NewServer(mux)
	t.Cleanup(f.Close)
	return f
}
