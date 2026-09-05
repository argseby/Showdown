package server

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"net/http"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"showdown/internal/store"
	"showdown/internal/table"
)

const (
	sessionLifetime = 30 * 24 * time.Hour
	bcryptCost      = 10
)

// newToken returns 32 random bytes, base64url encoded without padding.
func newToken() string {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic("crypto/rand unavailable: " + err.Error())
	}
	return base64.RawURLEncoding.EncodeToString(b[:])
}

// hashToken is the persisted form of a token.
func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

// bearerToken extracts the Authorization: Bearer value.
func bearerToken(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "Bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

// isTableAdmin reports whether token is the admin token of t.
func isTableAdmin(t *table.Table, token string) bool {
	if token == "" {
		return false
	}
	want := t.AdminTokenHash()
	return want != "" && subtle.ConstantTimeCompare([]byte(hashToken(token)), []byte(want)) == 1
}

// requireTableAdmin guards the per-table admin routes: the bearer token must
// be the admin token of the table named in the path ({id} or {table_id}).
// Unknown tables answer 401 as well so that ids cannot be probed.
func (s *Server) requireTableAdmin(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		if id == "" {
			id = r.PathValue("table_id")
		}
		t, ok := s.registry.Get(id)
		if !ok || !isTableAdmin(t, bearerToken(r)) {
			writeError(w, http.StatusUnauthorized, "unauthorized", "admin token of this table required")
			return
		}
		next(w, r)
	}
}

// hashPassword bcrypt-hashes a table password ("" stays "").
func hashPassword(pw string) (string, error) {
	if pw == "" {
		return "", nil
	}
	b, err := bcrypt.GenerateFromPassword([]byte(pw), bcryptCost)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func checkPassword(hash, pw string) bool {
	if hash == "" {
		return true
	}
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(pw)) == nil
}

// createSession persists a player/spectator token and returns the token.
func (s *Server) createSession(ctx context.Context, kind, tableID, playerID, name string) (string, error) {
	token := newToken()
	now := s.now()
	row := store.SessionRow{
		TokenHash: hashToken(token), Kind: kind, TableID: tableID, PlayerID: playerID, Name: name,
		CreatedAt: now.UnixMilli(), ExpiresAt: now.Add(sessionLifetime).UnixMilli(),
	}
	if err := s.store.CreateSession(ctx, row); err != nil {
		return "", err
	}
	return token, nil
}

// lookupSession resolves a player/spectator token.
func (s *Server) lookupSession(ctx context.Context, token string) (store.SessionRow, error) {
	return s.store.GetSession(ctx, hashToken(token), s.now().UnixMilli())
}
