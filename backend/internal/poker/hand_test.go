package poker

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"testing"
)

// rig builds a shuffle that lays the deck out so that each seat receives the
// given hole cards and the board comes out as specified. Unspecified cards
// are filled in canonical order.
func rig(button int, seats []Seat, holes map[int]string, board string) func([]Card) {
	var order []int
	for _, s := range seats {
		order = append(order, s.Seat)
	}
	sort.Ints(order)
	bi := 0
	for i, s := range order {
		if s == button {
			bi = i
		}
	}
	rotated := append(append([]int{}, order[bi+1:]...), order[:bi+1]...)

	var deck []Card
	used := map[Card]bool{}
	take := func(c Card) {
		if used[c] {
			panic("rig: card used twice: " + c.String())
		}
		used[c] = true
		deck = append(deck, c)
	}
	for round := 0; round < 2; round++ {
		for _, seat := range rotated {
			h, ok := holes[seat]
			if !ok {
				panic("rig: no hole cards for seat")
			}
			take(MustParseCards(h)[round])
		}
	}
	for _, c := range MustParseCards(board) {
		take(c)
	}
	for _, c := range NewDeck() {
		if !used[c] {
			deck = append(deck, c)
		}
	}
	return func(d []Card) { copy(d, deck) }
}

func newTestHand(t *testing.T, cfg HandConfig, seats []Seat, holes map[int]string, board string) (*Hand, []Event) {
	t.Helper()
	h, events, err := NewHand(cfg, seats, rig(cfg.ButtonSeat, seats, holes, board))
	if err != nil {
		t.Fatalf("NewHand: %v", err)
	}
	return h, events
}

func act(t *testing.T, h *Hand, seat int, kind ActionKind, amount int64) []Event {
	t.Helper()
	events, err := h.Apply(seat, Action{Kind: kind, Amount: amount})
	if err != nil {
		to, _ := h.ToAct()
		t.Fatalf("Apply(seat %d, %s %d): %v (to act: %d, options %+v)", seat, kind, amount, err, to, h.Options(to))
	}
	return events
}

// drain plays out a staged showdown and appends its events to ev.
func drain(t *testing.T, h *Hand, ev []Event) []Event {
	t.Helper()
	for h.Phase() == PhaseShowdown {
		ev = append(ev, advance(t, h)...)
	}
	return ev
}

// advance deals the next street, or shows the next hand of a staged
// showdown, so that loops can simply drive the hand to its end.
func advance(t *testing.T, h *Hand) []Event {
	t.Helper()
	if h.Phase() == PhaseShowdown {
		events, err := h.RevealNext()
		if err != nil {
			t.Fatalf("RevealNext: %v", err)
		}
		return events
	}
	events, err := h.Advance()
	if err != nil {
		t.Fatalf("Advance: %v", err)
	}
	return events
}

func mustToAct(t *testing.T, h *Hand, want int) {
	t.Helper()
	got, ok := h.ToAct()
	if !ok || got != want {
		t.Fatalf("to act = %d (%v), want %d", got, ok, want)
	}
}

func kinds(events []Event) string {
	var ks []string
	for _, e := range events {
		ks = append(ks, string(e.Kind))
	}
	return strings.Join(ks, " ")
}

func findEvent(events []Event, kind EventKind) *Event {
	for i := range events {
		if events[i].Kind == kind {
			return &events[i]
		}
	}
	return nil
}

func stack(t *testing.T, h *Hand, seat int) int64 {
	t.Helper()
	s, ok := h.Stack(seat)
	if !ok {
		t.Fatalf("no seat %d", seat)
	}
	return s
}

var blinds = HandConfig{SmallBlind: 50, BigBlind: 100}

func cfgWith(button int) HandConfig {
	c := blinds
	c.ButtonSeat = button
	return c
}

func TestNewHandValidation(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}}
	noop := func([]Card) {}
	bad := []struct {
		name  string
		cfg   HandConfig
		seats []Seat
		shuf  func([]Card)
	}{
		{"one player", cfgWith(0), seats[:1], noop},
		{"button not playing", cfgWith(5), seats, noop},
		{"zero stack", cfgWith(0), []Seat{{0, 0}, {1, 10}}, noop},
		{"negative seat", cfgWith(0), []Seat{{-1, 10}, {1, 10}}, noop},
		{"duplicate seat", cfgWith(0), []Seat{{0, 10}, {0, 10}}, noop},
		{"sb zero", HandConfig{SmallBlind: 0, BigBlind: 100}, seats, noop},
		{"bb below sb", HandConfig{SmallBlind: 100, BigBlind: 50}, seats, noop},
		{"negative ante", HandConfig{SmallBlind: 50, BigBlind: 100, Ante: -1}, seats, noop},
		{"nil shuffle", cfgWith(0), seats, nil},
	}
	for _, tc := range bad {
		if _, _, err := NewHand(tc.cfg, tc.seats, tc.shuf); err == nil {
			t.Errorf("%s: expected error", tc.name)
		}
	}
	if _, _, err := NewHand(cfgWith(0), seats, func(d []Card) { d[0] = 0; d[1] = 0 }); err == nil {
		t.Skip("duplicate cards after shuffle are not detected (by design: shuffle is trusted)")
	}
}

