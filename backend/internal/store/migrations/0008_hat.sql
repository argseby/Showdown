-- Hats: a cosmetic worn on the avatar (one of protocol.Hats, '' = none).
ALTER TABLE players ADD COLUMN hat TEXT NOT NULL DEFAULT '';
