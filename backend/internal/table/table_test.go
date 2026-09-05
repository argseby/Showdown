package table

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"sync"
	"testing"
	"time"

	"showdown/internal/poker"
	"showdown/internal/protocol"
	"showdown/internal/store"
)

// fakeConn records everything the table sends.
type fakeConn struct {
	mu     sync.Mutex
	msgs   []protocol.Envelope
	closed bool
	code   int
	reason string
}

func (f *fakeConn) Send(env protocol.Envelope) bool {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.closed {
		return false
	}
	f.msgs = append(f.msgs, env)
	return true
}

func (f *fakeConn) Close(code int, reason string) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.closed, f.code, f.reason = true, code, reason
}

func (f *fakeConn) all() []protocol.Envelope {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]protocol.Envelope{}, f.msgs...)
}

func (f *fakeConn) isClosed() (bool, int) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.closed, f.code
}

// lastSnapshot returns the most recent snapshot the connection received.
func (f *fakeConn) lastSnapshot(t *testing.T) protocol.Snapshot {
	t.Helper()
	msgs := f.all()
	for i := len(msgs) - 1; i >= 0; i-- {
		switch msgs[i].Type {
		case protocol.TypeSnapshot:
			var s protocol.Snapshot
			if err := json.Unmarshal(msgs[i].Payload, &s); err != nil {
				t.Fatal(err)
			}
			return s
		case protocol.TypeWelcome:
			var w protocol.Welcome
			if err := json.Unmarshal(msgs[i].Payload, &w); err != nil {
				t.Fatal(err)
			}
			return w.Snapshot
		}
	}
	t.Fatal("no snapshot received")
	return protocol.Snapshot{}
}

func (f *fakeConn) events(t *testing.T) []protocol.Event {
	t.Helper()
	var out []protocol.Event
	for _, m := range f.all() {
		if m.Type == protocol.TypeEvents {
			var p protocol.EventsPayload
			if err := json.Unmarshal(m.Payload, &p); err != nil {
				t.Fatal(err)
			}
			out = append(out, p.Events...)
		}
	}
	return out
}

func (f *fakeConn) count(typ string) int {
	n := 0
	for _, m := range f.all() {
		if m.Type == typ {
			n++
		}
	}
	return n
}

var testDelays = Delays{Street: 5 * time.Millisecond, Runout: 5 * time.Millisecond, Showdown: 5 * time.Millisecond, ShowdownPerHand: time.Millisecond, ResultExtension: 50 * time.Millisecond}

func testSettings() Settings {
	s := DefaultSettings()
	s.TurnTime = 1
	s.DisconnectedTurnTime = 1
	s.HandDelayMs = 30
	s.SitOutAfterMissedTurns = 1
	return s
}

func newTestTable(t *testing.T, s Settings) *Table {
	t.Helper()
	deps := Deps{Log: slog.New(slog.DiscardHandler), Delays: testDelays,
		Shuffle: func([]poker.Card) {}, RandIntn: func(int) int { return 0 }}
	tbl := newTable(NewTableID(), deps)
	tbl.name = "Test"
	tbl.state = StateWaiting
	tbl.createdAt = tbl.nowMs()
	tbl.settings = s
	go tbl.run()
	t.Cleanup(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		tbl.Stop(ctx, 1001, "test over")
	})
	return tbl
}

func join(t *testing.T, tbl *Table, name string) (JoinResult, *fakeConn) {
	t.Helper()
	res, err := tbl.Join(name, -1, -1)
	if err != nil {
		t.Fatalf("Join(%s): %v", name, err)
	}
	conn := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: conn, Role: RolePlayer, PlayerID: res.PlayerID}); err != nil {
		t.Fatalf("Attach(%s): %v", name, err)
	}
	return res, conn
}

func waitFor(t *testing.T, what string, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		if cond() {
			return
		}
		time.Sleep(5 * time.Millisecond)
	}
	t.Fatalf("timed out waiting for %s", what)
}

// toAct returns the player id and seat whose turn it is, or "" when nobody's.
func toAct(tbl *Table) (string, int) {
	var id string
	seat := -1
	tbl.call(func() {
		if tbl.hand == nil || tbl.hand.Done() {
			return
		}
		if s, ok := tbl.hand.ToAct(); ok {
			seat = s
			if p := tbl.seats[s]; p != nil {
				id = p.ID
			}
		}
	})
	return id, seat
}

func handRunning(tbl *Table) bool {
	var running bool
	tbl.call(func() { running = tbl.handInProgress() })
	return running
}

func handNumber(tbl *Table) int {
	var n int
	tbl.call(func() { n = tbl.handNumber })
	return n
}

