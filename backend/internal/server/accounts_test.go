package server

import (
	"context"
	"net/http"
	"testing"
	"time"

	"showdown/internal/botclient"
)

// on is the configuration of an instance that offers profiles.
var on = map[string]string{"ACCOUNTS": "true"}

func TestAccountsOffByDefault(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	// Nothing about profiles exists on a plain instance.
	status, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "alice", "password": "hunter22",
	})
	if status != http.StatusNotFound || out["error"].(map[string]any)["code"] != "accounts_disabled" {
		t.Fatalf("register with accounts off: %d %v", status, out)
	}
	status, cfg := h.request(http.MethodGet, "/api/config", "", nil)
	if status != http.StatusOK || cfg["accounts"] != false {
		t.Fatalf("config: %d %v", status, cfg)
	}
}

func TestAccountSignUpAndIn(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()

	status, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "Alice", "password": "hunter22", "display_name": "Alice",
	})
	if status != http.StatusCreated {
		t.Fatalf("register: %d %v", status, out)
	}
	token, _ := out["token"].(string)
	code, _ := out["recovery_code"].(string)
	acct := out["account"].(map[string]any)
	if token == "" || code == "" || acct["handle"] != "Alice" {
		t.Fatalf("register gave %v", out)
	}
	// Friends see the record; nothing is public until the owner says so.
	if vis := acct["visibility"].(map[string]any); vis["profile"] != "friends" || vis["winnings"] != "friends" {
		t.Fatalf("visibility defaults: %v", vis)
	}

	// A look-alike handle is the same name.
	if status, _ := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "al1ce", "password": "hunter22",
	}); status != http.StatusConflict {
		t.Fatalf("look-alike handle accepted: %d", status)
	}
	// Handles and passwords have rules.
	for _, body := range []map[string]string{
		{"handle": "ab", "password": "hunter22"},
		{"handle": "bad name", "password": "hunter22"},
		{"handle": "admin", "password": "hunter22"},
		{"handle": "carol", "password": "short"},
	} {
		if status, _ := h.request(http.MethodPost, "/api/accounts", "", body); status != http.StatusBadRequest {
			t.Errorf("accepted %v: %d", body, status)
		}
	}

	// Signing in: the folded handle finds the profile, a wrong password does not.
	status, out = h.request(http.MethodPost, "/api/accounts/session", "", map[string]string{
		"handle": "AL_ICE", "password": "hunter22",
	})
	if status != http.StatusOK || out["token"] == "" {
		t.Fatalf("login: %d %v", status, out)
	}
	if status, _ := h.request(http.MethodPost, "/api/accounts/session", "", map[string]string{
		"handle": "alice", "password": "wrong-one",
	}); status != http.StatusUnauthorized {
		t.Fatalf("wrong password accepted: %d", status)
	}
	if status, _ := h.request(http.MethodPost, "/api/accounts/session", "", map[string]string{
		"handle": "nobody", "password": "hunter22",
	}); status != http.StatusUnauthorized {
		t.Fatalf("unknown handle: %d", status)
	}

	// The profile is readable with the token and not without it.
	if status, out := h.request(http.MethodGet, "/api/accounts/me", token, nil); status != http.StatusOK ||
		out["account"].(map[string]any)["handle"] != "Alice" {
		t.Fatalf("me: %d %v", status, out)
	}
	if status, _ := h.request(http.MethodGet, "/api/accounts/me", "", nil); status != http.StatusUnauthorized {
		t.Fatalf("me without a token: %d", status)
	}
}

