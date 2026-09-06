package table

import (
	"cmp"
	"context"
	"log/slog"
	"sort"
	"time"

	"showdown/internal/poker"
	"showdown/internal/protocol"
	"showdown/internal/store"
)

// Table states.
const (
	StateWaiting = "waiting"
	StateRunning = "running"
	StatePaused  = "paused"
	StateEnded   = "ended"
)

// Player statuses.
const (
	StatusActive     = "active"
	StatusSittingOut = "sitting_out"
	StatusBusted     = "busted"
	StatusLeft       = "left"
)

// Client roles.
const (
	RolePlayer    = "player"
	RoleSpectator = "spectator"
	RoleAdmin     = "admin"
)

const (
	maxSeats        = 10
	chatKeep        = 200
	chatOnConnect   = 50
	maxChatRunes    = 300
	sessionLifetime = 30 * 24 * time.Hour
)

// Delays are the server constants of docs §5.2 (overridable in tests).
type Delays struct {
	Street   time.Duration
	Runout   time.Duration
	Showdown time.Duration
	// ShowdownPerHand is added to Showdown for every revealed hand beyond
	// the first, so a five-way showdown stays on screen long enough.
	ShowdownPerHand time.Duration
	// ResultExtension is the minimum time a finished hand stays on screen
	// after a late reveal or a rabbit hunt.
	ResultExtension time.Duration
	// RunTwiceDecision is how long the players have to agree to run it twice
	// when everyone is all-in.
	RunTwiceDecision time.Duration
	// PotAward is added to the showdown for every pot beyond the first: the
	// clients present the pots one after another (side pots first, main pot
	// last) and each one needs its moment on screen.
	PotAward time.Duration
}

// DefaultDelays are the production values.
var DefaultDelays = Delays{
	Street: 800 * time.Millisecond, Runout: 1200 * time.Millisecond,
	Showdown: 3500 * time.Millisecond, ShowdownPerHand: 1500 * time.Millisecond,
	ResultExtension: 5 * time.Second, RunTwiceDecision: 8 * time.Second,
	PotAward: 2500 * time.Millisecond,
}

// Conn is the transport side of a connected client. Send must never block
// the caller for long; it returns false when the connection is gone.
type Conn interface {
	Send(env protocol.Envelope) bool
	Close(code int, reason string)
}

// Client is one attached WebSocket connection.
type Client struct {
	Conn     Conn
	Role     string
	PlayerID string // players only
	Name     string // spectators (display name), admins ("admin")
	Admin    bool   // presented the table's admin token (any role)
}

// Player is a seated (or recently left) player.
type Player struct {
	ID          string
	Name        string
	Seat        int
	Stack       int64
	Status      string
	Connected   bool
	Muted       bool
	lastSay     int64 // unix ms of the last quick phrase (rate limit)
	MissedTurns int
	BuyInTotal  int64
	HandsPlayed int
	HandsWon    int
	BiggestPot  int64
	JoinedAt    int64
	LeftAt      int64
	Avatar      int // 0..19, one of the predefined avatars
	// Statistics: hands with chips put in voluntarily preflop, showdowns
	// reached and won.
	VPIPHands    int
	Showdowns    int
	ShowdownsWon int
	// TimeBank is the remaining extra thinking time in seconds;
	// usedTimeBank records that it kicked in during the current hand (no
	// refill for that hand).
	TimeBank     int
	usedTimeBank bool
	// Place is the final placement (1 = winner); 0 while still playing.
	Place int
	// Camera: the player's video is on (browser to browser like the voice).
	Camera bool

	inHand       bool
	vpipThisHand bool
	straddleNext bool // posts a straddle whenever seated left of the big blind
	leaving      bool
	kicked       bool
	preAction    string // automatic action at every turn: "", "fold" (sit-out, this hand), "check_fold", "call_any"

	// Seat changes: the wanted seat (-1 none) is taken at the next deal; the
	// mover then posts a dead big blind, and may move again after a cooldown.
	pendingSeat        int
	owesDeadBlind      bool
	lastSeatChangeHand int

	// Voice chat presence: "off", "on" or "muted". The audio itself never
	// touches the server; it only relays the WebRTC setup messages.
	Voice string
}

// Voice states.
const (
	VoiceOff   = "off"
	VoiceOn    = "on"
	VoiceMuted = "muted"
)

// SeatChangeCooldownHands is the number of hands between two seat changes.
const SeatChangeCooldownHands = 3

// Pre-action kinds (docs §8.2 pre_action).
const (
	PreNone      = "none"
	PreCheckFold = "check_fold"
	PreCallAny   = "call_any"
	preFold      = "fold" // internal: set by sit-out during a hand
)

// AvatarCount is the number of predefined avatars.
const AvatarCount = 20

// Deps are the table's external dependencies. Zero values get defaults.
type Deps struct {
	Store    *store.Store
	Log      *slog.Logger
	Now      func() time.Time
	Shuffle  func([]poker.Card)
	RandIntn func(n int) int
	Delays   Delays
}

func (d Deps) withDefaults() Deps {
	if d.Log == nil {
		d.Log = slog.New(slog.DiscardHandler)
	}
	if d.Now == nil {
		d.Now = time.Now
	}
	if d.Shuffle == nil {
		d.Shuffle = poker.SecureShuffle
	}
	if d.RandIntn == nil {
		d.RandIntn = func(n int) int { return int(randomIndex(n)) }
	}
	if d.Delays == (Delays{}) {
		d.Delays = DefaultDelays
	}
	return d
}

type closeRequest struct {
	code   int
	reason string
}

type chipAdjust struct {
	playerID string
	delta    int64
	note     string
}

