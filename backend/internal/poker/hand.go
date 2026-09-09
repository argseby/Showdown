package poker

import (
	"fmt"
	"sort"
)

// Street of a hand.
type Street int

// Streets in order.
const (
	Preflop Street = iota
	Flop
	Turn
	River
)

var streetNames = [...]string{"preflop", "flop", "turn", "river"}

func (s Street) String() string { return streetNames[s] }

// Phase of the hand state machine.
type Phase int

// Phases.
const (
	// PhaseBetting: a player is to act (see ToAct).
	PhaseBetting Phase = iota
	// PhaseDealPending: the betting round is over; call Advance to deal the
	// next street. Runout reports whether no further betting is possible.
	PhaseDealPending
	// PhaseShowdown: the river betting is over and hands are shown one at a
	// time in showdown order; call RevealNext until the pots are awarded.
	PhaseShowdown
	// PhaseResult: the hand is over; ShowCards is the only remaining action.
	PhaseResult
)

// RevealPolicy controls which hands are shown at showdown.
type RevealPolicy int

// Reveal policies.
const (
	RevealAll RevealPolicy = iota
	RevealWinnersOnly
	// RevealInOrder: hands are shown in showdown order (last aggressor on
	// the river first, otherwise left of the button); a hand that cannot win
	// any pot against what is already on the table is mucked instead.
	RevealInOrder
)

// ActionKind is a player action.
type ActionKind string

// Action kinds.
const (
	Fold  ActionKind = "fold"
	Check ActionKind = "check"
	Call  ActionKind = "call"
	Bet   ActionKind = "bet"
	Raise ActionKind = "raise"
	AllIn ActionKind = "all_in"
)

// Action is an intent sent by a player. Amount is the total bet this street
// for Bet and Raise ("raise to") and ignored otherwise.
type Action struct {
	Kind   ActionKind
	Amount int64
}

// HandConfig holds the table settings frozen at the start of a hand.
type HandConfig struct {
	SmallBlind int64
	BigBlind   int64
	Ante       int64
	ButtonSeat int
	Reveal     RevealPolicy
	// DeadBlinds are extra blinds owed by seat (a seat-change penalty),
	// posted into the pot after the antes without counting as a bet.
	DeadBlinds map[int]int64
	// Straddle is a live blind of StraddleAmount posted by StraddleSeat (the
	// seat left of the big blind) before the deal; 0 = none. The straddler
	// acts last preflop and the minimum raise is twice the straddle.
	StraddleSeat   int
	StraddleAmount int64
	// Variant selects the deck (Holdem unless set).
	Variant Variant
}

// Seat is a participating player at hand start.
type Seat struct {
	Seat  int
	Stack int64
}

// RaiseRange is the legal "raise to" interval.
type RaiseRange struct {
	Min int64
	Max int64
}

// Options lists what the player to act may do. Call is the number of chips
// the call adds (0 when checking is possible instead). Raise is nil when
// raising is not allowed (or only possible as a short all-in). AllIn is the
// total the player would have in front after going all-in, 0 when all-in is
// not a legal action.
type Options struct {
	Fold  bool
	Check bool
	Call  int64
	Raise *RaiseRange
	AllIn int64
}

// SeatState is the per-seat view the table layer renders into snapshots.
type SeatState struct {
	Seat          int
	Stack         int64
	InHand        bool
	Folded        bool
	AllIn         bool
	BetThisStreet int64
	TotalBet      int64
	HoleCards     []Card
	Revealed      bool
	Shown         [2]bool // per-card visibility (both true when Revealed)
	Mucked        bool    // declined to show at the showdown
	LastAction    *Action
}

// PotWinner is one recipient of a pot.
type PotWinner struct {
	Seat   int
	Amount int64
}

// PotAward is the outcome of one pot.
type PotAward struct {
	Index       int
	Amount      int64
	Winners     []PotWinner
	Description string // winning hand, empty when uncontested
	Board       int    // 0 = single board, 1 or 2 when the hand was run twice
}

// SeatResult is a player's outcome for the hand.
type SeatResult struct {
	Seat        int
	StartStack  int64
	EndStack    int64
	Net         int64
	Won         int64
	Folded      bool
	Revealed    bool
	Cards       []Card // only when revealed
	Description string // only when revealed and evaluable
	Best        []Card // the five cards making the hand, when revealed and evaluable
}

// Results summarises a finished hand.
type Results struct {
	Pots  []PotAward
	Seats map[int]SeatResult
}

type player struct {
	seat             int
	stack            int64
	startStack       int64
	hole             [2]Card
	shown            [2]bool // voluntarily shown cards (partial reveal)
	deadBlind        int64
	folded           bool
	allIn            bool
	betThisStreet    int64
	committed        int64 // completed streets and antes
	hasActed         bool
	actedAtFullLevel int64
	revealed         bool
	mucked           bool
	lastAction       *Action
	won              int64
}

// Hand is one hand of No-Limit Texas Hold'em. It is not safe for concurrent
// use; the table actor owns it.
type Hand struct {
	cfg     HandConfig
	players []*player // ascending seat order
	bySeat  map[int]*player
	deck    []Card
	deckPos int
	board   []Card
	street  Street
	phase   Phase
	runout  bool
	sbSeat  int
	bbSeat  int
	// straddleSeat is -1 unless a straddle was posted.
	straddleSeat int
	// runTwice: the run-out deals two boards; board2 holds the second.
	runTwice bool
	board2   []Card
	toAct    int // index into players, -1 when nobody
	// betting round state
	currentBet       int64
	lastFullBetLevel int64
	lastRaiseSize    int64
	seq              int
	results          *Results
	// awarded pots kept for the snapshot after the hand ended
	finalPots []Pot
	// aggressor is the index of the last player who bet or raised on the
	// current street (-1 when nobody did); it decides the showdown order.
	aggressor int
	// staged showdown: the players still to show, in order
	showOrder  []*player
	showIdx    int
	showWinner map[int]bool // seats that win at least one pot
}

