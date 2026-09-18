-- The pencil drawings switch.
ALTER TABLE table_settings ADD COLUMN allow_drawing INTEGER NOT NULL DEFAULT 1;