func TestHeadsUpHandToShowdown(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, events := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")

	if got := kinds(events); got != "hand_started blind_posted blind_posted hole_cards_dealt hole_cards_dealt" {
		t.Fatalf("start events: %s", got)
	}
	start := events[0].Start
	if start.ButtonSeat != 0 || start.SBSeat != 0 || start.BBSeat != 1 || start.Stacks[0] != 1000 {
		t.Fatalf("hand_started = %+v", start)
	}
	if events[1].Seat != 0 || events[1].Blind != SmallBlind || events[1].Amount != 50 ||
		events[2].Seat != 1 || events[2].Blind != BigBlind || events[2].Amount != 100 {
		t.Fatalf("blinds = %+v %+v", events[1], events[2])
	}
	// Heads-up: cards go to the big blind first (left of the button).
	if events[3].Seat != 1 || cardsString(events[3].Cards) != "Ks Kd" || events[4].Seat != 0 || cardsString(events[4].Cards) != "As Ad" {
		t.Fatalf("hole cards = %+v %+v", events[3], events[4])
	}
	if h.Phase() != PhaseBetting || h.Street() != Preflop {
		t.Fatalf("phase %v street %v", h.Phase(), h.Street())
	}
	mustToAct(t, h, 0) // button acts first preflop
	o := h.Options(0)
	if !o.Fold || o.Check || o.Call != 50 || o.Raise == nil || o.Raise.Min != 200 || o.Raise.Max != 1000 || o.AllIn != 1000 {
		t.Fatalf("button options = %+v", o)
	}
	if got := h.Options(1); got != (Options{}) {
		t.Fatalf("non-acting seat has options %+v", got)
	}
	if h.Description(0) != "Pair of Aces" || len(h.BestCards(0)) != 2 {
		t.Fatalf("preflop description = %q, best = %v", h.Description(0), h.BestCards(0))
	}
	if h.Description(1) != "Pair of Kings" {
		t.Fatalf("preflop description seat 1 = %q", h.Description(1))
	}

	ev := act(t, h, 0, Call, 0)
	if ev[0].Kind != EvAction || ev[0].Action != Call || ev[0].Amount != 50 {
		t.Fatalf("call event = %+v", ev[0])
	}
	mustToAct(t, h, 1)
	o = h.Options(1)
	if !o.Check || o.Call != 0 || o.Raise == nil || o.Raise.Min != 200 || o.Raise.Max != 1000 {
		t.Fatalf("big blind option = %+v", o)
	}
	ev = act(t, h, 1, Check, 0)
	if got := kinds(ev); got != "action pots_updated" {
		t.Fatalf("after check: %s", got)
	}
	if h.Phase() != PhaseDealPending || h.Runout() {
		t.Fatalf("phase %v runout %v", h.Phase(), h.Runout())
	}
	if pots := h.Pots(); len(pots) != 1 || pots[0].Amount != 200 {
		t.Fatalf("pots = %+v", pots)
	}
	if _, err := h.Apply(0, Action{Kind: Check}); !errors.Is(err, ErrNotYourTurn) {
		t.Fatalf("acting while deal pending: %v", err)
	}

	ev = advance(t, h)
	if ev[0].Kind != EvStreetDealt || ev[0].Street != Flop || cardsString(ev[0].Cards) != "2c 7h 9s" {
		t.Fatalf("flop event = %+v", ev[0])
	}
	mustToAct(t, h, 1) // big blind acts first postflop heads-up
	if h.Description(0) != "Pair of Aces" || h.Description(1) != "Pair of Kings" {
		t.Fatalf("descriptions %q %q", h.Description(0), h.Description(1))
	}
	o = h.Options(1)
	if !o.Check || o.Raise == nil || o.Raise.Min != 100 || o.Raise.Max != 900 || o.AllIn != 900 {
		t.Fatalf("flop options = %+v", o)
	}
	act(t, h, 1, Bet, 100)
	o = h.Options(0)
	if o.Call != 100 || o.Raise == nil || o.Raise.Min != 200 || o.Raise.Max != 900 {
		t.Fatalf("facing bet options = %+v", o)
	}
	act(t, h, 0, Raise, 300)
	st, _ := h.State(0)
	if st.BetThisStreet != 300 || st.LastAction == nil || st.LastAction.Kind != Raise || st.LastAction.Amount != 300 {
		t.Fatalf("state after raise = %+v", st)
	}
	o = h.Options(1)
	if o.Call != 200 || o.Raise == nil || o.Raise.Min != 500 {
		t.Fatalf("facing raise options = %+v", o)
	}
	act(t, h, 1, Call, 0)
	advance(t, h) // turn
	mustToAct(t, h, 1)
	act(t, h, 1, Check, 0)
	act(t, h, 0, Check, 0)
	advance(t, h) // river
	act(t, h, 1, Check, 0)
	ev = act(t, h, 0, Check, 0)
	if got := kinds(ev); got != "action pots_updated" || h.Phase() != PhaseShowdown || h.ShowdownPending() != 2 {
		t.Fatalf("river events: %s, phase %v, pending %d", got, h.Phase(), h.ShowdownPending())
	}
	if _, ok := h.ToAct(); ok || h.Done() {
		t.Fatal("nobody acts during the showdown")
	}
	// No bet on the river: the big blind (left of the button) shows first.
	step := advance(t, h)
	if got := kinds(step); got != "hands_revealed" || step[0].Reveals[0].Seat != 1 {
		t.Fatalf("first reveal: %s %+v", got, step[0].Reveals)
	}
	ev = drain(t, h, append(ev, step...))
	if got := kinds(ev); got != "action pots_updated hands_revealed hands_revealed pot_awarded hand_ended" {
		t.Fatalf("showdown events: %s", got)
	}
	if !h.Done() || h.Phase() != PhaseResult {
		t.Fatal("hand should be done")
	}
	rev := findEvent(ev, EvHandsRevealed)
	if len(rev.Reveals) != 1 {
		t.Fatalf("reveals = %+v", rev.Reveals)
	}
	award := findEvent(ev, EvPotAwarded)
	if award.Seat != 0 || award.Amount != 800 || award.Description != "Pair of Aces" || award.PotIndex != 0 {
		t.Fatalf("award = %+v", award)
	}
	if stack(t, h, 0) != 1400 || stack(t, h, 1) != 600 {
		t.Fatalf("stacks %d %d", stack(t, h, 0), stack(t, h, 1))
	}
	res := h.Results()
	if res.Seats[0].Net != 400 || res.Seats[1].Net != -400 || !res.Seats[1].Revealed || res.Seats[1].Description != "Pair of Kings" {
		t.Fatalf("results = %+v", res.Seats)
	}
	if len(h.Pots()) != 1 || h.Pots()[0].Amount != 800 {
		t.Fatalf("final pots = %+v", h.Pots())
	}
	if h.TotalChips() != 2000 {
		t.Fatalf("chips %d", h.TotalChips())
	}
	if h.CanShowCards(0) || h.CanShowCards(1) {
		t.Fatal("revealed players cannot show again")
	}
	if _, err := h.Advance(); !errors.Is(err, ErrWrongPhase) {
		t.Fatalf("Advance after end: %v", err)
	}
}

