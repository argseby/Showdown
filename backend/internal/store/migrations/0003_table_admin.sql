-- Table-scoped administration: the creator of a table manages it with an
-- admin token whose SHA-256 is stored with the table. There is no global
-- admin and no global leaderboard any more; per-table results live in the
-- players table.
ALTER TABLE tables ADD COLUMN admin_token_hash TEXT NOT NULL DEFAULT '';
DROP INDEX IF EXISTS player_results_name_idx;
DROP INDEX IF EXISTS player_results_table_idx;
DROP TABLE IF EXISTS player_results;