// Table is the actor. Every field below inbox is owned by the actor
// goroutine and must only be touched from inbox functions.
type Table struct {
	ID string

	deps    Deps
	log     *slog.Logger
	persist *persister
	inbox   chan func()
	stopCh  chan struct{}
	stopped chan struct{}

	name       string
	state      string
	createdAt  int64
	endedAt    int64
	settings   Settings
	handNumber int
	buttonSeat int

	seats          [maxSeats]*Player
	players        map[string]*Player // seated players by id
	names          map[string]string  // name key -> name, everything ever used at this table
	spectatorNames map[string]bool

	clients       map[*Client]struct{}
	playerClients map[string]*Client

	chat    []protocol.ChatMessage
	chatSeq int64

	hand            *poker.Hand
	handStartedAt   int64
	handStartStacks map[int]int64
	handEvents      []protocol.Event
	handPhase       string
	deadline        int64
	toActSeat       int
	seq             int
	timerGen        uint64

	pendingEvents   []protocol.Event
	adminTokenHash  string // SHA-256 of the creator's admin token
	pendingMsgs     []protocol.Envelope
	dirty           bool
	closeAfterFlush *closeRequest
	pendingChips    []chipAdjust
	sitOutPending   map[string]bool
	endAfterHand    bool
	startPending    bool
	rabbitCards     []string        // rabbit hunt of the current (finished) hand
	blindsUpAt      int64           // next scheduled blind increase (ms), 0 = none
	blindsPausedMs  int64           // remaining schedule time while paused
	phaseEndsAt     int64           // when the showdown/result phase ends (ms), 0 = n/a
	nextHandAt      int64           // when a pending hand start fires (ms), 0 = n/a
	timeBankUsing   bool            // the player on turn is spending their time bank
	equity          map[int]float64 // seat -> pot share in percent during a run-out
	ritVotes        map[int]bool    // run-it-twice answers by seat (vote open while non-nil)
	ritEndsAt       int64           // when the run-it-twice vote closes (ms)
	ritDecided      bool            // the vote of this hand is over
}

// newTable wires a table but does not start its loop.
func newTable(id string, deps Deps) *Table {
	deps = deps.withDefaults()
	t := &Table{
		ID:             id,
		deps:           deps,
		log:            deps.Log.With("table", id),
		inbox:          make(chan func(), 256),
		stopCh:         make(chan struct{}),
		stopped:        make(chan struct{}),
		players:        map[string]*Player{},
		names:          map[string]string{},
		spectatorNames: map[string]bool{},
		clients:        map[*Client]struct{}{},
		playerClients:  map[string]*Client{},
		sitOutPending:  map[string]bool{},
		buttonSeat:     -1,
		toActSeat:      -1,
	}
	t.persist = newPersister(deps.Store, t.log)
	return t
}

// run is the actor loop: one inbox function at a time, then a flush that
// pushes events and personalized snapshots to every client.
func (t *Table) run() {
	defer close(t.stopped)
	for {
		select {
		case fn := <-t.inbox:
			fn()
			t.flush()
		case <-t.stopCh:
			return
		}
	}
}

// post schedules fn on the actor goroutine without waiting.
func (t *Table) post(fn func()) {
	select {
	case t.inbox <- fn:
	case <-t.stopCh:
	}
}

// call runs fn on the actor goroutine and waits for it.
func (t *Table) call(fn func()) {
	done := make(chan struct{})
	t.post(func() {
		defer close(done)
		fn()
		t.flush() // callers observe a consistent, already-broadcast state
	})
	select {
	case <-done:
	case <-t.stopped:
	}
}

func (t *Table) callErr(fn func() error) error {
	err := ErrTableEnded
	t.call(func() { err = fn() })
	return err
}

func (t *Table) nowMs() int64 { return t.deps.Now().UnixMilli() }

// schedule arms the single table timer; any previously armed timer is
// invalidated. Timer callbacks run on the actor goroutine.
func (t *Table) schedule(d time.Duration, fn func()) {
	t.timerGen++
	gen := t.timerGen
	time.AfterFunc(d, func() {
		t.post(func() {
			if t.timerGen == gen {
				fn()
			}
		})
	})
}

func (t *Table) cancelTimer() { t.timerGen++ }

// ---- state helpers ---------------------------------------------------------------

func (t *Table) seatedCount() int { return len(t.players) }

func (t *Table) eligible() []*Player {
	var out []*Player
	for _, p := range t.seats[:t.settings.MaxPlayers] {
		if p != nil && p.Status == StatusActive && p.Stack > 0 {
			out = append(out, p)
		}
	}
	return out
}

func (t *Table) betweenHands() bool { return t.hand == nil || t.hand.Done() }

func (t *Table) handInProgress() bool { return t.hand != nil && !t.hand.Done() }

func (t *Table) nextSeq() int {
	t.seq++
	return t.seq
}

func (t *Table) emit(e protocol.Event) {
	e.Seq = t.nextSeq()
	e.TS = t.nowMs()
	t.pendingEvents = append(t.pendingEvents, e)
	t.handEvents = append(t.handEvents, e)
	t.dirty = true
}

func (t *Table) touch() { t.dirty = true }

// ---- flush: events + snapshots -----------------------------------------------------

func (t *Table) flush() {
	if !t.dirty && len(t.pendingEvents) == 0 && len(t.pendingMsgs) == 0 && t.closeAfterFlush == nil {
		return
	}
	events := t.pendingEvents
	msgs := t.pendingMsgs
	t.pendingEvents, t.pendingMsgs, t.dirty = nil, nil, false

	for _, m := range msgs {
		for c := range t.clients {
			c.Conn.Send(m)
		}
	}
	for c := range t.clients {
		if len(events) > 0 {
			c.Conn.Send(protocol.MustEncode(protocol.TypeEvents, "", protocol.EventsPayload{
				HandNumber: t.handNumber, Events: t.personalize(c, events),
			}))
		}
		c.Conn.Send(protocol.MustEncode(protocol.TypeSnapshot, "", t.snapshot(c)))
	}
	if req := t.closeAfterFlush; req != nil {
		t.closeAfterFlush = nil
		for c := range t.clients {
			c.Conn.Close(req.code, req.reason)
		}
		t.clients = map[*Client]struct{}{}
		t.playerClients = map[string]*Client{}
	}
}

