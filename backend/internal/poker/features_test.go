package poker

import (
	"math"
	"testing"
)

func TestEquityExhaustiveAndSampled(t *testing.T) {
	t.Parallel()
	card := func(s string) Card {
		c, err := ParseCard(s)
		if err != nil {
			t.Fatal(err)
		}
		return c
	}
	hands := [][2]Card{{card("As"), card("Ad")}, {card("Ks"), card("Kd")}}
	// River decided: the better hand has all the equity.
	e := Equity([]Card{card("2c"), card("7h"), card("9s"), card("Jd"), card("3c")}, hands, 0, 1)
	if e[0] != 1 || e[1] != 0 {
		t.Fatalf("river equity = %v", e)
	}
	// Turn: exhaustive over the 44 river cards; kings need one of two outs.
	e = Equity([]Card{card("2c"), card("7h"), card("9s"), card("Jd")}, hands, 0, 1)
	if math.Abs(e[1]-2.0/44) > 1e-9 || math.Abs(e[0]+e[1]-1) > 1e-9 {
		t.Fatalf("turn equity = %v", e)
	}
	// Preflop: sampled; aces are a roughly 80/20 favourite and the result is
	// deterministic for a seed.
	a := Equity(nil, hands, 20000, 42)
	b := Equity(nil, hands, 20000, 42)
	if a[0] < 0.78 || a[0] > 0.86 || a[0] != b[0] {
		t.Fatalf("preflop equity = %v / %v", a, b)
	}
	// A tie splits.
	e = Equity([]Card{card("2c"), card("7h"), card("9s"), card("Jd"), card("3c")},
		[][2]Card{{card("As"), card("Kd")}, {card("Ah"), card("Kc")}}, 0, 1)
	if e[0] != 0.5 || e[1] != 0.5 {
		t.Fatalf("tie equity = %v", e)
	}
}

func TestStraddleSetsThePriceAndTheOrder(t *testing.T) {
	t.Parallel()
	// Button 0, SB 1, BB 2, UTG 3 straddles 200 (blinds 50/100).
	cfg := cfgWith(0)
	cfg.StraddleSeat, cfg.StraddleAmount = 3, 200
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}, {3, 1000}}
	h, ev := newTestHand(t, cfg, seats, map[int]string{0: "As Ad", 1: "Ks Kd", 2: "Qs Qd", 3: "Js Jd"}, "2c 7h 9s Td 3c")
	var straddle *Event
	for i := range ev {
		if ev[i].Kind == EvBlindPosted && ev[i].Blind == StraddleBlind {
			straddle = &ev[i]
		}
	}
	if straddle == nil || straddle.Seat != 3 || straddle.Amount != 200 {
		t.Fatalf("straddle event = %+v", straddle)
	}
	if h.StraddleSeat() != 3 {
		t.Fatalf("straddle seat %d", h.StraddleSeat())
	}
	// The button acts first (left of the straddler) and faces 200; the
	// minimum raise is to 400.
	mustToAct(t, h, 0)
	o := h.Options(0)
	if o.Call != 200 || o.Raise == nil || o.Raise.Min != 400 {
		t.Fatalf("options = %+v", o)
	}
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Call, 0)
	// The straddler has the option and may raise.
	mustToAct(t, h, 3)
	o = h.Options(3)
	if !o.Check || o.Raise == nil {
		t.Fatalf("straddler options = %+v", o)
	}
	act(t, h, 3, Check, 0)
	if h.Phase() != PhaseDealPending || h.Pots()[0].Amount != 800 {
		t.Fatalf("phase %v pots %+v", h.Phase(), h.Pots())
	}
	if h.TotalChips() != 4000 {
		t.Fatalf("chips %d", h.TotalChips())
	}
}

func TestStraddleNeedsThreePlayers(t *testing.T) {
	t.Parallel()
	cfg := cfgWith(0)
	cfg.StraddleSeat, cfg.StraddleAmount = 1, 200
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Td 3c")
	if h.StraddleSeat() != -1 || h.Options(0).Call != 50 {
		t.Fatalf("heads-up straddle: seat %d options %+v", h.StraddleSeat(), h.Options(0))
	}
}

