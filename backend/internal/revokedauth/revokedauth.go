// Package revokedauth signs a player in with their revoked identity.
//
// revoked (https://docs.revoked.link) is an OpenID Connect provider that
// anyone can self-host, so this client takes the server's address from the
// player rather than from configuration: there is no client registration,
// the client_id is this instance's own origin, and the only credential is
// PKCE. That is what lets one Showdown instance accept sign-ins from every
// revoked instance, not just one.
//
// Taking the address from the player is also what makes this code careful.
// A hostile address is a request this server makes on a stranger's behalf,
// so an issuer must be https, must not resolve into a private network
// unless the operator allows it, and must serve a discovery document that
// names itself. Every endpoint is then pinned to the issuer's own origin.
package revokedauth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

// metadataTTL is how long a discovery document is reused. Short enough
// that a server that moves an endpoint is followed the same day, long
// enough that a sign-in costs one round trip and not three.
const metadataTTL = time.Hour

// maxBody caps every response this package reads. Discovery documents and
// key sets are small; anything larger is a server misbehaving.
const maxBody = 256 << 10

// Metadata is the part of a discovery document this client uses.
type Metadata struct {
	Issuer                string `json:"issuer"`
	AuthorizationEndpoint string `json:"authorization_endpoint"`
	TokenEndpoint         string `json:"token_endpoint"`
	JWKSURI               string `json:"jwks_uri"`
	UserinfoEndpoint      string `json:"userinfo_endpoint"`

	CodeChallengeMethodsSupported []string `json:"code_challenge_methods_supported"`
}

// Tokens is a token endpoint response.
type Tokens struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   int    `json:"expires_in"`
	IDToken     string `json:"id_token"`
	Scope       string `json:"scope"`
}

// Error is a refusal that names a revoked server, so a handler can tell the
// player which address went wrong without leaking what this server reached.
type Error struct {
	Issuer string
	Reason string
	err    error
}

func (e *Error) Error() string {
	if e.err != nil {
		return fmt.Sprintf("%s: %s: %v", e.Issuer, e.Reason, e.err)
	}
	return fmt.Sprintf("%s: %s", e.Issuer, e.Reason)
}

func (e *Error) Unwrap() error { return e.err }

func failf(issuer, reason string, err error) *Error {
	return &Error{Issuer: issuer, Reason: reason, err: err}
}

// Options configure a Client.
type Options struct {
	// Issuers, when not empty, is the only set of revoked servers this
	// instance will talk to. Empty means any server the player names,
	// which is the point of the feature; an operator who wants their
	// players on one server sets it.
	Issuers []string
	// AllowPrivateNetwork lifts the guard that keeps an issuer from
	// resolving to loopback or a private range. Development only: with it
	// on, a player can make this server probe its own network.
	AllowPrivateNetwork bool
	// HTTPClient is used for discovery, keys and the token exchange.
	HTTPClient *http.Client
}

// Client talks to revoked servers and remembers what it learned about each.
type Client struct {
	http                *http.Client
	issuers             map[string]bool
	allowPrivateNetwork bool

	mu      sync.Mutex
	servers map[string]*cached
}

type cached struct {
	md      Metadata
	keys    *keySet
	fetched time.Time
}

// New builds a Client. The returned client is safe for concurrent use.
func New(opts Options) (*Client, error) {
	c := &Client{
		http:                opts.HTTPClient,
		allowPrivateNetwork: opts.AllowPrivateNetwork,
		servers:             map[string]*cached{},
	}
	if c.http == nil {
		c.http = &http.Client{
			Timeout: 10 * time.Second,
			// A redirect could take a pinned endpoint somewhere else, so
			// none are followed: every revoked endpoint answers directly.
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}
	}
	if len(opts.Issuers) > 0 {
		c.issuers = map[string]bool{}
		for _, raw := range opts.Issuers {
			iss, err := NormalizeIssuer(raw)
			if err != nil {
				return nil, fmt.Errorf("issuer %q: %w", raw, err)
			}
			c.issuers[iss] = true
		}
	}
	return c, nil
}

