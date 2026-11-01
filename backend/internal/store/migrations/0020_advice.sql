-- The host's switch for the advice a player can ask for on their turn.
-- On for existing tables: the instance-wide PLAYER_ADVICE is what turns the
-- help off outright, and a host who wants it off at their table says so.
ALTER TABLE table_settings ADD COLUMN allow_advice INTEGER NOT NULL DEFAULT 1;
