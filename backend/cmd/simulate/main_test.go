package main

import (
	"math"
	"math/rand/v2"
	"testing"

	"showdown/internal/poker"
)

// TestCleanRun plays a small number of tables and expects every invariant to
// hold. It is the short version of what the command does.
func TestCleanRun(t *testing.T) {
	t.Parallel()
	tables := 300
	if testing.Short() {
		tables = 40
	}
	f := newFindings(10)
	for i := 0; i < tables; i++ {
		playTable(i, rand.New(rand.NewPCG(20260906, uint64(i))), f, 30)
	}
	passed, failed := f.totals()
	if failed != 0 {
		for _, v := range f.list {
			t.Errorf("[%s] table %d hand %d: %s", v.Check, v.Table, v.Hand, v.Detail)
		}
		t.Fatalf("%d of %d checks failed", failed, passed+failed)
	}
	if f.hands < int64(tables) {
		t.Fatalf("only %d hands played over %d tables", f.hands, tables)
	}
	// Every invariant has to have been exercised, or the run proves nothing.
	for i := checkID(0); i < numChecks; i++ {
		if f.passed[i] == 0 {
			t.Errorf("check %s never ran", checkInfo[i].Name)
		}
	}
	// The chips have to add up across the whole run.
	if want := f.boughtIn + f.adjusted - f.cashedOut; want != f.finalStacks {
		t.Fatalf("chips in stacks %d, bought in %d + adjusted %d - cashed out %d = %d",
			f.finalStacks, f.boughtIn, f.adjusted, f.cashedOut, want)
	}
}

// TestChecksCatchFaults feeds the checkers wrong input. A verifier that
// cannot fail proves nothing, so each of these has to be reported.
func TestChecksCatchFaults(t *testing.T) {
	t.Parallel()
	newState := func() *handState {
		f := newFindings(10)
		ts := newTableSim(0, rand.New(rand.NewPCG(1, 1)), f)
		seats := []poker.Seat{{Seat: 0, Stack: 1000}, {Seat: 1, Stack: 1000}, {Seat: 2, Stack: 1000}}
		cfg := poker.HandConfig{SmallBlind: 50, BigBlind: 100, ButtonSeat: 0}
		h, _, err := poker.NewHand(cfg, seats, poker.SecureShuffle)
		if err != nil {
			t.Fatalf("NewHand: %v", err)
		}
		return newHandState(ts, h, cfg, seats, 3000)
	}

	t.Run("wrong pot amount", func(t *testing.T) {
		s := newState()
		s.contrib = map[int]int64{0: 100, 1: 100, 2: 100}
		s.checkPots([]poker.Pot{{Amount: 400, Eligible: []int{0, 1, 2}}})
		if s.f.failed[chkPots] == 0 {
			t.Fatal("a pot that holds more than the players contributed was accepted")
		}
	})
	t.Run("folded player eligible", func(t *testing.T) {
		s := newState()
		s.contrib = map[int]int64{0: 100, 1: 100, 2: 100}
		s.folded = map[int]bool{2: true}
		s.checkPots([]poker.Pot{{Amount: 300, Eligible: []int{0, 1, 2}}})
		if s.f.failed[chkPots] == 0 {
			t.Fatal("a folded player was accepted as a pot contender")
		}
	})
	t.Run("missing side pot", func(t *testing.T) {
		s := newState()
		s.contrib = map[int]int64{0: 50, 1: 200, 2: 200}
		s.allIn = map[int]bool{0: true}
		s.checkPots([]poker.Pot{{Amount: 450, Eligible: []int{0, 1, 2}}})
		if s.f.failed[chkPots] == 0 {
			t.Fatal("a short all-in without a side pot was accepted")
		}
	})
	t.Run("chips appear from nowhere", func(t *testing.T) {
		f := newFindings(10)
		ts := newTableSim(0, rand.New(rand.NewPCG(2, 2)), f)
		seats := []poker.Seat{{Seat: 0, Stack: 1000}, {Seat: 1, Stack: 1000}}
		cfg := poker.HandConfig{SmallBlind: 50, BigBlind: 100, ButtonSeat: 0}
		h, events, err := poker.NewHand(cfg, seats, poker.SecureShuffle)
		if err != nil {
			t.Fatalf("NewHand: %v", err)
		}
		// Claim one chip more is in play than really is.
		s := newHandState(ts, h, cfg, seats, 2001)
		s.consume(events)
		if f.failed[chkChips] == 0 {
			t.Fatal("a hand with the wrong number of chips was accepted")
		}
	})
	t.Run("wrong blinds", func(t *testing.T) {
		s := newState()
		s.handStarted(poker.Event{Kind: poker.EvHandStarted, Start: &poker.HandStart{
			ButtonSeat: 0, SBSeat: 2, BBSeat: 1, // clockwise order reversed
		}})
		if s.f.failed[chkPositions] == 0 {
			t.Fatal("blinds in the wrong seats were accepted")
		}
	})
	t.Run("card dealt twice", func(t *testing.T) {
		s := newState()
		s.deal([]poker.Card{poker.MakeCard(poker.Ace, poker.Spades)})
		s.deal([]poker.Card{poker.MakeCard(poker.Ace, poker.Spades)})
		if s.f.failed[chkDeck] == 0 {
			t.Fatal("the same card dealt twice was accepted")
		}
	})
	t.Run("bankroll leak", func(t *testing.T) {
		f := newFindings(10)
		ts := newTableSim(0, rand.New(rand.NewPCG(3, 3)), f)
		ts.seats[0].stack += 7 // chips out of thin air
		ts.checkBankroll()
		if f.failed[chkBankroll] == 0 {
			t.Fatal("a table with chips out of thin air was accepted")
		}
	})
}

