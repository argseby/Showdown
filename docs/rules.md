# Showdown — Poker rules

Source of truth for the game rules; update this file whenever behaviour changes.

## 7. Poker rules (Texas Hold'em, No-Limit)

The implementation follows this section exactly. Where a rule is a deliberate
simplification it says so. This section is moved verbatim to `docs/rules.md` in M0.

### 7.1 Eligibility and start of a hand

1. A player is **eligible** for a hand if seated, `status == active`, and `stack > 0`.
2. A hand starts only with ≥2 eligible players; otherwise the table idles and shows
   "waiting for players". `auto_start` or admin Start moves `waiting → running`.
3. Players who join while a hand is running are seated immediately with status `active`
   and are dealt in from the next hand.

### 7.2 Button and blinds

1. **First hand:** the button goes to a random eligible seat.
2. **Subsequent hands (simplified moving button):** the button moves to the next
   eligible seat clockwise from the previous button seat. Small blind is the next
   eligible seat clockwise from the button, big blind the next after that. This is *not*
   the dead-button rule: after players leave or sit out, a seat may occasionally skip a
   blind. Documented and accepted for v1.
3. **Heads-up:** the button posts the small blind and acts first preflop; the other
   player posts the big blind and acts first on every later street.
4. **Antes** (if `ante > 0`) are posted by every eligible player before the blinds and
   go straight into the pot. A player who cannot cover an ante or blind posts all their
   chips and is all-in. A short blind does not lower the betting level: `current_bet`
   stays at `big_blind`, so other players still call the full big blind and the short
   poster's stake is settled through side pots.
5. Blind and ante amounts are the table settings at the moment the hand starts.

#### 7.2a Straddle (table setting `allow_straddle`, off by default)

With three or more players the seat left of the big blind may post a straddle of twice
the big blind before the cards are dealt (the player arms it; it applies whenever they
are in that seat and hold more than 2 BB). The straddle is a live blind: it sets the
price preflop, the first to act is the seat left of the straddler, the straddler acts
last with the option, and the minimum raise is twice the straddle.

### 7.3 Dealing

1. Deck of 52 cards shuffled with Fisher–Yates using `crypto/rand` (engine receives the
   shuffle function; tests inject a deterministic one). No burn cards (irrelevant to
   fairness; stated in the docs).
2. Two hole cards each, dealt one at a time clockwise starting left of the button.
3. Streets: preflop → flop (3 cards) → turn (1) → river (1) → showdown.

### 7.4 Order of action

1. Preflop: first to act is the seat left of the big blind (heads-up: the button).
2. Postflop: first eligible-in-hand seat left of the button (heads-up: the big blind).
3. Action passes clockwise, skipping players who have folded or are all-in.

### 7.5 Betting round state

Per street: `current_bet` (highest total bet this street), `last_full_bet_level` (highest
level established by a full bet or full raise), `last_raise_size` (initialized to
`big_blind`; preflop the big blind itself counts as a full bet of size `big_blind`).
Per player: `bet_this_street`, `has_acted`, `acted_at_full_level`.

Actions and legality:

| Action | Legal when | Effect |
|---|---|---|
| `fold` | always on your turn | out of the hand; chips already bet stay in |
| `check` | `bet_this_street == current_bet` | no chips |
| `call` | `current_bet > bet_this_street` | match `current_bet`; if `stack` is short → all-in for less (never counts as a raise) |
| `bet` (amount = total) | `current_bet == 0` (postflop, nobody has bet yet). Preflop the blinds set `current_bet = big_blind`, so the first voluntary wager there is a `raise`. | min `big_blind`, max `stack`; full bet → `last_raise_size = amount`, `last_full_bet_level = amount` |
| `raise` (amount = **raise to**) | `current_bet > 0` and player may raise (below) | min `current_bet + last_raise_size`, max `bet_this_street + stack`. A raise ≥ min is **full**: `last_raise_size = amount − current_bet`, `last_full_bet_level = amount`. An all-in raise below min is **short**: updates `current_bet` only. |
| `all_in` | always on your turn | shorthand for bet/raise/call with the entire stack, classified by the rules above |

**Who may raise:** a player may raise if `!has_acted` or
`acted_at_full_level < last_full_bet_level`. When a player acts, set `has_acted = true`
and `acted_at_full_level = last_full_bet_level`. Consequence: a short all-in does not
reopen raising for anyone who already acted at the current full level; they may only
call or fold. (Example: A bets 100, B raises to 300, C goes all-in for 350. A may
re-raise — A has not acted since B's full raise; B may only call 50 or fold. The next
minimum raise-to is 350 + 200 = 550.)

The big blind's forced post does not count as having acted (the big blind gets the
"option" preflop).

**Round ends** when every player still in the hand who is not all-in has `has_acted`
and `bet_this_street == current_bet`. In addition, if fewer than two players still in the
hand are not all-in and none of them is facing a bet (`bet_this_street == current_bet`),
the round ends at once without asking anyone to act — betting is over and the board runs
out (§7.7). An **uncalled bet** (the portion of `current_bet` no other live player
matched) is returned to the bettor before pots are formed; the client shows "uncalled bet
returned".

### 7.6 Pots and side pots

At the end of each street bets are collected. Pots are computed from each player's
`total_contributed` for the hand using contribution levels: sort the distinct
`total_contributed` values of all-in players ascending, then append the maximum
contribution. For level *i*, `pot_i = Σ_players (min(total, level_i) − min(total,
level_{i−1}))`; eligible for `pot_i` are the non-folded players with
`total ≥ level_i`. Folded players' chips are included in the amounts but never in
eligibility. The main pot is level 0; the snapshot lists pots with eligible seats so the
UI can label "Main pot" / "Side pot 1…".

