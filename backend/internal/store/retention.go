package store

import (
	"context"
	"log/slog"
	"time"
)

// RetentionCutoff returns the timestamp (Unix ms) before which ended tables
// lose their hands and chat.
func RetentionCutoff(now time.Time, days int) int64 {
	return now.Add(-time.Duration(days) * 24 * time.Hour).UnixMilli()
}

// RunRetention purges once immediately and then every interval until ctx
// ends. Player results are never touched (docs §6.2).
func (s *Store) RunRetention(ctx context.Context, days int, interval time.Duration, log *slog.Logger) {
	purge := func() {
		n, err := s.PurgeEndedTableData(ctx, RetentionCutoff(time.Now(), days))
		if err != nil {
			log.Error("retention purge failed", "err", err)
			return
		}
		if n > 0 {
			log.Info("retention purge", "tables", n, "days", days)
		}
	}
	purge()
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			purge()
		}
	}
}
