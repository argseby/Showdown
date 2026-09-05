import '../app/l10n.dart';

/// The quick phrases of the protocol, in display order.
const phraseKeys = [
  'nice_hand',
  'nice_call',
  'nice_fold',
  'nice_bluff',
  'well_played',
  'gg',
  'thanks',
  'sorry',
  'wow',
  'oops',
  'furious',
  'lol',
  'hurry_up',
  'brb',
];

/// Translated text of a phrase key (the key itself when unknown).
String phraseLabel(AppLocalizations l10n, String key) => switch (key) {
  'nice_hand' => l10n.phraseNiceHand,
  'nice_call' => l10n.phraseNiceCall,
  'nice_fold' => l10n.phraseNiceFold,
  'nice_bluff' => l10n.phraseNiceBluff,
  'well_played' => l10n.phraseWellPlayed,
  'gg' => l10n.phraseGg,
  'thanks' => l10n.phraseThanks,
  'sorry' => l10n.phraseSorry,
  'wow' => l10n.phraseWow,
  'oops' => l10n.phraseOops,
  'furious' => l10n.phraseFurious,
  'lol' => l10n.phraseLol,
  'hurry_up' => l10n.phraseHurryUp,
  'brb' => l10n.phraseBrb,
  _ => key,
};
