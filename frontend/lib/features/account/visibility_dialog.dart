import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/rest_client.dart';

/// Who may see which part of a profile. Everything starts private; the
/// owner decides, one section at a time.
Future<void> showVisibilityDialog(BuildContext context) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => const VisibilityDialog(),
).future;

/// The sections, in the order the dialog lists them. The keys are the ones
/// the server stores.
const visibilitySections = [
  'profile',
  'winnings',
  'best_hands',
  'achievements',
  'activity',
];

String visibilityTitle(AppLocalizations l10n, String section) =>
    switch (section) {
      'profile' => l10n.visProfile,
      'winnings' => l10n.visWinnings,
      'best_hands' => l10n.visBestHands,
      'achievements' => l10n.visAchievements,
      _ => l10n.visActivity,
    };

String visibilityHint(AppLocalizations l10n, String section) =>
    switch (section) {
      'profile' => l10n.visProfileHint,
      'winnings' => l10n.visWinningsHint,
      'best_hands' => l10n.visBestHandsHint,
      'achievements' => l10n.visAchievementsHint,
      _ => l10n.visActivityHint,
    };

class VisibilityDialog extends ConsumerStatefulWidget {
  const VisibilityDialog({super.key});

  @override
  ConsumerState<VisibilityDialog> createState() => _VisibilityDialogState();
}

class _VisibilityDialogState extends ConsumerState<VisibilityDialog> {
  /// The section currently being saved, so its switch stays put until the
  /// server has answered.
  String? _saving;
  String? _error;

  Future<void> _set(String section, bool public) async {
    setState(() {
      _saving = section;
      _error = null;
    });
    try {
      await ref
          .read(accountProvider.notifier)
          .setVisibility(section, public ? 'public' : 'private');
    } on ApiException {
      if (mounted) setState(() => _error = context.l10n.visSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = ref.watch(accountProvider).value;
    final visibility = account?.visibility ?? const {};
    final anyPublic = visibility.values.any((v) => v == 'public');

    return AlertDialog(
      title: Text(l10n.visTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.visBody).muted().small(),
            const Gap(12),
            for (final section in visibilitySections)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(visibilityTitle(l10n, section)).small(),
                          Text(visibilityHint(l10n, section)).muted().xSmall(),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Text(
                      visibility[section] == 'public'
                          ? l10n.visPublic
                          : l10n.visPrivate,
                    ).muted().xSmall(),
                    const Gap(8),
                    Switch(
                      key: Key('vis-$section'),
                      value: visibility[section] == 'public',
                      onChanged: _saving == null
                          ? (v) => _set(section, v)
                          : null,
                    ),
                  ],
                ),
              ),
            if (!anyPublic) ...[
              const Gap(8),
              Text(l10n.visAllPrivate).muted().xSmall(),
            ],
            if (_error != null) ...[
              const Gap(8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.destructive),
              ).small(),
            ],
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('vis-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
