package store

import (
	"context"
	"database/sql"
	"fmt"
)

// HandHighlight is one hand worth keeping: what it was, what it paid and
// where it happened. Counted says whether the hand may ever stand in a
// public total (see the hand_results columns).
type HandHighlight struct {
	Category    int
	Royal       bool
	Description string
	BestCards   string
	Net         int64
	Won         int64
	BigBlind    int64
	TableID     string
	TableName   string
	HandNumber  int
	EndedAt     int64
	Shown       bool
	Counted     bool
}

// WonBB is the pot in big blinds: the only figure that compares hands
// played at different stakes.
func (h HandHighlight) WonBB() float64 {
	if h.BigBlind <= 0 {
		return 0
	}
	return float64(h.Won) / float64(h.BigBlind)
}

const highlightColumns = `category, royal, description, best_cards, net, won, big_blind,
	table_id, table_name, hand_number, ended_at, shown, counted`

func scanHighlights(rows *sql.Rows) ([]HandHighlight, error) {
	defer rows.Close()
	var out []HandHighlight
	for rows.Next() {
		var h HandHighlight
		var royal, shown, counted int
		if err := rows.Scan(&h.Category, &royal, &h.Description, &h.BestCards, &h.Net, &h.Won,
			&h.BigBlind, &h.TableID, &h.TableName, &h.HandNumber, &h.EndedAt, &shown, &counted); err != nil {
			return nil, err
		}
		h.Royal, h.Shown, h.Counted = royal == 1, shown == 1, counted == 1
		out = append(out, h)
	}
	return out, rows.Err()
}

// BestHands returns the strongest hands a profile ever made, best first.
// Mucked hands count: the record is the player's own, and what the table
// was shown is kept on the row for the public page to filter by.
func (s *Store) BestHands(ctx context.Context, accountID string, limit int) ([]HandHighlight, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+highlightColumns+`
		FROM hand_results WHERE account_id = ? AND category >= 0
		ORDER BY royal DESC, category DESC, won DESC, ended_at DESC LIMIT ?`, accountID, limit)
	if err != nil {
		return nil, fmt.Errorf("best hands: %w", err)
	}
	return scanHighlights(rows)
}

// PublicBestHands is BestHands as somebody else may see it: only hands the
// table actually saw, and only from rounds that count. A hand nobody was
// shown stays the player's own business.
func (s *Store) PublicBestHands(ctx context.Context, accountID string, limit int) ([]HandHighlight, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+highlightColumns+`
		FROM hand_results
		WHERE account_id = ? AND category >= 0 AND shown = 1 AND counted = 1
		ORDER BY royal DESC, category DESC, won DESC, ended_at DESC LIMIT ?`, accountID, limit)
	if err != nil {
		return nil, fmt.Errorf("public best hands: %w", err)
	}
	return scanHighlights(rows)
}

// BiggestWins returns the largest pots a profile won, in big blinds.
func (s *Store) BiggestWins(ctx context.Context, accountID string, limit int) ([]HandHighlight, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+highlightColumns+`
		FROM hand_results WHERE account_id = ? AND won > 0 AND big_blind > 0
		ORDER BY CAST(won AS REAL) / big_blind DESC, ended_at DESC LIMIT ?`, accountID, limit)
	if err != nil {
		return nil, fmt.Errorf("biggest wins: %w", err)
	}
	return scanHighlights(rows)
}
