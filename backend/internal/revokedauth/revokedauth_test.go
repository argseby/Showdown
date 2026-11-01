package revokedauth

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestNormalizeIssuer(t *testing.T) {
	ok := map[string]string{
		"revoked.example":          "https://revoked.example",
		"https://revoked.example":  "https://revoked.example",
		"https://revoked.example/": "https://revoked.example",
		"https://REVOKED.example":  "https://revoked.example",
		"  revoked.example  ":      "https://revoked.example",
		"https://rev.example:8443": "https://rev.example:8443",
		"http://localhost:8090":    "http://localhost:8090",
	}
	for in, want := range ok {
		got, err := NormalizeIssuer(in)
		if err != nil {
			t.Errorf("NormalizeIssuer(%q): %v", in, err)
			continue
		}
		if got != want {
			t.Errorf("NormalizeIssuer(%q) = %q, want %q", in, got, want)
		}
	}
	// A path or a query would make two spellings of one issuer, and the
	// issuer is half of what a profile is keyed on.
	for _, in := range []string{
		"", "   ", "ftp://revoked.example", "https://", "https://a.example/oidc",
		"https://a.example?x=1", "https://a.example#f", "https://u:p@a.example",
	} {
		if got, err := NormalizeIssuer(in); err == nil {
			t.Errorf("NormalizeIssuer(%q) = %q, want an error", in, got)
		}
	}
}

func TestChallengeAndCheckCode(t *testing.T) {
	// RFC 7636 B: the worked example from the spec.
	const verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
	if got, want := Challenge(verifier), "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"; got != want {
		t.Errorf("Challenge = %q, want %q", got, want)
	}
	code := CheckCode("whatever")
	if len(code) != 7 || code[3] != '-' {
		t.Fatalf("CheckCode = %q, want NNN-NNN", code)
	}
	if code != CheckCode("whatever") {
		t.Error("CheckCode is not stable")
	}
	if code == CheckCode("something else") {
		t.Error("CheckCode does not depend on the challenge")
	}
}

func TestNewVerifierIsUnique(t *testing.T) {
	seen := map[string]bool{}
	for range 100 {
		v, err := NewVerifier()
		if err != nil {
			t.Fatalf("NewVerifier: %v", err)
		}
		if len(v) != 43 {
			t.Fatalf("verifier is %d characters, want 43", len(v))
		}
		if seen[v] {
			t.Fatal("NewVerifier repeated itself")
		}
		seen[v] = true
	}
}

// signer is a revoked server's signing key for the tests below.
type signer struct {
	key *rsa.PrivateKey
	kid string
}

func newSigner(t *testing.T) *signer {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate key: %v", err)
	}
	return &signer{key: k, kid: "test-key"}
}

func (s *signer) jwks() map[string]any {
	return map[string]any{"keys": []map[string]any{{
		"kty": "RSA", "alg": "RS256", "use": "sig", "kid": s.kid,
		"n": base64.RawURLEncoding.EncodeToString(s.key.N.Bytes()),
		"e": base64.RawURLEncoding.EncodeToString([]byte{1, 0, 1}),
	}}}
}

func (s *signer) token(t *testing.T, claims map[string]any) string {
	t.Helper()
	return s.tokenWithHeader(t, map[string]any{"alg": "RS256", "typ": "JWT", "kid": s.kid}, claims)
}

func (s *signer) tokenWithHeader(t *testing.T, header, claims map[string]any) string {
	t.Helper()
	enc := func(v any) string {
		b, err := json.Marshal(v)
		if err != nil {
			t.Fatalf("marshal: %v", err)
		}
		return base64.RawURLEncoding.EncodeToString(b)
	}
	signing := enc(header) + "." + enc(claims)
	sum := sha256.Sum256([]byte(signing))
	sig, err := rsa.SignPKCS1v15(rand.Reader, s.key, crypto.SHA256, sum[:])
	if err != nil {
		t.Fatalf("sign: %v", err)
	}
	return signing + "." + base64.RawURLEncoding.EncodeToString(sig)
}

// revokedServer is a stand-in for a revoked instance: discovery, keys and
// a token endpoint, all on one origin.
type revokedServer struct {
	*httptest.Server
	sign *signer
	// issuerOverride makes the discovery document claim a different name.
	issuerOverride string
	// jwksOverride moves the key set off this origin.
	jwksOverride string
	tokenBody    func() (int, string)
}

func newRevokedServer(t *testing.T) *revokedServer {
	t.Helper()
	rs := &revokedServer{sign: newSigner(t)}
	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/openid-configuration", func(w http.ResponseWriter, r *http.Request) {
		iss := rs.URL
		if rs.issuerOverride != "" {
			iss = rs.issuerOverride
		}
		jwks := rs.URL + "/oidc/jwks"
		if rs.jwksOverride != "" {
			jwks = rs.jwksOverride
		}
		writeJSON(w, map[string]any{
			"issuer":                           iss,
			"authorization_endpoint":           rs.URL + "/oidc/authorize",
			"token_endpoint":                   rs.URL + "/oidc/token",
			"jwks_uri":                         jwks,
			"userinfo_endpoint":                rs.URL + "/oidc/userinfo",
			"code_challenge_methods_supported": []string{"S256"},
			"subject_types_supported":          []string{"pairwise"},
		})
	})
	mux.HandleFunc("/oidc/jwks", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, rs.sign.jwks())
	})
	mux.HandleFunc("/oidc/token", func(w http.ResponseWriter, r *http.Request) {
		if rs.tokenBody != nil {
			status, body := rs.tokenBody()
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(status)
			_, _ = w.Write([]byte(body))
			return
		}
		http.Error(w, "not configured", http.StatusInternalServerError)
	})
	rs.Server = httptest.NewServer(mux)
	t.Cleanup(rs.Close)
	return rs
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

