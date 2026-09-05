// Command bot runs scripted players against a table for manual testing:
//
//	go run ./cmd/bot -server http://localhost:8080 -table <id> -password <pw> -count 6
package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"showdown/internal/botclient"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	server := flag.String("server", "http://localhost:8080", "base URL of the web or api service")
	tableID := flag.String("table", "", "table id (required)")
	password := flag.String("password", "", "table password if set")
	count := flag.Int("count", 6, "number of bots")
	prefix := flag.String("prefix", "Bot", "display name prefix")
	names := flag.String("names", "", "comma-separated display names (overrides -prefix and -count)")
	strategy := flag.String("strategy", "random", "random | passive | aggressive | idle")
	hands := flag.Int("hands", 0, "stop after this many hands (0 = run until interrupted)")
	delay := flag.Duration("delay", 300*time.Millisecond, "thinking time before acting")
	verbose := flag.Bool("v", false, "debug logging")
	flag.Parse()
	if *tableID == "" {
		return fmt.Errorf("-table is required")
	}
	level := slog.LevelInfo
	if *verbose {
		level = slog.LevelDebug
	}
	log := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: level}))

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	var nameList []string
	if *names != "" {
		nameList = strings.Split(*names, ",")
	} else {
		for i := 0; i < *count; i++ {
			nameList = append(nameList, fmt.Sprintf("%s%d", *prefix, i+1))
		}
	}
	bots := make([]*botclient.Bot, 0, len(nameList))
	for i, name := range nameList {
		b := botclient.New(botclient.Config{
			BaseURL: *server, TableID: *tableID, Name: strings.TrimSpace(name), Password: *password, Avatar: (i * 7) % 20,
			Strategy: botclient.Strategy(*strategy), Log: log, ActDelay: *delay,
		})
		if err := b.Join(ctx); err != nil {
			return fmt.Errorf("join failed for %s: %w", b.Name(), err)
		}
		log.Info("joined", "bot", b.Name(), "seat", b.Seat)
		bots = append(bots, b)
	}

	runCtx, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup
	for _, b := range bots {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := b.Run(runCtx); err != nil {
				log.Warn("bot stopped", "bot", b.Name(), "err", err)
			}
		}()
	}
	if *hands > 0 {
		go func() {
			for runCtx.Err() == nil {
				done := true
				for _, b := range bots {
					if b.HandsEnded() < *hands {
						done = false
					}
				}
				if done {
					cancel()
					return
				}
				time.Sleep(500 * time.Millisecond)
			}
		}()
	}
	wg.Wait()
	cancel()
	for _, b := range bots {
		s := b.Snapshot()
		var stack int64
		if s != nil {
			for _, sv := range s.Seats {
				if sv.Player != nil && sv.Player.ID == b.PlayerID {
					stack = sv.Player.Stack
				}
			}
		}
		log.Info("summary", "bot", b.Name(), "hands", b.HandsEnded(), "stack", stack, "reconnects", b.Reconnects(), "violations", len(b.Violations()))
		for _, v := range b.Violations() {
			log.Error("violation", "detail", v)
		}
	}
	return nil
}
