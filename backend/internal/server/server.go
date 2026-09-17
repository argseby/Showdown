// Package server wires the HTTP mux: middleware, REST handlers and the
// WebSocket transport. It never touches game state directly; everything goes
// through the table registry.
package server

import (
	"context"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"showdown/internal/buildinfo"
	"showdown/internal/config"
	"showdown/internal/store"
	"showdown/internal/table"
)

// Server holds the dependencies shared by all handlers.
type Server struct {
	cfg      config.Config
	store    *store.Store
	registry *table.Registry
	log      *slog.Logger
	mux      *http.ServeMux
	now      func() time.Time

	limJoin   *limiter
	limInfo   *limiter
	limWS     *limiter
	limCreate *limiter

	connMu    sync.Mutex
	connsByIP map[string]int
}

// New builds a Server and registers all routes.
func New(cfg config.Config, st *store.Store, reg *table.Registry, log *slog.Logger) *Server {
	s := &Server{
		cfg: cfg, store: st, registry: reg, log: log, mux: http.NewServeMux(), now: time.Now,
		limJoin:   newLimiter(10, 10),
		limInfo:   newLimiter(60, 60),
		limWS:     newLimiter(30, 30),
		limCreate: newLimiter(5, 5),
		connsByIP: map[string]int{},
	}
	s.routes()
	return s
}

// Handler returns the fully wrapped HTTP handler.
func (s *Server) Handler() http.Handler {
	var h http.Handler = http.HandlerFunc(s.dispatch)
	h = s.cors(h)
	h = s.securityHeaders(h)
	h = s.logging(h)
	h = s.recovery(h)
	h = requestID(h)
	return h
}

func (s *Server) routes() {
	s.mux.HandleFunc("GET /healthz", s.handleHealthz)
	s.mux.HandleFunc("GET /api/config", s.handleConfig)
	s.mux.HandleFunc("GET /readyz", s.handleReadyz)

	// Public API.
	s.mux.HandleFunc("GET /api/tables/{id}/info", s.rateLimited(s.limInfo, s.handleTableInfo))
	s.mux.HandleFunc("POST /api/tables/{id}/join", s.rateLimited(s.limJoin, s.handleJoin))
	s.mux.HandleFunc("POST /api/tables/{id}/spectate", s.rateLimited(s.limJoin, s.handleSpectate))
	s.mux.HandleFunc("POST /api/tables", s.rateLimited(s.limCreate, s.handleCreateTable))
	s.mux.HandleFunc("GET /api/tables/{id}/hands", s.rateLimited(s.limInfo, s.handleSessionHands))
	s.mux.HandleFunc("GET /ws/table/{id}", s.handleWS)

	// Table admin: every route is guarded by the table's own admin token.
	s.mux.HandleFunc("GET /api/admin/tables/{id}", s.requireTableAdmin(s.handleAdminGetTable))
	s.mux.HandleFunc("PATCH /api/admin/tables/{id}/settings", s.requireTableAdmin(s.handleAdminSettings))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/start", s.requireTableAdmin(s.lifecycle("start")))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/pause", s.requireTableAdmin(s.lifecycle("pause")))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/resume", s.requireTableAdmin(s.lifecycle("resume")))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/end", s.requireTableAdmin(s.lifecycle("end")))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/blinds-up", s.requireTableAdmin(s.handleAdminBlindsUp))
	s.mux.HandleFunc("DELETE /api/admin/tables/{id}", s.requireTableAdmin(s.handleAdminDeleteTable))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/players/{pid}/kick", s.requireTableAdmin(s.handleAdminKick))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/players/{pid}/chips", s.requireTableAdmin(s.handleAdminChips))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/players/{pid}/mute", s.requireTableAdmin(s.handleAdminMute))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/players/{pid}/voice-mute", s.requireTableAdmin(s.handleAdminMuteVoice))
	s.mux.HandleFunc("POST /api/admin/tables/{id}/players/{pid}/camera-off", s.requireTableAdmin(s.handleAdminCameraOff))
	s.mux.HandleFunc("GET /api/admin/tables/{id}/hands", s.requireTableAdmin(s.handleAdminHands))
	s.mux.HandleFunc("DELETE /api/admin/chat/{table_id}/{msg_id}", s.requireTableAdmin(s.handleAdminDeleteChat))
}

// dispatch routes through the mux but replaces its plain-text 404/405
// responses with the JSON error envelope.
func (s *Server) dispatch(w http.ResponseWriter, r *http.Request) {
	h, pattern := s.mux.Handler(r)
	if pattern != "" {
		// ServeMux.ServeHTTP (not h.ServeHTTP) so that path values are set.
		s.mux.ServeHTTP(w, r)
		return
	}
	probe := &probeWriter{header: http.Header{}}
	h.ServeHTTP(probe, r)
	if probe.status == http.StatusMethodNotAllowed {
		if allow := probe.header.Get("Allow"); allow != "" {
			w.Header().Set("Allow", allow)
		}
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "method not allowed")
		return
	}
	writeError(w, http.StatusNotFound, "not_found", "no such route")
}

// probeWriter captures the status and headers the mux's built-in handlers
// would have written, discarding the body.
type probeWriter struct {
	header http.Header
	status int
}

func (p *probeWriter) Header() http.Header         { return p.header }
func (p *probeWriter) WriteHeader(code int)        { p.status = code }
func (p *probeWriter) Write(b []byte) (int, error) { return len(b), nil }

func (s *Server) handleHealthz(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// handleConfig exposes the few instance settings the client needs.
func (s *Server) handleConfig(w http.ResponseWriter, _ *http.Request) {
	stun := s.cfg.StunURLs
	// ICE servers in the shape RTCPeerConnection takes: STUN without
	// credentials, the TURN relay with its long-term credentials.
	ice := []map[string]any{}
	if len(stun) > 0 {
		ice = append(ice, map[string]any{"urls": stun})
	}
	if len(s.cfg.TurnURLs) > 0 {
		ice = append(ice, map[string]any{
			"urls":       s.cfg.TurnURLs,
			"username":   s.cfg.TurnUsername,
			"credential": s.cfg.TurnCredential,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ice_servers": ice,
		// The build this instance runs, shown on the client's start screen.
		"version": buildinfo.Version(),
	})
}

func (s *Server) handleReadyz(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	if err := s.store.Ping(ctx); err != nil {
		s.log.Warn("readiness check failed", "err", err)
		writeError(w, http.StatusServiceUnavailable, "not_ready", "database unreachable")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (s *Server) tableOr404(w http.ResponseWriter, id string) (*table.Table, bool) {
	t, ok := s.registry.Get(id)
	if !ok {
		writeError(w, http.StatusNotFound, "not_found", "table not found")
		return nil, false
	}
	return t, true
}
