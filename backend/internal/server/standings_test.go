package server

import (
	"net/http"
	"testing"
	"time"

	"showdown/internal/store"
)

// TestBuildStandingsAggregates is the heart of the all-time board: rows of
// several rounds fold into one line per player, a guest is the same guest
// across rounds by name and a profile by its id, and the board is sorted by
// the money.
func TestBuildStandingsAggregates(t *testing.T) {
	rows := []store.RoundStandingRow{
		// Round 1: Alice wins, Bob busts.
		{TableID: "t1", RoundIndex: 1, Hands: 10, EndedAt: 100, Name: "Alice", NameKey: "alice",
			Place: 1, Net: 1000, Stack: 4000, HandsPlayed: 10, HandsWon: 6, BiggestPot: 900, Players: 2},
		{TableID: "t1", RoundIndex: 1, Hands: 10, EndedAt: 100, Name: "Bob", NameKey: "bob",
			Place: 2, Net: -1000, Stack: 0, HandsPlayed: 10, HandsWon: 4, BiggestPot: 700, Players: 2},
		// Round 2 on the same table: Bob takes it, and Alice is down overall.
		{TableID: "t1", RoundIndex: 2, Hands: 20, EndedAt: 200, Name: "Alice", NameKey: "alice",
			Place: 2, Net: -3000, Stack: 0, HandsPlayed: 20, HandsWon: 8, BiggestPot: 1200, Players: 2},
		{TableID: "t1", RoundIndex: 2, Hands: 20, EndedAt: 200, Name: "Bobby", NameKey: "bob",
			Place: 1, Net: 3000, Stack: 6000, HandsPlayed: 20, HandsWon: 12, BiggestPot: 2500, Players: 2},
	}
	got := buildStandings("t1", "Kitchen table", rows, nil, 200)
	if len(got.Rounds) != 2 {
		t.Fatalf("rounds = %d, want 2", len(got.Rounds))
	}
	if got.Rounds[0].Index != 1 || got.Rounds[0].Hands != 10 || len(got.Rounds[0].Standings) != 2 {
		t.Errorf("round 1 = %+v", got.Rounds[0])
	}
	if len(got.AllTime) != 2 {
		t.Fatalf("all-time rows = %d, want 2 (one per player)", len(got.AllTime))
	}
	first, second := got.AllTime[0], got.AllTime[1]
	// Bob is up 2000 over the two rounds, Alice down 2000.
	if first.Name != "Bobby" || first.Net != 2000 || first.Rounds != 2 || first.Wins != 1 {
		t.Errorf("leader = %+v, want Bobby net 2000 over 2 rounds with 1 win", first)
	}
	if first.HandsWon != 16 || first.BiggestPot != 2500 || first.BestPlace != 1 {
		t.Errorf("leader totals = %+v", first)
	}
	if second.Name != "Alice" || second.Net != -2000 || second.Wins != 1 {
		t.Errorf("second = %+v, want Alice net -2000", second)
	}
	if len(first.History) != 2 || first.History[0].Net != -1000 || first.History[1].Place != 1 {
		t.Errorf("leader history = %+v, want both rounds oldest first", first.History)
	}
	if first.LastPlayed != 200 {
		t.Errorf("last_played = %d, want the latest round", first.LastPlayed)
	}
}

// TestBuildStandingsSeparatesProfiles keeps two profiles apart even when they
// show the same display name, and keeps one profile together when the name
// changed between rounds.
func TestBuildStandingsSeparatesProfiles(t *testing.T) {
	rows := []store.RoundStandingRow{
		{TableID: "t1", RoundIndex: 1, EndedAt: 10, AccountID: "acc1", Name: "Sam", NameKey: "sam", Net: 100},
		{TableID: "t1", RoundIndex: 1, EndedAt: 10, AccountID: "acc2", Name: "Sam", NameKey: "sam", Net: 50},
		{TableID: "t1", RoundIndex: 2, EndedAt: 20, AccountID: "acc1", Name: "Samantha", NameKey: "samantha", Net: 400},
	}
	got := buildStandings("t1", "T", rows, nil, 20)
	if len(got.AllTime) != 2 {
		t.Fatalf("all-time rows = %d, want 2", len(got.AllTime))
	}
	if got.AllTime[0].Name != "Samantha" || got.AllTime[0].Net != 500 || got.AllTime[0].Rounds != 2 {
		t.Errorf("acc1 = %+v, want the two rounds under the newest name", got.AllTime[0])
	}
}