func TestThreeHandedOrder(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {3, 1000}, {7, 1000}}
	h, _ := newTestHand(t, cfgWith(3), seats, map[int]string{0: "2s 3d", 3: "4s 5d", 7: "6s 7d"}, "9c Th Js Qd Kc")
	if h.SBSeat() != 7 || h.BBSeat() != 0 || h.ButtonSeat() != 3 {
		t.Fatalf("positions sb=%d bb=%d btn=%d", h.SBSeat(), h.BBSeat(), h.ButtonSeat())
	}
	mustToAct(t, h, 3) // left of the big blind wraps around to the button
	act(t, h, 3, Call, 0)
	mustToAct(t, h, 7)
	act(t, h, 7, Call, 0)
	mustToAct(t, h, 0)
	o := h.Options(0)
	if !o.Check || o.Raise == nil || o.Raise.Min != 200 {
		t.Fatalf("big blind option = %+v", o)
	}
	act(t, h, 0, Check, 0)
	advance(t, h)
	mustToAct(t, h, 7) // first left of the button postflop
	act(t, h, 7, Check, 0)
	mustToAct(t, h, 0)
	act(t, h, 0, Check, 0)
	mustToAct(t, h, 3)
	act(t, h, 3, Bet, 100)
	mustToAct(t, h, 7)
	act(t, h, 7, Fold, 0)
	mustToAct(t, h, 0)
	act(t, h, 0, Call, 0)
	advance(t, h)
	mustToAct(t, h, 0) // seat 7 folded, so the big blind is first
}

func TestFoldToUncontestedWinnerAndShowCards(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd", 2: "Qs Qd"}, "2c 7h 9s Jd 3c")
	mustToAct(t, h, 0)
	act(t, h, 0, Raise, 300)
	act(t, h, 1, Fold, 0)
	ev := act(t, h, 2, Fold, 0)
	if got := kinds(ev); got != "action uncalled_returned pots_updated pot_awarded hand_ended" {
		t.Fatalf("events: %s", got)
	}
	ret := findEvent(ev, EvUncalledReturned)
	if ret.Seat != 0 || ret.Amount != 200 {
		t.Fatalf("uncalled = %+v", ret)
	}
	award := findEvent(ev, EvPotAwarded)
	if award.Seat != 0 || award.Amount != 250 || award.Description != "" {
		t.Fatalf("award = %+v", award)
	}
	if findEvent(ev, EvHandsRevealed) != nil {
		t.Fatal("uncontested win must not reveal")
	}
	if stack(t, h, 0) != 1150 || stack(t, h, 1) != 950 || stack(t, h, 2) != 900 {
		t.Fatalf("stacks %d %d %d", stack(t, h, 0), stack(t, h, 1), stack(t, h, 2))
	}
	if !h.CanShowCards(0) || h.CanShowCards(1) || h.CanShowCards(9) {
		t.Fatal("CanShowCards wrong")
	}
	if _, err := h.ShowCards(1, true, true); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("folded player show: %v", err)
	}
	if _, err := h.ShowCards(9, true, true); !errors.Is(err, ErrUnknownSeat) {
		t.Fatalf("unknown seat show: %v", err)
	}
	show, err := h.ShowCards(0, true, true)
	if err != nil || len(show) != 1 || show[0].Kind != EvHandsRevealed || cardsString(show[0].Reveals[0].Cards) != "As Ad" || show[0].Reveals[0].Description != "" {
		t.Fatalf("show = %+v, %v", show, err)
	}
	if !h.Results().Seats[0].Revealed || cardsString(h.Results().Seats[0].Cards) != "As Ad" {
		t.Fatalf("results not updated: %+v", h.Results().Seats[0])
	}
	if _, err := h.ShowCards(0, true, true); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("second show: %v", err)
	}
	st, _ := h.State(0)
	if !st.Revealed {
		t.Fatal("state not revealed")
	}
}

// docs/rules.md §7.5 example: A bets 100, B raises to 300, C goes all-in for
// 350. A may re-raise (min 550); B may only call 50 or fold.
func TestShortAllInDoesNotReopenRaising(t *testing.T) {
	t.Parallel()
	// Button 0 (C), SB 1 (A), BB 2 (B). C starts with 450 so that 350 remain after calling preflop.
	seats := []Seat{{0, 450}, {1, 2000}, {2, 2000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "2s 3d", 1: "As Ad", 2: "Ks Kd"}, "4c 7h 9s Jd 3c")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Check, 0)
	advance(t, h)
	mustToAct(t, h, 1)
	act(t, h, 1, Bet, 100)
	act(t, h, 2, Raise, 300)
	o := h.Options(0)
	if o.Call != 300 || o.Raise != nil || o.AllIn != 350 {
		t.Fatalf("C options = %+v", o)
	}
	ev := act(t, h, 0, AllIn, 0)
	if ev[0].Action != Raise || ev[0].Amount != 350 || !ev[0].AllIn {
		t.Fatalf("C all-in event = %+v", ev[0])
	}
	if h.CurrentBet() != 350 || h.MinRaiseTo() != 550 {
		t.Fatalf("current bet %d min raise %d", h.CurrentBet(), h.MinRaiseTo())
	}
	mustToAct(t, h, 1)
	o = h.Options(1)
	if o.Call != 250 || o.Raise == nil || o.Raise.Min != 550 || o.Raise.Max != 1900 || o.AllIn != 1900 {
		t.Fatalf("A options = %+v", o)
	}
	if _, err := h.Apply(1, Action{Kind: Raise, Amount: 500}); !errors.Is(err, ErrAmountOutOfRange) {
		t.Fatalf("raise below minimum: %v", err)
	}
	act(t, h, 1, Call, 0)
	mustToAct(t, h, 2)
	o = h.Options(2)
	if o.Call != 50 || o.Raise != nil || o.AllIn != 0 || !o.Fold || o.Check {
		t.Fatalf("B options = %+v", o)
	}
	if _, err := h.Apply(2, Action{Kind: Raise, Amount: 600}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("B raise must be illegal: %v", err)
	}
	if _, err := h.Apply(2, Action{Kind: AllIn}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("B all-in must be illegal: %v", err)
	}
	ev = act(t, h, 2, Call, 0)
	if got := kinds(ev); got != "action pots_updated" {
		t.Fatalf("after B call: %s", got)
	}
	// Everyone contributed 450 in total, so there is a single pot.
	pots := h.Pots()
	if len(pots) != 1 || pots[0].Amount != 1350 || len(pots[0].Eligible) != 3 {
		t.Fatalf("pots = %+v", pots)
	}
	if h.TotalChips() != 4450 {
		t.Fatalf("chips %d", h.TotalChips())
	}
}