// personalize strips hole cards from hole_cards_dealt events that are not
// the recipient's own.
func (t *Table) personalize(c *Client, events []protocol.Event) []protocol.Event {
	out := make([]protocol.Event, len(events))
	for i, e := range events {
		if e.Kind == "hole_cards_dealt" && e.Seat != nil {
			own := c.Role == RolePlayer && t.seatOf(c.PlayerID) == *e.Seat
			if !own {
				e.Cards = nil
			}
		}
		out[i] = e
	}
	return out
}

func (t *Table) seatOf(playerID string) int {
	if p, ok := t.players[playerID]; ok {
		return p.Seat
	}
	return -1
}

func (t *Table) broadcastMsg(env protocol.Envelope) {
	t.pendingMsgs = append(t.pendingMsgs, env)
}

// ---- public API ---------------------------------------------------------------------

// Info is the public join-page summary.
type Info struct {
	ID               string
	Name             string
	State            string
	RequiresPassword bool
	PasswordHash     string
	JoinPolicy       string
	AllowSpectators  bool
	Seated           int
	TakenSeats       []int
	MaxPlayers       int
	SmallBlind       int64
	BigBlind         int64
	HandNumber       int
	CreatedAt        int64
	EndedAt          int64
}

// Info returns the public summary.
func (t *Table) Info() Info {
	var info Info
	t.call(func() {
		info = Info{
			ID: t.ID, Name: t.name, State: t.state, RequiresPassword: t.settings.PasswordHash != "",
			PasswordHash: t.settings.PasswordHash, JoinPolicy: t.settings.JoinPolicy,
			AllowSpectators: t.settings.AllowSpectators, Seated: t.seatedCount(), MaxPlayers: t.settings.MaxPlayers,
			SmallBlind: t.settings.SmallBlind, BigBlind: t.settings.BigBlind, HandNumber: t.handNumber,
			CreatedAt: t.createdAt, EndedAt: t.endedAt, TakenSeats: []int{},
		}
		for i := 0; i < t.settings.MaxPlayers; i++ {
			if t.seats[i] != nil {
				info.TakenSeats = append(info.TakenSeats, i)
			}
		}
	})
	return info
}

// State returns the table state.
func (t *Table) State() string {
	var s string
	t.call(func() { s = t.state })
	return s
}

// JoinResult is returned by Join.
type JoinResult struct {
	PlayerID string
	Name     string
	Seat     int
}

// Join seats a new player (password already verified by the caller). seat
// is the wanted seat or -1 for the lowest free one; avatar is 0..19.
func (t *Table) Join(rawName string, seat, avatar int) (JoinResult, error) {
	var res JoinResult
	err := t.callErr(func() error {
		if t.state == StateEnded {
			return ErrTableEnded
		}
		if t.settings.JoinPolicy == JoinClosed || (t.settings.JoinPolicy == JoinBeforeStart && t.state != StateWaiting) {
			return ErrJoinsClosed
		}
		name, err := NormalizeName(rawName)
		if err != nil {
			return err
		}
		if _, taken := t.names[NameKey(name)]; taken {
			return ErrNameTaken
		}
		if seat >= 0 {
			if seat >= t.settings.MaxPlayers {
				return ErrSeatTaken
			}
			if t.seats[seat] != nil {
				return ErrSeatTaken
			}
		} else {
			for i := 0; i < t.settings.MaxPlayers; i++ {
				if t.seats[i] == nil {
					seat = i
					break
				}
			}
			if seat < 0 {
				return ErrTableFull
			}
		}
		if avatar < 0 || avatar >= AvatarCount {
			avatar = int(randomIndex(AvatarCount))
		}
		p := &Player{
			ID: newPlayerID(), Name: name, Seat: seat, Stack: t.settings.StartMoney, Status: StatusActive,
			BuyInTotal: t.settings.StartMoney, JoinedAt: t.nowMs(), Avatar: avatar, pendingSeat: -1,
			TimeBank: t.settings.TimeBankSeconds,
		}
		t.seats[seat] = p
		t.players[p.ID] = p
		t.names[NameKey(name)] = name
		t.emit(protocol.Event{Kind: "player_joined", Seat: protocol.Int(seat), Name: name})
		t.persistPlayer(p)
		t.scheduleStart()
		res = JoinResult{PlayerID: p.ID, Name: name, Seat: seat}
		return nil
	})
	return res, err
}

// Spectate reserves a spectator name and returns its normalized form.
func (t *Table) Spectate(rawName string) (string, error) {
	var name string
	err := t.callErr(func() error {
		if t.state == StateEnded {
			return ErrTableEnded
		}
		if !t.settings.AllowSpectators {
			return ErrSpectatorsDisabled
		}
		n, err := NormalizeName(rawName)
		if err != nil {
			return err
		}
		if _, taken := t.names[NameKey(n)]; taken {
			return ErrNameTaken
		}
		t.names[NameKey(n)] = n
		t.spectatorNames[NameKey(n)] = true
		name = n
		return nil
	})
	return name, err
}

// HasPlayer reports whether the player is currently seated.
func (t *Table) HasPlayer(playerID string) bool {
	var ok bool
	t.call(func() { _, ok = t.players[playerID] })
	return ok
}

