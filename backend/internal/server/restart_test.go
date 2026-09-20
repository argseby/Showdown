package server

import (
	"context"
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"github.com/coder/websocket"

	"showdown/internal/protocol"
)

// TestReconnectAfterServerRestart is the shape of the live bug report: a
// player sits at a table with bots, the server goes down and comes back up on
// the same data directory, and the browser reconnects with the token it still
// holds. It must get a welcome that names it a player in its seat — the
// client shows "Connecting..." and a spectator badge until one arrives.
func TestReconnectAfterServerRestart(t *testing.T) {
	dir := t.TempDir()

	h := newHarness(t, dir, "")
	tableID, adminToken := h.createTable(fastSettings())

	status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "chubby"})
	if status != http.StatusOK && status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, out)
	}
	token, _ := out["player_token"].(string)
	playerID, _ := out["player_id"].(string)

	for range 5 {
		if st, o := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", adminToken, nil); st != http.StatusOK && st != http.StatusCreated {
			t.Fatalf("add bot: %d %v", st, o)
		}
	}

	c := dialRaw(t, h, tableID, token, playerID)
	time.Sleep(2 * time.Second) // let a hand get under way, so the restart voids one
	_ = c.conn.CloseNow()

	h.stop()

	// Same data directory: this is the restart.
	h2 := newHarness(t, dir, "")
	defer h2.stop()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	conn, resp, err := websocket.Dial(ctx, "ws://"+h2.addr+"/ws/table/"+tableID, nil)
	if resp != nil && resp.Body != nil {
		_ = resp.Body.Close()
	}
	if err != nil {
		t.Fatalf("dial after restart: %v", err)
	}
	defer func() { _ = conn.CloseNow() }()

	c2 := &rawClient{t: t, conn: conn, id: playerID}
	c2.write(protocol.MustEncode(protocol.TypeHello, "hello-1", protocol.Hello{V: protocol.Version, Token: token}))
	env := c2.read(5 * time.Second)
	if env.Type != protocol.TypeWelcome {
		t.Fatalf("after restart: got %q, want a welcome", env.Type)
	}
	var w protocol.Welcome
	if err := json.Unmarshal(env.Payload, &w); err != nil {
		t.Fatal(err)
	}
	t.Logf("after restart: role=%q seat=%v player_id=%q", w.You.Role, w.You.Seat, w.You.PlayerID)
	if w.You.Role != "player" {
		t.Errorf("role %q after restart, want player", w.You.Role)
	}
	if w.You.Seat == nil || *w.You.Seat < 0 {
		t.Errorf("seat %v after restart, want the seat back", w.You.Seat)
	}
}
