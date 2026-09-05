// Package botclient is a scripted player/spectator used by cmd/bot and the
// integration tests. It joins through the REST API, speaks the WebSocket
// protocol, acts on its options and watches for hole-card leaks.
package botclient

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"math/rand/v2"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/coder/websocket"

	"showdown/internal/protocol"
)

// Strategy selects how a bot acts on its turn.
type Strategy string

// Strategies.
const (
	StrategyRandom     Strategy = "random"     // mixed folds, calls, raises, all-ins
	StrategyPassive    Strategy = "passive"    // check when possible, else call
	StrategyAggressive Strategy = "aggressive" // raises and shoves often
	StrategyIdle       Strategy = "idle"       // never acts (turns time out)
)

// Role of the bot.
const (
	RolePlayer    = "player"
	RoleSpectator = "spectator"
	RoleAdmin     = "admin"
)

// Config configures a bot.
type Config struct {
	BaseURL  string // http://host:port
	TableID  string
	Name     string
	Password string
	Role     string   // player (default), spectator or admin
	Token    string   // existing token (admin token, or a stored session)
	Strategy Strategy // players only
	Seed     uint64
	Log      *slog.Logger
	// ActDelay is the pause before acting (simulates thinking).
	ActDelay time.Duration
	// Header is added to every REST request and WebSocket upgrade (for
	// example X-Forwarded-For in load tests behind TRUST_PROXY).
	Header http.Header
}

// ErrTerminal is returned by Run when the server closed the connection with
// a code that must not trigger a reconnect.
var ErrTerminal = errors.New("terminal close")

// Bot is one scripted client.
type Bot struct {
	cfg Config
	log *slog.Logger
	rng *rand.Rand

	Token    string
	PlayerID string
	Seat     int

	mu         sync.Mutex
	snapshot   *protocol.Snapshot
	handsEnded int
	handsSeen  map[int]bool
	violations []string
	revealed   map[int]bool
	lastActKey string
	reconnects int
	closeCode  int
	conn       *websocket.Conn
	seq        int
	idle       atomic.Bool

	// action -> snapshot latency measurement
	actionSentAt  time.Time
	actionSentKey string
	latencies     []time.Duration

	// OnSnapshot and OnEvents are optional observers.
	OnSnapshot func(protocol.Snapshot)
	OnEvents   func(protocol.EventsPayload)
}

// New creates a bot; call Join/Spectate (or set cfg.Token) before Run.
func New(cfg Config) *Bot {
	if cfg.Role == "" {
		cfg.Role = RolePlayer
	}
	if cfg.Strategy == "" {
		cfg.Strategy = StrategyRandom
	}
	if cfg.Log == nil {
		cfg.Log = slog.New(slog.DiscardHandler)
	}
	if cfg.Seed == 0 {
		cfg.Seed = uint64(time.Now().UnixNano())
	}
	return &Bot{
		cfg: cfg, log: cfg.Log.With("bot", cfg.Name), rng: rand.New(rand.NewPCG(cfg.Seed, cfg.Seed^0x9e3779b97f4a7c15)),
		Token: cfg.Token, Seat: -1, handsSeen: map[int]bool{}, revealed: map[int]bool{},
	}
}

// Name returns the display name.
func (b *Bot) Name() string { return b.cfg.Name }

func (b *Bot) postJSON(ctx context.Context, path string, body any, out any) error {
	buf, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimRight(b.cfg.BaseURL, "/")+path, bytes.NewReader(buf))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	for k, v := range b.cfg.Header {
		req.Header[k] = v
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 300 {
		return fmt.Errorf("%s: %d %s", path, resp.StatusCode, string(data))
	}
	return json.Unmarshal(data, out)
}

// Join takes a seat through the REST API.
func (b *Bot) Join(ctx context.Context) error {
	var res struct {
		Token    string `json:"player_token"`
		PlayerID string `json:"player_id"`
		Seat     int    `json:"seat"`
	}
	if err := b.postJSON(ctx, "/api/tables/"+b.cfg.TableID+"/join", map[string]string{"name": b.cfg.Name, "password": b.cfg.Password}, &res); err != nil {
		return err
	}
	b.Token, b.PlayerID, b.Seat = res.Token, res.PlayerID, res.Seat
	b.cfg.Role = RolePlayer
	return nil
}