// Attach registers a connection. Players replace an older connection with
// the same identity (closed with 4004). The welcome and chat history are
// sent directly; everybody else learns about it through the next snapshot.
func (t *Table) Attach(c *Client) error {
	return t.callErr(func() error {
		if t.state == StateEnded {
			return ErrTableEnded
		}
		switch c.Role {
		case RolePlayer:
			p, ok := t.players[c.PlayerID]
			if !ok {
				return ErrNotSeated
			}
			if old := t.playerClients[c.PlayerID]; old != nil && old != c {
				delete(t.clients, old)
				old.Conn.Close(protocol.CloseReplaced, "replaced")
			}
			t.playerClients[c.PlayerID] = c
			p.Connected = true
		case RoleSpectator:
			if !t.settings.AllowSpectators {
				return ErrSpectatorsDisabled
			}
		case RoleAdmin:
		default:
			return ErrIllegalAction
		}
		t.clients[c] = struct{}{}
		you := protocol.YouIdentity{Role: c.Role}
		if c.Role == RolePlayer {
			you.PlayerID = c.PlayerID
			you.Seat = protocol.Int(t.seatOf(c.PlayerID))
		}
		c.Conn.Send(protocol.MustEncode(protocol.TypeWelcome, "", protocol.Welcome{You: you, Snapshot: t.snapshot(c)}))
		hist := t.chat
		if len(hist) > chatOnConnect {
			hist = hist[len(hist)-chatOnConnect:]
		}
		c.Conn.Send(protocol.MustEncode(protocol.TypeChatHistory, "", protocol.ChatHistory{Messages: append([]protocol.ChatMessage{}, hist...)}))
		t.touch()
		return nil
	})
}

// Detach forgets a connection.
func (t *Table) Detach(c *Client) {
	t.call(func() {
		if _, ok := t.clients[c]; !ok {
			return
		}
		delete(t.clients, c)
		if c.Role == RolePlayer && t.playerClients[c.PlayerID] == c {
			delete(t.playerClients, c.PlayerID)
			if p, ok := t.players[c.PlayerID]; ok {
				p.Connected = false
				p.Voice = VoiceOff
				p.Camera = false
			}
		}
		t.touch()
	})
}

// NotifyRestart tells every client the server is going down.
func (t *Table) NotifyRestart() {
	t.call(func() {
		t.broadcastMsg(protocol.MustEncode(protocol.TypeServerRestarting, "", struct{}{}))
	})
}

// Stop ends the actor: clients are closed with the given code, timers are
// cancelled and the persister is drained.
func (t *Table) Stop(ctx context.Context, code int, reason string) {
	t.call(func() {
		t.cancelTimer()
		for c := range t.clients {
			c.Conn.Close(code, reason)
		}
		t.clients = map[*Client]struct{}{}
		t.playerClients = map[string]*Client{}
	})
	close(t.stopCh)
	<-t.stopped
	t.persist.close(ctx)
}

// ---- player commands ----------------------------------------------------------------

func (t *Table) seatedPlayer(playerID string) (*Player, error) {
	if t.state == StateEnded {
		return nil, ErrTableEnded
	}
	p, ok := t.players[playerID]
	if !ok {
		return nil, ErrNotSeated
	}
	return p, nil
}

// Action applies a betting action.
func (t *Table) Action(playerID string, a poker.Action) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if !t.handInProgress() || !p.inHand {
			return poker.ErrNotYourTurn
		}
		events, err := t.hand.Apply(p.Seat, a)
		if err != nil {
			return err
		}
		p.MissedTurns = 0
		p.preAction = ""
		if t.timeBankUsing {
			// Unused time bank goes back to the player.
			p.TimeBank = max(0, int((t.deadline-t.nowMs())/1000))
			t.timeBankUsing = false
		}
		t.applyEngineEvents(events)
		t.afterEngine()
		return nil
	})
}

// SetVoice records a player's voice-chat presence (and camera) for the
// other clients.
func (t *Table) SetVoice(playerID, state string, camera bool) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		switch state {
		case VoiceOff, VoiceOn, VoiceMuted:
		default:
			return ErrIllegalAction
		}
		p.Voice = state
		p.Camera = camera && state != VoiceOff
		t.touch()
		return nil
	})
}

// CameraOff turns a player's camera off on the host's behalf; the player
// may turn it on again themselves.
func (t *Table) CameraOff(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if !p.Camera {
			return ErrIllegalAction
		}
		p.Camera = false
		t.audit("camera_off", playerID, nil)
		t.touch()
		return nil
	})
}

// SetStraddle arms or disarms the player's straddle for the hands in which
// they sit left of the big blind (table setting allow_straddle).
func (t *Table) SetStraddle(playerID string, on bool) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if on && !t.settings.AllowStraddle {
			return ErrIllegalAction
		}
		p.straddleNext = on
		t.touch()
		return nil
	})
}

// RunTwice records a player's answer to the run-it-twice vote of the
// current run-out. A "no" ends the vote at once; the last "yes" too.
func (t *Table) RunTwice(playerID string, agree bool) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if t.ritVotes == nil || !p.inHand || t.hand == nil {
			return poker.ErrWrongPhase
		}
		if st, ok := t.hand.State(p.Seat); !ok || st.Folded {
			return poker.ErrWrongPhase
		}
		if _, voted := t.ritVotes[p.Seat]; voted {
			return ErrIllegalAction
		}
		t.ritVotes[p.Seat] = agree
		t.touch()
		if !agree || t.ritVoteComplete() {
			t.resolveRunTwice()
		}
		return nil
	})
}

// MuteVoice mutes a player's microphone on the host's behalf. The player can
// unmute again themselves; there is deliberately no host unmute.
func (t *Table) MuteVoice(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if p.Voice != VoiceOn {
			return ErrIllegalAction
		}
		p.Voice = VoiceMuted
		t.audit("mute_voice", playerID, nil)
		t.touch()
		return nil
	})
}

// sayInterval is the minimum pause between two quick phrases of one player.
const sayInterval = 3000

