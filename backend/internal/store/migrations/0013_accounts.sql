-- 0013_accounts: optional player profiles. A profile is only ever an
-- addition: guests keep playing with no account at all, and an instance
-- that leaves ACCOUNTS off never writes a row here.

CREATE TABLE accounts (
    -- Opaque and permanent: friendships, results and achievements point
    -- here, so a handle can be changed later without touching them.
    id            TEXT    PRIMARY KEY,
    handle        TEXT    NOT NULL,
    -- handle_key is the folded form (see internal/account.Key): two
    -- handles that look alike cannot both exist.
    handle_key    TEXT    NOT NULL UNIQUE,
    display_name  TEXT    NOT NULL,
    password_hash TEXT    NOT NULL,
    -- The one code handed out at sign-up, hashed like a session token.
    recovery_hash TEXT    NOT NULL,
    created_at    INTEGER NOT NULL,
    -- Who may see what: 'private', 'friends' or 'public'. Friends do not
    -- exist yet; the value does, so adding them later moves no data.
    vis_profile      TEXT NOT NULL DEFAULT 'private',
    vis_winnings     TEXT NOT NULL DEFAULT 'private',
    vis_best_hands   TEXT NOT NULL DEFAULT 'private',
    vis_achievements TEXT NOT NULL DEFAULT 'private',
    vis_activity     TEXT NOT NULL DEFAULT 'private'
);

-- Profile sessions are their own thing: a table session belongs to a table
-- and dies with it, this one outlives every table the player sits at.
CREATE TABLE account_sessions (
    token_hash TEXT    PRIMARY KEY,          -- SHA-256 of the token, hex
    account_id TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);
CREATE INDEX account_sessions_account_idx ON account_sessions(account_id);

-- The seat's link to a profile ('' = a guest, which stays the default).
-- The handle rides along so a seat keeps its badge across a restart
-- without a lookup; it is the name that sat there, at that table.
ALTER TABLE players ADD COLUMN account_id TEXT NOT NULL DEFAULT '';
ALTER TABLE players ADD COLUMN account_handle TEXT NOT NULL DEFAULT '';
CREATE INDEX players_account_idx ON players(account_id);
