package table

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	"showdown/internal/poker"
	"showdown/internal/protocol"
)

// playDown checks or calls for whoever is on turn until the hand is over.
func playDown(t *testing.T, tbl *Table) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for handRunning(tbl) {
		if time.Now().After(deadline) {
			t.Fatal("hand did not finish")
		}
		id, _ := toAct(tbl)
		if id == "" {
			time.Sleep(5 * time.Millisecond)
			continue
		}
		if err := tbl.Action(id, poker.Action{Kind: poker.Check}); err != nil {
			if err := tbl.Action(id, poker.Action{Kind: poker.Call}); err != nil {
				t.Fatal(err)
			}
		}
	}
}

func TestTimeBankExtendsTheTurnOnce(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.TimeBankSeconds = 2
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	actor, _ := toAct(tbl)
	// Nobody acts: after turn_time (1 s) the actor's bank (2 s) kicks in
	// instead of the fold; the snapshot shows the extension.
	waitFor(t, "time bank active", func() bool {
		snap := connA.lastSnapshot(t)
		return snap.Hand != nil && snap.Hand.TimeBankActive
	})
	if id, _ := toAct(tbl); id != actor {
		t.Fatalf("turn moved during the extension: %s vs %s", id, actor)
	}
	// Acting inside the extension refunds what is left.
	if err := tbl.Action(actor, poker.Action{Kind: poker.Call}); err != nil {
		if err := tbl.Action(actor, poker.Action{Kind: poker.Check}); err != nil {
			t.Fatal(err)
		}
	}
	var bank int
	tbl.call(func() { bank = tbl.players[actor].TimeBank })
	if bank < 0 || bank > 2 {
		t.Fatalf("bank after refund = %d", bank)
	}
	// The other player lets both the clock and the bank run out: fold/check,
	// bank empty.
	other := a.PlayerID
	if actor == a.PlayerID {
		for id := range tbl.players {
			if id != actor {
				other = id
			}
		}
	}
	waitFor(t, "other on turn", func() bool { id, _ := toAct(tbl); return id == other })
	waitFor(t, "bank spent", func() bool {
		var b int
		tbl.call(func() { b = tbl.players[other].TimeBank })
		id, _ := toAct(tbl)
		return b == 0 && id != other
	})
}

func TestStraddleIsPostedBySeatLeftOfTheBigBlind(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AllowStraddle = true
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	// Three players join before the first deal: auto start needs two, so the
	// third joins into the pause and is dealt in from hand 1 only if quick.
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	c, _ := join(t, tbl, "Carol")
	for _, id := range []string{a.PlayerID, b.PlayerID, c.PlayerID} {
		if err := tbl.SetStraddle(id, true); err != nil {
			t.Fatal(err)
		}
	}
	waitFor(t, "straddle in snapshot", func() bool { return connA.lastSnapshot(t).You.Straddle })
	waitFor(t, "hand with three players", func() bool {
		if !handRunning(tbl) {
			return false
		}
		snap := connA.lastSnapshot(t)
		n := 0
		for _, sv := range snap.Seats {
			if sv.Player != nil && sv.Player.InHand {
				n++
			}
		}
		return n == 3 && snap.Hand != nil && snap.Hand.StraddleSeat != nil
	})
	snap := connA.lastSnapshot(t)
	if snap.Hand.CurrentBet != 2*s.BigBlind {
		t.Fatalf("current bet %d, want the straddle %d", snap.Hand.CurrentBet, 2*s.BigBlind)
	}
	var straddled bool
	for _, m := range connA.all() {
		if m.Type != protocol.TypeEvents {
			continue
		}
		var ev protocol.EventsPayload
		if err := json.Unmarshal(m.Payload, &ev); err != nil {
			t.Fatal(err)
		}
		for _, e := range ev.Events {
			if e.Kind == "blind_posted" && e.Blind == "straddle" && e.Amount != nil && *e.Amount == 2*s.BigBlind {
				straddled = true
			}
		}
	}
	if !straddled {
		t.Fatal("no straddle event")
	}
	s2 := testSettings()
	tbl2 := newTestTable(t, s2)
	d, _ := join(t, tbl2, "Dan")
	if err := tbl2.SetStraddle(d.PlayerID, true); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("straddle without the setting: %v", err)
	}
}

func TestRunItTwiceVoteDealsTwoBoards(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.RunItTwice = true
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	// Both all-in preflop -> run-out with cards to come -> vote.
	actor, _ := toAct(tbl)
	if err := tbl.Action(actor, poker.Action{Kind: poker.AllIn}); err != nil {
		t.Fatal(err)
	}
	other := a.PlayerID
	if actor == a.PlayerID {
		other = b.PlayerID
	}
	waitFor(t, "other on turn", func() bool { id, _ := toAct(tbl); return id == other })
	if err := tbl.Action(other, poker.Action{Kind: poker.Call}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "vote open", func() bool {
		snap := connA.lastSnapshot(t)
		return snap.Hand != nil && snap.Hand.RunTwiceEndsTS > 0 && snap.You.CanRunTwice
	})
	// Equity is shown during the run-out.
	snap := connA.lastSnapshot(t)
	seen := 0
	for _, sv := range snap.Seats {
		if sv.Player != nil && sv.Player.Equity != nil {
			seen++
		}
	}
	if seen != 2 {
		t.Fatalf("equity on %d seats", seen)
	}
	if err := tbl.RunTwice(a.PlayerID, true); err != nil {
		t.Fatal(err)
	}
	if err := tbl.RunTwice(a.PlayerID, true); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("double vote: %v", err)
	}
	waitFor(t, "vote recorded", func() bool {
		v := connA.lastSnapshot(t).You.RunTwiceVote
		return v != nil && *v
	})
	if err := tbl.RunTwice(b.PlayerID, true); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "two boards", func() bool {
		snap := connA.lastSnapshot(t)
		return snap.Hand != nil && snap.Hand.RunTwice && len(snap.Hand.Board2) == 5 && len(snap.Hand.Board) == 5
	})
	waitFor(t, "hand over", func() bool {
		var done bool
		tbl.call(func() { done = tbl.hand != nil && tbl.hand.Done() })
		return done
	})
	// Every pot_awarded carries a board and both boards paid something.
	boards := map[int]int64{}
	for _, m := range connA.all() {
		if m.Type != protocol.TypeEvents {
			continue
		}
		var ev protocol.EventsPayload
		if err := json.Unmarshal(m.Payload, &ev); err != nil {
			t.Fatal(err)
		}
		for _, e := range ev.Events {
			if e.Kind == "pot_awarded" && e.Amount != nil {
				boards[e.Board] += *e.Amount
			}
		}
	}
	if boards[1] == 0 || boards[2] == 0 || boards[0] != 0 {
		t.Fatalf("awards per board = %v", boards)
	}
	var total int64
	tbl.call(func() {
		for _, p := range tbl.players {
			total += p.Stack
		}
	})
	if total != 2*s.StartMoney {
		t.Fatalf("chips %d", total)
	}
}

