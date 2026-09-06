package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
)

// ErrNotFound is returned when a row does not exist.
var ErrNotFound = errors.New("store: not found")

func nullInt(v int64) any {
	if v == 0 {
		return nil
	}
	return v
}

func scanNullInt(v sql.NullInt64) int64 {
	if v.Valid {
		return v.Int64
	}
	return 0
}

func b2i(b bool) int {
	if b {
		return 1
	}
	return 0
}

// ---- tables ---------------------------------------------------------------------

// CreateTable inserts a table together with its settings.
func (s *Store) CreateTable(ctx context.Context, t TableRow, st SettingsRow) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO tables (id, name, state, created_at, ended_at, hand_number, button_seat, admin_token_hash)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		t.ID, t.Name, t.State, t.CreatedAt, nullInt(t.EndedAt), t.HandNumber, t.ButtonSeat, t.AdminTokenHash); err != nil {
		return fmt.Errorf("insert table: %w", err)
	}
	st.TableID = t.ID
	if err := upsertSettings(ctx, tx, st); err != nil {
		return err
	}
	return tx.Commit()
}

type execer interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
}

func upsertSettings(ctx context.Context, ex execer, st SettingsRow) error {
	_, err := ex.ExecContext(ctx, `
		INSERT INTO table_settings (table_id, password_hash, max_players, start_money, small_blind, big_blind, ante,
			turn_time, disconnected_turn_time, sit_out_after_missed_turns, join_policy, allow_spectators,
			spectator_chat, chat_enabled, allow_rebuy, showdown_reveal, auto_start, hand_delay_ms,
			allow_rabbit_hunt, blinds_up_minutes, blinds_up_percent, time_bank_seconds, allow_straddle, run_it_twice)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(table_id) DO UPDATE SET
			password_hash = excluded.password_hash, max_players = excluded.max_players,
			start_money = excluded.start_money, small_blind = excluded.small_blind,
			big_blind = excluded.big_blind, ante = excluded.ante, turn_time = excluded.turn_time,
			disconnected_turn_time = excluded.disconnected_turn_time,
			sit_out_after_missed_turns = excluded.sit_out_after_missed_turns,
			join_policy = excluded.join_policy, allow_spectators = excluded.allow_spectators,
			spectator_chat = excluded.spectator_chat, chat_enabled = excluded.chat_enabled,
			allow_rebuy = excluded.allow_rebuy, showdown_reveal = excluded.showdown_reveal,
			auto_start = excluded.auto_start, hand_delay_ms = excluded.hand_delay_ms,
			allow_rabbit_hunt = excluded.allow_rabbit_hunt, blinds_up_minutes = excluded.blinds_up_minutes,
			blinds_up_percent = excluded.blinds_up_percent, time_bank_seconds = excluded.time_bank_seconds,
			allow_straddle = excluded.allow_straddle, run_it_twice = excluded.run_it_twice`,
		st.TableID, st.PasswordHash, st.MaxPlayers, st.StartMoney, st.SmallBlind, st.BigBlind, st.Ante,
		st.TurnTime, st.DisconnectedTurnTime, st.SitOutAfterMissedTurns, st.JoinPolicy, b2i(st.AllowSpectators),
		b2i(st.SpectatorChat), b2i(st.ChatEnabled), b2i(st.AllowRebuy), st.ShowdownReveal, b2i(st.AutoStart), st.HandDelayMs,
		b2i(st.AllowRabbitHunt), st.BlindsUpMinutes, st.BlindsUpPercent, st.TimeBankSeconds, b2i(st.AllowStraddle), b2i(st.RunItTwice))
	if err != nil {
		return fmt.Errorf("upsert settings: %w", err)
	}
	return nil
}

// SaveSettings replaces the settings of a table.
func (s *Store) SaveSettings(ctx context.Context, st SettingsRow) error {
	return upsertSettings(ctx, s.db, st)
}