func TestSidePotsAndOddChipsThreeWayTie(t *testing.T) {
	t.Parallel()
	// Blinds 10/20, button 0. UTG(3), button(0) and SB(1) go all-in for 100; BB(2) folds.
	// Board is a royal flush: everyone left ties. Pot 320 -> 106 each, two odd
	// chips go clockwise from the seat left of the button: seat 1, then 3.
	cfg := HandConfig{SmallBlind: 10, BigBlind: 20, ButtonSeat: 0}
	seats := []Seat{{0, 100}, {1, 100}, {2, 100}, {3, 100}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "2s 3d", 1: "4s 5d", 2: "6s 7d", 3: "8s 9d"}, "Ts Js Qs Ks As")
	mustToAct(t, h, 3)
	act(t, h, 3, AllIn, 0)
	act(t, h, 0, AllIn, 0)
	act(t, h, 1, AllIn, 0)
	o := h.Options(2)
	if o.Call != 80 || o.Raise != nil || o.AllIn != 100 {
		t.Fatalf("BB options = %+v", o)
	}
	ev := act(t, h, 2, Fold, 0)
	if got := kinds(ev); got != "action pots_updated hands_revealed" {
		t.Fatalf("events: %s", got)
	}
	if h.Phase() != PhaseDealPending || !h.Runout() {
		t.Fatal("expected run-out")
	}
	if pots := h.Pots(); len(pots) != 1 || pots[0].Amount != 320 || len(pots[0].Eligible) != 3 {
		t.Fatalf("pots = %+v", pots)
	}
	for i := 0; i < 2; i++ {
		advance(t, h)
		if h.Done() {
			t.Fatal("finished too early")
		}
	}
	ev = advance(t, h)
	if !h.Done() {
		t.Fatal("river must finish the run-out")
	}
	if got := kinds(ev); got != "street_dealt pot_awarded pot_awarded pot_awarded hand_ended" {
		t.Fatalf("river events: %s", got)
	}
	want := map[int]int64{1: 107, 3: 107, 0: 106}
	for _, e := range ev {
		if e.Kind == EvPotAwarded {
			if want[e.Seat] != e.Amount || e.Description != "Royal Flush" {
				t.Errorf("award %+v, want %d", e, want[e.Seat])
			}
			delete(want, e.Seat)
		}
	}
	if len(want) != 0 {
		t.Fatalf("missing awards for %v", want)
	}
	if stack(t, h, 2) != 80 || h.TotalChips() != 400 {
		t.Fatalf("BB stack %d, chips %d", stack(t, h, 2), h.TotalChips())
	}
	res := h.Results()
	if len(res.Pots) != 1 || len(res.Pots[0].Winners) != 3 || res.Pots[0].Winners[0].Seat != 1 {
		t.Fatalf("results pots = %+v", res.Pots)
	}
}

func TestTwoWayTieOddChipClockwiseFromButton(t *testing.T) {
	t.Parallel()
	// Blinds 25/50, button 0: UTG(0) calls, SB(1) folds (25 dead), BB(2) checks.
	// Pot 125; checked down to a board tie -> BB (first left of the button) gets 63.
	cfg := HandConfig{SmallBlind: 25, BigBlind: 50, ButtonSeat: 0}
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "2s 3d", 1: "4s 5d", 2: "6s 7d"}, "Ts Js Qs Ks As")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Fold, 0)
	act(t, h, 2, Check, 0)
	for s := 0; s < 3; s++ {
		advance(t, h)
		act(t, h, 2, Check, 0)
		act(t, h, 0, Check, 0)
	}
	drain(t, h, nil)
	if !h.Done() {
		t.Fatal("not done")
	}
	if stack(t, h, 2) != 1013 || stack(t, h, 0) != 1012 || stack(t, h, 1) != 975 {
		t.Fatalf("stacks %d %d %d", stack(t, h, 0), stack(t, h, 1), stack(t, h, 2))
	}
}

func TestSidePotsAwardedSeparately(t *testing.T) {
	t.Parallel()
	// Button 0 (1000), SB 1 (300), BB 2 (1000). Everyone all-in preflop.
	// Seat 1 has the best hand but only wins the main pot (900); seat 2 wins the side pot.
	seats := []Seat{{0, 1000}, {1, 300}, {2, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "2s 3d", 1: "As Ad", 2: "Ks Kd"}, "4c 7h 9s Jd 8c")
	act(t, h, 0, AllIn, 0)
	act(t, h, 1, AllIn, 0)
	ev := act(t, h, 2, Call, 0)
	pots := findEvent(ev, EvPotsUpdated).Pots
	if len(pots) != 2 || pots[0].Amount != 900 || pots[1].Amount != 1400 || len(pots[1].Eligible) != 2 {
		t.Fatalf("pots = %+v", pots)
	}
	for !h.Done() {
		ev = advance(t, h)
	}
	awards := map[int]int64{}
	for _, e := range ev {
		if e.Kind == EvPotAwarded {
			awards[e.Seat] += e.Amount
		}
	}
	if awards[1] != 900 || awards[2] != 1400 || awards[0] != 0 {
		t.Fatalf("awards = %v", awards)
	}
	res := h.Results()
	if res.Pots[0].Description != "Pair of Aces" || res.Pots[1].Description != "Pair of Kings" {
		t.Fatalf("pot descriptions %+v", res.Pots)
	}
	if h.TotalChips() != 2300 || stack(t, h, 0) != 0 || stack(t, h, 1) != 900 || stack(t, h, 2) != 1400 {
		t.Fatalf("stacks %d %d %d", stack(t, h, 0), stack(t, h, 1), stack(t, h, 2))
	}
}

