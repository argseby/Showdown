package table

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"math"
	"math/big"
	"sort"
	"strconv"
	"time"

	"showdown/internal/poker"
	"showdown/internal/protocol"
	"showdown/internal/store"
)

func randomIndex(n int) int64 {
	v, err := rand.Int(rand.Reader, big.NewInt(int64(n)))
	if err != nil {
		panic("crypto/rand unavailable: " + err.Error())
	}
	return v.Int64()
}

func marshalJSON(v any) []byte {
	if v == nil {
		return nil
	}
	b, err := json.Marshal(v)
	if err != nil {
		return nil
	}
	return b
}

// scheduleStart arms a delayed hand start (hand_delay_ms) so that a joining
// player's connection is up before the deal. No-op while a hand is shown.
func (t *Table) scheduleStart() {
	if t.hand != nil || t.startPending {
		return
	}
	autoStarting := t.state == StateWaiting && t.settings.AutoStart
	if t.state != StateRunning && !autoStarting {
		return
	}
	if len(t.eligible()) < 2 {
		return
	}
	t.startPending = true
	t.nextHandAt = t.nowMs() + int64(t.settings.HandDelayMs)
	t.touch()
	t.schedule(time.Duration(t.settings.HandDelayMs)*time.Millisecond, func() {
		t.startPending = false
		t.nextHandAt = 0
		t.maybeStartHand()
	})
}

// maybeStartHand deals a hand if the table is running (or auto-starts) and
// at least two players are eligible.
func (t *Table) maybeStartHand() {
	if t.hand != nil {
		return
	}
	eligible := t.eligible()
	if len(eligible) < 2 {
		return
	}
	if t.state == StateWaiting && t.settings.AutoStart {
		t.setState(StateRunning, "table_started")
		t.armBlindsClock()
	}
	if t.state != StateRunning {
		return
	}
	t.startHand(eligible)
}

func (t *Table) startHand(eligible []*Player) {
	if t.blindsUpAt > 0 && t.nowMs() >= t.blindsUpAt {
		t.raiseBlinds() // the schedule is checked when a hand is dealt
	}
	button := -1
	if t.buttonSeat < 0 {
		button = eligible[t.deps.RandIntn(len(eligible))].Seat
	} else {
		for i := 1; i <= maxSeats && button < 0; i++ {
			seat := (t.buttonSeat + i) % maxSeats
			for _, p := range eligible {
				if p.Seat == seat {
					button = seat
					break
				}
			}
		}
	}
	reveal := poker.RevealAll
	switch t.settings.ShowdownReveal {
	case RevealWinnersOnly:
		reveal = poker.RevealWinnersOnly
	case RevealInOrder:
		reveal = poker.RevealInOrder
	}
	deadBlinds := map[int]int64{}
	cfg := poker.HandConfig{
		SmallBlind: t.settings.SmallBlind, BigBlind: t.settings.BigBlind, Ante: t.settings.Ante,
		ButtonSeat: button, Reveal: reveal, DeadBlinds: deadBlinds, StraddleSeat: -1,
		Variant: t.settings.PokerVariant(),
	}
	seats := make([]poker.Seat, len(eligible))
	stacks := make(map[int]int64, len(eligible))
	for i, p := range eligible {
		seats[i] = poker.Seat{Seat: p.Seat, Stack: p.Stack}
		if p.owesDeadBlind {
			deadBlinds[p.Seat] = t.settings.BigBlind
			p.owesDeadBlind = false
		}
		stacks[p.Seat] = p.Stack
		p.vpipThisHand = false
		p.usedTimeBank = false
	}
	// Straddle: the third eligible seat clockwise from the button (left of
	// the big blind) posts 2x the big blind when armed and allowed.
	if t.settings.AllowStraddle && len(eligible) >= 3 {
		order := clockwiseFrom(button, eligible)
		if utg := order[2]; utg.straddleNext && utg.Stack > 2*t.settings.BigBlind {
			cfg.StraddleSeat, cfg.StraddleAmount = utg.Seat, 2*t.settings.BigBlind
		}
	}
	t.equity, t.ritVotes, t.ritEndsAt, t.ritDecided, t.timeBankUsing = nil, nil, 0, false, false
	hand, events, err := poker.NewHand(cfg, seats, t.deps.Shuffle)
	if err != nil {
		t.log.Error("cannot start hand", "err", err)
		t.setState(StatePaused, "table_paused")
		return
	}
	t.hand = hand
	t.rabbitCards = nil
	t.handNumber++
	t.buttonSeat = button
	t.handStartedAt = t.nowMs()
	t.handStartStacks = stacks
	t.handEvents = nil
	t.seq = 0
	for _, p := range eligible {
		p.inHand = true
		p.HandsPlayed++
	}
	row := store.HandRow{
		TableID: t.ID, Number: t.handNumber, StartedAt: t.handStartedAt, ButtonSeat: button,
		SmallBlind: cfg.SmallBlind, BigBlind: cfg.BigBlind, Ante: cfg.Ante, StacksAtStart: marshalJSON(seatMap(stacks)),
	}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, p *persister) error {
		id, err := st.InsertHand(ctx, row)
		p.handRowID = id
		return err
	})
	t.persistTable()
	t.applyEngineEvents(events)
	t.afterEngine()
}

