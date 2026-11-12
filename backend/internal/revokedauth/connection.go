// Connected tools: the other direction of the same relationship.
//
// Signing in tells this instance who somebody is. A connection lets this
// instance keep something for them: the player connects it to their vault
// as a tool, it is given a section of its own there, and it writes one
// entry saying which table they are at. A share over that entry resolves
// at read time, so the link the player hands out always says where they
// are now.
//
// What a connection token can do is decided once, by the player, in their
// app: write the section it was given, and manage the shares it made. It
// is not a session, reaches no other section, and is refused the moment
// they pause or disconnect the tool. It lapses on its own after 90 days,
// and only the player can renew it.

package revokedauth

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// The permissions this instance asks for, and nothing besides: no reading
// of the vault, no requests in the player's name, no attestations.
var connectPermissions = []string{"vault:write", "shares:manage"}

// Trouble is why a connection token stopped working. It is kept so the
// player can be told the truth — paused is not ended, and a lapsed
// connection is theirs to renew — rather than "something went wrong".
const (
	// TroublePaused: the player paused the tool. The token is still good
	// and works again when they resume, so it is kept.
	TroublePaused = "paused"
	// TroubleExpired: the 90 days have run out.
	TroubleExpired = "expired"
	// TroubleGone: the player disconnected the tool, or the server no
	// longer knows this token.
	TroubleGone = "gone"
)

// ConnError is a refusal from a connection endpoint. Code is the revoked
// server's own error code, which is stable; the message is not.
type ConnError struct {
	Server  string
	Status  int
	Code    string
	Message string
}

func (e *ConnError) Error() string {
	if e.Code != "" {
		return fmt.Sprintf("%s: %s (%d)", e.Server, e.Code, e.Status)
	}
	return fmt.Sprintf("%s: answered %d", e.Server, e.Status)
}

// Trouble maps a refusal onto what the player should be told, or "" when
// this was a passing failure rather than the end of the connection.
func (e *ConnError) Trouble() string {
	switch e.Code {
	case "connection_paused":
		return TroublePaused
	case "connection_expired":
		return TroubleExpired
	case "connection_unauthorized":
		return TroubleGone
	}
	// A bare 401 from a connection endpoint means the token is not known
	// there any more, whatever the server called it.
	if e.Status == http.StatusUnauthorized {
		return TroubleGone
	}
	return ""
}

// Trouble reports what an error from this package means for a connection.
func Trouble(err error) string {
	var ce *ConnError
	if errors.As(err, &ce) {
		return ce.Trouble()
	}
	return ""
}

// KeyTaken reports whether a write was refused because the player already
// has an entry under that key. The tool may not touch an entry it did not
// write, so the answer is to ask for another key, not to overwrite.
func KeyTaken(err error) bool {
	var ce *ConnError
	return errors.As(err, &ce) && ce.Code == "vault_key_taken"
}

// Connection is a connection as the tool holding it may see itself.
type Connection struct {
	ID          string   `json:"id"`
	ClientID    string   `json:"clientId"`
	ClientName  string   `json:"clientName"`
	ExpiresAt   string   `json:"expiresAt"`
	Permissions []string `json:"permissions"`
	VaultAccess string   `json:"vaultAccess"`
	Section     string   `json:"section"`
}

// Expires parses ExpiresAt, falling back to 90 days from now — the term the
// server gives a fresh connection — when it says nothing readable.
func (c Connection) Expires(now time.Time) time.Time {
	for _, layout := range []string{time.RFC3339, "2006-01-02 15:04:05.999Z07:00", "2006-01-02 15:04:05Z07:00"} {
		if t, err := time.Parse(layout, c.ExpiresAt); err == nil {
			return t
		}
	}
	return now.Add(90 * 24 * time.Hour)
}

// Writable reports whether this connection can do the job: a section of
// its own to write, and permission to write it.
func (c Connection) Writable() bool {
	return c.Section != "" && contains(c.Permissions, "vault:write")
}

// CanShare reports whether this connection may make the share.
func (c Connection) CanShare() bool { return contains(c.Permissions, "shares:manage") }

// ConnectLink is the link that asks a player to connect this instance to
// their vault. The app opens it, shows who is asking and what for, and the
// player decides; nothing is registered anywhere in advance.
//
// The answer comes back to redirect, on this instance's own origin, with a
// one-time code bound to the PKCE challenge — so a link read off somebody
// else's screen cannot be turned into a token.
func ConnectLink(clientOrigin, name, redirect, state, challenge, reason string) string {
	q := url.Values{
		"client":    {clientOrigin},
		"name":      {name},
		"redirect":  {redirect},
		"state":     {state},
		"challenge": {challenge},
		// A section of its own is the whole point: this instance keeps one
		// entry of its own making and never reads anything of the
		// player's. vault=read is deliberately not asked for.
		"section":     {"1"},
		"permissions": {strings.Join(connectPermissions, ",")},
	}
	if reason != "" {
		q.Set("section_reason", reason)
		q.Set("permissions_reason", reason)
	}
	// Encode writes a space as "+", which a revoked link reads literally.
	return "revoked://connect?" + strings.ReplaceAll(q.Encode(), "+", "%20")
}