// Say broadcasts one of the predefined quick phrases next to the player's
// avatar. Phrases are not persisted and not part of the hand log.
func (t *Table) Say(c *Client, phrase string) error {
	return t.callErr(func() error {
		if c.Role != RolePlayer {
			return ErrNotSeated
		}
		p, err := t.seatedPlayer(c.PlayerID)
		if err != nil {
			return err
		}
		if p.Muted {
			return ErrMuted
		}
		ok := false
		for _, ph := range protocol.Phrases {
			if ph == phrase {
				ok = true
			}
		}
		if !ok {
			return ErrIllegalAction
		}
		now := t.nowMs()
		if now-p.lastSay < sayInterval {
			return ErrRateLimited
		}
		p.lastSay = now
		env, err := protocol.Encode(protocol.TypePhrase, "", protocol.PhrasePayload{Seat: p.Seat, Name: p.Name, Phrase: phrase, TS: now})
		if err != nil {
			return err
		}
		t.broadcastMsg(env)
		return nil
	})
}

// RelayVoice forwards a WebRTC signalling message from one seated player to
// another. Offline targets are dropped silently; the sender retries when the
// target shows up in a snapshot.
func (t *Table) RelayVoice(from *Client, to string, sig protocol.VoiceSignal) error {
	return t.callErr(func() error {
		if from.Role != RolePlayer {
			return ErrNotSeated
		}
		if _, ok := t.players[to]; !ok {
			return ErrNotSeated
		}
		if c := t.playerClients[to]; c != nil {
			sig.From, sig.To = from.PlayerID, ""
			c.Conn.Send(protocol.MustEncode(protocol.TypeVoiceSignal, "", sig))
		}
		return nil
	})
}

// ChangeSeat moves a seated player to a free seat. Between hands the move
// happens at once, otherwise at the end of the running hand. To keep seat
// changes from being used to dodge the blinds, the mover posts a dead big
// blind in their next hand and cannot move again for a few hands.
func (t *Table) ChangeSeat(playerID string, seat int) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if seat < 0 || seat >= t.settings.MaxPlayers || seat == p.Seat {
			return ErrSeatTaken
		}
		if !t.canChangeSeat(p) {
			return ErrInvalidState
		}
		if t.seats[seat] != nil || t.seatReserved(seat) {
			return ErrSeatTaken
		}
		p.pendingSeat = seat
		p.owesDeadBlind = true
		p.lastSeatChangeHand = t.handNumber
		if !t.handInProgress() || !p.inHand {
			t.applySeatChange(p)
		}
		t.touch()
		return nil
	})
}

// canChangeSeat is the cooldown rule.
func (t *Table) canChangeSeat(p *Player) bool {
	return p.pendingSeat < 0 && (p.lastSeatChangeHand == 0 || t.handNumber-p.lastSeatChangeHand >= SeatChangeCooldownHands)
}

// seatReserved reports whether another player already waits for the seat.
func (t *Table) seatReserved(seat int) bool {
	for _, q := range t.players {
		if q.pendingSeat == seat {
			return true
		}
	}
	return false
}

// applySeatChange performs a pending move (between hands only).
func (t *Table) applySeatChange(p *Player) {
	to := p.pendingSeat
	p.pendingSeat = -1
	if to < 0 || to >= t.settings.MaxPlayers || t.seats[to] != nil {
		return
	}
	from := p.Seat
	t.seats[from] = nil
	t.seats[to] = p
	p.Seat = to
	t.emit(protocol.Event{Kind: "player_moved", Seat: protocol.Int(to), Name: p.Name, Delta: protocol.Int64(int64(from))})
	t.persistPlayer(p)
	t.audit("seat_change", p.ID, map[string]any{"from": from, "to": to})
}

// applyPendingSeatChanges moves everyone who asked during the last hand.
func (t *Table) applyPendingSeatChanges() {
	for _, p := range t.seats[:maxSeats] {
		if p != nil && p.pendingSeat >= 0 {
			t.applySeatChange(p)
		}
	}
}

// SetPreAction arms an automatic action (check/fold or call any) that is
// performed at every turn of the player for the rest of the current hand
// (or, armed between hands, for the next one) and is cleared when that hand
// ends, so it never carries over. The player may switch it off earlier
// (PreNone); sitting out or leaving clears it too. If it is their turn
// already, it is performed at once.
func (t *Table) SetPreAction(playerID, kind string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		switch kind {
		case PreNone:
			if p.preAction != preFold {
				p.preAction = ""
			}
			t.touch()
			return nil
		case PreCheckFold, PreCallAny:
		default:
			return ErrIllegalAction
		}
		if p.preAction == preFold {
			return poker.ErrWrongPhase // sitting out: the hand is folded anyway
		}
		p.preAction = kind
		t.touch()
		if t.handInProgress() && p.inHand {
			if seat, ok := t.hand.ToAct(); ok && seat == p.Seat {
				t.applyPreAction(p)
				t.afterEngine()
			}
		}
		return nil
	})
}

// applyPreAction performs the player's armed action now (it must be their
// turn). Check/fold and call any stay armed for the rest of the hand; the
// sit-out fold is one-shot.
// Impossible actions fall back to the timeout rule.
func (t *Table) applyPreAction(p *Player) {
	kind := p.preAction
	if kind == preFold {
		p.preAction = ""
	}
	o := t.hand.Options(p.Seat)
	var a poker.Action
	switch kind {
	case preFold:
		a = poker.Action{Kind: poker.Fold}
	case PreCheckFold:
		if o.Check {
			a = poker.Action{Kind: poker.Check}
		} else {
			a = poker.Action{Kind: poker.Fold}
		}
	case PreCallAny:
		switch {
		case o.Check:
			a = poker.Action{Kind: poker.Check}
		case o.Call > 0:
			a = poker.Action{Kind: poker.Call}
		default:
			a = poker.Action{Kind: poker.Fold}
		}
	default:
		return
	}
	events, err := t.hand.Apply(p.Seat, a)
	if err != nil {
		events = t.hand.Timeout(p.Seat)
	}
	t.applyEngineEvents(events)
}

