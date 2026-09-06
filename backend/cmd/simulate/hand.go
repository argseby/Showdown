package main

import (
	"sort"

	"showdown/internal/poker"
)

// handState follows one hand and re-derives the betting state from the event
// stream alone, using only the engine's public API. Every rule of
// docs/rules.md that can be stated as a property of that state is checked
// after every event; a mismatch between the derivation and what the engine
// offers is a violation.
type handState struct {
	t     *tableSim
	f     *findings
	h     *poker.Hand
	cfg   poker.HandConfig
	seats []int // seats in the hand, ascending
	total int64 // chips in play, constant for the whole hand
	start map[int]int64

	lastSeq int
	seen    [poker.DeckSize]bool
	started bool
	ended   bool

	// Chip state derived from the events alone: what each seat has put into
	// the pots, what is still in front of them, and who is out or all-in.
	// The engine hands back a whole batch of events at once, so its own
	// state is already past them; the pot checks use this instead.
	contrib map[int]int64
	bet     map[int]int64
	folded  map[int]bool
	allIn   map[int]bool

	// Betting state derived from the events (rules.md 7.5).
	currentBet    int64
	lastRaiseSize int64
	lastFullLevel int64
	acted         map[int]bool
	actedAt       map[int]int64
	straddleSeat  int

	// A new betting round has begun and its first actor is not checked yet.
	pendingFirst bool
	anchor       int

	pots    []poker.Pot // layout of the most recent pots_updated
	awarded int64
	results *poker.Results
}

func newHandState(t *tableSim, h *poker.Hand, cfg poker.HandConfig, seats []poker.Seat, total int64) *handState {
	s := &handState{
		t: t, f: t.f, h: h, cfg: cfg, total: total,
		start:   make(map[int]int64, len(seats)),
		contrib: make(map[int]int64, len(seats)),
		bet:     make(map[int]int64, len(seats)),
		folded:  make(map[int]bool, len(seats)),
		allIn:   make(map[int]bool, len(seats)),
		acted:   make(map[int]bool, len(seats)), actedAt: make(map[int]int64, len(seats)),
		straddleSeat: -1,
	}
	for _, seat := range seats {
		s.start[seat.Seat] = seat.Stack
		s.seats = append(s.seats, seat.Seat)
	}
	sort.Ints(s.seats)
	// Preflop the blinds have set the price before anyone acts.
	s.currentBet = cfg.BigBlind
	s.lastRaiseSize = cfg.BigBlind
	s.lastFullLevel = cfg.BigBlind
	s.anchor = -1 // set from the hand_started event
	return s
}

func (s *handState) ok(c checkID) { s.f.ok(c) }
func (s *handState) fail(c checkID, format string, args ...any) {
	s.f.fail(c, s.t.idx, s.t.handNo, format, args...)
}

// next returns the seat clockwise after seat.
func (s *handState) next(seat int) int {
	i := sort.SearchInts(s.seats, seat)
	return s.seats[(i+1)%len(s.seats)]
}

