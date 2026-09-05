import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../shared/kbd_hint.dart';
import '../shortcuts.dart';

/// The `?` overlay listing every shortcut of [shortcutBindings].
Future<void> showShortcutsOverlay(BuildContext context) {
  final l10n = context.l10n;
  final rows = <(String, String)>[
    (shortcutLabel(ShortcutAction.fold), l10n.scFold),
    (shortcutLabel(ShortcutAction.checkCall), l10n.scCheckCall),
    (shortcutLabel(ShortcutAction.openRaise), l10n.scOpenRaise),
    (shortcutLabel(ShortcutAction.selectAllIn), l10n.scAllIn),
    ('1 2 3 4', l10n.scPresets),
    ('Up Down', l10n.scAmount),
    (shortcutLabel(ShortcutAction.confirm), l10n.scConfirm),
    (shortcutLabel(ShortcutAction.cancel), l10n.scCancel),
    (shortcutLabel(ShortcutAction.focusChat), l10n.scChat),
    (shortcutLabel(ShortcutAction.toggleLog), l10n.scLog),
    (shortcutLabel(ShortcutAction.toggleLeaderboard), l10n.scLeaderboard),
    (shortcutLabel(ShortcutAction.toggleSound), l10n.scSound),
    (shortcutLabel(ShortcutAction.showHelp), l10n.scHelp),
  ];
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (context) => AlertDialog(
      title: Text(l10n.shortcutsTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (key, desc) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Wrap(
                        spacing: 4,
                        children: [for (final k in key.split(' ')) KbdHint(k)],
                      ),
                    ),
                    Expanded(child: Text(desc)),
                  ],
                ),
              ),
            const Gap(12),
            Text(l10n.shortcutsHint).muted().small(),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    ),
  ).future;
}
