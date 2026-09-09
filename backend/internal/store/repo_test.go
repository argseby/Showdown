package store

import (
	"context"
	"errors"
	"testing"
)

func sampleSettings(id string) SettingsRow {
	return SettingsRow{
		TableID: id, MaxPlayers: 9, StartMoney: 10000, SmallBlind: 50, BigBlind: 100, Ante: 0,
		TurnTime: 30, DisconnectedTurnTime: 10, SitOutAfterMissedTurns: 2, JoinPolicy: "always",
		AllowSpectators: true, SpectatorChat: true, ChatEnabled: true, AllowRebuy: true,
		ShowdownReveal: "all", AutoStart: true, HandDelayMs: 5000, Variant: "holdem",
	}
}

func TestTablesAndSettings(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())

	tr := TableRow{ID: "abc", Name: "Friday", State: "waiting", CreatedAt: 100, ButtonSeat: -1}
	if err := s.CreateTable(ctx, tr, sampleSettings("abc")); err != nil {
		t.Fatal(err)
	}
	got, st, err := s.GetTable(ctx, "abc")
	if err != nil || got != tr || st != sampleSettings("abc") {
		t.Fatalf("GetTable = %+v %+v %v", got, st, err)
	}
	tr.State, tr.HandNumber, tr.ButtonSeat = "running", 3, 4
	if err := s.UpdateTable(ctx, tr); err != nil {
		t.Fatal(err)
	}
	st.BigBlind, st.PasswordHash, st.AllowSpectators = 200, "hash", false
	if err := s.SaveSettings(ctx, st); err != nil {
		t.Fatal(err)
	}
	got, st2, _ := s.GetTable(ctx, "abc")
	if got.State != "running" || got.HandNumber != 3 || got.ButtonSeat != 4 || st2 != st {
		t.Fatalf("after update: %+v %+v", got, st2)
	}
	if _, _, err := s.GetTable(ctx, "nope"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("missing table: %v", err)
	}
	if err := s.UpdateTable(ctx, TableRow{ID: "nope"}); !errors.Is(err, ErrNotFound) {
		t.Fatalf("update missing: %v", err)
	}

	ended := TableRow{ID: "old", Name: "Old", State: "ended", CreatedAt: 50, EndedAt: 60, ButtonSeat: -1}
	if err := s.CreateTable(ctx, ended, sampleSettings("old")); err != nil {
		t.Fatal(err)
	}
	if list, _ := s.ListTables(ctx, false); len(list) != 1 || list[0].ID != "abc" {
		t.Fatalf("non-ended list = %+v", list)
	}
	if list, _ := s.ListTables(ctx, true); len(list) != 2 || list[0].ID != "abc" || list[1].EndedAt != 60 {
		t.Fatalf("full list = %+v", list)
	}
	counts, _ := s.CountTablesByState(ctx)
	if counts["running"] != 1 || counts["ended"] != 1 {
		t.Fatalf("counts = %v", counts)
	}
	if err := s.DeleteTable(ctx, "old"); err != nil {
		t.Fatal(err)
	}
	if err := s.DeleteTable(ctx, "old"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("delete twice: %v", err)
	}
	if _, err := s.getSettings(ctx, "old"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("settings must cascade: %v", err)
	}
}

func TestPlayersSessionsChat(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	if err := s.CreateTable(ctx, TableRow{ID: "t1", Name: "T", State: "waiting", CreatedAt: 1, ButtonSeat: -1}, sampleSettings("t1")); err != nil {
		t.Fatal(err)
	}
	p := PlayerRow{ID: "p1", TableID: "t1", Name: "Alice", Seat: 2, Stack: 10000, Status: "active", BuyInTotal: 10000, JoinedAt: 5}
	if err := s.UpsertPlayer(ctx, p); err != nil {
		t.Fatal(err)
	}
	p.Stack, p.Muted, p.HandsWon, p.LeftAt = 12000, true, 2, 9
	if err := s.UpsertPlayer(ctx, p); err != nil {
		t.Fatal(err)
	}
	players, err := s.ListPlayers(ctx, "t1")
	if err != nil || len(players) != 1 || players[0] != p {
		t.Fatalf("players = %+v %v", players, err)
	}

	sess := SessionRow{TokenHash: "h1", Kind: "player", TableID: "t1", PlayerID: "p1", Name: "Alice", CreatedAt: 5, ExpiresAt: 1000}
	if err := s.CreateSession(ctx, sess); err != nil {
		t.Fatal(err)
	}
	if got, err := s.GetSession(ctx, "h1", 500); err != nil || got != sess {
		t.Fatalf("session = %+v %v", got, err)
	}
	if _, err := s.GetSession(ctx, "h1", 1000); !errors.Is(err, ErrNotFound) {
		t.Fatalf("expired session: %v", err)
	}
	if err := s.CreateSession(ctx, SessionRow{TokenHash: "h2", Kind: "spectator", TableID: "t1", Name: "Bob", CreatedAt: 5, ExpiresAt: 1000}); err != nil {
		t.Fatal(err)
	}
	if list, _ := s.ListSessions(ctx, "t1", 500); len(list) != 2 {
		t.Fatalf("sessions = %+v", list)
	}
	if err := s.DeleteSessionsForPlayer(ctx, "t1", "p1"); err != nil {
		t.Fatal(err)
	}
	if err := s.DeleteSession(ctx, "h2"); err != nil {
		t.Fatal(err)
	}
	if list, _ := s.ListSessions(ctx, "t1", 500); len(list) != 0 {
		t.Fatalf("sessions after delete = %+v", list)
	}

	var ids []int64
	for i := 0; i < 5; i++ {
		id, err := s.InsertChat(ctx, ChatRow{TableID: "t1", AuthorKind: "player", AuthorName: "Alice", Text: "hi", TS: int64(i)})
		if err != nil {
			t.Fatal(err)
		}
		ids = append(ids, id)
	}
	recent, err := s.RecentChat(ctx, "t1", 3)
	if err != nil || len(recent) != 3 || recent[0].ID != ids[2] || recent[2].ID != ids[4] {
		t.Fatalf("recent = %+v %v", recent, err)
	}
	if err := s.DeleteChat(ctx, "t1", ids[4]); err != nil {
		t.Fatal(err)
	}
	if err := s.DeleteChat(ctx, "t1", ids[4]); !errors.Is(err, ErrNotFound) {
		t.Fatalf("delete twice: %v", err)
	}
}