func TestJoinAutoStartAndHoleCardPrivacy(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	a, ca := join(t, tbl, "Alice")
	b, cb := join(t, tbl, "Bob")
	_, cc := join(t, tbl, "Carol")
	if a.Seat != 0 || b.Seat != 1 {
		t.Fatalf("seats %d %d", a.Seat, b.Seat)
	}
	if _, err := tbl.Spectate("Watcher"); err != nil {
		t.Fatal(err)
	}
	spec := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: spec, Role: RoleSpectator, Name: "Watcher"}); err != nil {
		t.Fatal(err)
	}
	admin := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: admin, Role: RoleAdmin, Name: "admin"}); err != nil {
		t.Fatal(err)
	}
	if _, err := tbl.Join("alice", -1, -1); !errors.Is(err, ErrNameTaken) {
		t.Fatalf("duplicate name: %v", err)
	}
	if _, err := tbl.Join("Watcher", -1, -1); !errors.Is(err, ErrNameTaken) {
		t.Fatalf("spectator name reuse: %v", err)
	}
	if _, err := tbl.Join("bad!name", -1, -1); !errors.Is(err, ErrInvalidName) {
		t.Fatalf("invalid name: %v", err)
	}

	waitFor(t, "hand to start", func() bool { return handRunning(tbl) })
	if tbl.State() != StateRunning {
		t.Fatalf("state %s", tbl.State())
	}
	snap := ca.lastSnapshot(t)
	if snap.Hand == nil || snap.Hand.Street != "preflop" || snap.Table.HandNumber != 1 || snap.Spectators != 1 {
		t.Fatalf("snapshot = %+v", snap)
	}
	for _, sv := range snap.Seats {
		if sv.Player == nil {
			continue
		}
		if sv.Seat == 0 && len(sv.Player.HoleCards) != 2 {
			t.Fatalf("own cards missing: %+v", sv.Player)
		}
		if sv.Seat != 0 && sv.Player.HoleCards != nil {
			t.Fatalf("leaked cards of seat %d to Alice", sv.Seat)
		}
	}
	for name, conn := range map[string]*fakeConn{"spectator": spec, "admin": admin} {
		s := conn.lastSnapshot(t)
		if s.You.Role != name {
			t.Fatalf("%s role = %s", name, s.You.Role)
		}
		for _, sv := range s.Seats {
			if sv.Player != nil && sv.Player.HoleCards != nil {
				t.Fatalf("%s received hole cards", name)
			}
		}
		for _, e := range conn.events(t) {
			if e.Kind == "hole_cards_dealt" && e.Cards != nil {
				t.Fatalf("%s received hole cards in events", name)
			}
		}
	}
	for _, e := range cb.events(t) {
		if e.Kind == "hole_cards_dealt" && e.Seat != nil && *e.Seat != 1 && e.Cards != nil {
			t.Fatal("Bob received someone else's cards")
		}
	}
	_ = cc

	// Whoever is to act may act; others may not.
	actor, seat := toAct(tbl)
	if actor == "" {
		t.Fatal("nobody to act")
	}
	other := a.PlayerID
	if other == actor {
		other = b.PlayerID
	}
	if err := tbl.Action(other, poker.Action{Kind: poker.Fold}); !errors.Is(err, poker.ErrNotYourTurn) {
		t.Fatalf("out of turn: %v", err)
	}
	if err := tbl.Action(actor, poker.Action{Kind: poker.Check}); !errors.Is(err, poker.ErrIllegalAction) {
		t.Fatalf("check facing blind: %v", err)
	}
	if err := tbl.Action(actor, poker.Action{Kind: poker.Fold}); err != nil {
		t.Fatalf("fold: %v", err)
	}
	if next, _ := toAct(tbl); next == actor || next == "" {
		t.Fatalf("turn did not pass (seat %d)", seat)
	}
	snap = ca.lastSnapshot(t)
	if snap.Hand.ToActSeat == nil || snap.Hand.DeadlineTS == nil {
		t.Fatalf("hand view = %+v", snap.Hand)
	}
}

func TestTimeoutsSitOutAndHandsContinue(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand 1", func() bool { return handNumber(tbl) >= 1 && handRunning(tbl) })
	// Nobody acts: turns time out (1 s), the hand ends, players sit out after one missed turn.
	waitFor(t, "hand 1 to end", func() bool { return !handRunning(tbl) })
	var statuses []string
	tbl.call(func() {
		for _, p := range tbl.seats[:2] {
			statuses = append(statuses, p.Status)
		}
	})
	sittingOut := 0
	for _, s := range statuses {
		if s == StatusSittingOut {
			sittingOut++
		}
	}
	if sittingOut == 0 {
		t.Fatalf("expected sit-outs after missed turns, statuses %v", statuses)
	}
	// No new hand starts while fewer than two players are eligible.
	time.Sleep(100 * time.Millisecond)
	if handNumber(tbl) != 1 {
		t.Fatalf("hand number %d", handNumber(tbl))
	}
}

func playToEnd(t *testing.T, tbl *Table) {
	t.Helper()
	waitFor(t, "hand to end", func() bool {
		if !handRunning(tbl) {
			return true
		}
		if id, _ := toAct(tbl); id != "" {
			_ = tbl.Action(id, poker.Action{Kind: poker.Fold})
		}
		return false
	})
}

