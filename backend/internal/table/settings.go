// Package table implements the table actor: seats, settings, timers, the
// current hand, connected clients, personalized snapshots and persistence
// hooks. All mutations run on the table's own goroutine.
package table

import (
	"encoding/json"
	"fmt"

	"showdown/internal/protocol"
	"showdown/internal/store"
)

// Join policies.
const (
	JoinAlways      = "always"
	JoinBeforeStart = "before_start"
	JoinClosed      = "closed"
)

// Reveal policies.
const (
	RevealAll         = "all"
	RevealWinnersOnly = "winners_only"
	// RevealInOrder: hands are shown one at a time in showdown order and
	// beaten hands are mucked (owner decision 2026-09-05; default).
	RevealInOrder = "in_order"
)

// Settings are the live table settings (docs §5.2). PasswordHash is the
// bcrypt hash or "" when no password is required.
type Settings struct {
	PasswordHash           string
	MaxPlayers             int
	StartMoney             int64
	SmallBlind             int64
	BigBlind               int64
	Ante                   int64
	TurnTime               int
	DisconnectedTurnTime   int
	SitOutAfterMissedTurns int
	JoinPolicy             string
	AllowSpectators        bool
	SpectatorChat          bool
	ChatEnabled            bool
	AllowRebuy             bool
	ShowdownReveal         string
	AutoStart              bool
	HandDelayMs            int
	// AllowRabbitHunt lets players see the rest of the board after a hand
	// ended before the river.
	AllowRabbitHunt bool
	// BlindsUpMinutes raises the blinds every N minutes (0 = manual only);
	// BlindsUpPercent is the increase (100 = double).
	BlindsUpMinutes int
	BlindsUpPercent int
}

// DefaultSettings returns the §5.2 defaults.
func DefaultSettings() Settings {
	return Settings{
		MaxPlayers: 9, StartMoney: 10000, SmallBlind: 50, BigBlind: 100, Ante: 0,
		TurnTime: 30, DisconnectedTurnTime: 10, SitOutAfterMissedTurns: 2,
		JoinPolicy: JoinAlways, AllowSpectators: true, SpectatorChat: true, ChatEnabled: true,
		AllowRebuy: true, ShowdownReveal: RevealInOrder, AutoStart: true, HandDelayMs: 5000,
		AllowRabbitHunt: true, BlindsUpMinutes: 0, BlindsUpPercent: 100,
	}
}

// Public converts to the client-visible subset.
func (s Settings) Public() protocol.PublicSettings {
	return protocol.PublicSettings{
		SmallBlind: s.SmallBlind, BigBlind: s.BigBlind, Ante: s.Ante, TurnTime: s.TurnTime,
		MaxPlayers: s.MaxPlayers, StartMoney: s.StartMoney, JoinPolicy: s.JoinPolicy,
		AllowRebuy: s.AllowRebuy, ShowdownReveal: s.ShowdownReveal, ChatEnabled: s.ChatEnabled,
		SpectatorChat: s.SpectatorChat, RequiresPassword: s.PasswordHash != "",
		AllowRabbitHunt: s.AllowRabbitHunt, BlindsUpMinutes: s.BlindsUpMinutes, BlindsUpPercent: s.BlindsUpPercent,
	}
}

// Row converts to the persistence row.
func (s Settings) Row(tableID string) store.SettingsRow {
	return store.SettingsRow{
		TableID: tableID, PasswordHash: s.PasswordHash, MaxPlayers: s.MaxPlayers, StartMoney: s.StartMoney,
		SmallBlind: s.SmallBlind, BigBlind: s.BigBlind, Ante: s.Ante, TurnTime: s.TurnTime,
		DisconnectedTurnTime: s.DisconnectedTurnTime, SitOutAfterMissedTurns: s.SitOutAfterMissedTurns,
		JoinPolicy: s.JoinPolicy, AllowSpectators: s.AllowSpectators, SpectatorChat: s.SpectatorChat,
		ChatEnabled: s.ChatEnabled, AllowRebuy: s.AllowRebuy, ShowdownReveal: s.ShowdownReveal,
		AutoStart: s.AutoStart, HandDelayMs: s.HandDelayMs,
		AllowRabbitHunt: s.AllowRabbitHunt, BlindsUpMinutes: s.BlindsUpMinutes, BlindsUpPercent: s.BlindsUpPercent,
	}
}