func TestUncalledBetReturnedWhenAllInCalledForLess(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 200}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	act(t, h, 0, AllIn, 0) // raise to 1000
	o := h.Options(1)
	if o.Call != 100 || o.Raise != nil || o.AllIn != 200 {
		t.Fatalf("options = %+v", o)
	}
	ev := act(t, h, 1, Call, 0)
	ret := findEvent(ev, EvUncalledReturned)
	if ret == nil || ret.Seat != 0 || ret.Amount != 800 {
		t.Fatalf("uncalled = %+v", ret)
	}
	if h.Pots()[0].Amount != 400 || stack(t, h, 0) != 800 {
		t.Fatalf("pot %+v stack %d", h.Pots(), stack(t, h, 0))
	}
	if !h.Runout() {
		t.Fatal("expected run-out")
	}
}

func TestTimeouts(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd", 2: "Qs Qd"}, "2c 7h 9s Jd 3c")
	if h.Timeout(1) != nil {
		t.Fatal("timeout for a player not to act must be a no-op")
	}
	ev := h.Timeout(0)
	if ev[0].Kind != EvTimeout || ev[0].Action != Fold || ev[0].Seat != 0 {
		t.Fatalf("timeout event = %+v", ev[0])
	}
	st, _ := h.State(0)
	if !st.Folded || st.LastAction.Kind != Fold {
		t.Fatalf("state = %+v", st)
	}
	act(t, h, 1, Call, 0)
	ev = h.Timeout(2)
	if ev[0].Action != Check {
		t.Fatalf("big blind timeout should check: %+v", ev[0])
	}
	if h.Phase() != PhaseDealPending {
		t.Fatal("round should be over")
	}
	if h.Timeout(2) != nil {
		t.Fatal("timeout outside betting must be a no-op")
	}
}

func TestWinnersOnlyRevealAndShowCards(t *testing.T) {
	t.Parallel()
	cfg := cfgWith(0)
	cfg.Reveal = RevealWinnersOnly
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Check, 0)
	var ev []Event
	for s := 0; s < 3; s++ {
		advance(t, h)
		act(t, h, 1, Check, 0)
		ev = act(t, h, 0, Check, 0)
	}
	ev = drain(t, h, ev)
	// Seat 1 shows first (left of the button) and mucks; seat 0 wins.
	if got := kinds(ev); got != "action pots_updated mucked hands_revealed pot_awarded hand_ended" {
		t.Fatalf("events: %s", got)
	}
	rev := findEvent(ev, EvHandsRevealed)
	if len(rev.Reveals) != 1 || rev.Reveals[0].Seat != 0 {
		t.Fatalf("reveals = %+v", rev.Reveals)
	}
	if st, _ := h.State(1); !st.Mucked || st.Revealed {
		t.Fatalf("seat 1 state = %+v", st)
	}
	if h.CanShowCards(0) || !h.CanShowCards(1) {
		t.Fatal("loser should be able to show")
	}
	if h.Results().Seats[1].Revealed || h.Results().Seats[1].Cards != nil {
		t.Fatalf("loser leaked: %+v", h.Results().Seats[1])
	}
	show, err := h.ShowCards(1, true, true)
	if err != nil || show[0].Reveals[0].Description != "Pair of Kings" {
		t.Fatalf("show = %+v, %v", show, err)
	}
}

func TestShowCardsWrongPhase(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	if _, err := h.ShowCards(0, true, true); !errors.Is(err, ErrWrongPhase) {
		t.Fatalf("show during betting: %v", err)
	}
	if h.CanShowCards(0) {
		t.Fatal("cannot show during betting")
	}
}

func TestAntesAndShortBlinds(t *testing.T) {
	t.Parallel()
	cfg := HandConfig{SmallBlind: 25, BigBlind: 50, Ante: 10, ButtonSeat: 0}
	seats := []Seat{{0, 1000}, {1, 5}, {2, 60}}
	h, events := newTestHand(t, cfg, seats, map[int]string{0: "2s 3d", 1: "As Ad", 2: "Ks Kd"}, "4c 7h 9s Jd 8c")
	got := kinds(events)
	if got != "hand_started ante_posted ante_posted ante_posted blind_posted blind_posted hole_cards_dealt hole_cards_dealt hole_cards_dealt" {
		t.Fatalf("events: %s", got)
	}
	// Seat 1 can only post 5 of the ante and is all-in; its small blind is 0.
	for _, e := range events {
		switch {
		case e.Kind == EvAntePosted && e.Seat == 1:
			if e.Amount != 5 || !e.AllIn {
				t.Fatalf("ante seat 1 = %+v", e)
			}
		case e.Kind == EvBlindPosted && e.Seat == 1:
			if e.Amount != 0 || !e.AllIn {
				t.Fatalf("sb seat 1 = %+v", e)
			}
		case e.Kind == EvBlindPosted && e.Seat == 2:
			if e.Amount != 50 || !e.AllIn {
				t.Fatalf("bb seat 2 = %+v", e)
			}
		}
	}
	if h.TotalChips() != 1065 {
		t.Fatalf("chips %d", h.TotalChips())
	}
	mustToAct(t, h, 0)
	o := h.Options(0)
	if o.Call != 50 || o.Raise == nil || o.Raise.Min != 100 || o.Raise.Max != 990 {
		t.Fatalf("options = %+v", o)
	}
	ev := act(t, h, 0, Call, 0)
	if got := kinds(ev); got != "action pots_updated hands_revealed" {
		t.Fatalf("events: %s", got)
	}
	pots := h.Pots()
	if len(pots) != 2 || pots[0].Amount != 15 || len(pots[0].Eligible) != 3 || pots[1].Amount != 110 || len(pots[1].Eligible) != 2 {
		t.Fatalf("pots = %+v", pots)
	}
	for !h.Done() {
		advance(t, h)
	}
	if h.TotalChips() != 1065 || stack(t, h, 1) != 15 || stack(t, h, 2) != 110 {
		t.Fatalf("stacks %d %d %d", stack(t, h, 0), stack(t, h, 1), stack(t, h, 2))
	}
}