// ConnectToken spends the one-time code the app delivered. The verifier is
// what proves this is the same client that asked, and the code is spent
// whether it matches or not.
func (c *Client) ConnectToken(ctx context.Context, server, code, verifier, redirectURI string) (string, Connection, error) {
	var answer struct {
		Token      string     `json:"token"`
		Connection Connection `json:"connection"`
	}
	body := map[string]string{"code": code, "verifier": verifier, "redirectUri": redirectURI}
	if err := c.connCall(ctx, http.MethodPost, server, "/api/connect/token", "", body, &answer); err != nil {
		return "", Connection{}, err
	}
	if answer.Token == "" {
		return "", Connection{}, &ConnError{Server: server, Code: "connection_grant_invalid"}
	}
	return answer.Token, answer.Connection, nil
}

// Connection reads what the connection may still do. It is also how a
// token is checked without writing anything.
func (c *Client) Connection(ctx context.Context, server, token string) (Connection, error) {
	var conn Connection
	if err := c.connCall(ctx, http.MethodGet, server, "/api/connection", token, nil, &conn); err != nil {
		return Connection{}, err
	}
	return conn, nil
}

// WriteEntry creates the entry in this instance's own section and returns
// its id. A key the player already uses is refused rather than taken over.
func (c *Client) WriteEntry(ctx context.Context, server, token, key, label, value string) (string, error) {
	var out struct {
		ID string `json:"id"`
	}
	body := map[string]string{"key": key, "label": label, "value": value}
	if err := c.connCall(ctx, http.MethodPost, server, "/api/vault", token, body, &out); err != nil {
		return "", err
	}
	if out.ID == "" {
		return "", &ConnError{Server: server, Code: "record_not_found"}
	}
	return out.ID, nil
}

// UpdateEntry writes a new value to the entry this instance wrote. Every
// share over it says the new thing on its next read: that is the whole
// mechanism this feature rests on.
func (c *Client) UpdateEntry(ctx context.Context, server, token, id, value string) error {
	return c.connCall(ctx, http.MethodPatch, server, "/api/vault/"+url.PathEscape(id), token,
		map[string]string{"value": value}, nil)
}

// CreateShare shares the given entries and returns the share's id and its
// address. The address is handed over once, here, and never again — so it
// is kept.
//
// What a share serves is decided by the records it names. A section on a
// link only groups them for whoever reads it and grants nothing at all, so
// the entries are named outright; the section is named as well, for its
// heading.
func (c *Client) CreateShare(ctx context.Context, server, token, label string, records []string, section, ref string) (string, string, error) {
	var out struct {
		ID  string `json:"id"`
		URL string `json:"url"`
	}
	body := map[string]any{
		"label":   label,
		"records": records,
		"ref":     ref,
		// No maxViews and no expiry: every read of a share consumes a
		// view, so a cap would turn a standing link into a burner.
	}
	if section != "" {
		body["sections"] = []string{section}
	}
	if err := c.connCall(ctx, http.MethodPost, server, "/api/connection/links", token, body, &out); err != nil {
		return "", "", err
	}
	if out.ID == "" {
		return "", "", &ConnError{Server: server, Code: "link_not_found"}
	}
	return out.ID, out.URL, nil
}

// RevokeShare ends the share this instance made. The player can do the
// same from their app; this is what "turn it off" does from here.
func (c *Client) RevokeShare(ctx context.Context, server, token, id string) error {
	return c.connCall(ctx, http.MethodPost, server,
		"/api/connection/links/"+url.PathEscape(id)+"/revoke", token, nil, nil)
}

// Disconnect gives the connection up from this side. What it wrote stays
// the player's, in their vault, named after this instance.
func (c *Client) Disconnect(ctx context.Context, server, token string) error {
	return c.connCall(ctx, http.MethodDelete, server, "/api/connection", token, nil, nil)
}

// connCall is every connection request: the server is judged as an issuer
// first, the path is pinned to its origin, and a refusal keeps the
// server's own error code.
func (c *Client) connCall(ctx context.Context, method, server, path, token string, in, out any) error {
	// The address came from the app or from a row this instance wrote
	// after the app named it, but it is checked all the same: the
	// allow-list, the private-network guard and a server that names
	// itself are the same requirements as for a sign-in.
	if _, err := c.Discover(ctx, server); err != nil {
		return err
	}
	var rd io.Reader
	if in != nil {
		body, err := json.Marshal(in)
		if err != nil {
			return err
		}
		rd = bytes.NewReader(body)
	}
	req, err := http.NewRequestWithContext(ctx, method, server+path, rd)
	if err != nil {
		return failf(server, "connection request", err)
	}
	if in != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		// Not Authorization: a connection token is not a session, and no
		// collection rule admits it.
		req.Header.Set("X-Revoked-Connection", token)
	}
	req.Header.Set("Accept", "application/json")

	res, err := c.http.Do(req)
	if err != nil {
		return failf(server, "that server could not be reached", err)
	}
	defer func() { _, _ = io.Copy(io.Discard, res.Body); _ = res.Body.Close() }()

	body, err := io.ReadAll(io.LimitReader(res.Body, maxBody))
	if err != nil {
		return failf(server, "connection response", err)
	}
	if res.StatusCode < 200 || res.StatusCode > 299 {
		ce := &ConnError{Server: server, Status: res.StatusCode}
		var env struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		}
		if err := json.Unmarshal(body, &env); err == nil {
			ce.Code, ce.Message = env.Code, env.Message
		}
		return ce
	}
	if out == nil || len(body) == 0 {
		return nil
	}
	if err := json.Unmarshal(body, out); err != nil {
		return failf(server, "connection response", err)
	}
	return nil
}