// NewHand validates the inputs, shuffles a fresh deck with shuffle, posts
// antes and blinds and deals hole cards. The returned events describe all of
// that; the hand is then either in PhaseBetting or (everyone all-in) in
// PhaseDealPending.
func NewHand(cfg HandConfig, seats []Seat, shuffle func([]Card)) (*Hand, []Event, error) {
	if len(seats) < 2 {
		return nil, nil, fmt.Errorf("poker: need at least 2 players, got %d", len(seats))
	}
	if cfg.SmallBlind < 1 || cfg.BigBlind < cfg.SmallBlind || cfg.Ante < 0 {
		return nil, nil, fmt.Errorf("poker: invalid blinds sb=%d bb=%d ante=%d", cfg.SmallBlind, cfg.BigBlind, cfg.Ante)
	}
	if shuffle == nil {
		return nil, nil, fmt.Errorf("poker: shuffle function is required")
	}
	h := &Hand{cfg: cfg, bySeat: make(map[int]*player, len(seats)), toAct: -1, aggressor: -1, straddleSeat: -1}
	for _, s := range seats {
		if s.Seat < 0 {
			return nil, nil, fmt.Errorf("poker: invalid seat %d", s.Seat)
		}
		if s.Stack <= 0 {
			return nil, nil, fmt.Errorf("poker: seat %d has no chips", s.Seat)
		}
		if _, dup := h.bySeat[s.Seat]; dup {
			return nil, nil, fmt.Errorf("poker: duplicate seat %d", s.Seat)
		}
		p := &player{seat: s.Seat, stack: s.Stack, startStack: s.Stack, deadBlind: cfg.DeadBlinds[s.Seat]}
		h.players = append(h.players, p)
		h.bySeat[s.Seat] = p
	}
	sort.Slice(h.players, func(i, j int) bool { return h.players[i].seat < h.players[j].seat })
	button, ok := h.bySeat[cfg.ButtonSeat]
	if !ok {
		return nil, nil, fmt.Errorf("poker: button seat %d is not playing", cfg.ButtonSeat)
	}

	h.deck = cfg.Variant.Deck()
	if need := len(seats)*2 + 5; need > len(h.deck) {
		return nil, nil, fmt.Errorf("poker: %d players need %d cards, the %s deck has %d", len(seats), need, cfg.Variant, len(h.deck))
	}
	shuffle(h.deck)
	if len(h.deck) != cfg.Variant.DeckSize() {
		return nil, nil, fmt.Errorf("poker: shuffle changed the deck size")
	}

	bi := h.index(button.seat)
	if len(h.players) == 2 {
		h.sbSeat = button.seat
		h.bbSeat = h.players[h.next(bi)].seat
	} else {
		sbi := h.next(bi)
		h.sbSeat = h.players[sbi].seat
		h.bbSeat = h.players[h.next(sbi)].seat
	}

	var events []Event
	start := &HandStart{
		ButtonSeat: cfg.ButtonSeat, SBSeat: h.sbSeat, BBSeat: h.bbSeat,
		SmallBlind: cfg.SmallBlind, BigBlind: cfg.BigBlind, Ante: cfg.Ante,
		Stacks: make(map[int]int64, len(h.players)),
	}
	for _, p := range h.players {
		start.Stacks[p.seat] = p.stack
	}
	events = h.emit(events, Event{Kind: EvHandStarted, Seat: -1, Start: start})

	// Antes, clockwise from the seat left of the button.
	if cfg.Ante > 0 {
		for i, n := h.next(bi), 0; n < len(h.players); i, n = h.next(i), n+1 {
			p := h.players[i]
			amt := min(cfg.Ante, p.stack)
			p.stack -= amt
			p.committed += amt
			p.allIn = p.stack == 0
			events = h.emit(events, Event{Kind: EvAntePosted, Seat: p.seat, Amount: amt, AllIn: p.allIn})
		}
	}
	// Dead blinds owed by players who changed seats: into the pot, no bet.
	for i, n := h.next(bi), 0; n < len(h.players); i, n = h.next(i), n+1 {
		p := h.players[i]
		if p.deadBlind <= 0 || p.stack == 0 {
			continue
		}
		amt := min(p.deadBlind, p.stack)
		p.stack -= amt
		p.committed += amt
		p.allIn = p.stack == 0
		events = h.emit(events, Event{Kind: EvBlindPosted, Seat: p.seat, Blind: DeadBlind, Amount: amt, AllIn: p.allIn})
	}
	// Blinds.
	events = h.emit(events, h.postBlind(h.bySeat[h.sbSeat], cfg.SmallBlind, SmallBlind))
	events = h.emit(events, h.postBlind(h.bySeat[h.bbSeat], cfg.BigBlind, BigBlind))
	h.currentBet = cfg.BigBlind
	h.lastFullBetLevel = cfg.BigBlind
	h.lastRaiseSize = cfg.BigBlind
	// Straddle: a live blind by the seat left of the big blind (three or
	// more players); it sets the price and the straddler gets the option.
	if cfg.StraddleAmount > 0 && len(h.players) >= 3 {
		utg := h.players[h.next(h.index(h.bbSeat))]
		if utg.seat == cfg.StraddleSeat && utg.stack > 0 {
			ev := h.postBlind(utg, cfg.StraddleAmount, StraddleBlind)
			events = h.emit(events, ev)
			h.straddleSeat = utg.seat
			if ev.Amount >= cfg.StraddleAmount {
				h.currentBet = cfg.StraddleAmount
				h.lastFullBetLevel = cfg.StraddleAmount
				h.lastRaiseSize = cfg.StraddleAmount
			} else {
				h.currentBet = max(h.currentBet, ev.Amount)
			}
		}
	}

	// Hole cards: one at a time, clockwise starting left of the button.
	for round := 0; round < 2; round++ {
		for i, n := h.next(bi), 0; n < len(h.players); i, n = h.next(i), n+1 {
			h.players[i].hole[round] = h.draw()
		}
	}
	for i, n := h.next(bi), 0; n < len(h.players); i, n = h.next(i), n+1 {
		p := h.players[i]
		events = h.emit(events, Event{Kind: EvHoleCardsDealt, Seat: p.seat, Cards: []Card{p.hole[0], p.hole[1]}})
	}

	// First to act preflop: left of the big blind (heads-up: the button),
	// or left of the straddler.
	var first int
	switch {
	case h.straddleSeat >= 0:
		first = h.next(h.index(h.straddleSeat))
	case len(h.players) == 2:
		first = bi
	default:
		first = h.next(h.index(h.bbSeat))
	}
	h.phase = PhaseBetting
	events = h.settle(events, first, true)
	return h, events, nil
}

