package table

import (
	"sort"

	"showdown/internal/botplay"
	"showdown/internal/poker"
	"showdown/internal/protocol"
)

func (t *Table) spectatorCount() int {
	n := 0
	for c := range t.clients {
		if c.Role == RoleSpectator {
			n++
		}
	}
	return n
}

// currentStack is the engine's view during a hand, the player's otherwise.
func (t *Table) currentStack(p *Player) int64 {
	if t.handInProgress() && p.inHand {
		if s, ok := t.hand.Stack(p.Seat); ok {
			return s
		}
	}
	return p.Stack
}

func (t *Table) leaderboard() []protocol.LeaderboardEntry {
	out := []protocol.LeaderboardEntry{}
	for _, p := range t.seats[:maxSeats] {
		if p == nil {
			continue
		}
		stack := t.currentStack(p)
		out = append(out, protocol.LeaderboardEntry{
			Name: p.Name, Stack: stack, Net: stack - p.BuyInTotal, HandsWon: p.HandsWon, BiggestPot: p.BiggestPot,
			HandsPlayed: p.HandsPlayed, VPIPHands: p.VPIPHands, Showdowns: p.Showdowns, ShowdownsWon: p.ShowdownsWon,
			Place: p.Place,
		})
	}
	sort.SliceStable(out, func(i, j int) bool {
		// Placed players (out or final standings) sort by place, the rest by net.
		if out[i].Place != out[j].Place {
			if out[i].Place == 0 {
				return true
			}
			if out[j].Place == 0 {
				return false
			}
			return out[i].Place < out[j].Place
		}
		return out[i].Net > out[j].Net
	})
	return out
}

