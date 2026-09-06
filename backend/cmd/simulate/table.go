package main

import (
	"fmt"
	"math/rand/v2"
	"strings"

	"showdown/internal/poker"
)

// tableSeat is one chair of a simulated table between hands.
type tableSeat struct {
	occupied   bool
	stack      int64
	sittingOut bool
}

// tableSim plays the whole life of one table: hands with a moving button,
// players busting, re-buying, joining, leaving and being adjusted by the
// host, so the chip accounting is exercised the same way it is at a real
// table (rules.md 7.11).
type tableSim struct {
	idx int
	rng *rand.Rand
	f   *findings

	seats      []tableSeat
	startMoney int64
	sb, bb     int64
	ante       int64
	button     int
	handNo     int

	// Chip accounting for the table bankroll invariant.
	boughtIn  int64
	adjusted  int64
	cashedOut int64
}

func newTableSim(idx int, rng *rand.Rand, f *findings) *tableSim {
	maxSeats := 2 + rng.IntN(9) // 2..10 chairs
	t := &tableSim{
		idx: idx, rng: rng, f: f,
		seats:      make([]tableSeat, maxSeats),
		startMoney: []int64{200, 1000, 10000, 250000}[rng.IntN(4)],
		sb:         1 + rng.Int64N(100),
	}
	t.bb = t.sb + rng.Int64N(t.sb+1)
	if rng.IntN(3) == 0 {
		t.ante = rng.Int64N(t.bb/2 + 1)
	}
	// Seat two to all chairs, with stacks that make short all-ins common.
	n := 2 + rng.IntN(maxSeats-1)
	for i := 0; i < n; i++ {
		t.seat(i, t.stakeFor())
	}
	t.button = -1
	return t
}

// stakeFor returns a starting stack; a quarter of them are short enough to
// be all-in on the first blind.
func (t *tableSim) stakeFor() int64 {
	switch t.rng.IntN(4) {
	case 0:
		return 1 + t.rng.Int64N(3*t.bb+1)
	case 1:
		return t.bb * int64(5+t.rng.IntN(20))
	default:
		return t.startMoney
	}
}

func (t *tableSim) seat(i int, stack int64) {
	t.seats[i] = tableSeat{occupied: true, stack: stack}
	t.boughtIn += stack
	t.f.joins++
}

// eligible lists the seats dealt into the next hand (rules.md 7.1).
func (t *tableSim) eligible() []int {
	var out []int
	for i, s := range t.seats {
		if s.occupied && !s.sittingOut && s.stack > 0 {
			out = append(out, i)
		}
	}
	return out
}

// run plays up to hands hands, stopping early when the table runs dry.
func (t *tableSim) run(hands int) {
	t.f.tables++
	defer t.finish()
	for n := 0; n < hands; n++ {
		t.between()
		elig := t.eligible()
		if len(elig) < 2 {
			return
		}
		t.playHand(elig)
		t.handNo++
		t.f.hands++
		t.checkBankroll()
	}
}

// finish adds this table's chip accounting to the run totals.
func (t *tableSim) finish() {
	t.f.boughtIn += t.boughtIn
	t.f.adjusted += t.adjusted
	t.f.cashedOut += t.cashedOut
	for _, s := range t.seats {
		if s.occupied {
			t.f.finalStacks += s.stack
		}
	}
}

// between applies everything that may happen while no hand is running:
// busts, re-buys, joins, leaves, sit-outs, host chip adjustments and a blind
// increase (rules.md 7.10, 7.11).
func (t *tableSim) between() {
	for i := range t.seats {
		s := &t.seats[i]
		if !s.occupied {
			// An empty chair is taken again now and then.
			if t.rng.IntN(40) == 0 {
				t.seat(i, t.stakeFor())
			}
			continue
		}
		switch {
		case s.stack == 0 && t.rng.IntN(2) == 0:
			// Busted player re-buys.
			s.stack = t.startMoney
			t.boughtIn += t.startMoney
			t.f.rebuys++
		case t.rng.IntN(60) == 0:
			// Player leaves and takes the stack off the table.
			t.cashedOut += s.stack
			t.f.leaves++
			t.seats[i] = tableSeat{}
			continue
		case t.rng.IntN(30) == 0:
			s.sittingOut = !s.sittingOut
		case t.rng.IntN(80) == 0:
			// Host adjusts chips (audited at a real table).
			delta := t.rng.Int64N(2*t.bb+1) - t.bb
			if s.stack+delta < 0 {
				delta = -s.stack
			}
			s.stack += delta
			t.adjusted += delta
		}
	}
	if t.rng.IntN(50) == 0 {
		// Blind schedule.
		t.sb *= 2
		t.bb *= 2
		t.ante *= 2
	}
}