func (h *Hand) postBlind(p *player, amount int64, kind BlindKind) Event {
	amt := min(amount, p.stack)
	p.stack -= amt
	p.betThisStreet += amt
	p.allIn = p.stack == 0
	return Event{Kind: EvBlindPosted, Seat: p.seat, Blind: kind, Amount: amt, AllIn: p.allIn}
}

func (h *Hand) emit(events []Event, e Event) []Event {
	h.seq++
	e.Seq = h.seq
	return append(events, e)
}

func (h *Hand) draw() Card {
	c := h.deck[h.deckPos]
	h.deckPos++
	return c
}

func (h *Hand) index(seat int) int {
	for i, p := range h.players {
		if p.seat == seat {
			return i
		}
	}
	return -1
}

func (h *Hand) next(i int) int { return (i + 1) % len(h.players) }

// active reports whether p can still make decisions this hand.
func (p *player) active() bool { return !p.folded && !p.allIn }

func (p *player) total() int64 { return p.committed + p.betThisStreet }

// needsToAct reports whether p still owes an action in the current round.
func (h *Hand) needsToAct(p *player) bool {
	return p.active() && (!p.hasActed || p.betThisStreet < h.currentBet)
}

// nextActor finds the next player who needs to act, scanning from index i
// (inclusive when inclusive is true). Returns -1 when nobody does.
func (h *Hand) nextActor(i int, inclusive bool) int {
	if !inclusive {
		i = h.next(i)
	}
	for n := 0; n < len(h.players); n++ {
		if h.needsToAct(h.players[i]) {
			return i
		}
		i = h.next(i)
	}
	return -1
}

func (h *Hand) mayRaise(p *player) bool {
	return !p.hasActed || p.actedAtFullLevel < h.lastFullBetLevel
}

// ---- public state accessors -------------------------------------------------

// Phase of the hand.
func (h *Hand) Phase() Phase { return h.phase }

// Runout reports whether betting is over for good and the board is being
// dealt out (meaningful in PhaseDealPending).
func (h *Hand) Runout() bool { return h.runout }

// Done reports whether the hand has finished.
func (h *Hand) Done() bool { return h.phase == PhaseResult }

// Street currently being played.
func (h *Hand) Street() Street { return h.street }

// StraddleSeat is the seat that posted a straddle, -1 when none.
func (h *Hand) StraddleSeat() int { return h.straddleSeat }

// Board2 is the second board of a hand run twice (nil otherwise).
func (h *Hand) Board2() []Card { return append([]Card(nil), h.board2...) }

// RunTwice reports whether the run-out deals two boards.
func (h *Hand) RunTwice() bool { return h.runTwice }

// CanRunItTwice reports whether the hand is at the start of a run-out with
// cards still to come and enough of them in the deck for a second board, so
// the players may agree to run it twice.
func (h *Hand) CanRunItTwice() bool {
	missing := 5 - len(h.board)
	return h.phase == PhaseDealPending && h.runout && !h.runTwice && missing > 0 &&
		h.deckPos+2*missing <= len(h.deck)
}

// RunItTwice switches the pending run-out to two boards; every pot is split
// in halves awarded per board (odd chip to the first board).
func (h *Hand) RunItTwice() error {
	if !h.CanRunItTwice() {
		return ErrWrongPhase
	}
	h.runTwice = true
	h.board2 = append([]Card(nil), h.board...)
	return nil
}

// Board returns the community cards dealt so far.
func (h *Hand) Board() []Card { return append([]Card(nil), h.board...) }

// Variant is the deck the hand was dealt from.
func (h *Hand) Variant() Variant { return h.cfg.Variant }

// ButtonSeat, SBSeat and BBSeat identify the positions.
func (h *Hand) ButtonSeat() int { return h.cfg.ButtonSeat }

// SBSeat is the small blind seat.
func (h *Hand) SBSeat() int { return h.sbSeat }

// BBSeat is the big blind seat.
func (h *Hand) BBSeat() int { return h.bbSeat }

