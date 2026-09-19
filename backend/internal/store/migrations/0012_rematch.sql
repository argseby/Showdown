-- 0012_rematch: the host can open a new round on the same table id. The
-- blind level the host configured is remembered so a new round does not
-- start where the blind schedule had climbed to, and the standings of the
-- finished round are kept so the clients can still show them.

ALTER TABLE table_settings ADD COLUMN start_small_blind INTEGER NOT NULL DEFAULT 0;
ALTER TABLE table_settings ADD COLUMN start_big_blind   INTEGER NOT NULL DEFAULT 0;
ALTER TABLE table_settings ADD COLUMN start_ante        INTEGER NOT NULL DEFAULT 0;

-- Existing tables never stored a starting level: the current one becomes it.
UPDATE table_settings SET start_small_blind = small_blind, start_big_blind = big_blind, start_ante = ante;

-- round_start_hand is the hand number the current round started at, so a
-- tournament unlocks its settings and seats again between rounds.
ALTER TABLE tables ADD COLUMN round_start_hand INTEGER NOT NULL DEFAULT 0;
-- last_round is the JSON standing of the last finished round ('' = none).
ALTER TABLE tables ADD COLUMN last_round TEXT NOT NULL DEFAULT '';
