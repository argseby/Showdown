package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
)

// RevokedLinkRow is one profile's connection to their own revoked vault:
// the section this instance was given, the entry it keeps there saying
// which table they are at, and the share over it.
//
// The player made this connection and can end it from their app at any
// moment. Nothing here is a credential of theirs: Token writes this
// instance's own section and manages the shares it made, and does not
// reach the rest of the vault.
type RevokedLinkRow struct {
	AccountID    string
	Server       string
	ConnectionID string
	Token        string
	Section      string
	RecordID     string
	RecordKey    string
	LinkID       string
	LinkURL      string
	// LinkRecords is the entries the share was made to grant, comma
	// separated. A share serves the records it names and nothing else, so
	// when what this instance keeps no longer matches, the share is
	// replaced rather than quietly serving the wrong thing.
	LinkRecords string
	// Published is the value last written, so a player who has not moved
	// costs their server no request.
	Published string
	// Trouble is why this connection stopped working, in the revoked
	// server's own words: "paused", "expired" or "gone". Empty while all
	// is well.
	Trouble   string
	CreatedAt int64
	ExpiresAt int64
	UpdatedAt int64
}

const revokedLinkCols = `account_id, server, connection_id, token, section, record_id, record_key,
	link_id, link_url, link_records, published, trouble, created_at, expires_at, updated_at`

func scanRevokedLink(row interface{ Scan(...any) error }) (RevokedLinkRow, error) {
	var l RevokedLinkRow
	err := row.Scan(&l.AccountID, &l.Server, &l.ConnectionID, &l.Token, &l.Section, &l.RecordID,
		&l.RecordKey, &l.LinkID, &l.LinkURL, &l.LinkRecords, &l.Published, &l.Trouble,
		&l.CreatedAt, &l.ExpiresAt, &l.UpdatedAt)
	return l, err
}

// SaveRevokedLink writes a profile's connection, replacing whatever it had.
// Connecting again is how a lapsed connection is renewed, so an upsert is
// the whole of it: one profile, one vault, one row.
func (s *Store) SaveRevokedLink(ctx context.Context, l RevokedLinkRow) error {
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO account_revoked_links (`+revokedLinkCols+`)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(account_id) DO UPDATE SET
			server = excluded.server, connection_id = excluded.connection_id,
			token = excluded.token, section = excluded.section,
			record_id = excluded.record_id, record_key = excluded.record_key,
			link_id = excluded.link_id, link_url = excluded.link_url,
			link_records = excluded.link_records,
			published = excluded.published, trouble = excluded.trouble,
			expires_at = excluded.expires_at, updated_at = excluded.updated_at`,
		l.AccountID, l.Server, l.ConnectionID, l.Token, l.Section, l.RecordID, l.RecordKey,
		l.LinkID, l.LinkURL, l.LinkRecords, l.Published, l.Trouble, l.CreatedAt, l.ExpiresAt, l.UpdatedAt)
	if err != nil {
		return fmt.Errorf("save revoked link: %w", err)
	}
	return nil
}

// RevokedLink loads one profile's connection.
func (s *Store) RevokedLink(ctx context.Context, accountID string) (RevokedLinkRow, error) {
	l, err := scanRevokedLink(s.db.QueryRowContext(ctx,
		`SELECT `+revokedLinkCols+` FROM account_revoked_links WHERE account_id = ?`, accountID))
	if errors.Is(err, sql.ErrNoRows) {
		return RevokedLinkRow{}, ErrNotFound
	}
	if err != nil {
		return RevokedLinkRow{}, fmt.Errorf("revoked link: %w", err)
	}
	return l, nil
}

// RevokedLinks lists every connection that is still worth a request: a
// lapsed one is left to the player to renew, and a paused one keeps its
// token because pausing is not ending.
func (s *Store) RevokedLinks(ctx context.Context, now int64) ([]RevokedLinkRow, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT `+revokedLinkCols+` FROM account_revoked_links
		WHERE expires_at > ? AND trouble NOT IN ('expired', 'gone')
		ORDER BY account_id`, now)
	if err != nil {
		return nil, fmt.Errorf("revoked links: %w", err)
	}
	defer func() { _ = rows.Close() }()

	var out []RevokedLinkRow
	for rows.Next() {
		l, err := scanRevokedLink(rows)
		if err != nil {
			return nil, fmt.Errorf("revoked links: %w", err)
		}
		out = append(out, l)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("revoked links: %w", err)
	}
	return out, nil
}

// UpdateRevokedLinkEntry records the entry and share a connection now has,
// and what was last written to them.
func (s *Store) UpdateRevokedLinkEntry(ctx context.Context, l RevokedLinkRow) error {
	_, err := s.db.ExecContext(ctx, `
		UPDATE account_revoked_links
		SET record_id = ?, record_key = ?, link_id = ?, link_url = ?, link_records = ?,
			published = ?, trouble = '', updated_at = ?
		WHERE account_id = ?`,
		l.RecordID, l.RecordKey, l.LinkID, l.LinkURL, l.LinkRecords, l.Published, l.UpdatedAt, l.AccountID)
	if err != nil {
		return fmt.Errorf("update revoked link entry: %w", err)
	}
	return nil
}

// MarkRevokedLinkTrouble writes down why a connection is not working. The
// row is kept either way: a paused tool works again when the player says
// so, and a lapsed one is theirs to renew.
func (s *Store) MarkRevokedLinkTrouble(ctx context.Context, accountID, trouble string, now int64) error {
	_, err := s.db.ExecContext(ctx,
		`UPDATE account_revoked_links SET trouble = ?, updated_at = ? WHERE account_id = ?`,
		trouble, now, accountID)
	if err != nil {
		return fmt.Errorf("mark revoked link trouble: %w", err)
	}
	return nil
}

// DeleteRevokedLink forgets a connection. The entry and the share stay in
// the player's vault, because they are theirs; this only stops this
// instance from writing to them.
func (s *Store) DeleteRevokedLink(ctx context.Context, accountID string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM account_revoked_links WHERE account_id = ?`, accountID)
	if err != nil {
		return fmt.Errorf("delete revoked link: %w", err)
	}
	return nil
}