// CurrentBet is the highest total bet of the current street.
func (h *Hand) CurrentBet() int64 { return h.currentBet }

// MinRaiseTo is the smallest legal full raise total right now.
func (h *Hand) MinRaiseTo() int64 { return h.currentBet + h.lastRaiseSize }

// Seats lists the participating seats in ascending order.
func (h *Hand) Seats() []int {
	out := make([]int, len(h.players))
	for i, p := range h.players {
		out[i] = p.seat
	}
	return out
}

// ToAct returns the seat whose turn it is.
func (h *Hand) ToAct() (int, bool) {
	if h.phase != PhaseBetting || h.toAct < 0 {
		return 0, false
	}
	return h.players[h.toAct].seat, true
}

// Pots returns the pots built from completed streets (bets of the current
// street are still in front of the players). After the hand ended it returns
// the pots as they were awarded.
func (h *Hand) Pots() []Pot {
	if h.phase == PhaseResult {
		return clonePots(h.finalPots)
	}
	return h.pots()
}

func (h *Hand) pots() []Pot {
	pp := make([]potPlayer, len(h.players))
	for i, p := range h.players {
		pp[i] = potPlayer{seat: p.seat, total: p.committed, folded: p.folded, allIn: p.allIn}
	}
	return buildPots(pp)
}

func clonePots(pots []Pot) []Pot {
	out := make([]Pot, len(pots))
	for i, p := range pots {
		out[i] = Pot{Amount: p.Amount, Eligible: append([]int(nil), p.Eligible...)}
	}
	return out
}

// State returns the per-seat view, or ok=false for a seat not in the hand.
func (h *Hand) State(seat int) (SeatState, bool) {
	p, ok := h.bySeat[seat]
	if !ok {
		return SeatState{}, false
	}
	st := SeatState{
		Seat: p.seat, Stack: p.stack, InHand: true, Folded: p.folded, AllIn: p.allIn,
		BetThisStreet: p.betThisStreet, TotalBet: p.total(), Revealed: p.revealed, Mucked: p.mucked,
		HoleCards: []Card{p.hole[0], p.hole[1]}, Shown: p.shown,
	}
	if p.revealed {
		st.Shown = [2]bool{true, true}
	}
	if p.lastAction != nil {
		a := *p.lastAction
		st.LastAction = &a
	}
	return st, true
}

// Stack returns the seat's current stack.
func (h *Hand) Stack(seat int) (int64, bool) {
	p, ok := h.bySeat[seat]
	if !ok {
		return 0, false
	}
	return p.stack, true
}

// Description returns the seat's current best hand in words from the flop
// on, or "" before the flop or for unknown seats.
func (h *Hand) Description(seat int) string {
	p, ok := h.bySeat[seat]
	if !ok {
		return ""
	}
	if len(h.board) < 3 {
		return DescribeHole(p.hole[0], p.hole[1])
	}
	return Evaluate(append([]Card{p.hole[0], p.hole[1]}, h.board...)).Describe()
}

// DescribeHole describes two hole cards before the flop ("Pair of Aces",
// "Ace-King suited", "Queen high").
func DescribeHole(a, b Card) string {
	if a.Rank() == b.Rank() {
		return "Pair of " + a.Rank().Plural()
	}
	hi, lo := a, b
	if lo.Rank() > hi.Rank() {
		hi, lo = lo, hi
	}
	if hi.Suit() == lo.Suit() {
		return hi.Rank().Name() + "-" + lo.Rank().Name() + " suited"
	}
	return hi.Rank().Name() + " high"
}

// BestCards returns the cards that make up the seat's current best hand: the
// best five from the flop on, before that the hole cards that count (the
// pair, or the high card).
func (h *Hand) BestCards(seat int) []Card {
	p, ok := h.bySeat[seat]
	if !ok {
		return nil
	}
	if len(h.board) < 3 {
		if p.hole[0].Rank() == p.hole[1].Rank() {
			return []Card{p.hole[0], p.hole[1]}
		}
		if p.hole[0].Rank() > p.hole[1].Rank() {
			return []Card{p.hole[0]}
		}
		return []Card{p.hole[1]}
	}
	v := Evaluate(append([]Card{p.hole[0], p.hole[1]}, h.board...))
	return append([]Card(nil), v.Best[:]...)
}

// RemainingBoard returns the cards that would complete the board if the hand
// had been played out (rabbit hunting). Only meaningful once the hand is over;
// it does not change the deck.
func (h *Hand) RemainingBoard() []Card {
	missing := 5 - len(h.board)
	if missing <= 0 || h.deckPos+missing > len(h.deck) {
		return nil
	}
	return append([]Card(nil), h.deck[h.deckPos:h.deckPos+missing]...)
}

// Options returns the legal actions for seat; the zero value when it is not
// that seat's turn.
func (h *Hand) Options(seat int) Options {
	if h.phase != PhaseBetting || h.toAct < 0 || h.players[h.toAct].seat != seat {
		return Options{}
	}
	p := h.players[h.toAct]
	o := Options{Fold: true}
	toCall := h.currentBet - p.betThisStreet
	if toCall <= 0 {
		o.Check = true
	} else {
		o.Call = min(toCall, p.stack)
	}
	maxTo := p.betThisStreet + p.stack
	if h.currentBet == 0 {
		// Opening bet: min big blind, max stack; a short stack may only shove.
		minTo := h.cfg.BigBlind
		if maxTo >= minTo {
			o.Raise = &RaiseRange{Min: minTo, Max: maxTo}
		}
		o.AllIn = maxTo
		return o
	}
	if h.mayRaise(p) && maxTo > h.currentBet {
		minTo := h.MinRaiseTo()
		if maxTo >= minTo {
			o.Raise = &RaiseRange{Min: minTo, Max: maxTo}
		}
		o.AllIn = maxTo
	} else if p.stack <= toCall {
		// Cannot raise, but the whole stack is a (short) call.
		o.AllIn = maxTo
	}
	return o
}

