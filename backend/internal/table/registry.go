package table

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"sync"
	"time"

	"showdown/internal/protocol"
	"showdown/internal/store"
)

// ErrTooManyTables is returned when MAX_TABLES non-ended tables exist.
var ErrTooManyTables = errors.New("too many tables")

// Registry owns every live table actor.
type Registry struct {
	mu        sync.RWMutex
	tables    map[string]*Table
	deps      Deps
	maxTables int
}

// NewRegistry creates an empty registry.
func NewRegistry(deps Deps, maxTables int) *Registry {
	return &Registry{tables: map[string]*Table{}, deps: deps.withDefaults(), maxTables: maxTables}
}

// Create validates, persists and starts a new table.
// Create makes a new table; adminTokenHash is the SHA-256 of the admin
// token handed to the creator, who manages the table with it.
func (r *Registry) Create(ctx context.Context, name string, s Settings, adminTokenHash string) (*Table, error) {
	name = trimName(name)
	if n := len([]rune(name)); n < 1 || n > 40 {
		return nil, &ValidationError{Fields: []FieldError{{Field: "name", Message: "must be 1–40 characters"}}}
	}
	if err := s.Validate(0); err != nil {
		return nil, err
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	live := 0
	for _, t := range r.tables {
		if t.State() != StateEnded {
			live++
		}
	}
	if live >= r.maxTables {
		return nil, ErrTooManyTables
	}
	id := NewTableID()
	for r.tables[id] != nil {
		id = NewTableID()
	}
	t := newTable(id, r.deps)
	t.name = name
	t.state = StateWaiting
	t.createdAt = t.nowMs()
	t.settings = s
	t.adminTokenHash = adminTokenHash
	if r.deps.Store != nil {
		row := store.TableRow{ID: id, Name: name, State: StateWaiting, CreatedAt: t.createdAt, ButtonSeat: -1, AdminTokenHash: adminTokenHash}
		if err := r.deps.Store.CreateTable(ctx, row, s.Row(id)); err != nil {
			return nil, fmt.Errorf("create table: %w", err)
		}
	}
	go t.run()
	r.tables[id] = t
	return t, nil
}

func trimName(name string) string {
	out := make([]rune, 0, len(name))
	space := false
	for _, ch := range name {
		if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
			space = true
			continue
		}
		if space && len(out) > 0 {
			out = append(out, ' ')
		}
		space = false
		out = append(out, ch)
	}
	return string(out)
}

// Get returns a table by id.
func (r *Registry) Get(id string) (*Table, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	t, ok := r.tables[id]
	return t, ok
}

// List returns all tables, newest first.
func (r *Registry) List() []*Table {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]*Table, 0, len(r.tables))
	for _, t := range r.tables {
		out = append(out, t)
	}
	sort.Slice(out, func(i, j int) bool {
		a, b := out[i].Info(), out[j].Info()
		if a.CreatedAt != b.CreatedAt {
			return a.CreatedAt > b.CreatedAt
		}
		return a.ID < b.ID
	})
	return out
}

// Delete stops and removes a table (not while running).
func (r *Registry) Delete(ctx context.Context, id string) error {
	r.mu.Lock()
	t, ok := r.tables[id]
	if !ok {
		r.mu.Unlock()
		return ErrNotFound
	}
	if t.State() == StateRunning {
		r.mu.Unlock()
		return ErrTableRunning
	}
	delete(r.tables, id)
	r.mu.Unlock()
	t.Stop(ctx, protocol.CloseTableGone, "table_deleted")
	if r.deps.Store != nil {
		if err := r.deps.Store.DeleteTable(ctx, id); err != nil && !errors.Is(err, store.ErrNotFound) {
			return err
		}
	}
	return nil
}

// Stats summarises the registry.
func (r *Registry) Stats() (byState map[string]int, connections int) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	byState = map[string]int{}
	for _, t := range r.tables {
		d := t.AdminDetail()
		byState[d.State]++
		connections += d.Connections
	}
	return byState, connections
}