// checkBankroll asserts the chips on the table are exactly what was brought
// to it, minus what was taken away.
func (t *tableSim) checkBankroll() {
	var stacks int64
	for _, s := range t.seats {
		if s.occupied {
			stacks += s.stack
		}
	}
	if want := t.boughtIn + t.adjusted - t.cashedOut; stacks != want {
		t.f.fail(chkBankroll, t.idx, t.handNo, "chips on the table %d, bought in %d + adjusted %d - cashed out %d = %d",
			stacks, t.boughtIn, t.adjusted, t.cashedOut, want)
		return
	}
	t.f.ok(chkBankroll)
}

// nextButton moves the button clockwise to the next eligible seat
// (rules.md 7.2, simplified moving button).
func (t *tableSim) nextButton(elig []int) int {
	if t.button < 0 {
		return elig[t.rng.IntN(len(elig))]
	}
	in := make(map[int]bool, len(elig))
	for _, s := range elig {
		in[s] = true
	}
	for i := 1; i <= len(t.seats); i++ {
		s := (t.button + i) % len(t.seats)
		if in[s] {
			return s
		}
	}
	return elig[0]
}

// playHand deals one hand and checks every invariant while it runs.
func (t *tableSim) playHand(elig []int) {
	t.button = t.nextButton(elig)
	seats := make([]poker.Seat, 0, len(elig))
	var total int64
	for _, s := range elig {
		seats = append(seats, poker.Seat{Seat: s, Stack: t.seats[s].stack})
		total += t.seats[s].stack
	}
	cfg := poker.HandConfig{
		SmallBlind: t.sb, BigBlind: t.bb, Ante: t.ante, ButtonSeat: t.button,
		Reveal: []poker.RevealPolicy{poker.RevealAll, poker.RevealWinnersOnly, poker.RevealInOrder}[t.rng.IntN(3)],
	}
	// A seat change now and then owes a dead blind, and the seat left of the
	// big blind sometimes straddles.
	if t.rng.IntN(20) == 0 {
		cfg.DeadBlinds = map[int]int64{elig[t.rng.IntN(len(elig))]: t.bb}
	}
	if len(elig) >= 3 && t.rng.IntN(10) == 0 {
		// A straddle is only accepted from the seat left of the big blind:
		// three seats clockwise from the button (7.2).
		for i, s := range elig {
			if s == t.button {
				cfg.StraddleSeat = elig[(i+3)%len(elig)]
				cfg.StraddleAmount = 2 * t.bb
				break
			}
		}
	}

	shuffle := func(d []poker.Card) { t.rng.Shuffle(len(d), func(i, j int) { d[i], d[j] = d[j], d[i] }) }
	h, events, err := poker.NewHand(cfg, seats, shuffle)
	if err != nil {
		t.f.fail(chkEvents, t.idx, t.handNo, "NewHand: %v", err)
		return
	}
	s := newHandState(t, h, cfg, seats, total)
	s.consume(events)
	if len(events) == 0 || events[0].Kind != poker.EvHandStarted {
		t.f.fail(chkEvents, t.idx, t.handNo, "hand does not open with hand_started")
	}

	for step := 0; !h.Done(); step++ {
		if step > 5000 {
			t.f.fail(chkEvents, t.idx, t.handNo, "hand did not terminate")
			return
		}
		switch h.Phase() {
		case poker.PhaseDealPending:
			if h.CanRunItTwice() && t.rng.IntN(6) == 0 {
				if err := h.RunItTwice(); err != nil {
					t.f.fail(chkEvents, t.idx, t.handNo, "RunItTwice: %v", err)
					return
				}
				t.f.runTwice++
			}
			if h.Runout() && h.Street() == poker.Preflop {
				t.f.runouts++
			}
			ev, err := h.Advance()
			if err != nil {
				t.f.fail(chkEvents, t.idx, t.handNo, "Advance: %v", err)
				return
			}
			s.consume(ev)
		case poker.PhaseShowdown:
			if seat, ok := h.ToAct(); ok {
				t.f.fail(chkTurnOrder, t.idx, t.handNo, "showdown with seat %d to act", seat)
				return
			}
			ev, err := h.RevealNext()
			if err != nil {
				t.f.fail(chkEvents, t.idx, t.handNo, "RevealNext: %v", err)
				return
			}
			s.consume(ev)
		case poker.PhaseBetting:
			seat, ok := h.ToAct()
			if !ok {
				t.f.fail(chkTurnOrder, t.idx, t.handNo, "betting phase without a player to act")
				return
			}
			s.checkTurn(seat)
			o := h.Options(seat)
			s.checkOptions(seat, o)
			s.checkRejects(seat, o)
			if t.rng.IntN(25) == 0 {
				s.consume(h.Timeout(seat))
				continue
			}
			a := t.pick(o)
			ev, err := h.Apply(seat, a)
			if err != nil {
				t.f.fail(chkOptions, t.idx, t.handNo, "seat %d: legal action %v %d rejected: %v (offered %s)",
					seat, a.Kind, a.Amount, err, showOptions(o))
				return
			}
			s.consume(ev)
		default:
			t.f.fail(chkEvents, t.idx, t.handNo, "unexpected phase %d", h.Phase())
			return
		}
	}

	s.checkEnd()
	// The result phase: everyone allowed to show may show, nobody else.
	for _, seat := range elig {
		if h.CanShowCards(seat) && t.rng.IntN(3) == 0 {
			if _, err := h.ShowCards(seat, true, t.rng.IntN(2) == 0); err != nil {
				t.f.fail(chkEvents, t.idx, t.handNo, "ShowCards(%d): %v", seat, err)
			}
		}
	}
	// Write the stacks back to the table.
	for _, seat := range elig {
		st, ok := h.Stack(seat)
		if !ok {
			t.f.fail(chkResults, t.idx, t.handNo, "seat %d vanished", seat)
			return
		}
		t.seats[seat].stack = st
	}
	for _, p := range h.Pots() {
		t.f.wagered += p.Amount
	}
	if len(elig) == 2 {
		t.f.headsUp++
	}
}