// CanShowCards reports whether seat may voluntarily reveal in the result phase.
func (h *Hand) CanShowCards(seat int) bool {
	p, ok := h.bySeat[seat]
	return ok && h.phase == PhaseResult && !p.folded && !p.revealed
}

// Shown reports which of the seat's cards are visible to everyone.
func (h *Hand) Shown(seat int) [2]bool {
	p, ok := h.bySeat[seat]
	if !ok {
		return [2]bool{}
	}
	if p.revealed {
		return [2]bool{true, true}
	}
	return p.shown
}

// TotalChips is the chip-conservation invariant: stacks plus everything in
// front of players and in pots.
func (h *Hand) TotalChips() int64 {
	var sum int64
	for _, p := range h.players {
		sum += p.stack + p.committed + p.betThisStreet
	}
	return sum
}

// Results of a finished hand (nil before PhaseResult).
func (h *Hand) Results() *Results { return h.results }

// ---- actions ------------------------------------------------------------------

// Apply performs a on behalf of seat and returns the resulting events.
func (h *Hand) Apply(seat int, a Action) ([]Event, error) {
	if _, ok := h.bySeat[seat]; !ok {
		return nil, ErrUnknownSeat
	}
	if h.phase != PhaseBetting || h.toAct < 0 || h.players[h.toAct].seat != seat {
		return nil, ErrNotYourTurn
	}
	p := h.players[h.toAct]
	before := p.betThisStreet
	kind, err := h.perform(p, a)
	if err != nil {
		return nil, err
	}
	p.hasActed = true
	p.actedAtFullLevel = h.lastFullBetLevel
	var amount int64
	switch kind {
	case Call:
		amount = p.betThisStreet - before
	case Bet, Raise:
		amount = p.betThisStreet
		h.aggressor = h.toAct
	}
	p.lastAction = &Action{Kind: kind, Amount: amount}
	events := h.emit(nil, Event{Kind: EvAction, Seat: p.seat, Action: kind, Amount: amount, AllIn: p.allIn, Street: h.street})
	return h.settle(events, h.toAct, false), nil
}

// Timeout resolves the current turn of seat as a check if legal, else a
// fold. It returns nil when it is not that seat's turn.
func (h *Hand) Timeout(seat int) []Event {
	if h.phase != PhaseBetting || h.toAct < 0 || h.players[h.toAct].seat != seat {
		return nil
	}
	p := h.players[h.toAct]
	resolved := Fold
	if p.betThisStreet == h.currentBet {
		resolved = Check
	} else {
		p.folded = true
	}
	p.hasActed = true
	p.actedAtFullLevel = h.lastFullBetLevel
	p.lastAction = &Action{Kind: resolved}
	events := h.emit(nil, Event{Kind: EvTimeout, Seat: p.seat, Action: resolved})
	return h.settle(events, h.toAct, false)
}

// perform validates and executes the chip movement of a and returns the
// effective action kind.
func (h *Hand) perform(p *player, a Action) (ActionKind, error) {
	toCall := h.currentBet - p.betThisStreet
	maxTo := p.betThisStreet + p.stack

	kind := a.Kind
	// Be lenient about bet/raise naming: the amount semantics are identical.
	if kind == Bet && h.currentBet > 0 {
		kind = Raise
	}
	if kind == Raise && h.currentBet == 0 {
		kind = Bet
	}
	if kind == AllIn {
		switch {
		case h.currentBet == 0:
			kind, a.Amount = Bet, maxTo
		case maxTo <= h.currentBet:
			kind = Call
		default:
			kind, a.Amount = Raise, maxTo
		}
	}

	switch kind {
	case Fold:
		p.folded = true
		return Fold, nil
	case Check:
		if toCall > 0 {
			return "", ErrIllegalAction
		}
		return Check, nil
	case Call:
		if toCall <= 0 {
			return "", ErrIllegalAction
		}
		add := min(toCall, p.stack)
		h.commit(p, add)
		return Call, nil
	case Bet:
		if h.currentBet != 0 {
			return "", ErrIllegalAction
		}
		amt := a.Amount
		if amt <= 0 || amt > maxTo || (amt < h.cfg.BigBlind && amt != maxTo) {
			return "", ErrAmountOutOfRange
		}
		h.commit(p, amt)
		h.currentBet = amt
		if amt >= h.cfg.BigBlind {
			h.lastRaiseSize = amt
			h.lastFullBetLevel = amt
		}
		return Bet, nil
	case Raise:
		if !h.mayRaise(p) || maxTo <= h.currentBet {
			return "", ErrIllegalAction
		}
		amt := a.Amount
		minTo := h.MinRaiseTo()
		if amt <= h.currentBet || amt > maxTo || (amt < minTo && amt != maxTo) {
			return "", ErrAmountOutOfRange
		}
		h.commit(p, amt-p.betThisStreet)
		if amt >= minTo {
			h.lastRaiseSize = amt - h.currentBet
			h.lastFullBetLevel = amt
		}
		h.currentBet = amt
		return Raise, nil
	default:
		return "", ErrIllegalAction
	}
}

func (h *Hand) commit(p *player, add int64) {
	p.stack -= add
	p.betThisStreet += add
	p.allIn = p.stack == 0
}

