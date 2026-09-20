package table

import (
	"context"
	"strings"

	"showdown/internal/poker"
	"showdown/internal/store"
)

// recordHandResults keeps what every signed-in player did in this hand. It
// runs while the engine still holds the hand, so a mucked hand can be
// counted without ever being put into an event.
func (t *Table) recordHandResults() {
	if t.hand == nil || t.hand.Results() == nil {
		return
	}
	res := t.hand.Results()
	profiles := 0
	for _, p := range t.seats[:maxSeats] {
		if p != nil && p.inHand && p.AccountID != "" {
			profiles++
		}
	}
	ended := t.nowMs()
	var rows []store.HandResultRow
	for _, p := range t.seats[:maxSeats] {
		if p == nil || !p.inHand || p.AccountID == "" {
			continue
		}
		sr, ok := res.Seats[p.Seat]
		if !ok {
			continue
		}
		row := store.HandResultRow{
			AccountID: p.AccountID, TableID: t.ID, TableName: t.name,
			HandNumber: t.handNumber, EndedAt: ended, BigBlind: t.settings.BigBlind,
			Net: sr.Net, Won: sr.Won, DealtIn: true, Folded: sr.Folded,
			VPIP: p.vpipThisHand, AllIn: sr.AllIn,
			Category: -1, Profiles: profiles,
		}
		// At the showdown when the hand was still live and contested.
		row.Showdown = !sr.Folded && t.contested()
		row.ShowdownWon = row.Showdown && sr.Won > 0
		if v, ok := t.hand.MadeHand(p.Seat); ok {
			row.Category = int(v.Category)
			row.Royal = poker.IsRoyalFlush(v)
			row.Description = v.Describe()
			row.BestCards = strings.Join(cardStrings(v.Best[:]), " ")
			// Shown means the table saw it; a mucked hand is only ever on
			// the player's own record.
			row.Shown = sr.Revealed
		}
		rows = append(rows, row)
	}
	if len(rows) == 0 {
		return
	}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.InsertHandResults(ctx, rows)
	})
}

// recordRoundResults keeps the end of a round for every signed-in player;
// it runs from endTable, where the placements are final.
func (t *Table) recordRoundResults() {
	profiles, players := 0, 0
	for _, p := range t.seats[:maxSeats] {
		if p == nil {
			continue
		}
		players++
		if p.AccountID != "" {
			profiles++
		}
	}
	var rows []store.RoundResultRow
	for _, p := range t.seats[:maxSeats] {
		if p == nil || p.AccountID == "" {
			continue
		}
		rows = append(rows, store.RoundResultRow{
			AccountID: p.AccountID, TableID: t.ID, TableName: t.name,
			RoundStart: t.roundStartHand, EndedAt: t.endedAt, BigBlind: t.settings.BigBlind,
			Net: p.Stack - p.BuyInTotal, Place: p.Place, Players: players,
			Tournament: t.settings.Tournament,
		})
	}
	if len(rows) == 0 {
		return
	}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.InsertRoundResults(ctx, rows)
	})
}