// NormalizeIssuer turns what a player typed into the exact issuer string
// that will be compared against the discovery document and the iss of the
// callback. A bare host is read as https; a path, query or fragment is
// refused rather than quietly dropped, because the issuer is an identity
// and two spellings of it must not both be accepted.
func NormalizeIssuer(raw string) (string, error) {
	s := strings.TrimSpace(raw)
	if s == "" {
		return "", errors.New("no address given")
	}
	if !strings.Contains(s, "://") {
		s = "https://" + s
	}
	u, err := url.Parse(s)
	if err != nil {
		return "", errors.New("not a valid address")
	}
	switch {
	case u.Scheme != "https" && u.Scheme != "http":
		return "", fmt.Errorf("%q is not an http address", u.Scheme)
	case u.Host == "":
		return "", errors.New("no host in the address")
	case u.User != nil:
		return "", errors.New("the address must not carry a user")
	case u.RawQuery != "" || u.Fragment != "":
		return "", errors.New("the address must be a plain origin")
	case strings.Trim(u.Path, "/") != "":
		return "", errors.New("the address must be a plain origin, with no path")
	}
	return u.Scheme + "://" + strings.ToLower(u.Host), nil
}

// Allowed reports whether this instance talks to the given issuer at all.
func (c *Client) Allowed(issuer string) bool {
	if c.issuers == nil {
		return true
	}
	return c.issuers[issuer]
}

// Discover loads and caches the issuer's metadata. It is the only way into
// this package: every other call takes an issuer already discovered here.
func (c *Client) Discover(ctx context.Context, issuer string) (Metadata, error) {
	if !c.Allowed(issuer) {
		return Metadata{}, failf(issuer, "this instance does not accept sign-ins from that server", nil)
	}
	if err := c.checkAddress(ctx, issuer); err != nil {
		return Metadata{}, err
	}

	c.mu.Lock()
	if s, ok := c.servers[issuer]; ok && time.Since(s.fetched) < metadataTTL {
		md := s.md
		c.mu.Unlock()
		return md, nil
	}
	c.mu.Unlock()

	var md Metadata
	if err := c.getJSON(ctx, issuer+"/.well-known/openid-configuration", &md); err != nil {
		return Metadata{}, failf(issuer, "no revoked server answered there", err)
	}
	// The document must name itself: without this a server could claim to
	// be any issuer, and the (issuer, subject) pair a profile is keyed on
	// would mean nothing.
	if md.Issuer != issuer {
		return Metadata{}, failf(issuer, fmt.Sprintf("that server calls itself %q", md.Issuer), nil)
	}
	for name, endpoint := range map[string]string{
		"authorization_endpoint": md.AuthorizationEndpoint,
		"token_endpoint":         md.TokenEndpoint,
		"jwks_uri":               md.JWKSURI,
	} {
		if err := sameOrigin(issuer, endpoint); err != nil {
			return Metadata{}, failf(issuer, fmt.Sprintf("%s is not on that server", name), err)
		}
	}
	if md.UserinfoEndpoint != "" {
		if err := sameOrigin(issuer, md.UserinfoEndpoint); err != nil {
			return Metadata{}, failf(issuer, "userinfo_endpoint is not on that server", err)
		}
	}
	if len(md.CodeChallengeMethodsSupported) > 0 && !contains(md.CodeChallengeMethodsSupported, "S256") {
		return Metadata{}, failf(issuer, "that server does not offer PKCE with S256", nil)
	}

	c.mu.Lock()
	c.servers[issuer] = &cached{
		md:      md,
		keys:    &keySet{jwksURI: md.JWKSURI, refetch: time.Minute, download: c.jwks},
		fetched: time.Now(),
	}
	c.mu.Unlock()
	return md, nil
}

