package table

import "errors"

// Errors returned by table commands. The server maps them to protocol codes.
var (
	ErrTableEnded         = errors.New("table has ended")
	ErrJoinsClosed        = errors.New("joins are closed")
	ErrTableFull          = errors.New("table is full")
	ErrNameTaken          = errors.New("name is taken")
	ErrNotSeated          = errors.New("player is not seated")
	ErrNotBetweenHands    = errors.New("only allowed between hands")
	ErrRebuyNotAllowed    = errors.New("rebuy is not allowed")
	ErrChatDisabled       = errors.New("chat is disabled")
	ErrMuted              = errors.New("you are muted")
	ErrInvalidState       = errors.New("not allowed in the current table state")
	ErrSpectatorsDisabled = errors.New("spectators are not allowed")
	ErrTableRunning       = errors.New("table is running")
	ErrNotFound           = errors.New("not found")
	ErrIllegalAction      = errors.New("illegal action")
	ErrSeatTaken          = errors.New("seat taken")
	ErrRabbitNotAllowed   = errors.New("rabbit hunting not allowed")
	ErrRateLimited        = errors.New("rate limited")
)