// Shutdown notifies every client and stops all tables, draining persisters.
func (r *Registry) Shutdown(ctx context.Context) {
	r.mu.Lock()
	tables := r.tables
	r.tables = map[string]*Table{}
	r.mu.Unlock()
	for _, t := range tables {
		t.NotifyRestart()
	}
	for _, t := range tables {
		t.Stop(ctx, 1001, "server_restarting")
	}
}

// LoadAll restores every non-ended table from the store (restart recovery):
// players and settings are reloaded, sessions stay valid, and a hand that
// was in progress is voided with a system chat line.
func (r *Registry) LoadAll(ctx context.Context) error {
	if r.deps.Store == nil {
		return nil
	}
	st := r.deps.Store
	rows, err := st.ListTables(ctx, false)
	if err != nil {
		return err
	}
	now := time.Now().UnixMilli()
	for _, row := range rows {
		_, settings, err := st.GetTable(ctx, row.ID)
		if err != nil {
			return fmt.Errorf("load table %s: %w", row.ID, err)
		}
		t := newTable(row.ID, r.deps)
		t.name, t.state, t.createdAt, t.endedAt = row.Name, row.State, row.CreatedAt, row.EndedAt
		t.adminTokenHash = row.AdminTokenHash
		t.handNumber, t.buttonSeat = row.HandNumber, row.ButtonSeat
		t.settings = SettingsFromRow(settings)

		players, err := st.ListPlayers(ctx, row.ID)
		if err != nil {
			return fmt.Errorf("load players %s: %w", row.ID, err)
		}
		for _, pr := range players {
			t.names[NameKey(pr.Name)] = pr.Name
			if pr.Status == StatusLeft {
				continue
			}
			p := &Player{
				ID: pr.ID, Name: pr.Name, Seat: pr.Seat, Stack: pr.Stack, Status: pr.Status, Muted: pr.Muted,
				MissedTurns: pr.MissedTurns, BuyInTotal: pr.BuyInTotal, HandsPlayed: pr.HandsPlayed,
				HandsWon: pr.HandsWon, BiggestPot: pr.BiggestPot, JoinedAt: pr.JoinedAt, Avatar: pr.Avatar,
				pendingSeat: -1,
			}
			if pr.Seat >= 0 && pr.Seat < maxSeats {
				t.seats[pr.Seat] = p
				t.players[p.ID] = p
			}
		}
		sessions, err := st.ListSessions(ctx, row.ID, now)
		if err != nil {
			return fmt.Errorf("load sessions %s: %w", row.ID, err)
		}
		for _, s := range sessions {
			if s.Kind == RoleSpectator {
				t.names[NameKey(s.Name)] = s.Name
				t.spectatorNames[NameKey(s.Name)] = true
			}
		}
		chat, err := st.RecentChat(ctx, row.ID, chatKeep)
		if err != nil {
			return fmt.Errorf("load chat %s: %w", row.ID, err)
		}
		for _, m := range chat {
			t.chat = append(t.chat, protocol.ChatMessage{ID: m.ID, AuthorKind: m.AuthorKind, AuthorName: m.AuthorName, Text: m.Text, TS: m.TS})
			if m.ID > t.chatSeq {
				t.chatSeq = m.ID
			}
		}
		voided, err := st.VoidOpenHands(ctx, row.ID, now)
		if err != nil {
			return fmt.Errorf("void hands %s: %w", row.ID, err)
		}
		go t.run()
		for _, h := range voided {
			r.deps.Log.Warn("voided unfinished hand after restart", "table", row.ID, "hand", h.Number)
			num := h.Number
			t.call(func() {
				t.postChat("system", "system", fmt.Sprintf("Server restarted: hand #%d was voided and stacks restored.", num))
			})
		}
		t.call(func() { t.scheduleStart() })
		r.mu.Lock()
		r.tables[row.ID] = t
		r.mu.Unlock()
	}
	return nil
}
