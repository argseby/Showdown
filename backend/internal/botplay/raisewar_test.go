package botplay

import (
	"fmt"
	"strings"
	"testing"

	"showdown/internal/protocol"
)

// headsUpPreflop plays a whole preflop betting round between two copies of
// the strategy, on snapshots built the way the server builds them: Pots holds
// only what earlier streets committed — nothing, before the flop — and the
// blinds sit in BetThisStreet. It returns one line per action.
func headsUpPreflop(t *testing.T, holes [2][]string, stack int64) []string {
	t.Helper()
	const bb, sb = solidBB, solidBB / 2
	bets := [2]int64{sb, bb} // seat 0 is the button and small blind
	stacks := [2]int64{stack - sb, stack - bb}
	currentBet, lastRaise := int64(bb), int64(bb)
	var log []string

	snap := func(seat int) protocol.Snapshot {
		s := protocol.Snapshot{
			Table: protocol.TableInfo{Settings: protocol.PublicSettings{
				BigBlind: bb, SmallBlind: sb, MaxPlayers: 2, Variant: "holdem",
			}},
			Hand: &protocol.HandView{
				Street: "preflop", ButtonSeat: 0, SBSeat: 0, BBSeat: 1,
				CurrentBet: currentBet, MinRaiseTo: currentBet + lastRaise,
				Phase: "betting", Pots: []protocol.PotView{},
			},
		}
		for i := range 2 {
			p := &protocol.PlayerView{
				ID: fmt.Sprint(i), Name: fmt.Sprint(i), Stack: stacks[i], Status: "active",
				Connected: true, InHand: true, BetThisStreet: bets[i], TotalBet: bets[i],
			}
			if i == seat {
				p.HoleCards = holes[i]
			}
			s.Seats = append(s.Seats, protocol.SeatView{Seat: i, Player: p})
		}
		return s
	}

	seat := 0 // the button acts first before the flop, heads-up
	for range 200 {
		call := currentBet - bets[seat]
		o := protocol.OptionsView{Fold: true, Call: call, Check: call == 0, AllIn: stacks[seat] + bets[seat]}
		if stacks[seat] > call {
			o.Raise = &protocol.RaiseView{
				Min: min(currentBet+lastRaise, stacks[seat]+bets[seat]),
				Max: stacks[seat] + bets[seat],
			}
		}
		a := Decide(o, snap(seat), seat, seeded(uint64(7+seat)))
		log = append(log, fmt.Sprintf("seat %d: %s %d (to call %d)", seat, a.Kind, a.Amount, call))
		switch a.Kind {
		case "fold", "check":
			return log
		case "call":
			stacks[seat] -= call
			bets[seat] += call
			return log
		case "raise", "all_in":
			to := a.Amount
			if a.Kind == "all_in" {
				to = stacks[seat] + bets[seat]
			}
			lastRaise = to - currentBet
			stacks[seat] -= to - bets[seat]
			bets[seat], currentBet = to, to
			if stacks[seat] == 0 {
				return log
			}
		}
		seat = 1 - seat
	}
	t.Fatalf("the betting round never ended:\n%s", strings.Join(log, "\n"))
	return log
}

// TestPreflopRaisingTerminates is the regression test for the raise war: two
// bots with the same decent hand used to re-raise each other one big blind at
// a time until one was all in, because the pot they sized their raises from
// left out this street's bets and read as empty, and because the bar to
// re-raise did not move however much was already in.
func TestPreflopRaisingTerminates(t *testing.T) {
	hands := [][]string{
		{"Ah", "Kd"}, {"Qs", "Qc"}, {"As", "Ac"}, {"Kh", "Ks"}, {"Jd", "Jc"},
		{"Ad", "Qh"}, {"Th", "Ts"}, {"9c", "9d"}, {"7h", "2c"}, {"As", "Ks"},
		{"8d", "8h"}, {"Kc", "Qd"},
	}
	// A hand is not a war at any depth a table is ever played at, and stays
	// bounded even a thousand big blinds deep.
	for _, stack := range []int64{15 * solidBB, 30 * solidBB, 100 * solidBB, 1000 * solidBB} {
		worst := 0
		for _, a := range hands {
			for _, b := range hands {
				if a[0] == b[0] || a[0] == b[1] || a[1] == b[0] || a[1] == b[1] {
					continue // the same card cannot be in both hands
				}
				log := headsUpPreflop(t, [2][]string{a, b}, stack)
				raises := 0
				for _, l := range log {
					if strings.Contains(l, ": raise") || strings.Contains(l, ": all_in") {
						raises++
					}
				}
				worst = max(worst, raises)
				if raises > 6 {
					t.Errorf("%d big blinds, %v vs %v: %d raises\n%s",
						stack/solidBB, a, b, raises, strings.Join(log, "\n"))
				}
			}
		}
		t.Logf("%d big blinds deep: at most %d raises in a preflop round", stack/solidBB, worst)
	}
}

// TestPreflopOpenAndThreeBetAreSized checks the sizes the raise war exposed:
// an open of about three big blinds and a three-bet of about three times
// that, rather than a minimum raise on top of the blind.
func TestPreflopOpenAndThreeBetAreSized(t *testing.T) {
	log := headsUpPreflop(t, [2][]string{{"Ah", "Kd"}, {"Qs", "Qc"}}, 100*solidBB)
	if len(log) < 2 {
		t.Fatalf("expected an open and a three-bet, got:\n%s", strings.Join(log, "\n"))
	}
	if want := fmt.Sprintf("seat 0: raise %d", 3*solidBB); !strings.HasPrefix(log[0], want) {
		t.Errorf("open: %q, want %q", log[0], want)
	}
	if want := fmt.Sprintf("seat 1: raise %d", 9*solidBB); !strings.HasPrefix(log[1], want) {
		t.Errorf("three-bet: %q, want %q", log[1], want)
	}
}