// clockwiseFrom orders the eligible players by seat starting left of button.
func clockwiseFrom(button int, eligible []*Player) []*Player {
	out := append([]*Player(nil), eligible...)
	key := func(seat int) int {
		if seat > button {
			return seat - button
		}
		return seat + maxSeats - button
	}
	sort.Slice(out, func(i, j int) bool { return key(out[i].Seat) < key(out[j].Seat) })
	return out
}

func seatMap(m map[int]int64) map[string]int64 {
	out := make(map[string]int64, len(m))
	for k, v := range m {
		out[strconv.Itoa(k)] = v
	}
	return out
}

// afterEngine schedules whatever the engine's phase requires.
func (t *Table) afterEngine() {
	if t.hand == nil {
		return
	}
	t.touch()
	switch t.hand.Phase() {
	case poker.PhaseBetting:
		seat, _ := t.hand.ToAct()
		p := t.seats[seat]
		if p != nil && p.preAction != "" {
			// A pre-selected action (or a sit-out fold) is performed as soon
			// as the turn arrives; the engine then moves on.
			t.applyPreAction(p)
			t.afterEngine()
			return
		}
		secs := t.settings.TurnTime
		if p == nil || !p.Connected {
			secs = t.settings.DisconnectedTurnTime
		}
		t.toActSeat = seat
		t.deadline = t.nowMs() + int64(secs)*1000
		t.timeBankUsing = false
		t.handPhase = "betting"
		t.schedule(time.Duration(secs)*time.Second, func() { t.onTurnTimeout(seat) })
	case poker.PhaseDealPending:
		t.toActSeat, t.deadline = -1, 0
		if t.hand.Runout() {
			t.handPhase = "runout"
			t.computeEquity()
			if t.settings.RunItTwice && !t.ritDecided && t.hand.CanRunItTwice() && t.liveSeats() > 1 {
				// Everyone all-in with cards to come: ask before dealing.
				t.ritVotes = map[int]bool{}
				t.ritEndsAt = t.nowMs() + t.deps.Delays.RunTwiceDecision.Milliseconds()
				t.schedule(t.deps.Delays.RunTwiceDecision, t.resolveRunTwice)
				return
			}
			t.schedule(t.deps.Delays.Runout, t.advanceHand)
		} else {
			t.handPhase = "betting"
			t.schedule(t.deps.Delays.Street, t.advanceHand)
		}
	case poker.PhaseShowdown:
		// Hands are shown one at a time; the strip counts down the whole
		// sequence plus the time to read the result.
		t.toActSeat, t.deadline = -1, 0
		t.handPhase = "showdown"
		steps := time.Duration(t.hand.ShowdownPending()) * t.deps.Delays.ShowdownPerHand
		t.phaseEndsAt = t.nowMs() + (steps + t.deps.Delays.Showdown).Milliseconds()
		t.schedule(t.deps.Delays.ShowdownPerHand, t.revealStep)
	case poker.PhaseResult:
		t.toActSeat, t.deadline = -1, 0
		t.finishHand()
		handDelay := time.Duration(t.settings.HandDelayMs) * time.Millisecond
		if t.contested() {
			// A staged showdown already spent time per hand; a run-out
			// reveals everything at once and needs more time to read.
			showdown := t.deps.Delays.Showdown
			if !t.hand.Staged() {
				showdown += time.Duration(max(t.revealedCount()-1, 0)) * t.deps.Delays.ShowdownPerHand
			}
			// Every additional pot is presented on its own by the clients.
			if res := t.hand.Results(); res != nil && len(res.Pots) > 1 {
				showdown += time.Duration(len(res.Pots)-1) * t.deps.Delays.PotAward
			}
			t.handPhase = "showdown"
			t.phaseEndsAt = t.nowMs() + showdown.Milliseconds()
			t.schedule(showdown, func() {
				t.handPhase = "result"
				t.phaseEndsAt = t.nowMs() + handDelay.Milliseconds()
				t.touch()
				t.schedule(handDelay, t.clearHand)
			})
		} else {
			t.handPhase = "result"
			t.phaseEndsAt = t.nowMs() + handDelay.Milliseconds()
			t.schedule(handDelay, t.clearHand)
		}
	}
}

