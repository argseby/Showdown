// Package botplay decides a poker action from a table snapshot. It is the
// brain the bots share: the network client of internal/botclient, and the
// seats the server plays itself.
package botplay

import (
	"math/rand/v2"

	"showdown/internal/poker"
	"showdown/internal/protocol"
)

// The strategy. It is not a solver and does not pretend to be one: it
// estimates how much of the pot the hand is worth against unknown opponents,
// compares that with the price it is being offered, and folds, calls or bets
// accordingly. That is enough to fold trash, value-bet made hands and respect
// pot odds — the things a random bot never does.
//
// The estimate is equity against *random* hands. Real opponents put money in
// with better than random hands, so the number is optimistic, more so on later
// streets and in bigger pots. The thresholds below are set well above break
// even to pay for that, which makes the bot tight rather than loose: the safer
// way to be wrong at a table of friends.

// equitySamples is the number of random run-outs behind one decision. The
// standard error of the estimate is roughly 0.5/sqrt(n), so this puts it near
// one percentage point — finer than any threshold here needs.
const equitySamples = 1500

// spot is everything the solid strategy looks at on one turn.
type spot struct {
	variant poker.Variant
	hole    [2]poker.Card
	board   []poker.Card
	preflop bool
	// pot is everything in the middle: the pots built from earlier streets
	// plus every bet still in front of a player on this one.
	pot int64
	// call is what it costs to continue, currentBet the biggest bet this
	// street (what a raise is measured from).
	call       int64
	currentBet int64
	bb         int64
	// opponents are the players still contesting the pot, all-in ones
	// included; relPos is the share of those still to act that act before
	// us, so 1 means we act last and 0 first.
	opponents int
	relPos    float64
	// stack is everything we can still put in this hand — what is left in
	// front of us plus what we already bet this street. currentBet measured
	// against it says how deep the raising has gone.
	stack int64
}

// readSpot builds the spot from a snapshot. It returns false when the bot
// cannot see what it needs — no hand, no hole cards, an unreadable card —
// and the caller then falls back to checking or calling.
func readSpot(o protocol.OptionsView, s protocol.Snapshot, seat int) (spot, bool) {
	if s.Hand == nil {
		return spot{}, false
	}
	var me *protocol.PlayerView
	for _, sv := range s.Seats {
		if sv.Seat == seat {
			me = sv.Player
			break
		}
	}
	if me == nil || len(me.HoleCards) != 2 {
		return spot{}, false
	}
	sp := spot{
		preflop:    s.Hand.Street == poker.Preflop.String(),
		call:       o.Call,
		currentBet: s.Hand.CurrentBet,
		bb:         s.Table.Settings.BigBlind,
		stack:      me.Stack + me.BetThisStreet,
	}
	if s.Table.Settings.Variant == poker.Royal.String() {
		sp.variant = poker.Royal
	}
	for i, cs := range me.HoleCards {
		c, err := poker.ParseCard(cs)
		if err != nil {
			return spot{}, false
		}
		sp.hole[i] = c
	}
	for _, cs := range s.Hand.Board {
		c, err := poker.ParseCard(cs)
		if err != nil {
			return spot{}, false
		}
		sp.board = append(sp.board, c)
	}
	for _, p := range s.Hand.Pots {
		sp.pot += p.Amount
	}
	// Pots holds only what earlier streets committed; this street's bets —
	// the blinds included — are still in front of the players. Leaving them
	// out would make the pot empty before the flop, and with it every bet
	// size and every pot odd computed from it.
	for _, sv := range s.Seats {
		if sv.Player != nil {
			sp.pot += sv.Player.BetThisStreet
		}
	}
	sp.opponents, sp.relPos = position(s, seat)
	return sp, true
}