func TestLeaveKickRebuyAndChips(t *testing.T) {
	t.Parallel()
	s := testSettings()
	tbl := newTestTable(t, s)
	a, ca := join(t, tbl, "Alice")
	b, cb := join(t, tbl, "Bob")
	c, cc := join(t, tbl, "Carol")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })

	// Leaving mid-hand folds immediately; the seat is freed when the hand ends.
	if err := tbl.Leave(c.PlayerID); err != nil {
		t.Fatal(err)
	}
	if !tbl.HasPlayer(c.PlayerID) && handRunning(tbl) {
		t.Fatal("seat freed too early")
	}
	// Chip adjustments are queued during the hand.
	if applied, err := tbl.AdjustChips(a.PlayerID, 500, "bonus"); err != nil || applied {
		t.Fatalf("queued adjust: applied=%v err=%v", applied, err)
	}
	if _, err := tbl.AdjustChips(a.PlayerID, 0, ""); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("zero delta: %v", err)
	}
	playToEnd(t, tbl)
	waitFor(t, "carol gone", func() bool { return !tbl.HasPlayer(c.PlayerID) })
	if closed, _ := cc.isClosed(); closed {
		t.Fatal("a voluntary leaver's socket is closed by the transport, not the table")
	}
	if d := tbl.AdminDetail(); d.Connections != 2 {
		t.Fatalf("connections after leave = %d, want 2", d.Connections)
	}
	waitFor(t, "chips applied", func() bool {
		var buyIn int64
		tbl.call(func() {
			if p := tbl.players[a.PlayerID]; p != nil {
				buyIn = p.BuyInTotal
			}
		})
		return buyIn == s.StartMoney+500
	})
	found := false
	for _, e := range ca.events(t) {
		if e.Kind == "chips_adjusted" && e.Delta != nil && *e.Delta == 500 {
			found = true
		}
	}
	if !found {
		t.Fatal("chips_adjusted event missing")
	}

	// Kick between hands (or during: either way Bob ends up gone with 4005).
	if err := tbl.Kick(b.PlayerID); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "bob gone", func() bool { return !tbl.HasPlayer(b.PlayerID) })
	waitFor(t, "bob closed", func() bool { closed, _ := cb.isClosed(); return closed })
	if _, code := cb.isClosed(); code != protocol.CloseKicked || cb.count(protocol.TypeKicked) != 1 {
		t.Fatalf("kick close code %d, kicked msgs %d", code, cb.count(protocol.TypeKicked))
	}
	if err := tbl.Kick(b.PlayerID); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("kick twice: %v", err)
	}

	// Rebuy only for busted players.
	if err := tbl.Rebuy(a.PlayerID); !errors.Is(err, ErrRebuyNotAllowed) {
		t.Fatalf("rebuy while active: %v", err)
	}
	tbl.call(func() {
		p := tbl.players[a.PlayerID]
		p.Stack = 0
		p.Status = StatusBusted
	})
	if err := tbl.Rebuy(a.PlayerID); err != nil {
		t.Fatalf("rebuy: %v", err)
	}
	snap := ca.lastSnapshot(t)
	var alice *protocol.PlayerView
	for _, sv := range snap.Seats {
		if sv.Player != nil && sv.Player.ID == a.PlayerID {
			alice = sv.Player
		}
	}
	if alice == nil || alice.Stack != s.StartMoney || alice.Status != StatusActive {
		t.Fatalf("alice after rebuy = %+v", alice)
	}
	if err := tbl.Mute(a.PlayerID, true); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(&Client{Role: RolePlayer, PlayerID: a.PlayerID}, "hi"); !errors.Is(err, ErrMuted) {
		t.Fatalf("muted chat: %v", err)
	}
}

func TestSitOutSitIn(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, _ := join(t, tbl, "Alice")
	if err := tbl.SitOut(a.PlayerID); err != nil {
		t.Fatal(err)
	}
	if err := tbl.SitOut(a.PlayerID); !errors.Is(err, ErrInvalidState) {
		t.Fatalf("sit out twice: %v", err)
	}
	if err := tbl.SitIn(a.PlayerID); err != nil {
		t.Fatal(err)
	}
	if err := tbl.SitIn(a.PlayerID); !errors.Is(err, ErrInvalidState) {
		t.Fatalf("sit in twice: %v", err)
	}
	if err := tbl.SitOut("nobody"); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("unknown player: %v", err)
	}
}