// consume folds a batch of events into the derived state and runs every check
// that batch enables.
func (s *handState) consume(events []poker.Event) {
	for _, e := range events {
		if e.Seq <= s.lastSeq {
			s.fail(chkEvents, "event %s has seq %d after %d", e.Kind, e.Seq, s.lastSeq)
		}
		s.lastSeq = e.Seq
		if s.ended {
			s.fail(chkEvents, "event %s after hand_ended", e.Kind)
		}
		switch e.Kind {
		case poker.EvHandStarted:
			s.handStarted(e)
		case poker.EvAntePosted:
			// Antes go straight into the pot, they are not a bet (7.2).
			s.contrib[e.Seat] += e.Amount
			s.allIn[e.Seat] = e.AllIn
		case poker.EvBlindPosted:
			if e.Blind == poker.DeadBlind {
				s.contrib[e.Seat] += e.Amount
			} else {
				s.bet[e.Seat] += e.Amount
			}
			s.allIn[e.Seat] = e.AllIn
			if e.Blind == poker.StraddleBlind && e.Amount >= s.cfg.StraddleAmount {
				s.straddleSeat = e.Seat
				s.currentBet = s.cfg.StraddleAmount
				s.lastRaiseSize = s.cfg.StraddleAmount
				s.lastFullLevel = s.cfg.StraddleAmount
			} else if e.Blind == poker.StraddleBlind {
				s.straddleSeat = e.Seat
				s.currentBet = max(s.currentBet, e.Amount)
			}
		case poker.EvHoleCardsDealt:
			if len(e.Cards) != 2 {
				s.fail(chkDeck, "seat %d got %d hole cards", e.Seat, len(e.Cards))
			}
			s.deal(e.Cards)
		case poker.EvStreetDealt:
			s.deal(e.Cards)
			if e.Board != 2 {
				s.newStreet()
			}
		case poker.EvAction:
			s.action(e)
		case poker.EvTimeout:
			s.f.timeouts++
			if e.Action == poker.Fold {
				s.folded[e.Seat] = true
			}
			s.acted[e.Seat] = true
			s.actedAt[e.Seat] = s.lastFullLevel
		case poker.EvUncalledReturned:
			// The uncalled part of the top bet goes back before the pots are
			// formed (7.5), which also lifts that player's all-in.
			s.bet[e.Seat] -= e.Amount
			s.allIn[e.Seat] = false
		case poker.EvPotsUpdated:
			s.collect()
			s.checkPots(e.Pots)
		case poker.EvPotAwarded:
			s.awarded += e.Amount
		case poker.EvHandEnded:
			s.ended = true
			s.results = e.Results
		}
	}
	s.ok(chkEvents)

	// rules.md 7.9: the chips in play never change inside a hand.
	if got := s.h.TotalChips(); got != s.total {
		s.fail(chkChips, "chips in play %d, want %d", got, s.total)
	} else {
		s.ok(chkChips)
	}

	// The first actor of a fresh betting round (7.4).
	if s.pendingFirst {
		if s.h.Phase() == poker.PhaseBetting {
			s.checkFirstActor()
		}
		s.pendingFirst = false
	}
}

func (s *handState) handStarted(e poker.Event) {
	if s.started {
		s.fail(chkEvents, "hand_started twice")
	}
	s.started = true
	if e.Start == nil {
		s.fail(chkEvents, "hand_started without payload")
		return
	}
	// rules.md 7.2: blinds sit clockwise from the button; heads-up the button
	// posts the small blind.
	wantSB := s.next(e.Start.ButtonSeat)
	if len(s.seats) == 2 {
		wantSB = e.Start.ButtonSeat
	}
	wantBB := s.next(wantSB)
	switch {
	case e.Start.ButtonSeat != s.cfg.ButtonSeat:
		s.fail(chkPositions, "button seat %d, want %d", e.Start.ButtonSeat, s.cfg.ButtonSeat)
	case e.Start.SBSeat != wantSB || s.h.SBSeat() != wantSB:
		s.fail(chkPositions, "small blind seat %d, want %d (button %d, %d players)", e.Start.SBSeat, wantSB, e.Start.ButtonSeat, len(s.seats))
	case e.Start.BBSeat != wantBB || s.h.BBSeat() != wantBB:
		s.fail(chkPositions, "big blind seat %d, want %d (button %d, %d players)", e.Start.BBSeat, wantBB, e.Start.ButtonSeat, len(s.seats))
	default:
		s.ok(chkPositions)
	}
	s.anchor = wantBB
	s.pendingFirst = true
}

// deal records dealt cards and rejects duplicates (rules.md 7.3).
func (s *handState) deal(cards []poker.Card) {
	for _, c := range cards {
		if !c.Valid() {
			s.fail(chkDeck, "invalid card %d", int(c))
			continue
		}
		if s.seen[c] {
			s.fail(chkDeck, "card %s dealt twice", c)
			continue
		}
		s.seen[c] = true
	}
	s.ok(chkDeck)
}