// TestBuildStandingsSession keeps the board of the current session apart
// from the all-time one: rounds a long break ago are not tonight, and a
// table nobody played for a while has no session at all.
func TestBuildStandingsSession(t *testing.T) {
	hour := time.Hour.Milliseconds()
	rows := []store.RoundStandingRow{
		// Last week.
		{TableID: "t1", RoundIndex: 1, EndedAt: 0, Name: "Alice", NameKey: "alice", Place: 1, Net: 5000},
		{TableID: "t1", RoundIndex: 1, EndedAt: 0, Name: "Bob", NameKey: "bob", Place: 2, Net: -5000},
		// Tonight, two rounds an hour apart.
		{TableID: "t1", RoundIndex: 2, EndedAt: 168 * hour, Name: "Alice", NameKey: "alice", Place: 2, Net: -1000},
		{TableID: "t1", RoundIndex: 2, EndedAt: 168 * hour, Name: "Bob", NameKey: "bob", Place: 1, Net: 1000},
		{TableID: "t1", RoundIndex: 3, EndedAt: 169 * hour, Name: "Bob", NameKey: "bob", Place: 1, Net: 500},
	}
	highlights := []store.RoundHighlightRow{
		{RoundIndex: 2, Hand: 14, Amount: 3200, Winners: []string{"Bob"}, Description: "Full House"},
	}
	got := buildStandings("t1", "T", rows, highlights, 170*hour)
	if got.SessionFrom != 2 {
		t.Fatalf("session from = %d, want round 2", got.SessionFrom)
	}
	if len(got.Session) != 2 || got.Session[0].Name != "Bob" || got.Session[0].Net != 1500 || got.Session[0].Rounds != 2 {
		t.Errorf("session = %+v, want Bob up 1500 over the two rounds", got.Session)
	}
	if got.AllTime[0].Name != "Alice" || got.AllTime[0].Net != 4000 {
		t.Errorf("all time = %+v, want Alice still up over everything", got.AllTime)
	}
	if b := got.Rounds[1].BiggestPot; b == nil || b.Amount != 3200 || b.Winners[0] != "Bob" || b.Hand != 14 {
		t.Errorf("round 2 biggest pot = %+v", b)
	}
	if got.Rounds[0].BiggestPot != nil {
		t.Errorf("round 1 has a biggest pot it never recorded: %+v", got.Rounds[0].BiggestPot)
	}

	// The next evening: nothing finished yet belongs to it.
	later := buildStandings("t1", "T", rows, highlights, 190*hour)
	if later.SessionFrom != 0 || len(later.Session) != 0 {
		t.Errorf("stale session = from %d, %+v; want none", later.SessionFrom, later.Session)
	}
}

// TestTableStandingsSurviveRestart is the report: a round ends, a new one is
// opened on the same table, and the record of the first round is still there.
func TestTableStandingsSurviveRestart(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, adminToken := h.createTable(fastSettings())

	status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "chubby"})
	if status != http.StatusOK && status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, out)
	}
	token, _ := out["player_token"].(string)

	for round := 1; round <= 2; round++ {
		if st, o := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/end", adminToken, map[string]any{"immediate": true}); st != http.StatusOK {
			t.Fatalf("end round %d: %d %v", round, st, o)
		}
		if round == 1 {
			if st, o := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/restart", adminToken, nil); st != http.StatusOK {
				t.Fatalf("restart: %d %v", st, o)
			}
		}
	}

	// The rows are written on the table's persister, so give it a moment.
	var rounds []any
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		st, body := h.request(http.MethodGet, "/api/tables/"+tableID+"/standings", token, nil)
		if st != http.StatusOK {
			t.Fatalf("standings: %d %v", st, body)
		}
		rounds, _ = body["rounds"].([]any)
		if len(rounds) == 2 {
			all, _ := body["all_time"].([]any)
			if len(all) != 1 {
				t.Fatalf("all_time = %v, want the one player once", all)
			}
			entry, _ := all[0].(map[string]any)
			if entry["name"] != "chubby" {
				t.Errorf("all_time[0].name = %v, want chubby", entry["name"])
			}
			if n, _ := entry["rounds"].(float64); n != 2 {
				t.Errorf("all_time[0].rounds = %v, want 2", entry["rounds"])
			}
			return
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatalf("rounds = %d after both rounds ended, want 2", len(rounds))
}

// TestTableStandingsNeedsASeat refuses a caller who is not at the table.
func TestTableStandingsNeedsASeat(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, _ := h.createTable(fastSettings())
	if st, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/standings", "", nil); st != http.StatusUnauthorized {
		t.Errorf("status = %d without a token, want 401", st)
	}
}
