package table

import (
	"errors"
	"strings"
	"unicode"
)

// ErrInvalidName is returned for display names that break §5.6.
var ErrInvalidName = errors.New("invalid display name")

var reservedNames = map[string]bool{"system": true, "admin": true, "dealer": true}

// NormalizeName trims, collapses inner whitespace and validates a display
// name. It returns the normalized name.
func NormalizeName(raw string) (string, error) {
	name := strings.Join(strings.Fields(raw), " ")
	n := 0
	for _, r := range name {
		n++
		switch {
		case unicode.IsLetter(r), unicode.IsDigit(r):
		case r == ' ', r == '_', r == '-', r == '.':
		default:
			return "", ErrInvalidName
		}
	}
	if n < 1 || n > 20 {
		return "", ErrInvalidName
	}
	if reservedNames[NameKey(name)] {
		return "", ErrInvalidName
	}
	return name, nil
}

// NameKey is the case-insensitive comparison key for names.
func NameKey(name string) string {
	return strings.ToLower(strings.TrimSpace(name))
}
