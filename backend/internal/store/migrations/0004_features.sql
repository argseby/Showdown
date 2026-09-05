-- Avatars, rabbit hunting and the blind schedule (owner feature batch).
ALTER TABLE players ADD COLUMN avatar INTEGER NOT NULL DEFAULT 0;
ALTER TABLE table_settings ADD COLUMN allow_rabbit_hunt INTEGER NOT NULL DEFAULT 1;
ALTER TABLE table_settings ADD COLUMN blinds_up_minutes INTEGER NOT NULL DEFAULT 0;
ALTER TABLE table_settings ADD COLUMN blinds_up_percent INTEGER NOT NULL DEFAULT 100;