// newStreet resets the derived betting state for a new round (rules.md 7.5).
func (s *handState) newStreet() {
	s.currentBet = 0
	s.lastFullLevel = 0
	s.lastRaiseSize = s.cfg.BigBlind
	clear(s.acted)
	clear(s.actedAt)
	s.anchor = s.cfg.ButtonSeat
	s.pendingFirst = true
	if st := int(s.h.Street()); st >= 0 && st < len(s.f.streets) {
		s.f.streets[st]++
	}
}

// action folds one action event into the derived betting state.
func (s *handState) action(e poker.Event) {
	s.f.actions++
	if e.AllIn {
		s.f.allIns++
	}
	s.allIn[e.Seat] = e.AllIn
	switch e.Action {
	case poker.Fold:
		s.folded[e.Seat] = true
	case poker.Call:
		s.bet[e.Seat] += e.Amount // a call event carries the chips added
	case poker.Bet, poker.Raise:
		amt := e.Amount // a bet or raise event carries the total
		s.bet[e.Seat] = amt
		minTo := s.currentBet + s.lastRaiseSize
		if s.currentBet == 0 {
			minTo = s.cfg.BigBlind
		}
		if amt >= minTo {
			// A full bet or raise resets the size and reopens the action.
			if s.currentBet == 0 {
				s.lastRaiseSize = amt
			} else {
				s.lastRaiseSize = amt - s.currentBet
			}
			s.lastFullLevel = amt
		}
		s.currentBet = amt
	}
	s.acted[e.Seat] = true
	s.actedAt[e.Seat] = s.lastFullLevel
}

// mayRaise re-derives who is allowed to raise (rules.md 7.5 "Who may raise").
func (s *handState) mayRaise(seat int) bool {
	return !s.acted[seat] || s.actedAt[seat] < s.lastFullLevel
}

// checkFirstActor verifies who opens a betting round (rules.md 7.4): left of
// the big blind (or the straddle) preflop, left of the button afterwards,
// skipping folded and all-in players.
func (s *handState) checkFirstActor() {
	anchor := s.anchor
	if s.h.Street() == poker.Preflop && s.straddleSeat >= 0 {
		anchor = s.straddleSeat
	}
	want := -1
	for seat, n := s.next(anchor), 0; n < len(s.seats); seat, n = s.next(seat), n+1 {
		st, ok := s.h.State(seat)
		if ok && !st.Folded && !st.AllIn {
			want = seat
			break
		}
	}
	got, ok := s.h.ToAct()
	if !ok {
		s.fail(chkTurnOrder, "betting phase without a player to act")
		return
	}
	if want != got {
		s.fail(chkTurnOrder, "%s opens with seat %d, want seat %d (anchor %d)", s.h.Street(), got, want, anchor)
		return
	}
	s.ok(chkTurnOrder)
}

// checkTurn verifies that nobody except the seat on turn can act.
func (s *handState) checkTurn(seat int) {
	bad := 0
	for _, other := range s.seats {
		if other == seat {
			continue
		}
		bad++
		if _, err := s.h.Apply(other, poker.Action{Kind: poker.Fold}); err == nil {
			s.fail(chkTurnOrder, "seat %d folded out of turn (seat %d is to act)", other, seat)
			return
		}
	}
	if bad > 0 {
		s.ok(chkTurnOrder)
	}
}

