package store

import (
	"context"
	"database/sql"
	"fmt"
)

// ProfileStats is everything a player's own page shows, aggregated from the
// per-hand and per-round records.
type ProfileStats struct {
	// Volume.
	Hands     int
	Tables    int
	Rounds    int
	FirstHand int64
	LastHand  int64

	// Money. Chips are only comparable across tables in big blinds, so both
	// are kept; Counted* leaves out the hands that stand in no public total.
	Net          int64
	NetBB        float64
	CountedHands int
	CountedNet   int64
	CountedNetBB float64
	BiggestPot   int64
	BiggestWin   int64
	BestRound    int64
	HandsWon     int
	RoundsWon    int
	Podiums      int
	Tournaments  int

	// Style.
	VPIP               int
	Showdowns          int
	ShowdownsWon       int
	WonWithoutShowdown int
	Folded             int
	AllIns             int

	// What the hands made, by poker category (0 high card .. 8 straight
	// flush) and the royal flush apart. Shown is what the table saw.
	Categories []CategoryCount
}

// CategoryCount is how often one kind of hand was made, and how much of
// that everyone else got to see.
type CategoryCount struct {
	Category int
	Royal    bool
	Made     int
	Shown    int
}

// AccountStats aggregates a profile's record. An empty record is not an
// error: a new profile simply has nothing yet.
func (s *Store) AccountStats(ctx context.Context, accountID string) (ProfileStats, error) {
	var st ProfileStats
	var first, last sql.NullInt64
	var netBB, countedNetBB sql.NullFloat64
	err := s.db.QueryRowContext(ctx, `
		SELECT COUNT(*),
			COUNT(DISTINCT table_id),
			MIN(ended_at), MAX(ended_at),
			COALESCE(SUM(net), 0),
			SUM(CAST(net AS REAL) / big_blind),
			COALESCE(SUM(CASE WHEN counted = 1 THEN 1 ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN counted = 1 THEN net ELSE 0 END), 0),
			SUM(CASE WHEN counted = 1 THEN CAST(net AS REAL) / big_blind ELSE 0 END),
			COALESCE(MAX(won), 0),
			COALESCE(MAX(net), 0),
			COALESCE(SUM(CASE WHEN won > 0 THEN 1 ELSE 0 END), 0),
			COALESCE(SUM(vpip), 0),
			COALESCE(SUM(showdown), 0),
			COALESCE(SUM(showdown_won), 0),
			COALESCE(SUM(CASE WHEN won > 0 AND showdown = 0 THEN 1 ELSE 0 END), 0),
			COALESCE(SUM(folded), 0),
			COALESCE(SUM(all_in), 0)
		FROM hand_results WHERE account_id = ?`, accountID).Scan(
		&st.Hands, &st.Tables, &first, &last, &st.Net, &netBB,
		&st.CountedHands, &st.CountedNet, &countedNetBB,
		&st.BiggestPot, &st.BiggestWin, &st.HandsWon,
		&st.VPIP, &st.Showdowns, &st.ShowdownsWon, &st.WonWithoutShowdown,
		&st.Folded, &st.AllIns)
	if err != nil {
		return ProfileStats{}, fmt.Errorf("account stats: %w", err)
	}
	st.FirstHand, st.LastHand = scanNullInt(first), scanNullInt(last)
	st.NetBB, st.CountedNetBB = netBB.Float64, countedNetBB.Float64

	err = s.db.QueryRowContext(ctx, `
		SELECT COUNT(*),
			COALESCE(SUM(CASE WHEN place = 1 THEN 1 ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN place BETWEEN 1 AND 3 AND players >= 3 THEN 1 ELSE 0 END), 0),
			COALESCE(SUM(tournament), 0),
			COALESCE(MAX(net), 0)
		FROM round_results WHERE account_id = ?`, accountID).Scan(
		&st.Rounds, &st.RoundsWon, &st.Podiums, &st.Tournaments, &st.BestRound)
	if err != nil {
		return ProfileStats{}, fmt.Errorf("account round stats: %w", err)
	}

	rows, err := s.db.QueryContext(ctx, `
		SELECT category, royal, COUNT(*), COALESCE(SUM(shown), 0)
		FROM hand_results WHERE account_id = ? AND category >= 0
		GROUP BY category, royal ORDER BY category DESC, royal DESC`, accountID)
	if err != nil {
		return ProfileStats{}, fmt.Errorf("account hand classes: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var c CategoryCount
		var royal int
		if err := rows.Scan(&c.Category, &royal, &c.Made, &c.Shown); err != nil {
			return ProfileStats{}, err
		}
		c.Royal = royal == 1
		st.Categories = append(st.Categories, c)
	}
	return st, rows.Err()
}