// snapshot builds the personalized state for one client.
func (t *Table) snapshot(c *Client) protocol.Snapshot {
	viewerSeat := -1
	if c.Role == RolePlayer {
		viewerSeat = t.seatOf(c.PlayerID)
	}
	snap := protocol.Snapshot{
		ServerTS: t.nowMs(),
		Table: protocol.TableInfo{
			ID: t.ID, Name: t.name, State: t.state, HandNumber: t.handNumber, Settings: t.settings.Public(),
			NextBlindsUpTS: t.blindsUpAt,
			NextHandTS:     t.nextHandAt,
		},
		Seats:       make([]protocol.SeatView, 0, t.settings.MaxPlayers),
		Leaderboard: t.leaderboard(),
		LastRound:   t.lastRound,
		Spectators:  t.spectatorCount(),
	}
	for c := range t.clients {
		if c.Role == RoleSpectator {
			snap.SpectatorNames = append(snap.SpectatorNames, c.Name)
		}
	}
	sort.Strings(snap.SpectatorNames)
	for seat := 0; seat < t.settings.MaxPlayers; seat++ {
		sv := protocol.SeatView{Seat: seat}
		if p := t.seats[seat]; p != nil {
			voice := p.Voice
			if voice == "" {
				voice = VoiceOff
			}
			pv := &protocol.PlayerView{
				ID: p.ID, Name: p.Name, Avatar: p.Avatar, Hat: p.Hat, Heat: heatOf(p.WinStreak), Stack: p.Stack, Status: p.Status, Connected: p.Connected,
				Voice: voice, Muted: p.Muted, Camera: p.Camera, TimeBank: p.TimeBank, Place: p.Place,
				Account: p.AccountHandle, Bot: p.Bot,
			}
			if eq, ok := t.equity[seat]; ok && p.inHand {
				pv.Equity = &eq
			}
			if t.hand != nil && p.inHand {
				if st, ok := t.hand.State(seat); ok {
					if !t.hand.Done() {
						pv.Stack = st.Stack
					}
					pv.InHand, pv.Folded, pv.AllIn, pv.Mucked = true, st.Folded, st.AllIn, st.Mucked
					pv.BetThisStreet, pv.TotalBet = st.BetThisStreet, st.TotalBet
					if st.LastAction != nil {
						pv.LastAction = &protocol.LastAction{Kind: string(st.LastAction.Kind), Amount: st.LastAction.Amount}
					}
					if seat == viewerSeat || st.Revealed {
						pv.HoleCards = cardStrings(st.HoleCards)
					} else if st.Shown[0] || st.Shown[1] {
						// Partial voluntary reveal: the hidden card is "".
						pv.HoleCards = cardStrings(st.HoleCards)
						for i := range pv.HoleCards {
							if !st.Shown[i] {
								pv.HoleCards[i] = ""
							}
						}
					}
					if st.Revealed && !st.Folded {
						// Public cards, public hand: everyone sees what the
						// revealed hand makes on the board as it runs out —
						// and before the flop the two cards themselves.
						pv.HandDescription = t.hand.Description(seat)
						pv.BestCards = cardStrings(t.hand.ShownBest(seat))
					}
				}
			}
			sv.Player = pv
		}
		snap.Seats = append(snap.Seats, sv)
	}
	if t.hand != nil {
		h := t.hand
		hv := &protocol.HandView{
			Street: h.Street().String(), Board: cardStrings(h.Board()), ButtonSeat: h.ButtonSeat(),
			SBSeat: h.SBSeat(), BBSeat: h.BBSeat(), CurrentBet: h.CurrentBet(), Pots: potViews(h.Pots()), Phase: t.handPhase,
			RabbitCards: t.rabbitCards,
		}
		if t.handPhase == "showdown" || t.handPhase == "result" {
			hv.PhaseEndsTS = t.phaseEndsAt
		}
		if b2 := h.Board2(); len(b2) > 0 || h.RunTwice() {
			hv.Board2 = cardStrings(b2)
			hv.RunTwice = true
		}
		if s := h.StraddleSeat(); s >= 0 {
			hv.StraddleSeat = protocol.Int(s)
		}
		hv.TimeBankActive = t.timeBankUsing
		if t.ritVotes != nil {
			hv.RunTwiceEndsTS = t.ritEndsAt
		}
		if hv.Board == nil {
			hv.Board = []string{}
		}
		if hv.Pots == nil {
			hv.Pots = []protocol.PotView{}
		}
		if seat, ok := h.ToAct(); ok {
			hv.ToActSeat = protocol.Int(seat)
			hv.MinRaiseTo = h.MinRaiseTo()
			if t.deadline > 0 {
				hv.DeadlineTS = protocol.Int64(t.deadline)
			}
		}
		snap.Hand = hv
	}
	you := protocol.You{Role: c.Role, IsAdmin: c.Admin || c.Role == RoleAdmin, PreAction: PreNone}
	if c.Role == RolePlayer {
		if p, ok := t.players[c.PlayerID]; ok {
			you.PlayerID = p.ID
			you.Seat = protocol.Int(p.Seat)
			you.CanRebuy = p.Status == StatusBusted && t.settings.AllowRebuy && t.betweenHands()
			if p.preAction == PreCheckFold || p.preAction == PreCallAny {
				you.PreAction = p.preAction
			}
			if p.pendingSeat >= 0 {
				you.PendingSeat = protocol.Int(p.pendingSeat)
			}
			you.Straddle = p.straddleNext
			if t.ritVotes != nil && p.inHand && t.hand != nil {
				if st, ok := t.hand.State(p.Seat); ok && !st.Folded {
					if v, voted := t.ritVotes[p.Seat]; voted {
						you.RunTwiceVote = protocol.Bool(v)
					} else {
						you.CanRunTwice = true
					}
				}
			}
			you.CanChangeSeat = t.canChangeSeat(p) && t.state != StateEnded
			if t.hand != nil && p.inHand {
				if seat, ok := t.hand.ToAct(); ok && seat == p.Seat {
					you.Options = optionsView(t.hand.Options(seat))
				}
				// The viewer's own hand is described for the whole hand,
				// folded or not, so they can still talk about it. This is
				// their own cards read back to them and never withheld:
				// what an instance or a host can refuse is being told what
				// to do with them.
				you.HandDescription = t.hand.Description(p.Seat)
				you.BestCards = cardStrings(t.hand.BestCards(p.Seat))
				if cat, royal, ok := t.hand.Rank(p.Seat); ok {
					you.HandCategory = protocol.Int(int(cat))
					you.HandRoyal = royal
				}
				you.HandRanks = rankStrings(t.hand.HandRanks(p.Seat))
				you.Notes = noteViews(t.hand.Notes(p.Seat))
				you.CanShowCards = t.hand.CanShowCards(p.Seat)
				you.CanRabbitHunt = t.canRabbitHunt(p)
			}
		}
	}
	snap.You = you
	return snap
}

func optionsView(o poker.Options) *protocol.OptionsView {
	v := &protocol.OptionsView{Fold: o.Fold, Check: o.Check, Call: o.Call, AllIn: o.AllIn}
	if o.Raise != nil {
		v.Raise = &protocol.RaiseView{Min: o.Raise.Min, Max: o.Raise.Max}
	}
	return v
}

