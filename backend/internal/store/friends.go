package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
)

// Friend errors the HTTP layer turns into answers of its own.
var (
	// ErrBlocked is returned when one of the two has blocked the other.
	// The asking side is never told which way round it is.
	ErrBlocked = errors.New("store: blocked")
	// ErrAlreadyFriends is returned when the friendship already exists.
	ErrAlreadyFriends = errors.New("store: already friends")
	// ErrSelf is returned for a profile asking itself.
	ErrSelf = errors.New("store: same profile")
)

// FriendRow is another profile as a friend list shows it.
type FriendRow struct {
	ID          string
	Handle      string
	DisplayName string
	Since       int64
}

// RequestRow is one pending ask, in either direction.
type RequestRow struct {
	ID          string // the other profile's id
	Handle      string
	DisplayName string
	CreatedAt   int64
}

// InviteRow is an invitation to a table that has not expired.
type InviteRow struct {
	ID        string
	TableID   string
	TableName string
	FromID    string
	FromName  string
	ToID      string
	CreatedAt int64
	ExpiresAt int64
}

const friendCols = `a.id, a.handle, a.display_name`

// Friends lists a profile's friends, newest friendship first.
func (s *Store) Friends(ctx context.Context, accountID string) ([]FriendRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+friendCols+`, f.created_at FROM friends f
		JOIN accounts a ON a.id = f.friend_id
		WHERE f.account_id = ? ORDER BY f.created_at DESC`, accountID)
	if err != nil {
		return nil, fmt.Errorf("friends: %w", err)
	}
	defer rows.Close()
	var out []FriendRow
	for rows.Next() {
		var f FriendRow
		if err := rows.Scan(&f.ID, &f.Handle, &f.DisplayName, &f.Since); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// AreFriends reports whether two profiles are friends. It is the whole of
// the "friends" visibility rule, so it stays cheap and exact.
func (s *Store) AreFriends(ctx context.Context, a, b string) (bool, error) {
	if a == "" || b == "" {
		return false, nil
	}
	var one int
	err := s.db.QueryRowContext(ctx,
		`SELECT 1 FROM friends WHERE account_id = ? AND friend_id = ?`, a, b).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("are friends: %w", err)
	}
	return true, nil
}

// IsBlocked reports whether either profile has blocked the other.
func (s *Store) IsBlocked(ctx context.Context, a, b string) (bool, error) {
	var one int
	err := s.db.QueryRowContext(ctx, `
		SELECT 1 FROM friend_blocks
		WHERE (account_id = ? AND blocked_id = ?) OR (account_id = ? AND blocked_id = ?)`,
		a, b, b, a).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("is blocked: %w", err)
	}
	return true, nil
}

// PendingRequests lists the asks waiting for this profile to answer
// (incoming) and the ones it is waiting on (outgoing).
func (s *Store) PendingRequests(ctx context.Context, accountID string) (incoming, outgoing []RequestRow, err error) {
	read := func(query string) ([]RequestRow, error) {
		rows, qErr := s.db.QueryContext(ctx, query, accountID)
		if qErr != nil {
			return nil, fmt.Errorf("pending requests: %w", qErr)
		}
		defer rows.Close()
		var out []RequestRow
		for rows.Next() {
			var r RequestRow
			if scanErr := rows.Scan(&r.ID, &r.Handle, &r.DisplayName, &r.CreatedAt); scanErr != nil {
				return nil, scanErr
			}
			out = append(out, r)
		}
		return out, rows.Err()
	}
	incoming, err = read(`
		SELECT ` + friendCols + `, r.created_at FROM friend_requests r
		JOIN accounts a ON a.id = r.from_id
		WHERE r.to_id = ? ORDER BY r.created_at DESC`)
	if err != nil {
		return nil, nil, err
	}
	outgoing, err = read(`
		SELECT ` + friendCols + `, r.created_at FROM friend_requests r
		JOIN accounts a ON a.id = r.to_id
		WHERE r.from_id = ? ORDER BY r.created_at DESC`)
	if err != nil {
		return nil, nil, err
	}
	return incoming, outgoing, nil
}