// checkOptions re-derives the legal actions from the betting state and
// compares them with what the engine offers (rules.md 7.5).
func (s *handState) checkOptions(seat int, got poker.Options) {
	st, ok := s.h.State(seat)
	if !ok || st.Folded || st.AllIn {
		s.fail(chkOptions, "seat %d is to act but folded=%v all_in=%v", seat, st.Folded, st.AllIn)
		return
	}
	if s.currentBet != s.h.CurrentBet() {
		s.fail(chkOptions, "current bet %d, engine says %d", s.currentBet, s.h.CurrentBet())
		return
	}
	if want := s.currentBet + s.lastRaiseSize; want != s.h.MinRaiseTo() {
		s.fail(chkOptions, "minimum raise-to %d, engine says %d", want, s.h.MinRaiseTo())
		return
	}
	toCall := s.currentBet - st.BetThisStreet
	maxTo := st.BetThisStreet + st.Stack
	var want poker.Options
	want.Fold = true
	if toCall <= 0 {
		want.Check = true
	} else {
		want.Call = min(toCall, st.Stack)
	}
	switch {
	case s.currentBet == 0:
		// Opening bet: at least a big blind, or the whole stack.
		if maxTo >= s.cfg.BigBlind {
			want.Raise = &poker.RaiseRange{Min: s.cfg.BigBlind, Max: maxTo}
		}
		want.AllIn = maxTo
	case s.mayRaise(seat) && maxTo > s.currentBet:
		if minTo := s.currentBet + s.lastRaiseSize; maxTo >= minTo {
			want.Raise = &poker.RaiseRange{Min: minTo, Max: maxTo}
		}
		want.AllIn = maxTo
	case st.Stack <= toCall:
		// Raising is closed, but the whole stack is still a short call.
		want.AllIn = maxTo
	}
	if !sameOptions(want, got) {
		s.fail(chkOptions, "seat %d offered %s, want %s (current bet %d, last raise %d, full level %d)",
			seat, showOptions(got), showOptions(want), s.currentBet, s.lastRaiseSize, s.lastFullLevel)
		return
	}
	s.ok(chkOptions)
}

// checkRejects tries the illegal variants of the current turn and verifies
// they are refused without moving a chip.
func (s *handState) checkRejects(seat int, o poker.Options) {
	before := s.h.TotalChips()
	tried := 0
	bad := func(what string, a poker.Action) {
		tried++
		if _, err := s.h.Apply(seat, a); err == nil {
			s.fail(chkRejects, "seat %d: %s was accepted", seat, what)
		}
	}
	if o.Check {
		bad("calling with nothing to call", poker.Action{Kind: poker.Call})
	} else {
		bad("checking while facing a bet", poker.Action{Kind: poker.Check})
	}
	st, _ := s.h.State(seat)
	maxTo := st.BetThisStreet + st.Stack
	bad("raising past the stack", poker.Action{Kind: poker.Raise, Amount: maxTo + 1})
	bad("betting past the stack", poker.Action{Kind: poker.Bet, Amount: maxTo + 1})
	if o.Raise != nil && o.Raise.Min > 1 && o.Raise.Min-1 != o.Raise.Max {
		bad("raising below the minimum", poker.Action{Kind: poker.Raise, Amount: o.Raise.Min - 1})
		bad("betting below the minimum", poker.Action{Kind: poker.Bet, Amount: o.Raise.Min - 1})
	}
	if o.Raise == nil && o.AllIn == 0 {
		bad("going all-in while raising is closed", poker.Action{Kind: poker.AllIn})
	}
	if after := s.h.TotalChips(); after != before {
		s.fail(chkRejects, "a rejected action moved chips: %d -> %d", before, after)
		return
	}
	if tried > 0 {
		s.ok(chkRejects)
	}
}

// collect moves the chips in front of the players into their contributions,
// which is what the engine does before it publishes a pot layout.
func (s *handState) collect() {
	for seat, b := range s.bet {
		s.contrib[seat] += b
		s.bet[seat] = 0
	}
}

