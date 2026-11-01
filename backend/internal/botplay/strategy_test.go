package botplay

import (
	"math"
	"math/rand/v2"
	"testing"

	"showdown/internal/protocol"
)

// seeded is a repeatable source for the mixed frequencies and the sampler.
func seeded(seed uint64) *rand.Rand {
	return rand.New(rand.NewPCG(seed, seed^0x9e3779b97f4a7c15))
}

// solidSpot builds a snapshot for one turn: our seat holds `hole`, the board
// is `board`, and `opponents` other seats are in the hand. Seat 0 is ours and
// the button sits on the last occupied seat, so we act first unless said
// otherwise — the harder side of every decision.
type solidSpot struct {
	hole       []string
	board      []string
	opponents  int
	pot        int64
	call       int64
	currentBet int64
	button     int
	street     string
	options    protocol.OptionsView
}

const (
	solidBB       = 100
	solidMaxSeats = 6
)

func (sp solidSpot) snapshot() protocol.Snapshot {
	street := sp.street
	if street == "" {
		if len(sp.board) == 0 {
			street = "preflop"
		} else {
			street = "flop"
		}
	}
	s := protocol.Snapshot{
		Table: protocol.TableInfo{Settings: protocol.PublicSettings{
			BigBlind: solidBB, SmallBlind: solidBB / 2, MaxPlayers: solidMaxSeats, Variant: "holdem",
		}},
		Hand: &protocol.HandView{
			Street: street, Board: sp.board, ButtonSeat: sp.button, CurrentBet: sp.currentBet,
			Phase: "betting", Pots: []protocol.PotView{{Amount: sp.pot}},
		},
	}
	s.Seats = append(s.Seats, protocol.SeatView{Seat: 0, Player: &protocol.PlayerView{
		ID: "me", Name: "Solid", Stack: 10000, Status: "active", Connected: true,
		InHand: true, HoleCards: sp.hole,
	}})
	for i := 1; i <= sp.opponents; i++ {
		s.Seats = append(s.Seats, protocol.SeatView{Seat: i, Player: &protocol.PlayerView{
			ID: "o", Name: "Opp", Stack: 10000, Status: "active", Connected: true, InHand: true,
		}})
	}
	return s
}

// act runs the solid strategy on the spot. The seed is fixed, so the mixed
// frequencies in the strategy do not make the test flaky.
func (sp solidSpot) act(t *testing.T) protocol.ActionPayload {
	t.Helper()
	o := sp.options
	o.Call = sp.call
	return Decide(o, sp.snapshot(), 0, seeded(7))
}

func TestSolidPreflopRaisesPremiumsAndFoldsTrash(t *testing.T) {
	// Six-handed, unopened, us under the gun: the tightest seat there is.
	open := solidSpot{opponents: 5, pot: 150, call: solidBB, currentBet: solidBB, button: 5,
		options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 200, Max: 10000}, AllIn: 10000}}

	for _, hole := range [][]string{{"As", "Ah"}, {"Kd", "Kc"}, {"As", "Ks"}} {
		sp := open
		sp.hole = hole
		got := sp.act(t)
		if got.Kind != "raise" {
			t.Errorf("%v under the gun: got %q, want a raise", hole, got.Kind)
		}
		// Three big blinds or so, not the minimum and not a shove.
		if got.Amount < 3*solidBB || got.Amount > 6*solidBB {
			t.Errorf("%v opened to %d, want roughly three big blinds", hole, got.Amount)
		}
	}
	for _, hole := range [][]string{{"7d", "2c"}, {"9s", "4h"}, {"Jc", "3d"}} {
		sp := open
		sp.hole = hole
		if got := sp.act(t); got.Kind != "fold" {
			t.Errorf("%v under the gun: got %q, want a fold", hole, got.Kind)
		}
	}
}

func TestSolidPreflopFoldsToARaiseWithAWeakHand(t *testing.T) {
	sp := solidSpot{hole: []string{"Jd", "8c"}, opponents: 2, pot: 1050, call: 800, currentBet: 800, button: 2,
		options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 1500, Max: 10000}, AllIn: 10000}}
	if got := sp.act(t); got.Kind != "fold" {
		t.Errorf("J8o facing a big raise: got %q, want a fold", got.Kind)
	}
	sp.hole = []string{"Ac", "Ad"}
	if got := sp.act(t); got.Kind != "raise" {
		t.Errorf("aces facing a raise: got %q, want a re-raise", got.Kind)
	}
}

