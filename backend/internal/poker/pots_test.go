package poker

import (
	"reflect"
	"testing"
)

func TestBuildPots(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name    string
		players []potPlayer
		want    []Pot
	}{
		{"nothing contributed", []potPlayer{{seat: 0}, {seat: 1}}, nil},
		{"single pot", []potPlayer{{0, 100, false, false}, {1, 100, false, false}}, []Pot{{200, []int{0, 1}}}},
		{"one all-in short", []potPlayer{{0, 100, false, true}, {1, 300, false, false}, {2, 300, false, false}},
			[]Pot{{300, []int{0, 1, 2}}, {400, []int{1, 2}}}},
		{"three all-ins ascending", []potPlayer{{0, 50, false, true}, {1, 100, false, true}, {2, 200, false, true}, {3, 200, false, false}},
			[]Pot{{200, []int{0, 1, 2, 3}}, {150, []int{1, 2, 3}}, {200, []int{2, 3}}}},
		{"equal all-ins dedupe", []potPlayer{{0, 100, false, true}, {1, 100, false, true}, {2, 100, false, false}},
			[]Pot{{300, []int{0, 1, 2}}}},
		{"folded contributor never eligible", []potPlayer{{0, 100, true, false}, {1, 50, false, true}, {2, 100, false, false}},
			[]Pot{{150, []int{1, 2}}, {100, []int{2}}}},
		{"folded excess merges into last pot", []potPlayer{{0, 300, true, false}, {1, 100, false, true}, {2, 100, false, false}},
			[]Pot{{500, []int{1, 2}}}},
		{"four all-ins with folder", []potPlayer{{0, 10, false, true}, {1, 20, false, true}, {2, 30, false, true}, {3, 40, false, true}, {4, 25, true, false}},
			[]Pot{{50, []int{0, 1, 2, 3}}, {40, []int{1, 2, 3}}, {25, []int{2, 3}}, {10, []int{3}}}},
		{"zero-stack all-in ignored", []potPlayer{{0, 0, false, true}, {1, 100, false, false}, {2, 100, false, false}},
			[]Pot{{200, []int{1, 2}}}},
		// A dead blind is never returned, so a player who folds can end up
		// having contributed more than anyone still in the hand. Those chips
		// are dead money for the contenders, not a pot of their own.
		{"folded player contributed the most", []potPlayer{{0, 200, true, false}, {1, 140, false, false}, {2, 140, false, false}},
			[]Pot{{480, []int{1, 2}}}},
		{"folded player above the only all-in level", []potPlayer{{0, 500, true, false}, {1, 60, false, true}, {2, 200, false, false}, {3, 200, false, false}},
			[]Pot{{240, []int{1, 2, 3}}, {720, []int{2, 3}}}},
		{"only folded players contributed", []potPlayer{{0, 90, true, false}, {1, 0, false, false}, {2, 0, false, false}},
			[]Pot{{90, []int{1, 2}}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got := buildPots(tc.players)
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
			var sum, want int64
			for _, p := range got {
				sum += p.Amount
			}
			for _, p := range tc.players {
				want += p.total
			}
			if sum != want {
				t.Fatalf("pots hold %d chips, contributions were %d", sum, want)
			}
		})
	}
}
