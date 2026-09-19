package account

import (
	"errors"
	"strings"
	"testing"
)

func TestValidateHandle(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		handle string
		want   error
	}{
		{"alice", nil},
		{"Al1ce_99", nil},
		{"ab", ErrHandleLength},
		{strings.Repeat("a", 21), ErrHandleLength},
		{"alice bob", ErrHandleChars},
		{"älice", ErrHandleChars},
		{"alice!", ErrHandleChars},
		{"admin", ErrHandleReserved},
		{"Gu_est", ErrHandleReserved},
	} {
		if err := ValidateHandle(tc.handle); !errors.Is(err, tc.want) {
			t.Errorf("ValidateHandle(%q) = %v, want %v", tc.handle, err, tc.want)
		}
	}
}

func TestKeyFoldsLookAlikes(t *testing.T) {
	t.Parallel()
	// Everything in a group must collide: one player, one name.
	for _, group := range [][]string{
		{"alice", "Alice", "al_ice", "AL1CE", "a1ice"},
		{"boss", "b05s", "bo_ss"},
	} {
		want := Key(group[0])
		for _, h := range group[1:] {
			if got := Key(h); got != want {
				t.Errorf("Key(%q) = %q, want %q (same as %q)", h, got, want, group[0])
			}
		}
	}
	if Key("alice") == Key("alicia") {
		t.Error("different names must not collide")
	}
}

func TestValidatePassword(t *testing.T) {
	t.Parallel()
	if err := ValidatePassword("hunter22"); err != nil {
		t.Errorf("8 characters: %v", err)
	}
	if err := ValidatePassword("short"); !errors.Is(err, ErrPasswordLength) {
		t.Errorf("short password: %v", err)
	}
	if err := ValidatePassword(strings.Repeat("x", 65)); !errors.Is(err, ErrPasswordLength) {
		t.Error("over-long password accepted")
	}
}

func TestRecoveryCodeAndID(t *testing.T) {
	t.Parallel()
	a, b := NewRecoveryCode(), NewRecoveryCode()
	if a == b || len(a) < 20 || !strings.Contains(a, "-") {
		t.Fatalf("recovery codes %q %q", a, b)
	}
	if id := NewID(); len(id) < 10 || id[0] != 'u' || id == NewID() {
		t.Fatalf("id %q", id)
	}
}