// RequestFriend asks another profile. When that profile has already asked
// this one, the two are made friends on the spot and mutual is true: two
// people who both asked have both agreed.
func (s *Store) RequestFriend(ctx context.Context, fromID, toID string, now int64) (mutual bool, err error) {
	if fromID == toID {
		return false, ErrSelf
	}
	blocked, err := s.IsBlocked(ctx, fromID, toID)
	if err != nil {
		return false, err
	}
	if blocked {
		return false, ErrBlocked
	}
	friends, err := s.AreFriends(ctx, fromID, toID)
	if err != nil {
		return false, err
	}
	if friends {
		return false, ErrAlreadyFriends
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return false, err
	}
	defer func() { _ = tx.Rollback() }()

	var one int
	err = tx.QueryRowContext(ctx,
		`SELECT 1 FROM friend_requests WHERE from_id = ? AND to_id = ?`, toID, fromID).Scan(&one)
	switch {
	case err == nil:
		// They asked first: both have now said yes.
		if err := befriend(ctx, tx, fromID, toID, now); err != nil {
			return false, err
		}
		mutual = true
	case errors.Is(err, sql.ErrNoRows):
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO friend_requests (from_id, to_id, created_at) VALUES (?, ?, ?)
			ON CONFLICT (from_id, to_id) DO NOTHING`, fromID, toID, now); err != nil {
			return false, fmt.Errorf("request friend: %w", err)
		}
	default:
		return false, fmt.Errorf("request friend: %w", err)
	}
	return mutual, tx.Commit()
}

// befriend writes the friendship both ways and clears the asks.
func befriend(ctx context.Context, tx *sql.Tx, a, b string, now int64) error {
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO friends (account_id, friend_id, created_at) VALUES (?, ?, ?), (?, ?, ?)
		ON CONFLICT (account_id, friend_id) DO NOTHING`, a, b, now, b, a, now); err != nil {
		return fmt.Errorf("befriend: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		DELETE FROM friend_requests WHERE (from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)`,
		a, b, b, a); err != nil {
		return fmt.Errorf("befriend clear: %w", err)
	}
	return nil
}

// AcceptRequest turns a pending ask into a friendship. It reports false
// when there was nothing to accept.
func (s *Store) AcceptRequest(ctx context.Context, accountID, fromID string, now int64) (bool, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return false, err
	}
	defer func() { _ = tx.Rollback() }()
	res, err := tx.ExecContext(ctx,
		`DELETE FROM friend_requests WHERE from_id = ? AND to_id = ?`, fromID, accountID)
	if err != nil {
		return false, fmt.Errorf("accept request: %w", err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return false, nil
	}
	if err := befriend(ctx, tx, accountID, fromID, now); err != nil {
		return false, err
	}
	return true, tx.Commit()
}

// DeclineRequest drops a pending ask. The other side is not told: a
// request that goes unanswered and one that was turned down look the same.
func (s *Store) DeclineRequest(ctx context.Context, accountID, fromID string) (bool, error) {
	res, err := s.db.ExecContext(ctx,
		`DELETE FROM friend_requests WHERE from_id = ? AND to_id = ?`, fromID, accountID)
	if err != nil {
		return false, fmt.Errorf("decline request: %w", err)
	}
	n, _ := res.RowsAffected()
	return n > 0, nil
}

// BlockAccount stops every path between the two: the friendship, the asks
// in both directions, and anything either would share with friends.
func (s *Store) BlockAccount(ctx context.Context, accountID, blockedID string, now int64) error {
	if accountID == blockedID {
		return ErrSelf
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO friend_blocks (account_id, blocked_id, created_at) VALUES (?, ?, ?)
		ON CONFLICT (account_id, blocked_id) DO NOTHING`, accountID, blockedID, now); err != nil {
		return fmt.Errorf("block: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		DELETE FROM friends WHERE (account_id = ? AND friend_id = ?) OR (account_id = ? AND friend_id = ?)`,
		accountID, blockedID, blockedID, accountID); err != nil {
		return fmt.Errorf("block unfriend: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		DELETE FROM friend_requests WHERE (from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)`,
		accountID, blockedID, blockedID, accountID); err != nil {
		return fmt.Errorf("block clear: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		DELETE FROM table_invites WHERE (from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)`,
		accountID, blockedID, blockedID, accountID); err != nil {
		return fmt.Errorf("block invites: %w", err)
	}
	return tx.Commit()
}

// UnblockAccount lifts a block. It does not restore the friendship.
func (s *Store) UnblockAccount(ctx context.Context, accountID, blockedID string) error {
	if _, err := s.db.ExecContext(ctx,
		`DELETE FROM friend_blocks WHERE account_id = ? AND blocked_id = ?`, accountID, blockedID); err != nil {
		return fmt.Errorf("unblock: %w", err)
	}
	return nil
}

// Blocked lists the profiles this one has blocked.
func (s *Store) Blocked(ctx context.Context, accountID string) ([]FriendRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+friendCols+`, b.created_at FROM friend_blocks b
		JOIN accounts a ON a.id = b.blocked_id
		WHERE b.account_id = ? ORDER BY b.created_at DESC`, accountID)
	if err != nil {
		return nil, fmt.Errorf("blocked: %w", err)
	}
	defer rows.Close()
	var out []FriendRow
	for rows.Next() {
		var f FriendRow
		if err := rows.Scan(&f.ID, &f.Handle, &f.DisplayName, &f.Since); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// Unfriend removes the friendship in both directions.
func (s *Store) Unfriend(ctx context.Context, accountID, friendID string) error {
	if _, err := s.db.ExecContext(ctx, `
		DELETE FROM friends WHERE (account_id = ? AND friend_id = ?) OR (account_id = ? AND friend_id = ?)`,
		accountID, friendID, friendID, accountID); err != nil {
		return fmt.Errorf("unfriend: %w", err)
	}
	return nil
}

// SearchAccounts finds profiles by the start of their handle or display
// name. Profiles either side of a block are left out, and so is the
// searcher: a friend list is not a way to find out who blocked you.
func (s *Store) SearchAccounts(ctx context.Context, accountID, query string, limit int) ([]FriendRow, error) {
	like := query + "%"
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+friendCols+`, a.created_at FROM accounts a
		WHERE a.id != ?
			AND (a.handle_key LIKE ? OR LOWER(a.display_name) LIKE ?)
			AND NOT EXISTS (
				SELECT 1 FROM friend_blocks b
				WHERE (b.account_id = ? AND b.blocked_id = a.id)
					OR (b.account_id = a.id AND b.blocked_id = ?))
		ORDER BY a.handle LIMIT ?`, accountID, like, like, accountID, accountID, limit)
	if err != nil {
		return nil, fmt.Errorf("search accounts: %w", err)
	}
	defer rows.Close()
	var out []FriendRow
	for rows.Next() {
		var f FriendRow
		if err := rows.Scan(&f.ID, &f.Handle, &f.DisplayName, &f.Since); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// CreateInvite records an invitation to a table.
func (s *Store) CreateInvite(ctx context.Context, r InviteRow) error {
	if _, err := s.db.ExecContext(ctx, `
		INSERT INTO table_invites (id, table_id, table_name, from_id, to_id, created_at, expires_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		r.ID, r.TableID, r.TableName, r.FromID, r.ToID, r.CreatedAt, r.ExpiresAt); err != nil {
		return fmt.Errorf("create invite: %w", err)
	}
	return nil
}

// Invites lists the invitations waiting for a profile, newest first, and
// drops the ones that have run out along the way.
func (s *Store) Invites(ctx context.Context, accountID string, now int64) ([]InviteRow, error) {
	if _, err := s.db.ExecContext(ctx, `DELETE FROM table_invites WHERE expires_at <= ?`, now); err != nil {
		return nil, fmt.Errorf("purge invites: %w", err)
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT i.id, i.table_id, i.table_name, i.from_id, a.handle, i.to_id, i.created_at, i.expires_at
		FROM table_invites i JOIN accounts a ON a.id = i.from_id
		WHERE i.to_id = ? ORDER BY i.created_at DESC`, accountID)
	if err != nil {
		return nil, fmt.Errorf("invites: %w", err)
	}
	defer rows.Close()
	var out []InviteRow
	for rows.Next() {
		var r InviteRow
		if err := rows.Scan(&r.ID, &r.TableID, &r.TableName, &r.FromID, &r.FromName,
			&r.ToID, &r.CreatedAt, &r.ExpiresAt); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// DeleteInvite drops one invitation once it has been used or dismissed.
func (s *Store) DeleteInvite(ctx context.Context, accountID, id string) error {
	if _, err := s.db.ExecContext(ctx,
		`DELETE FROM table_invites WHERE id = ? AND to_id = ?`, id, accountID); err != nil {
		return fmt.Errorf("delete invite: %w", err)
	}
	return nil
}