// SettingsFromRow converts a persistence row.
func SettingsFromRow(r store.SettingsRow) Settings {
	return Settings{
		PasswordHash: r.PasswordHash, MaxPlayers: r.MaxPlayers, StartMoney: r.StartMoney,
		SmallBlind: r.SmallBlind, BigBlind: r.BigBlind, Ante: r.Ante, TurnTime: r.TurnTime,
		DisconnectedTurnTime: r.DisconnectedTurnTime, SitOutAfterMissedTurns: r.SitOutAfterMissedTurns,
		JoinPolicy: r.JoinPolicy, AllowSpectators: r.AllowSpectators, SpectatorChat: r.SpectatorChat,
		ChatEnabled: r.ChatEnabled, AllowRebuy: r.AllowRebuy, ShowdownReveal: r.ShowdownReveal,
		AutoStart: r.AutoStart, HandDelayMs: r.HandDelayMs,
		AllowRabbitHunt: r.AllowRabbitHunt, BlindsUpMinutes: r.BlindsUpMinutes, BlindsUpPercent: r.BlindsUpPercent,
	}
}

// AdminView is the full settings object shown to admins (password is only
// reported as a flag).
type AdminView struct {
	RequiresPassword       bool   `json:"requires_password"`
	MaxPlayers             int    `json:"max_players"`
	StartMoney             int64  `json:"start_money"`
	SmallBlind             int64  `json:"small_blind"`
	BigBlind               int64  `json:"big_blind"`
	Ante                   int64  `json:"ante"`
	TurnTime               int    `json:"turn_time"`
	DisconnectedTurnTime   int    `json:"disconnected_turn_time"`
	SitOutAfterMissedTurns int    `json:"sit_out_after_missed_turns"`
	JoinPolicy             string `json:"join_policy"`
	AllowSpectators        bool   `json:"allow_spectators"`
	SpectatorChat          bool   `json:"spectator_chat"`
	ChatEnabled            bool   `json:"chat_enabled"`
	AllowRebuy             bool   `json:"allow_rebuy"`
	ShowdownReveal         string `json:"showdown_reveal"`
	AutoStart              bool   `json:"auto_start"`
	HandDelayMs            int    `json:"hand_delay_ms"`
	AllowRabbitHunt        bool   `json:"allow_rabbit_hunt"`
	BlindsUpMinutes        int    `json:"blinds_up_minutes"`
	BlindsUpPercent        int    `json:"blinds_up_percent"`
}

// Admin converts to the admin view.
func (s Settings) Admin() AdminView {
	return AdminView{
		RequiresPassword: s.PasswordHash != "", MaxPlayers: s.MaxPlayers, StartMoney: s.StartMoney,
		SmallBlind: s.SmallBlind, BigBlind: s.BigBlind, Ante: s.Ante, TurnTime: s.TurnTime,
		DisconnectedTurnTime: s.DisconnectedTurnTime, SitOutAfterMissedTurns: s.SitOutAfterMissedTurns,
		JoinPolicy: s.JoinPolicy, AllowSpectators: s.AllowSpectators, SpectatorChat: s.SpectatorChat,
		ChatEnabled: s.ChatEnabled, AllowRebuy: s.AllowRebuy, ShowdownReveal: s.ShowdownReveal,
		AutoStart: s.AutoStart, HandDelayMs: s.HandDelayMs,
		AllowRabbitHunt: s.AllowRabbitHunt, BlindsUpMinutes: s.BlindsUpMinutes, BlindsUpPercent: s.BlindsUpPercent,
	}
}