func TestLifecycleAndVoid(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, ca := join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	spec := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: spec, Role: RoleSpectator, Name: "W"}); err != nil {
		t.Fatal(err)
	}
	time.Sleep(60 * time.Millisecond)
	if handRunning(tbl) || tbl.State() != StateWaiting {
		t.Fatal("must not start without auto_start")
	}
	if err := tbl.Pause(); !errors.Is(err, ErrInvalidState) {
		t.Fatalf("pause while waiting: %v", err)
	}
	if err := tbl.Start(); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Start(); !errors.Is(err, ErrInvalidState) {
		t.Fatalf("start twice: %v", err)
	}
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	if err := tbl.Pause(); err != nil {
		t.Fatal(err)
	}
	if tbl.State() != StatePaused {
		t.Fatal("state")
	}
	playToEnd(t, tbl)
	time.Sleep(80 * time.Millisecond)
	if handNumber(tbl) != 1 {
		t.Fatalf("paused table dealt hand %d", handNumber(tbl))
	}
	if err := tbl.Resume(); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "hand 2", func() bool { return handNumber(tbl) == 2 && handRunning(tbl) })

	// End now: the running hand is voided and stacks restored.
	var before map[int]int64
	tbl.call(func() { before = tbl.handStartStacks })
	if err := tbl.End(true); err != nil {
		t.Fatal(err)
	}
	if tbl.State() != StateEnded {
		t.Fatal("not ended")
	}
	var stacks map[int]int64
	tbl.call(func() {
		stacks = map[int]int64{}
		for seat, p := range tbl.seats {
			if p != nil {
				stacks[seat] = p.Stack
			}
		}
	})
	for seat, st := range before {
		if stacks[seat] != st {
			t.Fatalf("seat %d stack %d, want %d", seat, stacks[seat], st)
		}
	}
	waitFor(t, "clients closed", func() bool { closed, _ := ca.isClosed(); return closed })
	if _, code := ca.isClosed(); code != protocol.CloseTableGone || ca.count(protocol.TypeTableEnded) != 1 {
		t.Fatalf("close code %d, table_ended msgs %d", code, ca.count(protocol.TypeTableEnded))
	}
	voided := false
	for _, e := range spec.events(t) {
		if e.Kind == "hand_voided" {
			voided = true
		}
	}
	if !voided {
		t.Fatal("hand_voided event missing")
	}
	if err := tbl.End(false); !errors.Is(err, ErrInvalidState) {
		t.Fatalf("end twice: %v", err)
	}
	if _, err := tbl.Join("Zed", -1, -1); !errors.Is(err, ErrTableEnded) {
		t.Fatalf("join ended: %v", err)
	}
	if err := tbl.Attach(&Client{Conn: &fakeConn{}, Role: RolePlayer, PlayerID: a.PlayerID}); !errors.Is(err, ErrTableEnded) {
		t.Fatalf("attach ended: %v", err)
	}
}

func TestEndAfterHand(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	if err := tbl.End(false); err != nil {
		t.Fatal(err)
	}
	if tbl.State() == StateEnded {
		t.Fatal("ended before the hand finished")
	}
	playToEnd(t, tbl)
	waitFor(t, "ended", func() bool { return tbl.State() == StateEnded })
}

func TestSettingsSpectatorsAndReplace(t *testing.T) {
	t.Parallel()
	s := DefaultSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, ca := join(t, tbl, "Alice")
	spec := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: spec, Role: RoleSpectator, Name: "W"}); err != nil {
		t.Fatal(err)
	}
	if _, err := tbl.Spectate("Alice"); !errors.Is(err, ErrNameTaken) {
		t.Fatalf("spectate with player name: %v", err)
	}
	name, err := tbl.Spectate("  Watcher  Two ")
	if err != nil || name != "Watcher Two" {
		t.Fatalf("spectate = %q %v", name, err)
	}
	f := false
	changed, next, err := tbl.UpdateSettings(SettingsPatch{AllowSpectators: &f, BigBlind: ptr64(200), SmallBlind: ptr64(100)}, "")
	if err != nil || len(changed) != 3 || len(next) != 2 {
		t.Fatalf("update = %v %v %v", changed, next, err)
	}
	if closed, _ := spec.isClosed(); !closed {
		t.Fatal("spectator not disconnected")
	}
	if err := tbl.Attach(&Client{Conn: &fakeConn{}, Role: RoleSpectator, Name: "X"}); !errors.Is(err, ErrSpectatorsDisabled) {
		t.Fatalf("spectate disabled: %v", err)
	}
	if _, err := tbl.Spectate("Y"); !errors.Is(err, ErrSpectatorsDisabled) {
		t.Fatalf("spectate disabled: %v", err)
	}
	small := 1
	if _, _, err := tbl.UpdateSettings(SettingsPatch{MaxPlayers: &small}, ""); err == nil {
		t.Fatal("invalid settings accepted")
	}
	snap := ca.lastSnapshot(t)
	if snap.Table.Settings.BigBlind != 200 {
		t.Fatalf("settings not in snapshot: %+v", snap.Table.Settings)
	}

	// A second connection replaces the first.
	second := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: second, Role: RolePlayer, PlayerID: a.PlayerID}); err != nil {
		t.Fatal(err)
	}
	if closed, code := ca.isClosed(); !closed || code != protocol.CloseReplaced {
		t.Fatalf("old connection closed=%v code=%d", closed, code)
	}
	if err := tbl.Attach(&Client{Conn: &fakeConn{}, Role: RolePlayer, PlayerID: "ghost"}); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("unknown player attach: %v", err)
	}
	if err := tbl.Attach(&Client{Conn: &fakeConn{}, Role: "weird"}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("weird role: %v", err)
	}
	info := tbl.Info()
	if info.Seated != 1 || info.BigBlind != 200 || info.AllowSpectators {
		t.Fatalf("info = %+v", info)
	}
	d := tbl.AdminDetail()
	if len(d.Players) != 1 || d.Players[0].Name != "Alice" || d.Connections != 1 || d.JoinURL != "/t/"+tbl.ID {
		t.Fatalf("detail = %+v", d)
	}
	tbl.Detach(&Client{Conn: second, Role: RolePlayer, PlayerID: a.PlayerID}) // not the registered pointer: no-op
	if d := tbl.AdminDetail(); d.Connections != 1 {
		t.Fatal("detach of unknown client changed state")
	}
}

