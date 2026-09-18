import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/gamepad/gamepad.dart';
import '../../../shared/kbd_hint.dart';
import '../shortcuts.dart';

/// The `?` overlay listing every shortcut of [shortcutBindings], with the
/// controller buttons next to them while a controller is connected.
Future<void> showShortcutsOverlay(BuildContext context) {
  final l10n = context.l10n;
  final rows = <(String, String?, String)>[
    (
      shortcutLabel(ShortcutAction.fold),
      padLabel(ShortcutAction.fold),
      l10n.scFold,
    ),
    (
      shortcutLabel(ShortcutAction.checkCall),
      padLabel(ShortcutAction.checkCall),
      l10n.scCheckCall,
    ),
    (
      shortcutLabel(ShortcutAction.openRaise),
      padLabel(ShortcutAction.openRaise),
      l10n.scOpenRaise,
    ),
    (shortcutLabel(ShortcutAction.focusAmount), null, l10n.scFocusAmount),
    (
      shortcutLabel(ShortcutAction.selectAllIn),
      padLabel(ShortcutAction.selectAllIn),
      l10n.scAllIn,
    ),
    ('1 2 3 4', '← →', l10n.scPresets),
    ('Up Down', '↑ ↓ LB RB', l10n.scAmount),
    (
      shortcutLabel(ShortcutAction.confirm),
      padLabel(ShortcutAction.confirm),
      l10n.scConfirm,
    ),
    (
      shortcutLabel(ShortcutAction.cancel),
      padLabel(ShortcutAction.cancel),
      l10n.scCancel,
    ),
    (shortcutLabel(ShortcutAction.focusChat), null, l10n.scChat),
    (
      shortcutLabel(ShortcutAction.toggleLog),
      padLabel(ShortcutAction.toggleLog),
      l10n.scLog,
    ),
    (
      shortcutLabel(ShortcutAction.toggleLeaderboard),
      padLabel(ShortcutAction.toggleLeaderboard),
      l10n.scLeaderboard,
    ),
    (shortcutLabel(ShortcutAction.toggleSound), null, l10n.scSound),
    (
      shortcutLabel(ShortcutAction.showHelp),
      padLabel(ShortcutAction.showHelp),
      l10n.scHelp,
    ),
    ('', '${PadButton.lb.label} ${PadButton.rb.label}', l10n.scSections),
    ('', PadButton.back.label, l10n.scSettingsPanel),
  ];
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final padOn = ref.watch(gamepadProvider);
        return AlertDialog(
          title: Text(l10n.shortcutsTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (key, pad, desc) in rows)
                    // Rows without a key exist for the controller only.
                    if (key.isNotEmpty || padOn)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Wrap(
                                spacing: 4,
                                children: [
                                  for (final k in key.split(' '))
                                    if (k.isNotEmpty) KbdHint(k),
                                ],
                              ),
                            ),
                            if (padOn)
                              SizedBox(
                                width: 84,
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    for (final k in (pad ?? '').split(' '))
                                      if (k.isNotEmpty) KbdHint('', pad: k),
                                  ],
                                ),
                              ),
                            Expanded(child: Text(desc)),
                          ],
                        ),
                      ),
                  const Gap(12),
                  Text(l10n.shortcutsHint).muted().small(),
                  if (padOn) ...[
                    const Gap(6),
                    Text(l10n.shortcutsPadHint).muted().small(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            PrimaryButton(
              key: const Key('shortcuts-close'),
              onPressed: () => closeOverlay<void>(context),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    ),
  ).future;
}
