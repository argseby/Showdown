package botclient

import (
	"log/slog"
	"math"
	"testing"

	"showdown/internal/protocol"
)

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
	b := New(Config{Strategy: StrategySolid, Seed: 7, Log: slog.New(slog.DiscardHandler)})
	b.Seat = 0
	o := sp.options
	o.Call = sp.call
	return b.decideSolid(o, sp.snapshot())
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
		b := New(Config{Strategy: StrategySolid, Seed: seed, Log: slog.New(slog.DiscardHandler)})
		b.Seat = 0
		o := sp.options
		o.Call = sp.call
		if b.decideSolid(o, sp.snapshot()).Kind == "check" {
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
		b := New(Config{Strategy: StrategySolid, Seed: seed, Log: slog.New(slog.DiscardHandler)})
		b.Seat = 0
		if got := b.decideSolid(sp.options, sp.snapshot()); got.Kind == "fold" {
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
				b := New(Config{Seed: seed, Log: slog.New(slog.DiscardHandler)})
				spot, ok := readSpot(protocol.OptionsView{}, s, 0)
				if !ok {
					t.Fatal("could not read the spot")
				}
				got += equityVsRandom(spot, b.rng)
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
		b := New(Config{Seed: 3, Log: slog.New(slog.DiscardHandler)})
		got := equityVsRandom(spot, b.rng)
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
