package server

import (
	"encoding/json"
	"net/http"
	"strconv"

	"showdown/internal/protocol"
	"showdown/internal/store"
	"showdown/internal/table"
)

type createTableResponse struct {
	table.AdminDetail
	AdminToken string `json:"admin_token"`
}

type createTableRequest struct {
	Name     string              `json:"name"`
	Settings table.SettingsPatch `json:"settings"`
}

// handleCreateTable is public: whoever creates a table becomes its admin and
// receives the admin token exactly once, in this response.
func (s *Server) handleCreateTable(w http.ResponseWriter, r *http.Request) {
	var req createTableRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	hash := ""
	if req.Settings.Password != nil {
		if err := table.ValidatePassword(*req.Settings.Password); err != nil {
			writeErr(w, err)
			return
		}
		h, err := hashPassword(*req.Settings.Password)
		if err != nil {
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not hash password")
			return
		}
		hash = h
	}
	settings, _, _, err := table.DefaultSettings().Apply(req.Settings, hash, 0)
	if err != nil {
		writeErr(w, err)
		return
	}
	adminToken := newToken()
	t, err := s.registry.Create(r.Context(), req.Name, settings, hashToken(adminToken))
	if err != nil {
		writeErr(w, err)
		return
	}
	s.audit(r, "create_table", t.ID, "", map[string]any{"name": req.Name, "ip": s.clientIP(r)})
	writeJSON(w, http.StatusCreated, createTableResponse{AdminDetail: t.AdminDetail(), AdminToken: adminToken})
}

func (s *Server) handleAdminGetTable(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	writeJSON(w, http.StatusOK, t.AdminDetail())
}

func (s *Server) handleAdminSettings(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	var patch table.SettingsPatch
	if !decodeJSON(w, r, &patch) {
		return
	}
	hash := ""
	if patch.Password != nil {
		if err := table.ValidatePassword(*patch.Password); err != nil {
			writeErr(w, err)
			return
		}
		h, err := hashPassword(*patch.Password)
		if err != nil {
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not hash password")
			return
		}
		hash = h
	}
	changed, next, err := t.UpdateSettings(patch, hash)
	if err != nil {
		writeErr(w, err)
		return
	}
	if changed == nil {
		changed = []string{}
	}
	if next == nil {
		next = []string{}
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"changed": changed, "applies_next_hand": next, "settings": t.AdminDetail().Settings,
	})
}

func (s *Server) lifecycle(op string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		t, ok := s.tableOr404(w, r.PathValue("id"))
		if !ok {
			return
		}
		var err error
		switch op {
		case "start":
			err = t.Start()
		case "pause":
			err = t.Pause()
		case "resume":
			err = t.Resume()
		case "end":
			var req struct {
				Immediate bool `json:"immediate"`
			}
			if r.ContentLength != 0 && !decodeJSON(w, r, &req) {
				return
			}
			err = t.End(req.Immediate)
		}
		if err != nil {
			writeErr(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"state": t.State()})
	}
}

func (s *Server) handleAdminDeleteTable(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := s.registry.Delete(r.Context(), id); err != nil {
		writeErr(w, err)
		return
	}
	s.audit(r, "delete_table", id, "", nil)
	writeJSON(w, http.StatusOK, map[string]string{"status": "deleted"})
}

func (s *Server) handleAdminKick(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	if err := t.Kick(r.PathValue("pid")); err != nil {
		writeErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "kicked"})
}

func (s *Server) handleAdminChips(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	var req struct {
		Delta int64  `json:"delta"`
		Note  string `json:"note"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	applied, err := t.AdjustChips(r.PathValue("pid"), req.Delta, req.Note)
	if err != nil {
		writeErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"applied": applied, "queued": !applied})
}

func (s *Server) handleAdminMute(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	var req struct {
		Muted bool `json:"muted"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := t.Mute(r.PathValue("pid"), req.Muted); err != nil {
		writeErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"muted": req.Muted})
}

// handleAdminMuteVoice mutes a player's microphone; unmuting is the
// player's own business.
func (s *Server) handleAdminMuteVoice(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	if err := t.MuteVoice(r.PathValue("pid")); err != nil {
		writeErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"voice": table.VoiceMuted})
}

// handleAdminCameraOff turns a player's camera off; only the player turns
// it on again.
func (s *Server) handleAdminCameraOff(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	if err := t.CameraOff(r.PathValue("pid")); err != nil {
		writeErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"camera": false})
}

type handView struct {
	ID            int64           `json:"id"`
	Number        int             `json:"number"`
	StartedAt     int64           `json:"started_at"`
	EndedAt       int64           `json:"ended_at,omitempty"`
	ButtonSeat    int             `json:"button_seat"`
	SmallBlind    int64           `json:"small_blind"`
	BigBlind      int64           `json:"big_blind"`
	Ante          int64           `json:"ante"`
	StacksAtStart json.RawMessage `json:"stacks_at_start"`
	Events        json.RawMessage `json:"events"`
	Results       json.RawMessage `json:"results"`
	Voided        bool            `json:"voided"`
}

