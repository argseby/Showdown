package poker

import "sort"

// Notes read a board out loud: what it makes possible for anybody holding
// the right two cards, and what the hand looking at it can still become.
// They are the half of "how am I doing" that a percentage cannot carry —
// 86% means nothing until you know it is 86% against a flush that is one
// card away.
//
// Everything here is derived from the shared board and the reader's own two
// cards, so a note tells its reader nothing they could not work out by
// looking. They are deliberately written as observations rather than
// instructions: a board that threatens a flush is a board that is hard to
// call on, which is exactly when a bet without the flush works. Telling a
// player only about the danger would teach them to fold and never to bet,
// which is not the game.

// NoteID names a note; the client has the words for it in the player's
// language, which is why these are ids and not sentences.
type NoteID string

// The notes, in the order a player should hear them: what they have first,
// then what is still coming, then what the board gives everyone else.
const (
	// NoteNuts: no two cards in the remaining deck beat this hand right
	// now. It cannot last past another card, and says so.
	NoteNuts NoteID = "nuts"
	// NoteFlushDraw: one more card of the suit makes a flush.
	NoteFlushDraw NoteID = "flush_draw"
	// NoteOpenEnded: four to a straight, open at both ends.
	NoteOpenEnded NoteID = "open_ended"
	// NoteGutshot: four to a straight with the hole in the middle.
	NoteGutshot NoteID = "gutshot"
	// NoteFlushPossible: three or more of a suit lie on the board, so
	// anyone with two of that suit already has a flush.
	NoteFlushPossible NoteID = "flush_possible"
	// NoteFlushLanded: the board alone holds a flush; everybody has one
	// and the highest card of the suit wins it.
	NoteFlushLanded NoteID = "flush_landed"
	// NoteStraightPossible: the board's ranks sit close enough together
	// that two cards complete a straight.
	NoteStraightPossible NoteID = "straight_possible"
	// NoteBoardPaired: a pair on the board, so a full house is in reach
	// for anyone holding one of its ranks.
	NoteBoardPaired NoteID = "board_paired"
	// NoteOvercard: the board holds a card higher than the pair being
	// held, so a single opponent card beats it.
	NoteOvercard NoteID = "overcard"
	// NoteScaryForEveryone: the board threatens more than this hand holds
	// — which is the same board the opponents have to call on.
	NoteScaryForEveryone NoteID = "scary_for_everyone"
)

// Note is one observation, with the card rank or suit it is about where
// naming it makes the note concrete ("three hearts", "a pair of sevens").
type Note struct {
	ID   NoteID
	Rank Rank
	Suit Suit
	// HasRank and HasSuit say which of the two above mean anything.
	HasRank bool
	HasSuit bool
}

// MaxNotes is what a table can show without becoming a spreadsheet. Read
// returns at most this many, most useful first.
const MaxNotes = 3

// Read looks at a hand on a board and says what is worth noticing. It
// returns nothing before the flop, where there is no board to read.
func Read(v Variant, hole [2]Card, board []Card) []Note {
	if len(board) < 3 {
		return nil
	}
	all := append([]Card{hole[0], hole[1]}, board...)
	toCome := 5 - len(board)

	var mine, theirs []Note

	// What the board holds for everyone.
	boardSuits := countSuits(board)
	suited := -1
	for s, n := range boardSuits {
		if n >= 3 {
			suited = s
		}
	}
	if suited >= 0 {
		id := NoteFlushPossible
		if boardSuits[suited] >= 5 {
			id = NoteFlushLanded
		}
		theirs = append(theirs, Note{ID: id, Suit: Suit(suited), HasSuit: true})
	}
	if straightOnBoard(board) {
		theirs = append(theirs, Note{ID: NoteStraightPossible})
	}
	if r, ok := pairedBoard(board); ok {
		theirs = append(theirs, Note{ID: NoteBoardPaired, Rank: r, HasRank: true})
	}

	// What this hand is, and what it can still become.
	value := Evaluate(all)
	if isNuts(v, value, board) {
		mine = append(mine, Note{ID: NoteNuts})
	}
	if toCome > 0 && value.Category < Flush {
		if s, ok := flushDraw(all); ok {
			mine = append(mine, Note{ID: NoteFlushDraw, Suit: s, HasSuit: true})
		}
	}
	if toCome > 0 && value.Category < Straight {
		switch straightDraw(v, all) {
		case drawOpen:
			mine = append(mine, Note{ID: NoteOpenEnded})
		case drawGut:
			mine = append(mine, Note{ID: NoteGutshot})
		}
	}
	if value.Category == OnePair {
		if r, ok := overcard(value, board); ok {
			mine = append(mine, Note{ID: NoteOvercard, Rank: r, HasRank: true})
		}
	}

	// A board that threatens something this hand has not got is a board
	// everyone else has to call on too. Said once, and only when there is
	// something to say it about.
	if len(theirs) > 0 && value.Category < Straight && len(mine) == 0 {
		theirs = append(theirs, Note{ID: NoteScaryForEveryone})
	}

	// A fresh slice: mine and theirs are built separately and neither
	// should end up sharing the other's backing array.
	out := make([]Note, 0, len(mine)+len(theirs))
	out = append(out, mine...)
	out = append(out, theirs...)
	if len(out) > MaxNotes {
		out = out[:MaxNotes]
	}
	return out
}

