package table

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	"showdown/internal/poker"
	"showdown/internal/protocol"
)

func TestVoicePresenceAndRelay(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, connB := join(t, tbl, "Bob")
	if err := tbl.SetVoice(a.PlayerID, "loud", false); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("bad state: %v", err)
	}
	if err := tbl.SetVoice(a.PlayerID, VoiceOn, false); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "voice in snapshot", func() bool {
		for _, sv := range connB.lastSnapshot(t).Seats {
			if sv.Player != nil && sv.Player.ID == a.PlayerID && sv.Player.Voice == VoiceOn {
				return true
			}
		}
		return false
	})
	var clientA *Client
	tbl.call(func() { clientA = tbl.playerClients[a.PlayerID] })
	if err := tbl.RelayVoice(clientA, b.PlayerID, protocol.VoiceSignal{Kind: "offer", Data: "sdp"}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "signal delivered", func() bool {
		for _, env := range connB.all() {
			if env.Type == protocol.TypeVoiceSignal {
				var sig protocol.VoiceSignal
				_ = json.Unmarshal(env.Payload, &sig)
				return sig.From == a.PlayerID && sig.To == "" && sig.Kind == "offer" && sig.Data == "sdp"
			}
		}
		return false
	})
	for _, env := range connA.all() {
		if env.Type == protocol.TypeVoiceSignal {
			t.Fatal("the sender must not receive its own signal")
		}
	}
	if err := tbl.RelayVoice(clientA, "nobody", protocol.VoiceSignal{Kind: "ice", Data: "x"}); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("unknown target: %v", err)
	}
	// Dropping the connection switches the presence off.
	tbl.Detach(clientA)
	waitFor(t, "voice off after detach", func() bool {
		for _, sv := range connB.lastSnapshot(t).Seats {
			if sv.Player != nil && sv.Player.ID == a.PlayerID {
				return sv.Player.Voice == VoiceOff
			}
		}
		return false
	})
}

func TestLateRevealExtendsTheResultPhase(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, _ := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	actor, _ := toAct(tbl)
	if err := tbl.Action(actor, poker.Action{Kind: poker.Fold}); err != nil {
		t.Fatal(err)
	}
	winner := a.PlayerID
	if actor == winner {
		winner = b.PlayerID
	}
	// Reveal late in the result phase: the next deal is pushed back by the
	// configured extension, measured from the reveal.
	time.Sleep(1500 * time.Millisecond)
	if err := tbl.ShowCards(winner, "both"); err != nil {
		t.Fatal(err)
	}
	ends := phaseEnd(tbl)
	if ends < tbl.nowMs()+testDelays.ResultExtension.Milliseconds()-20 {
		t.Fatalf("the reveal must extend the result phase, got end in %d ms", ends-tbl.nowMs())
	}
	if handNumber(tbl) != 1 || handRunning(tbl) {
		t.Fatal("the reveal must keep the finished hand on screen")
	}
	waitFor(t, "next hand", func() bool { return handNumber(tbl) >= 2 })
}

// phaseEnd reads phase_ends_ts through the actor.
func phaseEnd(tbl *Table) int64 {
	var v int64
	tbl.call(func() { v = tbl.phaseEndsAt })
	return v
}

func TestHostMutesMicrophoneButCannotUnmute(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	a, connA := join(t, tbl, "Alice")
	_, connB := join(t, tbl, "Bob")
	if err := tbl.MuteVoice(a.PlayerID); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("muting a player without voice: %v", err)
	}
	if err := tbl.SetVoice(a.PlayerID, VoiceOn, false); err != nil {
		t.Fatal(err)
	}
	if err := tbl.MuteVoice(a.PlayerID); err != nil {
		t.Fatal(err)
	}
	voiceOf := func(conn *fakeConn) string {
		for _, sv := range conn.lastSnapshot(t).Seats {
			if sv.Player != nil && sv.Player.ID == a.PlayerID {
				return sv.Player.Voice
			}
		}
		return ""
	}
	waitFor(t, "muted", func() bool { return voiceOf(connB) == VoiceMuted && voiceOf(connA) == VoiceMuted })
	if err := tbl.MuteVoice(a.PlayerID); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("muting twice: %v", err)
	}
	// The player unmutes themselves; the host has no unmute.
	if err := tbl.SetVoice(a.PlayerID, VoiceOn, false); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "unmuted", func() bool { return voiceOf(connB) == VoiceOn })
}

