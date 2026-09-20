package table

import (
	"context"
	"errors"
	"log/slog"
	"testing"
	"time"

	"showdown/internal/poker"
	"showdown/internal/store"
)

// botSettings gives the bots a turn clock they can comfortably act inside.
// The pause itself is already out of the way — testDelays thinks for
// milliseconds — but a busy -race run can still take its time between the
// snapshot and the action, and a seat that misses its turn stops playing.
func botSettings() Settings {
	s := testSettings()
	s.TurnTime = 5
	s.SitOutAfterMissedTurns = 3
	return s
}

func TestAddBotSeatsAPlayerThatPlays(t *testing.T) {
	t.Parallel()
	tbl := newTestTableShuffled(t, botSettings(), poker.SecureShuffle)

	first, err := tbl.AddBot()
	if err != nil {
		t.Fatalf("AddBot: %v", err)
	}
	second, err := tbl.AddBot()
	if err != nil {
		t.Fatalf("AddBot: %v", err)
	}
	if first.Name != "Bot 1" || second.Name != "Bot 2" {
		t.Fatalf("names = %q %q, want Bot 1 and Bot 2", first.Name, second.Name)
	}

	// The bots attach themselves, so the seats come up connected...
	waitFor(t, "both bots connected", func() bool {
		connected := 0
		tbl.call(func() {
			for _, p := range tbl.seats[:2] {
				if p != nil && p.Connected && p.Bot {
					connected++
				}
			}
		})
		return connected == 2
	})
	// ...and then play by themselves, with nobody else at the table.
	waitFor(t, "three hands", func() bool { return handNumber(tbl) >= 3 })

	// Playing means acting, not letting the clock run out.
	var missed int
	tbl.call(func() {
		for _, p := range tbl.seats[:2] {
			if p != nil {
				missed += p.MissedTurns
			}
		}
	})
	if missed != 0 {
		t.Errorf("bots missed %d turns: they are not acting in time", missed)
	}
}

func TestKickedBotStopsPlaying(t *testing.T) {
	t.Parallel()
	tbl := newTestTableShuffled(t, botSettings(), poker.SecureShuffle)
	bot, err := tbl.AddBot()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := tbl.AddBot(); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "a hand", func() bool { return handNumber(tbl) >= 1 })

	if err := tbl.Kick(bot.PlayerID); err != nil {
		t.Fatalf("Kick: %v", err)
	}
	waitFor(t, "the seat to clear", func() bool { return !tbl.HasPlayer(bot.PlayerID) })
	// A kicked bot must not keep acting: its own connection was closed, so
	// every further action is refused.
	if err := tbl.Action(bot.PlayerID, poker.Action{Kind: "check"}); err == nil {
		t.Error("a kicked bot could still act")
	}
	// A name stays reserved once it has been used, here as anywhere else,
	// so the next bot takes the next free number rather than the seat's.
	next, err := tbl.AddBot()
	if err != nil {
		t.Fatalf("AddBot after kick: %v", err)
	}
	if next.Name != "Bot 3" {
		t.Errorf("name after kick = %q, want the next free number", next.Name)
	}
}

func TestAddBotRefusedOnAFullTable(t *testing.T) {
	t.Parallel()
	s := botSettings()
	s.MaxPlayers = 2
	s.AutoStart = false
	tbl := newTestTable(t, s)
	if _, err := tbl.AddBot(); err != nil {
		t.Fatal(err)
	}
	if _, err := tbl.AddBot(); err != nil {
		t.Fatal(err)
	}
	if _, err := tbl.AddBot(); !errors.Is(err, ErrTableFull) {
		t.Fatalf("third bot at a two-seat table: %v, want ErrTableFull", err)
	}
}

func TestBotSeatsComeBackAfterARestart(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	dir := t.TempDir()
	st, err := store.Open(ctx, dir, slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	deps := Deps{Store: st, Log: slog.New(slog.DiscardHandler), Delays: testDelays}
	reg := NewRegistry(deps, 10)
	// A registry validates what it is given, so this table takes the real
	// minimums rather than the sped-up ones the other tests use.
	s := botSettings()
	s.DisconnectedTurnTime, s.HandDelayMs = 3, 2000
	tbl, err := reg.Create(ctx, "Bots", s, "hash")
	if err != nil {
		t.Fatal(err)
	}
	person, _ := join(t, tbl, "Alice")
	bot, err := tbl.AddBot()
	if err != nil {
		t.Fatal(err)
	}
	waitFor(t, "a hand", func() bool { return handNumber(tbl) >= 1 })

	shutdownCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	reg.Shutdown(shutdownCtx)

	reg2 := NewRegistry(deps, 10)
	if err := reg2.LoadAll(ctx); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { reg2.Shutdown(context.Background()) })
	restored, ok := reg2.Get(tbl.ID)
	if !ok {
		t.Fatal("table not restored")
	}
	// The bot's goroutine did not survive the restart, but the seat did, so
	// the table starts playing it again on its own. Alice's browser has to
	// come back by itself, as before.
	waitFor(t, "the bot to reconnect", func() bool {
		var connected bool
		restored.call(func() {
			for _, p := range restored.seats[:restored.settings.MaxPlayers] {
				if p != nil && p.ID == bot.PlayerID {
					connected = p.Connected && p.Bot
				}
			}
		})
		return connected
	})
	var personConnected bool
	restored.call(func() {
		for _, p := range restored.seats[:restored.settings.MaxPlayers] {
			if p != nil && p.ID == person.PlayerID {
				personConnected = p.Connected
			}
		}
	})
	if personConnected {
		t.Error("a person's seat came back connected; only bots reconnect themselves")
	}
}