func TestSolidValueBetsTheNutsAndChecksAirInPosition(t *testing.T) {
	// Flopped top set on a dry board, checked to us.
	sp := solidSpot{hole: []string{"9s", "9h"}, board: []string{"9d", "4c", "2h"}, opponents: 1,
		pot: 600, button: 0,
		options: protocol.OptionsView{Check: true, Raise: &protocol.RaiseView{Min: 100, Max: 10000}, AllIn: 10000}}
	got := sp.act(t)
	if got.Kind != "raise" {
		t.Fatalf("top set checked to us: got %q, want a bet", got.Kind)
	}
	if got.Amount < 300 || got.Amount > 600 {
		t.Errorf("bet %d into 600, want about two thirds of the pot", got.Amount)
	}

	// The same board with nothing at all: checking behind must be the norm.
	sp.hole = []string{"7c", "3d"}
	checks := 0
	for seed := uint64(1); seed <= 20; seed++ {
		o := sp.options
		o.Call = sp.call
		if Decide(o, sp.snapshot(), 0, seeded(seed)).Kind == "check" {
			checks++
		}
	}
	if checks < 14 {
		t.Errorf("checked back air %d times in 20, want mostly checks", checks)
	}
}

func TestSolidFoldsToABigBetWithoutEquity(t *testing.T) {
	sp := solidSpot{hole: []string{"7c", "3d"}, board: []string{"Ad", "Kc", "Qh", "9s", "2c"}, street: "river",
		opponents: 1, pot: 600, call: 600, currentBet: 600, button: 1,
		options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 1200, Max: 10000}, AllIn: 10000}}
	if got := sp.act(t); got.Kind != "fold" {
		t.Errorf("seven high facing a pot-sized river bet: got %q, want a fold", got.Kind)
	}
}

func TestSolidRaisesTheNutsOnTheRiver(t *testing.T) {
	// Straight flush: nothing beats it, so a bet in front of us gets raised.
	sp := solidSpot{hole: []string{"9h", "8h"}, board: []string{"7h", "6h", "5h", "2c", "Kd"}, street: "river",
		opponents: 1, pot: 800, call: 200, currentBet: 200, button: 1,
		options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 400, Max: 10000}, AllIn: 10000}}
	got := sp.act(t)
	if got.Kind != "raise" {
		t.Fatalf("straight flush facing a bet: got %q, want a raise", got.Kind)
	}
	if got.Amount <= 200 {
		t.Errorf("raised to %d, want more than the %d bet", got.Amount, 200)
	}
}

func TestSolidCallsOnPotOdds(t *testing.T) {
	// A flush draw on the flop getting 9 to 1: roughly 35% to get there,
	// so calling 10% of the pot is not close.
	sp := solidSpot{hole: []string{"Ah", "5h"}, board: []string{"Kh", "9h", "2c"}, opponents: 1,
		pot: 900, call: 100, currentBet: 100, button: 1,
		options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 200, Max: 10000}, AllIn: 10000}}
	if got := sp.act(t); got.Kind != "call" && got.Kind != "raise" {
		t.Errorf("nut flush draw getting 9 to 1: got %q, want a call", got.Kind)
	}
	// The same draw for a pot-sized bet is not worth it.
	sp.pot, sp.call, sp.currentBet = 900, 900, 900
	sp.options.Raise = &protocol.RaiseView{Min: 1800, Max: 10000}
	if got := sp.act(t); got.Kind != "fold" {
		t.Errorf("nut flush draw facing a pot-sized bet: got %q, want a fold", got.Kind)
	}
}

func TestSolidNeverFoldsWhenChecking(t *testing.T) {
	sp := solidSpot{hole: []string{"7c", "3d"}, board: []string{"Ad", "Kc", "Qh"}, opponents: 3,
		pot: 400, button: 3,
		options: protocol.OptionsView{Check: true, Raise: &protocol.RaiseView{Min: 100, Max: 10000}, AllIn: 10000}}
	for seed := uint64(1); seed <= 25; seed++ {
		if got := Decide(sp.options, sp.snapshot(), 0, seeded(seed)); got.Kind == "fold" {
			t.Fatalf("seed %d folded a free look at the pot", seed)
		}
	}
}

func TestSolidFallsBackWithoutHoleCards(t *testing.T) {
	// A spectator's snapshot, or one that arrives before the deal: the bot
	// must not guess, it takes the free option instead.
	sp := solidSpot{opponents: 2, pot: 300, button: 2,
		options: protocol.OptionsView{Check: true, Raise: &protocol.RaiseView{Min: 100, Max: 10000}}}
	if got := sp.act(t); got.Kind != "check" {
		t.Errorf("no hole cards: got %q, want a check", got.Kind)
	}
}

