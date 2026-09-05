package poker

import (
	"testing"
)

func ev(s string) HandValue { return Evaluate(MustParseCards(s)) }

func TestExhaustiveFiveCardClassification(t *testing.T) {
	if testing.Short() {
		t.Skip("exhaustive evaluator test skipped in -short mode")
	}
	want := map[Category]int{
		HighCard: 1302540, OnePair: 1098240, TwoPair: 123552, ThreeOfAKind: 54912,
		Straight: 10200, Flush: 5108, FullHouse: 3744, FourOfAKind: 624, StraightFlush: 40,
	}
	got := map[Category]int{}
	royals := 0
	total := 0
	minRankPerCat := map[Category]uint32{}
	maxRankPerCat := map[Category]uint32{}
	for a := 0; a < 52; a++ {
		for b := a + 1; b < 52; b++ {
			for c := b + 1; c < 52; c++ {
				for d := c + 1; d < 52; d++ {
					for e := d + 1; e < 52; e++ {
						v := evaluate5([5]Card{Card(a), Card(b), Card(c), Card(d), Card(e)})
						got[v.Category]++
						total++
						if v.Category == StraightFlush && v.ranks()[0] == Ace {
							royals++
						}
						if lo, ok := minRankPerCat[v.Category]; !ok || v.Rank < lo {
							minRankPerCat[v.Category] = v.Rank
						}
						if v.Rank > maxRankPerCat[v.Category] {
							maxRankPerCat[v.Category] = v.Rank
						}
					}
				}
			}
		}
	}
	if total != 2598960 {
		t.Fatalf("evaluated %d hands, want 2598960", total)
	}
	for cat, n := range want {
		if got[cat] != n {
			t.Errorf("%v: got %d, want %d", cat, got[cat], n)
		}
	}
	if royals != 4 {
		t.Errorf("royal flushes: got %d, want 4", royals)
	}
	// Ranks must be totally ordered by category.
	for cat := HighCard; cat < StraightFlush; cat++ {
		if maxRankPerCat[cat] >= minRankPerCat[cat+1] {
			t.Errorf("rank ranges overlap between %v and %v", cat, cat+1)
		}
	}
}

func TestEvaluateCategories(t *testing.T) {
	t.Parallel()
	cases := []struct {
		cards string
		cat   Category
		desc  string
	}{
		{"As Ks Qs Js Ts", StraightFlush, "Royal Flush"},
		{"9h 8h 7h 6h 5h 2c 3d", StraightFlush, "Straight Flush, Nine High"},
		{"Ah 2h 3h 4h 5h Kd Qc", StraightFlush, "Straight Flush, Five High"},
		{"7s 7d 7c 7h 2s As 3d", FourOfAKind, "Four of a Kind, Sevens"},
		{"3s 3d 3c Ks Kd 9s 9d", FullHouse, "Full House, Threes over Kings"},
		{"Ks Kd 9s 9d 9c 3s 3d", FullHouse, "Full House, Nines over Kings"},
		{"Ks 9s 5s 3s 2s Ad Ac", Flush, "Flush, King High"},
		{"As 2d 3c 4h 5s Kd Qc", Straight, "Straight, Five High"},
		{"2s 3d 4c 5h 6s Kd Qc", Straight, "Straight, Six High"},
		{"Ts Jd Qc Kh As 2d 2c", Straight, "Straight, Ace High"},
		{"Qs Qd Qc 7h 2s 3d 4c", ThreeOfAKind, "Three of a Kind, Queens"},
		{"Ks Kd 9s 9d 3c As 2d", TwoPair, "Two Pair, Kings and Nines"},
		{"2s 2d 9s 8d 3c", OnePair, "Pair of Twos"},
		{"As Kd 9s 8d 3c", HighCard, "High Card, Ace"},
	}
	for _, tc := range cases {
		v := ev(tc.cards)
		if v.Category != tc.cat {
			t.Errorf("%s: category %v, want %v", tc.cards, v.Category, tc.cat)
		}
		if d := v.Describe(); d != tc.desc {
			t.Errorf("%s: describe %q, want %q", tc.cards, d, tc.desc)
		}
		if len(v.Best) != 5 {
			t.Errorf("%s: best has %d cards", tc.cards, len(v.Best))
		}
	}
	if (HandValue{Category: Category(99)}).Describe() != "Unknown" {
		t.Error("unknown category description")
	}
}

