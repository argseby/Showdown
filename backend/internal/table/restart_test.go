package table

import (
	"errors"
	"testing"
	"time"

	"showdown/internal/poker"
	"showdown/internal/protocol"
)

// endNow ends the running table immediately and waits until it is ended.
func endNow(t *testing.T, tbl *Table) {
	t.Helper()
	if err := tbl.End(true); err != nil {
		t.Fatalf("End: %v", err)
	}
	waitFor(t, "ended", func() bool { return tbl.State() == StateEnded })
}

func TestRestartOpensANewRoundOnTheSameTable(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.StartMoney = 500
	s.AutoStart = true
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")

	waitFor(t, "a hand", func() bool { return handNumber(tbl) >= 1 })
	playToEnd(t, tbl)
	waitFor(t, "hand finished", func() bool { return !handRunning(tbl) })
	endNow(t, tbl)
	handsBefore := handNumber(tbl)

	// Only an ended table starts a new round.
	if err := tbl.Restart(); err != nil {
		t.Fatalf("Restart: %v", err)
	}
	if err := tbl.Restart(); !errors.Is(err, ErrInvalidState) {
		t.Fatalf("restart a waiting table: %v", err)
	}

	if tbl.State() != StateWaiting {
		t.Fatalf("state = %s", tbl.State())
	}
	// Nobody was dropped: the seats, the sessions and the link all stand.
	if closed, code := connA.isClosed(); closed {
		t.Fatalf("Alice's connection closed (%d) across the restart", code)
	}
	tbl.call(func() {
		for _, id := range []string{a.PlayerID, b.PlayerID} {
			p := tbl.players[id]
			if p == nil {
				t.Fatalf("%s lost their seat", id)
				return
			}
			if p.Stack != 500 || p.BuyInTotal != 500 {
				t.Errorf("%s: stack %d, bought in %d, want 500/500", p.Name, p.Stack, p.BuyInTotal)
			}
			if p.Status != StatusActive || p.Place != 0 {
				t.Errorf("%s: status %s, place %d", p.Name, p.Status, p.Place)
			}
			if p.HandsPlayed != 0 || p.HandsWon != 0 || p.BiggestPot != 0 || p.Showdowns != 0 || p.VPIPHands != 0 {
				t.Errorf("%s: statistics not reset: %+v", p.Name, p)
			}
		}
		// Hands are unique per table and number, so numbering runs on; the
		// round marker is what the tournament lock goes by.
		if tbl.handNumber != handsBefore || tbl.roundStartHand != handsBefore {
			t.Errorf("hand %d, round start %d, want both %d", tbl.handNumber, tbl.roundStartHand, handsBefore)
		}
		if tbl.endedAt != 0 || tbl.buttonSeat != -1 {
			t.Errorf("ended at %d, button %d", tbl.endedAt, tbl.buttonSeat)
		}
	})

	// The standing of the finished round outlives the reset.
	var snap protocol.Snapshot
	waitFor(t, "a snapshot of the new round", func() bool {
		snap = connA.lastSnapshot(t)
		return snap.Table.State == StateWaiting
	})
	if snap.LastRound == nil || len(snap.LastRound.Standings) != 2 {
		t.Fatalf("last round = %+v", snap.LastRound)
	}
	if snap.LastRound.Hands != handsBefore {
		t.Errorf("last round over %d hands, want %d", snap.LastRound.Hands, handsBefore)
	}
	restarted := false
	for _, e := range connA.events(t) {
		if e.Kind == "table_restarted" {
			restarted = true
		}
	}
	if !restarted {
		t.Error("no table_restarted event")
	}
}

func TestRestartBringsBustedPlayersBack(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AllowRebuy = false
	s.StartMoney = 200
	tbl := newTestTableShuffled(t, s, poker.SecureShuffle)
	join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	// Shove until one player owns everything and the table ends itself.
	deadline := time.Now().Add(10 * time.Second)
	for tbl.State() != StateEnded {
		if time.Now().After(deadline) {
			t.Fatal("table did not end")
		}
		id, _ := toAct(tbl)
		if id == "" {
			time.Sleep(5 * time.Millisecond)
			continue
		}
		if err := tbl.Action(id, poker.Action{Kind: poker.AllIn}); err != nil {
			_ = tbl.Action(id, poker.Action{Kind: poker.Call})
		}
	}
	if err := tbl.Restart(); err != nil {
		t.Fatalf("Restart: %v", err)
	}
	tbl.call(func() {
		for _, p := range tbl.seats[:maxSeats] {
			if p == nil {
				continue
			}
			if p.Stack != 200 || p.Status != StatusActive || p.Place != 0 {
				t.Errorf("%s: stack %d, status %s, place %d", p.Name, p.Stack, p.Status, p.Place)
			}
		}
	})
}

func TestRestartUnlocksATournamentAndResetsTheBlinds(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.Tournament = true
	s.AutoStart = false
	s.StartMoney = 1000
	s.SmallBlind, s.BigBlind = 25, 50
	s.StartSmallBlind, s.StartBigBlind = 25, 50
	s.BlindsUpPercent = 100
	tbl := newTestTable(t, s)
	alice, _ := join(t, tbl, "Alice")
	join(t, tbl, "Bob")

	if err := tbl.Start(); err != nil {
		t.Fatalf("Start: %v", err)
	}
	waitFor(t, "a hand", func() bool { return handNumber(tbl) >= 1 })
	if err := tbl.BlindsUp(); err != nil {
		t.Fatalf("BlindsUp: %v", err)
	}
	playToEnd(t, tbl)
	endNow(t, tbl)

	var locked bool
	tbl.call(func() { locked = tbl.tournamentLocked() })
	if !locked {
		t.Fatal("a finished tournament must stay locked")
	}
	if err := tbl.Restart(); err != nil {
		t.Fatalf("Restart: %v", err)
	}

	// The new tournament starts at the level the host configured, not where
	// the schedule had climbed to — and those settings are editable again.
	tbl.call(func() {
		if tbl.settings.SmallBlind != 25 || tbl.settings.BigBlind != 50 {
			t.Errorf("blinds %d/%d, want 25/50", tbl.settings.SmallBlind, tbl.settings.BigBlind)
		}
		if tbl.blindsUpAt != 0 || tbl.blindsPausedMs != 0 {
			t.Errorf("blind clock still armed: %d/%d", tbl.blindsUpAt, tbl.blindsPausedMs)
		}
		if tbl.tournamentLocked() {
			t.Error("a new round must unlock the tournament until its first deal")
		}
	})
	// Seats move again between rounds (the same lock).
	if err := tbl.ChangeSeat(alice.PlayerID, 3); err != nil {
		t.Fatalf("seat change between rounds: %v", err)
	}

	// Once the new round deals, everything is locked again.
	if err := tbl.Start(); err != nil {
		t.Fatalf("Start: %v", err)
	}
	waitFor(t, "the first hand of the new round", func() bool {
		var locked bool
		tbl.call(func() { locked = tbl.tournamentLocked() })
		return locked
	})
	if err := tbl.ChangeSeat(alice.PlayerID, 5); !errors.Is(err, ErrTournamentLocked) {
		t.Fatalf("seat change during the round: %v", err)
	}
}