### 7.7 Early termination and run-out

1. If all but one player fold, the remaining player wins every pot immediately with no
   reveal. They may `show_cards` during the result phase.
2. If betting is complete and no further betting is possible (every remaining player but
   at most one is all-in), all live hands are revealed immediately and the remaining
   streets are dealt automatically with `runout_delay_ms` between them.

#### 7.7a Run it twice (table setting `run_it_twice`, off by default)

When betting is over with at least two live hands and cards still to come, the run-out
waits up to 8 seconds for every live player to agree to run it twice. If all agree, the
remaining streets are dealt twice from the same deck (board 1 first, then board 2, street
by street) and every pot is paid in two halves, one per board, the odd chip going with
board 1. A single "no" or the timeout runs the board once.

### 7.8 Showdown

1. Each live player's best five-card hand is evaluated from their two hole cards plus the
   board (any 5 of 7). Categories high to low: straight flush (royal is not a separate
   category), four of a kind, full house, flush, straight, three of a kind, two pair, one
   pair, high card. The wheel (A-2-3-4-5) is the lowest straight. Ties are broken by
   ranks in standard order; suits never break ties.
2. Pots are awarded from the main pot outward. For each pot, the eligible players with
   the best hand split it equally. **Odd chips** go one each to the tied winners in
   clockwise order starting from the first seat left of the button.
3. Reveal policy (`showdown_reveal`): `all` reveals every hand that reached showdown;
   `winners_only` reveals only hands that won at least one pot; `in_order` (default,
   owner decision 2026-09-05) reveals like at a live table: the last player who bet or
   raised on the river shows first (with no river bet, the first live seat left of the
   button), then clockwise; each player in turn shows unless every pot they are
   eligible for is already beaten by a hand on the table, in which case they muck
   (`mucked` event, `player.mucked`). Ties show. Mucked and unrevealed players may
   `show_cards` during the result phase.
4. Hands are shown one at a time with `showdown_per_hand_ms` (1.5 s) between them
   (`hand.phase = "showdown"`); when the board ran out with everyone all-in, all hands
   are shown at once. The result phase then lasts `showdown_delay_ms`, then
   `hand_delay_ms` passes before the next deal.

### 7.9 Chip conservation (invariant)

Within a hand: `Σ stacks + Σ pots + Σ bets_in_front` is constant from the first post to
the last award. Across hands it changes only through joins, rebuys, admin chip
adjustments, and leaves — each of which produces an event. Tests assert this after every
event in the randomized simulation (§11).

### 7.10 Timers

1. Each turn has a deadline: `now + turn_time` (or `disconnected_turn_time` if the
   player is disconnected when the turn starts). The snapshot carries `deadline_ts`.
2. **Time bank** (`time_bank_seconds`, default 30, 0 = off): when a connected player's
   clock runs out, their remaining bank is added to the turn once; unused seconds are
   refunded when they act, and every hand played refills 5 seconds up to the maximum.
   Only when the extension runs out too does the timeout rule apply: `check` if legal,
   else `fold`; `missed_turns++`. A manual action resets
   `missed_turns` to 0. Reaching `sit_out_after_missed_turns` sets the player to
   `sitting_out` after the hand.
3. A player may `sit_out` at any time (takes effect next hand; if they are in a hand they
   still act) and `sit_in` at any time (dealt in next hand).

### 7.11 Busting, rebuys, leaving

1. A player with `stack == 0` after a hand becomes `busted`. With `allow_rebuy`, they may
   `rebuy` between hands: `stack = start_money`, `buy_in_total += start_money`, status
   `active`. Without rebuy they keep the seat until they leave or are kicked.
2. Leaving (or being kicked) mid-hand folds the player immediately; their chips already
   in pots stay. The seat is freed after the hand; the final stack is recorded in
   `player_results` at that moment.
3. Admin chip adjustments are applied between hands and recorded as events and audit rows.

## Additions after v1 (owner decisions, 2026-09-05)

- **Sitting out during a hand** folds the player immediately (the next time it would be
  their turn, or at once when it is); they are not dealt in until they sit back in.
- **Pre-actions.** A player who is not to act may pre-select *check/fold* or *call any*;
  the choice is executed the moment their turn arrives and is cleared by any manual
  action and at the end of the hand.
- **Showing cards.** After an uncontested win the winner may show one card or both.
- **Rabbit hunting** (`allow_rabbit_hunt`, default on): after a hand that ended before
  the river, a player who was dealt in may reveal the cards that would have completed
  the board, once per hand. It never changes the outcome.
- **Blind schedule.** With `blinds_up_minutes` > 0 the blinds (and ante) rise by
  `blinds_up_percent` (rounded up) every N minutes while the table runs; the increase is
  applied when the next hand is dealt. The host can also raise them at any time. The
  clock stops while the table is paused.
- **Seat picking.** A joining player may choose a free seat; otherwise the lowest free
  seat is assigned. A seated player may move to a free seat by tapping it; the move
  happens at the next deal. To stop seat changes from dodging the blinds, the mover
  posts a **dead big blind** in their next hand (into the pot, after the antes, not
  counting as a bet, so the regular blinds still apply on top) and may move again only
  after three hands. Only one player can wait for a given seat.