// AuthorizeURL is where the player's browser goes to approve the sign-in.
// client_id is this instance's origin and redirectURI must sit on it; both
// are checked by the revoked server before it shows anything.
func AuthorizeURL(md Metadata, clientID, redirectURI, state, nonce, challenge string, scopes []string) (string, error) {
	u, err := url.Parse(md.AuthorizationEndpoint)
	if err != nil {
		return "", fmt.Errorf("authorization_endpoint: %w", err)
	}
	q := u.Query()
	q.Set("client_id", clientID)
	q.Set("redirect_uri", redirectURI)
	q.Set("response_type", "code")
	q.Set("scope", strings.Join(scopes, " "))
	q.Set("state", state)
	q.Set("nonce", nonce)
	q.Set("code_challenge", challenge)
	q.Set("code_challenge_method", "S256")
	u.RawQuery = q.Encode()
	return u.String(), nil
}

// AppLink is the link that starts a sign-in through the Revoked app
// itself, without knowing the person's server: the app opens the request
// on whichever server it is signed into, and names that server in the iss
// of the answer. It is the ordinary way in — a person's server is their
// own business, and asking them to type it is the fallback.
func AppLink(clientID, redirectURI, state, nonce, challenge string, scopes []string) string {
	q := url.Values{
		"client_id":             {clientID},
		"redirect_uri":          {redirectURI},
		"response_type":         {"code"},
		"scope":                 {strings.Join(scopes, " ")},
		"state":                 {state},
		"nonce":                 {nonce},
		"code_challenge":        {challenge},
		"code_challenge_method": {"S256"},
	}
	return "revoked://signin?" + q.Encode()
}

