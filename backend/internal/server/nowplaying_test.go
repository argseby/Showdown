package server

import (
	"context"
	"net/http"
	"net/url"
	"strings"
	"testing"
)

// nowPlayingEnv is an instance that offers the table link as well as the
// sign-in. The fake vault runs on loopback, so the private-network guard
// is lifted the way it is for development.
func nowPlayingEnv() map[string]string {
	env := map[string]string{
		"REVOKED_NOW_PLAYING":           "true",
		"REVOKED_ALLOW_PRIVATE_NETWORK": "true",
	}
	for k, v := range revokedOn {
		env[k] = v
	}
	return env
}

// signInWithRevoked runs a whole sign-in against the fake server and
// returns the account token of "robin", the one player these tests need:
// everything below wants a profile that signs in with revoked, because
// that is the only kind this feature is for.
func signInWithRevoked(t *testing.T, h *harness, issuer *fakeRevoked) string {
	const handle = "robin"
	t.Helper()
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/start", "", map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("start: %d %v", status, out)
	}
	link, _ := url.Parse(out["app_link"].(string))
	issuer.nonce = link.Query().Get("nonce")
	deliverRevoked(t, h, url.Values{
		"code": {"auth-code"}, "state": {link.Query().Get("state")}, "iss": {issuer.URL},
	})
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/wait", "",
		map[string]string{"wait": out["wait"].(string)})
	if status != http.StatusOK || out["done"] != true {
		t.Fatalf("wait: %d %v", status, out)
	}
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/finish", "",
		map[string]string{"code": out["code"].(string)})
	if status != http.StatusOK {
		t.Fatalf("finish: %d %v", status, out)
	}
	if token, ok := out["token"].(string); ok && token != "" {
		return token
	}
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/claim", "", map[string]string{
		"claim": out["claim"].(string), "handle": handle,
	})
	if status != http.StatusCreated {
		t.Fatalf("claim: %d %v", status, out)
	}
	return out["token"].(string)
}

// connectVault takes the player through the connection: the link, the
// app's answer, and the page collecting the result.
func connectVault(t *testing.T, h *harness, issuer *fakeRevoked, token string) {
	t.Helper()
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/connect/start", token, map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("connect start: %d %v", status, out)
	}
	link, err := url.Parse(out["app_link"].(string))
	if err != nil || link.Scheme != "revoked" || link.Host != "connect" {
		t.Fatalf("app link: %q (%v)", out["app_link"], err)
	}
	q := link.Query()
	// What the player is asked for, and nothing besides: a section of its
	// own to write, and the right to make the one share. Never the vault.
	if q.Get("section") != "1" || q.Get("permissions") != "vault:write,shares:manage" {
		t.Fatalf("the link asks for the wrong things: %v", q)
	}
	if q.Get("vault") != "" {
		t.Fatalf("the link asks to read the vault: %v", q)
	}
	if q.Get("client") != revokedOn["PUBLIC_ORIGIN"] {
		t.Fatalf("client: %q", q.Get("client"))
	}
	if !strings.HasPrefix(q.Get("redirect"), revokedOn["PUBLIC_ORIGIN"]) {
		t.Fatalf("the answer must come back to this instance: %q", q.Get("redirect"))
	}
	if out["check_code"] == "" {
		t.Fatal("no check code for the player to compare")
	}
	deliverConnect(t, h, url.Values{
		"state": {q.Get("state")}, "status": {"connected"},
		"server": {issuer.URL}, "code": {"connect-code"},
	})
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/connect/wait", token,
		map[string]string{"wait": out["wait"].(string)})
	if status != http.StatusOK || out["done"] != true || out["error"] != "" {
		t.Fatalf("connect wait: %d %v", status, out)
	}
}

// deliverConnect is the app opening the return address. It lands in
// whichever browser the system picks, so it carries no session.
func deliverConnect(t *testing.T, h *harness, q url.Values) string {
	t.Helper()
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error {
		return http.ErrUseLastResponse
	}}
	res, err := client.Get(h.base + "/api/accounts/revoked/connect/callback?" + q.Encode())
	if err != nil {
		t.Fatalf("connect callback: %v", err)
	}
	defer func() { _ = res.Body.Close() }()
	return res.Header.Get("Location")
}

func TestNowPlayingOffByDefault(t *testing.T) {
	t.Parallel()
	// The sign-in on, the table link off: the routes are not there, and
	// the client is told by /api/config rather than by a failed attempt.
	h := newHarness(t, t.TempDir(), "", revokedOn)
	defer h.stop()

	status, cfg := h.request(http.MethodGet, "/api/config", "", nil)
	if status != http.StatusOK || cfg["revoked_now_playing"] != false {
		t.Fatalf("config: %d %v", status, cfg)
	}
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/connect/start", "", map[string]string{})
	if status != http.StatusNotFound || errCode(out) != "revoked_now_playing_disabled" {
		t.Fatalf("start with the feature off: %d %v", status, out)
	}
}