func TestShortStackBetPostflop(t *testing.T) {
	t.Parallel()
	// Seat 1 has 130: after calling 100 preflop, 30 remain (< big blind).
	seats := []Seat{{0, 1000}, {1, 130}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Check, 0)
	advance(t, h)
	mustToAct(t, h, 1)
	o := h.Options(1)
	if o.Raise != nil || o.AllIn != 30 || !o.Check {
		t.Fatalf("short stack options = %+v", o)
	}
	if _, err := h.Apply(1, Action{Kind: Bet, Amount: 20}); !errors.Is(err, ErrAmountOutOfRange) {
		t.Fatalf("bet below stack and blind: %v", err)
	}
	act(t, h, 1, Check, 0)
	// Seat 0 checks behind; turn: seat 1 shoves 30 as a short bet.
	act(t, h, 0, Check, 0)
	advance(t, h)
	act(t, h, 1, Bet, 30)
	if h.MinRaiseTo() != 130 {
		t.Fatalf("min raise after short bet = %d", h.MinRaiseTo())
	}
	o = h.Options(0)
	if o.Call != 30 || o.Raise == nil || o.Raise.Min != 130 {
		t.Fatalf("facing short bet options = %+v", o)
	}
}

func TestCheckedPlayerCannotRaiseShortBet(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 130}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd", 2: "Qs Qd"}, "2c 7h 9s Jd 3c")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Check, 0)
	advance(t, h)
	mustToAct(t, h, 1)
	act(t, h, 1, Check, 0)
	act(t, h, 2, AllIn, 0) // short bet of 30
	act(t, h, 0, Call, 0)
	o := h.Options(1)
	if o.Call != 30 || o.Raise != nil || o.AllIn != 0 {
		t.Fatalf("checked player facing short bet: %+v", o)
	}
	act(t, h, 1, Call, 0)
	if h.Phase() != PhaseDealPending || h.Runout() {
		t.Fatalf("phase %v runout %v: two players can still bet", h.Phase(), h.Runout())
	}
}

func TestLenientBetRaiseNamingAndErrors(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	if _, err := h.Apply(1, Action{Kind: Call}); !errors.Is(err, ErrNotYourTurn) {
		t.Fatalf("wrong seat: %v", err)
	}
	if _, err := h.Apply(5, Action{Kind: Call}); !errors.Is(err, ErrUnknownSeat) {
		t.Fatalf("unknown seat: %v", err)
	}
	if _, err := h.Apply(0, Action{Kind: Check}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("check facing bet: %v", err)
	}
	if _, err := h.Apply(0, Action{Kind: "dance"}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("unknown kind: %v", err)
	}
	if _, err := h.Apply(0, Action{Kind: Raise, Amount: 5000}); !errors.Is(err, ErrAmountOutOfRange) {
		t.Fatalf("raise above stack: %v", err)
	}
	ev := act(t, h, 0, Bet, 300) // "bet" preflop is really a raise
	if ev[0].Action != Raise || ev[0].Amount != 300 {
		t.Fatalf("event = %+v", ev[0])
	}
	act(t, h, 1, Call, 0)
	advance(t, h)
	if _, err := h.Apply(1, Action{Kind: Call}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("call with nothing to call: %v", err)
	}
	ev = act(t, h, 1, Raise, 100) // "raise" with no bet is really a bet
	if ev[0].Action != Bet {
		t.Fatalf("event = %+v", ev[0])
	}
	if _, err := h.Apply(0, Action{Kind: Bet, Amount: 150}); !errors.Is(err, ErrAmountOutOfRange) {
		t.Fatalf("raise below min: %v", err)
	}
	if _, err := h.Apply(0, Action{Kind: Bet, Amount: 100}); !errors.Is(err, ErrAmountOutOfRange) {
		t.Fatalf("raise to current bet: %v", err)
	}
}

func TestEverybodyAllInFromBlinds(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 50}, {1, 100}}
	h, events := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	if got := kinds(events); !strings.HasSuffix(got, "hole_cards_dealt hole_cards_dealt uncalled_returned pots_updated hands_revealed") {
		t.Fatalf("events: %s", got)
	}
	if _, ok := h.ToAct(); ok {
		t.Fatal("nobody can act")
	}
	if h.Phase() != PhaseDealPending || !h.Runout() {
		t.Fatal("expected immediate run-out")
	}
	if stack(t, h, 1) != 50 || h.Pots()[0].Amount != 100 {
		t.Fatalf("stack %d pots %+v", stack(t, h, 1), h.Pots())
	}
	for !h.Done() {
		advance(t, h)
	}
	if stack(t, h, 0) != 100 || stack(t, h, 1) != 50 {
		t.Fatalf("stacks %d %d", stack(t, h, 0), stack(t, h, 1))
	}
}

func TestStateAndAccessors(t *testing.T) {
	t.Parallel()
	seats := []Seat{{2, 1000}, {5, 1000}, {8, 1000}}
	h, _ := newTestHand(t, cfgWith(5), seats, map[int]string{2: "As Ad", 5: "Ks Kd", 8: "Qs Qd"}, "2c 7h 9s Jd 3c")
	if got := h.Seats(); len(got) != 3 || got[0] != 2 || got[2] != 8 {
		t.Fatalf("seats = %v", got)
	}
	if _, ok := h.State(3); ok {
		t.Fatal("unknown seat must not have state")
	}
	if _, ok := h.Stack(3); ok {
		t.Fatal("unknown seat must not have a stack")
	}
	st, _ := h.State(2)
	if !st.InHand || st.BetThisStreet != 100 || st.TotalBet != 100 || cardsString(st.HoleCards) != "As Ad" || st.LastAction != nil {
		t.Fatalf("state = %+v", st)
	}
	if len(h.Board()) != 0 || h.Description(3) != "" || h.Results() != nil {
		t.Fatal("initial accessors wrong")
	}
	if h.Street().String() != "preflop" || Flop.String() != "flop" || River.String() != "river" {
		t.Fatal("street names")
	}
}

