package table

import (
	"slices"

	"showdown/internal/protocol"
)

// Pencil drawings: strokes players scribble on the table. They live in
// memory only, are capped, and vanish with the player who drew them.
const (
	maxDrawings          = 200 // per table; the oldest go first
	maxDrawingsPerPlayer = 40
	drawRateWindowMs     = 60_000
	drawRateMax          = 60 // strokes per player and minute
)

// Draw adds a stroke of the player's. Points are x,y pairs in 0..1.
func (t *Table) Draw(c *Client, points []float64) error {
	return t.callErr(func() error {
		if c.Role != RolePlayer {
			return ErrNotSeated
		}
		if !t.settings.AllowDrawing {
			return ErrIllegalAction
		}
		p, err := t.seatedPlayer(c.PlayerID)
		if err != nil {
			return err
		}
		if p.Muted {
			return ErrMuted
		}
		if len(points) < 2 || len(points)%2 != 0 || len(points) > 2*protocol.MaxStrokePoints {
			return ErrIllegalAction
		}
		for _, v := range points {
			if v < 0 || v > 1 || v != v {
				return ErrIllegalAction
			}
		}
		now := t.nowMs()
		p.drawTimes = slices.DeleteFunc(p.drawTimes, func(ts int64) bool { return now-ts > drawRateWindowMs })
		if len(p.drawTimes) >= drawRateMax {
			return ErrRateLimited
		}
		p.drawTimes = append(p.drawTimes, now)
		// The oldest strokes make room: the player's own beyond their share,
		// then anyone's beyond the table cap.
		mine := 0
		for _, s := range t.drawings {
			if s.PlayerID == p.ID {
				mine++
			}
		}
		var drop []int64
		for _, s := range t.drawings {
			if mine >= maxDrawingsPerPlayer && s.PlayerID == p.ID {
				drop = append(drop, s.ID)
				mine--
			}
		}
		for i := 0; len(t.drawings)-len(drop) >= maxDrawings && i < len(t.drawings); i++ {
			if !slices.Contains(drop, t.drawings[i].ID) {
				drop = append(drop, t.drawings[i].ID)
			}
		}
		if len(drop) > 0 {
			t.removeDrawings(func(s protocol.Stroke) bool { return slices.Contains(drop, s.ID) }, false)
		}
		t.drawSeq++
		stroke := protocol.Stroke{
			ID: t.drawSeq, PlayerID: p.ID, Seat: p.Seat, Name: p.Name, Avatar: p.Avatar,
			Points: append([]float64{}, points...), TS: now,
		}
		t.drawings = append(t.drawings, stroke)
		t.broadcastMsg(protocol.MustEncode(protocol.TypeDrawing, "", stroke))
		return nil
	})
}

// EraseDrawings removes strokes by id; anyone at the table may erase
// anyone's scribble.
func (t *Table) EraseDrawings(c *Client, ids []int64) error {
	return t.callErr(func() error {
		if c.Role == RoleSpectator && !c.Admin {
			return ErrNotSeated
		}
		if len(ids) == 0 {
			return ErrIllegalAction
		}
		t.removeDrawings(func(s protocol.Stroke) bool { return slices.Contains(ids, s.ID) }, false)
		return nil
	})
}

// ClearDrawings removes the caller's strokes, or every stroke with all.
func (t *Table) ClearDrawings(c *Client, all bool) error {
	return t.callErr(func() error {
		if c.Role == RoleSpectator && !c.Admin {
			return ErrNotSeated
		}
		if all {
			t.removeDrawings(func(protocol.Stroke) bool { return true }, true)
			return nil
		}
		t.removeDrawings(func(s protocol.Stroke) bool { return s.PlayerID == c.PlayerID }, false)
		return nil
	})
}

// removeDrawings drops the strokes matching keep-out and tells everyone.
func (t *Table) removeDrawings(gone func(protocol.Stroke) bool, all bool) {
	var ids []int64
	t.drawings = slices.DeleteFunc(t.drawings, func(s protocol.Stroke) bool {
		if gone(s) {
			ids = append(ids, s.ID)
			return true
		}
		return false
	})
	if all {
		t.broadcastMsg(protocol.MustEncode(protocol.TypeDrawingsRemoved, "", protocol.DrawingsRemoved{All: true}))
	} else if len(ids) > 0 {
		t.broadcastMsg(protocol.MustEncode(protocol.TypeDrawingsRemoved, "", protocol.DrawingsRemoved{IDs: ids}))
	}
}
