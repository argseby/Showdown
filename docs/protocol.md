# Showdown — Wire protocol (v1)

Source of truth for the wire protocol; update this file whenever behaviour changes.

> **Implementation notes (M2).** The sections below are the original specification. Where the
> implementation had to be more precise, the differences are listed here and win:
>
> - **Event field names.** An event's own `kind` is the event kind, so the action kind
>   inside an `action` event is carried in `action` (`action {seat, action, amount,
>   all_in}`), the blind kind in `blind` (`blind_posted {seat, blind: "small"|"big",
>   amount, all_in}`) and the timeout resolution in `resolved_as`. `hand_started` carries
>   `button_seat, sb_seat, bb_seat, blinds {small, big}, ante, stacks {"<seat>": stack}`.
>   Amounts: `bet`/`raise` carry the total bet this street ("raise to"), `call` carries
>   the chips added. Table events carry `seat` and `name` where a player is involved;
>   `player_rebought` adds `amount`, `chips_adjusted` adds `delta`, `settings_changed`
>   adds `fields` (sorted), `hand_voided` adds `reason`.
> - **`hands_revealed.reveals[].best`** lists the five cards that form the revealed hand
>   (present from the flop on) so the client can highlight them at showdown.
> - **`hand_ended.results`** is `{pots: [{index, amount, winners: [{seat, amount}],
>   description}], seats: {"<seat>": {net, won, folded, revealed, cards?, description?}}}`.
> - **`events.hand_number`** is the current (or most recently played) hand; table events
>   between hands continue that hand's `seq` sequence.
> - **Snapshot phases.** `hand.phase` is `betting` (also during the short street-deal
>   pause), `runout` (no more betting possible, board being dealt), `showdown`
>   (results shown, `showdown_delay_ms`), `result` (results still shown, `hand_delay_ms`).
>   `show_cards` is accepted during `showdown` and `result`; `rebuy` as soon as the hand
>   reached its result phase. `hand.min_raise_to` is only meaningful while
>   `to_act_seat` is set.
> - **REST error envelope** may carry `fields: [{field, message}]` for validation
>   errors (`code: validation_failed`); `field`/`message` then repeat the first entry.
>   Additional codes: `bad_request`, `unauthorized`, `validation_failed`, `not_seated`,
>   `invalid_state`, `table_running`, `too_many_tables`, `internal_error`,
>   `spectators_disabled`, `rate_limited`.
> - **REST responses.** `join` → `{player_token, player_id, seat, name}` (201);
>   `spectate` → `{spectator_token, name}` (201); `info` → `{name, state,
>   requires_password, join_policy, allow_spectators, seated, max_players, blinds:
>   {small_blind, big_blind}}`; `POST /api/tables {name, settings}` (public, 5/min per
>   IP) → the table object plus `admin_token` (201; the token is returned exactly once).
>   Table admin (bearer = that table's admin token): `PATCH settings` →
>   `{changed, applies_next_hand, settings}`; lifecycle → `{state}`; `chips` →
>   `{applied, queued}`; `hands` → `{hands: [{id, number, started_at, ended_at,
>   button_seat, small_blind, big_blind, ante, stacks_at_start, events, results, voided}]}`.
>   Table objects in admin responses use `{id, name, state, hand_number, created_at,
>   ended_at?, settings, players, spectators, connections, join_url}`; `settings` reports
>   `requires_password` instead of the password. There is no global admin, no table
>   list and no global leaderboard (owner decision, 2026-09-05).
> - **Sessions.** Player and spectator tokens are valid for 30 days; a player's sessions
>   are deleted when they leave or are kicked. A table's admin token has no expiry; only
>   its SHA-256 is stored with the table, so it survives restarts.
> - **`you.is_admin`** (snapshot) is true for the table admin's connection.
> - **Phase timers.** `hand.phase_ends_ts` is set during `showdown` and `result` (the
>   next deal follows the result phase); `table.next_hand_ts` is set while the table
>   idles with a deal pending (hand delay after a join or the previous hand). Clients
>   show these as countdowns like the turn deadline.
> - **Late reveals.** A `show_cards` or `rabbit_hunt` in the showdown or result phase
>   guarantees at least five more seconds on screen (`phase_ends_ts` moves to
>   now + 5 s when that is later than the current deadline) and re-persists the hand,
>   so everyone sees it and the replay contains it. The showdown itself lasts
>   `showdown_delay_ms` plus 1.5 s per revealed hand beyond the first (a five-way
>   showdown stays for 9.5 s, an uncontested hand for 3.5 s).
> - **`spectator_names`** (snapshot, omitted when empty): the display names of the
>   connected spectators, sorted, for the invite dialog.
> - **Staged showdown (2026-09-05).** With `showdown_reveal: "in_order"` (default) or
>   `"all"`/`"winners_only"` the river betting ends with `hand.phase = "showdown"` and
>   the server emits one `hands_revealed` (single reveal) or `mucked {seat, name}`
>   event per live player in showdown order, one every 1.5 s; the `pot_awarded` and
>   `hand_ended` events follow the last one. `seats[].player.mucked` marks a player
>   who mucked. A run-out (everyone all-in) still reveals all hands at once.
> - **`hand_ended.results.seats[].best`** (2026-09-06): the five cards making each
>   revealed hand, so a run-out revealed before the board was complete still ends
>   with the winning cards known.
> - **`seats[].player.muted`** (omitted when false): chat-muted by the host.
> - **Time bank (2026-09-05).** Setting `time_bank_seconds` (default 30, 0 = off): when
>   a connected player's turn clock runs out, their remaining time bank is added once
>   (`hand.time_bank_active`, `deadline_ts` moves); unused seconds are refunded when they
>   act, the bank is emptied when the extension runs out too, and every hand played
>   without the bank kicking in refills `time_bank_refill_seconds` (setting, default 1,
>   0–30; public settings and admin settings carry it) up to the maximum.
>   `seats[].player.time_bank` shows the balance.
> - **Voice signalling (2026-09-06).** Clients apply the signals of one peer strictly in
>   order, keep ICE candidates that arrive before the remote description and resolve
>   offer collisions with perfect negotiation: the side that answered the first offer
>   is polite and yields, the other keeps its own offer and answers `null` (nothing is
>   sent). The kinds stay `offer`, `answer`, `ice`.
> - **Message size caps (2026-09-06).** A frame may be 32 KiB; every message except
>   `voice_signal` is capped at 8 KiB and an oversized one closes the connection with
>   `1008`. Only `voice_signal` may be larger, and its `data` is capped at 24 KiB:
>   an SDP offer that carries a video track is around 9 KiB, well over the 6 KB the
>   first releases allowed, so camera offers and answers were refused and video never
>   connected. A signal beyond the cap is answered with `illegal_action` and the
>   connection stays open.
> - **Staged pot awards (2026-09-06).** The `pot_awarded` events of a hand still arrive
>   in one batch (main pot first), but clients present the pots one after another,
>   side pots first and the main pot last, 2.5 s each (main pot gold, first side pot
>   silver, further pots bronze). The server adds the same 2.5 s per pot beyond the
>   first to the showdown phase (`hand.phase_ends_ts`) so the presentation fits.
> - **Run-out equity.** During a run-out (`hand.phase = "runout"`, everyone all-in) each
>   live seat carries `player.equity`, its share of the pot in percent for the cards to
>   come (exhaustive with two or fewer cards to come, 20 000 samples otherwise); it is
>   refreshed after every street.
> - **Statistics and placements.** `leaderboard[]` (and `table_ended.final_leaderboard`)
>   carry `hands_played`, `vpip_hands` (hands with chips put in voluntarily preflop),
>   `showdowns`, `showdowns_won` and `place`. Without rebuys a bust is final and the
>   player gets `place` = players still holding chips + 1; when one player holds all the
>   chips the table ends after the hand and the remaining players are placed by stack.
>   The leaderboard sorts placed players by place.
> - **Host camera off.** `POST /api/admin/tables/{id}/players/{pid}/camera-off` clears
>   `player.camera`; the player can turn it on again.
> - **Host microphone mute.** `POST /api/admin/tables/{id}/players/{pid}/voice-mute`
>   sets the player's `voice` to `muted` (error `illegal_action` unless it was `on`);
>   the player's client mutes its microphone when it sees that and may unmute again
>   itself — there is no host unmute. The admin table detail lists `players[].voice`.
> - **Owner feature batch (2026-09-05).** `join` accepts `seat` (wanted seat, error
>   `seat_taken`) and `avatar` (0–19); `info` lists `taken_seats`. Snapshot additions:
>   `seats[].player.avatar`, `hand.rabbit_cards?`, `you.pre_action`, `you.best_cards?`
>   (the viewer's cards making their current hand, from the deal on; the description is
>   given before the flop too), `you.can_rabbit_hunt`, `table.next_blinds_up_ts?` and the
>   settings `allow_rabbit_hunt`, `blinds_up_minutes`, `blinds_up_percent`. Events:
>   `rabbit_hunt {seat, name, cards}`, `blinds_changed {blinds, ante}`. A sit-out during
>   a hand folds the player at once. `GET /api/tables/{id}/hands` (bearer = session token)
>   serves the hand history to players and spectators with hole cards only for the
>   viewer's own seat and revealed hands; the admin route applies the same rule.
>   `POST /api/admin/tables/{id}/blinds-up` raises the blinds by `blinds_up_percent` now.
> - **Close codes** in use: `4001` bad/expired token (also a player who already left),
>   `4002` version, `4003` table not found / ended / deleted, `4004` replaced, `4005`
>   kicked, `1008` policy (no hello within 5 s, oversize, rate limit, slow consumer,
>   spectators disabled), `1000` after a voluntary `leave`, `1001` server shutdown
>   (after `server_restarting`).

## 8. Wire protocol (v1)

Source of truth is `docs/protocol.md` (extracted from this section in M0). Go types live
in `internal/protocol`, Dart types in `lib/protocol/`. For every message type there is a
fixture in `docs/protocol/fixtures/` that both test suites must parse and re-serialize
byte-identically (after key sorting).

### 8.1 Envelope

```json
{ "type": "action", "id": "c-17", "payload": { "kind": "raise", "amount": 550 } }
```

`id` is set by the client on commands and echoed on `ack`/`error`. Server pushes have no
`id`. Unknown `type` → `error {code: "unknown_type"}`. Cards are two-character strings:
rank `2-9 T J Q K A`, suit `s h d c` (e.g. `"As"`, `"Td"`).

### 8.2 Client → server

| type | payload | notes |
|---|---|---|
| `hello` | `{v: 1, token, admin_token?}` | must be the first message within `hello_timeout`; `token` is a player, spectator, or table admin token; a player/spectator who also sends the table's `admin_token` is flagged as its admin (`you.is_admin`) |
| `action` | `{kind: "fold"\|"check"\|"call"\|"bet"\|"raise"\|"all_in", amount?}` | `bet`/`raise` amount is the **total** the player bets/raises to |
| `sit_out` / `sit_in` / `rebuy` / `leave` | `{}` | |
| `show_cards` | `{cards?: "both"\|"first"\|"second"}` | only during the result phase, by an uncontested winner or a mucked player; one card at a time is allowed (a partial reveal lists the hidden card as `""`) |
| `pre_action` | `{kind: "none"\|"check_fold"\|"call_any"}` | an automatic action performed at every turn of the player (check if free else fold / call any bet else check) for the rest of the current hand (armed between hands: for the next one); it is cleared when that hand ends and never carries over; the player may send `none` earlier, sitting out or leaving clears it too; `you.pre_action` mirrors it |
| `change_seat` | `{seat}` | move to a free seat at the next deal (errors `seat_taken`, `invalid_state` during the cooldown); `you.pending_seat`, `you.can_change_seat`; events `player_moved {seat, name, delta = old seat}` and `blind_posted {blind: "dead"}` |
| `voice` | `{state: "off"\|"on"\|"muted", camera?}` | voice-chat presence, shown to everyone as `seats[].player.voice`, and whether the player's camera is on (`seats[].player.camera`; the video travels browser to browser like the audio); reset when the connection drops |
| `voice_signal` | `{to, kind: "offer"\|"answer"\|"ice", data}` | WebRTC setup message relayed to the target player as `voice_signal {from, kind, data}` (server push); the audio itself is browser-to-browser and never touches the server; `data` is opaque, at most 24 KiB (an SDP offer carrying a video track is around 9 KiB; a larger one is refused with `illegal_action` and the connection stays open) |
| `rabbit_hunt` | `{}` | result phase, once per hand, by a player dealt in, when `allow_rabbit_hunt`: reveals the rest of the board (`rabbit_hunt` event, `hand.rabbit_cards`) |
| `straddle` | `{on}` | arms/disarms the player's straddle (setting `allow_straddle`): whenever they sit left of the big blind with more than 2 BB they post 2×BB before the deal (`blind_posted {blind: "straddle"}`, `hand.straddle_seat`), act last preflop, and the minimum raise is twice the straddle; `you.straddle` mirrors it |
| `run_twice` | `{agree}` | answer to the run-it-twice vote (setting `run_it_twice`): when everyone is all-in with cards to come the run-out waits up to 8 s (`hand.run_twice_ends_ts`, `you.can_run_twice`, `you.run_twice_vote`); if every live player agrees the remaining streets are dealt twice (`street_dealt {board: 2}`, `hand.board2`, `hand.run_twice`) and each pot is paid in halves per board (`pot_awarded {board: 1|2}`, odd chip to board 1); a single "no" or the timeout runs it once |
| `say` | `{phrase}` | one of the quick phrases `nice_hand, nice_call, nice_fold, nice_bluff, well_played, gg, thanks, sorry, wow, oops, furious, lol, hurry_up, brb`; players only, at most one every 3 s (`rate_limited`), rejected while chat-muted; broadcast as `phrase` and never persisted |
| `chat` | `{text}` | |
| `ping` | `{}` | client keepalive; server answers `pong` |

Close codes from the server: `4001` bad token, `4002` unsupported protocol version,
`4003` table not found or ended, `4004` replaced by a newer connection, `4005` kicked,
`1008` policy (rate limit / oversize).

### 8.3 Server → client

| type | payload |
|---|---|
| `welcome` | `{you: {role: "player"\|"spectator"\|"admin", player_id?, seat?}, snapshot}` |
| `snapshot` | full personalized state (§8.5); sent after **every** state change |
| `events` | `{hand_number, events: [...]}` (§8.4); sent immediately before the snapshot they lead to |
| `chat` | one chat message |
| `chat_history` | `{messages: [...]}` on connect |
| `chat_removed` | `{id}` |
| `ack` | `{id}` |
| `error` | `{id?, code, message}` — codes include `not_your_turn`, `illegal_action`, `amount_out_of_range`, `chat_disabled`, `muted`, `rate_limited`, `rebuy_not_allowed`, `not_between_hands` |
| `kicked` | `{reason}` then close 4005 |
| `table_ended` | `{final_leaderboard}` |
| `server_restarting` | `{}` |
| `pong` | `{server_ts}` |
| `phrase` | `{seat, name, phrase, ts}` — a quick phrase to show next to the seat for a few seconds |

### 8.4 Hand events

Each event: `{seq, ts, kind, ...fields}`. Kinds: `hand_started {button_seat, sb_seat,
bb_seat, blinds, ante, stacks}`, `ante_posted {seat, amount}`, `blind_posted {seat,
kind, amount, all_in}`, `hole_cards_dealt {seat, cards?}` (cards only in the owner's
copy), `action {seat, kind, amount, all_in}`, `timeout {seat, resolved_as}`,
`uncalled_returned {seat, amount}`, `street_dealt {street, cards}`, `pots_updated
{pots}`, `hands_revealed {reveals: [{seat, cards, description}]}`, `pot_awarded
{pot_index, seat, amount, description}`, `hand_ended {results}`, `hand_voided {reason}`,
plus table events `player_joined`, `player_left`, `player_kicked`, `player_sat_out`,
`player_sat_in`, `player_busted`, `player_rebought`, `chips_adjusted {seat, delta}`,
`settings_changed {fields}`, `table_started`, `table_paused`, `table_resumed`,
`table_ended`. The hand log and system chat lines are rendered from these on the client.

### 8.5 Snapshot

```json
{
  "server_ts": 1789000000000,
  "table": { "id": "k7m2p9xq4w", "name": "Friday", "state": "running", "hand_number": 12,
             "settings": { "small_blind": 50, "big_blind": 100, "ante": 0, "turn_time": 30,
                           "max_players": 9, "start_money": 10000, "join_policy": "always",
                           "allow_rebuy": true, "showdown_reveal": "all", "chat_enabled": true,
                           "spectator_chat": true, "requires_password": true } },
  "seats": [ { "seat": 0, "player": { "id": "p1", "name": "Alice", "stack": 8450, "status": "active",
               "connected": true, "in_hand": true, "folded": false, "all_in": false,
               "bet_this_street": 0, "total_bet": 100, "hole_cards": ["As", "Kd"],
               "last_action": null } },
             { "seat": 1, "player": null },
             { "seat": 4, "player": { "id": "p4", "name": "Bob", "stack": 5200, "status": "active",
               "connected": true, "in_hand": true, "folded": false, "all_in": false,
               "bet_this_street": 300, "total_bet": 400,
               "last_action": { "kind": "bet", "amount": 300 } } } ],
  "hand": { "street": "flop", "board": ["Ah", "7c", "2d"], "button_seat": 3, "sb_seat": 4, "bb_seat": 0,
            "to_act_seat": 0, "deadline_ts": 1789000027000, "current_bet": 300, "min_raise_to": 600,
            "pots": [ { "amount": 300, "eligible_seats": [0, 3, 4] } ],
            "phase": "betting" },
  "you": { "role": "player", "player_id": "p1", "seat": 0,
           "options": { "fold": true, "check": false, "call": 300, "raise": { "min": 600, "max": 8450 }, "all_in": 8450 },
           "hand_description": "Pair of Aces", "can_rebuy": false, "can_show_cards": false },
  "leaderboard": [ { "name": "Alice", "stack": 8450, "net": -1550, "hands_won": 3, "biggest_pot": 2200 } ],
  "spectators": 2
}
```

`hole_cards` is present only for the recipient's own seat and for seats revealed in the
current hand; otherwise it is omitted (not `null`-ed with a count — the client draws two
face-down cards for any `in_hand && !folded` player). A seat whose hand is fully revealed
also carries `hand_description` and `best_cards` (its best five against the current board,
recomputed on every run-out street, so a hand shown after an all-in on the flop is
described correctly on the turn and the river); both are absent for hidden hands. `hand` is `null` while idle.
`hand.phase` ∈ `betting | runout | showdown | result`. `you.options` is `null` unless it
is the recipient's turn; `pots` shows chips collected from completed streets, while bets
of the current street are in `bet_this_street`. `you.hand_description` is computed
server-side from the flop on; the client has no hand evaluator.
