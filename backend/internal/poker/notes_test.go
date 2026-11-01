package poker

import "testing"

func mustCards(t *testing.T, s ...string) []Card {
	t.Helper()
	out := make([]Card, 0, len(s))
	for _, one := range s {
		c, err := ParseCard(one)
		if err != nil {
			t.Fatalf("parse %q: %v", one, err)
		}
		out = append(out, c)
	}
	return out
}

func read(t *testing.T, hole []string, board []string) []NoteID {
	t.Helper()
	h := mustCards(t, hole...)
	notes := Read(Holdem, [2]Card{h[0], h[1]}, mustCards(t, board...))
	ids := make([]NoteID, 0, len(notes))
	for _, n := range notes {
		ids = append(ids, n.ID)
	}
	return ids
}

func has(ids []NoteID, want NoteID) bool {
	for _, id := range ids {
		if id == want {
			return true
		}
	}
	return false
}

func TestReadNamesWhatTheBoardThreatens(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name       string
		hole       []string
		board      []string
		want, deny []NoteID
	}{
		{
			name: "three of a suit puts a flush on the table",
			hole: []string{"Ac", "Kd"}, board: []string{"7h", "2h", "9h"},
			want: []NoteID{NoteFlushPossible},
		},
		{
			// Two hearts on the board cannot make anyone else a flush —
			// they would need three of their own — so this is the
			// reader's draw and nobody's threat.
			name:  "four to a flush is a draw, not a warning",
			hole:  []string{"Ah", "Kh"},
			board: []string{"7h", "2h", "9c"},
			want:  []NoteID{NoteFlushDraw},
			deny:  []NoteID{NoteFlushPossible},
		},
		{
			name: "a board within five ranks lets two cards make a straight",
			hole: []string{"Ac", "Kd"}, board: []string{"7h", "8c", "9d"},
			want: []NoteID{NoteStraightPossible},
		},
		{
			name: "open at both ends",
			hole: []string{"Th", "9c"}, board: []string{"8d", "7s", "2c"},
			want: []NoteID{NoteOpenEnded},
			deny: []NoteID{NoteGutshot},
		},
		{
			name: "a hole in the middle is a gutshot",
			hole: []string{"Th", "8c"}, board: []string{"7d", "6s", "2c"},
			want: []NoteID{NoteGutshot},
			deny: []NoteID{NoteOpenEnded},
		},
		{
			name: "a paired board puts a full house in reach",
			hole: []string{"Ac", "Kd"}, board: []string{"7h", "7c", "2d"},
			want: []NoteID{NoteBoardPaired},
		},
		{
			name: "a pair under a board card is second best to one card",
			hole: []string{"9c", "9d"}, board: []string{"Ah", "7c", "2d"},
			want: []NoteID{NoteOvercard},
		},
		{
			name: "nothing can beat the top straight flush",
			hole: []string{"Ah", "Kh"}, board: []string{"Qh", "Jh", "Th"},
			want: []NoteID{NoteNuts},
		},
		{
			name: "before the flop there is no board to read",
			hole: []string{"Ah", "Kh"}, board: nil,
		},
		{
			name: "a scary board is scary for everyone, said once",
			hole: []string{"6c", "3d"}, board: []string{"Ah", "Kh", "9h"},
			want: []NoteID{NoteFlushPossible, NoteScaryForEveryone},
		},
		{
			name: "holding the flush is not a warning about it",
			hole: []string{"Ah", "2h"}, board: []string{"Kh", "9h", "4h"},
			deny: []NoteID{NoteScaryForEveryone},
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			ids := read(t, tc.hole, tc.board)
			for _, want := range tc.want {
				if !has(ids, want) {
					t.Errorf("notes %v, want %q among them", ids, want)
				}
			}
			for _, deny := range tc.deny {
				if has(ids, deny) {
					t.Errorf("notes %v must not carry %q", ids, deny)
				}
			}
			if len(tc.board) == 0 && len(ids) != 0 {
				t.Errorf("notes %v before the flop, want none", ids)
			}
			if len(ids) > MaxNotes {
				t.Errorf("%d notes, at most %d fit on a table", len(ids), MaxNotes)
			}
		})
	}
}

// The reader's own hand comes before the board's threats: what you have
// answers the question you asked.
func TestReadPutsYourOwnHandFirst(t *testing.T) {
	t.Parallel()
	ids := read(t, []string{"Ah", "Kh"}, []string{"7h", "2h", "9c"})
	if len(ids) == 0 || ids[0] != NoteFlushDraw {
		t.Errorf("notes %v, want the draw first", ids)
	}
}