// revealedCount is the number of hands shown at the showdown.
func (t *Table) revealedCount() int {
	res := t.hand.Results()
	if res == nil {
		return 0
	}
	n := 0
	for _, sr := range res.Seats {
		if sr.Revealed {
			n++
		}
	}
	return n
}

// contested reports whether the finished hand went to a showdown.
func (t *Table) contested() bool {
	res := t.hand.Results()
	if res == nil {
		return false
	}
	for _, p := range res.Pots {
		if p.Description != "" {
			return true
		}
	}
	return false
}

// liveSeats counts the players still in the hand.
func (t *Table) liveSeats() int {
	n := 0
	for _, p := range t.seats[:maxSeats] {
		if p == nil || !p.inHand {
			continue
		}
		if st, ok := t.hand.State(p.Seat); ok && !st.Folded {
			n++
		}
	}
	return n
}

// ritVoteComplete reports whether every live player agreed.
func (t *Table) ritVoteComplete() bool {
	for _, p := range t.seats[:maxSeats] {
		if p == nil || !p.inHand {
			continue
		}
		if st, ok := t.hand.State(p.Seat); ok && !st.Folded {
			if agree, voted := t.ritVotes[p.Seat]; !voted || !agree {
				return false
			}
		}
	}
	return true
}

// resolveRunTwice closes the run-it-twice vote and starts the run-out
// (twice when everyone agreed).
func (t *Table) resolveRunTwice() {
	if t.hand == nil || t.ritVotes == nil {
		return
	}
	if t.ritVoteComplete() {
		if err := t.hand.RunItTwice(); err != nil {
			t.log.Error("run it twice", "err", err)
		}
	}
	t.ritVotes, t.ritEndsAt, t.ritDecided = nil, 0, true
	t.touch()
	t.schedule(t.deps.Delays.Runout, t.advanceHand)
}

