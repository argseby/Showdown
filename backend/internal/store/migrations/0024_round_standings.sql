-- 0024_round_standings: the table's own record of every round it played.
--
-- A round ends, the host opens a new one on the same table, and every stack
-- and statistic goes back to the start money. Until now the only thing that
-- survived that reset was snapshot.last_round — one round, in memory and in
-- the tables row. A group that plays all evening on one table kept nothing
-- but the round they just finished.
--
-- This is per table and per player, guests included: round_results next
-- door only ever holds signed-in profiles, and most play here is guests.
-- The rows are what the all-time standings of a table are summed from, and
-- what the PDF export prints. They belong to the table (a host who deletes
-- the table deletes its history with it), so unlike the profile results
-- they do cascade.
CREATE TABLE round_standings (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id      TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    table_name    TEXT    NOT NULL,
    -- 1 for the first round played on this table, counting up per table.
    round_index   INTEGER NOT NULL,
    round_start   INTEGER NOT NULL,   -- hand number the round began at
    hands         INTEGER NOT NULL,   -- hands played in the round
    ended_at      INTEGER NOT NULL,
    big_blind     INTEGER NOT NULL,   -- the stake the round ended at
    -- Who this row is. player_id is the seat's id at the time, account_id
    -- the profile behind it ('' for a guest). name_key (lower-cased,
    -- trimmed name) is what a guest is recognised by across rounds.
    player_id     TEXT    NOT NULL,
    account_id    TEXT    NOT NULL DEFAULT '',
    name          TEXT    NOT NULL,
    name_key      TEXT    NOT NULL,
    avatar        INTEGER NOT NULL DEFAULT 0,
    bot           INTEGER NOT NULL DEFAULT 0,
    stack         INTEGER NOT NULL,
    buy_in_total  INTEGER NOT NULL,
    net           INTEGER NOT NULL,   -- stack minus everything bought in
    place         INTEGER NOT NULL DEFAULT 0,
    players       INTEGER NOT NULL DEFAULT 0,
    hands_played  INTEGER NOT NULL DEFAULT 0,
    hands_won     INTEGER NOT NULL DEFAULT 0,
    biggest_pot   INTEGER NOT NULL DEFAULT 0,
    vpip_hands    INTEGER NOT NULL DEFAULT 0,
    showdowns     INTEGER NOT NULL DEFAULT 0,
    showdowns_won INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX round_standings_table_idx ON round_standings(table_id, round_index);
