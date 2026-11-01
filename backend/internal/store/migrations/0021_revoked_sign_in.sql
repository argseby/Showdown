-- 0021_revoked_sign_in: sign in with a revoked identity instead of a
-- password. A profile is still a profile: nothing below changes what a
-- guest can do, and an instance with REVOKED_SIGN_IN off never writes here.

-- One row per (issuer, subject). The subject is pairwise, so the same
-- person at the same revoked server is one row no matter how often they
-- sign in, and the same person at a different server is somebody else
-- until they link it themselves.
CREATE TABLE account_identities (
    -- The revoked server that vouched for this person, as the issuer
    -- its discovery document names: an origin, no trailing slash.
    issuer     TEXT    NOT NULL,
    -- The "sub" claim. Pairwise, so it means nothing anywhere else.
    subject    TEXT    NOT NULL,
    account_id TEXT    NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    -- What the person last let us see, kept only to show which account a
    -- profile is linked to. Empty when the scope was declined.
    name       TEXT    NOT NULL DEFAULT '',
    PRIMARY KEY (issuer, subject)
);
CREATE INDEX account_identities_account_idx ON account_identities(account_id);

-- A profile that only ever signs in through revoked has no password and no
-- recovery code: both columns stay '' and internal/server refuses a
-- password sign-in for such a row. Existing profiles are untouched.