func TestRunItTwiceSplitsEveryPot(t *testing.T) {
	t.Parallel()
	// Both all-in preflop; board 1 makes the kings a set, board 2 gives the
	// aces the pot. Deck order after the hole cards: board 1 flop, then
	// board 2 flop, board 1 turn, board 2 turn, board 1 river, board 2 river.
	cfg := cfgWith(0)
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "As Ad", 1: "Ks Kd"},
		"Kc 7h 9s 2c 3d 4h 5s Jd 6c Tc 8d")
	act(t, h, 0, AllIn, 0)
	act(t, h, 1, Call, 0)
	if !h.CanRunItTwice() {
		t.Fatalf("run-out should allow running it twice: phase %v", h.Phase())
	}
	if err := h.RunItTwice(); err != nil {
		t.Fatal(err)
	}
	if h.CanRunItTwice() {
		t.Fatal("cannot switch twice")
	}
	var ev []Event
	for !h.Done() {
		ev = append(ev, advance(t, h)...)
	}
	boards := map[int]int{}
	for _, e := range ev {
		if e.Kind == EvStreetDealt {
			boards[e.Board] += len(e.Cards)
		}
	}
	if boards[0] != 5 || boards[2] != 5 {
		t.Fatalf("board cards = %v", boards)
	}
	if b2 := h.Board2(); len(b2) != 5 || b2[0].String() != "2c" {
		t.Fatalf("board2 = %v", b2)
	}
	// Board 1 (Kc 7h 9s 4h 6c): kings win 1000; board 2 (2c 3d 5s Jd Tc ... ):
	// aces win 1000. Both keep their stacks.
	awards := map[int]int64{}
	for _, e := range ev {
		if e.Kind == EvPotAwarded {
			awards[e.Board] += e.Amount
		}
	}
	if awards[1] != 1000 || awards[2] != 1000 {
		t.Fatalf("awards per board = %v", awards)
	}
	if stack(t, h, 0) != 1000 || stack(t, h, 1) != 1000 || h.TotalChips() != 2000 {
		t.Fatalf("stacks %d %d", stack(t, h, 0), stack(t, h, 1))
	}
	if len(h.Results().Pots) != 2 || h.Results().Pots[0].Board != 1 || h.Results().Pots[1].Board != 2 {
		t.Fatalf("results %+v", h.Results().Pots)
	}
}

func TestRunItTwiceOddChipToFirstBoard(t *testing.T) {
	t.Parallel()
	// Blinds 25/50 leave an odd pot when the button shoves 75 and is called.
	cfg := HandConfig{SmallBlind: 25, BigBlind: 50, ButtonSeat: 0}
	seats := []Seat{{0, 75}, {1, 1000}}
	h, _ := newTestHand(t, cfg, seats, map[int]string{0: "As Ad", 1: "Ks Kd"},
		"Kc 7h 9s 2c 3d 4h 5s Jd 6c Tc 8d")
	act(t, h, 0, AllIn, 0)
	act(t, h, 1, Call, 0)
	if err := h.RunItTwice(); err != nil {
		t.Fatal(err)
	}
	for !h.Done() {
		advance(t, h)
	}
	pots := h.Results().Pots
	if len(pots) != 2 || pots[0].Amount != 75 || pots[1].Amount != 75 {
		t.Fatalf("pots %+v", pots)
	}
	if h.TotalChips() != 1075 {
		t.Fatalf("chips %d", h.TotalChips())
	}
}

func TestActionEventsCarryTheStreet(t *testing.T) {
	t.Parallel()
	seats := []Seat{{0, 1000}, {1, 1000}}
	h, _ := newTestHand(t, cfgWith(0), seats, map[int]string{0: "As Ad", 1: "Ks Kd"}, "2c 7h 9s Jd 3c")
	ev := act(t, h, 0, Call, 0)
	if ev[0].Kind != EvAction || ev[0].Street != Preflop {
		t.Fatalf("event %+v", ev[0])
	}
	act(t, h, 1, Check, 0)
	advance(t, h)
	ev = act(t, h, 1, Check, 0)
	if ev[0].Street != Flop {
		t.Fatalf("event %+v", ev[0])
	}
}
