package table

import (
	"errors"
	"strings"
	"testing"

	"showdown/internal/poker"
)

func TestRoyalVariantSettings(t *testing.T) {
	t.Parallel()
	s := DefaultSettings()
	if s.Variant != VariantHoldem || s.PokerVariant() != poker.Holdem || s.Public().Variant != VariantHoldem {
		t.Fatalf("default variant = %q", s.Variant)
	}
	str := func(v string) *string { return &v }
	i := func(v int) *int { return &v }

	// Royal needs the seat cap; it applies from the next hand.
	out, changed, next, err := s.Apply(SettingsPatch{Variant: str(VariantRoyal), MaxPlayers: i(RoyalMaxPlayers)}, "", 0)
	if err != nil {
		t.Fatal(err)
	}
	if out.Variant != VariantRoyal || out.PokerVariant() != poker.Royal || len(changed) != 2 || len(next) != 1 || next[0] != "variant" {
		t.Fatalf("out = %+v changed = %v next = %v", out, changed, next)
	}
	if out.Public().Variant != VariantRoyal || out.Admin().Variant != VariantRoyal {
		t.Fatal("variant missing from the public or admin view")
	}

	// Too many seats for a 20-card deck.
	var ve *ValidationError
	if _, _, _, err := s.Apply(SettingsPatch{Variant: str(VariantRoyal)}, "", 0); !errors.As(err, &ve) || ve.Fields[0].Field != "max_players" {
		t.Fatalf("royal with 9 seats: %v", err)
	}
	if _, _, _, err := s.Apply(SettingsPatch{Variant: str("omaha")}, "", 0); !errors.As(err, &ve) || ve.Fields[0].Field != "variant" {
		t.Fatalf("unknown variant: %v", err)
	}

	// Persistence round trip; rows from before the setting read as hold'em.
	if got := SettingsFromRow(out.Row("t")); got != out {
		t.Fatalf("row round trip: %+v", got)
	}
	row := s.Row("t")
	row.Variant = ""
	if got := SettingsFromRow(row); got.Variant != VariantHoldem {
		t.Fatalf("legacy row variant = %q", got.Variant)
	}
}

func TestRoyalTableDealsOnlyTenToAce(t *testing.T) {
	t.Parallel()
	s := testSettings()
	s.Variant = VariantRoyal
	s.MaxPlayers = RoyalMaxPlayers
	tbl := newTestTableShuffled(t, s, poker.SecureShuffle)
	_, ca := join(t, tbl, "Alice")
	join(t, tbl, "Bob")
	waitFor(t, "hand to start", func() bool { return handRunning(tbl) })
	snap := ca.lastSnapshot(t)
	if snap.Table.Settings.Variant != VariantRoyal {
		t.Fatalf("snapshot variant = %q", snap.Table.Settings.Variant)
	}
	if tbl.Info().Variant != VariantRoyal {
		t.Fatal("info variant")
	}
	var cards []string
	for _, sv := range snap.Seats {
		if sv.Player != nil {
			cards = append(cards, sv.Player.HoleCards...)
		}
	}
	if len(cards) != 2 {
		t.Fatalf("Alice's cards = %v", cards)
	}
	for _, c := range cards {
		if !strings.ContainsRune("TJQKA", rune(c[0])) {
			t.Fatalf("%s was dealt in Royal Hold'em", c)
		}
	}
}