// Spectate registers as a spectator.
func (b *Bot) Spectate(ctx context.Context) error {
	var res struct {
		Token string `json:"spectator_token"`
	}
	if err := b.postJSON(ctx, "/api/tables/"+b.cfg.TableID+"/spectate", map[string]string{"name": b.cfg.Name, "password": b.cfg.Password}, &res); err != nil {
		return err
	}
	b.Token = res.Token
	b.cfg.Role = RoleSpectator
	return nil
}

func (b *Bot) wsURL() string {
	base := strings.TrimRight(b.cfg.BaseURL, "/")
	switch {
	case strings.HasPrefix(base, "https://"):
		base = "wss://" + base[8:]
	case strings.HasPrefix(base, "http://"):
		base = "ws://" + base[7:]
	}
	return base + "/ws/table/" + b.cfg.TableID
}

// Run connects (reconnecting with backoff) until ctx ends or the server
// closes with a terminal code.
func (b *Bot) Run(ctx context.Context) error {
	backoff := 100 * time.Millisecond
	for {
		err := b.session(ctx)
		if ctx.Err() != nil {
			return nil
		}
		if errors.Is(err, ErrTerminal) {
			return err
		}
		b.log.Debug("connection lost; reconnecting", "err", err, "backoff", backoff)
		b.mu.Lock()
		b.reconnects++
		b.mu.Unlock()
		select {
		case <-ctx.Done():
			return nil
		case <-time.After(backoff + time.Duration(b.rng.Int64N(int64(backoff/2)+1))):
		}
		backoff = min(backoff*2, 2*time.Second)
	}
}

func (b *Bot) session(ctx context.Context) error {
	var opts *websocket.DialOptions
	if len(b.cfg.Header) > 0 {
		opts = &websocket.DialOptions{HTTPHeader: b.cfg.Header}
	}
	conn, resp, err := websocket.Dial(ctx, b.wsURL(), opts)
	if resp != nil && resp.Body != nil {
		_ = resp.Body.Close()
	}
	if err != nil {
		return err
	}
	conn.SetReadLimit(1 << 20)
	b.mu.Lock()
	b.conn = conn
	b.mu.Unlock()
	defer func() {
		b.mu.Lock()
		if b.conn == conn {
			b.conn = nil
		}
		b.mu.Unlock()
		_ = conn.CloseNow()
	}()

	if err := b.send(ctx, conn, protocol.TypeHello, protocol.Hello{V: protocol.Version, Token: b.Token}); err != nil {
		return err
	}
	b.mu.Lock()
	b.lastActKey = "" // act again if it is still our turn after a reconnect
	b.mu.Unlock()
	for {
		_, data, err := conn.Read(ctx)
		if err != nil {
			code := websocket.CloseStatus(err)
			b.mu.Lock()
			b.closeCode = int(code)
			b.mu.Unlock()
			switch code {
			case protocol.CloseBadToken, protocol.CloseUnsupportedVersion, protocol.CloseTableGone, protocol.CloseKicked:
				return fmt.Errorf("%w: %d", ErrTerminal, code)
			}
			return err
		}
		var env protocol.Envelope
		if err := json.Unmarshal(data, &env); err != nil {
			return err
		}
		if err := b.handle(ctx, conn, env); err != nil {
			return err
		}
	}
}

func (b *Bot) send(ctx context.Context, conn *websocket.Conn, typ string, payload any) error {
	b.mu.Lock()
	b.seq++
	id := fmt.Sprintf("b-%d", b.seq)
	b.mu.Unlock()
	env, err := protocol.Encode(typ, id, payload)
	if err != nil {
		return err
	}
	data, _ := json.Marshal(env)
	wctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	return conn.Write(wctx, websocket.MessageText, data)
}

// Send sends a command on the current connection (chat, rebuy, ...).
func (b *Bot) Send(ctx context.Context, typ string, payload any) error {
	b.mu.Lock()
	conn := b.conn
	b.mu.Unlock()
	if conn == nil {
		return errors.New("not connected")
	}
	return b.send(ctx, conn, typ, payload)
}

// Disconnect drops the current socket without telling the server; Run
// reconnects with the stored token.
func (b *Bot) Disconnect() {
	b.mu.Lock()
	conn := b.conn
	b.mu.Unlock()
	if conn != nil {
		_ = conn.CloseNow()
	}
}