// checkPots rebuilds the pot layout from the contributions derived from the
// event stream and compares it with the engine's (rules.md 7.6).
func (s *handState) checkPots(got []poker.Pot) {
	var contributed, maxLive int64
	var levels []int64
	for _, seat := range s.seats {
		c := s.contrib[seat]
		if c < 0 {
			s.fail(chkPots, "seat %d contributed %d", seat, c)
			return
		}
		contributed += c
		if s.folded[seat] {
			continue
		}
		if c > maxLive {
			maxLive = c
		}
		if s.allIn[seat] && c > 0 {
			levels = append(levels, c)
		}
	}
	// One level per distinct all-in contribution, capped by the largest
	// contribution still in the hand: a folded player may have put in more
	// (a dead blind is never returned) and that excess is dead money.
	sort.Slice(levels, func(i, j int) bool { return levels[i] < levels[j] })
	uniq := levels[:0]
	for i, l := range levels {
		if i == 0 || l != levels[i-1] {
			uniq = append(uniq, l)
		}
	}
	levels = uniq
	if len(levels) == 0 || levels[len(levels)-1] < maxLive {
		levels = append(levels, maxLive)
	}
	var want []poker.Pot
	var prev, distributed int64
	for _, level := range levels {
		var amount int64
		var eligible []int
		for _, seat := range s.seats {
			c := s.contrib[seat]
			amount += min(c, level) - min(c, prev)
			if !s.folded[seat] && c >= level {
				eligible = append(eligible, seat)
			}
		}
		prev = level
		if amount == 0 {
			continue
		}
		sort.Ints(eligible)
		want = append(want, poker.Pot{Amount: amount, Eligible: eligible})
		distributed += amount
	}
	if rest := contributed - distributed; rest > 0 {
		if len(want) == 0 {
			var eligible []int
			for _, seat := range s.seats {
				if !s.folded[seat] {
					eligible = append(eligible, seat)
				}
			}
			want = []poker.Pot{{Amount: rest, Eligible: eligible}}
		} else {
			want[len(want)-1].Amount += rest
		}
	}
	if !samePots(want, got) {
		s.fail(chkPots, "pots %s, want %s (contributions %v)", showPots(got), showPots(want), s.contrib)
		return
	}
	var total int64
	for _, p := range got {
		total += p.Amount
		for _, seat := range p.Eligible {
			if s.folded[seat] {
				s.fail(chkPots, "folded seat %d is eligible for a pot", seat)
				return
			}
		}
	}
	if total != contributed {
		s.fail(chkPots, "pots hold %d, players contributed %d", total, contributed)
		return
	}
	s.pots = got
	if len(got) > 1 {
		s.f.sidePots++
	}
	if total > s.f.biggestPot {
		s.f.biggestPot = total
	}
	s.ok(chkPots)
}

// checkEnd verifies the awards and the result of a finished hand
// (rules.md 7.8) once the hand has reached the result phase.
func (s *handState) checkEnd() {
	res := s.results
	if res == nil {
		s.fail(chkResults, "hand ended without results")
		return
	}
	var stacks, net, won int64
	for _, seat := range s.seats {
		st, ok := s.h.Stack(seat)
		if !ok {
			s.fail(chkResults, "seat %d vanished", seat)
			return
		}
		r, ok := res.Seats[seat]
		if !ok {
			s.fail(chkResults, "no result for seat %d", seat)
			return
		}
		if r.StartStack != s.start[seat] || r.EndStack != st || r.Net != st-s.start[seat] {
			s.fail(chkResults, "seat %d result start=%d end=%d net=%d, want %d/%d/%d",
				seat, r.StartStack, r.EndStack, r.Net, s.start[seat], st, st-s.start[seat])
			return
		}
		stacks += st
		net += r.Net
		won += r.Won
	}
	if stacks != s.total || net != 0 {
		s.fail(chkResults, "final stacks %d (want %d), net sum %d (want 0)", stacks, s.total, net)
		return
	}
	var potTotal, awardTotal int64
	for _, p := range s.pots {
		potTotal += p.Amount
	}
	for _, a := range res.Pots {
		var sum int64
		for _, w := range a.Winners {
			sum += w.Amount
		}
		if sum != a.Amount || len(a.Winners) == 0 {
			s.fail(chkResults, "pot %d of %d went to %d winners totalling %d", a.Index, a.Amount, len(a.Winners), sum)
			return
		}
		awardTotal += a.Amount
	}
	if awardTotal != potTotal || awardTotal != s.awarded || awardTotal != won {
		s.fail(chkResults, "awarded %d, pots held %d, events said %d, seats won %d", awardTotal, potTotal, s.awarded, won)
		return
	}
	s.ok(chkResults)
	s.checkAwards(res)
}