// testClient allows the loopback address the httptest server runs on.
func testClient(t *testing.T, opts Options) *Client {
	t.Helper()
	opts.AllowPrivateNetwork = true
	c, err := New(opts)
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	return c
}

func TestDiscoverRejectsAnImpostor(t *testing.T) {
	rs := newRevokedServer(t)
	rs.issuerOverride = "https://somewhere.else"
	c := testClient(t, Options{})

	_, err := c.Discover(context.Background(), rs.URL)
	if err == nil {
		t.Fatal("a document naming another issuer was accepted")
	}
	if !strings.Contains(err.Error(), "calls itself") {
		t.Errorf("unexpected error: %v", err)
	}
}

func TestDiscoverPinsEndpointsToTheIssuer(t *testing.T) {
	// A discovery document is served by the very server being judged, so
	// an endpoint it places elsewhere must not be followed.
	elsewhere := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	t.Cleanup(elsewhere.Close)

	rs := newRevokedServer(t)
	rs.jwksOverride = elsewhere.URL + "/oidc/jwks"
	c := testClient(t, Options{})

	if _, err := c.Discover(context.Background(), rs.URL); err == nil {
		t.Fatal("an off-origin jwks_uri was accepted")
	}
}

func TestDiscoverHonoursTheAllowList(t *testing.T) {
	rs := newRevokedServer(t)
	c := testClient(t, Options{Issuers: []string{"https://only.example"}})

	if c.Allowed(rs.URL) {
		t.Fatal("Allowed said yes to a server not on the list")
	}
	if _, err := c.Discover(context.Background(), rs.URL); err == nil {
		t.Fatal("a server off the allow-list was discovered")
	}
	if !c.Allowed("https://only.example") {
		t.Error("Allowed said no to the listed server")
	}
}

func TestPrivateAddressesAreRefused(t *testing.T) {
	// Without AllowPrivateNetwork the sign-in form must not become a way
	// to ask this server what it can reach.
	c, err := New(Options{})
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	for _, issuer := range []string{
		"https://127.0.0.1", "https://localhost", "https://10.0.0.5",
		"https://192.168.1.1", "https://[::1]", "https://169.254.1.1",
	} {
		if _, err := c.Discover(context.Background(), issuer); err == nil {
			t.Errorf("Discover(%q) was allowed", issuer)
		}
	}
	// Plain http is refused as well.
	if _, err := c.Discover(context.Background(), "http://revoked.example"); err == nil {
		t.Error("an http issuer was allowed")
	}
}

func TestExchangeAndVerify(t *testing.T) {
	rs := newRevokedServer(t)
	const clientID = "https://poker.example"
	const nonce = "n-0S6_WzA2Mj"

	rs.tokenBody = func() (int, string) {
		id := rs.sign.token(t, map[string]any{
			"iss": rs.URL, "sub": "pairwise-subject", "aud": clientID,
			"exp": time.Now().Add(5 * time.Minute).Unix(), "iat": time.Now().Unix(),
			"nonce": nonce, "name": "Robin",
		})
		return http.StatusOK, fmt.Sprintf(
			`{"access_token":"at","token_type":"Bearer","expires_in":600,"id_token":%q,"scope":"openid profile"}`, id)
	}
	c := testClient(t, Options{})

	tok, err := c.Exchange(context.Background(), rs.URL, "the-code", clientID, clientID+"/cb", "verifier")
	if err != nil {
		t.Fatalf("Exchange: %v", err)
	}
	claims, err := c.VerifyIDToken(context.Background(), rs.URL, tok.IDToken, clientID, nonce)
	if err != nil {
		t.Fatalf("VerifyIDToken: %v", err)
	}
	if claims.Subject != "pairwise-subject" || claims.Issuer != rs.URL || claims.Name != "Robin" {
		t.Fatalf("claims = %+v", claims)
	}
}

func TestExchangeReportsTheServersRefusal(t *testing.T) {
	rs := newRevokedServer(t)
	rs.tokenBody = func() (int, string) {
		return http.StatusBadRequest, `{"error":"invalid_grant","error_description":"spent"}`
	}
	c := testClient(t, Options{})

	_, err := c.Exchange(context.Background(), rs.URL, "used", "https://poker.example", "https://poker.example/cb", "v")
	if err == nil {
		t.Fatal("a refused exchange returned no error")
	}
	if !strings.Contains(err.Error(), "invalid_grant") {
		t.Errorf("error does not name the reason: %v", err)
	}
}

