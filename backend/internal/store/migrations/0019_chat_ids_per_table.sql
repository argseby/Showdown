-- 0019_chat_ids_per_table: a chat id belongs to its table.
--
-- The column was a global AUTOINCREMENT key while the table actor numbers
-- its own messages from one, so the first message of the second table to
-- ever speak collided with the first message of the first, and every
-- message after it was dropped by the persister. Live chat still worked —
-- it is broadcast before it is written — so the loss only showed up as a
-- restart with no history, or the "hand was voided" line vanishing.
--
-- Everything else already treats the id as per-table: the actor's counter,
-- the recent-chat query, and the moderation delete, which has always been
-- scoped by table_id.

CREATE TABLE chat_messages_new (
    id          INTEGER NOT NULL,
    table_id    TEXT    NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    author_kind TEXT    NOT NULL,            -- player | spectator | admin | system
    author_name TEXT    NOT NULL,
    text        TEXT    NOT NULL,
    ts          INTEGER NOT NULL,
    PRIMARY KEY (table_id, id)
);

INSERT INTO chat_messages_new (id, table_id, author_kind, author_name, text, ts)
SELECT id, table_id, author_kind, author_name, text, ts FROM chat_messages;

DROP TABLE chat_messages;
ALTER TABLE chat_messages_new RENAME TO chat_messages;
