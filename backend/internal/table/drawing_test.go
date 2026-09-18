package table

import (
	"encoding/json"
	"errors"
	"testing"

	"showdown/internal/protocol"
)

func strokesOf(t *testing.T, conn *fakeConn) (added []protocol.Stroke, removed []protocol.DrawingsRemoved) {
	t.Helper()
	for _, m := range conn.all() {
		switch m.Type {
		case protocol.TypeDrawing:
			var s protocol.Stroke
			if err := json.Unmarshal(m.Payload, &s); err != nil {
				t.Fatal(err)
			}
			added = append(added, s)
		case protocol.TypeDrawingsRemoved:
			var r protocol.DrawingsRemoved
			if err := json.Unmarshal(m.Payload, &r); err != nil {
				t.Fatal(err)
			}
			removed = append(removed, r)
		}
	}
	return added, removed
}

func TestDrawings(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.AutoStart = false
	tbl := newTestTable(t, s)
	a, connA := join(t, tbl, "Alice")
	b, connB := join(t, tbl, "Bob")
	alice := &Client{Conn: connA, Role: RolePlayer, PlayerID: a.PlayerID}
	bob := &Client{Conn: connB, Role: RolePlayer, PlayerID: b.PlayerID}
	if err := tbl.Draw(alice, []float64{0.1, 0.2, 0.3, 0.4}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "stroke at Bob", func() bool { add, _ := strokesOf(t, connB); return len(add) == 1 })
	add, _ := strokesOf(t, connB)
	if add[0].PlayerID != a.PlayerID || add[0].Name != "Alice" || len(add[0].Points) != 4 || add[0].ID == 0 {
		t.Fatalf("stroke = %+v", add[0])
	}
	// Bad strokes: odd count, out of range, too many points, spectators, muted.
	for _, pts := range [][]float64{{0.1}, {0.1, 1.5}, make([]float64, 2*protocol.MaxStrokePoints+2)} {
		if err := tbl.Draw(alice, pts); !errors.Is(err, ErrIllegalAction) {
			t.Fatalf("points %d: %v", len(pts), err)
		}
	}
	if err := tbl.Draw(&Client{Conn: connB, Role: RoleSpectator, Name: "Eve"}, []float64{0, 0, 1, 1}); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("spectator: %v", err)
	}
	if err := tbl.Mute(b.PlayerID, true); err != nil {
		t.Fatal(err)
	}
	// A mute is announced in a snapshot at once (the host's switch shows it).
	waitFor(t, "muted in snapshot", func() bool {
		for _, sv := range connA.lastSnapshot(t).Seats {
			if sv.Player != nil && sv.Player.ID == b.PlayerID {
				return sv.Player.Muted
			}
		}
		return false
	})
	if err := tbl.Draw(bob, []float64{0, 0, 1, 1}); !errors.Is(err, ErrMuted) {
		t.Fatalf("muted: %v", err)
	}
	if err := tbl.Mute(b.PlayerID, false); err != nil {
		t.Fatal(err)
	}
	// A late joiner gets the history on connect.
	c, _ := join(t, tbl, "Carol")
	connC := &fakeConn{}
	if err := tbl.Attach(&Client{Conn: connC, Role: RolePlayer, PlayerID: c.PlayerID}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "history", func() bool { return connC.count(protocol.TypeDrawingHistory) == 1 })
	// Bob erases Alice's stroke; anyone may.
	if err := tbl.EraseDrawings(bob, []int64{add[0].ID}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "removed", func() bool { _, rem := strokesOf(t, connA); return len(rem) == 1 && len(rem[0].IDs) == 1 })
	// Own strokes beyond the per-player cap drop the oldest.
	for i := 0; i < maxDrawingsPerPlayer+1; i++ {
		if err := tbl.Draw(alice, []float64{0, 0, 0.5, 0.5}); err != nil {
			if errors.Is(err, ErrRateLimited) {
				break
			}
			t.Fatal(err)
		}
	}
	var n int
	tbl.call(func() { n = len(tbl.drawings) })
	if n > maxDrawingsPerPlayer {
		t.Fatalf("%d strokes kept, cap %d", n, maxDrawingsPerPlayer)
	}
	// Clear all, then the switch off.
	if err := tbl.ClearDrawings(bob, true); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "cleared", func() bool { _, rem := strokesOf(t, connA); return len(rem) > 0 && rem[len(rem)-1].All })
	tbl.call(func() { n = len(tbl.drawings) })
	if n != 0 {
		t.Fatalf("%d strokes after clear", n)
	}
	tbl.call(func() { tbl.settings.AllowDrawing = false })
	if err := tbl.Draw(alice, []float64{0, 0, 1, 1}); !errors.Is(err, ErrIllegalAction) {
		t.Fatalf("drawing off: %v", err)
	}
}
