-- 0018_every_hand_counts: every hand played is a hand played.
--
-- Rows used to carry a `counted` flag: a hand only stood in a public total
-- when three or more profiles were dealt in and nobody had been handed
-- chips. It was meant to stop three friends arranging a number, but it
-- also threw away every heads-up game, every game with a bot in it, and
-- every table where the host topped somebody up — which is most of the
-- poker people actually play here. A record that leaves out most of your
-- play is worse than one that can be gamed by somebody determined to.
--
-- `profiles` stays on hand_results: it says how many signed-in players
-- were dealt in, which is worth knowing even though nothing gates on it.

ALTER TABLE hand_results DROP COLUMN counted;
ALTER TABLE round_results DROP COLUMN counted;