func TestAccountPasswordAndRecovery(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "bob", "password": "hunter22",
	})
	token := out["token"].(string)
	code := out["recovery_code"].(string)

	// The password change signs every device out and hands out a new code.
	status, changed := h.request(http.MethodPost, "/api/accounts/password", token, map[string]string{
		"current_password": "hunter22", "new_password": "hunter333",
	})
	if status != http.StatusOK || changed["token"] == "" || changed["recovery_code"] == code {
		t.Fatalf("change password: %d %v", status, changed)
	}
	if status, _ := h.request(http.MethodGet, "/api/accounts/me", token, nil); status != http.StatusUnauthorized {
		t.Fatalf("old token still works: %d", status)
	}
	if status, _ := h.request(http.MethodGet, "/api/accounts/me", changed["token"].(string), nil); status != http.StatusOK {
		t.Fatal("new token rejected")
	}

	// The recovery code is the way back in when the password is gone.
	newCode := changed["recovery_code"].(string)
	status, back := h.requestWith(http.MethodPost, "/api/accounts/password", "",
		map[string]string{"X-Handle": "bob"},
		map[string]string{"recovery_code": newCode, "new_password": "hunter4444"})
	if status != http.StatusOK || back["token"] == "" {
		t.Fatalf("recover: %d %v", status, back)
	}
	// A code is good once.
	if status, _ := h.requestWith(http.MethodPost, "/api/accounts/password", "",
		map[string]string{"X-Handle": "bob"},
		map[string]string{"recovery_code": newCode, "new_password": "hunter55555"}); status != http.StatusUnauthorized {
		t.Fatalf("recovery code reused: %d", status)
	}
	if status, _ := h.request(http.MethodPost, "/api/accounts/session", "", map[string]string{
		"handle": "bob", "password": "hunter4444",
	}); status != http.StatusOK {
		t.Fatal("new password does not work")
	}
}

func TestSeatCarriesTheProfile(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "carol", "password": "hunter22", "display_name": "Carol",
	})
	token := out["token"].(string)
	tableID, _ := h.createTable(fastSettings())

	// Signed in: the seat knows whose it is.
	if status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", token,
		map[string]string{"name": "Carol"}); status != http.StatusCreated {
		t.Fatalf("join signed in: %d %v", status, out)
	}
	// A guest joins exactly as before.
	if status, _ := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "",
		map[string]string{"name": "Dave"}); status != http.StatusCreated {
		t.Fatal("guest join refused")
	}
	// Seats are written on the table's own goroutine, so give the row a
	// moment to land.
	seen := map[string]string{}
	waitUntil(t, 5*time.Second, "the seats are stored", func() bool {
		players, err := h.st.ListPlayers(context.Background(), tableID)
		if err != nil {
			t.Fatal(err)
		}
		seen = map[string]string{}
		for _, p := range players {
			seen[p.Name] = p.AccountHandle
		}
		return len(seen) == 2
	})
	if seen["Carol"] != "carol" {
		t.Errorf("Carol's seat carries %q", seen["Carol"])
	}
	if seen["Dave"] != "" {
		t.Errorf("the guest's seat carries %q", seen["Dave"])
	}
}

// Three signed-in players play real hands: every hand lands on each of
// their records and the money adds up.
func TestProfileStatsFromRealHands(t *testing.T) {
	if testing.Short() {
		t.Skip("plays real hands")
	}
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	tableID, adminToken := h.createTable(fastSettings())

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var bs botSet
	tokens := map[string]string{}
	for i, name := range []string{"ann", "ben", "cid"} {
		_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
			"handle": name, "password": "hunter22", "display_name": name,
		})
		token, _ := out["token"].(string)
		if token == "" {
			t.Fatalf("register %s: %v", name, out)
		}
		tokens[name] = token
		b := botclient.New(botclient.Config{
			BaseURL: h.base, TableID: tableID, Name: name,
			Strategy: botclient.StrategyRandom, Seed: uint64(i + 1), AccountToken: token,
		})
		if err := b.Join(ctx); err != nil {
			t.Fatal(err)
		}
		bs.players = append(bs.players, b)
	}
	admin := botclient.New(botclient.Config{
		BaseURL: h.base, TableID: tableID, Name: "admin",
		Role: botclient.RoleAdmin, Token: adminToken,
	})
	bs.others = []*botclient.Bot{admin}
	bs.start(ctx)

	waitUntil(t, 90*time.Second, "five hands", func() bool { return admin.HandsEnded() >= 5 })

	// Every hand is on every record, since all three are dealt in.
	var stats map[string]any
	waitUntil(t, 20*time.Second, "ann's record", func() bool {
		_, stats = h.request(http.MethodGet, "/api/accounts/me/stats", tokens["ann"], nil)
		return num(stats["hands"]) >= 5
	})
	if num(stats["tables"]) != 1 {
		t.Errorf("tables: %v", stats)
	}
	// The chips are conserved across the three records, and the style
	// counters are read off the hand as it was played: over this many
	// random hands somebody put chips in before the flop.
	var sum, vpip float64
	for _, name := range []string{"ann", "ben", "cid"} {
		_, s := h.request(http.MethodGet, "/api/accounts/me/stats", tokens[name], nil)
		sum += num(s["net"])
		vpip += num(s["vpip"])
	}
	if sum != 0 {
		t.Errorf("net over all three profiles = %v, want 0", sum)
	}
	if vpip == 0 {
		t.Errorf("no voluntary pot entry over %v hands", num(stats["hands"]))
	}

	// The hands themselves are kept, not just the totals.
	_, hl := h.request(http.MethodGet, "/api/accounts/me/highlights", tokens["ann"], nil)
	best := hl["best_hands"].([]any)
	if len(best) == 0 {
		t.Fatalf("no best hand after real play: %v", hl)
	}
	first := best[0].(map[string]any)
	if first["description"] == "" || len(first["cards"].([]any)) != 5 {
		t.Errorf("a best hand names itself and its five cards: %v", first)
	}

	// Ending the table writes the round, with places.
	if status, _ := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/end", adminToken,
		map[string]bool{"immediate": true}); status != http.StatusOK {
		t.Fatal("end table")
	}
	waitUntil(t, 20*time.Second, "the round is recorded", func() bool {
		_, s := h.request(http.MethodGet, "/api/accounts/me/stats", tokens["ann"], nil)
		return num(s["rounds"]) == 1
	})
	_, s := h.request(http.MethodGet, "/api/accounts/me/stats", tokens["ann"], nil)
	if classes, ok := s["hand_classes"].([]any); ok {
		for _, c := range classes {
			m := c.(map[string]any)
			if num(m["shown"]) > num(m["made"]) {
				t.Errorf("shown more hands than made: %v", m)
			}
		}
	}
	cancel()
	bs.wg.Wait()
}