// pick chooses one of the offered actions, weighted towards calling and
// checking so hands reach the later streets often enough.
func (t *tableSim) pick(o poker.Options) poker.Action {
	choices := []poker.Action{{Kind: poker.Fold}}
	if o.Check {
		choices = append(choices, poker.Action{Kind: poker.Check}, poker.Action{Kind: poker.Check}, poker.Action{Kind: poker.Check})
	}
	if o.Call > 0 {
		choices = append(choices, poker.Action{Kind: poker.Call}, poker.Action{Kind: poker.Call}, poker.Action{Kind: poker.Call})
	}
	if o.Raise != nil {
		amt := o.Raise.Min
		if o.Raise.Max > o.Raise.Min {
			amt += t.rng.Int64N(o.Raise.Max - o.Raise.Min + 1)
		}
		choices = append(choices,
			poker.Action{Kind: poker.Raise, Amount: amt},
			poker.Action{Kind: poker.Bet, Amount: o.Raise.Min},
			poker.Action{Kind: poker.Raise, Amount: o.Raise.Max})
	}
	if o.AllIn > 0 {
		choices = append(choices, poker.Action{Kind: poker.AllIn})
	}
	return choices[t.rng.IntN(len(choices))]
}

// ---- small helpers used by the checks ---------------------------------------

func sameOptions(a, b poker.Options) bool {
	if a.Fold != b.Fold || a.Check != b.Check || a.Call != b.Call || a.AllIn != b.AllIn {
		return false
	}
	if (a.Raise == nil) != (b.Raise == nil) {
		return false
	}
	return a.Raise == nil || *a.Raise == *b.Raise
}

func showOptions(o poker.Options) string {
	var b strings.Builder
	b.WriteString("{")
	if o.Fold {
		b.WriteString("fold ")
	}
	if o.Check {
		b.WriteString("check ")
	}
	if o.Call > 0 {
		fmt.Fprintf(&b, "call=%d ", o.Call)
	}
	if o.Raise != nil {
		fmt.Fprintf(&b, "raise=%d..%d ", o.Raise.Min, o.Raise.Max)
	}
	if o.AllIn > 0 {
		fmt.Fprintf(&b, "allin=%d", o.AllIn)
	}
	return strings.TrimSpace(b.String()) + "}"
}

func samePots(a, b []poker.Pot) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i].Amount != b[i].Amount || len(a[i].Eligible) != len(b[i].Eligible) {
			return false
		}
		for j := range a[i].Eligible {
			if a[i].Eligible[j] != b[i].Eligible[j] {
				return false
			}
		}
	}
	return true
}

func showPots(pots []poker.Pot) string {
	var b strings.Builder
	b.WriteString("[")
	for i, p := range pots {
		if i > 0 {
			b.WriteString(" ")
		}
		fmt.Fprintf(&b, "%d%v", p.Amount, p.Eligible)
	}
	b.WriteString("]")
	return b.String()
}