func TestQuickPhrasesBroadcastAndRateLimit(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	a, connA := join(t, tbl, "Alice")
	b, connB := join(t, tbl, "Bob")
	alice := &Client{Conn: connA, Role: RolePlayer, PlayerID: a.PlayerID}
	if err := tbl.Say(alice, "nice_call"); err != nil {
		t.Fatal(err)
	}
	phrases := func(conn *fakeConn) []protocol.PhrasePayload {
		var out []protocol.PhrasePayload
		for _, m := range conn.all() {
			if m.Type == protocol.TypePhrase {
				var p protocol.PhrasePayload
				if err := json.Unmarshal(m.Payload, &p); err != nil {
					t.Fatal(err)
				}
				out = append(out, p)
			}
		}
		return out
	}
	waitFor(t, "phrase", func() bool { return len(phrases(connB)) == 1 && len(phrases(connA)) == 1 })
	if p := phrases(connB)[0]; p.Seat != a.Seat || p.Name != "Alice" || p.Phrase != "nice_call" || p.TS == 0 {
		t.Fatalf("phrase = %+v", p)
	}
	if err := tbl.Say(alice, "gg"); !errors.Is(err, ErrRateLimited) {
		t.Fatalf("second phrase within 3 s: %v", err)
	}
	if err := tbl.Say(&Client{Conn: connB, Role: RolePlayer, PlayerID: b.PlayerID}, "shout"); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("unknown phrase: %v", err)
	}
	if err := tbl.Say(&Client{Conn: connB, Role: RoleSpectator, Name: "Eve"}, "gg"); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("spectator phrase: %v", err)
	}
	if err := tbl.Mute(b.PlayerID, true); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Say(&Client{Conn: connB, Role: RolePlayer, PlayerID: b.PlayerID}, "gg"); !errors.Is(err, ErrMuted) {
		t.Fatalf("muted phrase: %v", err)
	}
}

func TestStagedShowdownRevealsOneHandAtATime(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.ShowdownReveal = RevealInOrder
	tbl := newTestTable(t, s)
	_, connA := join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	// Check or call down to the river.
	deadline := time.Now().Add(5 * time.Second)
	for handNumber(tbl) == 1 && handRunning(tbl) {
		if time.Now().After(deadline) {
			t.Fatal("hand did not reach the showdown")
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
	waitFor(t, "result", func() bool {
		var done bool
		tbl.call(func() { done = tbl.hand != nil && tbl.hand.Done() })
		return done
	})
	var sawShowdown bool
	reveals, mucks := 0, 0
	for _, m := range connA.all() {
		switch m.Type {
		case protocol.TypeSnapshot:
			var snap protocol.Snapshot
			if err := json.Unmarshal(m.Payload, &snap); err != nil {
				t.Fatal(err)
			}
			if snap.Hand != nil && snap.Hand.Phase == "showdown" && snap.Hand.PhaseEndsTS > 0 {
				sawShowdown = true
			}
		case protocol.TypeEvents:
			var ev protocol.EventsPayload
			if err := json.Unmarshal(m.Payload, &ev); err != nil {
				t.Fatal(err)
			}
			for _, e := range ev.Events {
				switch e.Kind {
				case "hands_revealed":
					if len(e.Reveals) != 1 {
						t.Fatalf("staged reveals show one hand at a time, got %d", len(e.Reveals))
					}
					reveals++
				case "mucked":
					if e.Name == "" {
						t.Fatalf("mucked event without a name: %+v", e)
					}
					mucks++
				}
			}
		}
	}
	if !sawShowdown || reveals+mucks != 2 || reveals < 1 {
		t.Fatalf("showdown %v, reveals %d, mucks %d", sawShowdown, reveals, mucks)
	}
}
