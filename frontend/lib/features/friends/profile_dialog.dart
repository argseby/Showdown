import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../core/friends.dart';
import '../../core/rest_client.dart';
import '../../shared/pot_colors.dart';
import '../account/stats_dialog.dart';

/// Another player's profile, as far as they share it. A profile shared
/// with nobody is not there at all — the same answer as for a name that
/// was never taken, so this cannot be used to find out who exists.
Future<void> showProfileDialog(BuildContext context, String handle) =>
    showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (context) => ProfileDialog(handle: handle),
    ).future;

class ProfileDialog extends ConsumerStatefulWidget {
  const ProfileDialog({super.key, required this.handle});

  final String handle;

  @override
  ConsumerState<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<ProfileDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _ask(PublicProfile profile) async {
    final token = ref.read(accountProvider.notifier).token;
    if (token == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(friendsApiProvider).request(token, profile.handle);
      ref.invalidate(friendsProvider);
      ref.invalidate(profileProvider(widget.handle));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final async = ref.watch(profileProvider(widget.handle));

    Widget body;
    switch (async) {
      case AsyncLoading():
        body = const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      case AsyncError():
        body = Text(l10n.errGeneric('')).muted().small();
      case AsyncData(:final value):
        final p = value;
        if (p == null) {
          body = SizedBox(
            height: 100,
            child: Center(
              child: Text(
                l10n.profilePrivate,
                key: const Key('profile-private'),
              ).muted(),
            ),
          );
          break;
        }
        body = _sections(p, locale);
    }

    final profile = async.value;
    return AlertDialog(
      title: Text(profile == null ? l10n.profileTitle : profile.displayName),
      content: SizedBox(width: 420, child: body),
      actions: [
        if (profile != null && !profile.you && accountsFriendable(profile))
          OutlineButton(
            key: const Key('profile-add-friend'),
            enabled: !_busy,
            onPressed: () => _ask(profile),
            leading: const Icon(LucideIcons.userPlus, size: 14),
            child: Text(l10n.friendsAdd),
          ),
        PrimaryButton(
          key: const Key('profile-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  /// Whether the "add friend" button makes sense: not already friends and
  /// not already asked.
  bool accountsFriendable(PublicProfile p) => p.relation == Relation.none;

  Widget _sections(PublicProfile p, String locale) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.atSign, size: 14),
            const Gap(4),
            Text(p.handle).muted().small(),
            const Spacer(),
            if (p.relation == Relation.friend)
              Text(l10n.friendsTabAll).muted().xSmall(),
          ],
        ),
        if (p.since > 0)
          Text(l10n.profileSince(formatDate(p.since, locale))).muted().xSmall(),
        if (_error != null) ...[
          const Gap(8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.destructive),
          ).small(),
        ],
        if (p.winnings == null)
          _notShared(LucideIcons.coins, l10n.profileWinnings, p),
        if (p.winnings case final w?) ...[
          const Gap(14),
          _heading(LucideIcons.coins, l10n.profileWinnings),
          _row(l10n.statsHands, '${w.hands}'),
          _row(
            l10n.statsNet,
            (w.net > 0 ? '+' : '') + formatChips(w.net, locale),
            color: w.net == 0
                ? null
                : w.net > 0
                ? potGold
                : Theme.of(context).colorScheme.destructive,
          ),
          _row(
            l10n.statsPer100,
            '${w.bbPer100 > 0 ? '+' : ''}${w.bbPer100.toStringAsFixed(1)} bb',
          ),
          if (w.roundsWon > 0) _row(l10n.statsRoundsWon, '${w.roundsWon}'),
          if (w.podiums > 0) _row(l10n.statsPodiums, '${w.podiums}'),
          Text(l10n.profileCountedOnly).muted().xSmall(),
        ],
        if (p.bestHands == null)
          _notShared(LucideIcons.crown, l10n.profileBestHands, p),
        if (p.bestHands case final hands? when hands.isNotEmpty) ...[
          const Gap(14),
          _heading(LucideIcons.crown, l10n.profileBestHands),
          for (final h in hands.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          h.description.isNotEmpty
                              ? h.description
                              : handClassName(l10n, h.category, royal: h.royal),
                          overflow: TextOverflow.ellipsis,
                        ).small(),
                        Text(
                          prettyCards(h.cards),
                          style: const TextStyle(
                            fontFamily: 'GeistMono',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  Text(formatDate(h.endedAt, locale)).muted().xSmall(),
                ],
              ),
            ),
        ],
        if (p.achievements == null)
          _notShared(LucideIcons.award, l10n.profileAwards, p),
        if (p.achievements case final awards? when awards.isNotEmpty) ...[
          const Gap(14),
          _heading(LucideIcons.award, l10n.profileAwards),
          for (final a in awards)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(LucideIcons.badgeCheck, size: 14, color: potGold),
                  const Gap(6),
                  Expanded(child: Text(achievementTitle(l10n, a.id)).small()),
                  Text(formatDate(a.earnedAt, locale)).muted().xSmall(),
                ],
              ),
            ),
        ],
        if (p.lastHand == null)
          _notShared(LucideIcons.activity, l10n.profileActivity, p),
        if (p.lastHand != null) ...[
          const Gap(14),
          _heading(LucideIcons.activity, l10n.profileActivity),
          if (p.lastHand! > 0)
            _row(l10n.profileLastHand, formatDate(p.lastHand!, locale)),
          if ((p.playingAt ?? '').isNotEmpty)
            Text(l10n.profilePlayingNow).muted().small(),
        ],
      ],
    );
  }

  /// A section its owner keeps to themselves. It is named rather than
  /// left out: an empty space says nothing, and "not shared" says the
  /// profile is fine and the section is theirs.
  Widget _notShared(IconData icon, String title, PublicProfile p) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _heading(icon, title),
        Row(
          children: [
            Icon(
              LucideIcons.lock,
              size: 11,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
            const Gap(6),
            Flexible(
              child: Text(context.l10n.profileNotSharedHint(p.displayName))
                  .muted()
                  .xSmall(),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _heading(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Theme.of(context).colorScheme.mutedForeground,
        ),
        const Gap(6),
        Text(title.toUpperCase()).muted().xSmall().semiBold(),
      ],
    ),
  );

  Widget _row(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label).muted().small()),
        const Gap(8),
        Text(
          value,
          style: TextStyle(fontFamily: 'GeistMono', color: color),
        ),
      ],
    ),
  );
}
