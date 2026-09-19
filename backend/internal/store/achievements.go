package store

import (
	"context"
	"database/sql"
	"fmt"
)

// Achievement is one milestone of a profile. EarnedAt is when it was
// reached (0 while it is not), and the counted ones also carry how far
// along the profile is, so the page can show the way there rather than a
// locked box.
type Achievement struct {
	ID       string
	EarnedAt int64
	Progress int
	Goal     int
}

// The milestones, in the order the page shows them. The ids are the
// contract with the app, which puts the names and the wording on them.
const (
	AchRoyalFlush    = "royal_flush"
	AchStraightFlush = "straight_flush"
	AchQuads         = "quads"
	AchFullHouse     = "full_house"
	AchBigPot        = "big_pot"
	AchAllInWin      = "all_in_win"
	AchHands100      = "hands_100"
	AchHands1000     = "hands_1000"
	AchBluffs25      = "bluffs_25"
	AchRoundWin      = "round_win"
	AchPodium3       = "podium_3"
	AchTournamentWin = "tournament_win"
)

// bigPotBlinds is the pot a hand has to win to count as a big one. In big
// blinds, so a table's stakes do not decide who gets it.
const bigPotBlinds = 100

// AccountAchievements reads a profile's milestones. An empty record is no
// error: everything is simply unearned.
func (s *Store) AccountAchievements(ctx context.Context, accountID string) ([]Achievement, error) {
	var royalAt, sfAt, quadsAt, houseAt, bigPotAt, allInAt sql.NullInt64
	var hands, bluffs int
	err := s.db.QueryRowContext(ctx, `
		SELECT MIN(CASE WHEN royal = 1 THEN ended_at END),
			MIN(CASE WHEN category = 8 THEN ended_at END),
			MIN(CASE WHEN category = 7 THEN ended_at END),
			MIN(CASE WHEN category = 6 THEN ended_at END),
			MIN(CASE WHEN big_blind > 0 AND won >= ? * big_blind THEN ended_at END),
			MIN(CASE WHEN all_in = 1 AND won > 0 THEN ended_at END),
			COUNT(*),
			COALESCE(SUM(CASE WHEN won > 0 AND showdown = 0 THEN 1 ELSE 0 END), 0)
		FROM hand_results WHERE account_id = ?`, bigPotBlinds, accountID).Scan(
		&royalAt, &sfAt, &quadsAt, &houseAt, &bigPotAt, &allInAt, &hands, &bluffs)
	if err != nil {
		return nil, fmt.Errorf("account achievements: %w", err)
	}

	var roundAt, tourneyAt sql.NullInt64
	var podiums int
	err = s.db.QueryRowContext(ctx, `
		SELECT MIN(CASE WHEN place = 1 THEN ended_at END),
			MIN(CASE WHEN place = 1 AND tournament = 1 THEN ended_at END),
			COALESCE(SUM(CASE WHEN place BETWEEN 1 AND 3 AND players >= 3 THEN 1 ELSE 0 END), 0)
		FROM round_results WHERE account_id = ?`, accountID).Scan(
		&roundAt, &tourneyAt, &podiums)
	if err != nil {
		return nil, fmt.Errorf("account round achievements: %w", err)
	}

	// The counted ones are earned by the row that crossed the goal, so the
	// date on the page is the day it happened, not today.
	counted := func(id string, have, goal int, query string) (Achievement, error) {
		a := Achievement{ID: id, Progress: min(have, goal), Goal: goal}
		if have < goal {
			return a, nil
		}
		var at int64
		err := s.db.QueryRowContext(ctx, query, accountID, goal-1).Scan(&at)
		if err != nil && err != sql.ErrNoRows {
			return a, fmt.Errorf("achievement %s: %w", id, err)
		}
		a.EarnedAt = at
		return a, nil
	}
	const nthHand = `SELECT ended_at FROM hand_results WHERE account_id = ?
		ORDER BY ended_at LIMIT 1 OFFSET ?`
	const nthBluff = `SELECT ended_at FROM hand_results
		WHERE account_id = ? AND won > 0 AND showdown = 0
		ORDER BY ended_at LIMIT 1 OFFSET ?`
	const nthPodium = `SELECT ended_at FROM round_results
		WHERE account_id = ? AND place BETWEEN 1 AND 3 AND players >= 3
		ORDER BY ended_at LIMIT 1 OFFSET ?`

	out := []Achievement{
		{ID: AchRoyalFlush, EarnedAt: royalAt.Int64},
		{ID: AchStraightFlush, EarnedAt: sfAt.Int64},
		{ID: AchQuads, EarnedAt: quadsAt.Int64},
		{ID: AchFullHouse, EarnedAt: houseAt.Int64},
		{ID: AchBigPot, EarnedAt: bigPotAt.Int64},
		{ID: AchAllInWin, EarnedAt: allInAt.Int64},
	}
	for _, c := range []struct {
		id    string
		have  int
		goal  int
		query string
	}{
		{AchHands100, hands, 100, nthHand},
		{AchHands1000, hands, 1000, nthHand},
		{AchBluffs25, bluffs, 25, nthBluff},
	} {
		a, err := counted(c.id, c.have, c.goal, c.query)
		if err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	out = append(out, Achievement{ID: AchRoundWin, EarnedAt: roundAt.Int64})
	podium, err := counted(AchPodium3, podiums, 3, nthPodium)
	if err != nil {
		return nil, err
	}
	out = append(out, podium, Achievement{ID: AchTournamentWin, EarnedAt: tourneyAt.Int64})
	return out, nil
}