// computeEquity refreshes each live seat's pot share for the run-out.
func (t *Table) computeEquity() {
	var seats []int
	var hands [][2]poker.Card
	for _, p := range t.seats[:maxSeats] {
		if p == nil || !p.inHand {
			continue
		}
		st, ok := t.hand.State(p.Seat)
		if !ok || st.Folded || len(st.HoleCards) != 2 {
			continue
		}
		seats = append(seats, p.Seat)
		hands = append(hands, [2]poker.Card{st.HoleCards[0], st.HoleCards[1]})
	}
	if len(seats) < 2 {
		t.equity = nil
		return
	}
	eq := poker.Equity(t.hand.Variant(), t.hand.Board(), hands, 20000, uint64(t.handNumber))
	t.equity = make(map[int]float64, len(seats))
	for i, seat := range seats {
		t.equity[seat] = math.Round(eq[i]*1000) / 10
	}
}

// revealStep shows or mucks the next player of a staged showdown.
func (t *Table) revealStep() {
	if t.hand == nil || t.hand.Phase() != poker.PhaseShowdown {
		return
	}
	events, err := t.hand.RevealNext()
	if err != nil {
		t.log.Error("reveal failed", "err", err)
		return
	}
	t.applyEngineEvents(events)
	t.afterEngine()
}

func (t *Table) advanceHand() {
	if t.hand == nil || t.hand.Phase() != poker.PhaseDealPending {
		return
	}
	events, err := t.hand.Advance()
	if err != nil {
		t.log.Error("advance failed", "err", err)
		return
	}
	t.applyEngineEvents(events)
	if t.hand != nil && t.hand.Runout() && !t.hand.Done() {
		t.computeEquity()
	}
	t.afterEngine()
}

func (t *Table) onTurnTimeout(seat int) {
	if t.hand == nil || t.hand.Phase() != poker.PhaseBetting {
		return
	}
	if s, ok := t.hand.ToAct(); !ok || s != seat {
		return
	}
	p := t.seats[seat]
	if p != nil && !t.timeBankUsing && p.Connected && p.TimeBank > 0 {
		// The clock ran out: the time bank kicks in once, for whatever is
		// left of it. Unused seconds are refunded when the player acts.
		t.timeBankUsing = true
		p.usedTimeBank = true
		t.deadline = t.nowMs() + int64(p.TimeBank)*1000
		t.touch()
		t.schedule(time.Duration(p.TimeBank)*time.Second, func() { t.onTurnTimeout(seat) })
		return
	}
	if p != nil && t.timeBankUsing {
		p.TimeBank = 0
		t.timeBankUsing = false
	}
	events := t.hand.Timeout(seat)
	if p != nil {
		p.MissedTurns++
		if p.MissedTurns >= t.settings.SitOutAfterMissedTurns {
			t.sitOutPending[p.ID] = true
		}
	}
	t.applyEngineEvents(events)
	t.afterEngine()
}

