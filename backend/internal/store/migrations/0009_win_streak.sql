-- Running hot: hands won in a row, shown as a fire ring on the seat.
ALTER TABLE players ADD COLUMN win_streak INTEGER NOT NULL DEFAULT 0;
