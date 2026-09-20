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

/// What one of the three values is called.
String visibilityValueLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'public' => l10n.visPublic,
      'friends' => l10n.visFriendsOnly,
      _ => l10n.visPrivate,
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
  /// The section currently being saved, so its control stays put until the
  /// server has answered.
  String? _saving;
  String? _error;

  Future<void> _set(String section, String value) async {
    setState(() {
      _saving = section;
      _error = null;
    });
    try {
      await ref.read(accountProvider.notifier).setVisibility(section, value);
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
    final allPrivate = visibility.values.every((v) => v == 'private');

    return AlertDialog(
      title: Text(l10n.visTitle),
      content: SizedBox(
        width: 400,
        // Five sections and three choices each: on a short screen this
        // scrolls rather than pushing the buttons off the bottom.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.visBody).muted().small(),
                const Gap(12),
                VisibilitySections(
                  value: visibility,
                  enabled: _saving == null,
                  onPick: _set,
                ),
                if (allPrivate) ...[
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

/// The five sections and their three states, as one list. The dialog
/// saves each pick on its own; signing up collects them and sends one
/// change at the end.
class VisibilitySections extends StatelessWidget {
  const VisibilitySections({
    super.key,
    required this.value,
    required this.onPick,
    this.enabled = true,
  });

  final Map<String, String> value;
  final void Function(String section, String value) onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in visibilitySections)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
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
                _Choice(
                  section: section,
                  value: value[section] ?? 'friends',
                  enabled: enabled,
                  onPick: (v) => onPick(section, v),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The three states of one section, side by side: no popup to open, and
/// the current one is always the one that looks chosen.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.section,
    required this.value,
    required this.enabled,
    required this.onPick,
  });

  final String section;
  final String value;
  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in const ['private', 'friends', 'public'])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: (v == value ? PrimaryButton.new : GhostButton.new)(
              key: Key('vis-$section-$v'),
              size: ButtonSize.small,
              enabled: enabled,
              onPressed: () {
                if (v != value) onPick(v);
              },
              child: Text(visibilityValueLabel(l10n, v)).xSmall(),
            ),
          ),
      ],
    );
  }
}
