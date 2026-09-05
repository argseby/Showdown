package server

import (
	"net/http"

	"showdown/internal/protocol"
	"showdown/internal/table"
)

type tableInfoResponse struct {
	Name             string `json:"name"`
	State            string `json:"state"`
	RequiresPassword bool   `json:"requires_password"`
	JoinPolicy       string `json:"join_policy"`
	AllowSpectators  bool   `json:"allow_spectators"`
	Seated           int    `json:"seated"`
	MaxPlayers       int    `json:"max_players"`
	Blinds           blinds `json:"blinds"`
	TakenSeats       []int  `json:"taken_seats"`
}

type blinds struct {
	Small int64 `json:"small_blind"`
	Big   int64 `json:"big_blind"`
}

func (s *Server) handleTableInfo(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	info := t.Info()
	writeJSON(w, http.StatusOK, tableInfoResponse{
		Name: info.Name, State: info.State, RequiresPassword: info.RequiresPassword, JoinPolicy: info.JoinPolicy,
		AllowSpectators: info.AllowSpectators, Seated: info.Seated, MaxPlayers: info.MaxPlayers,
		Blinds: blinds{Small: info.SmallBlind, Big: info.BigBlind}, TakenSeats: info.TakenSeats,
	})
}

type joinRequest struct {
	Name     string `json:"name"`
	Password string `json:"password"`
	Seat     *int   `json:"seat"`   // wanted seat; omitted = lowest free
	Avatar   *int   `json:"avatar"` // 0..19; omitted = random
}

func (s *Server) handleJoin(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	var req joinRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	info := t.Info()
	if info.State == table.StateEnded {
		writeError(w, http.StatusGone, protocol.ErrTableEnded, "table has ended")
		return
	}
	if !checkPassword(info.PasswordHash, req.Password) {
		writeError(w, http.StatusForbidden, protocol.ErrWrongPassword, "wrong table password")
		return
	}
	seat, avatar := -1, -1
	if req.Seat != nil {
		seat = *req.Seat
	}
	if req.Avatar != nil {
		avatar = *req.Avatar
	}
	res, err := t.Join(req.Name, seat, avatar)
	if err != nil {
		writeErr(w, err)
		return
	}
	token, err := s.createSession(r.Context(), table.RolePlayer, t.ID, res.PlayerID, res.Name)
	if err != nil {
		s.log.Error("create session", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not create session")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{
		"player_token": token, "player_id": res.PlayerID, "seat": res.Seat, "name": res.Name,
	})
}

func (s *Server) handleSpectate(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	var req joinRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	info := t.Info()
	if info.State == table.StateEnded {
		writeError(w, http.StatusGone, protocol.ErrTableEnded, "table has ended")
		return
	}
	if !checkPassword(info.PasswordHash, req.Password) {
		writeError(w, http.StatusForbidden, protocol.ErrWrongPassword, "wrong table password")
		return
	}
	name, err := t.Spectate(req.Name)
	if err != nil {
		writeErr(w, err)
		return
	}
	token, err := s.createSession(r.Context(), table.RoleSpectator, t.ID, "", name)
	if err != nil {
		s.log.Error("create session", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not create session")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"spectator_token": token, "name": name})
}
