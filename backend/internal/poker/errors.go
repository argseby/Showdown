package poker

import "errors"

// Errors returned by Hand methods. The table layer maps them to protocol
// error codes.
var (
	ErrNotYourTurn      = errors.New("not your turn")
	ErrIllegalAction    = errors.New("illegal action")
	ErrAmountOutOfRange = errors.New("amount out of range")
	ErrUnknownSeat      = errors.New("unknown seat")
	ErrWrongPhase       = errors.New("not allowed in this phase")
)