func TestEquityVsRandomMatchesKnownNumbers(t *testing.T) {
	// Published heads-up numbers for all-in preflop hands, to a percentage
	// point or so. They pin the sampler down: a wrong deck, a mixed-up
	// tie count or a biased shuffle all show up here.
	cases := []struct {
		name string
		hole []string
		want float64
	}{
		{"AA vs one random hand", []string{"As", "Ah"}, 0.852},
		{"72o vs one random hand", []string{"7c", "2d"}, 0.354},
		{"AKs vs one random hand", []string{"As", "Ks"}, 0.670},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			sp := solidSpot{hole: c.hole, opponents: 1, button: 1}
			s := sp.snapshot()
			got := 0.0
			// Average a few seeds: one run of 1500 samples is only good to
			// about a percentage point on its own.
			const runs = 6
			for seed := uint64(1); seed <= runs; seed++ {
				spot, ok := readSpot(protocol.OptionsView{}, s, 0)
				if !ok {
					t.Fatal("could not read the spot")
				}
				got += equityVsRandom(spot, seeded(seed))
			}
			got /= runs
			if math.Abs(got-c.want) > 0.012 {
				t.Errorf("equity %.3f, want %.3f", got, c.want)
			}
		})
	}
}

func TestEquityVsRandomFallsWithMoreOpponents(t *testing.T) {
	// The same aces are worth less against more hands, and always more than
	// an even share of the pot.
	prev := 1.0
	for opponents := 1; opponents <= 5; opponents++ {
		sp := solidSpot{hole: []string{"As", "Ah"}, opponents: opponents, button: opponents}
		spot, ok := readSpot(protocol.OptionsView{}, sp.snapshot(), 0)
		if !ok {
			t.Fatal("could not read the spot")
		}
		got := equityVsRandom(spot, seeded(3))
		if got >= prev {
			t.Errorf("%d opponents: equity %.3f did not fall below %.3f", opponents, got, prev)
		}
		if share := 1 / float64(opponents+1); got <= share {
			t.Errorf("%d opponents: aces hold %.3f, want more than an even %.3f", opponents, got, share)
		}
		prev = got
	}
}

func TestReadSpotPosition(t *testing.T) {
	// Button on seat 5 of six, us on seat 0: we are the small blind, first
	// to act after the flop, with four opponents still to act behind.
	sp := solidSpot{hole: []string{"As", "Ah"}, board: []string{"2c", "7d", "9h"}, opponents: 5, button: 5, pot: 300}
	spot, ok := readSpot(protocol.OptionsView{}, sp.snapshot(), 0)
	if !ok {
		t.Fatal("could not read the spot")
	}
	if spot.opponents != 5 {
		t.Errorf("opponents %d, want 5", spot.opponents)
	}
	if spot.relPos != 0 {
		t.Errorf("relPos %.2f, want 0 (first to act)", spot.relPos)
	}
	// Move the button behind us and we act last instead.
	sp.button = 5
	s := sp.snapshot()
	s.Hand.ButtonSeat = 0
	spot, _ = readSpot(protocol.OptionsView{}, s, 0)
	if spot.relPos != 1 {
		t.Errorf("relPos %.2f on the button, want 1 (last to act)", spot.relPos)
	}
	// An all-in opponent still contests the pot but no longer acts.
	s.Seats[1].Player.AllIn = true
	s.Hand.ButtonSeat = 5
	spot, _ = readSpot(protocol.OptionsView{}, s, 0)
	if spot.opponents != 5 {
		t.Errorf("opponents %d with one all-in, want 5", spot.opponents)
	}
	if spot.relPos != 0 {
		t.Errorf("relPos %.2f, want 0: the all-in seat does not act", spot.relPos)
	}
}

// The advice is the strategy's own line, and it is the same line every
// time: a player who asks twice in one spot must not be told two things.
func TestAdviseIsStableAndAgreesWithTheBot(t *testing.T) {
	t.Parallel()
	// A strong made hand facing a bet: the strategy has a clear line.
	sp := solidSpot{
		hole: []string{"Ah", "Ad"}, board: []string{"As", "7c", "2d"},
		opponents: 2, pot: 600, call: 200, currentBet: 200, button: 2,
		options: protocol.OptionsView{
			Fold: true, Raise: &protocol.RaiseView{Min: 400, Max: 10000}, AllIn: 10000,
		},
	}
	o := sp.options
	o.Call = sp.call
	snap, seat := sp.snapshot(), 0
	first, ok := Advise(o, snap, seat)
	if !ok {
		t.Fatal("no advice for a readable spot")
	}
	for range 5 {
		again, _ := Advise(o, snap, seat)
		if again != first {
			t.Fatalf("advice changed between asks: %+v then %+v", first, again)
		}
	}
	if first.Action == "" {
		t.Error("advice without an action")
	}
	if first.Equity <= 0 || first.Equity > 1 {
		t.Errorf("equity = %v, want a share of the pot", first.Equity)
	}
	// The bot facing the same spot plays the advice, or the plain line the
	// advice declined to gamble on (the mixed bluff and thin value bet).
	rng := rand.New(rand.NewPCG(7, 7))
	act := Decide(o, snap, seat, rng)
	if act.Kind != first.Action && first.Action != "check" && first.Action != "fold" {
		t.Errorf("bot played %q where the advice says %q", act.Kind, first.Action)
	}
}

