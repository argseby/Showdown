package main

import (
	"math"
	"runtime"
	"sync"

	"showdown/internal/poker"
)

// categoryNames are the nine hand categories in engine order.
var categoryNames = [9]string{
	"High card", "One pair", "Two pair", "Three of a kind", "Straight",
	"Flush", "Full house", "Four of a kind", "Straight flush",
}

// fiveCardCounts is how often each category occurs among the 2,598,960
// distinct five-card hands. These are the textbook frequencies; the
// evaluator has to reproduce them exactly.
var fiveCardCounts = [9]int64{1302540, 1098240, 123552, 54912, 10200, 5108, 3744, 624, 40}

// sevenCardCounts is how often each category occurs among the 133,784,560
// distinct seven-card hands; a fair shuffle has to reproduce the resulting
// probabilities within sampling error.
var sevenCardCounts = [9]int64{23294460, 58627800, 31433400, 6461620, 6180020, 4047644, 3473184, 224848, 41584}

// evaluatorAudit is the exhaustive classification of every five-card hand.
type evaluatorAudit struct {
	Hands    int64    `json:"hands"`
	Counts   [9]int64 `json:"counts"`
	Expected [9]int64 `json:"expected"`
	OK       bool     `json:"ok"`
}

// auditEvaluator deals every one of the 2,598,960 five-card combinations and
// checks the category counts against the textbook frequencies. This is what
// backs the claim that the hand ranking itself is right; the play simulation
// below only checks that the pots follow the ranking.
func auditEvaluator() evaluatorAudit {
	workers := runtime.GOMAXPROCS(0)
	parts := make([][9]int64, workers)
	var wg sync.WaitGroup
	for w := 0; w < workers; w++ {
		wg.Add(1)
		go func(w int) {
			defer wg.Done()
			var counts [9]int64
			for a := w; a < poker.DeckSize; a += workers {
				for b := a + 1; b < poker.DeckSize; b++ {
					for c := b + 1; c < poker.DeckSize; c++ {
						for d := c + 1; d < poker.DeckSize; d++ {
							for e := d + 1; e < poker.DeckSize; e++ {
								v := poker.Evaluate([]poker.Card{poker.Card(a), poker.Card(b), poker.Card(c), poker.Card(d), poker.Card(e)})
								counts[v.Category]++
							}
						}
					}
				}
			}
			parts[w] = counts
		}(w)
	}
	wg.Wait()
	out := evaluatorAudit{Expected: fiveCardCounts, OK: true}
	for _, p := range parts {
		for i, n := range p {
			out.Counts[i] += n
		}
	}
	for i := range out.Counts {
		out.Hands += out.Counts[i]
		if out.Counts[i] != fiveCardCounts[i] {
			out.OK = false
		}
	}
	return out
}

// shuffleAudit is the fairness check of the production shuffle.
type shuffleAudit struct {
	Deals      int64      `json:"deals"`
	Counts     [9]int64   `json:"counts"`
	Expected   [9]float64 `json:"expected"`
	CategoryX2 float64    `json:"category_chi_square"`
	CategoryP  float64    `json:"category_p"`
	PositionX2 float64    `json:"position_chi_square"`
	PositionP  float64    `json:"position_p"`
	OK         bool       `json:"ok"`
}

// auditShuffle deals n hands with the same crypto/rand Fisher-Yates shuffle
// the server deals with (rules.md 7.3) and tests two things: that the
// categories of the first seven cards follow the theoretical distribution,
// and that every one of the 52 cards reaches those seven positions equally
// often. Both are chi-square goodness-of-fit tests; a p-value that is not
// tiny means the deal is indistinguishable from a uniform shuffle.
func auditShuffle(n int64) shuffleAudit {
	workers := runtime.GOMAXPROCS(0)
	type part struct {
		cats [9]int64
		pos  [poker.DeckSize]int64
	}
	parts := make([]part, workers)
	var wg sync.WaitGroup
	for w := 0; w < workers; w++ {
		wg.Add(1)
		go func(w int) {
			defer wg.Done()
			deck := poker.NewDeck()
			var p part
			for i := int64(w); i < n; i += int64(workers) {
				poker.SecureShuffle(deck)
				seven := deck[:7]
				p.cats[poker.Evaluate(seven).Category]++
				for _, c := range seven {
					p.pos[c]++
				}
			}
			parts[w] = p
		}(w)
	}
	wg.Wait()

	out := shuffleAudit{Deals: n}
	var pos [poker.DeckSize]int64
	for _, p := range parts {
		for i, v := range p.cats {
			out.Counts[i] += v
		}
		for i, v := range p.pos {
			pos[i] += v
		}
	}
	const totalSeven = 133784560.0
	for i, c := range sevenCardCounts {
		out.Expected[i] = float64(c) / totalSeven * float64(n)
	}
	for i, c := range out.Counts {
		if e := out.Expected[i]; e > 0 {
			d := float64(c) - e
			out.CategoryX2 += d * d / e
		}
	}
	out.CategoryP = chiSquareP(out.CategoryX2, 8)
	exp := float64(n) * 7 / float64(poker.DeckSize)
	for _, c := range pos {
		d := float64(c) - exp
		out.PositionX2 += d * d / exp
	}
	out.PositionP = chiSquareP(out.PositionX2, poker.DeckSize-1)
	// A fair shuffle fails this bar once in a thousand runs by chance.
	out.OK = out.CategoryP > 0.001 && out.PositionP > 0.001
	return out
}

// chiSquareP returns the probability that a chi-square statistic of at least
// x arises by chance with df degrees of freedom.
func chiSquareP(x float64, df int) float64 {
	if df <= 0 || x < 0 {
		return math.NaN()
	}
	return gammaQ(float64(df)/2, x/2)
}

// gammaQ is the regularized upper incomplete gamma function Q(a, x), by the
// series for small x and the continued fraction otherwise.
func gammaQ(a, x float64) float64 {
	switch {
	case a <= 0 || x < 0:
		return math.NaN()
	case x == 0:
		return 1
	case x < a+1:
		return 1 - gammaP(a, x)
	}
	const eps, tiny = 1e-15, 1e-300
	lg, _ := math.Lgamma(a)
	b := x + 1 - a
	c := 1 / tiny
	d := 1 / b
	h := d
	for i := 1; i < 500; i++ {
		an := -float64(i) * (float64(i) - a)
		b += 2
		d = an*d + b
		if math.Abs(d) < tiny {
			d = tiny
		}
		c = b + an/c
		if math.Abs(c) < tiny {
			c = tiny
		}
		d = 1 / d
		del := d * c
		h *= del
		if math.Abs(del-1) < eps {
			break
		}
	}
	return math.Exp(-x+a*math.Log(x)-lg) * h
}

// gammaP is the regularized lower incomplete gamma function P(a, x).
func gammaP(a, x float64) float64 {
	lg, _ := math.Lgamma(a)
	ap, sum, del := a, 1/a, 1/a
	for n := 0; n < 500; n++ {
		ap++
		del *= x / ap
		sum += del
		if math.Abs(del) < math.Abs(sum)*1e-15 {
			break
		}
	}
	return sum * math.Exp(-x+a*math.Log(x)-lg)
}