func ptr64(v int64) *int64 { return &v }

func TestChat(t *testing.T) {
	t.Parallel()
	s := DefaultSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, ca := join(t, tbl, "Alice")
	specConn := &fakeConn{}
	spec := &Client{Conn: specConn, Role: RoleSpectator, Name: "W"}
	if err := tbl.Attach(spec); err != nil {
		t.Fatal(err)
	}
	player := &Client{Role: RolePlayer, PlayerID: a.PlayerID}
	if err := tbl.Chat(player, "  hello \x00 world  "); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(player, "   "); !errors.Is(err, ErrInvalidText) {
		t.Fatalf("empty chat: %v", err)
	}
	if err := tbl.Chat(spec, "watching"); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(&Client{Role: RoleAdmin, Name: "admin"}, "hi all"); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(&Client{Role: RolePlayer, PlayerID: "ghost"}, "x"); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("ghost chat: %v", err)
	}
	waitFor(t, "chat delivered", func() bool { return ca.count(protocol.TypeChat) == 3 })
	var msgs []protocol.ChatMessage
	for _, m := range ca.all() {
		if m.Type == protocol.TypeChat {
			var cm protocol.ChatMessage
			_ = json.Unmarshal(m.Payload, &cm)
			msgs = append(msgs, cm)
		}
	}
	if msgs[0].Text != "hello  world" || msgs[0].AuthorKind != "player" || msgs[1].AuthorKind != "spectator" || msgs[2].AuthorKind != "admin" {
		t.Fatalf("msgs = %+v", msgs)
	}
	if err := tbl.RemoveChat(msgs[1].ID); err != nil {
		t.Fatal(err)
	}
	if err := tbl.RemoveChat(999); !errors.Is(err, ErrNotFound) {
		t.Fatalf("remove missing: %v", err)
	}
	waitFor(t, "removal broadcast", func() bool { return ca.count(protocol.TypeChatRemoved) == 1 })

	// New connections get the remaining history.
	late := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: late, Role: RoleSpectator, Name: "Late"}); err != nil {
		t.Fatal(err)
	}
	var hist protocol.ChatHistory
	for _, m := range late.all() {
		if m.Type == protocol.TypeChatHistory {
			_ = json.Unmarshal(m.Payload, &hist)
		}
	}
	if len(hist.Messages) != 2 {
		t.Fatalf("history = %+v", hist.Messages)
	}

	f := false
	if _, _, err := tbl.UpdateSettings(SettingsPatch{SpectatorChat: &f}, ""); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(spec, "x"); !errors.Is(err, ErrChatDisabled) {
		t.Fatalf("spectator chat off: %v", err)
	}
	if _, _, err := tbl.UpdateSettings(SettingsPatch{ChatEnabled: &f}, ""); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(player, "x"); !errors.Is(err, ErrChatDisabled) {
		t.Fatalf("chat off: %v", err)
	}
}

func TestShowCardsAfterUncontestedWin(t *testing.T) {
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
	if err := tbl.ShowCards(actor, "both"); !errors.Is(err, poker.ErrIllegalAction) {
		t.Fatalf("folded show: %v", err)
	}
	if err := tbl.ShowCards(winner, "both"); err != nil {
		t.Fatalf("winner show: %v", err)
	}
	if err := tbl.ShowCards(winner, "both"); !errors.Is(err, poker.ErrIllegalAction) {
		t.Fatalf("show twice: %v", err)
	}
}

