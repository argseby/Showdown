package table

import (
	"context"
	"strings"

	"showdown/internal/poker"
	"showdown/internal/protocol"
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

// recordRoundStandings keeps the table's own record of the round that just
// ended: one row per player who sat in it, guests and bots included. It is
// what survives the restart that puts every stack back to the start money,
// and what the all-time standings of the table are summed from.
func (t *Table) recordRoundStandings() {
	players := 0
	for _, p := range t.seats[:maxSeats] {
		if p != nil {
			players++
		}
	}
	hands := t.handNumber - t.roundStartHand
	var rows []store.RoundStandingRow
	for _, p := range t.seats[:maxSeats] {
		if p == nil {
			continue
		}
		rows = append(rows, store.RoundStandingRow{
			TableID: t.ID, TableName: t.name, RoundStart: t.roundStartHand, Hands: hands,
			EndedAt: t.endedAt, BigBlind: t.settings.BigBlind,
			PlayerID: p.ID, AccountID: p.AccountID, Name: p.Name, NameKey: NameKey(p.Name),
			Avatar: p.Avatar, Bot: p.Bot,
			Stack: p.Stack, BuyInTotal: p.BuyInTotal, Net: p.Stack - p.BuyInTotal,
			Place: p.Place, Players: players,
			HandsPlayed: p.HandsPlayed, HandsWon: p.HandsWon, BiggestPot: p.BiggestPot,
			VPIPHands: p.VPIPHands, Showdowns: p.Showdowns, ShowdownsWon: p.ShowdownsWon,
		})
	}
	if len(rows) == 0 {
		return
	}
	var best *store.RoundHighlightRow
	if b := t.roundBest; b != nil {
		best = &store.RoundHighlightRow{
			Hand: b.Hand, Amount: b.Amount, Winners: append([]string{}, b.Winners...), Description: b.Description,
		}
	}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.InsertRoundStandings(ctx, rows, best)
	})
}

// noteRoundBest keeps the biggest pot of the round being played. The
// winners are named now, while they still sit where the engine says: a
// player who leaves later in the round is still who took it.
func (t *Table) noteRoundBest(res *poker.Results) {
	if res == nil {
		return
	}
	changed := false
	for _, pot := range res.Pots {
		if pot.Amount <= 0 || (t.roundBest != nil && pot.Amount <= t.roundBest.Amount) {
			continue
		}
		best := &protocol.RoundHighlight{Hand: t.handNumber, Amount: pot.Amount, Winners: []string{}, Description: pot.Description}
		for _, w := range pot.Winners {
			if p := t.seats[w.Seat]; p != nil {
				best.Winners = append(best.Winners, p.Name)
			}
		}
		t.roundBest = best
		changed = true
	}
	if changed {
		t.persistTable()
	}
}
