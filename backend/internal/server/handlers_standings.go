package server

import (
	"net/http"
	"sort"
	"time"

	"showdown/internal/protocol"
	"showdown/internal/store"
	"showdown/internal/table"
)

// handleTableStandings serves the table's whole record: every round it has
// finished and the all-time totals summed from them. Readable by anyone who
// is at the table (player or spectator session) and by the host, the same
// audience as the hand history — and it outlives the restarts that reset the
// stacks, which is the point of keeping it.
func (s *Server) handleTableStandings(w http.ResponseWriter, r *http.Request) {
	t, ok := s.tableOr404(w, r.PathValue("id"))
	if !ok {
		return
	}
	token := bearerToken(r)
	if !isTableAdmin(t, token) {
		sess, err := s.lookupSession(r.Context(), token)
		if err != nil || sess.TableID != t.ID {
			writeError(w, http.StatusUnauthorized, protocol.ErrUnauthorized, "session token of this table required")
			return
		}
	}
	rows, err := s.store.ListRoundStandings(r.Context(), t.ID)
	if err != nil {
		s.log.Error("list round standings", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not load standings")
		return
	}
	highlights, err := s.store.ListRoundHighlights(r.Context(), t.ID)
	if err != nil {
		s.log.Error("list round highlights", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not load standings")
		return
	}
	out := buildStandings(t.ID, t.Info().Name, rows, highlights, time.Now().UnixMilli())
	writeJSON(w, http.StatusOK, out)
}

// sessionGap is the break that ends a session: rounds that ended closer
// together than this were one evening, and the board of "this session" stops
// counting the moment the newest round is older than this.
const sessionGap = 6 * time.Hour

// buildStandings turns the stored rows into the rounds, the all-time board
// and the board of the current session. The rows arrive oldest round first,
// already sorted inside a round; highlights are the biggest pots by round.
func buildStandings(tableID, tableName string, rows []store.RoundStandingRow,
	highlights []store.RoundHighlightRow, now int64) protocol.TableStandings {
	out := protocol.TableStandings{
		TableID: tableID, TableName: tableName,
		Rounds: []protocol.RoundStanding{}, AllTime: []protocol.AllTimeEntry{}, Session: []protocol.AllTimeEntry{},
	}
	best := make(map[int]*protocol.RoundHighlight, len(highlights))
	for _, h := range highlights {
		winners := h.Winners
		if winners == nil {
			winners = []string{}
		}
		best[h.RoundIndex] = &protocol.RoundHighlight{
			Hand: h.Hand, Amount: h.Amount, Winners: winners, Description: h.Description,
		}
	}
	for _, r := range rows {
		if n := len(out.Rounds); n == 0 || out.Rounds[n-1].Index != r.RoundIndex {
			out.Rounds = append(out.Rounds, protocol.RoundStanding{
				Index: r.RoundIndex, RoundStart: r.RoundStart, Hands: r.Hands,
				EndedAt: r.EndedAt, BigBlind: r.BigBlind, Standings: []protocol.LeaderboardEntry{},
				BiggestPot: best[r.RoundIndex],
			})
		}
		round := &out.Rounds[len(out.Rounds)-1]
		round.Standings = append(round.Standings, protocol.LeaderboardEntry{
			Name: r.Name, Stack: r.Stack, Net: r.Net, HandsWon: r.HandsWon, BiggestPot: r.BiggestPot,
			HandsPlayed: r.HandsPlayed, VPIPHands: r.VPIPHands, Showdowns: r.Showdowns,
			ShowdownsWon: r.ShowdownsWon, Place: r.Place,
		})
	}
	out.AllTime = aggregateStandings(rows)

	// The current session: walk back from the newest round while the rounds
	// follow each other without a long break. Nothing when even the newest
	// round is from an earlier evening.
	if n := len(out.Rounds); n > 0 && now-out.Rounds[n-1].EndedAt <= sessionGap.Milliseconds() {
		from := n - 1
		for from > 0 && out.Rounds[from].EndedAt-out.Rounds[from-1].EndedAt <= sessionGap.Milliseconds() {
			from--
		}
		out.SessionFrom = out.Rounds[from].Index
		var session []store.RoundStandingRow
		for _, r := range rows {
			if r.RoundIndex >= out.SessionFrom {
				session = append(session, r)
			}
		}
		out.Session = aggregateStandings(session)
	}
	return out
}

// aggregateStandings sums rows of any number of rounds into one line per
// player, sorted for the board.
func aggregateStandings(rows []store.RoundStandingRow) []protocol.AllTimeEntry {
	byKey := map[string]*protocol.AllTimeEntry{}
	var order []string
	for _, r := range rows {
		// One player across rounds: the profile where there is one, the
		// name otherwise — a guest has nothing else to be known by.
		key := "a:" + r.AccountID
		if r.AccountID == "" {
			key = "n:" + r.NameKey
		}
		e, seen := byKey[key]
		if !seen {
			e = &protocol.AllTimeEntry{History: []protocol.RoundLine{}}
			byKey[key] = e
			order = append(order, key)
		}
		// The latest round a player sat in names them: a display name and
		// an avatar may have changed since the first.
		if r.EndedAt >= e.LastPlayed {
			e.Name, e.Avatar, e.LastPlayed = r.Name, r.Avatar, r.EndedAt
		}
		e.Bot = e.Bot || r.Bot
		e.Rounds++
		if r.Place == 1 {
			e.Wins++
		}
		if r.Place > 0 && (e.BestPlace == 0 || r.Place < e.BestPlace) {
			e.BestPlace = r.Place
		}
		e.Net += r.Net
		e.HandsPlayed += r.HandsPlayed
		e.HandsWon += r.HandsWon
		e.VPIPHands += r.VPIPHands
		e.Showdowns += r.Showdowns
		e.ShowdownsWon += r.ShowdownsWon
		if r.BiggestPot > e.BiggestPot {
			e.BiggestPot = r.BiggestPot
		}
		e.History = append(e.History, protocol.RoundLine{
			Round: r.RoundIndex, Net: r.Net, Place: r.Place, HandsWon: r.HandsWon,
		})
	}
	out := make([]protocol.AllTimeEntry, 0, len(order))
	for _, k := range order {
		out = append(out, *byKey[k])
	}
	// Money first: the board answers who is up at this table. Rounds won,
	// then rounds played break ties, and the name makes it deterministic.
	sort.SliceStable(out, func(i, j int) bool {
		a, b := out[i], out[j]
		switch {
		case a.Net != b.Net:
			return a.Net > b.Net
		case a.Wins != b.Wins:
			return a.Wins > b.Wins
		case a.Rounds != b.Rounds:
			return a.Rounds > b.Rounds
		default:
			return table.NameKey(a.Name) < table.NameKey(b.Name)
		}
	})
	return out
}
