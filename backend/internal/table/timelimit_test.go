package table

import (
	"context"
	"log/slog"
	"testing"
	"time"

	"showdown/internal/poker"
	"showdown/internal/store"
)

// ageTable moves this table's time-limit clock back, as if it had been
// open for that long.
func ageTable(tbl *Table, by time.Duration) {
	tbl.call(func() { tbl.limitFrom = tbl.nowMs() - by.Milliseconds() })
}

func systemLines(tbl *Table) (n int) {
	tbl.call(func() {
		for _, m := range tbl.chat {
			if m.AuthorKind == "system" {
				n++
			}
		}
	})
	return n
}

func TestTimeLimitWarnsOnceAndThenCloses(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	join(t, tbl, "Alice")
	const maxAge = time.Hour

	if soft, hard := tbl.timeLimitDue(maxAge); soft || hard {
		t.Fatalf("a table that just opened is already due: %v %v", soft, hard)
	}
	if n := systemLines(tbl); n != 0 {
		t.Fatalf("%d system lines before anything is due", n)
	}

	// Inside the warning window the table is told — once, however often
	// the sweeper comes past.
	ageTable(tbl, maxAge-TableLimitWarning+time.Minute)
	for i := 0; i < 3; i++ {
		if soft, hard := tbl.timeLimitDue(maxAge); soft || hard {
			t.Fatalf("the warning must not end anything: %v %v", soft, hard)
		}
	}
	if n := systemLines(tbl); n != 1 {
		t.Fatalf("the table was told %d times, want once", n)
	}

	// At the limit: a polite end, and the table is told that too.
	ageTable(tbl, maxAge)
	soft, hard := tbl.timeLimitDue(maxAge)
	if !soft || hard {
		t.Fatalf("at the limit: soft=%v hard=%v, want a polite end", soft, hard)
	}
	if n := systemLines(tbl); n != 2 {
		t.Fatalf("%d system lines, want the warning and the goodbye", n)
	}

	// The next pass changes nothing while the grace runs.
	if soft, hard := tbl.timeLimitDue(maxAge); soft || hard {
		t.Fatalf("the grace was skipped: %v %v", soft, hard)
	}

	// A table that still has not ended when the grace is up is ended for
	// good — the hung table this whole loop exists for.
	tbl.call(func() { tbl.limitEndAsked -= TableLimitGrace.Milliseconds() })
	if _, hard := tbl.timeLimitDue(maxAge); !hard {
		t.Fatal("the grace ran out and nothing happened")
	}
}

// An ended table is left alone, whatever its age.
func TestTimeLimitLeavesEndedTablesAlone(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	endNow(t, tbl)
	ageTable(tbl, 100*time.Hour)
	if soft, hard := tbl.timeLimitDue(time.Hour); soft || hard {
		t.Fatalf("an ended table was swept again: %v %v", soft, hard)
	}
}

// A new round on the same table starts the clock over, or the table would
// be swept away the moment the host reopened it.
func TestRestartStartsTheTimeLimitOver(t *testing.T) {
	t.Parallel()
	tbl := newTestTable(t, testSettings())
	ageTable(tbl, 10*time.Hour)
	endNow(t, tbl)
	if err := tbl.Restart(); err != nil {
		t.Fatalf("Restart: %v", err)
	}
	if soft, hard := tbl.timeLimitDue(time.Hour); soft || hard {
		t.Fatalf("the new round was due at once: %v %v", soft, hard)
	}
}

// The sweeper the binary runs: an old table is gone after a pass, a young
// one is untouched.
func TestSweepTimeLimitClosesTheOldTable(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	log := slog.New(slog.DiscardHandler)
	st, err := store.Open(ctx, t.TempDir(), log)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = st.Close() })
	deps := Deps{Store: st, Log: log, Delays: testDelays, Shuffle: func([]poker.Card) {}}
	reg := NewRegistry(deps, 5)
	t.Cleanup(func() {
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		reg.Shutdown(c)
	})

	// Registry.Create validates, so these are settings an instance would
	// really accept, not the bare-bones ones the actor tests use.
	s := DefaultSettings()
	s.TurnTime, s.DisconnectedTurnTime, s.HandDelayMs = 5, 3, 2000
	old, err := reg.Create(ctx, "Yesterday", s, "hash")
	if err != nil {
		t.Fatal(err)
	}
	fresh, err := reg.Create(ctx, "Tonight", s, "hash")
	if err != nil {
		t.Fatal(err)
	}
	ageTable(old, 7*time.Hour)

	// Nothing to do while no limit is configured.
	reg.SweepTimeLimit(0, log)
	if old.State() == StateEnded {
		t.Fatal("swept with TABLE_MAX_HOURS unset")
	}

	reg.SweepTimeLimit(6*time.Hour, log)
	waitFor(t, "the old table to close", func() bool { return old.State() == StateEnded })
	if fresh.State() == StateEnded {
		t.Fatal("the young table was closed as well")
	}
}
