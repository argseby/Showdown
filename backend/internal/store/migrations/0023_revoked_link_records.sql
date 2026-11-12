-- 0023_revoked_link_records: which entries the share actually grants.
--
-- 0022 shared the section this instance was given and assumed its entries
-- came with it. They do not: a share serves the records it names, and a
-- section on a link only groups them -- so the first links made this way
-- resolved to nothing at all. The entry ids now go on the link itself,
-- and this column records which ones, so a link that grants the wrong set
-- -- an empty one, from before this was understood -- is replaced with
-- one that grants the right set the next time the publisher looks.
ALTER TABLE account_revoked_links ADD COLUMN link_records TEXT NOT NULL DEFAULT '';
