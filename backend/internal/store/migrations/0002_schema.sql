-- 0002_schema: core tables for the table actor, sessions, chat, hand history,
-- global leaderboard results and the admin audit log.

CREATE TABLE tables (
    id          TEXT    PRIMARY KEY,
    name        TEXT    NOT NULL,
    state       TEXT    NOT NULL,           -- waiting | running | paused | ended
    created_at  INTEGER NOT NULL,
    ended_at    INTEGER,
    hand_number INTEGER NOT NULL DEFAULT 0,
    button_seat INTEGER NOT NULL DEFAULT -1
);

CREATE TABLE table_settings (
    table_id                   TEXT    PRIMARY KEY REFERENCES tables(id) ON DELETE CASCADE,
    password_hash              TEXT    NOT NULL DEFAULT '',
    max_players                INTEGER NOT NULL,
    start_money                INTEGER NOT NULL,
    small_blind                INTEGER NOT NULL,
    big_blind                  INTEGER NOT NULL,
    ante                       INTEGER NOT NULL,
    turn_time                  INTEGER NOT NULL,
    disconnected_turn_time     INTEGER NOT NULL,
    sit_out_after_missed_turns INTEGER NOT NULL,
    join_policy                TEXT    NOT NULL,
    allow_spectators           INTEGER NOT NULL,
    spectator_chat             INTEGER NOT NULL,
    chat_enabled               INTEGER NOT NULL,
    allow_rebuy                INTEGER NOT NULL,
    showdown_reveal            TEXT    NOT NULL,
    auto_start                 INTEGER NOT NULL,
    hand_delay_ms              INTEGER NOT NULL
);

CREATE TABLE players (
    id           TEXT    PRIMARY KEY,
    table_id     TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    name         TEXT    NOT NULL,
    seat         INTEGER NOT NULL,
    stack        INTEGER NOT NULL,
    status       TEXT    NOT NULL,           -- active | sitting_out | busted | left
    muted        INTEGER NOT NULL DEFAULT 0,
    missed_turns INTEGER NOT NULL DEFAULT 0,
    buy_in_total INTEGER NOT NULL,
    hands_played INTEGER NOT NULL DEFAULT 0,
    hands_won    INTEGER NOT NULL DEFAULT 0,
    biggest_pot  INTEGER NOT NULL DEFAULT 0,
    joined_at    INTEGER NOT NULL,
    left_at      INTEGER
);
CREATE INDEX players_table_idx ON players(table_id);

CREATE TABLE sessions (
    token_hash TEXT    PRIMARY KEY,          -- SHA-256 of the token, hex
    kind       TEXT    NOT NULL,             -- player | spectator
    table_id   TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    player_id  TEXT    NOT NULL DEFAULT '',
    name       TEXT    NOT NULL,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);
CREATE INDEX sessions_table_idx ON sessions(table_id);

CREATE TABLE chat_messages (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id    TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    author_kind TEXT    NOT NULL,            -- player | spectator | admin | system
    author_name TEXT    NOT NULL,
    text        TEXT    NOT NULL,
    ts          INTEGER NOT NULL
);
CREATE INDEX chat_messages_table_idx ON chat_messages(table_id, id);

CREATE TABLE hands (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id        TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    number          INTEGER NOT NULL,
    started_at      INTEGER NOT NULL,
    ended_at        INTEGER,
    button_seat     INTEGER NOT NULL,
    small_blind     INTEGER NOT NULL,
    big_blind       INTEGER NOT NULL,
    ante            INTEGER NOT NULL,
    stacks_at_start TEXT    NOT NULL,        -- JSON object seat -> stack
    events          TEXT    NOT NULL DEFAULT '[]',
    results         TEXT,                    -- JSON, null until the hand ended
    voided          INTEGER NOT NULL DEFAULT 0,
    UNIQUE (table_id, number)
);

-- Kept for the global leaderboard even after retention removes hands and
-- chat. Self-contained on purpose: no foreign key to tables.
CREATE TABLE player_results (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id     TEXT    NOT NULL,
    table_name   TEXT    NOT NULL,
    player_id    TEXT    NOT NULL,
    name         TEXT    NOT NULL,
    name_key     TEXT    NOT NULL,           -- lower-cased, trimmed name
    stack        INTEGER NOT NULL,
    buy_in_total INTEGER NOT NULL,
    net          INTEGER NOT NULL,
    hands_played INTEGER NOT NULL,
    hands_won    INTEGER NOT NULL,
    biggest_pot  INTEGER NOT NULL,
    recorded_at  INTEGER NOT NULL,
    table_ended  INTEGER NOT NULL DEFAULT 0,
    ended_at     INTEGER
);
CREATE INDEX player_results_name_idx ON player_results(name_key);
CREATE INDEX player_results_table_idx ON player_results(table_id);

CREATE TABLE admin_actions (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    ts        INTEGER NOT NULL,
    action    TEXT    NOT NULL,
    table_id  TEXT    NOT NULL DEFAULT '',
    player_id TEXT    NOT NULL DEFAULT '',
    details   TEXT    NOT NULL DEFAULT '{}'
);