func countSuits(cards []Card) [4]int {
	var n [4]int
	for _, c := range cards {
		n[c.Suit()]++
	}
	return n
}

// pairedBoard reports the highest rank that appears more than once on the
// board.
func pairedBoard(board []Card) (Rank, bool) {
	var seen [13]int
	for _, c := range board {
		seen[c.Rank()]++
	}
	for r := Ace; ; r-- {
		if seen[r] > 1 {
			return r, true
		}
		if r == Two {
			return 0, false
		}
	}
}

// straightOnBoard reports whether three of the board's distinct ranks sit
// within a five-rank window, which is what two cards in a hand need to
// complete a straight. The wheel counts the ace as low as well.
func straightOnBoard(board []Card) bool {
	ranks := distinctRanks(board)
	for _, set := range withWheel(ranks) {
		for i := 0; i+2 < len(set); i++ {
			if set[i+2]-set[i] <= 4 {
				return true
			}
		}
	}
	return false
}

// flushDraw reports a suit the hand holds exactly four of — one card short.
func flushDraw(all []Card) (Suit, bool) {
	n := countSuits(all)
	for s, count := range n {
		if count == 4 {
			return Suit(s), true
		}
	}
	return 0, false
}

type drawKind int

const (
	drawNone drawKind = iota
	drawGut
	drawOpen
)

// straightDraw asks what one more card would do: a draw is open-ended when
// two different ranks complete it and a gutshot when only one does. The
// deck of the variant decides which ranks exist at all.
func straightDraw(v Variant, all []Card) drawKind {
	have := map[Rank]bool{}
	for _, c := range all {
		have[c.Rank()] = true
	}
	// Ranks, not cards: four nines in the deck are one way to fill a
	// straight, not four, and counting cards would read every gutshot as
	// open-ended.
	ranks := map[Rank]bool{}
	for _, c := range v.Deck() {
		ranks[c.Rank()] = true
	}
	outs := 0
	for r := range ranks {
		if have[r] {
			continue
		}
		have[r] = true
		if straightFromRanks(have) {
			outs++
		}
		delete(have, r)
	}
	switch {
	case outs >= 2:
		return drawOpen
	case outs == 1:
		return drawGut
	default:
		return drawNone
	}
}

// straightFromRanks reports five ranks in a row among those held.
func straightFromRanks(have map[Rank]bool) bool {
	for _, set := range withWheel(sortedRanks(have)) {
		run := 1
		for i := 1; i < len(set); i++ {
			if set[i] == set[i-1]+1 {
				run++
				if run >= 5 {
					return true
				}
			} else {
				run = 1
			}
		}
	}
	return false
}

// isNuts reports that no two cards left in the deck make a better hand on
// this board.
func isNuts(v Variant, mine HandValue, board []Card) bool {
	used := make([]bool, DeckSize)
	for _, c := range board {
		used[c] = true
	}
	for _, c := range mine.Best {
		used[c] = true
	}
	var rest []Card
	for _, c := range v.Deck() {
		if !used[c] {
			rest = append(rest, c)
		}
	}
	hand := make([]Card, 0, 7)
	for i := range rest {
		for j := i + 1; j < len(rest); j++ {
			hand = append(hand[:0], rest[i], rest[j])
			hand = append(hand, board...)
			if Evaluate(hand).Compare(mine) > 0 {
				return false
			}
		}
	}
	return true
}

// overcard reports a board card that outranks the pair being held, which
// is what turns top pair into second pair the moment somebody holds it.
func overcard(value HandValue, board []Card) (Rank, bool) {
	pair := value.ranks()[0]
	best, found := Two, false
	for _, c := range board {
		if c.Rank() > pair && (!found || c.Rank() > best) {
			best, found = c.Rank(), true
		}
	}
	return best, found
}

func distinctRanks(cards []Card) []int {
	seen := map[Rank]bool{}
	for _, c := range cards {
		seen[c.Rank()] = true
	}
	return sortedRanks(seen)
}

func sortedRanks(seen map[Rank]bool) []int {
	out := make([]int, 0, len(seen))
	for r := range seen {
		out = append(out, int(r))
	}
	sort.Ints(out)
	return out
}

// withWheel returns the ranks as they are, and — when an ace is among them
// — again with the ace counted below the two, so A-2-3-4-5 reads as a run.
func withWheel(ranks []int) [][]int {
	sets := [][]int{ranks}
	if len(ranks) > 0 && ranks[len(ranks)-1] == int(Ace) {
		low := append([]int{-1}, ranks[:len(ranks)-1]...)
		sets = append(sets, low)
	}
	return sets
}