// StrengthView answers "how am I doing, and what would you do?" for one
// player's own turn. Everything in it is derived from that player's own
// cards and the public board, so it tells the asker nothing about anybody
// else — it does the arithmetic they could do themselves, with the house
// strategy's own line on top.
type StrengthView struct {
	Street      string   `json:"street"`
	Cards       []string `json:"cards"`
	Board       []string `json:"board"`
	Description string   `json:"description"`
	Category    int      `json:"category"`
	Royal       bool     `json:"royal,omitempty"`
	Best        []string `json:"best,omitempty"`
	// Equity is the share of the pot the hand takes against Opponents
	// random hands (0..1), Tier the same thing in a word.
	Equity    float64 `json:"equity"`
	Opponents int     `json:"opponents"`
	Tier      string  `json:"tier"`
	// Advice is present only on the player's own turn, and only where the
	// table allows it.
	Advice *AdviceView `json:"advice,omitempty"`
}

// AdviceView is the strategy's line with the numbers behind it.
type AdviceView struct {
	Action string `json:"action"`
	Amount int64  `json:"amount,omitempty"`
	// Sizing is "small" or "big" for a raise, empty otherwise.
	Sizing string `json:"sizing,omitempty"`
	// Reason is why this line, as an id the client has words for.
	Reason string `json:"reason,omitempty"`
	// Need is the share of the time a call has to win to break even; zero
	// when checking is free.
	Need float64 `json:"need"`
}

// tiers name the edge over an average holding, weakest first.
func tierOf(edge float64) string {
	switch {
	case edge >= 0.55:
		return "monster"
	case edge >= 0.3:
		return "strong"
	case edge >= 0.12:
		return "good"
	case edge >= 0:
		return "marginal"
	default:
		return "weak"
	}
}

// Strength reads the hand of the player behind playerID. ok is false when
// there is nothing to read: no hand, not dealt in, already folded, or an
// instance that serves no player help at all.
func (t *Table) Strength(playerID string) (view StrengthView, ok bool) {
	t.call(func() {
		if t.hand == nil {
			return
		}
		p, found := t.players[playerID]
		if !found || !p.inHand {
			return
		}
		st, live := t.hand.State(p.Seat)
		if !live || st.Folded {
			return
		}
		cat, royal, _ := t.hand.Rank(p.Seat)
		view = StrengthView{
			Street:      t.hand.Street().String(),
			Cards:       cardStrings(st.HoleCards),
			Board:       cardStrings(t.hand.Board()),
			Description: t.hand.Description(p.Seat),
			Category:    int(cat),
			Royal:       royal,
			Best:        cardStrings(t.hand.BestCards(p.Seat)),
		}
		if view.Board == nil {
			view.Board = []string{} // an empty board is empty, not absent
		}
		// The strategy reads the snapshot the player themselves would get,
		// so it can never see a card the player cannot.
		snap := t.snapshot(&Client{Role: RolePlayer, PlayerID: playerID})
		if snap.You.Options == nil || snap.You.Seat == nil {
			// Not their turn: the hand can still be weighed, but there is
			// no price on the table and so no line to take.
			view.Opponents, view.Equity, view.Tier = 0, 0, "marginal"
			ok = true
			return
		}
		a, read := botplay.Advise(*snap.You.Options, snap, *snap.You.Seat)
		if !read {
			ok = true
			return
		}
		view.Equity, view.Opponents, view.Tier = a.Equity, a.Opponents, tierOf(a.Edge)
		// Three yeses for a recommendation: the instance, the host and —
		// on the client — the player. The reading above needs none.
		if t.settings.AllowAdvice && !t.deps.NoAdvice {
			view.Advice = &AdviceView{
				Action: a.Action, Amount: a.Amount, Sizing: a.Sizing,
				Reason: a.Reason, Need: a.Need,
			}
		}
		ok = true
	})
	return view, ok
}

// rankStrings spells ranks the way the cards do, so a client reads them
// with the parser it already has.
func rankStrings(ranks []poker.Rank) []string {
	if len(ranks) == 0 {
		return nil
	}
	out := make([]string, 0, len(ranks))
	for _, r := range ranks {
		out = append(out, r.String())
	}
	return out
}

// noteViews renders the board reading for the wire: ids plus the rank or
// suit that makes a note concrete, in the one-character spelling the cards
// already use.
func noteViews(notes []poker.Note) []protocol.NoteView {
	if len(notes) == 0 {
		return nil
	}
	out := make([]protocol.NoteView, 0, len(notes))
	for _, n := range notes {
		v := protocol.NoteView{ID: string(n.ID)}
		if n.HasRank {
			v.Rank = n.Rank.String()
		}
		if n.HasSuit {
			v.Suit = n.Suit.String()
		}
		out = append(out, v)
	}
	return out
}
