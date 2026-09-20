-- A seat taken by a program rather than a person, so the table can say so.
-- Self-declared on joining: the bots that ship with Showdown set it, and
-- nothing stops a client from lying either way.
ALTER TABLE players ADD COLUMN bot INTEGER NOT NULL DEFAULT 0;