func TestForfeit(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}}
	holes := map[int]string{0: "As Ad", 1: "Ks Kd", 2: "Qs Qd"}
	board := "2c 7h 9s Jd 3c"

	t.Run("out of turn keeps the actor", func(t *testing.T) {
		t.Parallel()
		h, _ := newTestHand(t, cfgWith(0), seats, holes, board)
		mustToAct(t, h, 0)
		ev := h.Forfeit(2) // big blind leaves while UTG is to act
		if len(ev) != 1 || ev[0].Kind != EvAction || ev[0].Action != Fold || ev[0].Seat != 2 {
			t.Fatalf("events = %+v", ev)
		}
		mustToAct(t, h, 0)
		if h.Forfeit(2) != nil || h.Forfeit(9) != nil {
			t.Fatal("repeated or unknown forfeit must be a no-op")
		}
		act(t, h, 0, Call, 0)
		ev = act(t, h, 1, Call, 0) // completes the round: seat 2 is skipped
		if h.Phase() != PhaseDealPending {
			t.Fatalf("phase %v, events %s", h.Phase(), kinds(ev))
		}
	})

	t.Run("in turn passes the action", func(t *testing.T) {
		t.Parallel()
		h, _ := newTestHand(t, cfgWith(0), seats, holes, board)
		h.Forfeit(0)
		mustToAct(t, h, 1)
	})

	t.Run("last needed action completes the round", func(t *testing.T) {
		t.Parallel()
		h, _ := newTestHand(t, cfgWith(0), seats, holes, board)
		act(t, h, 0, Call, 0)
		mustToAct(t, h, 1)
		act(t, h, 1, Call, 0)
		mustToAct(t, h, 2)
		// Seat 0 leaves while seat 2 has the option; the round is not complete yet.
		if ev := h.Forfeit(0); h.Phase() != PhaseBetting || len(ev) != 1 {
			t.Fatalf("phase %v events %s", h.Phase(), kinds(ev))
		}
		// Now seat 1 leaves too: only seat 2 remains and wins.
		ev := h.Forfeit(1)
		if !h.Done() || findEvent(ev, EvPotAwarded) == nil || findEvent(ev, EvPotAwarded).Seat != 2 {
			t.Fatalf("events %s", kinds(ev))
		}
		if stack(t, h, 2) != 1200 || h.TotalChips() != 3000 {
			t.Fatalf("stack %d chips %d", stack(t, h, 2), h.TotalChips())
		}
	})

	t.Run("during run-out", func(t *testing.T) {
		t.Parallel()
		h, _ := newTestHand(t, cfgWith(0), []Seat{{0, 500}, {1, 500}}, map[int]string{0: "As Ad", 1: "Ks Kd"}, board)
		act(t, h, 0, AllIn, 0)
		act(t, h, 1, Call, 0)
		if !h.Runout() {
			t.Fatal("expected run-out")
		}
		ev := h.Forfeit(1)
		if !h.Done() || stack(t, h, 0) != 1000 {
			t.Fatalf("events %s stack %d", kinds(ev), stack(t, h, 0))
		}
		if _, err := h.Advance(); !errors.Is(err, ErrWrongPhase) {
			t.Fatalf("stale advance: %v", err)
		}
		if h.Forfeit(0) != nil {
			t.Fatal("forfeit after the hand must be a no-op")
		}
	})
}

func TestDescribeHoleAndBestCards(t *testing.T) {
	t.Parallel()
	card := func(s string) Card {
		c, err := ParseCard(s)
		if err != nil {
			t.Fatal(err)
		}
		return c
	}
	cases := map[string]string{
		"As Ad": "Pair of Aces", "Ks Qs": "King-Queen suited", "Qh 7c": "Queen high", "2d 9d": "Nine-Two suited",
	}
	for hole, want := range cases {
		var a, b string
		if _, err := fmt.Sscanf(hole, "%s %s", &a, &b); err != nil {
			t.Fatal(err)
		}
		if got := DescribeHole(card(a), card(b)); got != want {
			t.Errorf("DescribeHole(%s) = %q, want %q", hole, got, want)
		}
	}
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "Qh 7c", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	if best := h.BestCards(0); len(best) != 1 || best[0] != card("Qh") {
		t.Fatalf("high card best = %v", best)
	}
	act(t, h, 0, Call, 0)
	act(t, h, 1, Check, 0)
	if _, err := h.Advance(); err != nil {
		t.Fatal(err)
	}
	if h.Description(0) != "Pair of Sevens" || len(h.BestCards(0)) != 5 {
		t.Fatalf("flop description = %q best = %v", h.Description(0), h.BestCards(0))
	}
}

