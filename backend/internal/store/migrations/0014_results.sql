-- 0014_results: what a profile did, hand by hand and round by round.
--
-- Neither table has a foreign key to tables: retention drops the hands and
-- the chat of an old table, and a host may delete a table outright, but a
-- player's record of having played is theirs and outlives both. The table
-- id and name ride along as plain columns so the record still reads.

CREATE TABLE hand_results (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id   TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    table_id     TEXT    NOT NULL,
    table_name   TEXT    NOT NULL,
    hand_number  INTEGER NOT NULL,
    ended_at     INTEGER NOT NULL,
    -- The stake the hand was played at: chips are only comparable across
    -- tables once they are counted in big blinds.
    big_blind    INTEGER NOT NULL,
    net          INTEGER NOT NULL,   -- stack after minus stack before
    won          INTEGER NOT NULL,   -- chips collected from pots
    dealt_in     INTEGER NOT NULL,
    folded       INTEGER NOT NULL,
    vpip         INTEGER NOT NULL,   -- put chips in voluntarily before the flop
    showdown     INTEGER NOT NULL,   -- still in it when the cards came down
    showdown_won INTEGER NOT NULL,
    all_in       INTEGER NOT NULL,
    -- What the hand made: a poker category (0 high card .. 8 straight flush),
    -- -1 for a hand that never reached a board. royal marks the one straight
    -- flush everybody counts separately; shown says the table saw it.
    category     INTEGER NOT NULL DEFAULT -1,
    royal        INTEGER NOT NULL DEFAULT 0,
    shown        INTEGER NOT NULL DEFAULT 0,
    description  TEXT    NOT NULL DEFAULT '',
    best_cards   TEXT    NOT NULL DEFAULT '',
    -- counted: this hand may stand in a public total. Three or more
    -- profiles were dealt in and nobody's chips were adjusted this round,
    -- so the money was played for, not handed out.
    counted      INTEGER NOT NULL DEFAULT 0,
    profiles     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX hand_results_account_idx ON hand_results(account_id, ended_at);

-- One row per profile per finished round (a table restarted for a new round
-- writes a second one).
CREATE TABLE round_results (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id  TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    table_id    TEXT    NOT NULL,
    table_name  TEXT    NOT NULL,
    round_start INTEGER NOT NULL,   -- hand number the round began at
    ended_at    INTEGER NOT NULL,
    big_blind   INTEGER NOT NULL,
    net         INTEGER NOT NULL,   -- stack at the end minus everything bought in
    place       INTEGER NOT NULL DEFAULT 0,
    players     INTEGER NOT NULL DEFAULT 0,
    tournament  INTEGER NOT NULL DEFAULT 0,
    counted     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX round_results_account_idx ON round_results(account_id, ended_at);
