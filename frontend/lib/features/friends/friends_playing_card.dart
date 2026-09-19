import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/friends.dart';
import '../../core/providers.dart';
import 'friends_dialog.dart';

/// How often the home screen looks again by itself. The socket says when a
/// friend sits down; nobody is told when one gets up, so a slow refresh
/// keeps the list from going stale.
const friendsPlayingRefresh = Duration(seconds: 30);

/// The tables friends are at right now, with the way in. Nothing at all
/// when this instance has no profiles, nobody is signed in, or no friend
/// is playing.
class FriendsPlayingCard extends ConsumerStatefulWidget {
  const FriendsPlayingCard({super.key});

  @override
  ConsumerState<FriendsPlayingCard> createState() => _FriendsPlayingCardState();
}

class _FriendsPlayingCardState extends ConsumerState<FriendsPlayingCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      friendsPlayingRefresh,
      (_) => ref.invalidate(friendsPlayingProvider),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (ref.watch(accountsEnabledProvider).value != true) {
      return const SizedBox.shrink();
    }
    if (ref.watch(accountProvider).value == null) {
      return const SizedBox.shrink();
    }
    final tables = ref.watch(friendsPlayingProvider).value ?? const [];
    if (tables.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        key: const Key('friends-playing'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.users, size: 15),
                const Gap(8),
                Expanded(child: Text(l10n.friendsPlayingTitle).semiBold()),
                GhostButton(
                  key: const Key('friends-playing-open'),
                  density: ButtonDensity.icon,
                  onPressed: () => showFriendsDialog(context),
                  child: const Icon(LucideIcons.arrowRight, size: 15),
                ),
              ],
            ),
            for (final t in tables) ...[const Gap(10), _TableRow(table: t)],
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.table});

  final PlayingTable table;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final names = table.friends.map((f) => f.displayName).join(', ');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      table.name,
                      overflow: TextOverflow.ellipsis,
                    ).semiBold().small(),
                  ),
                  const Gap(6),
                  Text(
                    '${table.smallBlind}/${table.bigBlind}',
                    style: TextStyle(
                      fontFamily: 'GeistMono',
                      fontSize: 11,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  if (table.requiresPassword) ...[
                    const Gap(6),
                    Icon(
                      LucideIcons.lock,
                      size: 11,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ],
                ],
              ),
              Text(names, overflow: TextOverflow.ellipsis).muted().xSmall(),
              Text(
                table.hasRoom
                    ? l10n.friendsPlayingSeats(
                        '${table.freeSeats}',
                        '${table.maxPlayers}',
                      )
                    : l10n.friendsPlayingFull,
              ).muted().xSmall(),
            ],
          ),
        ),
        const Gap(8),
        if (table.hasRoom)
          PrimaryButton(
            key: Key('friends-join-${table.id}'),
            size: ButtonSize.small,
            onPressed: () => context.go('/t/${table.id}'),
            child: Text(l10n.friendsJoin),
          )
        else if (table.allowSpectators)
          OutlineButton(
            key: Key('friends-watch-${table.id}'),
            size: ButtonSize.small,
            onPressed: () => context.go('/t/${table.id}'),
            child: Text(l10n.friendsPlayingWatch),
          ),
      ],
    );
  }
}
