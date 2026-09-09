// Package protocol defines the JSON wire types of docs/protocol.md. It is a
// pure data package: no game logic, no I/O. Cards travel as two-character
// strings ("As", "Td").
package protocol

import "encoding/json"

// Version is the protocol version clients must send in hello.
const Version = 1

// Envelope wraps every message. ID is set by the client on commands and
// echoed on ack/error; server pushes carry no ID.
type Envelope struct {
	Type    string          `json:"type"`
	ID      string          `json:"id,omitempty"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

// Client → server message types.
const (
	TypeHello      = "hello"
	TypeAction     = "action"
	TypeSitOut     = "sit_out"
	TypeSitIn      = "sit_in"
	TypeRebuy      = "rebuy"
	TypeLeave      = "leave"
	TypeShowCards  = "show_cards"
	TypePreAction  = "pre_action"
	TypeChangeSeat = "change_seat"
	TypeVoice      = "voice"
	// TypeVoiceSignal travels both ways: client -> server with "to", server ->
	// the target client with "from".
	TypeVoiceSignal = "voice_signal"
	TypeRabbit      = "rabbit_hunt"
	TypeSay         = "say"
	TypeStraddle    = "straddle"
	TypeRunTwice    = "run_twice"
	TypeChat        = "chat"
	TypePing        = "ping"
)

// Server → client message types.
const (
	TypeWelcome          = "welcome"
	TypeSnapshot         = "snapshot"
	TypeEvents           = "events"
	TypeChatHistory      = "chat_history"
	TypeChatRemoved      = "chat_removed"
	TypeAck              = "ack"
	TypeError            = "error"
	TypeKicked           = "kicked"
	TypeTableEnded       = "table_ended"
	TypeServerRestarting = "server_restarting"
	TypePong             = "pong"
	// TypePhrase broadcasts a quick phrase a player picked (say).
	TypePhrase = "phrase"
)

// WebSocket close codes sent by the server.
const (
	CloseBadToken           = 4001
	CloseUnsupportedVersion = 4002
	CloseTableGone          = 4003
	CloseReplaced           = 4004
	CloseKicked             = 4005
	ClosePolicy             = 1008
)

// Error codes used in error messages and REST error envelopes.
const (
	ErrUnknownType        = "unknown_type"
	ErrBadRequest         = "bad_request"
	ErrNotYourTurn        = "not_your_turn"
	ErrIllegalAction      = "illegal_action"
	ErrAmountOutOfRange   = "amount_out_of_range"
	ErrChatDisabled       = "chat_disabled"
	ErrMuted              = "muted"
	ErrRateLimited        = "rate_limited"
	ErrRebuyNotAllowed    = "rebuy_not_allowed"
	ErrNotBetweenHands    = "not_between_hands"
	ErrNotSeated          = "not_seated"
	ErrTableEnded         = "table_ended"
	ErrWrongPassword      = "wrong_password"
	ErrNameTaken          = "name_taken"
	ErrTableFull          = "table_full"
	ErrJoinsClosed        = "joins_closed"
	ErrInvalidName        = "invalid_name"
	ErrSpectatorsDisabled = "spectators_disabled"
	ErrNotFound           = "not_found"
	ErrUnauthorized       = "unauthorized"
	ErrValidation         = "validation_failed"
	ErrTableRunning       = "table_running"
	ErrInvalidState       = "invalid_state"
	ErrTooManyTables      = "too_many_tables"
	ErrSeatTaken          = "seat_taken"
	ErrRabbitNotAllowed   = "rabbit_not_allowed"
	ErrInternal           = "internal_error"
)

// ---- client payloads ------------------------------------------------------------

// Hello is the first message on a connection.
type Hello struct {
	V     int    `json:"v"`
	Token string `json:"token"`
	// AdminToken is the table's admin token; a player or spectator who also
	// presents it is flagged as the table admin (you.is_admin).
	AdminToken string `json:"admin_token,omitempty"`
}

// ActionPayload is a betting action. Amount is the total the player bets or
// raises to; it is omitted for fold/check/call/all_in.
type ActionPayload struct {
	Kind   string `json:"kind"`
	Amount int64  `json:"amount,omitempty"`
}

// ChatPayload is an outgoing chat line.
type ChatPayload struct {
	Text string `json:"text"`
}

// ShowCardsPayload selects which hole cards to show in the result phase:
// "both" (default), "first" or "second".
type ShowCardsPayload struct {
	Cards string `json:"cards,omitempty"`
}

// SayPayload picks one of the predefined quick phrases (see Phrases).
type SayPayload struct {
	Phrase string `json:"phrase"`
}

// Phrases are the quick phrases a player may say; the client translates them.
var Phrases = []string{
	"nice_hand", "nice_call", "nice_fold", "nice_bluff", "well_played", "gg",
	"thanks", "sorry", "wow", "oops", "furious", "lol", "hurry_up", "brb",
}

// PhrasePayload is a quick phrase shown next to the player's avatar.
type PhrasePayload struct {
	Seat   int    `json:"seat"`
	Name   string `json:"name"`
	Phrase string `json:"phrase"`
	TS     int64  `json:"ts"`
}

// VoicePayload announces the sender's voice-chat state: "off", "on", "muted",
// plus whether their camera is on (video travels browser to browser too).
type VoicePayload struct {
	State  string `json:"state"`
	Camera bool   `json:"camera,omitempty"`
}

// StraddlePayload arms or disarms the player's straddle: when they are the
// seat left of the big blind, they post twice the big blind before the deal.
type StraddlePayload struct {
	On bool `json:"on"`
}

// RunTwicePayload is a player's answer to running out the board twice.
type RunTwicePayload struct {
	Agree bool `json:"agree"`
}

// VoiceSignal is one WebRTC signalling message (offer, answer or ICE
// candidate) relayed between two players; Data is opaque to the server.
type VoiceSignal struct {
	To   string `json:"to,omitempty"`
	From string `json:"from,omitempty"`
	Kind string `json:"kind"` // offer | answer | ice
	Data string `json:"data"`
}

// ChangeSeatPayload asks to move to a free seat at the next deal.
type ChangeSeatPayload struct {
	Seat int `json:"seat"`
}

// PreActionPayload sets an action to be performed automatically when the
// player's turn comes: "none", "check_fold" or "call_any".
type PreActionPayload struct {
	Kind string `json:"kind"`
}

// ---- server payloads ------------------------------------------------------------

// Welcome is sent once after a successful hello.
type Welcome struct {
	You      YouIdentity `json:"you"`
	Snapshot Snapshot    `json:"snapshot"`
}

// YouIdentity identifies the connection's role.
type YouIdentity struct {
	Role     string `json:"role"` // player | spectator | admin
	PlayerID string `json:"player_id,omitempty"`
	Seat     *int   `json:"seat,omitempty"`
}

// Snapshot is the full personalized table state.
type Snapshot struct {
	ServerTS    int64              `json:"server_ts"`
	Table       TableInfo          `json:"table"`
	Seats       []SeatView         `json:"seats"`
	Hand        *HandView          `json:"hand"`
	You         You                `json:"you"`
	Leaderboard []LeaderboardEntry `json:"leaderboard"`
	Spectators  int                `json:"spectators"`
	// SpectatorNames lists the connected spectators (for the invite dialog).
	SpectatorNames []string `json:"spectator_names,omitempty"`
}

// TableInfo is the table header inside a snapshot.
type TableInfo struct {
	ID         string         `json:"id"`
	Name       string         `json:"name"`
	State      string         `json:"state"`
	HandNumber int            `json:"hand_number"`
	Settings   PublicSettings `json:"settings"`
	// NextBlindsUpTS is when the blinds go up next (blind schedule), 0 = off.
	NextBlindsUpTS int64 `json:"next_blinds_up_ts,omitempty"`
	// NextHandTS is when a pending deal fires while the table idles between
	// hands (hand_delay_ms after the end of the last hand or a join).
	NextHandTS int64 `json:"next_hand_ts,omitempty"`
}

// PublicSettings are the settings every client may see.
type PublicSettings struct {
	SmallBlind       int64  `json:"small_blind"`
	BigBlind         int64  `json:"big_blind"`
	Ante             int64  `json:"ante"`
	TurnTime         int    `json:"turn_time"`
	MaxPlayers       int    `json:"max_players"`
	StartMoney       int64  `json:"start_money"`
	JoinPolicy       string `json:"join_policy"`
	AllowRebuy       bool   `json:"allow_rebuy"`
	ShowdownReveal   string `json:"showdown_reveal"`
	ChatEnabled      bool   `json:"chat_enabled"`
	SpectatorChat    bool   `json:"spectator_chat"`
	RequiresPassword bool   `json:"requires_password"`
	// TimeBankSeconds is each player's extra thinking time (0 = off);
	// TimeBankRefillSeconds is regained per hand played without the bank.
	TimeBankSeconds       int `json:"time_bank_seconds"`
	TimeBankRefillSeconds int `json:"time_bank_refill_seconds"`
	// AllowStraddle lets the seat left of the big blind post a straddle.
	AllowStraddle bool `json:"allow_straddle"`
	// RunItTwice offers to deal the run-out twice when everyone is all-in.
	RunItTwice      bool `json:"run_it_twice"`
	AllowRabbitHunt bool `json:"allow_rabbit_hunt"`
	// Variant is the deck: "holdem" (52 cards) or "royal" (Ten to Ace only).
	Variant         string `json:"variant"`
	BlindsUpMinutes int    `json:"blinds_up_minutes"`
	BlindsUpPercent int    `json:"blinds_up_percent"`
}

// SeatView is one seat; Player is null for an empty seat.
type SeatView struct {
	Seat   int         `json:"seat"`
	Player *PlayerView `json:"player"`
}

// PlayerView is a seated player as seen by one recipient. HoleCards is
// present only for the recipient's own seat and for revealed hands.
type PlayerView struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Avatar int    `json:"avatar"`
	Voice  string `json:"voice"`            // off | on | muted
	Muted  bool   `json:"muted,omitempty"`  // chat muted by the host
	Mucked bool   `json:"mucked,omitempty"` // declined to show at the showdown
	Camera bool   `json:"camera,omitempty"` // video on (browser to browser)
	// Equity is the seat's share of the pot in percent during a run-out.
	Equity *float64 `json:"equity,omitempty"`
	// TimeBank is the player's remaining extra thinking time in seconds.
	TimeBank int `json:"time_bank,omitempty"`
	// Place is the final placement once the player is out (no rebuy) or the
	// table ended; 0 = still playing.
	Place         int         `json:"place,omitempty"`
	Stack         int64       `json:"stack"`
	Status        string      `json:"status"`
	Connected     bool        `json:"connected"`
	InHand        bool        `json:"in_hand"`
	Folded        bool        `json:"folded"`
	AllIn         bool        `json:"all_in"`
	BetThisStreet int64       `json:"bet_this_street"`
	TotalBet      int64       `json:"total_bet"`
	HoleCards     []string    `json:"hole_cards,omitempty"`
	LastAction    *LastAction `json:"last_action"`
	// HandDescription and BestCards describe a revealed hand against the
	// current board (they follow every run-out street); only set for seats
	// whose hole cards are fully revealed.
	HandDescription string   `json:"hand_description,omitempty"`
	BestCards       []string `json:"best_cards,omitempty"`
}

// LastAction is the most recent action of a player in the current hand.
type LastAction struct {
	Kind   string `json:"kind"`
	Amount int64  `json:"amount"`
}

// HandView is the current hand; nil while the table idles.
type HandView struct {
	Street     string    `json:"street"`
	Board      []string  `json:"board"`
	ButtonSeat int       `json:"button_seat"`
	SBSeat     int       `json:"sb_seat"`
	BBSeat     int       `json:"bb_seat"`
	ToActSeat  *int      `json:"to_act_seat"`
	DeadlineTS *int64    `json:"deadline_ts"`
	CurrentBet int64     `json:"current_bet"`
	MinRaiseTo int64     `json:"min_raise_to"`
	Pots       []PotView `json:"pots"`
	Phase      string    `json:"phase"` // betting | runout | showdown | result
	// RabbitCards are the cards that would have completed the board (rabbit
	// hunt in the result phase); absent otherwise.
	RabbitCards []string `json:"rabbit_cards,omitempty"`
	// PhaseEndsTS is when the showdown or result phase ends (the next deal
	// follows the result phase); absent while betting.
	PhaseEndsTS int64 `json:"phase_ends_ts,omitempty"`
	// Board2 is the second board when the hand is run twice.
	Board2 []string `json:"board2,omitempty"`
	// StraddleSeat is the seat that posted a straddle this hand.
	StraddleSeat *int `json:"straddle_seat,omitempty"`
	// TimeBankActive: the player on turn is spending their time bank.
	TimeBankActive bool `json:"time_bank_active,omitempty"`
	// RunTwice is true once everyone agreed to run it twice.
	RunTwice bool `json:"run_twice,omitempty"`
	// RunTwiceEndsTS is when the run-it-twice vote closes (during a run-out).
	RunTwiceEndsTS int64 `json:"run_twice_ends_ts,omitempty"`
}

// PotView is one pot with the seats that can win it.
type PotView struct {
	Amount        int64 `json:"amount"`
	EligibleSeats []int `json:"eligible_seats"`
}

// You is the recipient-specific part of a snapshot.
type You struct {
	Role            string       `json:"role"`
	IsAdmin         bool         `json:"is_admin"`
	PlayerID        string       `json:"player_id,omitempty"`
	Seat            *int         `json:"seat,omitempty"`
	Options         *OptionsView `json:"options"`
	HandDescription string       `json:"hand_description"`
	CanRebuy        bool         `json:"can_rebuy"`
	CanShowCards    bool         `json:"can_show_cards"`
	// PreAction is the pending automatic action ("none", "check_fold", "call_any").
	PreAction string `json:"pre_action"`
	// BestCards are the recipient's cards that make their current hand.
	BestCards []string `json:"best_cards,omitempty"`
	// CanRabbitHunt is true in the result phase when the board was not dealt
	// out and rabbit hunting is allowed.
	CanRabbitHunt bool `json:"can_rabbit_hunt"`
	// PendingSeat is the seat the player moves to at the next deal.
	PendingSeat *int `json:"pending_seat,omitempty"`
	// CanChangeSeat is false during the seat-change cooldown.
	CanChangeSeat bool `json:"can_change_seat"`
	// Straddle: the player posts a straddle whenever they are left of the
	// big blind (table setting allow_straddle).
	Straddle bool `json:"straddle,omitempty"`
	// CanRunTwice: the player may still answer the run-it-twice vote.
	CanRunTwice bool `json:"can_run_twice,omitempty"`
	// RunTwiceVote is the player's answer once given.
	RunTwiceVote *bool `json:"run_twice_vote,omitempty"`
}

// OptionsView lists the legal actions when it is the recipient's turn.
type OptionsView struct {
	Fold  bool       `json:"fold"`
	Check bool       `json:"check"`
	Call  int64      `json:"call"`
	Raise *RaiseView `json:"raise"`
	AllIn int64      `json:"all_in"`
}

// RaiseView is the legal raise-to interval.
type RaiseView struct {
	Min int64 `json:"min"`
	Max int64 `json:"max"`
}

// LeaderboardEntry is one row of the table leaderboard.
type LeaderboardEntry struct {
	Name       string `json:"name"`
	Stack      int64  `json:"stack"`
	Net        int64  `json:"net"`
	HandsWon   int    `json:"hands_won"`
	BiggestPot int64  `json:"biggest_pot"`
	// Statistics (omitted when zero): hands dealt in, hands with chips put
	// in voluntarily preflop, showdowns reached and won, final placement.
	HandsPlayed  int `json:"hands_played,omitempty"`
	VPIPHands    int `json:"vpip_hands,omitempty"`
	Showdowns    int `json:"showdowns,omitempty"`
	ShowdownsWon int `json:"showdowns_won,omitempty"`
	Place        int `json:"place,omitempty"`
}

// EventsPayload carries the events that led to the following snapshot.
type EventsPayload struct {
	HandNumber int     `json:"hand_number"`
	Events     []Event `json:"events"`
}

// Event is one hand or table event (docs/protocol.md §8.4). Only the fields
// relevant to Kind are present.
type Event struct {
	Seq  int    `json:"seq"`
	TS   int64  `json:"ts"`
	Kind string `json:"kind"`

	Seat        *int             `json:"seat,omitempty"`
	Name        string           `json:"name,omitempty"`
	Amount      *int64           `json:"amount,omitempty"`
	Delta       *int64           `json:"delta,omitempty"`
	AllIn       *bool            `json:"all_in,omitempty"`
	Action      string           `json:"action,omitempty"`      // action: fold|check|call|bet|raise
	Blind       string           `json:"blind,omitempty"`       // blind_posted: small|big
	ResolvedAs  string           `json:"resolved_as,omitempty"` // timeout: check|fold
	Street      string           `json:"street,omitempty"`
	Cards       []string         `json:"cards,omitempty"`
	Pots        []PotView        `json:"pots,omitempty"`
	Reveals     []Reveal         `json:"reveals,omitempty"`
	PotIndex    *int             `json:"pot_index,omitempty"`
	Description string           `json:"description,omitempty"`
	Results     *HandResults     `json:"results,omitempty"`
	Reason      string           `json:"reason,omitempty"`
	Fields      []string         `json:"fields,omitempty"`
	ButtonSeat  *int             `json:"button_seat,omitempty"`
	SBSeat      *int             `json:"sb_seat,omitempty"`
	BBSeat      *int             `json:"bb_seat,omitempty"`
	Blinds      *Blinds          `json:"blinds,omitempty"`
	Ante        *int64           `json:"ante,omitempty"`
	Stacks      map[string]int64 `json:"stacks,omitempty"` // seat -> stack (JSON object keys are strings)
	Board       int              `json:"board,omitempty"`  // street_dealt / pot_awarded: 2 = second board (run it twice)
}

// Blinds in a hand_started event.
type Blinds struct {
	Small int64 `json:"small"`
	Big   int64 `json:"big"`
}

// Reveal is one revealed hand. Best (the five cards forming the hand) is
// present from the flop on.
type Reveal struct {
	Seat        int      `json:"seat"`
	Cards       []string `json:"cards"` // a hidden card of a partial reveal is ""
	Description string   `json:"description"`
	Best        []string `json:"best,omitempty"`
}

// HandResults is the hand_ended payload.
type HandResults struct {
	Pots  []PotResult           `json:"pots"`
	Seats map[string]SeatResult `json:"seats"` // seat -> result
}

// PotResult is the outcome of one pot.
type PotResult struct {
	Index       int         `json:"index"`
	Amount      int64       `json:"amount"`
	Winners     []PotWinner `json:"winners"`
	Description string      `json:"description"`
	Board       int         `json:"board,omitempty"` // 1 or 2 when the hand was run twice
}

// PotWinner is one recipient of a pot.
type PotWinner struct {
	Seat   int   `json:"seat"`
	Amount int64 `json:"amount"`
}

// SeatResult is one player's outcome.
type SeatResult struct {
	Net         int64    `json:"net"`
	Won         int64    `json:"won"`
	Folded      bool     `json:"folded"`
	Revealed    bool     `json:"revealed"`
	Cards       []string `json:"cards,omitempty"`
	Description string   `json:"description,omitempty"`
	Best        []string `json:"best,omitempty"` // the five cards making the hand
}

// ChatMessage is one chat line (server → client "chat" and history entries).
type ChatMessage struct {
	ID         int64  `json:"id"`
	AuthorKind string `json:"author_kind"` // player | spectator | admin | system
	AuthorName string `json:"author_name"`
	Text       string `json:"text"`
	TS         int64  `json:"ts"`
}

// ChatHistory is sent on connect.
type ChatHistory struct {
	Messages []ChatMessage `json:"messages"`
}

// ChatRemoved announces a moderated message.
type ChatRemoved struct {
	ID int64 `json:"id"`
}

// Ack confirms a command.
type Ack struct {
	ID string `json:"id"`
}

// ErrorPayload reports a rejected command or protocol problem.
type ErrorPayload struct {
	ID      string `json:"id,omitempty"`
	Code    string `json:"code"`
	Message string `json:"message"`
}

// Kicked precedes close code 4005.
type Kicked struct {
	Reason string `json:"reason"`
}

// TableEnded carries the final standings.
type TableEnded struct {
	FinalLeaderboard []LeaderboardEntry `json:"final_leaderboard"`
}

// Pong answers a ping.
type Pong struct {
	ServerTS int64 `json:"server_ts"`
}

// ---- helpers ----------------------------------------------------------------------

// Int returns a pointer to v (for optional fields).
func Int(v int) *int { return &v }

// Int64 returns a pointer to v.
func Int64(v int64) *int64 { return &v }

// Bool returns a pointer to v.
func Bool(v bool) *bool { return &v }

// Encode builds an envelope with the payload marshalled to JSON.
func Encode(typ, id string, payload any) (Envelope, error) {
	env := Envelope{Type: typ, ID: id}
	if payload == nil {
		return env, nil
	}
	b, err := json.Marshal(payload)
	if err != nil {
		return Envelope{}, err
	}
	env.Payload = b
	return env, nil
}

// MustEncode is Encode for payloads that cannot fail to marshal.
func MustEncode(typ, id string, payload any) Envelope {
	env, err := Encode(typ, id, payload)
	if err != nil {
		panic(err)
	}
	return env
}