// finishHand does the between-hands bookkeeping as soon as the engine
// reaches the result phase (stacks are final at that point).
func (t *Table) finishHand() {
	res := t.hand.Results()
	contested := t.contested()
	var startSum, endSum int64
	for seat, sr := range res.Seats {
		startSum += sr.StartStack
		endSum += sr.EndStack
		p := t.seats[seat]
		if p == nil {
			continue
		}
		p.Stack = sr.EndStack
		if sr.Won > 0 {
			p.HandsWon++
		}
	}
	for _, pot := range res.Pots {
		for _, w := range pot.Winners {
			if p := t.seats[w.Seat]; p != nil && w.Amount > p.BiggestPot {
				p.BiggestPot = w.Amount
			}
		}
	}
	if startSum != endSum {
		t.log.Error("chip conservation violated; pausing table",
			"hand", t.handNumber, "start", startSum, "end", endSum, "events", string(marshalJSON(t.handEvents)))
		if t.state == StateRunning {
			t.setState(StatePaused, "table_paused")
		}
	}
	var leaving []*Player
	for _, p := range t.seats[:maxSeats] {
		if p == nil || !p.inHand {
			continue
		}
		// Every pre-action is per hand: the sit-out fold, check/fold and
		// call any are cleared when the hand ends so nothing carries over.
		p.preAction = ""
		if p.vpipThisHand {
			p.VPIPHands++
			p.vpipThisHand = false
		}
		if contested {
			if sr, ok := res.Seats[p.Seat]; ok && !sr.Folded {
				p.Showdowns++
				if sr.Won > 0 {
					p.ShowdownsWon++
				}
			}
		}
		if t.settings.TimeBankSeconds > 0 && !p.usedTimeBank {
			// A hand played on the plain clock earns time bank back.
			p.TimeBank = min(t.settings.TimeBankSeconds, p.TimeBank+t.settings.TimeBankRefillSeconds)
		}
		p.usedTimeBank = false
		if p.Stack == 0 && p.Status == StatusActive {
			p.Status = StatusBusted
			t.emit(protocol.Event{Kind: "player_busted", Seat: protocol.Int(p.Seat), Name: p.Name})
			if !t.settings.AllowRebuy {
				// Without rebuys a bust is final: the placement is the
				// number of players still holding chips plus one.
				p.Place = t.playersWithChips() + 1
			}
		}
		if t.sitOutPending[p.ID] {
			delete(t.sitOutPending, p.ID)
			p.MissedTurns = 0
			if p.Status == StatusActive {
				p.Status = StatusSittingOut
				t.emit(protocol.Event{Kind: "player_sat_out", Seat: protocol.Int(p.Seat), Name: p.Name})
			}
		}
		if p.leaving {
			leaving = append(leaving, p)
		} else {
			t.persistPlayer(p)
		}
	}
	for _, p := range leaving {
		t.freeSeat(p)
	}
	pending := t.pendingChips
	t.pendingChips = nil
	for _, c := range pending {
		if p, ok := t.players[c.playerID]; ok {
			if err := t.applyChips(p, c.delta, c.note); err != nil {
				t.log.Warn("queued chip adjustment rejected", "player", c.playerID, "delta", c.delta, "err", err)
			}
		}
	}
	// A tournament-style table (no rebuys) ends when one player has all the
	// chips; the standings carry the placements.
	if !t.settings.AllowRebuy && t.seatedCount() >= 2 && t.playersWithChips() <= 1 {
		t.endAfterHand = true
	}
	t.persistHandEnd(false)
	t.persistTable()
}

func (t *Table) persistHandEnd(voided bool) {
	events := marshalJSON(t.handEvents)
	var results []byte
	if r := t.hand.Results(); r != nil {
		results = marshalJSON(convertResults(r))
	}
	ended := t.nowMs()
	t.persist.enqueue(func(ctx context.Context, st *store.Store, p *persister) error {
		return st.FinishHand(ctx, p.handRowID, ended, events, results, voided)
	})
}

// extendResultPhase keeps a finished hand on screen for another
// hand_delay_ms after a late reveal or a rabbit hunt, so that everyone gets
// to see it, and re-persists the hand so the replay has the late events.
func (t *Table) extendResultPhase() {
	if t.hand == nil || !t.hand.Done() || t.state == StateEnded {
		return
	}
	// Every reveal or rabbit hunt guarantees at least resultExtension more
	// seconds on screen; earlier deadlines are pushed, later ones kept.
	t.handPhase = "result"
	ext := t.deps.Delays.ResultExtension
	if end := t.nowMs() + ext.Milliseconds(); end > t.phaseEndsAt {
		t.phaseEndsAt = end
		t.schedule(ext, t.clearHand)
	}
	t.touch()
	t.persistHandEnd(false)
}

// clearHand removes the finished hand from the snapshot and continues.
func (t *Table) clearHand() {
	for _, p := range t.seats[:maxSeats] {
		if p != nil {
			p.inHand = false
		}
	}
	t.hand = nil
	t.handPhase = ""
	t.phaseEndsAt = 0
	t.toActSeat, t.deadline = -1, 0
	t.equity, t.ritVotes, t.ritEndsAt, t.ritDecided, t.timeBankUsing = nil, nil, 0, false, false
	t.touch()
	if t.endAfterHand {
		t.endAfterHand = false
		t.endTable()
		return
	}
	t.applyPendingSeatChanges()
	t.maybeStartHand()
}

