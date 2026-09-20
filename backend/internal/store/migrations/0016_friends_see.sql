-- 0016_friends_see: a profile's record is for friends by default.
--
-- The sections started out private, from before friends existed: with
-- nobody to share with, private was the only honest default. Now that a
-- friend can be asked and answered, seeing what a friend has been up to is
-- the point of having one — the public still sees nothing until the owner
-- says otherwise.
--
-- Only profiles that never made a choice move: all five still private is
-- the old default, untouched. The column defaults in 0013 stay as they
-- are; nothing relies on them, because a profile is always written with
-- all five values set.

UPDATE accounts
SET vis_profile      = 'friends',
    vis_winnings     = 'friends',
    vis_best_hands   = 'friends',
    vis_achievements = 'friends',
    vis_activity     = 'friends'
WHERE vis_profile = 'private'
  AND vis_winnings = 'private'
  AND vis_best_hands = 'private'
  AND vis_achievements = 'private'
  AND vis_activity = 'private';
