package poker

import (
	"encoding/json"
	"testing"
)

func TestCardRoundTrip(t *testing.T) {
	t.Parallel()
	seen := map[string]bool{}
	for _, c := range NewDeck() {
		s := c.String()
		if len(s) != 2 || seen[s] {
			t.Fatalf("card %d renders as %q", c, s)
		}
		seen[s] = true
		parsed, err := ParseCard(s)
		if err != nil || parsed != c {
			t.Fatalf("ParseCard(%q) = %v, %v; want %v", s, parsed, err, c)
		}
		if MakeCard(c.Rank(), c.Suit()) != c {
			t.Fatalf("MakeCard(Rank, Suit) mismatch for %v", c)
		}
	}
	if len(seen) != DeckSize {
		t.Fatalf("deck has %d distinct cards", len(seen))
	}
	if got := MakeCard(Ace, Spades).String(); got != "As" {
		t.Fatalf("As renders as %q", got)
	}
	if got := MakeCard(Ten, Diamonds).String(); got != "Td" {
		t.Fatalf("Td renders as %q", got)
	}
	if Card(200).String() != "??" {
		t.Fatal("invalid card must render as ??")
	}
}

func TestParseCardErrors(t *testing.T) {
	t.Parallel()
	for _, s := range []string{"", "A", "Asx", "1s", "Ax", "as", "AS"} {
		if _, err := ParseCard(s); err == nil {
			t.Errorf("ParseCard(%q) accepted", s)
		}
	}
}

func TestCardJSON(t *testing.T) {
	t.Parallel()
	in := []Card{MakeCard(Ace, Spades), MakeCard(Two, Clubs)}
	b, err := json.Marshal(in)
	if err != nil || string(b) != `["As","2c"]` {
		t.Fatalf("marshal = %s, %v", b, err)
	}
	var out []Card
	if err := json.Unmarshal(b, &out); err != nil || len(out) != 2 || out[0] != in[0] || out[1] != in[1] {
		t.Fatalf("unmarshal = %v, %v", out, err)
	}
	if err := json.Unmarshal([]byte(`["Zz"]`), &out); err == nil {
		t.Fatal("expected error for invalid card")
	}
	if _, err := Card(99).MarshalText(); err == nil {
		t.Fatal("expected error marshalling invalid card")
	}
}

func TestMustParseCards(t *testing.T) {
	t.Parallel()
	cards := MustParseCards(" As  Kd 7c ")
	if len(cards) != 3 || cards[0].String() != "As" || cards[2].String() != "7c" {
		t.Fatalf("MustParseCards = %v", cards)
	}
	defer func() {
		if recover() == nil {
			t.Fatal("expected panic")
		}
	}()
	MustParseCards("As Xx")
}

func TestRankNames(t *testing.T) {
	t.Parallel()
	if Ace.Name() != "Ace" || Six.Plural() != "Sixes" || Ten.String() != "T" || Clubs.String() != "c" {
		t.Fatal("rank/suit naming wrong")
	}
}

func TestSecureShuffleIsPermutation(t *testing.T) {
	t.Parallel()
	deck := NewDeck()
	SecureShuffle(deck)
	var seen [DeckSize]bool
	for _, c := range deck {
		if !c.Valid() || seen[c] {
			t.Fatalf("shuffle produced duplicate or invalid card %v", c)
		}
		seen[c] = true
	}
	// Over a few shuffles the first card must vary (probability of failure ~ (1/52)^4).
	first := deck[0]
	varied := false
	for i := 0; i < 5; i++ {
		d := NewDeck()
		SecureShuffle(d)
		if d[0] != first {
			varied = true
		}
	}
	if !varied {
		t.Fatal("shuffle does not appear to randomize")
	}
}
