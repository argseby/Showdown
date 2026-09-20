// Package account holds the rules for player profiles: what a handle may
// look like, how two handles are told apart, and the password rules. The
// HTTP side lives in internal/server, the rows in internal/store.
package account

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"strings"
	"unicode"
)

// Handle limits: long enough to be a name, short enough for a seat label.
const (
	HandleMinLen = 3
	HandleMaxLen = 20
	// PasswordMinLen is the shortest password accepted; bcrypt ignores
	// anything past 72 bytes, so the maximum stays well below that.
	PasswordMinLen = 8
	PasswordMaxLen = 64
)

// Errors returned by the validators.
var (
	ErrHandleLength   = errors.New("handle must be 3–20 characters")
	ErrHandleChars    = errors.New("handle may use a–z, 0–9 and _")
	ErrHandleReserved = errors.New("handle is reserved")
	ErrPasswordLength = errors.New("password must be 8–64 characters")
)

// reserved handles nobody may take: they name the house, not a player.
var reserved = map[string]bool{
	"admin": true, "system": true, "showdown": true, "guest": true,
	"host": true, "dealer": true, "support": true, "root": true,
}

// ValidateHandle checks a handle as typed.
func ValidateHandle(handle string) error {
	if n := len(handle); n < HandleMinLen || n > HandleMaxLen {
		return ErrHandleLength
	}
	for _, r := range handle {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', unicode.IsDigit(r), r == '_':
		default:
			return ErrHandleChars
		}
	}
	if reserved[Key(handle)] {
		return ErrHandleReserved
	}
	return nil
}

// Key is the form two handles are compared by: lower case, underscores
// dropped and the look-alike characters folded together — 1, l and i are
// the same stroke in most faces, as are 0 and o, 5 and s. So "Al1ce",
// "al_ice" and "alice" are one name, and nobody sits at a table wearing
// another player's winnings.
func Key(handle string) string {
	var b strings.Builder
	b.Grow(len(handle))
	for _, r := range strings.ToLower(handle) {
		switch r {
		case '_':
		case '0':
			b.WriteRune('o')
		case '1', 'l', 'i':
			b.WriteRune('i')
		case '5':
			b.WriteRune('s')
		default:
			b.WriteRune(r)
		}
	}
	return b.String()
}

// ValidatePassword checks a password as typed.
func ValidatePassword(pw string) error {
	if n := len(pw); n < PasswordMinLen || n > PasswordMaxLen {
		return ErrPasswordLength
	}
	return nil
}

// NewRecoveryCode returns the one code a player writes down at sign-up: the
// only way back into a profile whose password is gone, since the server
// sends no mail.
func NewRecoveryCode() string {
	var b [20]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic("crypto/rand unavailable: " + err.Error())
	}
	s := base64.RawURLEncoding.EncodeToString(b[:])
	// Grouped in fours: it is meant to be written on paper.
	var out strings.Builder
	for i, r := range s {
		if i > 0 && i%4 == 0 {
			out.WriteRune('-')
		}
		out.WriteRune(r)
	}
	return out.String()
}

// NewID returns an opaque profile id. Everything inside points at this, so
// a handle can be changed later without touching a single row.
func NewID() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic("crypto/rand unavailable: " + err.Error())
	}
	return "u" + base64.RawURLEncoding.EncodeToString(b[:])
}
