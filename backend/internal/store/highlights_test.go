package store

import (
	"context"
	"testing"
)

// hand builds a finished hand for the profile, with the parts the
// highlights care about.
func hand(n int, at int64, category int, royal bool, won int64) HandResultRow {
	return HandResultRow{
		AccountID: "u1", TableID: "t1", TableName: "Kitchen table",
		HandNumber: n, EndedAt: at, BigBlind: 50, Net: won - 100, Won: won,
		DealtIn: true, Category: category, Royal: royal,
		Description: "hand", BestCards: "As Ks Qs Js Ts", Counted: true, Profiles: 3,
	}
}

func profile(t *testing.T, s *Store, ctx context.Context) {
	t.Helper()
	err := s.CreateAccount(ctx, AccountRow{
		ID: "u1", Handle: "ann", HandleKey: "ann", DisplayName: "Ann",
		PasswordHash: "x", CreatedAt: 1000,
		VisProfile: "private", VisWinnings: "private", VisBestHands: "private",
		VisAchievements: "private", VisActivity: "private",
	})
	if err != nil {
		t.Fatalf("CreateAccount: %v", err)
	}
}

func TestBestHandsRankBeforeSize(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	profile(t, s, ctx)

	// A royal, quads, and a pair that won far more than either.
	rows := []HandResultRow{
		hand(1, 1_000, 1, false, 12_000), // pair, the biggest pot
		hand(2, 2_000, 7, false, 400),    // quads
		hand(3, 3_000, 8, true, 300),     // royal flush
		hand(4, 4_000, 8, false, 900),    // straight flush
	}
	if err := s.InsertHandResults(ctx, rows); err != nil {
		t.Fatalf("InsertHandResults: %v", err)
	}

	best, err := s.BestHands(ctx, "u1", 8)
	if err != nil {
		t.Fatalf("BestHands: %v", err)
	}
	if len(best) != 4 {
		t.Fatalf("got %d hands, want 4", len(best))
	}
	// The royal leads, then the straight flush, then quads: what the hand
	// was beats what it paid.
	if !best[0].Royal || best[1].Category != 8 || best[2].Category != 7 {
		t.Errorf("best hands out of order: %+v", best)
	}
	if best[0].TableName != "Kitchen table" || best[0].BestCards == "" {
		t.Errorf("a best hand carries where and what: %+v", best[0])
	}

	// The biggest pot is a different list, and in big blinds.
	biggest, err := s.BiggestWins(ctx, "u1", 8)
	if err != nil {
		t.Fatalf("BiggestWins: %v", err)
	}
	if biggest[0].Won != 12_000 || biggest[0].WonBB() != 240 {
		t.Errorf("biggest win: %+v (%.1f bb)", biggest[0], biggest[0].WonBB())
	}
}

func TestAchievementsAreEarnedWhenTheyHappened(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	profile(t, s, ctx)

	var rows []HandResultRow
	// 120 plain hands, one per second, the 40th a royal flush.
	for i := 1; i <= 120; i++ {
		h := hand(i, int64(i)*1_000, 0, false, 0)
		if i == 40 {
			h = hand(i, int64(i)*1_000, 8, true, 0)
		}
		rows = append(rows, h)
	}
	// One hand that wins 100 big blinds without a showdown.
	big := hand(121, 200_000, 1, false, 5_000)
	rows = append(rows, big)
	if err := s.InsertHandResults(ctx, rows); err != nil {
		t.Fatalf("InsertHandResults: %v", err)
	}
	if err := s.InsertRoundResults(ctx, []RoundResultRow{{
		AccountID: "u1", TableID: "t1", TableName: "Kitchen table",
		EndedAt: 300_000, BigBlind: 50, Net: 4_000, Place: 1, Players: 4,
		Tournament: true, Counted: true,
	}}); err != nil {
		t.Fatalf("InsertRoundResults: %v", err)
	}

	got := map[string]Achievement{}
	list, err := s.AccountAchievements(ctx, "u1")
	if err != nil {
		t.Fatalf("AccountAchievements: %v", err)
	}
	for _, a := range list {
		got[a.ID] = a
	}
	if a := got[AchRoyalFlush]; a.EarnedAt != 40_000 {
		t.Errorf("the royal flush is dated when it was made: %+v", a)
	}
	// The hundredth hand earns it, not the last one played.
	if a := got[AchHands100]; a.EarnedAt != 100_000 || a.Progress != 100 || a.Goal != 100 {
		t.Errorf("hands_100: %+v", a)
	}
	if a := got[AchHands1000]; a.EarnedAt != 0 || a.Progress != 121 || a.Goal != 1000 {
		t.Errorf("an unearned milestone shows the way there: %+v", a)
	}
	if a := got[AchBigPot]; a.EarnedAt != 200_000 {
		t.Errorf("big_pot: %+v", a)
	}
	if a := got[AchRoundWin]; a.EarnedAt != 300_000 {
		t.Errorf("round_win: %+v", a)
	}
	if a := got[AchTournamentWin]; a.EarnedAt != 300_000 {
		t.Errorf("tournament_win: %+v", a)
	}
	if a := got[AchQuads]; a.EarnedAt != 0 {
		t.Errorf("quads were never made: %+v", a)
	}
}

func TestAnEmptyProfileHasNoHighlights(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	profile(t, s, ctx)

	best, err := s.BestHands(ctx, "u1", 8)
	if err != nil || len(best) != 0 {
		t.Fatalf("BestHands: %v %v", best, err)
	}
	list, err := s.AccountAchievements(ctx, "u1")
	if err != nil {
		t.Fatalf("AccountAchievements: %v", err)
	}
	for _, a := range list {
		if a.EarnedAt != 0 || a.Progress != 0 {
			t.Errorf("nothing is earned yet: %+v", a)
		}
	}
}