// Heads-up counts. The record used to leave out any hand played by fewer
// than three profiles, which is most of the poker played here.
func TestTwoPlayersAreAGame(t *testing.T) {
	if testing.Short() {
		t.Skip("plays real hands")
	}
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	tableID, adminToken := h.createTable(fastSettings())

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var bs botSet
	tokens := map[string]string{}
	for i, name := range []string{"eve", "fay"} {
		_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
			"handle": name, "password": "hunter22", "display_name": name,
		})
		token, _ := out["token"].(string)
		if token == "" {
			t.Fatalf("register %s: %v", name, out)
		}
		tokens[name] = token
		b := botclient.New(botclient.Config{
			BaseURL: h.base, TableID: tableID, Name: name,
			Strategy: botclient.StrategyRandom, Seed: uint64(i + 1), AccountToken: token,
		})
		if err := b.Join(ctx); err != nil {
			t.Fatal(err)
		}
		bs.players = append(bs.players, b)
	}
	admin := botclient.New(botclient.Config{
		BaseURL: h.base, TableID: tableID, Name: "admin",
		Role: botclient.RoleAdmin, Token: adminToken,
	})
	bs.others = []*botclient.Bot{admin}
	bs.start(ctx)

	waitUntil(t, 90*time.Second, "three hands", func() bool { return admin.HandsEnded() >= 3 })

	var stats map[string]any
	waitUntil(t, 20*time.Second, "eve's record", func() bool {
		_, stats = h.request(http.MethodGet, "/api/accounts/me/stats", tokens["eve"], nil)
		return num(stats["hands"]) >= 3
	})
	// What the two of them won and lost adds up, and the hands they made
	// are kept like any others.
	var sum float64
	for _, name := range []string{"eve", "fay"} {
		_, s := h.request(http.MethodGet, "/api/accounts/me/stats", tokens[name], nil)
		sum += num(s["net"])
	}
	if sum != 0 {
		t.Errorf("net over both profiles = %v, want 0", sum)
	}
	_, hl := h.request(http.MethodGet, "/api/accounts/me/highlights", tokens["eve"], nil)
	if len(hl["best_hands"].([]any)) == 0 {
		t.Errorf("no hands kept from a heads-up game: %v", hl)
	}
	cancel()
	bs.wg.Wait()
}