// SettingsPatch is a partial update. Pointer fields that are nil are left
// unchanged. Password is the plain text (empty string clears it); the caller
// hashes it before applying.
type SettingsPatch struct {
	Password               *string `json:"password"`
	MaxPlayers             *int    `json:"max_players"`
	StartMoney             *int64  `json:"start_money"`
	SmallBlind             *int64  `json:"small_blind"`
	BigBlind               *int64  `json:"big_blind"`
	Ante                   *int64  `json:"ante"`
	TurnTime               *int    `json:"turn_time"`
	DisconnectedTurnTime   *int    `json:"disconnected_turn_time"`
	SitOutAfterMissedTurns *int    `json:"sit_out_after_missed_turns"`
	JoinPolicy             *string `json:"join_policy"`
	AllowSpectators        *bool   `json:"allow_spectators"`
	SpectatorChat          *bool   `json:"spectator_chat"`
	ChatEnabled            *bool   `json:"chat_enabled"`
	AllowRebuy             *bool   `json:"allow_rebuy"`
	ShowdownReveal         *string `json:"showdown_reveal"`
	AutoStart              *bool   `json:"auto_start"`
	HandDelayMs            *int    `json:"hand_delay_ms"`
	AllowRabbitHunt        *bool   `json:"allow_rabbit_hunt"`
	BlindsUpMinutes        *int    `json:"blinds_up_minutes"`
	BlindsUpPercent        *int    `json:"blinds_up_percent"`
}

// FieldError is a per-field validation problem.
type FieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

func (e FieldError) Error() string { return e.Field + ": " + e.Message }

// ValidationError collects per-field problems.
type ValidationError struct {
	Fields []FieldError `json:"fields"`
}

func (e *ValidationError) Error() string {
	b, _ := json.Marshal(e.Fields)
	return "validation failed: " + string(b)
}

func (e *ValidationError) add(field, msg string) {
	e.Fields = append(e.Fields, FieldError{Field: field, Message: msg})
}

// appliesNextHand lists the fields whose change only takes effect at the
// next hand (docs §5.2).
var appliesNextHand = map[string]bool{
	"small_blind": true, "big_blind": true, "ante": true, "turn_time": true,
	"disconnected_turn_time": true, "showdown_reveal": true, "hand_delay_ms": true,
}

// Apply merges the patch into s (password already hashed into passwordHash
// when p.Password != nil) and validates the result. seated is the number of
// occupied seats. It returns the changed field names and the subset that
// only applies at the next hand.
func (s Settings) Apply(p SettingsPatch, passwordHash string, seated int) (Settings, []string, []string, error) {
	out := s
	var changed []string
	set := func(name string) { changed = append(changed, name) }

	if p.Password != nil {
		out.PasswordHash = passwordHash
		set("password")
	}
	if p.MaxPlayers != nil {
		out.MaxPlayers = *p.MaxPlayers
		set("max_players")
	}
	if p.StartMoney != nil {
		out.StartMoney = *p.StartMoney
		set("start_money")
	}
	if p.SmallBlind != nil {
		out.SmallBlind = *p.SmallBlind
		set("small_blind")
	}
	if p.BigBlind != nil {
		out.BigBlind = *p.BigBlind
		set("big_blind")
	}
	if p.Ante != nil {
		out.Ante = *p.Ante
		set("ante")
	}
	if p.TurnTime != nil {
		out.TurnTime = *p.TurnTime
		set("turn_time")
	}
	if p.DisconnectedTurnTime != nil {
		out.DisconnectedTurnTime = *p.DisconnectedTurnTime
		set("disconnected_turn_time")
	}
	if p.SitOutAfterMissedTurns != nil {
		out.SitOutAfterMissedTurns = *p.SitOutAfterMissedTurns
		set("sit_out_after_missed_turns")
	}
	if p.JoinPolicy != nil {
		out.JoinPolicy = *p.JoinPolicy
		set("join_policy")
	}
	if p.AllowSpectators != nil {
		out.AllowSpectators = *p.AllowSpectators
		set("allow_spectators")
	}
	if p.SpectatorChat != nil {
		out.SpectatorChat = *p.SpectatorChat
		set("spectator_chat")
	}
	if p.ChatEnabled != nil {
		out.ChatEnabled = *p.ChatEnabled
		set("chat_enabled")
	}
	if p.AllowRebuy != nil {
		out.AllowRebuy = *p.AllowRebuy
		set("allow_rebuy")
	}
	if p.ShowdownReveal != nil {
		out.ShowdownReveal = *p.ShowdownReveal
		set("showdown_reveal")
	}
	if p.AutoStart != nil {
		out.AutoStart = *p.AutoStart
		set("auto_start")
	}
	if p.HandDelayMs != nil {
		out.HandDelayMs = *p.HandDelayMs
		set("hand_delay_ms")
	}
	if p.AllowRabbitHunt != nil {
		out.AllowRabbitHunt = *p.AllowRabbitHunt
		set("allow_rabbit_hunt")
	}
	if p.BlindsUpMinutes != nil {
		out.BlindsUpMinutes = *p.BlindsUpMinutes
		set("blinds_up_minutes")
	}
	if p.BlindsUpPercent != nil {
		out.BlindsUpPercent = *p.BlindsUpPercent
		set("blinds_up_percent")
	}

	if err := out.Validate(seated); err != nil {
		return s, nil, nil, err
	}
	var next []string
	for _, f := range changed {
		if appliesNextHand[f] {
			next = append(next, f)
		}
	}
	return out, changed, next, nil
}

