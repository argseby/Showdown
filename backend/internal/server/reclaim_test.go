package server

import (
	"net/http"
	"testing"
)

// A profile that already holds a seat gets that seat back instead of a
// second one. Without this a player who lost the token of their session
// finds their own name taken — by their own seat — and has no way back to
// the table at all.
func TestJoinHandsBackTheSeatOfTheProfile(t *testing.T) {
	h := newHarness(t, t.TempDir(), "", map[string]string{"ACCOUNTS": "true"})
	defer h.stop()

	token := signUp(t, h, "robin")
	id, _ := h.createTable(fastSettings())

	status, first := h.request(http.MethodPost, "/api/tables/"+id+"/join", token,
		map[string]any{"name": "Robin"})
	if status != http.StatusCreated {
		t.Fatalf("join: %d %v", status, first)
	}

	// The browser forgot its session. The player comes back and types a
	// different name, because their own is "taken".
	status, again := h.request(http.MethodPost, "/api/tables/"+id+"/join", token,
		map[string]any{"name": "Someone Else"})
	if status != http.StatusOK || again["reclaimed"] != true {
		t.Fatalf("coming back: %d %v", status, again)
	}
	if again["player_id"] != first["player_id"] || again["seat"] != first["seat"] {
		t.Fatalf("a different seat came back: %v, want %v", again, first)
	}
	if again["name"] != "Robin" {
		t.Fatalf("the seat was renamed to %v", again["name"])
	}
	if again["player_token"] == first["player_token"] {
		t.Fatal("the old token came back; the point is a fresh one")
	}
	// One player, not two: the seat was handed over, not added to.
	status, info := h.request(http.MethodGet, "/api/tables/"+id+"/info", "", nil)
	if seated, _ := info["seated"].(float64); status != http.StatusOK || seated != 1 {
		t.Fatalf("seated: %d %v", status, info)
	}
}

// A guest has no identity to recognise, so the name of a seated player
// stays taken. Nothing to hand back, and nothing quietly taken over.
func TestJoinStillRefusesATakenNameForGuests(t *testing.T) {
	h := newHarness(t, t.TempDir(), "", map[string]string{"ACCOUNTS": "true"})
	defer h.stop()

	id, _ := h.createTable(fastSettings())
	if status, out := h.request(http.MethodPost, "/api/tables/"+id+"/join", "",
		map[string]any{"name": "Robin"}); status != http.StatusCreated {
		t.Fatalf("first guest: %d %v", status, out)
	}
	status, out := h.request(http.MethodPost, "/api/tables/"+id+"/join", "",
		map[string]any{"name": "Robin"})
	if status != http.StatusConflict {
		t.Fatalf("second guest: %d %v", status, out)
	}
}

// The seat belongs to the profile, not to the name: a player who signed in
// elsewhere gets their seat even when somebody else is sitting there under
// a name of their own.
func TestReclaimIgnoresTheSeatOfAnotherProfile(t *testing.T) {
	h := newHarness(t, t.TempDir(), "", map[string]string{"ACCOUNTS": "true"})
	defer h.stop()

	robin := signUp(t, h, "robin")
	alex := signUp(t, h, "alex")
	id, _ := h.createTable(fastSettings())

	_, first := h.request(http.MethodPost, "/api/tables/"+id+"/join", robin,
		map[string]any{"name": "Robin"})
	status, other := h.request(http.MethodPost, "/api/tables/"+id+"/join", alex,
		map[string]any{"name": "Alex"})
	if status != http.StatusCreated || other["reclaimed"] == true {
		t.Fatalf("a second profile must get a seat of its own: %d %v", status, other)
	}
	if other["player_id"] == first["player_id"] {
		t.Fatal("two profiles ended up on one seat")
	}
}
