-- Game variant: holdem (52 cards) or royal (Ten to Ace only).
ALTER TABLE table_settings ADD COLUMN variant TEXT NOT NULL DEFAULT 'holdem';
