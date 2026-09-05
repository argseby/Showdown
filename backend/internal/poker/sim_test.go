package poker

import (
	"math/rand/v2"
	"os"
	"strconv"
	"testing"
)

// TestRandomizedSimulation plays thousands of hands with random players,
// stacks and legal actions and checks the engine's invariants after every
// call: chip conservation, consistency of the offered options, termination
// and that every hand ends with all chips back in stacks.
func TestRandomizedSimulation(t *testing.T) {
	hands := 10000
	if v := os.Getenv("POKER_SIM_HANDS"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			t.Fatalf("POKER_SIM_HANDS: %v", err)
		}
		hands = n
	} else if testing.Short() {
		hands = 500
	}
	rng := rand.New(rand.NewPCG(20260904, 42))
	for i := 0; i < hands; i++ {
		simulateHand(t, rng, i)
		if t.Failed() {
			return
		}
	}
}

func simulateHand(t *testing.T, rng *rand.Rand, handNo int) {
	t.Helper()
	n := 2 + rng.IntN(9) // 2..10 players
	perm := rng.Perm(10)
	seats := make([]Seat, n)
	var total int64
	for i := 0; i < n; i++ {
		var st int64
		switch rng.IntN(4) {
		case 0:
			st = 1 + rng.Int64N(150) // tiny stacks stress antes/blinds/short all-ins
		case 1:
			st = 100 + rng.Int64N(1000)
		default:
			st = 1000 + rng.Int64N(20000)
		}
		seats[i] = Seat{Seat: perm[i], Stack: st}
		total += st
	}
	cfg := HandConfig{
		SmallBlind: 1 + rng.Int64N(100),
		ButtonSeat: seats[rng.IntN(n)].Seat,
	}
	cfg.BigBlind = cfg.SmallBlind + rng.Int64N(cfg.SmallBlind+1)
	if rng.IntN(3) == 0 {
		cfg.Ante = rng.Int64N(cfg.BigBlind/2 + 1)
	}
	if rng.IntN(2) == 0 {
		cfg.Reveal = RevealWinnersOnly
	}
	shuffle := func(d []Card) { rng.Shuffle(len(d), func(i, j int) { d[i], d[j] = d[j], d[i] }) }

	h, events, err := NewHand(cfg, seats, shuffle)
	if err != nil {
		t.Fatalf("hand %d: NewHand: %v", handNo, err)
	}
	lastSeq := 0
	check := func(where string) {
		t.Helper()
		if got := h.TotalChips(); got != total {
			t.Fatalf("hand %d %s: chips %d, want %d", handNo, where, got, total)
		}
		for _, e := range events {
			if e.Seq <= lastSeq {
				t.Fatalf("hand %d %s: event seq %d not increasing (last %d)", handNo, where, e.Seq, lastSeq)
			}
			lastSeq = e.Seq
		}
	}
	check("start")
	if len(events) == 0 || events[0].Kind != EvHandStarted {
		t.Fatalf("hand %d: first event %+v", handNo, events)
	}

	for step := 0; !h.Done(); step++ {
		if step > 2000 {
			t.Fatalf("hand %d did not terminate", handNo)
		}
		switch h.Phase() {
		case PhaseDealPending:
			events, err = h.Advance()
			if err != nil {
				t.Fatalf("hand %d: Advance: %v", handNo, err)
			}
			check("advance")
		case PhaseShowdown:
			if seat, ok := h.ToAct(); ok {
				t.Fatalf("hand %d: showdown with an actor (seat %d)", handNo, seat)
			}
			events, err = h.RevealNext()
			if err != nil {
				t.Fatalf("hand %d: RevealNext: %v", handNo, err)
			}
			check("reveal")
		case PhaseBetting:
			seat, ok := h.ToAct()
			if !ok {
				t.Fatalf("hand %d: betting phase without actor", handNo)
			}
			o := h.Options(seat)
			validateOptions(t, h, seat, o, handNo)
			// Someone else must not be able to act.
			other := seats[rng.IntN(n)].Seat
			if other != seat {
				if _, err := h.Apply(other, Action{Kind: Fold}); err == nil {
					t.Fatalf("hand %d: seat %d acted out of turn", handNo, other)
				}
			}
			if rng.IntN(20) == 0 {
				events = h.Timeout(seat)
				check("timeout")
				continue
			}
			a := randomLegalAction(rng, o)
			events, err = h.Apply(seat, a)
			if err != nil {
				t.Fatalf("hand %d: legal action %+v rejected: %v (options %+v)", handNo, a, err, o)
			}
			check("apply")
		default:
			t.Fatalf("hand %d: unexpected phase %v", handNo, h.Phase())
		}
	}

	// Hand over: everything is back in stacks and the results add up.
	var stacks int64
	res := h.Results()
	if res == nil {
		t.Fatalf("hand %d: no results", handNo)
	}
	var net int64
	for _, s := range seats {
		st, ok := h.Stack(s.Seat)
		if !ok {
			t.Fatalf("hand %d: seat %d vanished", handNo, s.Seat)
		}
		stacks += st
		r := res.Seats[s.Seat]
		if r.EndStack != st || r.StartStack != s.Stack || r.Net != st-s.Stack {
			t.Fatalf("hand %d: result %+v vs stack %d start %d", handNo, r, st, s.Stack)
		}
		net += r.Net
		if r.Revealed != (r.Cards != nil) {
			t.Fatalf("hand %d: reveal flag/cards mismatch %+v", handNo, r)
		}
	}
	if stacks != total || net != 0 {
		t.Fatalf("hand %d: stacks %d (want %d), net %d", handNo, stacks, total, net)
	}
	var awarded int64
	for _, p := range res.Pots {
		var sum int64
		for _, w := range p.Winners {
			sum += w.Amount
		}
		if sum != p.Amount || len(p.Winners) == 0 {
			t.Fatalf("hand %d: pot %+v winners do not add up", handNo, p)
		}
		awarded += p.Amount
	}
	var potsTotal int64
	for _, p := range h.Pots() {
		potsTotal += p.Amount
	}
	if potsTotal != awarded {
		t.Fatalf("hand %d: final pots %d, awarded %d", handNo, potsTotal, awarded)
	}
	if events[len(events)-1].Kind != EvHandEnded {
		t.Fatalf("hand %d: last event %v", handNo, events[len(events)-1].Kind)
	}
	// Result-phase reveal must work for exactly the players allowed to show.
	for _, s := range seats {
		if h.CanShowCards(s.Seat) {
			events, err = h.ShowCards(s.Seat, true, true)
			if err != nil || len(events) != 1 || events[0].Kind != EvHandsRevealed {
				t.Fatalf("hand %d: ShowCards(%d): %v %+v", handNo, s.Seat, err, events)
			}
			check("show")
		} else if _, err := h.ShowCards(s.Seat, true, true); err == nil {
			t.Fatalf("hand %d: ShowCards(%d) should fail", handNo, s.Seat)
		}
	}
}

