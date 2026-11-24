package store

import (
	"context"
	"testing"
)

// TestRoundStandingsAndHighlights writes two rounds of one table, the first
// with its biggest pot, and reads both back under the indexes the store gave
// them.
func TestRoundStandingsAndHighlights(t *testing.T) {
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	if err := s.CreateTable(ctx, TableRow{ID: "t1", Name: "T", State: "running", ButtonSeat: -1, RoundBest: `{"amount":5}`}, sampleSettings("t1")); err != nil {
		t.Fatal(err)
	}
	row := RoundStandingRow{TableID: "t1", TableName: "T", Name: "Alice", NameKey: "alice", Net: 100}
	best := &RoundHighlightRow{Hand: 7, Amount: 2400, Winners: []string{"Alice", "Bob"}, Description: "Two Pair"}
	if err := s.InsertRoundStandings(ctx, []RoundStandingRow{row}, best); err != nil {
		t.Fatal(err)
	}
	if err := s.InsertRoundStandings(ctx, []RoundStandingRow{row}, nil); err != nil {
		t.Fatal(err)
	}
	rows, err := s.ListRoundStandings(ctx, "t1")
	if err != nil || len(rows) != 2 || rows[0].RoundIndex != 1 || rows[1].RoundIndex != 2 {
		t.Fatalf("rows = %+v, %v", rows, err)
	}
	hl, err := s.ListRoundHighlights(ctx, "t1")
	if err != nil || len(hl) != 1 {
		t.Fatalf("highlights = %+v, %v", hl, err)
	}
	if h := hl[0]; h.RoundIndex != 1 || h.Hand != 7 || h.Amount != 2400 || len(h.Winners) != 2 || h.Description != "Two Pair" {
		t.Errorf("highlight = %+v", h)
	}
	tr, _, err := s.GetTable(ctx, "t1")
	if err != nil || tr.RoundBest != `{"amount":5}` {
		t.Errorf("round best = %q, %v", tr.RoundBest, err)
	}
}