// settle runs the round-end checks after any state change while betting and
// otherwise hands the turn to the next player, scanning from index from
// (inclusive or not).
func (h *Hand) settle(events []Event, from int, inclusive bool) []Event {
	if h.phase != PhaseBetting {
		return events
	}
	live := 0
	var last *player
	for _, p := range h.players {
		if !p.folded {
			live++
			last = p
		}
	}
	if live == 1 {
		return h.finishUncontested(events, last)
	}
	if h.roundComplete() {
		return h.endStreet(events)
	}
	h.toAct = h.nextActor(from, inclusive)
	if h.toAct < 0 {
		// Defensive: roundComplete was false, so somebody must need to act.
		panic("poker: no player to act although the round is not complete")
	}
	return events
}

func (h *Hand) roundComplete() bool {
	active := 0
	for _, p := range h.players {
		if p.active() {
			active++
		}
	}
	for _, p := range h.players {
		if !p.active() {
			continue
		}
		if p.betThisStreet != h.currentBet {
			return false
		}
		if active >= 2 && !p.hasActed {
			return false
		}
	}
	return true
}

// returnUncalled gives back the part of the highest bet nobody matched.
func (h *Hand) returnUncalled(events []Event) []Event {
	var top *player
	var second int64
	for _, p := range h.players {
		if top == nil || p.betThisStreet > top.betThisStreet {
			top = p
		}
	}
	if top == nil {
		return events
	}
	for _, p := range h.players {
		if p != top && p.betThisStreet > second {
			second = p.betThisStreet
		}
	}
	if diff := top.betThisStreet - second; diff > 0 {
		top.betThisStreet -= diff
		top.stack += diff
		top.allIn = false
		events = h.emit(events, Event{Kind: EvUncalledReturned, Seat: top.seat, Amount: diff})
	}
	return events
}

func (h *Hand) collect() {
	for _, p := range h.players {
		p.committed += p.betThisStreet
		p.betThisStreet = 0
	}
}

func (h *Hand) endStreet(events []Event) []Event {
	events = h.returnUncalled(events)
	h.collect()
	events = h.emit(events, Event{Kind: EvPotsUpdated, Seat: -1, Pots: h.pots()})
	h.toAct = -1
	if h.street == River {
		return h.showdown(events)
	}
	active := 0
	for _, p := range h.players {
		if p.active() {
			active++
		}
	}
	h.phase = PhaseDealPending
	if active < 2 {
		h.runout = true
		events = h.revealAll(events)
	}
	return events
}

// Advance deals the next street. Legal only in PhaseDealPending.
func (h *Hand) Advance() ([]Event, error) {
	if h.phase != PhaseDealPending {
		return nil, ErrWrongPhase
	}
	h.street++
	n := 1
	if h.street == Flop {
		n = 3
	}
	dealt := make([]Card, 0, n)
	for i := 0; i < n; i++ {
		dealt = append(dealt, h.draw())
	}
	h.board = append(h.board, dealt...)
	events := h.emit(nil, Event{Kind: EvStreetDealt, Seat: -1, Street: h.street, Cards: dealt})
	if h.runTwice {
		second := make([]Card, 0, n)
		for i := 0; i < n; i++ {
			second = append(second, h.draw())
		}
		h.board2 = append(h.board2, second...)
		events = h.emit(events, Event{Kind: EvStreetDealt, Seat: -1, Street: h.street, Cards: second, Board: 2})
	}
	if h.runout {
		if h.street == River {
			return h.showdown(events), nil
		}
		return events, nil
	}
	// New betting round.
	h.currentBet = 0
	h.lastFullBetLevel = 0
	h.lastRaiseSize = h.cfg.BigBlind
	h.aggressor = -1
	for _, p := range h.players {
		p.hasActed = false
		p.actedAtFullLevel = 0
	}
	h.phase = PhaseBetting
	return h.settle(events, h.next(h.index(h.cfg.ButtonSeat)), true), nil
}

func (h *Hand) revealAll(events []Event) []Event {
	var reveals []Reveal
	for _, p := range h.players {
		if !p.folded && !p.revealed {
			p.revealed = true
			reveals = append(reveals, h.reveal(p))
		}
	}
	if len(reveals) > 0 {
		events = h.emit(events, Event{Kind: EvHandsRevealed, Seat: -1, Reveals: reveals})
	}
	return events
}

func (h *Hand) reveal(p *player) Reveal {
	r := Reveal{Seat: p.seat, Cards: []Card{p.hole[0], p.hole[1]}, Shown: [2]bool{true, true}}
	if len(h.board) >= 3 {
		v := Evaluate(append([]Card{p.hole[0], p.hole[1]}, h.board...))
		r.Description = v.Describe()
		r.Best = append([]Card(nil), v.Best[:]...)
	}
	return r
}

// clockwiseFromButton orders seats starting left of the button.
func (h *Hand) clockwiseFromButton(seats []int) []int {
	out := append([]int(nil), seats...)
	b := h.cfg.ButtonSeat
	key := func(s int) int {
		if s > b {
			return s - b
		}
		return s + 1<<20 - b
	}
	sort.Slice(out, func(i, j int) bool { return key(out[i]) < key(out[j]) })
	return out
}