// voidHand cancels the running hand: stacks go back to their start values.
func (t *Table) voidHand(reason string) {
	if t.hand == nil {
		return
	}
	t.cancelTimer()
	for seat, stack := range t.handStartStacks {
		if p := t.seats[seat]; p != nil {
			p.Stack = stack
			p.inHand = false
			p.preAction = ""
			t.persistPlayer(p)
		}
	}
	t.emit(protocol.Event{Kind: "hand_voided", Reason: reason})
	t.persistHandEnd(true)
	t.hand = nil
	t.handPhase = ""
	t.toActSeat, t.deadline = -1, 0
	t.touch()
	for _, p := range t.seats[:maxSeats] {
		if p != nil && p.leaving {
			t.freeSeat(p)
		}
	}
}

// endTable is terminal: stacks are frozen and recorded, clients told and
// disconnected.
func (t *Table) endTable() {
	t.cancelTimer()
	t.hand = nil
	t.handPhase = ""
	t.state = StateEnded
	t.endedAt = t.nowMs()
	t.blindsUpAt = 0
	t.emit(protocol.Event{Kind: "table_ended"})
	t.assignPlaces()
	for _, p := range t.seats[:maxSeats] {
		if p == nil {
			continue
		}
		p.inHand = false
		t.persistPlayer(p)
	}
	t.persistTable()
	t.broadcastMsg(protocol.MustEncode(protocol.TypeTableEnded, "", protocol.TableEnded{FinalLeaderboard: t.leaderboard()}))
	t.closeAfterFlush = &closeRequest{code: protocol.CloseTableGone, reason: "table_ended"}
}

// assignPlaces gives every seated player without a placement one, by net
// result (stack minus everything bought in, so rebuys count against a
// player); the stack breaks ties. Busted players already hold theirs.
func (t *Table) assignPlaces() {
	var open []*Player
	taken := 0
	for _, p := range t.seats[:maxSeats] {
		if p == nil {
			continue
		}
		if p.Place > 0 {
			taken++
		} else {
			open = append(open, p)
		}
	}
	sort.SliceStable(open, func(i, j int) bool {
		ni, nj := open[i].Stack-open[i].BuyInTotal, open[j].Stack-open[j].BuyInTotal
		if ni != nj {
			return ni > nj
		}
		return open[i].Stack > open[j].Stack
	})
	for i, p := range open {
		p.Place = i + 1
	}
	_ = taken
}

// playersWithChips counts the seated players who can still play.
func (t *Table) playersWithChips() int {
	n := 0
	for _, p := range t.seats[:maxSeats] {
		if p != nil && p.Stack > 0 {
			n++
		}
	}
	return n
}

// ---- engine event conversion ----------------------------------------------------------

func cardStrings(cards []poker.Card) []string {
	if len(cards) == 0 {
		return nil
	}
	out := make([]string, len(cards))
	for i, c := range cards {
		out[i] = c.String()
	}
	return out
}

func potViews(pots []poker.Pot) []protocol.PotView {
	out := make([]protocol.PotView, len(pots))
	for i, p := range pots {
		out[i] = protocol.PotView{Amount: p.Amount, EligibleSeats: append([]int{}, p.Eligible...)}
	}
	return out
}

func convertResults(r *poker.Results) *protocol.HandResults {
	out := &protocol.HandResults{Seats: make(map[string]protocol.SeatResult, len(r.Seats))}
	for _, p := range r.Pots {
		pr := protocol.PotResult{Index: p.Index, Amount: p.Amount, Description: p.Description, Winners: []protocol.PotWinner{}, Board: p.Board}
		for _, w := range p.Winners {
			pr.Winners = append(pr.Winners, protocol.PotWinner{Seat: w.Seat, Amount: w.Amount})
		}
		out.Pots = append(out.Pots, pr)
	}
	if out.Pots == nil {
		out.Pots = []protocol.PotResult{}
	}
	for seat, s := range r.Seats {
		out.Seats[strconv.Itoa(seat)] = protocol.SeatResult{
			Net: s.Net, Won: s.Won, Folded: s.Folded, Revealed: s.Revealed,
			Cards: cardStrings(s.Cards), Description: s.Description, Best: cardStrings(s.Best),
		}
	}
	return out
}