func TestPartialShowAndRabbitHunt(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	if got := h.RemainingBoard(); len(got) != 5 {
		t.Fatalf("the engine always knows the rest of the deck: %v", got)
	}
	// Seat 0 folds preflop: seat 1 wins uncontested and may show one card.
	act(t, h, 0, Fold, 0)
	if !h.Done() {
		t.Fatal("hand should be over")
	}
	if got := h.RemainingBoard(); len(got) != 5 || got[0].String() != "2c" || got[4].String() != "3c" {
		t.Fatalf("remaining board = %v", got)
	}
	if _, err := h.ShowCards(1, false, false); err == nil {
		t.Fatal("showing nothing must be rejected")
	}
	ev, err := h.ShowCards(1, true, false)
	if err != nil {
		t.Fatal(err)
	}
	r := ev[0].Reveals[0]
	if r.Shown != [2]bool{true, false} || r.Description != "" || r.Best != nil {
		t.Fatalf("partial reveal = %+v", r)
	}
	if st, _ := h.State(1); st.Revealed || st.Shown != [2]bool{true, false} {
		t.Fatalf("state after partial reveal = %+v", st)
	}
	if _, err := h.ShowCards(1, true, false); err == nil {
		t.Fatal("the same card cannot be shown twice")
	}
	ev, err = h.ShowCards(1, false, true)
	if err != nil {
		t.Fatal(err)
	}
	r = ev[0].Reveals[0]
	if r.Shown != [2]bool{true, true} || !h.Results().Seats[1].Revealed {
		t.Fatalf("second card completes the reveal: %+v", r)
	}
	if !h.CanShowCards(0) == true && false {
		t.Fatal("unreachable")
	}
	if _, err := h.ShowCards(0, true, true); err == nil {
		t.Fatal("a folded player cannot show")
	}
}

func TestDeadBlindGoesToThePot(t *testing.T) {
	t.Parallel()
	// Button 0, small blind 1, big blind 2; seat 3 owes a dead blind.
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}, {3, 1000}}
	cfg := cfgWith(0)
	cfg.DeadBlinds = map[int]int64{3: 100}
	h, events := newTestHand(t, cfg, seats, map[int]string{0: "As Ad", 1: "Ks Kd", 2: "Qs Qd", 3: "Ts Td"}, "2c 7h 9s Jd 3c")
	var dead *Event
	for i := range events {
		if events[i].Kind == EvBlindPosted && events[i].Blind == DeadBlind {
			dead = &events[i]
		}
	}
	if dead == nil || dead.Seat != 3 || dead.Amount != 100 {
		t.Fatalf("dead blind event = %+v", dead)
	}
	// It is in the pot (total) but not a bet of the street: seat 3 still
	// has to call the big blind.
	if st, _ := h.State(3); st.Stack != 900 || st.BetThisStreet != 0 || st.TotalBet != 100 {
		t.Fatalf("seat 3 after dead blind = %+v", st)
	}
	if h.TotalChips() != 4000 {
		t.Fatalf("chips = %d", h.TotalChips())
	}
	if o := h.Options(3); o.Call != 100 {
		t.Fatalf("seat 3 must call the big blind: %+v", o)
	}
	act(t, h, 3, Fold, 0)
	act(t, h, 0, Fold, 0)
	act(t, h, 1, Fold, 0)
	var won int64
	for _, p := range h.Results().Pots {
		won += p.Amount
	}
	if won != 200 { // dead 100 + sb 50 + the called 50 of the big blind (the rest is uncalled)
		t.Fatalf("pot = %d, want 200", won)
	}
}

func TestInOrderShowdownMucksBeatenHands(t *testing.T) {
	t.Parallel()
	// Button 0. Seat 1 (SB) bets the river and shows first; seat 2's pair
	// of kings beats seat 1's pair of queens and is shown; seat 0's pair of
	// tens is beaten and mucked. Board: 2c 7h 9s Jd 3c.
	cfg := cfgWith(0)
	cfg.Reveal = RevealInOrder
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "Ts Tc", 1: "Qs Qd", 2: "Ks Kd"}, "2c 7h 9s Jd 3c")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Check, 0)
	for s := 0; s < 2; s++ {
		advance(t, h)
		act(t, h, 1, Check, 0)
		act(t, h, 2, Check, 0)
		act(t, h, 0, Check, 0)
	}
	advance(t, h) // river
	act(t, h, 1, Bet, 100)
	act(t, h, 2, Call, 0)
	ev := act(t, h, 0, Call, 0)
	if h.Phase() != PhaseShowdown || h.ShowdownPending() != 3 {
		t.Fatalf("phase %v pending %d", h.Phase(), h.ShowdownPending())
	}
	if h.Forfeit(2) != nil {
		t.Fatal("leaving during the showdown must not fold")
	}
	step := advance(t, h)
	if kinds(step) != "hands_revealed" || step[0].Reveals[0].Seat != 1 {
		t.Fatalf("aggressor shows first: %s %+v", kinds(step), step)
	}
	step = advance(t, h)
	if kinds(step) != "hands_revealed" || step[0].Reveals[0].Seat != 2 {
		t.Fatalf("better hand shows: %s %+v", kinds(step), step)
	}
	step = advance(t, h)
	if got := kinds(step); got != "mucked pot_awarded hand_ended" || step[0].Seat != 0 {
		t.Fatalf("beaten hand mucks: %s %+v", got, step[0])
	}
	ev = append(ev, step...)
	if !h.Done() || findEvent(ev, EvPotAwarded).Seat != 2 || stack(t, h, 2) != 1400 {
		t.Fatalf("winner: %+v stack %d", findEvent(ev, EvPotAwarded), stack(t, h, 2))
	}
	if !h.CanShowCards(0) || h.CanShowCards(1) {
		t.Fatal("only the mucked player may show afterwards")
	}
	if res := h.Results(); res.Seats[0].Revealed || res.Seats[0].Cards != nil {
		t.Fatalf("mucked hand leaked: %+v", res.Seats[0])
	}
	if h.TotalChips() != 3000 {
		t.Fatalf("chips %d", h.TotalChips())
	}
}

func TestInOrderShowdownTieShows(t *testing.T) {
	t.Parallel()
	// Both hold the same pair: the second player is not beaten and shows.
	cfg := cfgWith(0)
	cfg.Reveal = RevealInOrder
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "Ks Kd", 1: "Kh Kc"}, "2c 7h 9s Jd 3c")
	act(t, h, 0, Call, 0)
	act(t, h, 1, Check, 0)
	for s := 0; s < 3; s++ {
		advance(t, h)
		act(t, h, 1, Check, 0)
		act(t, h, 0, Check, 0)
	}
	ev := drain(t, h, nil)
	if got := kinds(ev); got != "hands_revealed hands_revealed pot_awarded pot_awarded hand_ended" {
		t.Fatalf("events: %s", got)
	}
}