// SitOut marks the player as sitting out from the next hand on. During a
// hand their cards are folded right away (at once when it is their turn,
// otherwise the moment it comes).
func (t *Table) SitOut(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if p.Status != StatusActive {
			return ErrInvalidState
		}
		p.Status = StatusSittingOut
		t.emit(protocol.Event{Kind: "player_sat_out", Seat: protocol.Int(p.Seat), Name: p.Name})
		t.persistPlayer(p)
		if t.handInProgress() && p.inHand {
			if st, ok := t.hand.State(p.Seat); ok && !st.Folded && !st.AllIn {
				events := t.hand.Forfeit(p.Seat)
				t.applyEngineEvents(events)
				t.afterEngine()
			}
		}
		return nil
	})
}

// SitIn marks a sitting-out player active again (dealt in next hand).
func (t *Table) SitIn(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if p.Status != StatusSittingOut {
			return ErrInvalidState
		}
		p.Status = StatusActive
		p.MissedTurns = 0
		if p.Stack == 0 {
			p.Status = StatusBusted
		}
		t.emit(protocol.Event{Kind: "player_sat_in", Seat: protocol.Int(p.Seat), Name: p.Name})
		t.persistPlayer(p)
		t.scheduleStart()
		return nil
	})
}

// Rebuy restores a busted player's stack between hands.
func (t *Table) Rebuy(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if !t.settings.AllowRebuy {
			return ErrRebuyNotAllowed
		}
		if p.Status != StatusBusted {
			return ErrRebuyNotAllowed
		}
		if !t.betweenHands() {
			return ErrNotBetweenHands
		}
		p.Stack = t.settings.StartMoney
		p.BuyInTotal += t.settings.StartMoney
		p.Status = StatusActive
		t.emit(protocol.Event{Kind: "player_rebought", Seat: protocol.Int(p.Seat), Name: p.Name, Amount: protocol.Int64(t.settings.StartMoney)})
		t.persistPlayer(p)
		t.scheduleStart()
		return nil
	})
}

// Leave removes the player: immediately between hands, otherwise after
// folding them and finishing the hand.
func (t *Table) Leave(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		t.removePlayer(p, false)
		return nil
	})
}

func (t *Table) removePlayer(p *Player, kicked bool) {
	p.leaving = true
	p.kicked = p.kicked || kicked
	if t.handInProgress() && p.inHand {
		events := t.hand.Forfeit(p.Seat)
		t.applyEngineEvents(events)
		t.afterEngine()
		if t.handInProgress() {
			return // seat is freed when the hand ends
		}
	}
	if p.Status != StatusLeft {
		t.freeSeat(p)
	}
}

// freeSeat finalises a leaving player: records results, frees the seat and
// closes the connection.
func (t *Table) freeSeat(p *Player) {
	kind := "player_left"
	if p.kicked {
		kind = "player_kicked"
	}
	t.seats[p.Seat] = nil
	delete(t.players, p.ID)
	delete(t.sitOutPending, p.ID)
	p.Status = StatusLeft
	p.LeftAt = t.nowMs()
	p.inHand = false
	t.emit(protocol.Event{Kind: kind, Seat: protocol.Int(p.Seat), Name: p.Name})
	t.persistPlayer(p)
	pid := p.ID
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.DeleteSessionsForPlayer(ctx, t.ID, pid)
	})
	if c := t.playerClients[p.ID]; c != nil {
		delete(t.playerClients, p.ID)
		delete(t.clients, c)
		if p.kicked {
			c.Conn.Send(protocol.MustEncode(protocol.TypeKicked, "", protocol.Kicked{Reason: "removed by admin"}))
			c.Conn.Close(protocol.CloseKicked, "kicked")
		}
		// A voluntary leaver's socket is closed by the transport after the
		// ack for the leave command has been written.
	}
}

// ShowCards reveals the player's hand during the result phase.
func (t *Table) ShowCards(playerID, which string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if t.hand == nil || !t.hand.Done() || !p.inHand {
			return poker.ErrWrongPhase
		}
		first, second := true, true
		switch which {
		case "", "both":
		case "first":
			second = false
		case "second":
			first = false
		default:
			return ErrIllegalAction
		}
		events, err := t.hand.ShowCards(p.Seat, first, second)
		if err != nil {
			return err
		}
		t.applyEngineEvents(events)
		t.extendResultPhase()
		return nil
	})
}

// RabbitHunt reveals the cards that would have completed the board. Allowed
// once per hand, in the result phase, by a player who was dealt in.
func (t *Table) RabbitHunt(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if !t.settings.AllowRabbitHunt {
			return ErrRabbitNotAllowed
		}
		if t.hand == nil || !t.hand.Done() || !p.inHand {
			return poker.ErrWrongPhase
		}
		if t.rabbitCards != nil {
			return ErrIllegalAction
		}
		cards := t.hand.RemainingBoard()
		if len(cards) == 0 {
			return ErrIllegalAction
		}
		t.rabbitCards = cardStrings(cards)
		t.emit(protocol.Event{Kind: "rabbit_hunt", Seat: protocol.Int(p.Seat), Name: p.Name, Cards: t.rabbitCards})
		t.extendResultPhase()
		return nil
	})
}

// canRabbitHunt is the snapshot flag for a player.
func (t *Table) canRabbitHunt(p *Player) bool {
	return t.settings.AllowRabbitHunt && t.hand != nil && t.hand.Done() && p.inHand &&
		t.rabbitCards == nil && len(t.hand.RemainingBoard()) > 0
}