func (h *Hand) finishUncontested(events []Event, winner *player) []Event {
	events = h.returnUncalled(events)
	h.collect()
	pots := h.pots()
	events = h.emit(events, Event{Kind: EvPotsUpdated, Seat: -1, Pots: pots})
	res := &Results{Seats: make(map[int]SeatResult, len(h.players))}
	for i, pot := range pots {
		winner.stack += pot.Amount
		winner.won += pot.Amount
		res.Pots = append(res.Pots, PotAward{Index: i, Amount: pot.Amount, Winners: []PotWinner{{Seat: winner.seat, Amount: pot.Amount}}})
		events = h.emit(events, Event{Kind: EvPotAwarded, PotIndex: i, Seat: winner.seat, Amount: pot.Amount})
	}
	return h.finish(events, res, pots)
}

// potWinners evaluates every live hand and returns, per pot, the winning
// seats in clockwise order from the button.
func (h *Hand) potWinners(pots []Pot) ([][]int, map[int]HandValue) {
	return h.potWinnersOn(pots, h.board)
}

// potWinnersOn is potWinners for an explicit board (run it twice).
func (h *Hand) potWinnersOn(pots []Pot, board []Card) ([][]int, map[int]HandValue) {
	values := make(map[int]HandValue, len(h.players))
	for _, p := range h.players {
		if !p.folded {
			values[p.seat] = Evaluate(append([]Card{p.hole[0], p.hole[1]}, board...))
		}
	}
	out := make([][]int, len(pots))
	for i, pot := range pots {
		var best HandValue
		var winners []int
		for _, seat := range pot.Eligible {
			v := values[seat]
			switch c := v.Compare(best); {
			case len(winners) == 0 || c > 0:
				best, winners = v, []int{seat}
			case c == 0:
				winners = append(winners, seat)
			}
		}
		out[i] = h.clockwiseFromButton(winners)
	}
	return out, values
}

// showdownOrder lists the live players in the order they show: the last
// aggressor of the final street first, otherwise the first live seat left
// of the button, then clockwise.
func (h *Hand) showdownOrder() []*player {
	var start int
	if h.aggressor >= 0 && !h.players[h.aggressor].folded {
		start = h.aggressor
	} else {
		start = h.next(h.index(h.cfg.ButtonSeat))
		for h.players[start].folded {
			start = h.next(start)
		}
	}
	var order []*player
	for i, n := start, 0; n < len(h.players); i, n = h.next(i), n+1 {
		if !h.players[i].folded {
			order = append(order, h.players[i])
		}
	}
	return order
}

// showdown ends the river betting. When every live hand is already on the
// table (a run-out) the pots are awarded at once; otherwise the hand enters
// PhaseShowdown and the caller reveals one player at a time with RevealNext.
func (h *Hand) showdown(events []Event) []Event {
	h.toAct = -1
	order := h.showdownOrder()
	pending := false
	for _, p := range order {
		if !p.revealed {
			pending = true
		}
	}
	if !pending {
		return h.awardPots(events)
	}
	winners, _ := h.potWinners(h.pots())
	h.showWinner = map[int]bool{}
	for _, ws := range winners {
		for _, seat := range ws {
			h.showWinner[seat] = true
		}
	}
	h.showOrder = order
	h.showIdx = 0
	h.phase = PhaseShowdown
	return events
}

// ShowdownPending is the number of players still to show or muck (0 unless
// the hand is in PhaseShowdown).
func (h *Hand) ShowdownPending() int {
	if h.phase != PhaseShowdown {
		return 0
	}
	return len(h.showOrder) - h.showIdx
}

// Staged reports whether the showdown was (or is being) played out one
// player at a time rather than revealed all at once.
func (h *Hand) Staged() bool { return h.showOrder != nil }

// RevealNext shows or mucks the next player in showdown order. Legal only in
// PhaseShowdown; after the last player the pots are awarded and the hand
// reaches PhaseResult.
func (h *Hand) RevealNext() ([]Event, error) {
	if h.phase != PhaseShowdown {
		return nil, ErrWrongPhase
	}
	p := h.showOrder[h.showIdx]
	h.showIdx++
	var events []Event
	if !p.revealed {
		if h.mustShow(p) {
			p.revealed = true
			events = h.emit(events, Event{Kind: EvHandsRevealed, Seat: -1, Reveals: []Reveal{h.reveal(p)}})
		} else {
			p.mucked = true
			events = h.emit(events, Event{Kind: EvMucked, Seat: p.seat})
		}
	}
	if h.showIdx >= len(h.showOrder) {
		events = h.awardPots(events)
	}
	return events, nil
}

// mustShow decides per policy whether p shows at their turn of the showdown.
func (h *Hand) mustShow(p *player) bool {
	switch h.cfg.Reveal {
	case RevealAll:
		return true
	case RevealWinnersOnly:
		return h.showWinner[p.seat]
	}
	// In order: show unless every pot p is eligible for is already beaten
	// by a hand on the table.
	mine := Evaluate(append([]Card{p.hole[0], p.hole[1]}, h.board...))
	for _, pot := range h.pots() {
		eligible := false
		beaten := false
		for _, seat := range pot.Eligible {
			if seat == p.seat {
				eligible = true
				continue
			}
			q := h.bySeat[seat]
			if q == nil || q.folded || !q.revealed {
				continue
			}
			v := Evaluate(append([]Card{q.hole[0], q.hole[1]}, h.board...))
			if v.Compare(mine) > 0 {
				beaten = true
			}
		}
		if eligible && !beaten {
			return true
		}
	}
	return false
}

