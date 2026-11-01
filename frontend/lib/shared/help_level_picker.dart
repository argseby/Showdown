import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/l10n.dart';
import '../app/preferences.dart';

/// The one control for everything the table does to help a player learn
/// the game, asked as a question about them rather than about switches:
/// how much poker they have played. Each answer is a preset of the
/// switches underneath it, so this never disagrees with the table.
class HelpLevelPicker extends StatelessWidget {
  const HelpLevelPicker({
    super.key,
    required this.level,
    required this.onChanged,
    this.compact = false,
  });

  final HelpLevel level;
  final ValueChanged<HelpLevel> onChanged;

  /// In the join form the description carries the explaining; the settings
  /// tab has its own text above it.
  final bool compact;

  /// Most help first: someone who needs it should not have to read past
  /// three answers that are not theirs.
  static const order = [
    HelpLevel.full,
    HelpLevel.cards,
    HelpLevel.hand,
    HelpLevel.none,
  ];

  static String label(AppLocalizations l10n, HelpLevel level) =>
      switch (level) {
        HelpLevel.full => l10n.helpLevelFull,
        HelpLevel.cards => l10n.helpLevelCards,
        HelpLevel.hand => l10n.helpLevelHand,
        HelpLevel.none => l10n.helpLevelNone,
        HelpLevel.custom => l10n.helpLevelCustom,
      };

  static String about(AppLocalizations l10n, HelpLevel level) =>
      switch (level) {
        HelpLevel.full => l10n.helpFullAbout,
        HelpLevel.cards => l10n.helpCardsAbout,
        HelpLevel.hand => l10n.helpHandAbout,
        HelpLevel.none => l10n.helpNoneAbout,
        HelpLevel.custom => l10n.helpCustomAbout,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in order)
              if (option == level)
                // The answer already showing is still an answer: pressing
                // it confirms, which is what closes the question on the
                // join form for a player the default already suited.
                PrimaryButton(
                  key: Key('help-level-${option.name}'),
                  size: ButtonSize.small,
                  onPressed: () => onChanged(option),
                  child: Text(label(l10n, option)),
                )
              else
                OutlineButton(
                  key: Key('help-level-${option.name}'),
                  size: ButtonSize.small,
                  onPressed: () => onChanged(option),
                  child: Text(label(l10n, option)),
                ),
          ],
        ),
        const Gap(6),
        Text(
          about(l10n, level),
          key: const Key('help-level-about'),
        ).muted().xSmall(),
        if (!compact) ...[
          const Gap(2),
          Text(l10n.helpChangeLater).muted().xSmall(),
        ],
      ],
    );
  }
}
