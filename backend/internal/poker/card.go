// Package poker is the pure Texas Hold'em engine: cards, hand evaluation,
// betting rounds, side pots and showdown. It has no goroutines, no clock and
// no I/O; randomness is injected as a shuffle function.
package poker

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
)

// Rank of a card, Two (0) to Ace (12).
type Rank uint8

// Card ranks.
const (
	Two Rank = iota
	Three
	Four
	Five
	Six
	Seven
	Eight
	Nine
	Ten
	Jack
	Queen
	King
	Ace
)

// Suit of a card.
type Suit uint8

// Card suits.
const (
	Spades Suit = iota
	Hearts
	Diamonds
	Clubs
)

const (
	rankChars = "23456789TJQKA"
	suitChars = "shdc"
	// DeckSize is the number of cards in a deck.
	DeckSize = 52
)

var rankNames = [...]string{"Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Jack", "Queen", "King", "Ace"}
var rankPlurals = [...]string{"Twos", "Threes", "Fours", "Fives", "Sixes", "Sevens", "Eights", "Nines", "Tens", "Jacks", "Queens", "Kings", "Aces"}

// Name returns the English rank name ("Ace").
func (r Rank) Name() string { return rankNames[r] }

// Plural returns the English plural ("Aces").
func (r Rank) Plural() string { return rankPlurals[r] }

// String returns the single-character rank symbol.
func (r Rank) String() string { return string(rankChars[r]) }

// String returns the single-character suit symbol.
func (s Suit) String() string { return string(suitChars[s]) }

// Card is a playing card encoded as rank*4 + suit, 0..51.
type Card uint8

// MakeCard builds a card from rank and suit.
func MakeCard(r Rank, s Suit) Card { return Card(uint8(r)*4 + uint8(s)) }

// Rank of the card.
func (c Card) Rank() Rank { return Rank(c / 4) }

// Suit of the card.
func (c Card) Suit() Suit { return Suit(c % 4) }

// Valid reports whether the card is within 0..51.
func (c Card) Valid() bool { return c < DeckSize }

// String renders the card as two characters, e.g. "As" or "Td".
func (c Card) String() string {
	if !c.Valid() {
		return "??"
	}
	return string([]byte{rankChars[c.Rank()], suitChars[c.Suit()]})
}

// MarshalText encodes the card as its two-character string.
func (c Card) MarshalText() ([]byte, error) {
	if !c.Valid() {
		return nil, fmt.Errorf("invalid card %d", uint8(c))
	}
	return []byte(c.String()), nil
}

// UnmarshalText parses the two-character form.
func (c *Card) UnmarshalText(text []byte) error {
	parsed, err := ParseCard(string(text))
	if err != nil {
		return err
	}
	*c = parsed
	return nil
}

// ParseCard parses "As", "Td", ... (case-sensitive: uppercase rank, lowercase suit).
func ParseCard(s string) (Card, error) {
	if len(s) != 2 {
		return 0, fmt.Errorf("invalid card %q", s)
	}
	r, sIdx := -1, -1
	for i := 0; i < len(rankChars); i++ {
		if rankChars[i] == s[0] {
			r = i
			break
		}
	}
	for i := 0; i < len(suitChars); i++ {
		if suitChars[i] == s[1] {
			sIdx = i
			break
		}
	}
	if r < 0 || sIdx < 0 {
		return 0, fmt.Errorf("invalid card %q", s)
	}
	return MakeCard(Rank(r), Suit(sIdx)), nil
}

// MustParseCards parses a space-separated list such as "As Kd 7c" and panics
// on error. Intended for tests and fixtures.
func MustParseCards(s string) []Card {
	var out []Card
	start := -1
	for i := 0; i <= len(s); i++ {
		if i == len(s) || s[i] == ' ' {
			if start >= 0 {
				c, err := ParseCard(s[start:i])
				if err != nil {
					panic(err)
				}
				out = append(out, c)
				start = -1
			}
			continue
		}
		if start < 0 {
			start = i
		}
	}
	return out
}

// NewDeck returns the 52 cards in canonical order (unshuffled).
func NewDeck() []Card {
	deck := make([]Card, DeckSize)
	for i := range deck {
		deck[i] = Card(i)
	}
	return deck
}

// Variant selects the deck a hand is dealt from: Holdem uses all 52 cards,
// Royal only Ten to Ace of every suit (20 cards, "Royal Hold'em").
type Variant uint8

// Variants.
const (
	Holdem Variant = iota
	Royal
)

// RoyalDeckSize is the number of cards in a Royal Hold'em deck.
const RoyalDeckSize = 20

// LowestRank is the lowest rank the variant deals.
func (v Variant) LowestRank() Rank {
	if v == Royal {
		return Ten
	}
	return Two
}

// DeckSize is the number of cards in the variant's deck.
func (v Variant) DeckSize() int { return int(Ace-v.LowestRank()+1) * 4 }

// Deck returns the variant's cards in canonical order (unshuffled).
func (v Variant) Deck() []Card {
	deck := make([]Card, 0, v.DeckSize())
	for c := Card(0); c < DeckSize; c++ {
		if c.Rank() >= v.LowestRank() {
			deck = append(deck, c)
		}
	}
	return deck
}

// String is the variant's wire name.
func (v Variant) String() string {
	if v == Royal {
		return "royal"
	}
	return "holdem"
}

// SecureShuffle performs a Fisher–Yates shuffle driven by crypto/rand.
func SecureShuffle(deck []Card) {
	for i := len(deck) - 1; i > 0; i-- {
		j := secureIntn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}
}

func secureIntn(n int) int {
	v, err := rand.Int(rand.Reader, big.NewInt(int64(n)))
	if err != nil {
		// crypto/rand never fails on supported platforms; a failure here would
		// make the deal unfair, so refuse to continue.
		panic(errors.Join(errors.New("crypto/rand unavailable"), err))
	}
	return int(v.Int64())
}
