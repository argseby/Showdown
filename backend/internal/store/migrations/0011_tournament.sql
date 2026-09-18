-- Tournament mode: locks money and information settings once started.
ALTER TABLE table_settings ADD COLUMN tournament INTEGER NOT NULL DEFAULT 0;
