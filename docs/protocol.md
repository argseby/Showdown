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
>   {small_blind, big_blind}, variant}`; `POST /api/tables {name, settings}` (public, 5/min per
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
> - **Royal Hold'em (2026-09-09).** Table setting `variant`: `holdem` (default, 52
>   cards) or `royal` (only Ten to Ace, 20 cards). Royal tables seat at most 6 players
>   (`max_players`) and the change applies from the next hand. Reported as
>   `settings.variant` in snapshots and as `variant` in the `info` response.
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
> - **`GET /api/config` (2026-09-06).** Public, unauthenticated, no rate limit:
>   `{"ice_servers": [...], "version": "v1.2.3"}`. `version` is the build the API
>   runs, stamped into the binary at build time (the pushed tag for a release,
>   `edge-<sha>` on main, the commit or `dev` for a local build). It is never empty,
>   and the client shows it in the start screen's footer. `showdown -version` prints
>   the same string, which is how a running container can be identified without a
>   shell.
> - **Voice presence after a reconnect (2026-09-07).** The server resets `voice` and
>   `camera` when a player's connection drops. A client whose WebSocket reconnects
>   therefore announces its state again: `voice {state: "off"}` first, then its real
>   state, and only then does it offer to the peers again. The "off" tells a peer that
>   never saw the drop (the new connection replaced the old one before the server
>   noticed) to close its side and start over. A client that sees itself as "off" in a
>   snapshot while its microphone is on does the same.
> - **Message size caps (2026-09-06).** A frame may be 32 KiB; every message except
>   `voice_signal` is capped at 8 KiB and an oversized one closes the connection with
>   `1008`. Only `voice_signal` may be larger, and its `data` is capped at 24 KiB:
>   an SDP offer that carries a video track is around 9 KiB, well over the 6 KB the
>   first releases allowed, so camera offers and answers were refused and video never
>   connected. A signal beyond the cap is answered with `illegal_action` and the
>   connection stays open.
> - **Signalling rate limit (2026-09-17).** Commands are limited to 20 per second per
>   connection (close `1008` "rate limit"), but `voice_signal` has its own budget of 100
>   per second with a burst of 400. A browser trickles every ICE candidate as one
>   `voice_signal`; with STUN, a TURN server with two URLs and a few network interfaces
>   that is 20 to 40 messages within a second per peer, times the peers it (re)connects
>   to at once. Before this the burst closed the connection, the client reconnected,
>   rejoined the voice chat, sent the burst again and looped, so voice only worked for
>   players with few candidates and got worse when a TURN server was added.
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
> - **Hats (2026-09-17).** `join` accepts `hat` and the `hat {hat}` message changes it at
>   the table (§8.2). `seats[].player.hat` (omitted without a hat) and the admin detail's
>   `players[].hat` show it. Ids: `top_hat, cowboy, crown, party, beanie, wizard, chef,
>   pirate, cap, halo, viking, sombrero, fedora, bowler, santa, tiara, propeller,
>   bunny_ears, flower_crown, headband`; the client draws them.
> - **Running hot (2026-09-17).** `seats[].player.heat` (1..3, omitted at 0) is the
>   player's streak of hands won in a row: 2 in a row = 1, 3 = 2, 4 or more = 3. A hand
>   dealt in without winning a pot resets the streak (hands sat out do not count either
>   way); the streak is stored with the player. The client draws a fire ring around the
>   avatar in three intensities. The admin detail lists `players[].win_streak`.
> - **Tournament mode (2026-09-18).** Setting `tournament` (default false, public as
>   `settings.tournament`, also in the `info` response). The admin chip adjustment is
>   refused with `tournament_locked` (409) for the life of such a table. Once it has dealt
>   a hand **in the current round** (or is running), changes to `tournament, start_money, small_blind, big_blind,
>   ante, max_players, variant, allow_rebuy, showdown_reveal, blinds_up_minutes,
>   blinds_up_percent` and `change_seat` are refused the same way; `you.can_change_seat`
>   is false. Time settings, chat, drawings, kicks and the
>   manual blinds-up (equal for everyone, logged) stay available. A new round unlocks
>   them again until its first deal; `tournament_locked` in the admin detail reports the
>   current state rather than leaving clients to derive it.
> - **Pencil drawings (2026-09-18).** Setting `allow_drawing` (default true)
>   enables the `draw` / `draw_erase` / `draw_clear` messages and the `drawing`,
>   `drawings_removed`, `drawing_history` pushes (§8.2, §8.3).
> - **Stickers (2026-09-17).** `say` takes `{sticker}` as an alternative to `{phrase}`;
>   the broadcast `phrase` carries `sticker` instead of `phrase` then. The ids are listed
>   in `protocol.Stickers`; the client bundles Noto Animated Emoji (CC BY 4.0) for them.
> - **Hand strength for beginners (2026-09-17).** `GET /api/tables/{id}/strength` (bearer =
>   player session token, during a hand the player is in and has not folded; `invalid_state`
>   otherwise) answers `{equity, opponents, tier, description, street, cards, board, best?}`:
>   `equity` is the share of the pot the hand would win against `opponents` random hands over
>   the cards to come (2000 samples), `tier` one of `monster, strong, good, marginal, weak`
>   relative to an even share. Rate limited like `info`.
> - **New round on the same table (2026-09-19).** `POST /api/admin/tables/{id}/restart`
>   (table admin, only from `ended` → `{state: "waiting"}`, `invalid_state` otherwise)
>   opens a new round on the same table id: everyone keeps their seat, their session and
>   the link, stacks and statistics start over, placements are cleared and the blinds go
>   back to the level the host configured (the schedule's raises are dropped). Hand
>   numbering runs on — hands are unique per table and number — and `round_start_hand`
>   (admin detail) marks where the round began. Ending a table therefore no longer closes
>   the connections: an ended table is inert (every command answers `table_ended`) but
>   stays readable and attachable, so the standings survive a reload and a new round
>   reaches everyone at once. `snapshot.last_round {ended_at, hands, standings}` carries
>   the standing of the finished round and outlives the reset, which is the only record
>   left once the stacks are back at the start money. Event: `table_restarted`. A server
>   restart restores ended tables for 7 days so a new round is still possible.
> - **Player profiles (2026-09-19).** Optional and off unless `ACCOUNTS=true`;
>   `GET /api/config` reports `accounts`, and with it false every profile route
>   answers 404 `accounts_disabled`. A profile is a handle (3–20 of `a-z 0-9 _`,
>   unique on a folded form that treats `1`, `l` and `i`, `0` and `o`, `5` and `s`
>   as the same stroke and drops `_`), a display name (the table's name rules,
>   checked at sign-up and on every change — it is what other people are shown),
>   a bcrypt password (8–64)
>   and one recovery code, shown once at sign-up and the only way back in — the
>   server sends no mail. `POST /api/accounts` → `{token, account, recovery_code}`
>   (201); `POST /api/accounts/session` → `{token, account}`; `DELETE` the same
>   path signs this device out; `GET /api/accounts/me` → `{account}`;
>   `POST /api/accounts/password` takes `current_password` (bearer) or
>   `recovery_code` with the handle in `X-Handle`, signs every device out and
>   returns a fresh token and code. The profile token is a bearer token like the
>   others and lives 90 days. `POST /api/tables/{id}/join` accepts it too: the
>   seat then carries the profile, and `snapshot.seats[].player.account` names the
>   handle (absent for a guest, who may always join without one).
> - **A profile's own record (2026-09-20).** Every hand a signed-in player is
>   dealt writes one `hand_results` row and every finished round one
>   `round_results` row; a guest writes nothing. A row is `counted` only when
>   three or more profiles were dealt in and nobody was handed chips that round,
>   so the rule is fixed when the hand is played and cannot be applied after the
>   fact. `GET /api/accounts/me/stats` aggregates them (chips first, big blinds
>   as the rate); `GET /api/accounts/me/highlights` → `{best_hands,
>   biggest_wins, achievements}`, the hands with their five cards, where they
>   happened and whether the table saw them, and the milestones as
>   `{id, earned_at, progress, goal}` with `earned_at` the moment they were
>   reached (0 while still ahead). Both are private: they need the profile's own
>   bearer token.
> - **Visibility (2026-09-20).** The five sections (`profile, winnings,
>   best_hands, achievements, activity`) are stored with every profile as
>   `private | friends | public` and default to private. `PATCH
>   /api/accounts/me` takes `{display_name?, visibility?}` and accepts only
>   `private` and `public` — the column keeps `friends` for the friends feature,
>   and a switch that would silently do nothing is not offered. Nothing reads
>   the fields yet; the public profile will, and `profile: private` must hide
>   the page itself rather than return an empty one.
> - **Friends (2026-09-20).** A friendship is stored both ways, an ask is one
>   row that answering removes, and a block is one-way and silent. `GET
>   /api/friends` answers the whole screen (`friends`, `incoming`, `outgoing`,
>   `blocked`, `invites`); `GET /api/friends/search?q=` finds profiles by the
>   start of a handle or display name — as literal text, `%` and `_` included —
>   and says how each already stands to the
>   searcher (`none`, `friend`, `pending_out`, `pending_in`). `POST
>   /api/friends/requests` asks — two profiles that have each asked the other
>   are friends at once — and `POST /api/friends/requests/{handle}/{accept |
>   decline | block}` answers. Only an accepted ask is announced: a decline and
>   an unanswered ask look the same from the outside, and a block is never
>   mentioned to the blocked, who simply cannot ask again and gets a 404 for
>   anything of the blocker's. `DELETE /api/friends/{handle}` ends a
>   friendship, `DELETE /api/friends/blocks/{handle}` lifts a block without
>   restoring it.
> - **The user socket (2026-09-20).** `GET /ws/me` is one connection per device
>   for the signed-in profile (up to four; the oldest goes when a fifth
>   arrives). Hello carries the profile token, the only push is `user_event`
>   (`friend_request`, `friend_accepted`, `friends_changed`, `table_invite`,
>   `friends_playing`) and the only accepted command is `ping` — anything else
>   closes the connection with 1008. Nothing is only delivered here: a device
>   that was away finds the same things over REST.
> - **Table invitations and who is playing (2026-09-20).** `POST
>   /api/tables/{id}/invites` asks a friend to a table, and only a friend, and
>   only from somebody sitting at it; the invitation is stored (two hours) as
>   well as pushed, and `DELETE /api/friends/invites/{id}` spends it. Asking the
>   same friend to the same table again renews that one invitation instead of
>   adding another. `GET
>   /api/friends/playing` lists the live tables friends are seated at with the
>   stakes, the free seats and whether the door is open. A friend sitting down
>   pushes `friends_playing` to their friends; nobody is told when one gets up,
>   so the home screen also looks again every 30 s.
> - **Public profiles (2026-09-20).** `GET /api/profiles/{handle}` answers the
>   sections their owner shares with this viewer, by `canSee`: your own always,
>   `public` to anyone (a guest included), `friends` to a friend, and nothing
>   either way once one has blocked the other. A profile whose `profile`
>   section is not visible answers 404 — the same as a handle nobody took — so
>   the route cannot be used to find out who exists or who blocked you. Public
>   winnings are the counted hands only, and public best hands only the ones
>   the table was actually shown.
> - **Close codes** in use: `4001` bad/expired token (also a player who already left),
>   `4002` version, `4003` table not found / deleted, `4004` replaced, `4005`
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
| `hat` | `{hat}` | puts a hat on the player's avatar: one of `top_hat, cowboy, crown, party, beanie, wizard, chef, pirate, cap, halo, viking, sombrero, fedora, bowler, santa, tiara, propeller, bunny_ears, flower_crown, headband`, or `none` to take it off (`illegal_action` for anything else); everyone sees it as `seats[].player.hat` (absent without a hat); it is stored with the player, so it survives reconnects and restarts; `join` accepts `hat` too. The client draws the hats, the server only knows the ids |
| `avatar` | `{avatar}` | changes the player's avatar (0–19, `illegal_action` otherwise); stored with the player like the hat |
| `draw` | `{points}` | a pencil stroke on the table: `x0,y0,x1,y1,...` in 0–1 of the table area, at most 400 pairs (like `voice_signal` it may exceed the 8 KiB message cap, up to the 32 KiB frame; the client sends at most 200 points at three decimals); players only, when `allow_drawing`, not while chat-muted, at most 60 a minute (`rate_limited`); broadcast as `drawing`. A player keeps at most 40 strokes and the table 200, the oldest go first |
| `draw_erase` | `{ids}` | removes strokes by id, anyone's; broadcast as `drawings_removed {ids}` |
| `draw_clear` | `{all?}` | removes the sender's strokes, or every stroke with `all`; broadcast as `drawings_removed {ids}` or `{all: true}` |
| `say` | `{phrase}` or `{sticker}` | a quick phrase, one of `nice_hand, nice_call, nice_fold, nice_bluff, well_played, gg, thanks, sorry, wow, oops, furious, lol, hurry_up, brb`, or an animated sticker, one of the ids in `protocol.Stickers` (22 poker scenes such as `all_in`, `royal_flush`, `bad_beat`, `tilt`, `shark`, then emoji such as `poker_face`, `fire`, `skull`; 64 in all; the client ships or draws the animations); exactly one of the two, players only, at most one every 3 s (`rate_limited`), rejected while chat-muted; broadcast as `phrase {seat, name, phrase?, sticker?, ts}` and never persisted |
| `chat` | `{text}` | |
| `ping` | `{}` | client keepalive; server answers `pong` |

Close codes from the server: `4001` bad token, `4002` unsupported protocol version,
`4003` table not found or deleted, `4004` replaced by a newer connection, `4005` kicked,
`1008` policy (rate limit / oversize). An ended table does **not** close connections.

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
| `table_ended` | `{final_leaderboard}` — the connection stays open (§ new round) |
| `server_restarting` | `{}` |
| `pong` | `{server_ts}` |
| `phrase` | `{seat, name, phrase?, sticker?, ts}` — a quick phrase or a sticker to show next to the seat for a few seconds |
| `drawing` | `{id, player_id, seat, name, avatar, points, ts}` — one new pencil stroke |
| `drawings_removed` | `{ids?, all?}` — strokes gone |
| `drawing_history` | `{strokes}` — every current stroke, sent on connect after `chat_history` when there are any; strokes are not persisted and vanish with the player who drew them |

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
`table_ended`, `table_restarted`. The hand log and system chat lines are rendered from
these on the client.

### 8.5 Snapshot

```json
{
  "server_ts": 1789000000000,
  "table": { "id": "k7m2p9xq4w", "name": "Friday", "state": "running", "hand_number": 12,
             "settings": { "small_blind": 50, "big_blind": 100, "ante": 0, "turn_time": 30,
                           "max_players": 9, "start_money": 10000, "join_policy": "always",
                           "allow_rebuy": true, "showdown_reveal": "all", "chat_enabled": true,
                           "spectator_chat": true, "requires_password": true, "variant": "holdem" } },
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
  "last_round": { "ended_at": 1788999000000, "hands": 34,
                  "standings": [ { "name": "Bob", "stack": 30000, "net": 20000, "place": 1 } ] },
  "spectators": 2
}
```

`hole_cards` is present only for the recipient's own seat and for seats revealed in the
current hand; otherwise it is omitted (not `null`-ed with a count — the client draws two
face-down cards for any `in_hand && !folded` player). A seat whose hand is fully revealed
also carries `hand_description` and `best_cards` (its best five against the current board,
recomputed on every run-out street, so a hand shown after an all-in on the flop is
described correctly on the turn and the river); both are absent for hidden hands.
`seats[].player.hat` names the hat worn on the avatar (§8.2 `hat`) and is absent without
one; `seats[].player.heat` (1..3) marks a streak of hands won in a row and is absent
otherwise. `hand` is `null` while idle.
`hand.phase` ∈ `betting | runout | showdown | result`. `you.options` is `null` unless it
is the recipient's turn; `pots` shows chips collected from completed streets, while bets
of the current street are in `bet_this_street`. `you.hand_description` is computed
server-side from the flop on; the client has no hand evaluator.
