-- 0022_revoked_now_playing: the table a player is at, kept in their own
-- revoked vault.
--
-- Signing in with revoked tells this instance who somebody is. This is the
-- other direction: the player connects this instance to their vault as a
-- tool, it gets a section of its own there, and it keeps one entry in it
-- saying where they are playing. A share over that entry resolves at read
-- time, so one link, pasted wherever the player likes, always points at
-- the table they are at now -- and stops the moment they revoke it.
--
-- One row per profile: a profile has one vault. Nothing here is written
-- unless the player asked for it, and REVOKED_NOW_PLAYING off never
-- writes at all.
CREATE TABLE account_revoked_links (
    account_id    TEXT    PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    -- The revoked server holding the vault, as an origin with no trailing
    -- slash. It is always one of this profile's account_identities: the
    -- vault we write to is a server this profile already signs in with.
    server        TEXT    NOT NULL,
    -- The connection as the server named it, and the token this instance
    -- sends as X-Revoked-Connection. The token is a narrow capability --
    -- write this instance's own section, manage the shares it made -- and
    -- nothing else; it is not a session and cannot read the vault.
    connection_id TEXT    NOT NULL,
    token         TEXT    NOT NULL,
    -- The section the player gave this instance, the entry it keeps there,
    -- and the share over it. link_url is kept because the server hands it
    -- over once, when the share is created, and never again.
    section       TEXT    NOT NULL DEFAULT '',
    record_id     TEXT    NOT NULL DEFAULT '',
    record_key    TEXT    NOT NULL DEFAULT '',
    link_id       TEXT    NOT NULL DEFAULT '',
    link_url      TEXT    NOT NULL DEFAULT '',
    -- What was last written, so a player who has not moved costs their
    -- server no request at all.
    published     TEXT    NOT NULL DEFAULT '',
    -- Why this connection stopped working, in the server's own words:
    -- 'paused' while the player paused the tool, 'expired' or 'gone'
    -- once the token is of no further use. Empty while all is well.
    trouble       TEXT    NOT NULL DEFAULT '',
    created_at    INTEGER NOT NULL,
    -- When the connection lapses: 90 days after the player last connected
    -- it, which only they can renew, from the app.
    expires_at    INTEGER NOT NULL,
    updated_at    INTEGER NOT NULL
);