func validateOptions(t *testing.T, h *Hand, seat int, o Options, handNo int) {
	t.Helper()
	st, ok := h.State(seat)
	if !ok || st.Folded || st.AllIn {
		t.Fatalf("hand %d: actor %d state %+v", handNo, seat, st)
	}
	toCall := h.CurrentBet() - st.BetThisStreet
	maxTo := st.BetThisStreet + st.Stack
	if !o.Fold {
		t.Fatalf("hand %d: fold must always be offered", handNo)
	}
	if o.Check != (toCall == 0) {
		t.Fatalf("hand %d: check=%v with toCall=%d", handNo, o.Check, toCall)
	}
	wantCall := int64(0)
	if toCall > 0 {
		wantCall = min(toCall, st.Stack)
	}
	if o.Call != wantCall {
		t.Fatalf("hand %d: call=%d want %d", handNo, o.Call, wantCall)
	}
	if o.Raise != nil {
		wantMin := h.MinRaiseTo()
		if h.CurrentBet() == 0 {
			wantMin = cfgBB(h)
		}
		if o.Raise.Min != wantMin || o.Raise.Max != maxTo || o.Raise.Min > o.Raise.Max || o.Raise.Max <= h.CurrentBet() {
			t.Fatalf("hand %d: raise range %+v, want min %d max %d (current %d)", handNo, o.Raise, wantMin, maxTo, h.CurrentBet())
		}
		if o.AllIn != maxTo {
			t.Fatalf("hand %d: all-in %d with raise allowed, want %d", handNo, o.AllIn, maxTo)
		}
	}
	if o.AllIn != 0 && o.AllIn != maxTo {
		t.Fatalf("hand %d: all-in %d, want 0 or %d", handNo, o.AllIn, maxTo)
	}
	if o.AllIn == 0 && st.Stack <= toCall {
		t.Fatalf("hand %d: short stack must be able to go all-in", handNo)
	}
	// Illegal variants must be rejected without changing state.
	before := h.TotalChips()
	if toCall > 0 {
		if _, err := h.Apply(seat, Action{Kind: Check}); err == nil {
			t.Fatalf("hand %d: check accepted while facing a bet", handNo)
		}
	} else if _, err := h.Apply(seat, Action{Kind: Call}); err == nil {
		t.Fatalf("hand %d: call accepted with nothing to call", handNo)
	}
	if o.Raise != nil && o.Raise.Min > h.CurrentBet()+1 {
		if _, err := h.Apply(seat, Action{Kind: Raise, Amount: o.Raise.Min - 1}); err == nil && o.Raise.Min-1 != o.Raise.Max {
			t.Fatalf("hand %d: raise below minimum accepted", handNo)
		}
	}
	if _, err := h.Apply(seat, Action{Kind: Raise, Amount: maxTo + 1}); err == nil {
		t.Fatalf("hand %d: raise above stack accepted", handNo)
	}
	if o.Raise == nil && o.AllIn == 0 {
		if _, err := h.Apply(seat, Action{Kind: AllIn}); err == nil {
			t.Fatalf("hand %d: all-in accepted although raising is closed", handNo)
		}
	}
	if h.TotalChips() != before {
		t.Fatalf("hand %d: rejected action moved chips", handNo)
	}
}

func cfgBB(h *Hand) int64 { return h.cfg.BigBlind }

func randomLegalAction(rng *rand.Rand, o Options) Action {
	var choices []Action
	choices = append(choices, Action{Kind: Fold})
	if o.Check {
		choices = append(choices, Action{Kind: Check}, Action{Kind: Check}, Action{Kind: Check})
	}
	if o.Call > 0 {
		choices = append(choices, Action{Kind: Call}, Action{Kind: Call}, Action{Kind: Call})
	}
	if o.Raise != nil {
		kind := Raise
		amt := o.Raise.Min
		if o.Raise.Max > o.Raise.Min {
			amt += rng.Int64N(o.Raise.Max - o.Raise.Min + 1)
		}
		choices = append(choices, Action{Kind: kind, Amount: amt}, Action{Kind: Bet, Amount: o.Raise.Min})
	}
	if o.AllIn > 0 {
		choices = append(choices, Action{Kind: AllIn})
	}
	return choices[rng.IntN(len(choices))]
}