func (s *Server) handleAdminHands(w http.ResponseWriter, r *http.Request) {
	if _, ok := s.tableOr404(w, r.PathValue("id")); !ok {
		return
	}
	// The admin never sees unrevealed hole cards either.
	s.writeHands(w, r, r.PathValue("id"), -1)
}

// handleAdminBlindsUp raises the blinds now (blind schedule step).
func (s *Server) handleAdminBlindsUp(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	if err := t.BlindsUp(); err != nil {
		writeErr(w, err)
		return
	}
	s.audit(r, "blinds_up", t.ID, "", nil)
	writeJSON(w, http.StatusOK, map[string]any{"settings": t.AdminDetail().Settings})
}

// handleSessionHands serves the hand history to a player or spectator of the
// table (bearer = their session token). Hole cards are only included for the
// viewer's own seat and for seats revealed in that hand.
func (s *Server) handleSessionHands(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	viewerSeat := -1
	token := bearerToken(r)
	if isTableAdmin(t, token) {
		// admin live view without a seat
	} else {
		sess, err := s.lookupSession(r.Context(), token)
		if err != nil || sess.TableID != t.ID {
			writeError(w, http.StatusUnauthorized, protocol.ErrUnauthorized, "session token of this table required")
			return
		}
		if sess.Kind == table.RolePlayer {
			viewerSeat = t.SeatOf(sess.PlayerID)
		}
	}
	s.writeHands(w, r, t.ID, viewerSeat)
}

func (s *Server) writeHands(w http.ResponseWriter, r *http.Request, tableID string, viewerSeat int) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	before, _ := strconv.Atoi(r.URL.Query().Get("before"))
	rows, err := s.store.ListHands(r.Context(), tableID, limit, before)
	if err != nil {
		s.log.Error("list hands", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not load hands")
		return
	}
	out := make([]handView, 0, len(rows))
	for _, h := range rows {
		v := handView{
			ID: h.ID, Number: h.Number, StartedAt: h.StartedAt, EndedAt: h.EndedAt, ButtonSeat: h.ButtonSeat,
			SmallBlind: h.SmallBlind, BigBlind: h.BigBlind, Ante: h.Ante, Voided: h.Voided,
			StacksAtStart: rawOr(h.StacksAtStart, "{}"), Events: stripHoleCards(rawOr(h.Events, "[]"), h.Results, viewerSeat),
			Results: rawOr(h.Results, "null"),
		}
		out = append(out, v)
	}
	writeJSON(w, http.StatusOK, map[string]any{"hands": out})
}

// stripHoleCards removes the cards from hole_cards_dealt events of seats
// other than viewerSeat unless the hand's results say the seat was revealed.
func stripHoleCards(raw json.RawMessage, results []byte, viewerSeat int) json.RawMessage {
	var events []protocol.Event
	if err := json.Unmarshal(raw, &events); err != nil {
		return json.RawMessage("[]")
	}
	revealed := map[int]bool{}
	if len(results) > 0 {
		var res protocol.HandResults
		if json.Unmarshal(results, &res) == nil {
			for seat, sr := range res.Seats {
				if n, err := strconv.Atoi(seat); err == nil && sr.Revealed {
					revealed[n] = true
				}
			}
		}
	}
	for i := range events {
		e := &events[i]
		if e.Kind == "hole_cards_dealt" && e.Seat != nil && *e.Seat != viewerSeat && !revealed[*e.Seat] {
			e.Cards = nil
		}
	}
	b, err := json.Marshal(events)
	if err != nil {
		return json.RawMessage("[]")
	}
	return b
}

func rawOr(b []byte, def string) json.RawMessage {
	if len(b) == 0 || !json.Valid(b) {
		return json.RawMessage(def)
	}
	return json.RawMessage(b)
}

func (s *Server) handleAdminDeleteChat(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("table_id"))
	if !ok {
		return
	}
	id, err := strconv.ParseInt(r.PathValue("msg_id"), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, protocol.ErrBadRequest, "invalid message id")
		return
	}
	if err := t.RemoveChat(id); err != nil {
		writeErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "removed"})
}

func (s *Server) audit(r *http.Request, action, tableID, playerID string, details map[string]any) {
	var raw []byte
	if details != nil {
		raw, _ = json.Marshal(details)
	}
	row := store.AdminActionRow{TS: s.now().UnixMilli(), Action: action, TableID: tableID, PlayerID: playerID, Details: raw}
	if err := s.store.InsertAdminAction(r.Context(), row); err != nil {
		s.log.Error("audit", "err", err)
	}
}