// position counts the opponents still in the hand and works out how late the
// seat acts among those that can still act. Betting after the flop starts
// left of the button and ends on it, so the distance from the button is the
// order; before the flop the blinds act last, but treating them as early
// there only makes the bot tighter out of position, which is no loss.
func position(s protocol.Snapshot, seat int) (opponents int, relPos float64) {
	n := s.Table.Settings.MaxPlayers
	if n <= 0 {
		n = len(s.Seats)
	}
	if n <= 0 {
		return 0, 0
	}
	order := func(st int) int { return ((st-s.Hand.ButtonSeat-1)%n + n) % n }
	mine := order(seat)
	acting, earlier := 0, 0
	for _, sv := range s.Seats {
		p := sv.Player
		if p == nil || sv.Seat == seat || !p.InHand || p.Folded {
			continue
		}
		opponents++
		if p.AllIn {
			continue // in the pot, but never acts again
		}
		acting++
		if order(sv.Seat) < mine {
			earlier++
		}
	}
	if acting > 0 {
		relPos = float64(earlier) / float64(acting)
	} else {
		relPos = 1 // nobody left to act: we have the last word
	}
	return opponents, relPos
}

// equityVsRandom estimates the hand's share of the pot against `opponents`
// unknown hands dealt from the rest of the deck, over random run-outs. Wins
// count 1 and an n-way tie 1/n, the same accounting as poker.Equity — which
// cannot be used here because it needs every opponent's cards.
func equityVsRandom(sp spot, rng *rand.Rand) float64 {
	used := make([]bool, poker.DeckSize)
	used[sp.hole[0]], used[sp.hole[1]] = true, true
	for _, c := range sp.board {
		used[c] = true
	}
	deck := make([]poker.Card, 0, sp.variant.DeckSize())
	for _, c := range sp.variant.Deck() {
		if !used[c] {
			deck = append(deck, c)
		}
	}
	runout := 5 - len(sp.board)
	if runout < 0 {
		runout = 0
	}
	opponents := sp.opponents
	if max := (len(deck) - runout) / 2; opponents > max {
		opponents = max // cannot happen at a legal table; never deal past the deck
	}
	if opponents <= 0 {
		return 1
	}
	need := runout + 2*opponents
	mine := make([]poker.Card, 0, 7)
	theirs := make([]poker.Card, 0, 7)
	total := 0.0
	for i := 0; i < equitySamples; i++ {
		// Partial Fisher-Yates: only the cards actually dealt are drawn.
		for j := 0; j < need; j++ {
			k := j + rng.IntN(len(deck)-j)
			deck[j], deck[k] = deck[k], deck[j]
		}
		run, rest := deck[:runout], deck[runout:need]
		mine = append(mine[:0], sp.hole[0], sp.hole[1])
		mine = append(mine, sp.board...)
		mine = append(mine, run...)
		best := poker.Evaluate(mine)
		ties, lost := 1, false
		for k := 0; k < opponents; k++ {
			theirs = append(theirs[:0], rest[2*k], rest[2*k+1])
			theirs = append(theirs, sp.board...)
			theirs = append(theirs, run...)
			switch poker.Evaluate(theirs).Compare(best) {
			case 1:
				lost = true
			case 0:
				ties++
			}
			if lost {
				break
			}
		}
		if !lost {
			total += 1 / float64(ties)
		}
	}
	return total / equitySamples
}

// CheckOrCall takes the cheapest way to stay in the hand. It is what a bot
// falls back on when it cannot read the spot.
func CheckOrCall(o protocol.OptionsView) protocol.ActionPayload {
	if o.Check {
		return protocol.ActionPayload{Kind: "check"}
	}
	if o.Call > 0 {
		return protocol.ActionPayload{Kind: "call"}
	}
	return protocol.ActionPayload{Kind: "fold"}
}

