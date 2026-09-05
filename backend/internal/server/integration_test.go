package server

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"sync"
	"testing"
	"time"

	"showdown/internal/botclient"
	"showdown/internal/config"
	"showdown/internal/protocol"
	"showdown/internal/store"
	"showdown/internal/table"
)

// harness boots the whole server on a loopback port.
type harness struct {
	t    *testing.T
	dir  string
	addr string
	st   *store.Store
	reg  *table.Registry
	srv  *httptest.Server
	base string
}

func newHarness(t *testing.T, dir, addr string) *harness {
	t.Helper()
	// Warnings and errors of the server under test are kept in memory and
	// printed only when the test fails; SHOWDOWN_TEST_LOG streams everything.
	var logBuf syncBuffer
	log := slog.New(slog.NewTextHandler(&logBuf, &slog.HandlerOptions{Level: slog.LevelWarn}))
	if os.Getenv("SHOWDOWN_TEST_LOG") != "" {
		log = slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelDebug}))
	}
	t.Cleanup(func() {
		if t.Failed() && logBuf.Len() > 0 {
			t.Logf("server log:\n%s", logBuf.String())
		}
	})
	st, err := store.Open(context.Background(), dir, log)
	if err != nil {
		t.Fatal(err)
	}
	reg := table.NewRegistry(table.Deps{Store: st, Log: log, Delays: table.Delays{
		Street: 20 * time.Millisecond, Runout: 20 * time.Millisecond, Showdown: 50 * time.Millisecond,
	}}, 10)
	if err := reg.LoadAll(context.Background()); err != nil {
		t.Fatal(err)
	}
	cfg, err := config.Load(func(k string) string {
		switch k {
		case "TRUST_PROXY":
			return "false"
		case "LOG_FORMAT":
			return "text"
		}
		return ""
	})
	if err != nil {
		t.Fatal(err)
	}
	s := New(cfg, st, reg, log)
	if addr == "" {
		addr = "127.0.0.1:0"
	}
	var l net.Listener
	for attempt := 0; attempt < 50; attempt++ {
		l, err = net.Listen("tcp", addr)
		if err == nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	if err != nil {
		t.Fatalf("listen %s: %v", addr, err)
	}
	srv := httptest.NewUnstartedServer(s.Handler())
	srv.Listener = l
	srv.Start()
	return &harness{t: t, dir: dir, addr: l.Addr().String(), st: st, reg: reg, srv: srv, base: "http://" + l.Addr().String()}
}

// stop shuts everything down the way main() does on SIGTERM.
func (h *harness) stop() {
	h.t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	h.srv.Config.SetKeepAlivesEnabled(false)
	_ = h.srv.Config.Shutdown(ctx)
	h.reg.Shutdown(ctx)
	h.srv.Listener.Close()
	_ = h.st.Close()
}

func (h *harness) request(method, path, token string, body any) (int, map[string]any) {
	h.t.Helper()
	var rd io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		rd = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, h.base+path, rd)
	if err != nil {
		h.t.Fatal(err)
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		h.t.Fatal(err)
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	var out map[string]any
	if len(data) > 0 {
		if err := json.Unmarshal(data, &out); err != nil {
			h.t.Fatalf("%s %s: invalid JSON %q", method, path, data)
		}
	}
	return resp.StatusCode, out
}

// createTable creates a table through the public route and returns its id
// and the admin token handed to the creator.
func (h *harness) createTable(settings map[string]any) (string, string) {
	h.t.Helper()
	status, out := h.request(http.MethodPost, "/api/tables", "", map[string]any{"name": "Integration", "settings": settings})
	if status != http.StatusCreated {
		h.t.Fatalf("create table: %d %v", status, out)
	}
	return out["id"].(string), out["admin_token"].(string)
}

func fastSettings() map[string]any {
	return map[string]any{
		"turn_time": 5, "disconnected_turn_time": 3, "hand_delay_ms": 2000, "start_money": 3000,
		"small_blind": 50, "big_blind": 100, "sit_out_after_missed_turns": 3, "max_players": 6,
	}
}

type botSet struct {
	players []*botclient.Bot
	others  []*botclient.Bot
	wg      sync.WaitGroup
	errs    sync.Map
}

func (bs *botSet) start(ctx context.Context) {
	for _, b := range append(append([]*botclient.Bot{}, bs.players...), bs.others...) {
		bs.wg.Add(1)
		go func() {
			defer bs.wg.Done()
			if err := b.Run(ctx); err != nil {
				bs.errs.Store(b.Name(), err)
			}
		}()
	}
}