func TestNowPlayingNeedsARevokedIdentity(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	status, cfg := h.request(http.MethodGet, "/api/config", "", nil)
	if status != http.StatusOK || cfg["revoked_now_playing"] != true {
		t.Fatalf("config: %d %v", status, cfg)
	}
	// A profile with a password has no vault for this to be about. It is
	// refused by name, and that refusal is also what stops somebody from
	// pointing this instance at a vault that is not theirs.
	status, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "pat", "password": "hunter2hunter2",
	})
	if status != http.StatusCreated {
		t.Fatalf("register: %d %v", status, out)
	}
	token := out["token"].(string)
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/connect/start", token, map[string]string{})
	if status != http.StatusConflict || errCode(out) != "revoked_identity_required" {
		t.Fatalf("connect without an identity: %d %v", status, out)
	}
	// Nor is there anything to report about.
	status, out = h.request(http.MethodGet, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusOK || out["connected"] != false {
		t.Fatalf("now playing: %d %v", status, out)
	}
}

// TestNowPlayingFollowsTheTable is the whole feature: the player connects
// their vault, sits down, and the entry the share resolves says where they
// are. Then they stand up, and it says they are not at a table.
func TestNowPlayingFollowsTheTable(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	status, out := h.request(http.MethodGet, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusOK || out["connected"] != false || out["playing"] != nowPlayingIdle {
		t.Fatalf("before connecting: %d %v", status, out)
	}

	connectVault(t, h, issuer, token)

	// The entry and the share exist the moment the player agreed, so the
	// page that comes back has a link to show.
	status, out = h.request(http.MethodGet, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusOK || out["connected"] != true {
		t.Fatalf("after connecting: %d %v", status, out)
	}
	link, _ := out["url"].(string)
	if !strings.Contains(link, "/s/") {
		t.Fatalf("no share address came back: %v", out)
	}
	if made, ended := issuer.shareCount(); made != 1 || ended != 0 {
		t.Fatalf("shares made %d, ended %d", made, ended)
	}
	if v, ok := issuer.vaultRecord(nowPlayingKey); !ok || v != nowPlayingIdle {
		t.Fatalf("the entry says %q", v)
	}
	// What the link is for: opening it serves the entry. A share grants
	// the records it names and nothing else, so a link that names only
	// the section resolves to nothing at all — which is exactly what the
	// first version of this did.
	if got := issuer.resolve(link); len(got) != 1 || got[0] != nowPlayingIdle {
		t.Fatalf("the share serves %v, want the entry", got)
	}

	// Sitting down: the entry names the table, its stakes and the way in.
	id, _ := h.createTable(fastSettings())
	status, out = h.request(http.MethodPost, "/api/tables/"+id+"/join", token, map[string]any{"name": "Robin"})
	if status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, out)
	}
	h.s.publishNowPlaying(context.Background(), nil)
	v, _ := issuer.vaultRecord(nowPlayingKey)
	if !strings.Contains(v, "Integration") || !strings.Contains(v, "50/100") {
		t.Fatalf("the entry does not name the table: %q", v)
	}
	// The share resolves at read time, so the same address now says this
	// without anything having been done to the link.
	if got := issuer.resolve(link); len(got) != 1 || got[0] != v {
		t.Fatalf("the share serves %v, want %q", got, v)
	}
	if !strings.Contains(v, revokedOn["PUBLIC_ORIGIN"]+"/t/"+id) {
		t.Fatalf("the entry carries no way in: %q", v)
	}
	// The same pass again writes nothing: a player who has not moved
	// costs their server no request at all.
	before, _ := issuer.vaultRecord(nowPlayingKey)
	h.s.publishNowPlaying(context.Background(), nil)
	if after, _ := issuer.vaultRecord(nowPlayingKey); after != before {
		t.Fatalf("a second pass rewrote the entry: %q then %q", before, after)
	}

	// The table ends, and the next pass says so. Standing up, busting out
	// and this server restarting all end here too.
	if err := h.reg.Delete(context.Background(), id); err != nil {
		t.Fatalf("delete table: %v", err)
	}
	h.s.publishNowPlaying(context.Background(), nil)
	if v, _ := issuer.vaultRecord(nowPlayingKey); v != nowPlayingIdle {
		t.Fatalf("after the table ended the entry says %q", v)
	}

	// Turning it off ends the share and gives the connection up, so
	// nothing here can write to that vault again.
	status, _ = h.request(http.MethodDelete, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusNoContent {
		t.Fatalf("turn off: %d", status)
	}
	if made, ended := issuer.shareCount(); made != 1 || ended != 1 {
		t.Fatalf("after turning off: shares made %d, ended %d", made, ended)
	}
	if got := issuer.resolve(link); got != nil {
		t.Fatalf("the link still serves %v after being turned off", got)
	}
	status, out = h.request(http.MethodGet, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusOK || out["connected"] != false {
		t.Fatalf("after turning off: %d %v", status, out)
	}
}

// TestNowPlayingKeepsPrivateTablesPrivate: a table nobody can walk into is
// named without its address, and a password is never written anywhere.
func TestNowPlayingKeepsPrivateTablesPrivate(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	connectVault(t, h, issuer, token)

	settings := fastSettings()
	settings["password"] = "letmein"
	id, _ := h.createTable(settings)
	status, out := h.request(http.MethodPost, "/api/tables/"+id+"/join", token,
		map[string]any{"name": "Robin", "password": "letmein"})
	if status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, out)
	}
	h.s.publishNowPlaying(context.Background(), nil)
	v, _ := issuer.vaultRecord(nowPlayingKey)
	switch {
	case !strings.Contains(v, "closed table"):
		t.Fatalf("a password-protected table should carry no address: %q", v)
	case strings.Contains(v, "/t/"+id):
		t.Fatalf("the entry hands out the way into a closed table: %q", v)
	case strings.Contains(v, "letmein"):
		t.Fatalf("the entry carries the table password: %q", v)
	}
}

