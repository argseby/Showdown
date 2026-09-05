package store

import (
	"context"
	"log/slog"
	"testing"
	"time"
)

func TestRetentionCutoff(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 9, 5, 12, 0, 0, 0, time.UTC)
	if got := RetentionCutoff(now, 90); got != now.Add(-90*24*time.Hour).UnixMilli() {
		t.Fatalf("cutoff = %d", got)
	}
}

func TestRunRetentionPurgesOldTables(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	old := time.Now().Add(-100 * 24 * time.Hour).UnixMilli()
	if err := s.CreateTable(ctx, TableRow{ID: "old", Name: "Old", State: "ended", CreatedAt: old, EndedAt: old, ButtonSeat: -1}, sampleSettings("old")); err != nil {
		t.Fatal(err)
	}
	if _, err := s.InsertChat(ctx, ChatRow{TableID: "old", AuthorKind: "system", AuthorName: "system", Text: "x", TS: old}); err != nil {
		t.Fatal(err)
	}
	runCtx, cancel := context.WithCancel(ctx)
	done := make(chan struct{})
	go func() {
		s.RunRetention(runCtx, 90, time.Hour, slog.New(slog.DiscardHandler))
		close(done)
	}()
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		if chat, _ := s.RecentChat(ctx, "old", 10); len(chat) == 0 {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	cancel()
	<-done
	if chat, _ := s.RecentChat(ctx, "old", 10); len(chat) != 0 {
		t.Fatal("chat of the old table was not purged")
	}
	if _, _, err := s.GetTable(ctx, "old"); err != nil {
		t.Fatal("the table itself must survive retention")
	}
}