func TestEvaluateTieBreaks(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name string
		a, b string
		want int // sign of a vs b
	}{
		{"kicker decides high card", "As Ks Qd Jc 9h 3s 2d", "Ad Kd Qh Jd 8s 3c 2h", 1},
		{"suits never break ties", "As Ks Qd Jc 9h", "Ad Kd Qh Jd 9s", 0},
		{"wheel loses to six-high straight", "As 2d 3c 4h 5s Kd Qc", "2s 3d 4c 5h 6s Kd Qc", -1},
		{"wheel is a straight and beats trips", "As 2d 3c 4h 5s", "Ks Kd Kc 2h 3s", 1},
		{"counterfeit two pair: ace kicker beats pocket deuces", "Ks Kd 9s 9d 3c As 4d", "Ks Kd 9s 9d 3c 2s 2d", 1},
		{"two pair: higher top pair wins", "As Ad 2s 2d 3c", "Ks Kd Qs Qd 3c", 1},
		{"two pair: same top pair, second pair decides", "As Ad 9s 9d 3c", "Ac Ah 8s 8d Kc", 1},
		{"two pair: kicker decides", "As Ad 9s 9d Kc", "Ac Ah 9c 9h Qc", 1},
		{"pair: kickers decide", "As Ad 9s 8d 3c", "Ac Ah 9c 7h 6c", 1},
		{"trips: kicker decides", "7s 7d 7c As 2d", "7s 7d 7c Ks Qd", 1},
		{"full house: trips rank first", "3s 3d 3c Ks Kd", "Ks Kd Kc 3s 3d", -1},
		{"quads: kicker decides", "7s 7d 7c 7h 2s As 3d", "7s 7d 7c 7h 2s Kd 3c", 1},
		{"flush beats straight", "Ks 9s 5s 3s 2s Ad Ac", "As 2d 3c 4h 5s Kd Qc", 1},
		{"full house beats flush", "3s 3d 3c Ks Kd 9s 9d", "Ks 9s 5s 3s 2s Ad Ac", 1},
		{"flush: high card then next", "As 9s 5s 3s 2s", "Ks Qs Js 9s 2s", 1},
		{"flush: second card decides", "As Ts 5s 3s 2s", "Ah 9h 8h 7h 6h", 1},
		{"straight on board: tie", "Ts Jd Qc Kh As 2d 2c", "Ts Jd Qc Kh As 3d 3c", 0},
		{"seven cards pick best five", "2s 2d 2c Ks Kd 9s 9d", "2s 2d 2c Ks Kd 9s 9d", 0},
		{"six cards", "As Ad Ks Kd 2c 3c", "As Ad Qs Qd 2c 3c", 1},
	}
	for _, tc := range cases {
		a, b := ev(tc.a), ev(tc.b)
		got := a.Compare(b)
		if got != tc.want {
			t.Errorf("%s: %s (%s) vs %s (%s) = %d, want %d", tc.name, tc.a, a.Describe(), tc.b, b.Describe(), got, tc.want)
		}
		if b.Compare(a) != -got {
			t.Errorf("%s: Compare is not antisymmetric", tc.name)
		}
	}
}

func TestEvaluateBestCardsOrder(t *testing.T) {
	t.Parallel()
	v := ev("Ks 9s Kd 9d 3c As 2d")
	if got := cardsString(v.Best[:]); got != "Ks Kd 9s 9d As" {
		t.Fatalf("best = %q", got)
	}
	w := ev("As 2d 3c 4h 5s Kd Qc")
	if got := cardsString(w.Best[:]); got != "5s 4h 3c 2d As" {
		t.Fatalf("wheel best = %q", got)
	}
}

func TestEvaluatePanicsOnBadSize(t *testing.T) {
	t.Parallel()
	for _, n := range []int{0, 4, 8} {
		func() {
			defer func() {
				if recover() == nil {
					t.Errorf("Evaluate with %d cards did not panic", n)
				}
			}()
			Evaluate(NewDeck()[:n])
		}()
	}
}

func cardsString(cs []Card) string {
	s := ""
	for i, c := range cs {
		if i > 0 {
			s += " "
		}
		s += c.String()
	}
	return s
}