func TestRegistryAndRestartRecovery(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	st, err := store.Open(ctx, t.TempDir(), slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = st.Close() })
	deps := Deps{Store: st, Log: slog.New(slog.DiscardHandler), Delays: testDelays, Shuffle: func([]poker.Card) {}}
	reg := NewRegistry(deps, 2)

	if _, err := reg.Create(ctx, "   ", DefaultSettings(), "hash"); err == nil {
		t.Fatal("empty name accepted")
	}
	bad := DefaultSettings()
	bad.BigBlind = 1
	if _, err := reg.Create(ctx, "X", bad, "hash"); err == nil {
		t.Fatal("invalid settings accepted")
	}
	s := DefaultSettings()
	s.TurnTime, s.DisconnectedTurnTime, s.HandDelayMs = 5, 3, 2000
	tbl, err := reg.Create(ctx, "  Friday   Night ", s, "hash")
	if err != nil {
		t.Fatal(err)
	}
	if tbl.Info().Name != "Friday Night" {
		t.Fatalf("name = %q", tbl.Info().Name)
	}
	if _, err := reg.Create(ctx, "Second", s, "hash"); err != nil {
		t.Fatal(err)
	}
	if _, err := reg.Create(ctx, "Third", s, "hash"); !errors.Is(err, ErrTooManyTables) {
		t.Fatalf("max tables: %v", err)
	}
	if got, ok := reg.Get(tbl.ID); !ok || got != tbl {
		t.Fatal("Get")
	}
	if len(reg.List()) != 2 {
		t.Fatal("List")
	}
	a, _ := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	if err := st.CreateSession(ctx, store.SessionRow{TokenHash: "h", Kind: RoleSpectator, TableID: tbl.ID, Name: "Watcher", CreatedAt: 1, ExpiresAt: time.Now().Add(time.Hour).UnixMilli()}); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Chat(&Client{Role: RolePlayer, PlayerID: a.PlayerID}, "before restart"); err != nil {
		t.Fatal(err)
	}
	// Start a hand explicitly (auto start waits hand_delay_ms).
	tbl.call(func() { tbl.maybeStartHand() })
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	if err := reg.Delete(ctx, tbl.ID); !errors.Is(err, ErrTableRunning) {
		t.Fatalf("delete running: %v", err)
	}
	byState, conns := reg.Stats()
	if byState[StateRunning] != 1 || byState[StateWaiting] != 1 || conns != 2 {
		t.Fatalf("stats = %v %d", byState, conns)
	}

	// Simulate a crash: shut the registry down (drains persistence) and reload.
	shutdownCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	reg.Shutdown(shutdownCtx)

	reg2 := NewRegistry(deps, 10)
	if err := reg2.LoadAll(ctx); err != nil {
		t.Fatal(err)
	}
	restored, ok := reg2.Get(tbl.ID)
	if !ok {
		t.Fatal("table not restored")
	}
	t.Cleanup(func() { reg2.Shutdown(context.Background()) })
	info := restored.Info()
	if info.Seated != 2 || info.State != StateRunning || info.HandNumber != 1 || info.Name != "Friday Night" {
		t.Fatalf("restored info = %+v", info)
	}
	if !restored.HasPlayer(a.PlayerID) || !restored.HasPlayer(b.PlayerID) {
		t.Fatal("players not restored")
	}
	var stacks []int64
	restored.call(func() {
		for _, p := range restored.seats[:2] {
			stacks = append(stacks, p.Stack)
		}
	})
	if stacks[0] != s.StartMoney || stacks[1] != s.StartMoney {
		t.Fatalf("stacks after void = %v", stacks)
	}
	if _, err := restored.Spectate("watcher"); !errors.Is(err, ErrNameTaken) {
		t.Fatalf("spectator name not restored: %v", err)
	}
	conn := &fakeConn{}
	if err := restored.Attach(&Client{Conn: conn, Role: RolePlayer, PlayerID: a.PlayerID}); err != nil {
		t.Fatal(err)
	}
	var hist protocol.ChatHistory
	for _, m := range conn.all() {
		if m.Type == protocol.TypeChatHistory {
			_ = json.Unmarshal(m.Payload, &hist)
		}
	}
	if len(hist.Messages) != 2 || hist.Messages[0].Text != "before restart" || hist.Messages[1].AuthorKind != "system" {
		t.Fatalf("history = %+v", hist.Messages)
	}
	hands, _ := st.ListHands(ctx, tbl.ID, 10, 0)
	if len(hands) != 1 || !hands[0].Voided {
		t.Fatalf("hands = %+v", hands)
	}
	// A new hand starts after the delay with the restored players.
	waitFor(t, "hand after restart", func() bool { return handNumber(restored) == 2 })

	// Deleting a non-running table works and removes it from the store.
	second := reg2.List()[1]
	if second.ID == tbl.ID {
		second = reg2.List()[0]
	}
	if err := reg2.Delete(ctx, second.ID); err != nil {
		t.Fatal(err)
	}
	if _, _, err := st.GetTable(ctx, second.ID); !errors.Is(err, store.ErrNotFound) {
		t.Fatalf("table still stored: %v", err)
	}
	if err := reg2.Delete(ctx, second.ID); !errors.Is(err, ErrNotFound) {
		t.Fatalf("delete twice: %v", err)
	}
}

func TestSeatPickingAndAvatar(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, err := tbl.Join("Alice", 3, 7)
	if err != nil || a.Seat != 3 {
		t.Fatalf("pick seat 3: %+v %v", a, err)
	}
	if _, err := tbl.Join("Bob", 3, 1); !errors.Is(err, ErrSeatTaken) {
		t.Fatalf("taken seat: %v", err)
	}
	if _, err := tbl.Join("Bob", 42, 1); !errors.Is(err, ErrSeatTaken) {
		t.Fatalf("seat out of range: %v", err)
	}
	b, err := tbl.Join("Bob", -1, 99)
	if err != nil || b.Seat != 0 {
		t.Fatalf("lowest free seat: %+v %v", b, err)
	}
	info := tbl.Info()
	if len(info.TakenSeats) != 2 || info.TakenSeats[0] != 0 || info.TakenSeats[1] != 3 {
		t.Fatalf("taken seats = %v", info.TakenSeats)
	}
	d := tbl.AdminDetail()
	if d.Players[0].Avatar < 0 || d.Players[0].Avatar >= AvatarCount || d.Players[1].Avatar != 7 {
		t.Fatalf("avatars = %d %d", d.Players[0].Avatar, d.Players[1].Avatar)
	}
}