// TestNowPlayingRefusesAnotherServersVault: the answer must come from the
// server the flow was started against, which is one the profile signs in
// with. Without this, somebody who read the link off the player's screen
// could have their play reported into a vault of their own.
func TestNowPlayingRefusesAnotherServersVault(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	stranger := newFakeRevoked(t)
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/connect/start", token, map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("connect start: %d %v", status, out)
	}
	link, _ := url.Parse(out["app_link"].(string))
	wait := out["wait"].(string)
	loc := deliverConnect(t, h, url.Values{
		"state": {link.Query().Get("state")}, "status": {"connected"},
		"server": {stranger.URL}, "code": {"connect-code"},
	})
	if !strings.Contains(loc, "revoked_error=issuer_mismatch") {
		t.Fatalf("another server's answer was taken: %s", loc)
	}
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/connect/wait", token,
		map[string]string{"wait": wait})
	if status != http.StatusOK || out["error"] != "issuer_mismatch" {
		t.Fatalf("wait: %d %v", status, out)
	}
	status, out = h.request(http.MethodGet, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusOK || out["connected"] != false {
		t.Fatalf("nothing should have been saved: %d %v", status, out)
	}

	// Asking for a server this profile does not sign in with is refused
	// before the app is ever opened.
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/connect/start", token,
		map[string]string{"server": stranger.URL})
	if status != http.StatusConflict || errCode(out) != "revoked_identity_required" {
		t.Fatalf("start against a stranger: %d %v", status, out)
	}
}

// TestNowPlayingDeclined: the player saying no in the app ends the wait,
// and leaves nothing behind.
func TestNowPlayingDeclined(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/connect/start", token, map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("connect start: %d %v", status, out)
	}
	link, _ := url.Parse(out["app_link"].(string))
	deliverConnect(t, h, url.Values{
		"state": {link.Query().Get("state")}, "status": {"declined"},
	})
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/connect/wait", token,
		map[string]string{"wait": out["wait"].(string)})
	if status != http.StatusOK || out["done"] != true || out["error"] != "access_denied" {
		t.Fatalf("wait: %d %v", status, out)
	}
}

// TestNowPlayingWithoutASection: the player can untick the section, and
// then there is nothing to keep. The token is given up rather than held.
func TestNowPlayingWithoutASection(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	issuer.noSection = true
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	status, out := h.request(http.MethodPost, "/api/accounts/revoked/connect/start", token, map[string]string{})
	if status != http.StatusOK {
		t.Fatalf("connect start: %d %v", status, out)
	}
	link, _ := url.Parse(out["app_link"].(string))
	deliverConnect(t, h, url.Values{
		"state": {link.Query().Get("state")}, "status": {"connected"},
		"server": {issuer.URL}, "code": {"connect-code"},
	})
	status, out = h.request(http.MethodPost, "/api/accounts/revoked/connect/wait", token,
		map[string]string{"wait": out["wait"].(string)})
	if status != http.StatusOK || out["error"] != "not_permitted" {
		t.Fatalf("wait: %d %v", status, out)
	}
}

