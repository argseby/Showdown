-- Time bank refill per hand played without using the bank.
ALTER TABLE table_settings ADD COLUMN time_bank_refill_seconds INTEGER NOT NULL DEFAULT 1;
