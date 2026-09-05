package poker

import "sort"

// Pot is one (side) pot: its size and the seats that can win it, ascending.
type Pot struct {
	Amount   int64
	Eligible []int
}

type potPlayer struct {
	seat   int
	total  int64 // chips contributed to completed streets (incl. antes)
	folded bool
	allIn  bool
}

// buildPots computes main and side pots from total contributions using
// contribution levels (docs/rules.md §7.6). Folded players' chips count
// towards the amounts but never towards eligibility.
func buildPots(players []potPlayer) []Pot {
	var levels []int64
	var maxTotal int64
	for _, p := range players {
		if p.total > maxTotal {
			maxTotal = p.total
		}
		if p.allIn && p.total > 0 {
			levels = append(levels, p.total)
		}
	}
	if maxTotal == 0 {
		return nil
	}
	sort.Slice(levels, func(i, j int) bool { return levels[i] < levels[j] })
	// Dedupe and append the maximum contribution as the final level.
	uniq := levels[:0]
	for i, l := range levels {
		if i == 0 || l != levels[i-1] {
			uniq = append(uniq, l)
		}
	}
	levels = uniq
	if len(levels) == 0 || levels[len(levels)-1] < maxTotal {
		levels = append(levels, maxTotal)
	}

	var pots []Pot
	var prev int64
	for _, level := range levels {
		var amount int64
		var eligible []int
		for _, p := range players {
			amount += min(p.total, level) - min(p.total, prev)
			if !p.folded && p.total >= level {
				eligible = append(eligible, p.seat)
			}
		}
		prev = level
		if amount == 0 {
			continue
		}
		sort.Ints(eligible)
		if len(eligible) == 0 && len(pots) > 0 {
			// Only folded players reached this level (their excess chips);
			// the chips belong to the previous pot's contenders.
			pots[len(pots)-1].Amount += amount
			continue
		}
		pots = append(pots, Pot{Amount: amount, Eligible: eligible})
	}
	return pots
}