func (b *Bot) handle(ctx context.Context, conn *websocket.Conn, env protocol.Envelope) error {
	switch env.Type {
	case protocol.TypeWelcome:
		var w protocol.Welcome
		if err := json.Unmarshal(env.Payload, &w); err != nil {
			return err
		}
		if w.You.Seat != nil {
			b.Seat = *w.You.Seat
		}
		b.learnRevealed(w.Snapshot)
		return b.onSnapshot(ctx, conn, w.Snapshot)
	case protocol.TypeSnapshot:
		var s protocol.Snapshot
		if err := json.Unmarshal(env.Payload, &s); err != nil {
			return err
		}
		return b.onSnapshot(ctx, conn, s)
	case protocol.TypeEvents:
		var p protocol.EventsPayload
		if err := json.Unmarshal(env.Payload, &p); err != nil {
			return err
		}
		b.onEvents(p)
	case protocol.TypeError:
		var e protocol.ErrorPayload
		_ = json.Unmarshal(env.Payload, &e)
		b.log.Debug("server error", "code", e.Code, "message", e.Message)
		b.mu.Lock()
		b.lastActKey = "" // allow a retry on the next snapshot
		b.mu.Unlock()
	case protocol.TypeKicked:
		b.log.Info("kicked")
	}
	return nil
}