func TestHandsResultsAudit(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	if err := s.CreateTable(ctx, TableRow{ID: "t1", Name: "T", State: "running", CreatedAt: 1, ButtonSeat: -1}, sampleSettings("t1")); err != nil {
		t.Fatal(err)
	}
	h1, err := s.InsertHand(ctx, HandRow{TableID: "t1", Number: 1, StartedAt: 10, ButtonSeat: 0, SmallBlind: 50, BigBlind: 100, StacksAtStart: []byte(`{"0":100}`)})
	if err != nil {
		t.Fatal(err)
	}
	if err := s.FinishHand(ctx, h1, 20, []byte(`[{"seq":1}]`), []byte(`{"pots":[]}`), false); err != nil {
		t.Fatal(err)
	}
	h2, err := s.InsertHand(ctx, HandRow{TableID: "t1", Number: 2, StartedAt: 30, ButtonSeat: 1, SmallBlind: 50, BigBlind: 100, StacksAtStart: []byte(`{"0":90}`)})
	if err != nil {
		t.Fatal(err)
	}
	voided, err := s.VoidOpenHands(ctx, "t1", 40)
	if err != nil || len(voided) != 1 || voided[0].ID != h2 || voided[0].Number != 2 || string(voided[0].StacksAtStart) != `{"0":90}` {
		t.Fatalf("voided = %+v %v", voided, err)
	}
	hands, err := s.ListHands(ctx, "t1", 10, 0)
	if err != nil || len(hands) != 2 || hands[0].Number != 2 || !hands[0].Voided || hands[0].EndedAt != 40 || hands[0].Results != nil ||
		hands[1].Number != 1 || string(hands[1].Results) != `{"pots":[]}` || string(hands[1].Events) != `[{"seq":1}]` {
		t.Fatalf("hands = %+v %v", hands, err)
	}
	if hands, _ := s.ListHands(ctx, "t1", 10, 2); len(hands) != 1 || hands[0].Number != 1 {
		t.Fatalf("hands before 2 = %+v", hands)
	}

	if err := s.InsertAdminAction(ctx, AdminActionRow{TS: 1, Action: "kick", TableID: "t1", PlayerID: "p1"}); err != nil {
		t.Fatal(err)
	}
	var n int
	if err := s.DB().QueryRow(`SELECT COUNT(*) FROM admin_actions WHERE details = '{}'`).Scan(&n); err != nil || n != 1 {
		t.Fatalf("audit rows = %d %v", n, err)
	}

	// Retention: mark t1 ended long ago and purge.
	if err := s.UpdateTable(ctx, TableRow{ID: "t1", Name: "T", State: "ended", EndedAt: 100, ButtonSeat: -1}); err != nil {
		t.Fatal(err)
	}
	if _, err := s.InsertChat(ctx, ChatRow{TableID: "t1", AuthorKind: "system", AuthorName: "system", Text: "x", TS: 1}); err != nil {
		t.Fatal(err)
	}
	if n, err := s.PurgeEndedTableData(ctx, 50); err != nil || n != 0 {
		t.Fatalf("purge before cutoff = %d %v", n, err)
	}
	if n, err := s.PurgeEndedTableData(ctx, 200); err != nil || n != 1 {
		t.Fatalf("purge = %d %v", n, err)
	}
	if hands, _ := s.ListHands(ctx, "t1", 10, 0); len(hands) != 0 {
		t.Fatal("hands not purged")
	}
	if chat, _ := s.RecentChat(ctx, "t1", 10); len(chat) != 0 {
		t.Fatal("chat not purged")
	}
	if _, _, err := s.GetTable(ctx, "t1"); err != nil {
		t.Fatal("the table itself must survive retention")
	}
}