// awardPots evaluates the live hands, pays every pot and finishes the hand.
// A hand run twice pays each pot in two halves, one per board (the odd chip
// goes with the first board).
func (h *Hand) awardPots(events []Event) []Event {
	pots := h.pots()
	res := &Results{Seats: make(map[int]SeatResult, len(h.players))}
	pay := func(i int, amount int64, ws []int, desc string, board int) {
		share := amount / int64(len(ws))
		odd := amount - share*int64(len(ws))
		award := PotAward{Index: i, Amount: amount, Description: desc, Board: board}
		for _, seat := range ws {
			amt := share
			if odd > 0 {
				amt++
				odd--
			}
			p := h.bySeat[seat]
			p.stack += amt
			p.won += amt
			award.Winners = append(award.Winners, PotWinner{Seat: seat, Amount: amt})
		}
		res.Pots = append(res.Pots, award)
	}
	winners, values := h.potWinners(pots)
	var winners2 [][]int
	var values2 map[int]HandValue
	if h.runTwice {
		winners2, values2 = h.potWinnersOn(pots, h.board2)
	}
	for i, pot := range pots {
		if !h.runTwice {
			pay(i, pot.Amount, winners[i], values[winners[i][0]].Describe(), 0)
			continue
		}
		half := pot.Amount / 2
		pay(i, pot.Amount-half, winners[i], values[winners[i][0]].Describe(), 1)
		if half > 0 {
			pay(i, half, winners2[i], values2[winners2[i][0]].Describe(), 2)
		}
	}
	// Winners that have not shown yet (run-out with a late joiner is not
	// possible, but a winners-only policy without staging is) show now.
	var reveals []Reveal
	for _, p := range h.players {
		if p.folded || p.revealed {
			continue
		}
		wins := false
		for _, ws := range append(append([][]int{}, winners...), winners2...) {
			for _, seat := range ws {
				if seat == p.seat {
					wins = true
				}
			}
		}
		if wins {
			p.revealed = true
			reveals = append(reveals, h.reveal(p))
		}
	}
	if len(reveals) > 0 {
		events = h.emit(events, Event{Kind: EvHandsRevealed, Seat: -1, Reveals: reveals})
	}
	for _, award := range res.Pots {
		for _, w := range award.Winners {
			events = h.emit(events, Event{Kind: EvPotAwarded, PotIndex: award.Index, Seat: w.Seat, Amount: w.Amount, Description: award.Description, Board: award.Board})
		}
	}
	return h.finish(events, res, pots)
}

func (h *Hand) finish(events []Event, res *Results, pots []Pot) []Event {
	for _, p := range h.players {
		p.committed = 0
		sr := SeatResult{
			Seat: p.seat, StartStack: p.startStack, EndStack: p.stack,
			Net: p.stack - p.startStack, Won: p.won, Folded: p.folded, Revealed: p.revealed,
		}
		if p.revealed {
			r := h.reveal(p)
			sr.Cards, sr.Description, sr.Best = r.Cards, r.Description, r.Best
		}
		res.Seats[p.seat] = sr
	}
	h.finalPots = pots
	h.results = res
	h.phase = PhaseResult
	h.toAct = -1
	return h.emit(events, Event{Kind: EvHandEnded, Seat: -1, Results: res})
}

// ShowCards reveals seat's hand during the result phase (uncontested winner
// or a player mucked under the winners-only policy).
func (h *Hand) ShowCards(seat int, first, second bool) ([]Event, error) {
	p, ok := h.bySeat[seat]
	if !ok {
		return nil, ErrUnknownSeat
	}
	if h.phase != PhaseResult {
		return nil, ErrWrongPhase
	}
	if p.folded || p.revealed || (!first && !second) {
		return nil, ErrIllegalAction
	}
	if (first && p.shown[0] && !second) || (second && p.shown[1] && !first) {
		return nil, ErrIllegalAction // that card is already shown
	}
	p.shown[0] = p.shown[0] || first
	p.shown[1] = p.shown[1] || second
	if p.shown[0] && p.shown[1] {
		p.revealed = true
		r := h.reveal(p)
		sr := h.results.Seats[seat]
		sr.Revealed, sr.Cards, sr.Description = true, r.Cards, r.Description
		h.results.Seats[seat] = sr
		return h.emit(nil, Event{Kind: EvHandsRevealed, Seat: -1, Reveals: []Reveal{r}}), nil
	}
	// One card only: no description, no best five.
	r := Reveal{Seat: p.seat, Cards: []Card{p.hole[0], p.hole[1]}, Shown: p.shown}
	return h.emit(nil, Event{Kind: EvHandsRevealed, Seat: -1, Reveals: []Reveal{r}}), nil
}

// Forfeit folds seat immediately regardless of whose turn it is (a player
// leaving or being kicked mid-hand). Chips already committed stay in the
// pots. It returns nil when the seat is unknown, already folded, or the hand
// is over.
func (h *Hand) Forfeit(seat int) []Event {
	p, ok := h.bySeat[seat]
	if !ok || p.folded || h.phase == PhaseResult || h.phase == PhaseShowdown {
		return nil
	}
	p.folded = true
	p.lastAction = &Action{Kind: Fold}
	events := h.emit(nil, Event{Kind: EvAction, Seat: p.seat, Action: Fold})

	live := 0
	var last *player
	for _, q := range h.players {
		if !q.folded {
			live++
			last = q
		}
	}
	if live == 1 {
		// Works in both betting and deal-pending phases: bets in front (if
		// any) are settled and the pots go to the remaining player.
		h.phase = PhaseBetting
		return h.finishUncontested(events, last)
	}
	if h.phase != PhaseBetting {
		return events
	}
	idx := h.index(seat)
	if h.toAct == idx {
		return h.settle(events, idx, false)
	}
	if h.roundComplete() {
		return h.endStreet(events)
	}
	return events
}
