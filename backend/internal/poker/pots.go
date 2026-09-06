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
	var maxLive, contributed int64
	for _, p := range players {
		contributed += p.total
		if p.folded {
			continue
		}
		if p.total > maxLive {
			maxLive = p.total
		}
		if p.allIn && p.total > 0 {
			levels = append(levels, p.total)
		}
	}
	if contributed == 0 {
		return nil
	}
	sort.Slice(levels, func(i, j int) bool { return levels[i] < levels[j] })
	// Dedupe and cap at the largest contribution still in the hand: a player
	// who folded may have put in more (a dead blind or an ante is never
	// returned), and that excess joins the last pot below.
	uniq := levels[:0]
	for i, l := range levels {
		if i == 0 || l != levels[i-1] {
			uniq = append(uniq, l)
		}
	}
	levels = uniq
	if len(levels) == 0 || levels[len(levels)-1] < maxLive {
		levels = append(levels, maxLive)
	}

	var pots []Pot
	var prev, distributed int64
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
		pots = append(pots, Pot{Amount: amount, Eligible: eligible})
		distributed += amount
	}
	// Chips no one left in the hand could match are dead money and go to the
	// contenders of the last pot.
	if rest := contributed - distributed; rest > 0 {
		if len(pots) == 0 {
			var eligible []int
			for _, p := range players {
				if !p.folded {
					eligible = append(eligible, p.seat)
				}
			}
			sort.Ints(eligible)
			return []Pot{{Amount: rest, Eligible: eligible}}
		}
		pots[len(pots)-1].Amount += rest
	}
	return pots
}
