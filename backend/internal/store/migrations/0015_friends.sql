-- 0015_friends: friendships between profiles, the requests that make them,
-- the blocks that stop them, and the invitations one friend sends another
-- to a table. All of it is optional in the same way profiles are: an
-- instance with ACCOUNTS off never writes a row here.

-- A friendship is stored in both directions, so "my friends" is one index
-- lookup and never a union of two queries.
CREATE TABLE friends (
    account_id TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    friend_id  TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (account_id, friend_id)
);
CREATE INDEX friends_friend_idx ON friends(friend_id);

-- One pending ask, from one profile to another. Answering it removes the
-- row: accepted rows become a friendship, declined ones leave no trace
-- beyond a block, if the answer was a block.
CREATE TABLE friend_requests (
    from_id    TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    to_id      TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (from_id, to_id)
);
CREATE INDEX friend_requests_to_idx ON friend_requests(to_id);

-- Blocks are one-way and silent: the blocked profile is not told, cannot
-- ask again, and stops seeing anything the block owner shares with friends.
CREATE TABLE friend_blocks (
    account_id TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    blocked_id TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (account_id, blocked_id)
);

-- An invitation to a table. It is kept rather than only pushed, so someone
-- who was away still finds it when they come back; expires_at keeps the
-- table from filling up with dead links.
CREATE TABLE table_invites (
    id         TEXT    PRIMARY KEY,
    table_id   TEXT    NOT NULL,
    table_name TEXT    NOT NULL,
    from_id    TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    to_id      TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);
CREATE INDEX table_invites_to_idx ON table_invites(to_id, expires_at);