func TestPreActionsAndSitOutFold(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.TurnTime = 5
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, connB := join(t, tbl, "Bob")
	c, _ := join(t, tbl, "Carol")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	actor, _ := toAct(tbl)
	others := []string{}
	for _, id := range []string{a.PlayerID, b.PlayerID, c.PlayerID} {
		if id != actor {
			others = append(others, id)
		}
	}
	// A pre-action of a wrong kind is rejected.
	if err := tbl.SetPreAction(others[0], "jump"); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("bad kind: %v", err)
	}
	// The next player pre-selects call-any; when the turn arrives the call
	// happens without them acting.
	if err := tbl.SetPreAction(others[0], PreCallAny); err != nil {
		t.Fatal(err)
	}
	snapConn := map[string]*fakeConn{a.PlayerID: connA, b.PlayerID: connB}
	if cn := snapConn[others[0]]; cn != nil {
		waitFor(t, "pre_action in snapshot", func() bool { return cn.lastSnapshot(t).You.PreAction == PreCallAny })
	}
	if err := tbl.Action(actor, poker.Action{Kind: poker.Raise, Amount: 300}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "turn moved past the pre-acting player", func() bool {
		id, _ := toAct(tbl)
		return id != others[0] && id != ""
	})
	var called bool
	tbl.call(func() {
		p := tbl.players[others[0]]
		st, _ := tbl.hand.State(p.Seat)
		called = st.LastAction != nil && st.LastAction.Kind == poker.Call && st.BetThisStreet == 300
		if p.preAction != PreCallAny {
			t.Errorf("pre-action must stay armed, got %q", p.preAction)
		}
	})
	if !called {
		t.Fatal("call-any did not call the raise")
	}
	// Sitting out during the hand folds at once and leaves only the sit-in option.
	if err := tbl.SitOut(others[1]); err != nil {
		t.Fatal(err)
	}
	var folded bool
	var status string
	tbl.call(func() {
		p := tbl.players[others[1]]
		status = p.Status
		if tbl.hand != nil {
			st, _ := tbl.hand.State(p.Seat)
			folded = st.Folded || tbl.hand.Done()
		} else {
			folded = true
		}
	})
	if !folded || status != StatusSittingOut {
		t.Fatalf("sit-out mid-hand: folded=%v status=%s", folded, status)
	}
}

func TestBlindsUpAndRabbitHunt(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.HandDelayMs = 2000
	s.BlindsUpPercent = 50
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	if err := tbl.BlindsUp(); err != nil {
		t.Fatal(err)
	}
	d := tbl.AdminDetail()
	if d.Settings.SmallBlind != 75 || d.Settings.BigBlind != 150 {
		t.Fatalf("blinds after +50%%: %d/%d", d.Settings.SmallBlind, d.Settings.BigBlind)
	}
	waitFor(t, "blinds_changed event", func() bool {
		for _, e := range connA.events(t) {
			if e.Kind == "blinds_changed" && e.Blinds != nil && e.Blinds.Big == 150 {
				return true
			}
		}
		return false
	})
	// Rabbit hunt: fold preflop, then reveal the rest of the board once.
	actor, _ := toAct(tbl)
	if err := tbl.RabbitHunt(actor); !errors.Is(err, poker.ErrWrongPhase) {
		t.Fatalf("rabbit during the hand: %v", err)
	}
	if err := tbl.Action(actor, poker.Action{Kind: poker.Fold}); err != nil {
		t.Fatal(err)
	}
	winner := a.PlayerID
	if actor == winner {
		winner = b.PlayerID
	}
	waitFor(t, "can_rabbit_hunt", func() bool {
		if winner != a.PlayerID {
			return true
		}
		return connA.lastSnapshot(t).You.CanRabbitHunt
	})
	if err := tbl.RabbitHunt(winner); err != nil {
		t.Fatal(err)
	}
	if err := tbl.RabbitHunt(actor); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("second rabbit hunt: %v", err)
	}
	waitFor(t, "rabbit cards in snapshot", func() bool {
		snap := connA.lastSnapshot(t)
		return snap.Hand != nil && len(snap.Hand.RabbitCards) == 5 && !snap.You.CanRabbitHunt
	})
	// The schedule is checked when the next hand is dealt.
	tbl.call(func() {
		tbl.settings.BlindsUpMinutes = 1
		tbl.blindsUpAt = tbl.nowMs() - 1
	})
	waitFor(t, "next hand", func() bool { return handNumber(tbl) >= 2 && handRunning(tbl) })
	d = tbl.AdminDetail()
	if d.Settings.SmallBlind != 113 || d.Settings.BigBlind != 225 {
		t.Fatalf("scheduled increase: %d/%d", d.Settings.SmallBlind, d.Settings.BigBlind)
	}
	var next int64
	tbl.call(func() { next = tbl.blindsUpAt })
	if next <= tbl.nowMs() {
		t.Fatal("clock not re-armed")
	}
	// Rabbit hunting can be switched off.
	tbl.call(func() { tbl.settings.AllowRabbitHunt = false })
	actor, _ = toAct(tbl)
	if err := tbl.Action(actor, poker.Action{Kind: poker.Fold}); err != nil {
		t.Fatal(err)
	}
	if err := tbl.RabbitHunt(a.PlayerID); !errors.Is(err, ErrRabbitNotAllowed) {
		t.Fatalf("rabbit disabled: %v", err)
	}
}

