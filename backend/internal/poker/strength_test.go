package poker

import "testing"

func TestStrength(t *testing.T) {
	t.Parallel()
	card := func(s string) Card {
		c, err := ParseCard(s)
		if err != nil {
			t.Fatal(err)
		}
		return c
	}
	aces := [2]Card{card("As"), card("Ah")}
	junk := [2]Card{card("7c"), card("2d")}
	// Well-known preflop numbers, within sampling noise.
	if eq := Strength(Holdem, nil, aces, 1, 6000, 1); eq < 0.8 || eq > 0.9 {
		t.Fatalf("AA heads-up = %.3f", eq)
	}
	if eq := Strength(Holdem, nil, junk, 1, 6000, 1); eq < 0.3 || eq > 0.4 {
		t.Fatalf("72o heads-up = %.3f", eq)
	}
	// More opponents, less equity.
	one := Strength(Holdem, nil, aces, 1, 3000, 2)
	five := Strength(Holdem, nil, aces, 5, 3000, 2)
	if five >= one || five < 0.4 {
		t.Fatalf("AA vs 1 = %.3f, vs 5 = %.3f", one, five)
	}
	// A complete board with the nuts is a lock.
	board := []Card{card("Ad"), card("Kd"), card("Qd"), card("2c"), card("7s")}
	royal := [2]Card{card("Jd"), card("Td")}
	if eq := Strength(Holdem, board, royal, 3, 500, 3); eq != 1 {
		t.Fatalf("royal flush on the river = %.3f", eq)
	}
	// Degenerate inputs do not panic.
	if eq := Strength(Holdem, board, royal, 0, 0, 4); eq != 1 {
		t.Fatalf("clamped inputs = %.3f", eq)
	}
}