// BlindsUp raises the blinds now (admin) by the configured percentage; the
// new blinds apply from the next hand.
func (t *Table) BlindsUp() error {
	return t.callErr(func() error {
		if t.state == StateEnded {
			return ErrTableEnded
		}
		t.raiseBlinds()
		return nil
	})
}

// raiseBlinds applies one step of the blind schedule and re-arms the clock.
func (t *Table) raiseBlinds() {
	pct := int64(t.settings.BlindsUpPercent)
	up := func(v int64) int64 { return (v*(100+pct) + 99) / 100 }
	t.settings.SmallBlind = up(t.settings.SmallBlind)
	t.settings.BigBlind = up(t.settings.BigBlind)
	if t.settings.Ante > 0 {
		t.settings.Ante = up(t.settings.Ante)
	}
	t.emit(protocol.Event{Kind: "blinds_changed", Blinds: &protocol.Blinds{Small: t.settings.SmallBlind, Big: t.settings.BigBlind}, Ante: protocol.Int64(t.settings.Ante)})
	t.persistSettings()
	t.armBlindsClock()
}

// armBlindsClock schedules the next automatic increase (checked when a hand
// starts) or clears it when the schedule is off.
func (t *Table) armBlindsClock() {
	if t.settings.BlindsUpMinutes <= 0 || t.state == StateEnded {
		t.blindsUpAt = 0
		return
	}
	t.blindsUpAt = t.nowMs() + int64(t.settings.BlindsUpMinutes)*60_000
	t.touch()
}

// ---- admin ---------------------------------------------------------------------------

// PlayerAdmin is the admin view of a player.
type PlayerAdmin struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Seat        int    `json:"seat"`
	Stack       int64  `json:"stack"`
	Status      string `json:"status"`
	Connected   bool   `json:"connected"`
	Muted       bool   `json:"muted"`
	MissedTurns int    `json:"missed_turns"`
	BuyInTotal  int64  `json:"buy_in_total"`
	HandsPlayed int    `json:"hands_played"`
	HandsWon    int    `json:"hands_won"`
	BiggestPot  int64  `json:"biggest_pot"`
	JoinedAt    int64  `json:"joined_at"`
	Avatar      int    `json:"avatar"`
	Voice       string `json:"voice"` // off | on | muted
	Camera      bool   `json:"camera"`
	Place       int    `json:"place"`
}

// AdminDetail is the full admin view of a table.
type AdminDetail struct {
	ID          string        `json:"id"`
	Name        string        `json:"name"`
	State       string        `json:"state"`
	HandNumber  int           `json:"hand_number"`
	CreatedAt   int64         `json:"created_at"`
	EndedAt     int64         `json:"ended_at,omitempty"`
	Settings    AdminView     `json:"settings"`
	Players     []PlayerAdmin `json:"players"`
	Spectators  int           `json:"spectators"`
	Connections int           `json:"connections"`
	JoinURL     string        `json:"join_url"`
}

// AdminDetail returns everything the admin panel shows.
func (t *Table) AdminDetail() AdminDetail {
	var d AdminDetail
	t.call(func() {
		d = AdminDetail{
			ID: t.ID, Name: t.name, State: t.state, HandNumber: t.handNumber, CreatedAt: t.createdAt,
			EndedAt: t.endedAt, Settings: t.settings.Admin(), Spectators: t.spectatorCount(),
			Connections: len(t.clients), JoinURL: "/t/" + t.ID, Players: []PlayerAdmin{},
		}
		for _, p := range t.seats[:t.settings.MaxPlayers] {
			if p == nil {
				continue
			}
			d.Players = append(d.Players, PlayerAdmin{
				ID: p.ID, Name: p.Name, Seat: p.Seat, Stack: t.currentStack(p), Status: p.Status, Connected: p.Connected,
				Muted: p.Muted, MissedTurns: p.MissedTurns, BuyInTotal: p.BuyInTotal, HandsPlayed: p.HandsPlayed,
				HandsWon: p.HandsWon, BiggestPot: p.BiggestPot, JoinedAt: p.JoinedAt, Avatar: p.Avatar,
				Voice: cmp.Or(p.Voice, VoiceOff), Camera: p.Camera, Place: p.Place,
			})
		}
	})
	return d
}

// UpdateSettings applies a validated patch. passwordHash is the bcrypt hash
// of the new password ("" clears it) and is only used when p.Password != nil.
func (t *Table) UpdateSettings(p SettingsPatch, passwordHash string) (changed, next []string, err error) {
	err = t.callErr(func() error {
		if t.state == StateEnded {
			return ErrTableEnded
		}
		s, ch, nx, err := t.settings.Apply(p, passwordHash, t.seatedCount())
		if err != nil {
			return err
		}
		t.settings = s
		changed, next = ch, nx
		if len(ch) > 0 {
			sort.Strings(ch)
			t.emit(protocol.Event{Kind: "settings_changed", Fields: ch})
		}
		if !s.AllowSpectators {
			for c := range t.clients {
				if c.Role == RoleSpectator {
					delete(t.clients, c)
					c.Conn.Close(1000, "spectators_disabled")
				}
			}
		}
		t.persistSettings()
		for _, f := range ch {
			if f == "blinds_up_minutes" && t.state == StateRunning {
				t.armBlindsClock()
			}
		}
		t.audit("settings_changed", "", map[string]any{"fields": ch})
		t.scheduleStart()
		return nil
	})
	return changed, next, err
}

// Start moves waiting -> running.
func (t *Table) Start() error {
	return t.callErr(func() error {
		if t.state != StateWaiting {
			return ErrInvalidState
		}
		t.setState(StateRunning, "table_started")
		t.armBlindsClock()
		t.audit("start", "", nil)
		t.maybeStartHand()
		return nil
	})
}

