package server

import (
	"net/http"
	"testing"
)

func TestRoyalHoldemTable(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "")

	// The default seat count does not fit the 20-card deck.
	status, out := h.request(http.MethodPost, "/api/tables", "", map[string]any{
		"name": "Royal", "settings": map[string]any{"variant": "royal"},
	})
	if status != http.StatusBadRequest {
		t.Fatalf("royal with 9 seats: %d %v", status, out)
	}
	if e, _ := out["error"].(map[string]any); e["field"] != "max_players" {
		t.Fatalf("error = %v", out["error"])
	}

	settings := fastSettings()
	settings["variant"] = "royal"
	id, token := h.createTable(settings)
	status, out = h.request(http.MethodGet, "/api/tables/"+id+"/info", "", nil)
	if status != http.StatusOK || out["variant"] != "royal" {
		t.Fatalf("info: %d %v", status, out)
	}

	// Back to hold'em from the next hand on.
	status, out = h.request(http.MethodPatch, "/api/admin/tables/"+id+"/settings", token, map[string]any{"variant": "holdem"})
	if status != http.StatusOK {
		t.Fatalf("patch: %d %v", status, out)
	}
	next, _ := out["applies_next_hand"].([]any)
	if len(next) != 1 || next[0] != "variant" {
		t.Fatalf("applies_next_hand = %v", out["applies_next_hand"])
	}
	if st, _ := out["settings"].(map[string]any); st["variant"] != "holdem" {
		t.Fatalf("settings = %v", out["settings"])
	}
}