// TestNowPlayingKeyTaken: an entry the player already keeps under that key
// is not the tool's to take over, so it writes its own.
func TestNowPlayingKeyTaken(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	issuer.keyTaken = true
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	connectVault(t, h, issuer, token)
	if _, ok := issuer.vaultRecord(nowPlayingKey + "_poker_example"); !ok {
		t.Fatal("no entry was written under a free key")
	}
	if _, ok := issuer.vaultRecord(nowPlayingKey); ok {
		t.Fatal("the player's own entry was taken over")
	}
}

// TestNowPlayingPaused: pausing the tool is not ending it. The row keeps
// its token, the player is told what happened, and nothing is retried
// until it is worth retrying.
func TestNowPlayingPaused(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	connectVault(t, h, issuer, token)

	issuer.mu.Lock()
	issuer.paused = true
	issuer.mu.Unlock()
	id, _ := h.createTable(fastSettings())
	if status, out := h.request(http.MethodPost, "/api/tables/"+id+"/join", token,
		map[string]any{"name": "Robin"}); status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, out)
	}
	h.s.publishNowPlaying(context.Background(), nil)

	status, out := h.request(http.MethodGet, "/api/accounts/me/now-playing", token, nil)
	if status != http.StatusOK || out["connected"] != true || out["trouble"] != "paused" {
		t.Fatalf("while paused: %d %v", status, out)
	}
	// Resuming is the player's doing, and the next pass that reaches the
	// row writes what the tables say.
	issuer.mu.Lock()
	issuer.paused = false
	issuer.mu.Unlock()
	if err := h.st.MarkRevokedLinkTrouble(context.Background(), accountIDOf(t, h, token), "paused", 0); err != nil {
		t.Fatalf("mark: %v", err)
	}
	h.s.publishNowPlaying(context.Background(), nil)
	if v, _ := issuer.vaultRecord(nowPlayingKey); !strings.Contains(v, "Integration") {
		t.Fatalf("after resuming the entry says %q", v)
	}
}

// accountIDOf reads the profile id behind a session token.
func accountIDOf(t *testing.T, h *harness, token string) string {
	t.Helper()
	status, out := h.request(http.MethodGet, "/api/accounts/me", token, nil)
	if status != http.StatusOK {
		t.Fatalf("me: %d %v", status, out)
	}
	a, _ := out["account"].(map[string]any)
	id, _ := a["id"].(string)
	if id == "" {
		t.Fatalf("no profile id in %v", out)
	}
	return id
}

// TestNowPlayingReplacesAShareThatGrantsNothing: a share serves the records
// it names, and naming the section alone grants nothing — which is what the
// first version of this made. Such a link is replaced the next time the
// publisher looks, without the player being asked to approve anything again.
func TestNowPlayingReplacesAShareThatGrantsNothing(t *testing.T) {
	t.Parallel()
	issuer := newFakeRevoked(t)
	h := newHarness(t, t.TempDir(), "", nowPlayingEnv())
	defer h.stop()

	token := signInWithRevoked(t, h, issuer)
	connectVault(t, h, issuer, token)

	// Put the row back the way the first version left it: a share that
	// names the section and grants no entry.
	ctx := context.Background()
	id := accountIDOf(t, h, token)
	row, err := h.st.RevokedLink(ctx, id)
	if err != nil {
		t.Fatalf("revoked link: %v", err)
	}
	issuer.mu.Lock()
	issuer.grants[row.LinkID] = nil
	issuer.mu.Unlock()
	row.LinkRecords = ""
	if err := h.st.UpdateRevokedLinkEntry(ctx, row); err != nil {
		t.Fatalf("update: %v", err)
	}
	if got := issuer.resolve(row.LinkURL); got != nil {
		t.Fatalf("the old share should serve nothing, it serves %v", got)
	}

	h.s.publishNowPlaying(ctx, nil)

	fixed, err := h.st.RevokedLink(ctx, id)
	if err != nil {
		t.Fatalf("revoked link: %v", err)
	}
	switch {
	case fixed.LinkID == row.LinkID:
		t.Fatal("the share that granted nothing was kept")
	case fixed.LinkRecords != fixed.RecordID:
		t.Fatalf("the new share grants %q, want the entry %q", fixed.LinkRecords, fixed.RecordID)
	}
	if got := issuer.resolve(fixed.LinkURL); len(got) != 1 || got[0] != nowPlayingIdle {
		t.Fatalf("the new share serves %v, want the entry", got)
	}
	// The old one is revoked rather than left hanging, and the live link
	// is the new one.
	if made, ended := issuer.shareCount(); made != 2 || ended != 1 {
		t.Fatalf("shares made %d, ended %d", made, ended)
	}
	if issuer.liveShare() != fixed.LinkURL {
		t.Fatalf("the live share is %q, the row says %q", issuer.liveShare(), fixed.LinkURL)
	}
}