// applyEngineEvents converts engine events to wire events and queues them.
func (t *Table) applyEngineEvents(events []poker.Event) {
	for _, e := range events {
		pe := protocol.Event{Kind: string(e.Kind)}
		if e.Seat >= 0 {
			pe.Seat = protocol.Int(e.Seat)
			// Names travel with seat events so that the log never has to
			// resolve a seat that just changed hands.
			if p := t.seats[e.Seat]; p != nil {
				pe.Name = p.Name
			}
		}
		switch e.Kind {
		case poker.EvHandStarted:
			s := e.Start
			pe.ButtonSeat, pe.SBSeat, pe.BBSeat = protocol.Int(s.ButtonSeat), protocol.Int(s.SBSeat), protocol.Int(s.BBSeat)
			if p := t.seats[s.ButtonSeat]; p != nil {
				pe.Name = p.Name // the dealer
			}
			pe.Blinds = &protocol.Blinds{Small: s.SmallBlind, Big: s.BigBlind}
			pe.Ante = protocol.Int64(s.Ante)
			pe.Stacks = seatMap(s.Stacks)
		case poker.EvAntePosted:
			pe.Amount, pe.AllIn = protocol.Int64(e.Amount), protocol.Bool(e.AllIn)
		case poker.EvBlindPosted:
			pe.Blind, pe.Amount, pe.AllIn = string(e.Blind), protocol.Int64(e.Amount), protocol.Bool(e.AllIn)
		case poker.EvHoleCardsDealt:
			pe.Cards = cardStrings(e.Cards)
		case poker.EvAction:
			pe.Action, pe.Amount, pe.AllIn = string(e.Action), protocol.Int64(e.Amount), protocol.Bool(e.AllIn)
			// Voluntarily put in the pot preflop (blinds do not count).
			if e.Street == poker.Preflop && (e.Action == poker.Call || e.Action == poker.Bet || e.Action == poker.Raise) {
				if p := t.seats[e.Seat]; p != nil {
					p.vpipThisHand = true
				}
			}
		case poker.EvTimeout:
			pe.ResolvedAs = string(e.Action)
		case poker.EvUncalledReturned:
			pe.Amount = protocol.Int64(e.Amount)
		case poker.EvStreetDealt:
			pe.Street, pe.Cards, pe.Board = e.Street.String(), cardStrings(e.Cards), e.Board
		case poker.EvPotsUpdated:
			pe.Pots = potViews(e.Pots)
		case poker.EvHandsRevealed:
			for _, r := range e.Reveals {
				cards := cardStrings(r.Cards)
				for i := range cards {
					if i < 2 && !r.Shown[i] {
						cards[i] = "" // partial reveal: this card stays face down
					}
				}
				pe.Reveals = append(pe.Reveals, protocol.Reveal{Seat: r.Seat, Cards: cards, Description: r.Description, Best: cardStrings(r.Best)})
			}
		case poker.EvPotAwarded:
			pe.PotIndex, pe.Amount, pe.Description, pe.Board = protocol.Int(e.PotIndex), protocol.Int64(e.Amount), e.Description, e.Board
		case poker.EvHandEnded:
			pe.Results = convertResults(e.Results)
		}
		// Keep the engine's sequence so that seq stays monotonic per hand.
		if e.Seq > t.seq {
			t.seq = e.Seq
		}
		pe.Seq = e.Seq
		pe.TS = t.nowMs()
		t.pendingEvents = append(t.pendingEvents, pe)
		t.handEvents = append(t.handEvents, pe)
	}
	t.dirty = true
}
