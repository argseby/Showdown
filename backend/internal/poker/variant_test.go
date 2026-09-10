package poker

import (
	"math"
	"testing"
)

func TestRoyalDeck(t *testing.T) {
	t.Parallel()
	if d := Holdem.Deck(); len(d) != DeckSize || Holdem.DeckSize() != DeckSize {
		t.Fatalf("hold'em deck = %d cards", len(d))
	}
	d := Royal.Deck()
	if len(d) != RoyalDeckSize || Royal.DeckSize() != RoyalDeckSize {
		t.Fatalf("royal deck = %d cards", len(d))
	}
	seen := map[Card]bool{}
	for _, c := range d {
		if c.Rank() < Ten || seen[c] {
			t.Fatalf("royal deck holds %s", c)
		}
		seen[c] = true
	}
	if Royal.String() != "royal" || Holdem.String() != "holdem" || Royal.LowestRank() != Ten {
		t.Fatal("variant names or lowest rank")
	}
}

func TestRoyalHandDealsOnlyTenToAce(t *testing.T) {
	t.Parallel()
	cfg := cfgWith(0)
	cfg.Variant = Royal
	seats := []Seat{{0, 1000}, {1, 1000}, {2, 1000}}
	// A shuffle that moves cards around, so the test does not depend on the
	// canonical order.
	swap := func(d []Card) { d[0], d[len(d)-1] = d[len(d)-1], d[0] }
	h, events, err := NewHand(cfg, seats, swap)
	if err != nil {
		t.Fatal(err)
	}
	if h.Variant() != Royal || len(h.deck) != RoyalDeckSize {
		t.Fatalf("variant %v, deck %d", h.Variant(), len(h.deck))
	}
	dealt := 0
	for _, e := range events {
		if e.Kind != EvHoleCardsDealt {
			continue
		}
		for _, c := range e.Cards {
			if c.Rank() < Ten {
				t.Fatalf("seat %d was dealt %s in Royal Hold'em", e.Seat, c)
			}
			dealt++
		}
	}
	if dealt != 6 {
		t.Fatalf("dealt %d hole cards", dealt)
	}
	// Seven players fit a 20-card deck (14 hole cards + 5 board); eight do not.
	seven := make([]Seat, 7)
	for i := range seven {
		seven[i] = Seat{i, 1000}
	}
	if _, _, err := NewHand(cfg, seven, func([]Card) {}); err != nil {
		t.Fatalf("7 players: %v", err)
	}
	eight := append(append([]Seat(nil), seven...), Seat{7, 1000})
	if _, _, err := NewHand(cfg, eight, func([]Card) {}); err == nil {
		t.Fatal("8 players must not fit a 20-card deck")
	}
}

func TestRunItTwiceNeedsCardsForBothBoards(t *testing.T) {
	t.Parallel()
	h := &Hand{phase: PhaseDealPending, runout: true, deck: Royal.Deck(), deckPos: 12}
	if h.CanRunItTwice() {
		t.Fatal("6 royal players all-in preflop: two boards need 10 of the 8 cards left")
	}
	h.deckPos = 10
	if !h.CanRunItTwice() {
		t.Fatal("5 royal players all-in preflop: both boards fit exactly")
	}
	h.board = MustParseCards("As Ks Qs")
	h.deckPos = 16
	if !h.CanRunItTwice() {
		t.Fatal("after the flop 4 cards are needed and 4 are left")
	}
	h.deckPos = 17
	if h.CanRunItTwice() {
		t.Fatal("after the flop 4 cards are needed but only 3 are left")
	}
}

func TestEquityUsesTheVariantDeck(t *testing.T) {
	t.Parallel()
	hands := [][2]Card{{MustParseCards("Th")[0], MustParseCards("Td")[0]}, {MustParseCards("Kc")[0], MustParseCards("Kd")[0]}}
	board := MustParseCards("Ah As Qc Jd")
	// Only a ten on the river (2 outs) wins for the tens: 12 river cards in
	// the royal deck, 44 in the full one.
	e := Equity(Royal, board, hands, 0, 1)
	if math.Abs(e[0]-2.0/12) > 1e-9 || math.Abs(e[0]+e[1]-1) > 1e-9 {
		t.Fatalf("royal equity = %v", e)
	}
	e = Equity(Holdem, board, hands, 0, 1)
	if math.Abs(e[0]-2.0/44) > 1e-9 {
		t.Fatalf("hold'em equity = %v", e)
	}
}
