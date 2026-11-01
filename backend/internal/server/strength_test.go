package server

import (
	"net/http"
	"testing"
	"time"
)

// seatTwoAndDeal joins two players and waits for a hand, which is what the
// strength endpoint needs before it has anything to say.
func seatTwoAndDeal(t *testing.T, h *harness) (tableID string, alice map[string]any) {
	t.Helper()
	tableID, _ = h.createTable(fastSettings())
	for _, name := range []string{"alice", "bob"} {
		status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": name})
		if status != http.StatusCreated {
			t.Fatalf("join %s: %d %v", name, status, out)
		}
		if name == "alice" {
			alice = out
		}
	}
	// Both are dealt in as soon as the table starts; the endpoint answers
	// once there is a hand.
	waitUntil(t, 5*time.Second, "a hand to read", func() bool {
		status, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", alice["player_token"].(string), nil)
		return status == http.StatusOK
	})
	return tableID, alice
}

func TestStrengthReadsTheCallersOwnHand(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, alice := seatTwoAndDeal(t, h)

	status, out := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", alice["player_token"].(string), nil)
	if status != http.StatusOK {
		t.Fatalf("strength: %d %v", status, out)
	}
	cards, _ := out["cards"].([]any)
	if len(cards) != 2 {
		t.Errorf("cards = %v, want the caller's two", out["cards"])
	}
	if out["description"] == "" {
		t.Error("no description")
	}
	if _, ok := out["tier"].(string); !ok {
		t.Errorf("tier = %v, want a word", out["tier"])
	}
	// Whoever is to act is offered a line; the other player is not, and
	// neither is told anything about the other's cards.
	if adv, ok := out["advice"].(map[string]any); ok {
		if adv["action"] == "" {
			t.Error("advice without an action")
		}
		if eq, _ := out["equity"].(float64); eq <= 0 || eq > 1 {
			t.Errorf("equity = %v, want a share of the pot", out["equity"])
		}
	}
}

func TestStrengthNeedsAPlayerTokenOfThisTable(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, _ := seatTwoAndDeal(t, h)

	for _, token := range []string{"", "nonsense"} {
		status, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", token, nil)
		if status != http.StatusUnauthorized {
			t.Errorf("token %q: status %d, want 401", token, status)
		}
	}
	// A spectator holds a session of this table and still gets nothing:
	// there are no cards of their own to read.
	status, spec := h.request(http.MethodPost, "/api/tables/"+tableID+"/spectate", "", map[string]any{"name": "watcher"})
	if status != http.StatusCreated {
		t.Fatalf("spectate: %d %v", status, spec)
	}
	if status, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", spec["spectator_token"].(string), nil); status != http.StatusUnauthorized {
		t.Errorf("spectator: status %d, want 401", status)
	}
}

// The host's switch decides whether a line is offered; the reading of the
// player's own hand is theirs either way.
func TestStrengthWithoutAdviceStillReadsTheHand(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	settings := fastSettings()
	settings["allow_advice"] = false
	tableID, _ := h.createTable(settings)
	status, alice := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "alice"})
	if status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, alice)
	}
	if status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "bob"}); status != http.StatusCreated {
		t.Fatalf("join bob: %d %v", status, out)
	}
	token := alice["player_token"].(string)
	waitUntil(t, 5*time.Second, "a hand to read", func() bool {
		status, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", token, nil)
		return status == http.StatusOK
	})
	_, out := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", token, nil)
	if _, has := out["advice"]; has {
		t.Errorf("advice offered at a table that switched it off: %v", out["advice"])
	}
	if out["description"] == "" {
		t.Error("the hand itself must still be described")
	}
}

// PLAYER_ADVICE=false: the reading still comes back, the line does not.
func TestStrengthWithoutInstanceAdvice(t *testing.T) {
	h := newHarness(t, t.TempDir(), "", map[string]string{"PLAYER_ADVICE": "false"})
	defer h.stop()
	tableID, _ := h.createTable(fastSettings())
	status, alice := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "alice"})
	if status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, alice)
	}
	if status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "bob"}); status != http.StatusCreated {
		t.Fatalf("join bob: %d %v", status, out)
	}
	token := alice["player_token"].(string)
	waitUntil(t, 5*time.Second, "a hand to read", func() bool {
		status, _ := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", token, nil)
		return status == http.StatusOK
	})
	_, out := h.request(http.MethodGet, "/api/tables/"+tableID+"/strength", token, nil)
	if _, has := out["advice"]; has {
		t.Errorf("advice on an instance that refuses it: %v", out["advice"])
	}
	if out["description"] == "" {
		t.Error("the player's own hand must still be read back")
	}
}
