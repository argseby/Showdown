package server

import (
	"net/http"
	"net/url"
	"strings"
	"testing"
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
			"scope":                 "openid profile",
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
		// Nothing was discovered, so no server is named yet.
		if out["issuer"] != "" || out["authorize_url"] != "" {
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

	status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("start: %d %v", status, out)
	}
	u, _ := url.Parse(out["app_link"].(string))
	state := u.Query().Get("state")

	client := &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	for _, iss := range []string{"", "not-an-origin", "https://a.example/path", "http://10.0.0.1"} {
		req, err := http.NewRequest(http.MethodGet,
			h.base+"/api/accounts/revoked/callback?code=x&state="+url.QueryEscape(state)+
				"&iss="+url.QueryEscape(iss), nil)
		if err != nil {
			t.Fatal(err)
		}
		req.AddCookie(&http.Cookie{Name: "showdown_revoked", Value: state})
		res, err := client.Do(req)
		if err != nil {
			t.Fatalf("callback: %v", err)
		}
		_ = res.Body.Close()
		loc := res.Header.Get("Location")
		if res.StatusCode != http.StatusSeeOther || !strings.Contains(loc, "revoked_error=") {
			t.Errorf("iss %q: %d %s", iss, res.StatusCode, loc)
		}
		if strings.Contains(loc, "revoked=") && !strings.Contains(loc, "revoked_error=") {
			t.Errorf("iss %q was accepted: %s", iss, loc)
		}
	}
}
