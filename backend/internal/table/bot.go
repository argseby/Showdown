package table

import (
	"encoding/json"
	"fmt"
	"math/rand/v2"
	"sync"
	"time"

	"showdown/internal/botplay"
	"showdown/internal/poker"
	"showdown/internal/protocol"
)

// A bot the host adds from the table itself. It is an ordinary seat with an
// ordinary player behind it, except that the player is a goroutine in this
// process instead of a browser: it attaches as a client like everyone else
// and reads the same snapshots, which are already redacted per recipient —
// so a bot cannot see a card it has no business seeing, and the rules that
// apply to it are the rules that apply to everyone.

// Bot thinking time. A bot that answered the instant its turn came round
// would feel like a machine and give its hand away by the pauses it did not
// take, so it takes one, longer for the decisions a person would think about.
const (
	botThinkMin = 700 * time.Millisecond
	botThinkMax = 2200 * time.Millisecond
	botNameStem = "Bot"
	// botNameTries bounds the search for a free name. A name stays reserved
	// after its player leaves, so a host who adds and kicks bots all evening
	// works through the numbers and must not run out at ten.
	botNameTries = 1000
	botSnapshots = 1 // only the newest snapshot matters
)

// botSeat plays one seat from inside the server. Send is called on the
// table's own goroutine and must never block it, so it only hands the
// snapshot over; the thinking happens on the bot's goroutine.
type botSeat struct {
	table    *Table
	playerID string
	rng      *rand.Rand

	snapshots chan protocol.Snapshot
	stopOnce  sync.Once
	stop      chan struct{}

	// lastActKey is the turn we last acted on, so a resend of the same
	// snapshot does not act twice.
	lastActKey string
}

func newBotSeat(t *Table, playerID string, seed uint64) *botSeat {
	return &botSeat{
		table: t, playerID: playerID,
		rng:       rand.New(rand.NewPCG(seed, seed^0x9e3779b97f4a7c15)),
		snapshots: make(chan protocol.Snapshot, botSnapshots),
		stop:      make(chan struct{}),
	}
}

// Send takes the newest snapshot and drops the one before it: the bot acts
// on the current state of the table, never on a queue of stale ones.
func (b *botSeat) Send(env protocol.Envelope) bool {
	var snap protocol.Snapshot
	switch env.Type {
	case protocol.TypeSnapshot:
		if json.Unmarshal(env.Payload, &snap) != nil {
			return true
		}
	case protocol.TypeWelcome:
		var w protocol.Welcome
		if json.Unmarshal(env.Payload, &w) != nil {
			return true
		}
		snap = w.Snapshot
	default:
		return true // chat, drawings, events: nothing a bot acts on
	}
	for {
		select {
		case b.snapshots <- snap:
			return true
		case <-b.snapshots: // make room for the newer one
		case <-b.stop:
			return false
		default:
			return true
		}
	}
}

// Close ends the bot: the host kicked it, the table was deleted or the
// server is going down.
func (b *botSeat) Close(int, string) { b.close() }

func (b *botSeat) close() { b.stopOnce.Do(func() { close(b.stop) }) }

// run is the bot's goroutine: wait for a snapshot, think, act.
func (b *botSeat) run() {
	client := &Client{Conn: b, Role: RolePlayer, PlayerID: b.playerID}
	if err := b.table.Attach(client); err != nil {
		b.table.log.Warn("bot could not attach", "table", b.table.ID, "err", err)
		return
	}
	defer b.table.Detach(client)
	for {
		select {
		case <-b.stop:
			return
		case snap := <-b.snapshots:
			b.consider(snap)
		}
	}
}

// consider acts on one snapshot, after a pause and on whatever the table
// looks like once that pause is over.
func (b *botSeat) consider(snap protocol.Snapshot) {
	if snap.Table.State == StateEnded {
		b.close()
		return
	}
	if snap.You.CanRebuy {
		// Busted with rebuys allowed: buy back in and wait for the deal.
		if err := b.table.Rebuy(b.playerID); err != nil {
			b.table.log.Debug("bot rebuy", "table", b.table.ID, "err", err)
		}
		return
	}
	if snap.You.Options == nil || snap.Hand == nil || snap.You.Seat == nil {
		return
	}
	key := botTurnKey(snap)
	if key == b.lastActKey {
		return
	}
	select {
	case <-b.stop:
		return
	case <-time.After(b.thinkFor(snap)):
	}
	// The table may have moved on while we were thinking (a fold elsewhere,
	// a timeout, a kick): act on the newest snapshot there is.
	for {
		select {
		case newer := <-b.snapshots:
			snap = newer
			continue
		case <-b.stop:
			return
		default:
		}
		break
	}
	if snap.You.Options == nil || snap.Hand == nil || snap.You.Seat == nil {
		return
	}
	key = botTurnKey(snap)
	if key == b.lastActKey {
		return
	}
	b.lastActKey = key
	a := botplay.Decide(*snap.You.Options, snap, *snap.You.Seat, b.rng)
	if err := b.table.Action(b.playerID, poker.Action{Kind: poker.ActionKind(a.Kind), Amount: a.Amount}); err != nil {
		b.table.log.Debug("bot action rejected", "table", b.table.ID, "kind", a.Kind, "err", err)
	}
}

// thinkFor is how long to pause before acting. Never long enough to run the
// turn clock down: a table with a short clock (or a bot on its time bank)
// gets a quick answer rather than a seat that times itself out.
func (b *botSeat) thinkFor(snap protocol.Snapshot) time.Duration {
	think := botThinkMin + time.Duration(b.rng.Int64N(int64(botThinkMax-botThinkMin+1)))
	if snap.Hand.DeadlineTS != nil && snap.ServerTS > 0 {
		left := time.Duration(*snap.Hand.DeadlineTS-snap.ServerTS) * time.Millisecond
		if limit := left / 3; limit < think {
			think = limit
		}
	}
	return max(think, 0)
}

// botTurnKey identifies one turn: the hand, the street and the deadline all
// change as the action moves on.
func botTurnKey(s protocol.Snapshot) string {
	var deadline int64
	if s.Hand.DeadlineTS != nil {
		deadline = *s.Hand.DeadlineTS
	}
	return fmt.Sprintf("%d/%s/%d", s.Table.HandNumber, s.Hand.Street, deadline)
}

// AddBot seats a bot and starts playing it. The name is picked from the free
// ones (Bot 1, Bot 2, ...) so the host does not have to think of one.
func (t *Table) AddBot() (JoinResult, error) {
	name, err := t.freeBotName()
	if err != nil {
		return JoinResult{}, err
	}
	res, err := t.Join(name, -1, -1, "", Profile{}, true)
	if err != nil {
		return JoinResult{}, err
	}
	t.startBot(res.PlayerID)
	return res, nil
}

// freeBotName returns the lowest unused "Bot n".
func (t *Table) freeBotName() (string, error) {
	var name string
	err := t.callErr(func() error {
		for i := 1; i <= botNameTries; i++ {
			candidate := fmt.Sprintf("%s %d", botNameStem, i)
			if _, taken := t.names[NameKey(candidate)]; !taken {
				name = candidate
				return nil
			}
		}
		return ErrNameTaken
	})
	return name, err
}

// startBot runs the goroutine that plays a seat. The seat must already exist
// and be marked as a bot.
func (t *Table) startBot(playerID string) {
	b := newBotSeat(t, playerID, randomSeed())
	go b.run()
}

func randomSeed() uint64 {
	return rand.Uint64()
}