func TestRunItTwiceRefusedRunsOnce(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.RunItTwice = true
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	actor, _ := toAct(tbl)
	if err := tbl.Action(actor, poker.Action{Kind: poker.AllIn}); err != nil {
		t.Fatal(err)
	}
	other := a.PlayerID
	if actor == a.PlayerID {
		other = b.PlayerID
	}
	waitFor(t, "other on turn", func() bool { id, _ := toAct(tbl); return id == other })
	if err := tbl.Action(other, poker.Action{Kind: poker.Call}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "vote open", func() bool {
		snap := connA.lastSnapshot(t)
		return snap.Hand != nil && snap.Hand.RunTwiceEndsTS > 0
	})
	if err := tbl.RunTwice(a.PlayerID, false); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "hand over", func() bool {
		var done bool
		tbl.call(func() { done = tbl.hand != nil && tbl.hand.Done() })
		return done
	})
	if snap := connA.lastSnapshot(t); snap.Hand.RunTwice || len(snap.Hand.Board2) != 0 {
		t.Fatalf("board2 = %v", snap.Hand.Board2)
	}
}

func TestPlacementsAndTournamentEnd(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AllowRebuy = false
	s.StartMoney = 200
	tbl := newTestTableShuffled(t, s, poker.SecureShuffle)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	// Shove every hand until one player has everything.
	deadline := time.Now().Add(10 * time.Second)
	for {
		var state string
		tbl.call(func() { state = tbl.state })
		if state == StateEnded {
			break
		}
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
	var places []int
	tbl.call(func() {
		for _, id := range []string{a.PlayerID, b.PlayerID} {
			places = append(places, tbl.players[id].Place)
		}
	})
	first, second := places[0] == 1 && places[1] == 2, places[0] == 2 && places[1] == 1
	if !first && !second {
		t.Fatalf("places = %v", places)
	}
	var ended protocol.TableEnded
	found := false
	for _, m := range connA.all() {
		if m.Type == protocol.TypeTableEnded {
			if err := json.Unmarshal(m.Payload, &ended); err != nil {
				t.Fatal(err)
			}
			found = true
		}
	}
	if !found || len(ended.FinalLeaderboard) != 2 || ended.FinalLeaderboard[0].Place != 1 || ended.FinalLeaderboard[1].Place != 2 {
		t.Fatalf("final standings = %+v (found %v)", ended.FinalLeaderboard, found)
	}
	if ended.FinalLeaderboard[0].HandsPlayed == 0 || ended.FinalLeaderboard[0].Showdowns == 0 {
		t.Fatalf("statistics missing: %+v", ended.FinalLeaderboard[0])
	}
}

func TestStatisticsCountVPIPAndShowdowns(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	playDown(t, tbl) // heads-up: the small blind calls (VPIP), the big blind checks
	var lb []protocol.LeaderboardEntry
	waitFor(t, "stats", func() bool {
		lb = connA.lastSnapshot(t).Leaderboard
		return len(lb) == 2 && lb[0].Showdowns == 1 && lb[1].Showdowns == 1
	})
	vpip := lb[0].VPIPHands + lb[1].VPIPHands
	if vpip != 1 || lb[0].ShowdownsWon+lb[1].ShowdownsWon < 1 || lb[0].HandsPlayed != 1 {
		t.Fatalf("stats = %+v", lb)
	}
	_ = a
}

func TestHostTurnsTheCameraOff(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	a, connA := join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	if err := tbl.CameraOff(a.PlayerID); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("camera already off: %v", err)
	}
	if err := tbl.SetVoice(a.PlayerID, VoiceOn, true); err != nil {
		t.Fatal(err)
	}
	cam := func() bool {
		for _, sv := range connA.lastSnapshot(t).Seats {
			if sv.Player != nil && sv.Player.ID == a.PlayerID {
				return sv.Player.Camera
			}
		}
		return false
	}
	waitFor(t, "camera on", cam)
	if err := tbl.CameraOff(a.PlayerID); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "camera off", func() bool { return !cam() })
	// Voice off drops the camera too.
	if err := tbl.SetVoice(a.PlayerID, VoiceOn, true); err != nil {
		t.Fatal(err)
	}
	if err := tbl.SetVoice(a.PlayerID, VoiceOff, true); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "camera off with voice", func() bool { return !cam() })
}
