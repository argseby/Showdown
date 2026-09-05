package table

import (
	"errors"
	"testing"
)

func TestDefaultSettingsValid(t *testing.T) {
	t.Parallel()
	if err := DefaultSettings().Validate(0); err != nil {
		t.Fatal(err)
	}
	pub := DefaultSettings().Public()
	if pub.BigBlind != 100 || pub.RequiresPassword {
		t.Fatalf("public = %+v", pub)
	}
	row := DefaultSettings().Row("t")
	if SettingsFromRow(row) != DefaultSettings() {
		t.Fatal("row round trip")
	}
	if DefaultSettings().Admin().HandDelayMs != 5000 {
		t.Fatal("admin view")
	}
}

func TestSettingsApply(t *testing.T) {
	t.Parallel()
	s := DefaultSettings()
	i := func(v int) *int { return &v }
	i64 := func(v int64) *int64 { return &v }
	str := func(v string) *string { return &v }
	b := func(v bool) *bool { return &v }

	out, changed, next, err := s.Apply(SettingsPatch{BigBlind: i64(200), SmallBlind: i64(100), MaxPlayers: i(6), Password: str("secret")}, "hash", 3)
	if err != nil {
		t.Fatal(err)
	}
	if out.BigBlind != 200 || out.SmallBlind != 100 || out.MaxPlayers != 6 || out.PasswordHash != "hash" {
		t.Fatalf("out = %+v", out)
	}
	if len(changed) != 4 || len(next) != 2 {
		t.Fatalf("changed %v next %v", changed, next)
	}

	bad := []struct {
		name  string
		patch SettingsPatch
		field string
	}{
		{"max players low", SettingsPatch{MaxPlayers: i(1)}, "max_players"},
		{"max players high", SettingsPatch{MaxPlayers: i(11)}, "max_players"},
		{"max players below seated", SettingsPatch{MaxPlayers: i(2)}, "max_players"},
		{"start money", SettingsPatch{StartMoney: i64(0)}, "start_money"},
		{"small blind", SettingsPatch{SmallBlind: i64(0)}, "small_blind"},
		{"big blind", SettingsPatch{BigBlind: i64(10)}, "big_blind"},
		{"ante", SettingsPatch{Ante: i64(-1)}, "ante"},
		{"turn time", SettingsPatch{TurnTime: i(4)}, "turn_time"},
		{"disconnected turn time", SettingsPatch{DisconnectedTurnTime: i(31)}, "disconnected_turn_time"},
		{"sit out", SettingsPatch{SitOutAfterMissedTurns: i(0)}, "sit_out_after_missed_turns"},
		{"join policy", SettingsPatch{JoinPolicy: str("sometimes")}, "join_policy"},
		{"reveal", SettingsPatch{ShowdownReveal: str("none")}, "showdown_reveal"},
		{"hand delay", SettingsPatch{HandDelayMs: i(100)}, "hand_delay_ms"},
	}
	for _, tc := range bad {
		_, _, _, err := s.Apply(tc.patch, "", 3)
		var ve *ValidationError
		if !errors.As(err, &ve) {
			t.Fatalf("%s: expected validation error, got %v", tc.name, err)
		}
		if ve.Fields[0].Field != tc.field {
			t.Fatalf("%s: field %s, want %s (%v)", tc.name, ve.Fields[0].Field, tc.field, ve.Error())
		}
	}
	out, changed, _, err = s.Apply(SettingsPatch{AllowSpectators: b(false), SpectatorChat: b(false), ChatEnabled: b(false), AllowRebuy: b(false), AutoStart: b(false), Ante: i64(5), TurnTime: i(60), DisconnectedTurnTime: i(20), SitOutAfterMissedTurns: i(3), JoinPolicy: str(JoinClosed), ShowdownReveal: str(RevealWinnersOnly), HandDelayMs: i(3000), StartMoney: i64(500)}, "", 0)
	if err != nil || len(changed) != 13 || out.AllowSpectators || out.ShowdownReveal != RevealWinnersOnly {
		t.Fatalf("bool patch: %+v %v %v", out, changed, err)
	}
}

func TestValidatePassword(t *testing.T) {
	t.Parallel()
	if ValidatePassword("") != nil || ValidatePassword("abcd") != nil {
		t.Fatal("valid passwords rejected")
	}
	if ValidatePassword("abc") == nil || ValidatePassword(string(make([]rune, 65))) == nil {
		t.Fatal("invalid passwords accepted")
	}
}

func TestNormalizeName(t *testing.T) {
	t.Parallel()
	good := map[string]string{"  Alice   B  ": "Alice B", "Bob_1": "Bob_1", "Jürgen.Ö": "Jürgen.Ö", "a-b": "a-b", "日本語": "日本語", "a\tb": "a b"}
	for in, want := range good {
		got, err := NormalizeName(in)
		if err != nil || got != want {
			t.Errorf("NormalizeName(%q) = %q, %v; want %q", in, got, err, want)
		}
	}
	for _, in := range []string{"", "   ", "Al!ce", "x\x00", "System", "ADMIN", "dealer", "abcdefghijklmnopqrstu", "a/b"} {
		if _, err := NormalizeName(in); !errors.Is(err, ErrInvalidName) {
			t.Errorf("NormalizeName(%q) accepted", in)
		}
	}
	if NameKey(" Alice ") != "alice" {
		t.Fatal("NameKey")
	}
}