func TestChiSquareP(t *testing.T) {
	t.Parallel()
	cases := []struct {
		x    float64
		df   int
		want float64
	}{
		{0, 8, 1},
		{3.8415, 1, 0.05},      // the classic 5 % critical value
		{15.5073, 8, 0.05},     // 8 degrees of freedom
		{20.0902, 51, 0.99987}, // far below expectation
	}
	for _, c := range cases {
		got := chiSquareP(c.x, c.df)
		if math.Abs(got-c.want) > 0.002 {
			t.Errorf("chiSquareP(%g, %d) = %g, want %g", c.x, c.df, got, c.want)
		}
	}
	if p := chiSquareP(200, 8); p > 1e-30 {
		t.Errorf("a hopeless statistic gave p = %g", p)
	}
}

// TestAuditShuffle checks the fairness test itself runs and adds up; the
// statistical verdict is what the command reports.
func TestAuditShuffle(t *testing.T) {
	t.Parallel()
	const n = 2000
	a := auditShuffle(n)
	var total int64
	for _, c := range a.Counts {
		total += c
	}
	if total != n {
		t.Fatalf("classified %d of %d deals", total, n)
	}
	if a.CategoryP < 0 || a.CategoryP > 1 || a.PositionP < 0 || a.PositionP > 1 {
		t.Fatalf("p-values out of range: %g, %g", a.CategoryP, a.PositionP)
	}
}

// TestAuditEvaluator is the exhaustive five-card check the report leads with.
func TestAuditEvaluator(t *testing.T) {
	if testing.Short() {
		t.Skip("exhaustive")
	}
	t.Parallel()
	a := auditEvaluator()
	if !a.OK || a.Hands != 2598960 {
		t.Fatalf("counts %v over %d hands, want %v", a.Counts, a.Hands, a.Expected)
	}
}

func TestComma(t *testing.T) {
	t.Parallel()
	cases := map[int64]string{0: "0", 7: "7", 1000: "1,000", -1234567: "-1,234,567", 100: "100", 12345: "12,345"}
	for in, want := range cases {
		if got := comma(in); got != want {
			t.Errorf("comma(%d) = %q, want %q", in, got, want)
		}
	}
}