// TestIDTokenIsCheckedProperly covers the ways a token that verifies
// cryptographically can still be the wrong token.
func TestIDTokenIsCheckedProperly(t *testing.T) {
	rs := newRevokedServer(t)
	const clientID = "https://poker.example"
	const nonce = "nonce-1"
	c := testClient(t, Options{})
	if _, err := c.Discover(context.Background(), rs.URL); err != nil {
		t.Fatalf("Discover: %v", err)
	}
	good := func() map[string]any {
		return map[string]any{
			"iss": rs.URL, "sub": "s", "aud": clientID,
			"exp": time.Now().Add(5 * time.Minute).Unix(), "iat": time.Now().Unix(),
			"nonce": nonce,
		}
	}
	bad := map[string]func(map[string]any){
		"another audience":  func(m map[string]any) { m["aud"] = "https://other.example" },
		"another issuer":    func(m map[string]any) { m["iss"] = "https://other.example" },
		"no subject":        func(m map[string]any) { delete(m, "sub") },
		"expired":           func(m map[string]any) { m["exp"] = time.Now().Add(-2 * time.Hour).Unix() },
		"no expiry":         func(m map[string]any) { delete(m, "exp") },
		"issued in future":  func(m map[string]any) { m["iat"] = time.Now().Add(2 * time.Hour).Unix() },
		"replayed nonce":    func(m map[string]any) { m["nonce"] = "someone else's" },
		"no nonce returned": func(m map[string]any) { delete(m, "nonce") },
	}
	for name, spoil := range bad {
		claims := good()
		spoil(claims)
		if _, err := c.VerifyIDToken(context.Background(), rs.URL, rs.sign.token(t, claims), clientID, nonce); err == nil {
			t.Errorf("%s: token was accepted", name)
		}
	}
	// The unspoiled one must still pass, or the table above proves nothing.
	if _, err := c.VerifyIDToken(context.Background(), rs.URL, rs.sign.token(t, good()), clientID, nonce); err != nil {
		t.Fatalf("a good token was refused: %v", err)
	}
	// A list audience is legal and must be accepted.
	listed := good()
	listed["aud"] = []string{"https://other.example", clientID}
	if _, err := c.VerifyIDToken(context.Background(), rs.URL, rs.sign.token(t, listed), clientID, nonce); err != nil {
		t.Errorf("an aud list containing us was refused: %v", err)
	}
}

// TestAlgorithmIsPinned is the classic JWT forgery: swap the algorithm for
// "none", or for an HMAC keyed with the public key, and see if it passes.
func TestAlgorithmIsPinned(t *testing.T) {
	rs := newRevokedServer(t)
	const clientID = "https://poker.example"
	c := testClient(t, Options{})
	if _, err := c.Discover(context.Background(), rs.URL); err != nil {
		t.Fatalf("Discover: %v", err)
	}
	claims := map[string]any{
		"iss": rs.URL, "sub": "s", "aud": clientID,
		"exp": time.Now().Add(5 * time.Minute).Unix(),
	}
	enc := func(v any) string {
		b, _ := json.Marshal(v)
		return base64.RawURLEncoding.EncodeToString(b)
	}
	for _, alg := range []string{"none", "HS256", "RS512", ""} {
		raw := enc(map[string]any{"alg": alg, "kid": rs.sign.kid}) + "." + enc(claims) + "."
		if _, err := c.VerifyIDToken(context.Background(), rs.URL, raw, clientID, ""); err == nil {
			t.Errorf("alg %q was accepted", alg)
		}
	}
	// A real RS256 header but a signature from the wrong key.
	other := newSigner(t)
	other.kid = rs.sign.kid
	if _, err := c.VerifyIDToken(context.Background(), rs.URL, other.token(t, claims), clientID, ""); err == nil {
		t.Error("a token signed by a stranger was accepted")
	}
}

func TestUnknownKeyIsNotRefetchedEveryTime(t *testing.T) {
	rs := newRevokedServer(t)
	var fetches int
	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/openid-configuration", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]any{
			"issuer": rs.URL, "authorization_endpoint": rs.URL + "/a",
			"token_endpoint": rs.URL + "/t", "jwks_uri": rs.URL + "/oidc/jwks",
		})
	})
	mux.HandleFunc("/oidc/jwks", func(w http.ResponseWriter, r *http.Request) {
		fetches++
		writeJSON(w, rs.sign.jwks())
	})
	rs.Config.Handler = mux

	c := testClient(t, Options{})
	claims := map[string]any{"iss": rs.URL, "sub": "s", "aud": "https://poker.example",
		"exp": time.Now().Add(time.Minute).Unix()}
	forged := rs.sign.tokenWithHeader(t,
		map[string]any{"alg": "RS256", "kid": "no-such-key"}, claims)

	for range 5 {
		if _, err := c.VerifyIDToken(context.Background(), rs.URL, forged, "https://poker.example", ""); err == nil {
			t.Fatal("a token naming an unknown key was accepted")
		}
	}
	if fetches > 1 {
		t.Errorf("key set was fetched %d times for an unknown kid; want at most 1", fetches)
	}
}