// ValidatePassword checks the plain-text password rule (0 or 4–64 chars).
func ValidatePassword(pw string) error {
	if n := len([]rune(pw)); n != 0 && (n < 4 || n > 64) {
		return &ValidationError{Fields: []FieldError{{Field: "password", Message: "must be empty or 4–64 characters"}}}
	}
	return nil
}

// Validate checks every constraint of §5.2.
func (s Settings) Validate(seated int) error {
	var ve ValidationError
	if s.MaxPlayers < 2 || s.MaxPlayers > 10 {
		ve.add("max_players", "must be between 2 and 10")
	} else if s.MaxPlayers < seated {
		ve.add("max_players", fmt.Sprintf("cannot be below the %d seated players", seated))
	}
	if s.StartMoney < 1 || s.StartMoney > 1_000_000_000_000 {
		ve.add("start_money", "must be between 1 and 10^12")
	}
	if s.SmallBlind < 1 {
		ve.add("small_blind", "must be at least 1")
	}
	if s.BigBlind < s.SmallBlind {
		ve.add("big_blind", "must be at least the small blind")
	}
	if s.Ante < 0 {
		ve.add("ante", "must not be negative")
	}
	if s.TurnTime < 5 || s.TurnTime > 600 {
		ve.add("turn_time", "must be between 5 and 600 seconds")
	}
	if s.DisconnectedTurnTime < 3 || s.DisconnectedTurnTime > s.TurnTime {
		ve.add("disconnected_turn_time", "must be between 3 seconds and turn_time")
	}
	if s.SitOutAfterMissedTurns < 1 || s.SitOutAfterMissedTurns > 10 {
		ve.add("sit_out_after_missed_turns", "must be between 1 and 10")
	}
	switch s.JoinPolicy {
	case JoinAlways, JoinBeforeStart, JoinClosed:
	default:
		ve.add("join_policy", "must be always, before_start or closed")
	}
	switch s.ShowdownReveal {
	case RevealAll, RevealWinnersOnly, RevealInOrder:
	default:
		ve.add("showdown_reveal", "must be all, winners_only or in_order")
	}
	if s.HandDelayMs < 2000 || s.HandDelayMs > 15000 {
		ve.add("hand_delay_ms", "must be between 2000 and 15000")
	}
	if s.BlindsUpMinutes < 0 || s.BlindsUpMinutes > 600 {
		ve.add("blinds_up_minutes", "must be between 0 (off) and 600")
	}
	if s.BlindsUpPercent < 10 || s.BlindsUpPercent > 400 {
		ve.add("blinds_up_percent", "must be between 10 and 400")
	}
	if len(ve.Fields) > 0 {
		return &ve
	}
	return nil
}
