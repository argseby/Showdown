package table

import (
	"context"
	"errors"
	"log/slog"
	"testing"
	"time"

	"showdown/internal/store"
)

func TestPersisterRetriesFailedJobs(t *testing.T) {
	st, err := store.Open(context.Background(), t.TempDir(), slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = st.Close() })
	old := persistBackoff
	persistBackoff = time.Millisecond
	t.Cleanup(func() { persistBackoff = old })

	p := newPersister(st, slog.New(slog.DiscardHandler))
	calls := 0
	done := make(chan struct{})
	p.enqueue(func(context.Context, *store.Store, *persister) error {
		calls++
		if calls < 3 {
			return errors.New("database is locked")
		}
		return nil
	})
	var order []int
	p.enqueue(func(context.Context, *store.Store, *persister) error {
		order = append(order, calls)
		close(done)
		return nil
	})
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("jobs did not complete")
	}
	p.close(context.Background())
	if calls != 3 {
		t.Fatalf("calls = %d, want 3 (two failures, then success)", calls)
	}
	if len(order) != 1 || order[0] != 3 {
		t.Fatalf("second job ran before the first succeeded: %v", order)
	}

	// A job that keeps failing is abandoned after persistAttempts and does not
	// block the queue.
	p2 := newPersister(st, slog.New(slog.DiscardHandler))
	failures := 0
	done2 := make(chan struct{})
	p2.enqueue(func(context.Context, *store.Store, *persister) error {
		failures++
		return errors.New("still locked")
	})
	p2.enqueue(func(context.Context, *store.Store, *persister) error { close(done2); return nil })
	select {
	case <-done2:
	case <-time.After(5 * time.Second):
		t.Fatal("queue blocked by a failing job")
	}
	p2.close(context.Background())
	if failures != persistAttempts {
		t.Fatalf("failures = %d, want %d", failures, persistAttempts)
	}
}
