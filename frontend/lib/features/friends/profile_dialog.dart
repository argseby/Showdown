import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../core/friends.dart';
import '../../core/rest_client.dart';
import '../account/stats_parts.dart';

/// Another player's record, as far as they share it: the same page as your
/// own statistics — the same tabs, the same figures in the same places —
/// with the sections they keep to themselves marked as such rather than
/// left out.
///
/// A profile shared with nobody is not there at all: the same answer as
/// for a name that was never taken, so this cannot be used to find out who
/// exists.
Future<void> showProfileDialog(BuildContext context, String handle) =>
    showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (context) => ProfileDialog(handle: handle),
    ).future;

/// The pages of somebody else's record.
enum ProfileTab { overview, hands, awards }

class ProfileDialog extends ConsumerStatefulWidget {
  const ProfileDialog({super.key, required this.handle});

  final String handle;

  @override
  ConsumerState<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<ProfileDialog> {
  ProfileTab _tab = ProfileTab.overview;
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
    final async = ref.watch(profileProvider(widget.handle));

    Widget body;
    switch (async) {
      case AsyncLoading():
        body = const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        );
      case AsyncError():
        body = Text(l10n.errGeneric('')).muted().small();
      case AsyncData(:final value):
        final p = value;
        if (p == null) {
          body = SizedBox(
            height: 140,
            child: Center(
              child: Text(
                l10n.profilePrivate,
                key: const Key('profile-private'),
                textAlign: TextAlign.center,
              ).muted(),
            ),
          );
          break;
        }
        body = _record(p);
    }

    final profile = async.value;
    return AlertDialog(
      title: Text(profile == null ? l10n.profileTitle : profile.displayName),
      content: SizedBox(width: 470, child: body),
      actions: [
        if (profile != null &&
            !profile.you &&
            profile.relation == Relation.none)
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

  Widget _record(PublicProfile p) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.atSign, size: 14),
            const Gap(4),
            Text(p.handle).muted().small(),
            const Spacer(),
            if (p.relation == Relation.friend)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.users, size: 12),
                  const Gap(4),
                  Text(l10n.friendsTabAll).muted().xSmall(),
                ],
              ),
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
        const Gap(12),
        Tabs(
          index: _tab.index,
          onChanged: (i) => setState(() => _tab = ProfileTab.values[i]),
          expand: true,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          children: [
            _tabItem(
              const Key('profile-tab-overview'),
              LucideIcons.layoutDashboard,
              l10n.statsTabOverview,
            ),
            _tabItem(
              const Key('profile-tab-hands'),
              LucideIcons.spade,
              l10n.statsTabHands,
            ),
            _tabItem(
              const Key('profile-tab-awards'),
              LucideIcons.award,
              l10n.statsTabAwards,
            ),
          ],
        ),
        const Gap(14),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: SingleChildScrollView(
            child: switch (_tab) {
              ProfileTab.overview => _overview(p, locale),
              ProfileTab.hands => _hands(p),
              ProfileTab.awards => _awards(p),
            },
          ),
        ),
      ],
    );
  }

  Widget _overview(PublicProfile p, String locale) {
    final l10n = context.l10n;
    final w = p.winnings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (w == null)
          _notShared(LucideIcons.coins, l10n.profileWinnings, p)
        else ...[
          NetHero(net: w.net, caption: l10n.profileOverHands('${w.hands}')),
          const Gap(14),
          StatsGroup(
            icon: LucideIcons.coins,
            title: l10n.profileWinnings,
            rows: [
              StatsRow(l10n.statsHands, '${w.hands}'),
              StatsRow(
                l10n.statsNetBB,
                bbText(w.netBB),
                color: moneyColor(context, w.netBB),
              ),
              StatsRow(l10n.statsPer100, bbText(w.bbPer100)),
              if (w.roundsWon > 0)
                StatsRow(l10n.statsRoundsWon, '${w.roundsWon}'),
              if (w.podiums > 0) StatsRow(l10n.statsPodiums, '${w.podiums}'),
            ],
          ),
        ],
        const Gap(14),
        if (p.lastHand == null)
          _notShared(LucideIcons.activity, l10n.profileActivity, p)
        else
          StatsGroup(
            icon: LucideIcons.activity,
            title: l10n.profileActivity,
            rows: [
              if (p.lastHand! > 0)
                StatsRow(l10n.profileLastHand, formatDate(p.lastHand!, locale)),
              if ((p.playingAt ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(l10n.profilePlayingNow).muted().small(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _hands(PublicProfile p) {
    final l10n = context.l10n;
    final hands = p.bestHands;
    if (hands == null) {
      return _notShared(LucideIcons.crown, l10n.profileBestHands, p);
    }
    if (hands.isEmpty) return Text(l10n.statsNoHandsYet).muted().small();
    return StatsGroup(
      icon: LucideIcons.crown,
      title: l10n.profileBestHands,
      rows: [for (final h in hands) HandCard(h)],
    );
  }

  Widget _awards(PublicProfile p) {
    final l10n = context.l10n;
    final awards = p.achievements;
    if (awards == null) {
      return _notShared(LucideIcons.award, l10n.profileAwards, p);
    }
    if (awards.isEmpty) return Text(l10n.statsNoAwardsYet).muted().small();
    return StatsGroup(
      icon: LucideIcons.award,
      title: l10n.profileAwards,
      rows: [for (final a in awards) AwardRow(a, earned: true)],
    );
  }

  /// A section its owner keeps to themselves. It is named rather than left
  /// out: an empty space says nothing, and "not shared" says the profile
  /// is fine and the section is theirs.
  Widget _notShared(IconData icon, String title, PublicProfile p) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.mutedForeground),
              const Gap(6),
              Text(title.toUpperCase()).muted().xSmall().semiBold(),
            ],
          ),
        ),
        Row(
          children: [
            Icon(
              LucideIcons.lock,
              size: 11,
              color: theme.colorScheme.mutedForeground,
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
    );
  }

  TabItem _tabItem(Key key, IconData icon, String label) => TabItem(
    key: key,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13),
        const Gap(5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis).small()),
      ],
    ),
  );
}
