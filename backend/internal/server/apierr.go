package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"showdown/internal/poker"
	"showdown/internal/protocol"
	"showdown/internal/store"
	"showdown/internal/table"
)

// APIError is the error envelope shared by every REST response.
type APIError struct {
	Code    string             `json:"code"`
	Message string             `json:"message"`
	Field   string             `json:"field,omitempty"`
	Fields  []table.FieldError `json:"fields,omitempty"`
}

type errorEnvelope struct {
	Error APIError `json:"error"`
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, errorEnvelope{Error: APIError{Code: code, Message: message}})
}

// writeErr maps a domain error to status + code.
func writeErr(w http.ResponseWriter, err error) {
	status, apiErr := mapError(err)
	writeJSON(w, status, errorEnvelope{Error: apiErr})
}

// mapError converts domain errors to HTTP status and API error.
func mapError(err error) (int, APIError) {
	var ve *table.ValidationError
	if errors.As(err, &ve) {
		e := APIError{Code: protocol.ErrValidation, Message: "validation failed", Fields: ve.Fields}
		if len(ve.Fields) > 0 {
			e.Field = ve.Fields[0].Field
			e.Message = ve.Fields[0].Message
		}
		return http.StatusBadRequest, e
	}
	code, status := wsErrorCode(err)
	if status == 0 {
		status = http.StatusInternalServerError
	}
	return status, APIError{Code: code, Message: err.Error()}
}

// wsErrorCode maps domain errors to protocol error codes (and an HTTP status
// for REST use; 0 for unknown errors).
func wsErrorCode(err error) (string, int) {
	switch {
	case errors.Is(err, poker.ErrNotYourTurn):
		return protocol.ErrNotYourTurn, http.StatusConflict
	case errors.Is(err, table.ErrSeatTaken):
		return protocol.ErrSeatTaken, http.StatusConflict
	case errors.Is(err, table.ErrRabbitNotAllowed):
		return protocol.ErrRabbitNotAllowed, http.StatusBadRequest
	case errors.Is(err, poker.ErrIllegalAction), errors.Is(err, poker.ErrWrongPhase), errors.Is(err, table.ErrIllegalAction):
		return protocol.ErrIllegalAction, http.StatusBadRequest
	case errors.Is(err, poker.ErrAmountOutOfRange):
		return protocol.ErrAmountOutOfRange, http.StatusBadRequest
	case errors.Is(err, poker.ErrUnknownSeat), errors.Is(err, table.ErrNotSeated):
		return protocol.ErrNotSeated, http.StatusNotFound
	case errors.Is(err, table.ErrTableEnded):
		return protocol.ErrTableEnded, http.StatusGone
	case errors.Is(err, table.ErrJoinsClosed):
		return protocol.ErrJoinsClosed, http.StatusForbidden
	case errors.Is(err, table.ErrTableFull):
		return protocol.ErrTableFull, http.StatusConflict
	case errors.Is(err, table.ErrNameTaken):
		return protocol.ErrNameTaken, http.StatusConflict
	case errors.Is(err, table.ErrInvalidName):
		return protocol.ErrInvalidName, http.StatusBadRequest
	case errors.Is(err, table.ErrSpectatorsDisabled):
		return protocol.ErrSpectatorsDisabled, http.StatusForbidden
	case errors.Is(err, table.ErrChatDisabled):
		return protocol.ErrChatDisabled, http.StatusForbidden
	case errors.Is(err, table.ErrMuted):
		return protocol.ErrMuted, http.StatusForbidden
	case errors.Is(err, table.ErrRateLimited):
		return protocol.ErrRateLimited, http.StatusTooManyRequests
	case errors.Is(err, table.ErrRebuyNotAllowed):
		return protocol.ErrRebuyNotAllowed, http.StatusConflict
	case errors.Is(err, table.ErrNotBetweenHands):
		return protocol.ErrNotBetweenHands, http.StatusConflict
	case errors.Is(err, table.ErrInvalidState):
		return protocol.ErrInvalidState, http.StatusConflict
	case errors.Is(err, table.ErrTableRunning):
		return protocol.ErrTableRunning, http.StatusConflict
	case errors.Is(err, table.ErrTooManyTables):
		return protocol.ErrTooManyTables, http.StatusConflict
	case errors.Is(err, table.ErrInvalidText):
		return protocol.ErrBadRequest, http.StatusBadRequest
	case errors.Is(err, table.ErrNotFound), errors.Is(err, store.ErrNotFound):
		return protocol.ErrNotFound, http.StatusNotFound
	}
	return protocol.ErrInternal, 0
}

const maxBodyBytes = 64 << 10

// decodeJSON reads a small JSON body into v.
func decodeJSON(w http.ResponseWriter, r *http.Request, v any) bool {
	body := http.MaxBytesReader(w, r.Body, maxBodyBytes)
	defer body.Close()
	dec := json.NewDecoder(body)
	if err := dec.Decode(v); err != nil {
		if errors.Is(err, io.EOF) {
			writeError(w, http.StatusBadRequest, protocol.ErrBadRequest, "request body required")
			return false
		}
		writeError(w, http.StatusBadRequest, protocol.ErrBadRequest, "invalid JSON: "+err.Error())
		return false
	}
	return true
}