func (bs *botSet) all() []*botclient.Bot {
	return append(append([]*botclient.Bot{}, bs.players...), bs.others...)
}

func waitUntil(t *testing.T, timeout time.Duration, what string, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if cond() {
			return
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatalf("timed out after %s waiting for %s", timeout, what)
}

// netSum returns the sum of stack - buy_in over all seated players via the
// admin API; it must be zero between hands (chip conservation).
func (h *harness) netSum(token, tableID string) (int64, string) {
	h.t.Helper()
	status, out := h.request(http.MethodGet, "/api/admin/tables/"+tableID, token, nil)
	if status != http.StatusOK {
		h.t.Fatalf("get table: %d %v", status, out)
	}
	var sum int64
	for _, p := range out["players"].([]any) {
		pm := p.(map[string]any)
		sum += int64(pm["stack"].(float64)) - int64(pm["buy_in_total"].(float64))
	}
	return sum, out["state"].(string)
}

func TestIntegrationBotsPlayHands(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in -short mode")
	}
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, token := h.createTable(fastSettings())

	// Public REST checks.
	status, info := h.request(http.MethodGet, "/api/tables/"+tableID+"/info", "", nil)
	if status != http.StatusOK || info["name"] != "Integration" || info["state"] != "waiting" {
		t.Fatalf("info: %d %v", status, info)
	}
	if status, _ := h.request(http.MethodGet, "/api/tables/nope/info", "", nil); status != http.StatusNotFound {
		t.Fatalf("missing table info: %d", status)
	}
	if status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]string{"name": "x!"}); status != http.StatusBadRequest || out["error"].(map[string]any)["code"] != "invalid_name" {
		t.Fatalf("invalid name join: %d %v", status, out)
	}
	if status, _ := h.request(http.MethodGet, "/api/admin/tables/"+tableID, "", nil); status != http.StatusUnauthorized {
		t.Fatalf("admin without token: %d", status)
	}
	if status, _ := h.request(http.MethodGet, "/api/admin/tables/"+tableID, "not-the-admin-token", nil); status != http.StatusUnauthorized {
		t.Fatalf("admin with wrong token: %d", status)
	}
	otherID, otherToken := h.createTable(fastSettings())
	if status, _ := h.request(http.MethodGet, "/api/admin/tables/"+tableID, otherToken, nil); status != http.StatusUnauthorized {
		t.Fatalf("admin token of another table accepted: %d", status)
	}
	if status, _ := h.request(http.MethodDelete, "/api/admin/tables/"+otherID, otherToken, nil); status != http.StatusOK {
		t.Fatalf("delete other table: %d", status)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var bs botSet
	strategies := []botclient.Strategy{botclient.StrategyRandom, botclient.StrategyAggressive, botclient.StrategyPassive, botclient.StrategyRandom}
	for i, st := range strategies {
		b := botclient.New(botclient.Config{BaseURL: h.base, TableID: tableID, Name: fmt.Sprintf("Bot%d", i+1), Strategy: st, Seed: uint64(i + 1)})
		if err := b.Join(ctx); err != nil {
			t.Fatal(err)
		}
		bs.players = append(bs.players, b)
	}
	spectator := botclient.New(botclient.Config{BaseURL: h.base, TableID: tableID, Name: "Watcher"})
	if err := spectator.Spectate(ctx); err != nil {
		t.Fatal(err)
	}
	admin := botclient.New(botclient.Config{BaseURL: h.base, TableID: tableID, Name: "admin", Role: botclient.RoleAdmin, Token: token})
	var evMu sync.Mutex
	kinds := map[string]int{}
	admin.OnEvents = func(p protocol.EventsPayload) {
		evMu.Lock()
		defer evMu.Unlock()
		for _, e := range p.Events {
			kinds[e.Kind]++
			if e.Kind == "action" && e.AllIn != nil && *e.AllIn {
				kinds["all_in"]++
			}
		}
	}
	seen := func(kind string) int {
		evMu.Lock()
		defer evMu.Unlock()
		return kinds[kind]
	}
	bs.others = []*botclient.Bot{spectator, admin}
	bs.start(ctx)

	waitUntil(t, 60*time.Second, "three hands", func() bool { return admin.HandsEnded() >= 3 })

	// Timeout: one bot stops acting until the server times its turn out.
	bs.players[2].SetIdle(true)
	waitUntil(t, 30*time.Second, "a timeout event", func() bool { return seen("timeout") >= 1 })
	bs.players[2].SetIdle(false)

	// Kill a connection mid-hand; the bot reconnects with its token.
	waitUntil(t, 60*time.Second, "a hand in progress", func() bool {
		s := bs.players[0].Snapshot()
		return s != nil && s.Hand != nil && s.Hand.Phase == "betting"
	})
	bs.players[0].Disconnect()
	waitUntil(t, 20*time.Second, "reconnect", func() bool {
		s := bs.players[0].Snapshot()
		return bs.players[0].Reconnects() >= 1 && s != nil
	})

	waitUntil(t, 180*time.Second, "20 hands", func() bool { return admin.HandsEnded() >= 20 })
	if seen("all_in") == 0 {
		t.Error("no all-in observed")
	}
	if seen("hands_revealed") == 0 || seen("pot_awarded") == 0 {
		t.Errorf("expected showdowns: %v", kinds)
	}

	// End after the current hand, then verify the books.
	if status, out := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/end", token, map[string]bool{"immediate": false}); status != http.StatusOK {
		t.Fatalf("end: %d %v", status, out)
	}
	waitUntil(t, 60*time.Second, "table ended", func() bool { _, state := h.netSum(token, tableID); return state == "ended" })
	if sum, _ := h.netSum(token, tableID); sum != 0 {
		t.Fatalf("chips not conserved: net sum %d", sum)
	}
	for _, b := range bs.all() {
		waitUntil(t, 10*time.Second, b.Name()+" closed", func() bool {
			_, ok := bs.errs.Load(b.Name())
			return ok
		})
		if v, _ := bs.errs.Load(b.Name()); !errors.Is(v.(error), botclient.ErrTerminal) || b.CloseCode() != protocol.CloseTableGone {
			t.Errorf("%s ended with %v (close %d)", b.Name(), v, b.CloseCode())
		}
		if v := b.Violations(); len(v) > 0 {
			t.Errorf("%s: hole card leaks: %v", b.Name(), v)
		}
	}
	cancel()
	bs.wg.Wait()

	status, hands := h.request(http.MethodGet, "/api/admin/tables/"+tableID+"/hands?limit=100", token, nil)
	if status != http.StatusOK || len(hands["hands"].([]any)) < 20 {
		var numbers []float64
		for _, hv := range hands["hands"].([]any) {
			numbers = append(numbers, hv.(map[string]any)["number"].(float64))
		}
		t.Fatalf("hands: %d, %d rows (admin saw %d hand_ended events), numbers %v", status, len(numbers), admin.HandsEnded(), numbers)
	}
	first := hands["hands"].([]any)[len(hands["hands"].([]any))-1].(map[string]any)
	if first["number"].(float64) != 1 || first["results"] == nil {
		t.Fatalf("hand 1 = %v", first)
	}
	status, detail := h.request(http.MethodGet, "/api/admin/tables/"+tableID, token, nil)
	if status != http.StatusOK || len(detail["players"].([]any)) != 4 {
		t.Fatalf("final standings: %d %v", status, detail)
	}
	// Hand history for a player: hole cards only for their own seat and for
	// seats revealed in that hand (the admin gets no unrevealed cards either).
	checkHands := func(who string, viewerSeat int, hands map[string]any) {
		t.Helper()
		seenOwn := false
		for _, hv := range hands["hands"].([]any) {
			hm := hv.(map[string]any)
			revealed := map[int]bool{}
			if res, ok := hm["results"].(map[string]any); ok {
				for seat, sr := range res["seats"].(map[string]any) {
					if sr.(map[string]any)["revealed"] == true {
						n, _ := strconv.Atoi(seat)
						revealed[n] = true
					}
				}
			}
			for _, ev := range hm["events"].([]any) {
				e := ev.(map[string]any)
				if e["kind"] != "hole_cards_dealt" {
					continue
				}
				seat := int(e["seat"].(float64))
				_, hasCards := e["cards"]
				if seat == viewerSeat && hasCards {
					seenOwn = true
				}
				if hasCards && seat != viewerSeat && !revealed[seat] {
					t.Fatalf("%s sees hole cards of seat %d in hand %v", who, seat, hm["number"])
				}
			}
		}
		if viewerSeat >= 0 && !seenOwn {
			t.Fatalf("%s never sees their own hole cards", who)
		}
	}
	status, playerHands := h.request(http.MethodGet, "/api/tables/"+tableID+"/hands?limit=100", bs.players[1].Token, nil)
	if status != http.StatusOK {
		t.Fatalf("player hands: %d %v", status, playerHands)
	}
	checkHands("player", bs.players[1].Seat, playerHands)
	checkHands("admin", -1, hands)
	if status, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/hands", "bogus", nil); status != http.StatusUnauthorized {
		t.Fatalf("hands without session: %d", status)
	}
	if status, _ := h.request(http.MethodDelete, "/api/admin/tables/"+tableID, token, nil); status != http.StatusOK {
		t.Fatalf("delete ended table: %d", status)
	}
}

