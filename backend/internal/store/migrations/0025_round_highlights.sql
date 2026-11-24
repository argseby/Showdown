-- 0025_round_highlights: the hand people talk about afterwards.
--
-- round_standings keeps how a round ended for every player, but not what
-- happened in it. The biggest pot of a round — who took it, with what, at
-- which hand — is what an evening is remembered by, and the hand history it
-- could be dug out of is dropped by retention long before the standings are.
--
-- tables.round_best carries the biggest pot of the round being played (JSON,
-- '' = none yet) so a server restart mid-round does not forget it; when the
-- round ends it is written next to that round's standings.
ALTER TABLE tables ADD COLUMN round_best TEXT NOT NULL DEFAULT '';

CREATE TABLE round_highlights (
    table_id    TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    round_index INTEGER NOT NULL,
    hand        INTEGER NOT NULL,   -- hand number the pot was won at
    amount      INTEGER NOT NULL,
    winners     TEXT    NOT NULL,   -- JSON array of names, a split pot has several
    description TEXT    NOT NULL DEFAULT '',  -- winning hand, '' when uncontested
    PRIMARY KEY (table_id, round_index)
);
