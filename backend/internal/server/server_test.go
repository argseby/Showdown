package server

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"showdown/internal/config"
	"showdown/internal/store"
	"showdown/internal/table"
)

func newTestServer(t *testing.T, corsOrigin string) *Server {
	t.Helper()
	log := slog.New(slog.DiscardHandler)
	st, err := store.Open(context.Background(), t.TempDir(), log)
	if err != nil {
		t.Fatalf("store.Open: %v", err)
	}
	t.Cleanup(func() { _ = st.Close() })
	cfg := config.Config{DevCORSOrigin: corsOrigin, MaxTables: 10, MaxConnectionsPerIP: 50}
	reg := table.NewRegistry(table.Deps{Store: st, Log: log}, cfg.MaxTables)
	t.Cleanup(func() { reg.Shutdown(context.Background()) })
	return New(cfg, st, reg, log)
}

func do(t *testing.T, h http.Handler, method, path string, hdr map[string]string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, path, http.NoBody)
	for k, v := range hdr {
		req.Header.Set(k, v)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestHealthz(t *testing.T) {
	t.Parallel()
	rec := do(t, newTestServer(t, "").Handler(), http.MethodGet, "/healthz", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
		t.Fatalf("content-type = %q", ct)
	}
	if rec.Header().Get("X-Request-Id") == "" {
		t.Fatal("missing X-Request-Id")
	}
	if rec.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatal("missing nosniff header")
	}
}

func TestReadyz(t *testing.T) {
	t.Parallel()
	srv := newTestServer(t, "")
	rec := do(t, srv.Handler(), http.MethodGet, "/readyz", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200: %s", rec.Code, rec.Body.String())
	}
	// A closed database must turn readiness off.
	_ = srv.store.Close()
	rec = do(t, srv.Handler(), http.MethodGet, "/readyz", nil)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status after close = %d, want 503", rec.Code)
	}
	var env struct {
		Error APIError `json:"error"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if env.Error.Code != "not_ready" {
		t.Fatalf("code = %q, want not_ready", env.Error.Code)
	}
}

func TestNotFoundIsJSON(t *testing.T) {
	t.Parallel()
	rec := do(t, newTestServer(t, "").Handler(), http.MethodGet, "/nope", nil)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", rec.Code)
	}
	var env struct {
		Error APIError `json:"error"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
		t.Fatalf("decode: %v (%s)", err, rec.Body.String())
	}
	if env.Error.Code != "not_found" {
		t.Fatalf("code = %q", env.Error.Code)
	}
}

func TestMethodNotAllowed(t *testing.T) {
	t.Parallel()
	rec := do(t, newTestServer(t, "").Handler(), http.MethodPost, "/healthz", nil)
	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want 405", rec.Code)
	}
}

func TestCORS(t *testing.T) {
	t.Parallel()
	const origin = "http://localhost:3000"
	h := newTestServer(t, origin).Handler()

	rec := do(t, h, http.MethodOptions, "/healthz", map[string]string{"Origin": origin})
	if rec.Code != http.StatusNoContent {
		t.Fatalf("preflight status = %d, want 204", rec.Code)
	}
	if rec.Header().Get("Access-Control-Allow-Origin") != origin {
		t.Fatalf("allow-origin = %q", rec.Header().Get("Access-Control-Allow-Origin"))
	}

	rec = do(t, h, http.MethodGet, "/healthz", map[string]string{"Origin": "http://evil.example"})
	if rec.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Fatal("foreign origin must not be allowed")
	}

	rec = do(t, newTestServer(t, "").Handler(), http.MethodGet, "/healthz", map[string]string{"Origin": origin})
	if rec.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Fatal("CORS must be off when DEV_CORS_ORIGIN is empty")
	}
}

func TestRecovery(t *testing.T) {
	t.Parallel()
	srv := newTestServer(t, "")
	srv.mux.HandleFunc("GET /boom", func(http.ResponseWriter, *http.Request) { panic("kaboom") })
	rec := do(t, srv.Handler(), http.MethodGet, "/boom", nil)
	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want 500", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "internal_error") {
		t.Fatalf("body = %s", rec.Body.String())
	}
}

func TestConfigEndpoint(t *testing.T) {
	t.Parallel()
	log := slog.New(slog.DiscardHandler)
	st, err := store.Open(context.Background(), t.TempDir(), log)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = st.Close() })
	cfg := config.Config{
		MaxTables: 10, MaxConnectionsPerIP: 50,
		StunURLs:       []string{"stun:stun.example.org:3478"},
		TurnURLs:       []string{"turn:relay.example.org:3478"},
		TurnUsername:   "u",
		TurnCredential: "p",
	}
	reg := table.NewRegistry(table.Deps{Store: st, Log: log}, cfg.MaxTables)
	t.Cleanup(func() { reg.Shutdown(context.Background()) })
	h := New(cfg, st, reg, log).Handler()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/config", http.NoBody))
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"ice_servers":[{"urls":["stun:stun.example.org:3478"]},`) ||
		!strings.Contains(rec.Body.String(), `{"credential":"p","urls":["turn:relay.example.org:3478"],"username":"u"}`) {
		t.Fatalf("config = %d %s", rec.Code, rec.Body.String())
	}
}