func TestBlindClockPausesWithTheTable(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.BlindsUpMinutes = 10
	tbl := newTestTable(t, s)
	join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	var before int64
	tbl.call(func() { before = tbl.blindsUpAt })
	if before == 0 {
		t.Fatal("clock not armed on auto start")
	}
	if err := tbl.Pause(); err != nil {
		t.Fatal(err)
	}
	var paused int64
	tbl.call(func() { paused = tbl.blindsUpAt })
	if paused != 0 {
		t.Fatal("clock must be hidden while paused")
	}
	if err := tbl.Resume(); err != nil {
		t.Fatal(err)
	}
	var after int64
	tbl.call(func() { after = tbl.blindsUpAt })
	if after == 0 || after > before+1000 || after < before-1000 {
		t.Fatalf("clock after resume = %d, want about %d", after, before)
	}
}

func TestSeatChangeCostsADeadBlind(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	waitFor(t, "hand", func() bool { return handRunning(tbl) })
	if err := tbl.ChangeSeat(a.PlayerID, 1); !errors.Is(err, ErrSeatTaken) {
		t.Fatalf("occupied seat: %v", err)
	}
	if err := tbl.ChangeSeat(a.PlayerID, 42); !errors.Is(err, ErrSeatTaken) {
		t.Fatalf("out of range: %v", err)
	}
	if err := tbl.ChangeSeat(a.PlayerID, 5); err != nil {
		t.Fatal(err)
	}
	if err := tbl.ChangeSeat(b.PlayerID, 5); !errors.Is(err, ErrSeatTaken) {
		t.Fatalf("reserved seat: %v", err)
	}
	waitFor(t, "pending seat in snapshot", func() bool {
		y := connA.lastSnapshot(t).You
		return y.PendingSeat != nil && *y.PendingSeat == 5 && !y.CanChangeSeat
	})
	// The move happens after the running hand, the dead blind in the next one.
	playToEnd(t, tbl)
	waitFor(t, "moved", func() bool {
		seat := -1
		tbl.call(func() { seat = tbl.players[a.PlayerID].Seat })
		return seat == 5
	})
	waitFor(t, "next hand", func() bool { return handNumber(tbl) >= 2 && handRunning(tbl) })
	waitFor(t, "dead blind event", func() bool {
		for _, e := range connA.events(t) {
			if e.Kind == "blind_posted" && e.Blind == "dead" && e.Seat != nil && *e.Seat == 5 {
				return true
			}
		}
		return false
	})
	if connA.lastSnapshot(t).You.CanChangeSeat {
		t.Fatal("cooldown must block a second move right away")
	}
	var stack int64
	tbl.call(func() {
		st, _ := tbl.hand.State(5)
		stack = st.TotalBet
	})
	if stack < s.BigBlind {
		t.Fatalf("dead blind not in the pot: total bet %d", stack)
	}
}

func TestPreActionsStayArmedAcrossHands(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.HandDelayMs = 2000
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, _ := join(t, tbl, "Bob")
	// Armed before the first hand is dealt: both call any bet and check
	// otherwise, so every hand runs to the showdown without a manual action.
	for _, id := range []string{a.PlayerID, b.PlayerID} {
		if err := tbl.SetPreAction(id, PreCallAny); err != nil {
			t.Fatal(err)
		}
	}
	waitFor(t, "hand 1", func() bool { return handNumber(tbl) >= 1 })
	waitFor(t, "hand 2 (hand 1 played itself out)", func() bool { return handNumber(tbl) >= 2 })
	waitFor(t, "hand 3", func() bool { return handNumber(tbl) >= 3 })
	tbl.call(func() {
		for _, id := range []string{a.PlayerID, b.PlayerID} {
			if tbl.players[id].preAction != PreCallAny {
				t.Errorf("%s: pre-action lost: %q", tbl.players[id].Name, tbl.players[id].preAction)
			}
		}
	})
	waitFor(t, "armed in snapshot", func() bool { return connA.lastSnapshot(t).You.PreAction == PreCallAny })
	// Switching off stops the automation: Alice's next turn waits for her.
	if err := tbl.SetPreAction(a.PlayerID, PreNone); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "Alice on turn", func() bool {
		id, _ := toAct(tbl)
		return id == a.PlayerID
	})
	// Check/fold folds when facing a bet.
	if err := tbl.SetPreAction(a.PlayerID, PreCheckFold); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "auto action", func() bool {
		id, _ := toAct(tbl)
		return id != a.PlayerID
	})
}
