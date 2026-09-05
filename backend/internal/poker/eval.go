package poker

import "fmt"

// Category is the hand class, ordered from weakest to strongest.
type Category int

// Hand categories.
const (
	HighCard Category = iota
	OnePair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
)

var categoryNames = [...]string{
	"High Card", "Pair", "Two Pair", "Three of a Kind", "Straight",
	"Flush", "Full House", "Four of a Kind", "Straight Flush",
}

func (c Category) String() string { return categoryNames[c] }

// HandValue is the evaluation of a five-card hand. Rank is a total order:
// a higher Rank always beats a lower one, equal Ranks tie. Best holds the
// five cards that form the hand, ordered by significance (e.g. the pair
// first, then kickers high to low).
type HandValue struct {
	Category Category
	Rank     uint32
	Best     [5]Card
}

// Compare returns -1, 0 or 1 as h is weaker than, equal to or stronger than o.
func (h HandValue) Compare(o HandValue) int {
	switch {
	case h.Rank < o.Rank:
		return -1
	case h.Rank > o.Rank:
		return 1
	default:
		return 0
	}
}

// tiebreak ranks encoded in Rank, most significant first.
func (h HandValue) ranks() [5]Rank {
	return [5]Rank{
		Rank((h.Rank >> 16) & 0xF),
		Rank((h.Rank >> 12) & 0xF),
		Rank((h.Rank >> 8) & 0xF),
		Rank((h.Rank >> 4) & 0xF),
		Rank(h.Rank & 0xF),
	}
}

// Describe renders the hand in words, e.g. "Two Pair, Kings and Nines".
func (h HandValue) Describe() string {
	r := h.ranks()
	switch h.Category {
	case HighCard:
		return fmt.Sprintf("High Card, %s", r[0].Name())
	case OnePair:
		return fmt.Sprintf("Pair of %s", r[0].Plural())
	case TwoPair:
		return fmt.Sprintf("Two Pair, %s and %s", r[0].Plural(), r[1].Plural())
	case ThreeOfAKind:
		return fmt.Sprintf("Three of a Kind, %s", r[0].Plural())
	case Straight:
		return fmt.Sprintf("Straight, %s High", r[0].Name())
	case Flush:
		return fmt.Sprintf("Flush, %s High", r[0].Name())
	case FullHouse:
		return fmt.Sprintf("Full House, %s over %s", r[0].Plural(), r[1].Plural())
	case FourOfAKind:
		return fmt.Sprintf("Four of a Kind, %s", r[0].Plural())
	case StraightFlush:
		if r[0] == Ace {
			return "Royal Flush"
		}
		return fmt.Sprintf("Straight Flush, %s High", r[0].Name())
	}
	return "Unknown"
}

// Evaluate returns the best five-card hand from 5, 6 or 7 cards.
func Evaluate(cards []Card) HandValue {
	switch len(cards) {
	case 5:
		return evaluate5([5]Card{cards[0], cards[1], cards[2], cards[3], cards[4]})
	case 6:
		var best HandValue
		for drop := 0; drop < 6; drop++ {
			var five [5]Card
			k := 0
			for i := 0; i < 6; i++ {
				if i != drop {
					five[k] = cards[i]
					k++
				}
			}
			if v := evaluate5(five); v.Rank > best.Rank {
				best = v
			}
		}
		return best
	case 7:
		var best HandValue
		for a := 0; a < 7; a++ {
			for b := a + 1; b < 7; b++ {
				var five [5]Card
				k := 0
				for i := 0; i < 7; i++ {
					if i != a && i != b {
						five[k] = cards[i]
						k++
					}
				}
				if v := evaluate5(five); v.Rank > best.Rank {
					best = v
				}
			}
		}
		return best
	default:
		panic(fmt.Sprintf("poker: Evaluate needs 5..7 cards, got %d", len(cards)))
	}
}

func encode(cat Category, r [5]Rank) uint32 {
	return uint32(cat)<<20 | uint32(r[0])<<16 | uint32(r[1])<<12 | uint32(r[2])<<8 | uint32(r[3])<<4 | uint32(r[4])
}