// checkAwards re-decides every pot from the hole cards and the board and
// compares winners, split shares and odd chips with the engine (rules.md 7.8).
func (s *handState) checkAwards(res *poker.Results) {
	var live []int
	for _, seat := range s.seats {
		if st, ok := s.h.State(seat); ok && !st.Folded {
			live = append(live, seat)
		}
	}
	if len(live) == 1 {
		// Uncontested: every pot goes to the last player standing (7.7).
		for _, a := range res.Pots {
			if len(a.Winners) != 1 || a.Winners[0].Seat != live[0] || a.Winners[0].Amount != a.Amount {
				s.fail(chkAwards, "uncontested pot %d of %d did not go to seat %d", a.Index, a.Amount, live[0])
				return
			}
		}
		s.ok(chkAwards)
		return
	}
	s.f.showdowns++
	boards := map[int][]poker.Card{0: s.h.Board(), 1: s.h.Board(), 2: s.h.Board2()}
	for _, a := range res.Pots {
		board := boards[a.Board]
		if len(board) != 5 {
			s.fail(chkAwards, "showdown pot %d with a board of %d cards", a.Index, len(board))
			return
		}
		if a.Index >= len(s.pots) {
			s.fail(chkAwards, "award for pot %d but only %d pots exist", a.Index, len(s.pots))
			return
		}
		pot := s.pots[a.Index]
		wantAmount := pot.Amount
		switch a.Board {
		case 1:
			// Run twice: the first board takes the odd chip.
			wantAmount = pot.Amount - pot.Amount/2
		case 2:
			wantAmount = pot.Amount / 2
		}
		if a.Amount != wantAmount {
			s.fail(chkAwards, "pot %d board %d paid %d, want %d of %d", a.Index, a.Board, a.Amount, wantAmount, pot.Amount)
			return
		}
		// Best hand among the eligible seats, independently evaluated.
		var best poker.HandValue
		var winners []int
		for _, seat := range pot.Eligible {
			st, ok := s.h.State(seat)
			if !ok || len(st.HoleCards) != 2 {
				s.fail(chkAwards, "seat %d has no hole cards at showdown", seat)
				return
			}
			v := poker.Evaluate(append([]poker.Card{st.HoleCards[0], st.HoleCards[1]}, board...))
			switch c := v.Compare(best); {
			case len(winners) == 0 || c > 0:
				best, winners = v, []int{seat}
			case c == 0:
				winners = append(winners, seat)
			}
		}
		winners = s.clockwise(winners)
		share := a.Amount / int64(len(winners))
		odd := a.Amount - share*int64(len(winners))
		if len(winners) != len(a.Winners) {
			s.fail(chkAwards, "pot %d board %d: %d winners, want %v", a.Index, a.Board, len(a.Winners), winners)
			return
		}
		for i, w := range a.Winners {
			amt := share
			if int64(i) < odd {
				amt++ // odd chips clockwise from the button
			}
			if w.Seat != winners[i] || w.Amount != amt {
				s.fail(chkAwards, "pot %d board %d winner %d: seat %d got %d, want seat %d with %d",
					a.Index, a.Board, i, w.Seat, w.Amount, winners[i], amt)
				return
			}
		}
		if a.Description != "" && a.Description != best.Describe() {
			s.fail(chkAwards, "pot %d described as %q, want %q", a.Index, a.Description, best.Describe())
			return
		}
		if a.Board != 2 {
			s.f.categories[best.Category]++
		}
		s.ok(chkAwards)
	}
}

// clockwise orders seats starting left of the button (rules.md 7.8.2).
func (s *handState) clockwise(seats []int) []int {
	out := append([]int(nil), seats...)
	b := s.cfg.ButtonSeat
	key := func(x int) int {
		if x > b {
			return x - b
		}
		return x + 1<<20 - b
	}
	sort.Slice(out, func(i, j int) bool { return key(out[i]) < key(out[j]) })
	return out
}
