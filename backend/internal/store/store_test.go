package store

import (
	"context"
	"log/slog"
	"path/filepath"
	"testing"
)

func openTest(t *testing.T, dir string) *Store {
	t.Helper()
	s, err := Open(context.Background(), dir, slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	t.Cleanup(func() { _ = s.Close() })
	return s
}

func TestOpenAppliesMigrationsAndWAL(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	s := openTest(t, dir)

	var mode string
	if err := s.DB().QueryRow(`PRAGMA journal_mode`).Scan(&mode); err != nil {
		t.Fatalf("journal_mode: %v", err)
	}
	if mode != "wal" {
		t.Fatalf("journal_mode = %q, want wal", mode)
	}

	var n, maxVersion int
	if err := s.DB().QueryRow(`SELECT COUNT(*), COALESCE(MAX(version), 0) FROM schema_migrations`).Scan(&n, &maxVersion); err != nil {
		t.Fatalf("schema_migrations: %v", err)
	}
	ms, err := loadMigrations()
	if err != nil {
		t.Fatalf("loadMigrations: %v", err)
	}
	if n != len(ms) || maxVersion != ms[len(ms)-1].version {
		t.Fatalf("applied %d (max %d), want %d (max %d)", n, maxVersion, len(ms), ms[len(ms)-1].version)
	}
	if got := filepath.Join(dir, FileName); !fileExists(t, got) {
		t.Fatalf("database file %s missing", got)
	}
}

func TestOpenIsIdempotent(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	first := openTest(t, dir)
	if err := first.Close(); err != nil {
		t.Fatalf("Close: %v", err)
	}
	second := openTest(t, dir)
	var n int
	if err := second.DB().QueryRow(`SELECT COUNT(*) FROM schema_migrations`).Scan(&n); err != nil {
		t.Fatalf("count: %v", err)
	}
	ms, _ := loadMigrations()
	if n != len(ms) {
		t.Fatalf("second open applied migrations twice: %d rows", n)
	}
}

func TestMigrationsAreWellFormed(t *testing.T) {
	t.Parallel()
	ms, err := loadMigrations()
	if err != nil {
		t.Fatal(err)
	}
	if len(ms) == 0 {
		t.Fatal("no migrations embedded")
	}
	for i, m := range ms {
		if m.version != i+1 {
			t.Errorf("migration %s has version %d, want %d (versions must be contiguous)", m.name, m.version, i+1)
		}
	}
}

func TestStripComments(t *testing.T) {
	t.Parallel()
	if got := stripComments("-- a\n  -- b\n"); got != "" && got != "\n" {
		if len(trim(got)) != 0 {
			t.Fatalf("stripComments left %q", got)
		}
	}
	if got := stripComments("-- a\nCREATE TABLE x (id INTEGER);\n"); trim(got) != "CREATE TABLE x (id INTEGER);" {
		t.Fatalf("stripComments = %q", got)
	}
}

func trim(s string) string {
	for len(s) > 0 && (s[0] == '\n' || s[0] == ' ') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == '\n' || s[len(s)-1] == ' ') {
		s = s[:len(s)-1]
	}
	return s
}

func fileExists(t *testing.T, path string) bool {
	t.Helper()
	_, err := filepath.Abs(path)
	if err != nil {
		return false
	}
	_, statErr := osStat(path)
	return statErr == nil
}