// evaluate5 classifies exactly five cards.
func evaluate5(c [5]Card) HandValue {
	// Insertion sort descending by rank (five elements; avoids reflection).
	for i := 1; i < 5; i++ {
		for j := i; j > 0 && c[j].Rank() > c[j-1].Rank(); j-- {
			c[j], c[j-1] = c[j-1], c[j]
		}
	}

	flush := c[0].Suit() == c[1].Suit() && c[0].Suit() == c[2].Suit() &&
		c[0].Suit() == c[3].Suit() && c[0].Suit() == c[4].Suit()

	// Count ranks.
	var counts [13]uint8
	for _, card := range c {
		counts[card.Rank()]++
	}

	// Straight detection on the descending ranks.
	straightHigh, isStraight := straightTop(c)

	// Group ranks by multiplicity, highest multiplicity first, then rank desc.
	type group struct {
		rank  Rank
		count uint8
	}
	var groupsBuf [5]group
	groups := groupsBuf[:0]
	for r := Ace; ; r-- {
		if counts[r] > 0 {
			groups = append(groups, group{r, counts[r]})
		}
		if r == Two {
			break
		}
	}
	// Stable insertion sort by count descending (rank order is preserved).
	for i := 1; i < len(groups); i++ {
		for j := i; j > 0 && groups[j].count > groups[j-1].count; j-- {
			groups[j], groups[j-1] = groups[j-1], groups[j]
		}
	}

	var cat Category
	var ranks [5]Rank
	switch {
	case isStraight && flush:
		cat = StraightFlush
		ranks[0] = straightHigh
	case groups[0].count == 4:
		cat = FourOfAKind
		ranks[0], ranks[1] = groups[0].rank, groups[1].rank
	case groups[0].count == 3 && groups[1].count == 2:
		cat = FullHouse
		ranks[0], ranks[1] = groups[0].rank, groups[1].rank
	case flush:
		cat = Flush
		for i := range c {
			ranks[i] = c[i].Rank()
		}
	case isStraight:
		cat = Straight
		ranks[0] = straightHigh
	case groups[0].count == 3:
		cat = ThreeOfAKind
		ranks[0], ranks[1], ranks[2] = groups[0].rank, groups[1].rank, groups[2].rank
	case groups[0].count == 2 && groups[1].count == 2:
		cat = TwoPair
		ranks[0], ranks[1], ranks[2] = groups[0].rank, groups[1].rank, groups[2].rank
	case groups[0].count == 2:
		cat = OnePair
		ranks[0], ranks[1], ranks[2], ranks[3] = groups[0].rank, groups[1].rank, groups[2].rank, groups[3].rank
	default:
		cat = HighCard
		for i := range c {
			ranks[i] = c[i].Rank()
		}
	}

	// Order Best by significance: grouped cards first (by group order), and
	// for straights the wheel's ace goes last.
	var best [5]Card
	k := 0
	if isStraight {
		if straightHigh == Five {
			// c is A,5,4,3,2 descending; rotate the ace to the end.
			best = [5]Card{c[1], c[2], c[3], c[4], c[0]}
		} else {
			best = c
		}
	} else {
		for _, g := range groups {
			for _, card := range c {
				if card.Rank() == g.rank {
					best[k] = card
					k++
				}
			}
		}
	}
	return HandValue{Category: cat, Rank: encode(cat, ranks), Best: best}
}

// straightTop returns the top rank of a straight formed by five cards sorted
// descending by rank, treating A-2-3-4-5 as a Five-high straight.
func straightTop(c [5]Card) (Rank, bool) {
	for i := 1; i < 5; i++ {
		if c[i].Rank() == c[i-1].Rank() {
			return 0, false
		}
	}
	if c[0].Rank()-c[4].Rank() == 4 {
		return c[0].Rank(), true
	}
	if c[0].Rank() == Ace && c[1].Rank() == Five && c[4].Rank() == Two {
		return Five, true
	}
	return 0, false
}