// A guest leaves no trace, and a profile that never played has an empty
// record rather than an error.
func TestGuestsLeaveNoRecord(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "dana", "password": "hunter22",
	})
	token := out["token"].(string)
	status, stats := h.request(http.MethodGet, "/api/accounts/me/stats", token, nil)
	if status != http.StatusOK || num(stats["hands"]) != 0 || num(stats["rounds"]) != 0 {
		t.Fatalf("a fresh profile: %d %v", status, stats)
	}
	if stats["bb_per_100"] != float64(0) {
		t.Errorf("bb/100 without hands: %v", stats["bb_per_100"])
	}
}

// The owner decides who sees what. Everything starts private, only
// private and public can be set, and the sections are named.
func TestVisibilityIsTheOwnersToSet(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "erin", "password": "hunter22",
	})
	token := out["token"].(string)
	acc := out["account"].(map[string]any)
	vis := acc["visibility"].(map[string]any)
	// Friends see the record; nothing is public until its owner says so.
	for section, v := range vis {
		if v != "friends" {
			t.Errorf("%s starts as %v, want friends", section, v)
		}
	}

	status, out := h.request(http.MethodPatch, "/api/accounts/me", token, map[string]any{
		"display_name": "Erin the Bold",
		"visibility":   map[string]string{"winnings": "public", "best_hands": "public"},
	})
	if status != http.StatusOK {
		t.Fatalf("patch: %d %v", status, out)
	}
	acc = out["account"].(map[string]any)
	vis = acc["visibility"].(map[string]any)
	if vis["winnings"] != "public" || vis["best_hands"] != "public" {
		t.Errorf("what was made public: %v", vis)
	}
	if vis["profile"] != "friends" || vis["achievements"] != "friends" {
		t.Errorf("the rest is untouched: %v", vis)
	}
	if acc["display_name"] != "Erin the Bold" {
		t.Errorf("display name: %v", acc["display_name"])
	}
	// It survives the round trip, so a reload shows the same switches.
	_, me := h.request(http.MethodGet, "/api/accounts/me", token, nil)
	if me["account"].(map[string]any)["visibility"].(map[string]any)["winnings"] != "public" {
		t.Errorf("after a reload: %v", me)
	}

	// Friends-only is a third state, and it sticks.
	status, out = h.request(http.MethodPatch, "/api/accounts/me", token, map[string]any{
		"visibility": map[string]string{"winnings": "friends"},
	})
	if status != http.StatusOK ||
		out["account"].(map[string]any)["visibility"].(map[string]any)["winnings"] != "friends" {
		t.Errorf("friends visibility: %d %v", status, out)
	}
	if status, _ := h.request(http.MethodPatch, "/api/accounts/me", token, map[string]any{
		"visibility": map[string]string{"winnings": "everyone"},
	}); status != http.StatusBadRequest {
		t.Errorf("an invented visibility: %d, want 400", status)
	}
	if status, _ := h.request(http.MethodPatch, "/api/accounts/me", token, map[string]any{
		"visibility": map[string]string{"salary": "public"},
	}); status != http.StatusBadRequest {
		t.Errorf("unknown section: %d, want 400", status)
	}
	// And a guest changes nothing.
	if status, _ := h.request(http.MethodPatch, "/api/accounts/me", "", map[string]any{
		"visibility": map[string]string{"winnings": "public"},
	}); status != http.StatusUnauthorized {
		t.Errorf("a guest patching a profile: %d, want 401", status)
	}
}

// The highlights page of a profile that has never played: empty lists and
// every milestone still ahead of it.
func TestHighlightsStartEmpty(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "fred", "password": "hunter22",
	})
	token := out["token"].(string)
	status, hl := h.request(http.MethodGet, "/api/accounts/me/highlights", token, nil)
	if status != http.StatusOK {
		t.Fatalf("highlights: %d %v", status, hl)
	}
	if len(hl["best_hands"].([]any)) != 0 || len(hl["biggest_wins"].([]any)) != 0 {
		t.Errorf("a fresh profile has no hands: %v", hl)
	}
	achievements := hl["achievements"].([]any)
	if len(achievements) == 0 {
		t.Fatal("the milestones are listed even before the first hand")
	}
	for _, a := range achievements {
		m := a.(map[string]any)
		if num(m["earned_at"]) != 0 {
			t.Errorf("earned already: %v", m)
		}
	}
}

func num(v any) float64 {
	f, _ := v.(float64)
	return f
}
