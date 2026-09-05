package server

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"showdown/internal/config"
	"showdown/internal/store"
	"showdown/internal/table"
)

func TestLimiterTokenBucket(t *testing.T) {
	t.Parallel()
	l := newLimiter(60, 3) // 1 per second, burst 3
	now := time.Unix(0, 0)
	for i := 0; i < 3; i++ {
		if !l.allow("a", now) {
			t.Fatalf("request %d must pass within the burst", i)
		}
	}
	if l.allow("a", now) {
		t.Fatal("fourth request must be limited")
	}
	if !l.allow("b", now) {
		t.Fatal("other keys are independent")
	}
	if !l.allow("a", now.Add(time.Second)) {
		t.Fatal("a token must be refilled after one second")
	}
	if l.allow("a", now.Add(time.Second)) {
		t.Fatal("only one token refilled")
	}
	if !l.allow("a", now.Add(time.Hour)) {
		t.Fatal("refill after a long pause")
	}
	b := newRateBucket(20, 20, now)
	for i := 0; i < 20; i++ {
		if !b.allow(now) {
			t.Fatalf("command %d must pass", i)
		}
	}
	if b.allow(now) {
		t.Fatal("21st command in the same second must be limited")
	}
	if !b.allow(now.Add(100 * time.Millisecond)) {
		t.Fatal("2 tokens refill in 100 ms")
	}
}

func TestClientIPHonoursProxyOnlyWhenTrusted(t *testing.T) {
	t.Parallel()
	log := slog.New(slog.DiscardHandler)
	for _, trust := range []bool{true, false} {
		s := &Server{cfg: config.Config{TrustProxy: trust}, log: log}
		r := httptest.NewRequest(http.MethodGet, "/", http.NoBody)
		r.RemoteAddr = "10.0.0.9:1234"
		r.Header.Set("X-Forwarded-For", "203.0.113.7, 10.0.0.1")
		got := s.clientIP(r)
		want := "10.0.0.9"
		if trust {
			want = "203.0.113.7"
		}
		if got != want {
			t.Fatalf("trust=%v: ip = %q, want %q", trust, got, want)
		}
	}
}

// The public rate limits of docs §6.3/§6.4 answer 429 once exhausted.
func TestHTTPRateLimits(t *testing.T) {
	t.Parallel()
	log := slog.New(slog.DiscardHandler)
	st, err := store.Open(context.Background(), t.TempDir(), log)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = st.Close() })
	cfg := config.Config{MaxTables: 100, MaxConnectionsPerIP: 2}
	reg := table.NewRegistry(table.Deps{Store: st, Log: log}, cfg.MaxTables)
	t.Cleanup(func() { reg.Shutdown(context.Background()) })
	s := New(cfg, st, reg, log)
	h := s.Handler()

	post := func(path, body, ip string) int {
		req := httptest.NewRequest(http.MethodPost, path, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.RemoteAddr = ip + ":1"
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec.Code
	}

	// Table creation: 5 per minute per IP, then 429.
	for i := 0; i < 5; i++ {
		if code := post("/api/tables", `{"name":"T","settings":{}}`, "198.51.100.1"); code != http.StatusCreated {
			t.Fatalf("create %d: %d", i, code)
		}
	}
	if code := post("/api/tables", `{"name":"T","settings":{}}`, "198.51.100.1"); code != http.StatusTooManyRequests {
		t.Fatalf("6th create = %d, want 429", code)
	}
	if code := post("/api/tables", `{"name":"T","settings":{}}`, "198.51.100.2"); code != http.StatusCreated {
		t.Fatalf("other ip create = %d", code)
	}

	// Join/spectate: 10 per minute per IP (shared bucket).
	tbl, err := reg.Create(context.Background(), "T", table.DefaultSettings(), "hash")
	if err != nil {
		t.Fatal(err)
	}
	var last int
	for i := 0; i < 11; i++ {
		last = post("/api/tables/"+tbl.ID+"/join", fmt.Sprintf(`{"name":"P%d"}`, i), "198.51.100.3")
	}
	if last != http.StatusTooManyRequests {
		t.Fatalf("11th join = %d, want 429", last)
	}

	// Info: 60 per minute per IP.
	for i := 0; i < 60; i++ {
		req := httptest.NewRequest(http.MethodGet, "/api/tables/"+tbl.ID+"/info", http.NoBody)
		req.RemoteAddr = "198.51.100.4:1"
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("info %d = %d", i, rec.Code)
		}
	}
	req := httptest.NewRequest(http.MethodGet, "/api/tables/"+tbl.ID+"/info", http.NoBody)
	req.RemoteAddr = "198.51.100.4:1"
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("61st info = %d, want 429", rec.Code)
	}

	// WebSocket upgrades: 30 per minute per IP, and MAX_CONNECTIONS_PER_IP.
	srv := httptest.NewServer(h)
	t.Cleanup(srv.Close)
	wsURL := "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws/table/" + tbl.ID
	_ = wsURL
	for i := 0; i < 30; i++ {
		req := httptest.NewRequest(http.MethodGet, "/ws/table/"+tbl.ID, http.NoBody)
		req.RemoteAddr = "198.51.100.5:1"
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		if rec.Code == http.StatusTooManyRequests {
			t.Fatalf("upgrade %d limited too early", i)
		}
	}
	req = httptest.NewRequest(http.MethodGet, "/ws/table/"+tbl.ID, http.NoBody)
	req.RemoteAddr = "198.51.100.5:1"
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("31st upgrade = %d, want 429", rec.Code)
	}
	var env struct {
		Error APIError `json:"error"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil || env.Error.Code != "rate_limited" {
		t.Fatalf("body = %s", rec.Body.String())
	}
}