// Decide picks the action for `seat`, whose turn the snapshot says it is.
// rng carries the mixed frequencies and makes a seeded bot repeatable.
func Decide(o protocol.OptionsView, s protocol.Snapshot, seat int, rng *rand.Rand) protocol.ActionPayload {
	sp, ok := readSpot(o, s, seat)
	if !ok || sp.opponents == 0 {
		return CheckOrCall(o)
	}
	equity := equityVsRandom(sp, rng)
	// Everyone holds 1/(opponents+1) of the pot on average, whatever the
	// table size. Measuring the hand between that share and certainty puts
	// every spot on one scale: 0 is an average holding and 1 is a lock,
	// heads-up and six-handed alike. Raw equity cannot do that — a third of
	// the pot is a monster against five players and hopeless against one.
	average := 1 / float64(sp.opponents+1)
	edge := (equity - average) / (1 - average)
	// What the price asks of us. A bet we can call for nothing is free.
	var potOdds float64
	if sp.call > 0 {
		potOdds = float64(sp.call) / float64(sp.pot+sp.call)
	}

	// raiseTo bets a fraction of the pot as it would stand after our call,
	// the usual way to size a bet. Raising is not always offered (a short
	// stack, a bet that is already all-in); shove instead when it is not.
	raiseTo := func(fraction float64) protocol.ActionPayload {
		if o.Raise == nil {
			if o.AllIn > 0 {
				return protocol.ActionPayload{Kind: "all_in"}
			}
			return CheckOrCall(o)
		}
		target := sp.currentBet + int64(fraction*float64(sp.pot+sp.call))
		if sp.bb > 0 {
			target = target / sp.bb * sp.bb // whole big blinds read better
		}
		target = min(max(target, o.Raise.Min), o.Raise.Max)
		return protocol.ActionPayload{Kind: "raise", Amount: target}
	}

	// pressure is how much of our stack the bet in front of us already is.
	// Every re-raise makes it bigger, so a threshold that climbs with it
	// asks for a better hand each time round — which is what stops two bots
	// holding the same good hand from re-raising each other to the felt.
	// Equity alone cannot: it does not change while the betting does, so a
	// fixed bar either never raises or raises for ever.
	var pressure float64
	if sp.stack > 0 {
		pressure = min(float64(sp.currentBet)/float64(sp.stack), 1)
	}

	if sp.preflop {
		// Unopened: only the blinds are in, or a straddle on top of them.
		if sp.currentBet <= 2*sp.bb {
			// Tight up front, wider on the button. Six-handed that is
			// about the top 6% from the first seat and the top 20% from
			// the last; heads-up the same numbers open about half.
			if edge >= 0.045-0.030*sp.relPos {
				return raiseTo(1) // about three big blinds, plus one per limper
			}
			if o.Check {
				return protocol.ActionPayload{Kind: "check"}
			}
			// Completing the small blind is cheap enough to be worth it
			// with anything playable; limping behind is not.
			if edge >= 0 && sp.call <= sp.bb/2 {
				return protocol.ActionPayload{Kind: "call"}
			}
			return protocol.ActionPayload{Kind: "fold"}
		}
		// Facing a raise.
		switch {
		case edge >= 0.13+2.5*pressure:
			return raiseTo(1)
		case edge >= 0.055-0.020*sp.relPos && equity >= potOdds*1.25:
			return CheckOrCall(o)
		default:
			return protocol.ActionPayload{Kind: "fold"}
		}
	}

	// After the flop, with the board to go on.
	if sp.call == 0 {
		switch {
		case edge >= 0.35:
			return raiseTo(0.67) // value
		case edge >= 0.18 && rng.Float64() < 0.6:
			return raiseTo(0.5) // thin value, not every time
		case sp.opponents == 1 && sp.relPos == 1 && rng.Float64() < 0.15:
			return raiseTo(0.5) // a bluff at a checked pot, heads-up and last
		default:
			return protocol.ActionPayload{Kind: "check"}
		}
	}
	// Facing a bet. The margin on top of the pot odds pays for the equity
	// the estimate overstates. It grows with the size of the bet, because a
	// player betting big is rarely doing it with nothing, and with the
	// number of players still in, because one of more hands is likelier to
	// have us beaten already.
	need := potOdds * (1.2 + 0.6*potOdds + 0.1*float64(sp.opponents-1))
	switch {
	case edge >= 0.55+1.5*pressure:
		return raiseTo(0.67)
	case equity >= need:
		return protocol.ActionPayload{Kind: "call"}
	case equity >= potOdds && sp.call <= sp.bb:
		return protocol.ActionPayload{Kind: "call"} // a token price, worth the look
	default:
		return protocol.ActionPayload{Kind: "fold"}
	}
}
