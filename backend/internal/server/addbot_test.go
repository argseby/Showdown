package server

import (
	"net/http"
	"testing"
	"time"
)

// TestIntegrationAddBot covers the route behind the invite dialog's "add a
// bot" button: the host seats one, it plays by itself, and the host takes it
// away again with the same kick that removes anybody else.
func TestIntegrationAddBot(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in -short mode")
	}
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, token := h.createTable(fastSettings())

	// Only the host: the route is behind the table's admin token.
	if status, _ := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", "", nil); status != http.StatusUnauthorized {
		t.Fatalf("add bot without the admin token: %d", status)
	}
	if status, _ := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", "not-the-admin-token", nil); status != http.StatusUnauthorized {
		t.Fatalf("add bot with a wrong token: %d", status)
	}

	var ids []string
	for i := range 2 {
		status, out := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", token, nil)
		if status != http.StatusCreated {
			t.Fatalf("add bot %d: %d %v", i+1, status, out)
		}
		if want := "Bot " + string(rune('1'+i)); out["name"] != want {
			t.Errorf("name = %v, want %q", out["name"], want)
		}
		ids = append(ids, out["player_id"].(string))
	}

	// Two bots at an otherwise empty table play hands on their own, and the
	// seats report themselves as bots to everyone.
	waitUntil(t, 60*time.Second, "two hands between bots", func() bool {
		_, out := h.request(http.MethodGet, "/api/admin/tables/"+tableID, token, nil)
		return out["hand_number"].(float64) >= 2
	})
	_, detail := h.request(http.MethodGet, "/api/admin/tables/"+tableID, token, nil)
	players := detail["players"].([]any)
	if len(players) != 2 {
		t.Fatalf("players = %d, want 2", len(players))
	}
	for _, p := range players {
		pm := p.(map[string]any)
		if pm["bot"] != true {
			t.Errorf("%v: bot = %v, want true", pm["name"], pm["bot"])
		}
		if pm["connected"] != true {
			t.Errorf("%v: not connected; the bot did not attach", pm["name"])
		}
		if pm["missed_turns"].(float64) > 0 {
			t.Errorf("%v missed %v turns", pm["name"], pm["missed_turns"])
		}
	}

	// Kicking a bot is kicking a player: no separate route for it.
	if status, out := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/players/"+ids[0]+"/kick", token, nil); status != http.StatusOK {
		t.Fatalf("kick a bot: %d %v", status, out)
	}
	waitUntil(t, 30*time.Second, "the seat to clear", func() bool {
		_, out := h.request(http.MethodGet, "/api/admin/tables/"+tableID, token, nil)
		return len(out["players"].([]any)) == 1
	})
}

// TestIntegrationAddBotAtSeat covers the seat a host picks by clicking an
// empty seat at the table: the bot lands there and not in the lowest free
// seat, and a seat somebody already has is refused like any other join.
func TestIntegrationAddBotAtSeat(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in -short mode")
	}
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, token := h.createTable(fastSettings())

	status, out := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", token, map[string]any{"seat": 4})
	if status != http.StatusCreated {
		t.Fatalf("add bot at seat 4: %d %v", status, out)
	}
	if out["seat"].(float64) != 4 {
		t.Errorf("seat = %v, want 4", out["seat"])
	}

	// The same seat again: taken, like any other join of a full seat.
	if status, out := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", token, map[string]any{"seat": 4}); status != http.StatusConflict {
		t.Fatalf("add bot at a taken seat: %d %v", status, out)
	}

	// No seat in the body is still the lowest free one, the way the invite
	// dialog asks for it.
	if status, out := h.request(http.MethodPost, "/api/admin/tables/"+tableID+"/bots", token, nil); status != http.StatusCreated {
		t.Fatalf("add bot without a seat: %d %v", status, out)
	} else if out["seat"].(float64) != 0 {
		t.Errorf("seat = %v, want 0", out["seat"])
	}
}
