package poker

// EventKind identifies an engine event. The names match docs/protocol.md
// §8.4; the table layer adds timestamps and strips hole cards per recipient.
type EventKind string

// Engine event kinds.
const (
	EvHandStarted      EventKind = "hand_started"
	EvAntePosted       EventKind = "ante_posted"
	EvBlindPosted      EventKind = "blind_posted"
	EvHoleCardsDealt   EventKind = "hole_cards_dealt"
	EvAction           EventKind = "action"
	EvTimeout          EventKind = "timeout"
	EvUncalledReturned EventKind = "uncalled_returned"
	EvStreetDealt      EventKind = "street_dealt"
	EvPotsUpdated      EventKind = "pots_updated"
	EvHandsRevealed    EventKind = "hands_revealed"
	// EvMucked: the seat declined to show at the showdown (beaten hand).
	EvMucked     EventKind = "mucked"
	EvPotAwarded EventKind = "pot_awarded"
	EvHandEnded  EventKind = "hand_ended"
)

// BlindKind distinguishes the two blinds in a blind_posted event.
type BlindKind string

// Blind kinds.
const (
	SmallBlind BlindKind = "small"
	BigBlind   BlindKind = "big"
	// DeadBlind is an extra big blind owed after a seat change; it goes
	// straight into the pot like an ante.
	DeadBlind BlindKind = "dead"
)

// HandStart carries the hand_started payload.
type HandStart struct {
	ButtonSeat int
	SBSeat     int
	BBSeat     int
	SmallBlind int64
	BigBlind   int64
	Ante       int64
	Stacks     map[int]int64 // seat -> stack before any posting
}

// Reveal is one revealed hand. Best holds the five cards that make the hand
// once at least a flop is out.
type Reveal struct {
	Seat        int
	Cards       []Card
	Description string
	Best        []Card
	// Shown marks which of the two cards are visible; a voluntary reveal may
	// show only one of them (Description and Best are then empty).
	Shown [2]bool
}

// Event is a single engine event. Only the fields relevant to Kind are set;
// Seat is -1 when the event is not about a particular seat.
//
//	hand_started      Start
//	ante_posted       Seat, Amount, AllIn
//	blind_posted      Seat, Blind, Amount, AllIn
//	hole_cards_dealt  Seat, Cards
//	action            Seat, Action (effective kind), Amount, AllIn
//	timeout           Seat, Action (resolved as check or fold)
//	uncalled_returned Seat, Amount
//	street_dealt      Street, Cards (the newly dealt cards)
//	pots_updated      Pots
//	hands_revealed    Reveals
//	mucked            Seat
//	pot_awarded       PotIndex, Seat, Amount, Description
//	hand_ended        Results
//
// Amount semantics for action: bet/raise carry the total bet this street
// ("raise to"); call carries the chips added; check/fold carry 0.
type Event struct {
	Seq         int
	Kind        EventKind
	Seat        int
	Amount      int64
	AllIn       bool
	Action      ActionKind
	Blind       BlindKind
	Street      Street
	Cards       []Card
	Pots        []Pot
	Reveals     []Reveal
	PotIndex    int
	Description string
	Start       *HandStart
	Results     *Results
}