// UpdateTable writes the mutable table columns.
func (s *Store) UpdateTable(ctx context.Context, t TableRow) error {
	res, err := s.db.ExecContext(ctx, `
		UPDATE tables SET name = ?, state = ?, ended_at = ?, hand_number = ?, button_seat = ?, admin_token_hash = ? WHERE id = ?`,
		t.Name, t.State, nullInt(t.EndedAt), t.HandNumber, t.ButtonSeat, t.AdminTokenHash, t.ID)
	if err != nil {
		return fmt.Errorf("update table: %w", err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

const tableCols = `id, name, state, created_at, ended_at, hand_number, button_seat, admin_token_hash`

func scanTable(row interface{ Scan(...any) error }) (TableRow, error) {
	var t TableRow
	var ended sql.NullInt64
	err := row.Scan(&t.ID, &t.Name, &t.State, &t.CreatedAt, &ended, &t.HandNumber, &t.ButtonSeat, &t.AdminTokenHash)
	t.EndedAt = scanNullInt(ended)
	return t, err
}

// GetTable loads one table and its settings.
func (s *Store) GetTable(ctx context.Context, id string) (TableRow, SettingsRow, error) {
	t, err := scanTable(s.db.QueryRowContext(ctx, `SELECT `+tableCols+` FROM tables WHERE id = ?`, id))
	if errors.Is(err, sql.ErrNoRows) {
		return TableRow{}, SettingsRow{}, ErrNotFound
	}
	if err != nil {
		return TableRow{}, SettingsRow{}, fmt.Errorf("get table: %w", err)
	}
	st, err := s.getSettings(ctx, id)
	return t, st, err
}

const settingsCols = `table_id, password_hash, max_players, start_money, small_blind, big_blind, ante,
	turn_time, disconnected_turn_time, sit_out_after_missed_turns, join_policy, allow_spectators,
	spectator_chat, chat_enabled, allow_rebuy, showdown_reveal, auto_start, hand_delay_ms,
	allow_rabbit_hunt, blinds_up_minutes, blinds_up_percent, time_bank_seconds, allow_straddle, run_it_twice`

func (s *Store) getSettings(ctx context.Context, id string) (SettingsRow, error) {
	var st SettingsRow
	var allowSpec, specChat, chat, rebuy, auto, rabbit, straddle, rit int
	err := s.db.QueryRowContext(ctx, `SELECT `+settingsCols+` FROM table_settings WHERE table_id = ?`, id).Scan(
		&st.TableID, &st.PasswordHash, &st.MaxPlayers, &st.StartMoney, &st.SmallBlind, &st.BigBlind, &st.Ante,
		&st.TurnTime, &st.DisconnectedTurnTime, &st.SitOutAfterMissedTurns, &st.JoinPolicy, &allowSpec,
		&specChat, &chat, &rebuy, &st.ShowdownReveal, &auto, &st.HandDelayMs, &rabbit, &st.BlindsUpMinutes, &st.BlindsUpPercent,
		&st.TimeBankSeconds, &straddle, &rit)
	if errors.Is(err, sql.ErrNoRows) {
		return SettingsRow{}, ErrNotFound
	}
	if err != nil {
		return SettingsRow{}, fmt.Errorf("get settings: %w", err)
	}
	st.AllowSpectators, st.SpectatorChat, st.ChatEnabled, st.AllowRebuy, st.AutoStart, st.AllowRabbitHunt =
		allowSpec == 1, specChat == 1, chat == 1, rebuy == 1, auto == 1, rabbit == 1
	st.AllowStraddle, st.RunItTwice = straddle == 1, rit == 1
	return st, nil
}

// ListTables returns all tables (ended included when includeEnded), newest first.
func (s *Store) ListTables(ctx context.Context, includeEnded bool) ([]TableRow, error) {
	q := `SELECT ` + tableCols + ` FROM tables`
	if !includeEnded {
		q += ` WHERE state <> 'ended'`
	}
	q += ` ORDER BY created_at DESC, id`
	rows, err := s.db.QueryContext(ctx, q)
	if err != nil {
		return nil, fmt.Errorf("list tables: %w", err)
	}
	defer rows.Close()
	var out []TableRow
	for rows.Next() {
		t, err := scanTable(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

// DeleteTable removes a table and everything that references it.
func (s *Store) DeleteTable(ctx context.Context, id string) error {
	res, err := s.db.ExecContext(ctx, `DELETE FROM tables WHERE id = ?`, id)
	if err != nil {
		return fmt.Errorf("delete table: %w", err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// CountTablesByState returns a state -> count map.
func (s *Store) CountTablesByState(ctx context.Context) (map[string]int, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT state, COUNT(*) FROM tables GROUP BY state`)
	if err != nil {
		return nil, fmt.Errorf("count tables: %w", err)
	}
	defer rows.Close()
	out := map[string]int{}
	for rows.Next() {
		var state string
		var n int
		if err := rows.Scan(&state, &n); err != nil {
			return nil, err
		}
		out[state] = n
	}
	return out, rows.Err()
}

// ---- players --------------------------------------------------------------------

// UpsertPlayer inserts or fully updates a player.
func (s *Store) UpsertPlayer(ctx context.Context, p PlayerRow) error {
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO players (id, table_id, name, seat, stack, status, muted, missed_turns, buy_in_total,
			hands_played, hands_won, biggest_pot, joined_at, left_at, avatar,
			vpip_hands, showdowns, showdowns_won, time_bank, place)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			name = excluded.name, seat = excluded.seat, stack = excluded.stack, status = excluded.status,
			muted = excluded.muted, missed_turns = excluded.missed_turns, buy_in_total = excluded.buy_in_total,
			hands_played = excluded.hands_played, hands_won = excluded.hands_won, biggest_pot = excluded.biggest_pot,
			joined_at = excluded.joined_at, left_at = excluded.left_at, avatar = excluded.avatar,
			vpip_hands = excluded.vpip_hands, showdowns = excluded.showdowns, showdowns_won = excluded.showdowns_won,
			time_bank = excluded.time_bank, place = excluded.place`,
		p.ID, p.TableID, p.Name, p.Seat, p.Stack, p.Status, b2i(p.Muted), p.MissedTurns, p.BuyInTotal,
		p.HandsPlayed, p.HandsWon, p.BiggestPot, p.JoinedAt, nullInt(p.LeftAt), p.Avatar,
		p.VPIPHands, p.Showdowns, p.ShowdownsWon, p.TimeBank, p.Place)
	if err != nil {
		return fmt.Errorf("upsert player: %w", err)
	}
	return nil
}

// ListPlayers returns every player row of a table (including left ones), by seat.
func (s *Store) ListPlayers(ctx context.Context, tableID string) ([]PlayerRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, table_id, name, seat, stack, status, muted, missed_turns, buy_in_total,
			hands_played, hands_won, biggest_pot, joined_at, left_at, avatar,
			vpip_hands, showdowns, showdowns_won, time_bank, place
		FROM players WHERE table_id = ? ORDER BY seat, joined_at`, tableID)
	if err != nil {
		return nil, fmt.Errorf("list players: %w", err)
	}
	defer rows.Close()
	var out []PlayerRow
	for rows.Next() {
		var p PlayerRow
		var muted int
		var left sql.NullInt64
		if err := rows.Scan(&p.ID, &p.TableID, &p.Name, &p.Seat, &p.Stack, &p.Status, &muted, &p.MissedTurns,
			&p.BuyInTotal, &p.HandsPlayed, &p.HandsWon, &p.BiggestPot, &p.JoinedAt, &left, &p.Avatar,
			&p.VPIPHands, &p.Showdowns, &p.ShowdownsWon, &p.TimeBank, &p.Place); err != nil {
			return nil, err
		}
		p.Muted = muted == 1
		p.LeftAt = scanNullInt(left)
		out = append(out, p)
	}
	return out, rows.Err()
}

// ---- sessions -------------------------------------------------------------------

// CreateSession stores a token hash.
func (s *Store) CreateSession(ctx context.Context, r SessionRow) error {
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO sessions (token_hash, kind, table_id, player_id, name, created_at, expires_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		r.TokenHash, r.Kind, r.TableID, r.PlayerID, r.Name, r.CreatedAt, r.ExpiresAt)
	if err != nil {
		return fmt.Errorf("create session: %w", err)
	}
	return nil
}

// GetSession looks a token hash up. Expired sessions are reported as not found.
func (s *Store) GetSession(ctx context.Context, tokenHash string, now int64) (SessionRow, error) {
	var r SessionRow
	err := s.db.QueryRowContext(ctx, `
		SELECT token_hash, kind, table_id, player_id, name, created_at, expires_at
		FROM sessions WHERE token_hash = ? AND expires_at > ?`, tokenHash, now).Scan(
		&r.TokenHash, &r.Kind, &r.TableID, &r.PlayerID, &r.Name, &r.CreatedAt, &r.ExpiresAt)
	if errors.Is(err, sql.ErrNoRows) {
		return SessionRow{}, ErrNotFound
	}
	if err != nil {
		return SessionRow{}, fmt.Errorf("get session: %w", err)
	}
	return r, nil
}

// ListSessions returns the unexpired sessions of a table.
func (s *Store) ListSessions(ctx context.Context, tableID string, now int64) ([]SessionRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT token_hash, kind, table_id, player_id, name, created_at, expires_at
		FROM sessions WHERE table_id = ? AND expires_at > ?`, tableID, now)
	if err != nil {
		return nil, fmt.Errorf("list sessions: %w", err)
	}
	defer rows.Close()
	var out []SessionRow
	for rows.Next() {
		var r SessionRow
		if err := rows.Scan(&r.TokenHash, &r.Kind, &r.TableID, &r.PlayerID, &r.Name, &r.CreatedAt, &r.ExpiresAt); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// DeleteSessionsForPlayer invalidates every session of a player.
func (s *Store) DeleteSessionsForPlayer(ctx context.Context, tableID, playerID string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM sessions WHERE table_id = ? AND player_id = ?`, tableID, playerID)
	if err != nil {
		return fmt.Errorf("delete sessions: %w", err)
	}
	return nil
}

// DeleteSession removes one session by token hash.
func (s *Store) DeleteSession(ctx context.Context, tokenHash string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM sessions WHERE token_hash = ?`, tokenHash)
	if err != nil {
		return fmt.Errorf("delete session: %w", err)
	}
	return nil
}

// ---- chat -----------------------------------------------------------------------

// InsertChat stores a message and returns its id. A positive m.ID is used
// as the explicit id (the table actor numbers messages itself).
func (s *Store) InsertChat(ctx context.Context, m ChatRow) (int64, error) {
	var res sql.Result
	var err error
	if m.ID > 0 {
		res, err = s.db.ExecContext(ctx, `
			INSERT INTO chat_messages (id, table_id, author_kind, author_name, text, ts) VALUES (?, ?, ?, ?, ?, ?)`,
			m.ID, m.TableID, m.AuthorKind, m.AuthorName, m.Text, m.TS)
	} else {
		res, err = s.db.ExecContext(ctx, `
			INSERT INTO chat_messages (table_id, author_kind, author_name, text, ts) VALUES (?, ?, ?, ?, ?)`,
			m.TableID, m.AuthorKind, m.AuthorName, m.Text, m.TS)
	}
	if err != nil {
		return 0, fmt.Errorf("insert chat: %w", err)
	}
	return res.LastInsertId()
}

// RecentChat returns the newest limit messages of a table in ascending order.
func (s *Store) RecentChat(ctx context.Context, tableID string, limit int) ([]ChatRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, table_id, author_kind, author_name, text, ts FROM (
			SELECT id, table_id, author_kind, author_name, text, ts FROM chat_messages
			WHERE table_id = ? ORDER BY id DESC LIMIT ?
		) ORDER BY id ASC`, tableID, limit)
	if err != nil {
		return nil, fmt.Errorf("recent chat: %w", err)
	}
	defer rows.Close()
	var out []ChatRow
	for rows.Next() {
		var m ChatRow
		if err := rows.Scan(&m.ID, &m.TableID, &m.AuthorKind, &m.AuthorName, &m.Text, &m.TS); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// DeleteChat removes one message.
func (s *Store) DeleteChat(ctx context.Context, tableID string, id int64) error {
	res, err := s.db.ExecContext(ctx, `DELETE FROM chat_messages WHERE table_id = ? AND id = ?`, tableID, id)
	if err != nil {
		return fmt.Errorf("delete chat: %w", err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// ---- hands ----------------------------------------------------------------------

// InsertHand stores a started hand and returns its id.
func (s *Store) InsertHand(ctx context.Context, h HandRow) (int64, error) {
	res, err := s.db.ExecContext(ctx, `
		INSERT INTO hands (table_id, number, started_at, ended_at, button_seat, small_blind, big_blind, ante,
			stacks_at_start, events, results, voided)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		h.TableID, h.Number, h.StartedAt, nullInt(h.EndedAt), h.ButtonSeat, h.SmallBlind, h.BigBlind, h.Ante,
		string(h.StacksAtStart), string(orEmptyArray(h.Events)), nullBytes(h.Results), b2i(h.Voided))
	if err != nil {
		return 0, fmt.Errorf("insert hand: %w", err)
	}
	return res.LastInsertId()
}

func orEmptyArray(b []byte) []byte {
	if len(b) == 0 {
		return []byte("[]")
	}
	return b
}

func nullBytes(b []byte) any {
	if b == nil {
		return nil
	}
	return string(b)
}

// FinishHand records the outcome of a hand.
func (s *Store) FinishHand(ctx context.Context, id int64, endedAt int64, events, results []byte, voided bool) error {
	_, err := s.db.ExecContext(ctx, `UPDATE hands SET ended_at = ?, events = ?, results = ?, voided = ? WHERE id = ?`,
		endedAt, string(orEmptyArray(events)), nullBytes(results), b2i(voided), id)
	if err != nil {
		return fmt.Errorf("finish hand: %w", err)
	}
	return nil
}

// VoidOpenHands marks every unfinished hand of a table as voided and returns
// the affected hand numbers with their starting stacks.
func (s *Store) VoidOpenHands(ctx context.Context, tableID string, now int64) ([]HandRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, number, stacks_at_start FROM hands WHERE table_id = ? AND ended_at IS NULL`, tableID)
	if err != nil {
		return nil, fmt.Errorf("open hands: %w", err)
	}
	var open []HandRow
	for rows.Next() {
		var h HandRow
		var stacks string
		if err := rows.Scan(&h.ID, &h.Number, &stacks); err != nil {
			_ = rows.Close()
			return nil, err
		}
		h.TableID = tableID
		h.StacksAtStart = []byte(stacks)
		open = append(open, h)
	}
	if err := errors.Join(rows.Err(), rows.Close()); err != nil {
		return nil, err
	}
	for i := range open {
		if _, err := s.db.ExecContext(ctx, `UPDATE hands SET ended_at = ?, voided = 1 WHERE id = ?`, now, open[i].ID); err != nil {
			return nil, fmt.Errorf("void hand: %w", err)
		}
		open[i].Voided = true
		open[i].EndedAt = now
	}
	return open, nil
}

// ListHands returns up to limit hands of a table with number < before (0 =
// newest), newest first.
func (s *Store) ListHands(ctx context.Context, tableID string, limit, before int) ([]HandRow, error) {
	if before <= 0 {
		before = 1 << 30
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, table_id, number, started_at, ended_at, button_seat, small_blind, big_blind, ante,
			stacks_at_start, events, results, voided
		FROM hands WHERE table_id = ? AND number < ? ORDER BY number DESC LIMIT ?`, tableID, before, limit)
	if err != nil {
		return nil, fmt.Errorf("list hands: %w", err)
	}
	defer rows.Close()
	var out []HandRow
	for rows.Next() {
		var h HandRow
		var ended sql.NullInt64
		var stacks, events string
		var results sql.NullString
		var voided int
		if err := rows.Scan(&h.ID, &h.TableID, &h.Number, &h.StartedAt, &ended, &h.ButtonSeat, &h.SmallBlind,
			&h.BigBlind, &h.Ante, &stacks, &events, &results, &voided); err != nil {
			return nil, err
		}
		h.EndedAt = scanNullInt(ended)
		h.StacksAtStart = []byte(stacks)
		h.Events = []byte(events)
		if results.Valid {
			h.Results = []byte(results.String)
		}
		h.Voided = voided == 1
		out = append(out, h)
	}
	return out, rows.Err()
}

// ---- player results & leaderboard ---------------------------------------------

// ---- admin audit ----------------------------------------------------------------

// InsertAdminAction appends to the audit log.
func (s *Store) InsertAdminAction(ctx context.Context, a AdminActionRow) error {
	details := a.Details
	if len(details) == 0 {
		details = []byte("{}")
	}
	_, err := s.db.ExecContext(ctx, `INSERT INTO admin_actions (ts, action, table_id, player_id, details) VALUES (?, ?, ?, ?, ?)`,
		a.TS, a.Action, a.TableID, a.PlayerID, string(details))
	if err != nil {
		return fmt.Errorf("insert admin action: %w", err)
	}
	return nil
}

// ---- retention ------------------------------------------------------------------

// PurgeEndedTableData deletes hands and chat of tables that ended before
// cutoff. The table and its players (the final standings) are kept. Returns
// the number of tables purged.
func (s *Store) PurgeEndedTableData(ctx context.Context, cutoff int64) (int, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id FROM tables WHERE state = 'ended' AND ended_at IS NOT NULL AND ended_at < ?`, cutoff)
	if err != nil {
		return 0, fmt.Errorf("purge query: %w", err)
	}
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			_ = rows.Close()
			return 0, err
		}
		ids = append(ids, id)
	}
	if err := errors.Join(rows.Err(), rows.Close()); err != nil {
		return 0, err
	}
	for _, id := range ids {
		if _, err := s.db.ExecContext(ctx, `DELETE FROM hands WHERE table_id = ?`, id); err != nil {
			return 0, fmt.Errorf("purge hands: %w", err)
		}
		if _, err := s.db.ExecContext(ctx, `DELETE FROM chat_messages WHERE table_id = ?`, id); err != nil {
			return 0, fmt.Errorf("purge chat: %w", err)
		}
	}
	return len(ids), nil
}