// learnRevealed handles a welcome that arrives after a reconnect: if the
// hand has already reached the run-out, showdown or result phase, the
// hands_revealed event was sent while this client was away, and the welcome
// snapshot legitimately carries the revealed cards of the live seats. Those
// seats are marked revealed so that the leak check does not flag them.
func (b *Bot) learnRevealed(s protocol.Snapshot) {
	if s.Hand == nil {
		return
	}
	switch s.Hand.Phase {
	case "runout", "showdown", "result":
	default:
		return
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	for _, sv := range s.Seats {
		if sv.Player != nil && sv.Player.HoleCards != nil && sv.Player.InHand && !sv.Player.Folded {
			b.revealed[sv.Seat] = true
		}
	}
}

func (b *Bot) onEvents(p protocol.EventsPayload) {
	b.mu.Lock()
	for _, e := range p.Events {
		switch e.Kind {
		case "hand_started":
			b.revealed = map[int]bool{}
		case "hands_revealed":
			for _, r := range e.Reveals {
				b.revealed[r.Seat] = true
			}
		case "hand_ended":
			if !b.handsSeen[p.HandNumber] {
				b.handsSeen[p.HandNumber] = true
				b.handsEnded++
			}
		case "hole_cards_dealt":
			if e.Cards != nil && (b.cfg.Role != RolePlayer || e.Seat == nil || *e.Seat != b.Seat) {
				b.violations = append(b.violations, fmt.Sprintf("%s (%s) received hole cards of seat %v in events", b.cfg.Name, b.cfg.Role, e.Seat))
			}
		}
	}
	b.mu.Unlock()
	if b.OnEvents != nil {
		b.OnEvents(p)
	}
}

func (b *Bot) onSnapshot(ctx context.Context, conn *websocket.Conn, s protocol.Snapshot) error {
	b.mu.Lock()
	b.snapshot = &s
	if s.You.Seat != nil {
		b.Seat = *s.You.Seat
	}
	if !b.actionSentAt.IsZero() && (s.You.Options == nil || s.Hand == nil || turnKey(s) != b.actionSentKey) {
		// First snapshot that reflects our action (the turn moved on).
		b.latencies = append(b.latencies, time.Since(b.actionSentAt))
		b.actionSentAt = time.Time{}
	}
	for _, sv := range s.Seats {
		if sv.Player == nil || sv.Player.HoleCards == nil {
			continue
		}
		own := b.cfg.Role == RolePlayer && sv.Seat == b.Seat
		if !own && !b.revealed[sv.Seat] {
			b.violations = append(b.violations, fmt.Sprintf("%s (%s) sees hole cards of seat %d in a snapshot", b.cfg.Name, b.cfg.Role, sv.Seat))
		}
	}
	b.mu.Unlock()
	if b.OnSnapshot != nil {
		b.OnSnapshot(s)
	}
	if b.cfg.Role != RolePlayer {
		return nil
	}
	if s.You.CanRebuy {
		return b.send(ctx, conn, protocol.TypeRebuy, struct{}{})
	}
	if s.You.Options == nil || s.Hand == nil || b.cfg.Strategy == StrategyIdle || b.idle.Load() {
		return nil
	}
	key := turnKey(s)
	b.mu.Lock()
	if b.lastActKey == key {
		b.mu.Unlock()
		return nil
	}
	b.lastActKey = key
	b.mu.Unlock()
	if b.cfg.ActDelay > 0 {
		select {
		case <-ctx.Done():
			return nil
		case <-time.After(b.cfg.ActDelay):
		}
	}
	action := b.decide(*s.You.Options, s)
	b.mu.Lock()
	b.actionSentAt, b.actionSentKey = time.Now(), key
	b.mu.Unlock()
	return b.send(ctx, conn, protocol.TypeAction, action)
}

// turnKey identifies one turn: hand, street and deadline change whenever
// the action moves on.
func turnKey(s protocol.Snapshot) string {
	return fmt.Sprintf("%d/%s/%v", s.Table.HandNumber, s.Hand.Street, deref(s.Hand.DeadlineTS))
}

func deref(p *int64) int64 {
	if p == nil {
		return 0
	}
	return *p
}

func (b *Bot) decide(o protocol.OptionsView, s protocol.Snapshot) protocol.ActionPayload {
	checkOrCall := func() protocol.ActionPayload {
		if o.Check {
			return protocol.ActionPayload{Kind: "check"}
		}
		if o.Call > 0 {
			return protocol.ActionPayload{Kind: "call"}
		}
		return protocol.ActionPayload{Kind: "fold"}
	}
	raise := func() protocol.ActionPayload {
		if o.Raise == nil {
			if o.AllIn > 0 {
				return protocol.ActionPayload{Kind: "all_in"}
			}
			return checkOrCall()
		}
		amount := o.Raise.Min
		if o.Raise.Max > o.Raise.Min && b.rng.IntN(3) == 0 {
			amount += b.rng.Int64N(o.Raise.Max - o.Raise.Min + 1)
		}
		bb := s.Table.Settings.BigBlind
		if bb > 0 && amount < o.Raise.Max {
			amount = min(o.Raise.Max, max(o.Raise.Min, amount/bb*bb))
		}
		return protocol.ActionPayload{Kind: "raise", Amount: amount}
	}
	switch b.cfg.Strategy {
	case StrategyPassive:
		return checkOrCall()
	case StrategyAggressive:
		switch r := b.rng.IntN(100); {
		case r < 10 && o.AllIn > 0:
			return protocol.ActionPayload{Kind: "all_in"}
		case r < 60:
			return raise()
		default:
			return checkOrCall()
		}
	default:
		switch r := b.rng.IntN(100); {
		case r < 15 && !o.Check:
			return protocol.ActionPayload{Kind: "fold"}
		case r < 20 && o.AllIn > 0:
			return protocol.ActionPayload{Kind: "all_in"}
		case r < 45:
			return raise()
		default:
			return checkOrCall()
		}
	}
}

// SetIdle stops (true) or resumes (false) acting on the bot's turns; while
// idle its turns time out on the server.
func (b *Bot) SetIdle(idle bool) {
	b.idle.Store(idle)
	if !idle {
		b.mu.Lock()
		b.lastActKey = ""
		b.mu.Unlock()
	}
}

// Snapshot returns the latest snapshot (nil before the welcome).
func (b *Bot) Snapshot() *protocol.Snapshot {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.snapshot == nil {
		return nil
	}
	s := *b.snapshot
	return &s
}

// HandsEnded counts distinct hands whose hand_ended event this bot saw.
func (b *Bot) HandsEnded() int {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.handsEnded
}

// Latencies returns the measured action -> snapshot round trips (time from
// sending an action until the first snapshot in which the turn moved on)
// and clears the buffer.
func (b *Bot) Latencies() []time.Duration {
	b.mu.Lock()
	defer b.mu.Unlock()
	out := b.latencies
	b.latencies = nil
	return out
}

// Violations lists observed hole-card leaks.
func (b *Bot) Violations() []string {
	b.mu.Lock()
	defer b.mu.Unlock()
	return append([]string{}, b.violations...)
}

// Reconnects counts reconnections performed by Run.
func (b *Bot) Reconnects() int {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.reconnects
}

// CloseCode is the last close status seen.
func (b *Bot) CloseCode() int {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.closeCode
}
