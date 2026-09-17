package poker

import "math/rand/v2"

// Equity returns each hand's share of the pot if the remaining board were
// dealt from the cards of the variant's deck not in hands or on the board:
// wins count 1, an n-way tie counts 1/n. With two or fewer cards to come
// every completion is enumerated; otherwise up to maxSamples random
// completions are drawn (seed makes that deterministic). The result sums to
// 1 for a non-empty hands slice.
func Equity(v Variant, board []Card, hands [][2]Card, maxSamples int, seed uint64) []float64 {
	n := len(hands)
	out := make([]float64, n)
	if n == 0 {
		return out
	}
	missing := 5 - len(board)
	if missing < 0 {
		missing = 0
	}
	used := make([]bool, DeckSize)
	for _, c := range board {
		used[c] = true
	}
	for _, h := range hands {
		used[h[0]], used[h[1]] = true, true
	}
	var deck []Card
	for _, c := range v.Deck() {
		if !used[c] {
			deck = append(deck, c)
		}
	}
	full := make([]Card, len(board), 5)
	copy(full, board)
	cards := make([]Card, 7)
	values := make([]HandValue, n)
	score := func(b []Card) {
		best := -1
		var bestVal HandValue
		var winners []int
		for i, h := range hands {
			cards = cards[:0]
			cards = append(cards, h[0], h[1])
			cards = append(cards, b...)
			values[i] = Evaluate(cards)
			switch c := values[i].Compare(bestVal); {
			case best < 0 || c > 0:
				best, bestVal, winners = i, values[i], winners[:0]
				winners = append(winners, i)
			case c == 0:
				winners = append(winners, i)
			}
		}
		share := 1 / float64(len(winners))
		for _, w := range winners {
			out[w] += share
		}
	}
	total := 0.0
	switch {
	case missing == 0:
		score(full)
		total = 1
	case missing <= 2 || maxSamples <= 0:
		// Exhaustive: every combination of the missing cards.
		idx := make([]int, missing)
		for i := range idx {
			idx[i] = i
		}
		for {
			b := full[:len(board)]
			for _, i := range idx {
				b = append(b, deck[i])
			}
			score(b)
			total++
			// next combination
			k := missing - 1
			for k >= 0 && idx[k] == len(deck)-missing+k {
				k--
			}
			if k < 0 {
				break
			}
			idx[k]++
			for j := k + 1; j < missing; j++ {
				idx[j] = idx[j-1] + 1
			}
		}
	default:
		rng := rand.New(rand.NewPCG(seed, seed^0x9e3779b97f4a7c15))
		b := make([]Card, 0, 5)
		for s := 0; s < maxSamples; s++ {
			// Partial Fisher-Yates for the first `missing` cards.
			for i := 0; i < missing; i++ {
				j := i + rng.IntN(len(deck)-i)
				deck[i], deck[j] = deck[j], deck[i]
			}
			b = append(b[:0], board...)
			b = append(b, deck[:missing]...)
			score(b)
			total++
		}
	}
	for i := range out {
		out[i] /= total
	}
	return out
}

// Strength is the share of the pot hero would take against opponents random
// hands, over samples random deals of those hands and the rest of the board
// from the variant's deck (hero's cards and the board excluded): a win
// counts 1, an n-way tie 1/n. A quick, rough measure of how good a hand is
// right now, meant for beginners; it ignores how anyone plays.
func Strength(v Variant, board []Card, hero [2]Card, opponents, samples int, seed uint64) float64 {
	if opponents < 1 {
		opponents = 1
	}
	if samples < 1 {
		samples = 1
	}
	used := make([]bool, DeckSize)
	for _, c := range board {
		used[c] = true
	}
	used[hero[0]], used[hero[1]] = true, true
	var deck []Card
	for _, c := range v.Deck() {
		if !used[c] {
			deck = append(deck, c)
		}
	}
	missing := 5 - len(board)
	if missing < 0 {
		missing = 0
	}
	need := missing + 2*opponents
	if need > len(deck) {
		return 0
	}
	rng := rand.New(rand.NewPCG(seed, seed^0x9e3779b97f4a7c15))
	full := make([]Card, 0, 5)
	cards := make([]Card, 0, 7)
	total := 0.0
	for s := 0; s < samples; s++ {
		for i := 0; i < need; i++ {
			j := i + rng.IntN(len(deck)-i)
			deck[i], deck[j] = deck[j], deck[i]
		}
		full = append(full[:0], board...)
		full = append(full, deck[:missing]...)
		cards = append(cards[:0], hero[0], hero[1])
		cards = append(cards, full...)
		mine := Evaluate(cards)
		ties, beaten := 1, false
		for o := 0; o < opponents && !beaten; o++ {
			cards = append(cards[:0], deck[missing+2*o], deck[missing+2*o+1])
			cards = append(cards, full...)
			switch Evaluate(cards).Compare(mine) {
			case 1:
				beaten = true
			case 0:
				ties++
			}
		}
		if !beaten {
			total += 1 / float64(ties)
		}
	}
	return total / float64(samples)
}
