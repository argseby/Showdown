package table

import (
	"sort"

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
		out = append(out, protocol.LeaderboardEntry{Name: p.Name, Stack: stack, Net: stack - p.BuyInTotal, HandsWon: p.HandsWon, BiggestPot: p.BiggestPot})
	}
	sort.SliceStable(out, func(i, j int) bool { return out[i].Net > out[j].Net })
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
				ID: p.ID, Name: p.Name, Avatar: p.Avatar, Stack: p.Stack, Status: p.Status, Connected: p.Connected,
				Voice: voice, Muted: p.Muted,
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
			you.CanChangeSeat = t.canChangeSeat(p) && t.state != StateEnded
			if t.hand != nil && p.inHand {
				if seat, ok := t.hand.ToAct(); ok && seat == p.Seat {
					you.Options = optionsView(t.hand.Options(seat))
				}
				if st, _ := t.hand.State(p.Seat); !st.Folded {
					you.HandDescription = t.hand.Description(p.Seat)
					you.BestCards = cardStrings(t.hand.BestCards(p.Seat))
				}
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