// TestIntegrationRestartNoChipsLost is the M2 acceptance run: six bots play
// through a server restart. SHOWDOWN_ACCEPTANCE_HANDS sets the hand count
// (default 12; the acceptance criterion is 100).
func TestIntegrationRestartNoChipsLost(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in -short mode")
	}
	hands := 12
	if v := os.Getenv("SHOWDOWN_ACCEPTANCE_HANDS"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			t.Fatal(err)
		}
		hands = n
	}
	dir := t.TempDir()
	h := newHarness(t, dir, "")
	settings := fastSettings()
	settings["max_players"] = 6
	tableID, token := h.createTable(settings)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var bs botSet
	for i := 0; i < 6; i++ {
		st := botclient.StrategyRandom
		if i%3 == 1 {
			st = botclient.StrategyAggressive
		}
		b := botclient.New(botclient.Config{BaseURL: h.base, TableID: tableID, Name: fmt.Sprintf("Bot%d", i+1), Strategy: st, Seed: uint64(100 + i)})
		if err := b.Join(ctx); err != nil {
			t.Fatal(err)
		}
		bs.players = append(bs.players, b)
	}
	admin := botclient.New(botclient.Config{BaseURL: h.base, TableID: tableID, Name: "admin", Role: botclient.RoleAdmin, Token: token})
	bs.others = []*botclient.Bot{admin}
	bs.start(ctx)

	half := hands / 2
	waitUntil(t, time.Duration(half+1)*15*time.Second, "first half", func() bool { return bs.players[0].HandsEnded() >= half })

	// Restart in the middle of a hand: every bot stops acting so the hand
	// stalls in the betting phase, then a graceful shutdown and a fresh
	// process on the same address and database.
	for _, b := range bs.players {
		b.SetIdle(true)
	}
	waitUntil(t, 60*time.Second, "hand in progress", func() bool {
		s := bs.players[0].Snapshot()
		return s != nil && s.Hand != nil && s.Hand.Phase == "betting" && s.Hand.ToActSeat != nil
	})
	before, _ := h.netSum(token, tableID)
	addr := h.addr
	h.stop()
	h2 := newHarness(t, dir, addr)
	defer h2.stop()
	// The admin token survives the restart: its hash is stored with the table.
	token2 := token
	for _, b := range bs.players {
		b.SetIdle(false)
	}
	waitUntil(t, 30*time.Second, "bots reconnected", func() bool {
		for _, b := range bs.players {
			if b.Reconnects() == 0 {
				return false
			}
		}
		return true
	})
	sum, state := h2.netSum(token2, tableID)
	if sum != 0 || state != "running" {
		t.Fatalf("after restart: net %d (before %d), state %s", sum, before, state)
	}
	status, list := h2.request(http.MethodGet, "/api/admin/tables/"+tableID+"/hands?limit=5", token2, nil)
	if status != http.StatusOK {
		t.Fatal(status)
	}
	newest := list["hands"].([]any)[0].(map[string]any)
	if newest["voided"] != true {
		t.Fatalf("the interrupted hand must be voided: %v", newest)
	}

	waitUntil(t, time.Duration(hands-half+2)*15*time.Second, "all hands", func() bool { return bs.players[0].HandsEnded() >= hands })
	if status, out := h2.request(http.MethodPost, "/api/admin/tables/"+tableID+"/end", token2, map[string]bool{"immediate": false}); status != http.StatusOK {
		t.Fatalf("end: %d %v", status, out)
	}
	waitUntil(t, 60*time.Second, "ended", func() bool { _, st := h2.netSum(token2, tableID); return st == "ended" })
	if sum, _ := h2.netSum(token2, tableID); sum != 0 {
		t.Fatalf("chips lost across restart: net sum %d", sum)
	}
	for _, b := range bs.all() {
		if v := b.Violations(); len(v) > 0 {
			t.Errorf("%s: %v", b.Name(), v)
		}
	}
	cancel()
	bs.wg.Wait()
	t.Logf("played %d hands with a restart after %d", bs.players[0].HandsEnded(), half)
}

// syncBuffer is a goroutine-safe bytes.Buffer for the captured server log.
type syncBuffer struct {
	mu  sync.Mutex
	buf bytes.Buffer
}

func (b *syncBuffer) Write(p []byte) (int, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.buf.Write(p)
}

func (b *syncBuffer) Len() int {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.buf.Len()
}

func (b *syncBuffer) String() string {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.buf.String()
}