// Advice never bluffs: the coin flips the strategy mixes in are declined,
// so a checked pot is checked back rather than stabbed at.
func TestAdviseDeclinesTheCoinFlips(t *testing.T) {
	t.Parallel()
	// A checked pot, heads-up and last to act, holding nothing: the one
	// place the strategy stabs at a pot by coin flip.
	sp := solidSpot{
		hole: []string{"7h", "2c"}, board: []string{"As", "Kd", "Qs"},
		opponents: 1, pot: 200, button: 0, street: "flop",
		options: protocol.OptionsView{
			Check: true, Raise: &protocol.RaiseView{Min: 100, Max: 10000}, AllIn: 10000,
		},
	}
	a, ok := Advise(sp.options, sp.snapshot(), 0)
	if !ok {
		t.Fatal("no advice for a readable spot")
	}
	if a.Action == "raise" && a.Edge < 0.35 {
		t.Errorf("advice raised on an edge of %.2f — that is the bluff it must decline", a.Edge)
	}
}

// A raise carries its size in words, because "raise a little" is something
// a beginner can act on and "raise to 420" is arithmetic.
func TestAdviseSizesARaiseInWords(t *testing.T) {
	t.Parallel()
	// A monster on the flop: the strategy bets for value, two thirds of
	// the pot, which is the big one of the two sizes.
	big := solidSpot{
		hole: []string{"Ah", "Ad"}, board: []string{"As", "7c", "2d"},
		opponents: 1, pot: 400, button: 0, street: "flop",
		options: protocol.OptionsView{
			Check: true, Raise: &protocol.RaiseView{Min: 100, Max: 10000}, AllIn: 10000,
		},
	}
	a, ok := Advise(big.options, big.snapshot(), 0)
	if !ok {
		t.Fatal("no advice for a readable spot")
	}
	if a.Action != "raise" {
		t.Fatalf("action = %q with aces full of nothing, want a raise", a.Action)
	}
	if a.Sizing != SizingBig {
		t.Errorf("sizing = %q, want %q", a.Sizing, SizingBig)
	}

	// Anything that is not a raise has no size to speak of.
	fold := solidSpot{
		hole: []string{"7h", "2c"}, board: []string{"As", "Kd", "Qs"},
		opponents: 3, pot: 600, call: 600, currentBet: 600, button: 3, street: "flop",
		options: protocol.OptionsView{
			Fold: true, Raise: &protocol.RaiseView{Min: 1200, Max: 10000}, AllIn: 10000,
		},
	}
	o := fold.options
	o.Call = fold.call
	if a, _ := Advise(o, fold.snapshot(), 0); a.Action == "raise" || a.Sizing != "" {
		t.Errorf("action %q sizing %q, want no size on a hand it does not raise", a.Action, a.Sizing)
	}
}

// Every line the strategy takes carries the reason it took it: a player
// told "too expensive for what you are holding" has learned something,
// and one told a percentage has not.
func TestAdviseAlwaysSaysWhy(t *testing.T) {
	t.Parallel()
	spots := []solidSpot{
		// Preflop, unopened, from the button with a premium.
		{hole: []string{"Ah", "Ad"}, opponents: 2, pot: 150, call: solidBB,
			currentBet: solidBB, button: 0,
			options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 200, Max: 10000}, AllIn: 10000}},
		// Preflop, facing a raise, with trash.
		{hole: []string{"7h", "2c"}, opponents: 2, pot: 450, call: 300,
			currentBet: 300, button: 2,
			options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 600, Max: 10000}, AllIn: 10000}},
		// Flop, checked to us, holding the world.
		{hole: []string{"Ah", "Ad"}, board: []string{"As", "7c", "2d"},
			opponents: 1, pot: 400, button: 0, street: "flop",
			options: protocol.OptionsView{Check: true, Raise: &protocol.RaiseView{Min: 100, Max: 10000}, AllIn: 10000}},
		// Flop, facing a big bet, holding nothing.
		{hole: []string{"7h", "2c"}, board: []string{"As", "Kd", "Qs"},
			opponents: 2, pot: 600, call: 600, currentBet: 600, button: 2, street: "flop",
			options: protocol.OptionsView{Fold: true, Raise: &protocol.RaiseView{Min: 1200, Max: 10000}, AllIn: 10000}},
	}
	for i, sp := range spots {
		o := sp.options
		o.Call = sp.call
		a, ok := Advise(o, sp.snapshot(), 0)
		if !ok {
			t.Fatalf("spot %d: no advice", i)
		}
		if a.Reason == "" {
			t.Errorf("spot %d: %q without a reason", i, a.Action)
		}
	}
}
