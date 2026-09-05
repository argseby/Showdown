// Command loadtest creates tables (becoming their admin), fills each with
// scripted players and reports the action -> snapshot latency distribution:
//
//	go run ./cmd/loadtest -server http://localhost:18080 -tables 20 -bots 9 -duration 60s
//
// The bots talk to the api service directly and present distinct
// X-Forwarded-For addresses (honoured with TRUST_PROXY=true) so the per-IP
// limits of §6.3 do not throttle 180 clients coming from one machine.
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"slices"
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

type client struct {
	base string
}

// call performs one JSON request; token (if set) is sent as bearer token.
func (a *client) call(ctx context.Context, method, path, token string, body any, out any) error {
	return a.callWith(ctx, method, path, token, nil, body, out)
}

func (a *client) callWith(ctx context.Context, method, path, token string, hdr http.Header, body any, out any) error {
	var rd io.Reader
	if body != nil {
		buf, _ := json.Marshal(body)
		rd = bytes.NewReader(buf)
	}
	req, err := http.NewRequestWithContext(ctx, method, a.base+path, rd)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	for k, v := range hdr {
		req.Header[k] = v
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 300 {
		return fmt.Errorf("%s %s: %d %s", method, path, resp.StatusCode, string(data))
	}
	if out != nil {
		return json.Unmarshal(data, out)
	}
	return nil
}

func run() error {
	server := flag.String("server", "http://localhost:18080", "base URL of the api service (direct, not through Caddy)")
	tables := flag.Int("tables", 20, "number of tables to create")
	bots := flag.Int("bots", 9, "players per table")
	duration := flag.Duration("duration", 60*time.Second, "measurement window after all bots joined")
	delay := flag.Duration("delay", 50*time.Millisecond, "thinking time before a bot acts")
	target := flag.Duration("target", 100*time.Millisecond, "p95 target; exit status 1 when exceeded")
	keep := flag.Bool("keep", false, "leave the tables in place instead of deleting them")
	verbose := flag.Bool("v", false, "debug logging")
	flag.Parse()
	level := slog.LevelInfo
	if *verbose {
		level = slog.LevelDebug
	}
	log := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: level}))

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	a := &client{base: strings.TrimRight(*server, "/")}

	// Short turns keep idle spots from stalling a table; the shortest allowed
	// hand delay maximises the hand rate.
	settings := map[string]any{"turn_time": 5, "disconnected_turn_time": 3, "hand_delay_ms": 2000, "max_players": max(*bots, 2)}
	ids := make([]string, 0, *tables)
	adminTokens := map[string]string{}
	for i := 0; i < *tables; i++ {
		var created struct {
			ID         string `json:"id"`
			AdminToken string `json:"admin_token"`
		}
		// Table creation is limited per IP; each creator presents its own address.
		hdr := http.Header{"X-Forwarded-For": {fmt.Sprintf("10.255.%d.%d", (i>>8)&255, i&255)}}
		if err := a.callWith(ctx, http.MethodPost, "/api/tables", "", hdr, map[string]any{"name": fmt.Sprintf("Load %d", i+1), "settings": settings}, &created); err != nil {
			return fmt.Errorf("create table %d: %w", i+1, err)
		}
		ids = append(ids, created.ID)
		adminTokens[created.ID] = created.AdminToken
	}
	log.Info("tables created", "count", len(ids))
	if !*keep {
		defer func() {
			cctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
			defer cancel()
			deleted := 0
			for _, id := range ids {
				// Pause first: delete is refused while running. Results of a
				// paused table are not written to the leaderboard.
				_ = a.call(cctx, http.MethodPost, "/api/admin/tables/"+id+"/pause", adminTokens[id], nil, nil)
				if err := a.call(cctx, http.MethodDelete, "/api/admin/tables/"+id, adminTokens[id], nil, nil); err != nil {
					log.Warn("delete failed", "table", id, "err", err)
					continue
				}
				deleted++
			}
			log.Info("tables deleted", "count", deleted)
		}()
	}

	all := make([]*botclient.Bot, 0, *tables**bots)
	for ti, id := range ids {
		for bi := 0; bi < *bots; bi++ {
			n := ti**bots + bi
			hdr := http.Header{"X-Forwarded-For": {fmt.Sprintf("10.%d.%d.%d", (n>>16)&255, (n>>8)&255, n&255)}}
			b := botclient.New(botclient.Config{
				BaseURL: a.base, TableID: id, Name: fmt.Sprintf("Load%d-%d", ti+1, bi+1),
				Strategy: botclient.StrategyRandom, Log: log, ActDelay: *delay, Header: hdr,
			})
			if err := b.Join(ctx); err != nil {
				return fmt.Errorf("join %s: %w", b.Name(), err)
			}
			all = append(all, b)
		}
	}
	log.Info("bots joined", "count", len(all))

	runCtx, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup
	for _, b := range all {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := b.Run(runCtx); err != nil {
				log.Warn("bot stopped", "bot", b.Name(), "err", err)
			}
		}()
	}
	// Warm-up: the first hands start after hand_delay_ms; do not count the
	// join burst.
	select {
	case <-ctx.Done():
	case <-time.After(3 * time.Second):
	}
	for _, b := range all {
		b.Latencies()
	}
	handsBefore := 0
	for _, b := range all {
		handsBefore += b.HandsEnded()
	}
	start := time.Now()
	log.Info("measuring", "duration", *duration, "tables", *tables, "bots_per_table", *bots)
	select {
	case <-ctx.Done():
	case <-time.After(*duration):
	}
	elapsed := time.Since(start)
	cancel()
	wg.Wait()

	var samples []time.Duration
	hands, reconnects, violations := 0, 0, 0
	for _, b := range all {
		samples = append(samples, b.Latencies()...)
		hands += b.HandsEnded()
		reconnects += b.Reconnects()
		violations += len(b.Violations())
	}
	hands = (hands - handsBefore) / max(*bots, 1) // every bot at a table counts the same hand
	if len(samples) == 0 {
		return fmt.Errorf("no actions were measured")
	}
	slices.Sort(samples)
	pct := func(p float64) time.Duration { return samples[min(len(samples)-1, int(float64(len(samples))*p))] }
	var sum time.Duration
	for _, s := range samples {
		sum += s
	}
	fmt.Printf("\naction -> snapshot latency over %s (%d tables x %d bots, delay %s)\n", elapsed.Round(time.Second), *tables, *bots, *delay)
	fmt.Printf("  samples  %d\n  mean     %s\n  p50      %s\n  p95      %s\n  p99      %s\n  max      %s\n",
		len(samples), (sum / time.Duration(len(samples))).Round(100*time.Microsecond), pct(0.50).Round(100*time.Microsecond),
		pct(0.95).Round(100*time.Microsecond), pct(0.99).Round(100*time.Microsecond), samples[len(samples)-1].Round(100*time.Microsecond))
	fmt.Printf("  hands    %d (%.1f/s)\n  reconnects %d\n  violations %d\n", hands, float64(hands)/elapsed.Seconds(), reconnects, violations)
	if violations > 0 {
		return fmt.Errorf("hole-card leaks observed")
	}
	if p95 := pct(0.95); p95 > *target {
		return fmt.Errorf("p95 %s exceeds target %s", p95.Round(100*time.Microsecond), *target)
	}
	fmt.Printf("  result   p95 within target %s\n", *target)
	return nil
}