// Exchange redeems the authorization code. There is no client secret: the
// code_verifier is what proves this is the same client that started.
func (c *Client) Exchange(ctx context.Context, issuer, code, clientID, redirectURI, verifier string) (Tokens, error) {
	md, err := c.Discover(ctx, issuer)
	if err != nil {
		return Tokens{}, err
	}
	form := url.Values{
		"grant_type":    {"authorization_code"},
		"code":          {code},
		"client_id":     {clientID},
		"redirect_uri":  {redirectURI},
		"code_verifier": {verifier},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, md.TokenEndpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return Tokens{}, failf(issuer, "token request", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")

	res, err := c.http.Do(req)
	if err != nil {
		return Tokens{}, failf(issuer, "that server could not be reached", err)
	}
	defer func() { _, _ = io.Copy(io.Discard, res.Body); _ = res.Body.Close() }()

	body, err := io.ReadAll(io.LimitReader(res.Body, maxBody))
	if err != nil {
		return Tokens{}, failf(issuer, "token response", err)
	}
	if res.StatusCode != http.StatusOK {
		var oe struct {
			Error       string `json:"error"`
			Description string `json:"error_description"`
		}
		_ = json.Unmarshal(body, &oe)
		if oe.Error != "" {
			return Tokens{}, failf(issuer, "the sign-in was refused: "+oe.Error, nil)
		}
		return Tokens{}, failf(issuer, fmt.Sprintf("the token endpoint answered %d", res.StatusCode), nil)
	}
	var t Tokens
	if err := json.Unmarshal(body, &t); err != nil {
		return Tokens{}, failf(issuer, "token response", err)
	}
	if t.IDToken == "" {
		return Tokens{}, failf(issuer, "the token response carried no id_token", nil)
	}
	return t, nil
}

// VerifyIDToken checks the token against the issuer's published keys and
// returns the claims. nonce is the one sent with the authorization request.
func (c *Client) VerifyIDToken(ctx context.Context, issuer, idToken, clientID, nonce string) (Claims, error) {
	if _, err := c.Discover(ctx, issuer); err != nil {
		return Claims{}, err
	}
	c.mu.Lock()
	s := c.servers[issuer]
	c.mu.Unlock()
	if s == nil {
		return Claims{}, failf(issuer, "that server is not known", nil)
	}
	cl, err := verifyIDToken(ctx, s.keys, idToken, issuer, clientID, nonce, time.Now())
	if err != nil {
		return Claims{}, failf(issuer, "the identity it returned could not be checked", err)
	}
	return cl, nil
}

func (c *Client) jwks(ctx context.Context, uri string) ([]jwk, error) {
	var doc struct {
		Keys []jwk `json:"keys"`
	}
	if err := c.getJSON(ctx, uri, &doc); err != nil {
		return nil, err
	}
	if len(doc.Keys) == 0 {
		return nil, errors.New("the key set is empty")
	}
	return doc.Keys, nil
}

func (c *Client) getJSON(ctx context.Context, uri string, out any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, uri, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/json")
	res, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer func() { _, _ = io.Copy(io.Discard, res.Body); _ = res.Body.Close() }()

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("%s answered %d", uri, res.StatusCode)
	}
	return json.NewDecoder(io.LimitReader(res.Body, maxBody)).Decode(out)
}

// checkAddress refuses an issuer this server should not be making requests
// to. The player chooses the address, so without this the sign-in form is a
// way to ask this server what it can see on its own network.
func (c *Client) checkAddress(ctx context.Context, issuer string) error {
	u, err := url.Parse(issuer)
	if err != nil {
		return failf(issuer, "not a valid address", err)
	}
	if u.Scheme != "https" && !c.allowPrivateNetwork {
		return failf(issuer, "a revoked server must be reached over https", nil)
	}
	if c.allowPrivateNetwork {
		return nil
	}
	host := u.Hostname()
	// A literal address skips the resolver; a name is resolved so that a
	// name pointing at 127.0.0.1 is caught as well.
	var ips []net.IP
	if ip := net.ParseIP(host); ip != nil {
		ips = []net.IP{ip}
	} else {
		addrs, err := net.DefaultResolver.LookupIPAddr(ctx, host)
		if err != nil {
			return failf(issuer, "that address does not resolve", err)
		}
		for _, a := range addrs {
			ips = append(ips, a.IP)
		}
	}
	if len(ips) == 0 {
		return failf(issuer, "that address does not resolve", nil)
	}
	for _, ip := range ips {
		if isPrivate(ip) {
			return failf(issuer, "that address is inside a private network", nil)
		}
	}
	return nil
}

func isPrivate(ip net.IP) bool {
	return ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() ||
		ip.IsLinkLocalMulticast() || ip.IsInterfaceLocalMulticast() ||
		ip.IsUnspecified() || ip.IsMulticast()
}

// sameOrigin pins an endpoint to the issuer. The discovery document is
// served by the very server being judged, so an endpoint it places
// elsewhere would send the code — or the player — somewhere this server
// never agreed to talk to.
func sameOrigin(issuer, endpoint string) error {
	if endpoint == "" {
		return errors.New("missing")
	}
	u, err := url.Parse(endpoint)
	if err != nil {
		return err
	}
	if u.Scheme+"://"+strings.ToLower(u.Host) != issuer {
		return fmt.Errorf("%s is not on %s", endpoint, issuer)
	}
	return nil
}

func contains(list []string, want string) bool {
	for _, s := range list {
		if s == want {
			return true
		}
	}
	return false
}

// NewVerifier makes a PKCE code verifier: 43 characters of base64url, the
// shortest RFC 7636 allows, from 32 bytes of randomness.
func NewVerifier() (string, error) {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b[:]), nil
}

// Challenge is the S256 challenge for a verifier.
func Challenge(verifier string) string {
	sum := sha256.Sum256([]byte(verifier))
	return base64.RawURLEncoding.EncodeToString(sum[:])
}

// CheckCode is the code a waiting page and the app both show so the player
// can see they are approving the same request: the first three bytes of
// SHA-256 over the challenge, upper-case hex in two groups.
func CheckCode(challenge string) string {
	sum := sha256.Sum256([]byte(challenge))
	hex := fmt.Sprintf("%X", sum[:3])
	return hex[:3] + "-" + hex[3:]
}