// Pause moves running -> paused; the current hand finishes.
func (t *Table) Pause() error {
	return t.callErr(func() error {
		if t.state != StateRunning {
			return ErrInvalidState
		}
		t.setState(StatePaused, "table_paused")
		// The blind clock stops with the table.
		if t.blindsUpAt > 0 {
			t.blindsPausedMs = max(t.blindsUpAt-t.nowMs(), 0)
			t.blindsUpAt = 0
		}
		t.audit("pause", "", nil)
		return nil
	})
}

// Resume moves paused -> running.
func (t *Table) Resume() error {
	return t.callErr(func() error {
		if t.state != StatePaused {
			return ErrInvalidState
		}
		t.setState(StateRunning, "table_resumed")
		if t.blindsPausedMs > 0 && t.settings.BlindsUpMinutes > 0 {
			t.blindsUpAt = t.nowMs() + t.blindsPausedMs
			t.touch()
		} else {
			t.armBlindsClock()
		}
		t.blindsPausedMs = 0
		t.audit("resume", "", nil)
		t.maybeStartHand()
		return nil
	})
}

// End finishes the table: after the current hand, or immediately (voiding
// the hand and returning all bets).
func (t *Table) End(immediate bool) error {
	return t.callErr(func() error {
		if t.state == StateEnded {
			return ErrInvalidState
		}
		t.audit("end", "", map[string]any{"immediate": immediate})
		if t.handInProgress() {
			if !immediate {
				t.endAfterHand = true
				return nil
			}
			t.voidHand("ended_by_admin")
		}
		t.endTable()
		return nil
	})
}

// Kick removes a player.
func (t *Table) Kick(playerID string) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		t.audit("kick", playerID, map[string]any{"name": p.Name})
		t.removePlayer(p, true)
		return nil
	})
}

// AdjustChips changes a stack between hands (queued while a hand runs).
// It reports whether the change was applied immediately.
func (t *Table) AdjustChips(playerID string, delta int64, note string) (bool, error) {
	applied := false
	err := t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		if delta == 0 {
			return ErrIllegalAction
		}
		if t.betweenHands() {
			if err := t.applyChips(p, delta, note); err != nil {
				return err
			}
			applied = true
			return nil
		}
		t.pendingChips = append(t.pendingChips, chipAdjust{playerID: playerID, delta: delta, note: note})
		t.audit("chips_queued", playerID, map[string]any{"delta": delta, "note": note})
		return nil
	})
	return applied, err
}

func (t *Table) applyChips(p *Player, delta int64, note string) error {
	if p.Stack+delta < 0 {
		return ErrIllegalAction
	}
	p.Stack += delta
	if delta > 0 {
		p.BuyInTotal += delta
	}
	switch {
	case p.Stack == 0 && p.Status == StatusActive:
		p.Status = StatusBusted
	case p.Stack > 0 && p.Status == StatusBusted:
		p.Status = StatusActive
	}
	t.emit(protocol.Event{Kind: "chips_adjusted", Seat: protocol.Int(p.Seat), Name: p.Name, Delta: protocol.Int64(delta)})
	t.persistPlayer(p)
	t.audit("chips_adjusted", p.ID, map[string]any{"delta": delta, "note": note})
	t.scheduleStart()
	return nil
}

// Mute toggles chat for a player.
func (t *Table) Mute(playerID string, muted bool) error {
	return t.callErr(func() error {
		p, err := t.seatedPlayer(playerID)
		if err != nil {
			return err
		}
		p.Muted = muted
		t.persistPlayer(p)
		t.audit("mute", playerID, map[string]any{"muted": muted})
		return nil
	})
}

func (t *Table) setState(state, eventKind string) {
	t.state = state
	t.emit(protocol.Event{Kind: eventKind})
	t.persistTable()
}

// ---- persistence helpers -------------------------------------------------------------

func (t *Table) persistTable() {
	row := store.TableRow{
		ID: t.ID, Name: t.name, State: t.state, CreatedAt: t.createdAt, EndedAt: t.endedAt,
		HandNumber: t.handNumber, ButtonSeat: t.buttonSeat, AdminTokenHash: t.adminTokenHash,
	}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.UpdateTable(ctx, row)
	})
}

// SeatOf returns the seat of a seated player, -1 when unknown.
func (t *Table) SeatOf(playerID string) int {
	seat := -1
	t.call(func() {
		if p, ok := t.players[playerID]; ok {
			seat = p.Seat
		}
	})
	return seat
}

// AdminTokenHash is the SHA-256 of the creator's admin token.
func (t *Table) AdminTokenHash() string {
	var h string
	t.call(func() { h = t.adminTokenHash })
	return h
}

func (t *Table) persistSettings() {
	row := t.settings.Row(t.ID)
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.SaveSettings(ctx, row)
	})
}

func (t *Table) persistPlayer(p *Player) {
	row := store.PlayerRow{
		ID: p.ID, TableID: t.ID, Name: p.Name, Seat: p.Seat, Stack: p.Stack, Status: p.Status, Muted: p.Muted,
		MissedTurns: p.MissedTurns, BuyInTotal: p.BuyInTotal, HandsPlayed: p.HandsPlayed, HandsWon: p.HandsWon,
		BiggestPot: p.BiggestPot, JoinedAt: p.JoinedAt, LeftAt: p.LeftAt, Avatar: p.Avatar,
		VPIPHands: p.VPIPHands, Showdowns: p.Showdowns, ShowdownsWon: p.ShowdownsWon, TimeBank: p.TimeBank, Place: p.Place,
	}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.UpsertPlayer(ctx, row)
	})
}

func (t *Table) audit(action, playerID string, details map[string]any) {
	row := store.AdminActionRow{TS: t.nowMs(), Action: action, TableID: t.ID, PlayerID: playerID, Details: marshalJSON(details)}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		return st.InsertAdminAction(ctx, row)
	})
}
