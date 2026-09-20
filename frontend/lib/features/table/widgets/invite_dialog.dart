import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/account.dart';
import '../../../core/friends.dart';
import '../../../core/providers.dart';
import '../../../core/rest_client.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';
import '../../admin/admin_session.dart';
import '../../admin/admin_widgets.dart';
import '../table_session.dart';

/// Copies the table link and shows it with a QR code and everyone who is
/// connected right now.
Future<void> showInviteDialog(
  BuildContext context, {
  required String tableId,
  required Snapshot? snapshot,
  String? adminToken,
}) {
  final link = joinLinkFor(tableId);
  Clipboard.setData(ClipboardData(text: link));
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (context) => _InviteDialog(
      link: link,
      snapshot: snapshot,
      tableId: tableId,
      adminToken: adminToken,
    ),
  ).future;
}

class _InviteDialog extends ConsumerWidget {
  const _InviteDialog({
    required this.link,
    required this.snapshot,
    required this.tableId,
    this.adminToken,
  });
  final String link;
  final Snapshot? snapshot;
  final String tableId;

  /// The table's admin token when the viewer hosts it; only the host fills
  /// a seat with a bot.
  final String? adminToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // The host can seat a bot from this dialog, so the table it lists has to
    // follow along rather than stay as it was when the dialog opened.
    final live =
        ref.watch(tableSessionProvider(tableId).select((s) => s.snapshot)) ??
        snapshot;
    final players = [
      for (final sv in live?.seats ?? const <SeatView>[])
        if (sv.player != null) sv.player!,
    ];
    final spectators = live?.spectatorNames ?? const <String>[];
    final maxPlayers = live?.table.settings.maxPlayers ?? players.length;
    final freeSeats = (maxPlayers - players.length).clamp(0, maxPlayers);
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(title).semiBold().small(),
    );
    return AlertDialog(
      title: Text(l10n.inviteTitle),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.inviteHint).muted().small(),
              const Gap(10),
              // A friend needs no link: they get a notification wherever
              // they are.
              _InviteFriends(tableId: tableId, snapshot: live),
              // Nobody to ask, or one short of a game: the host can fill a
              // seat from here instead.
              if (adminToken != null)
                _AddBot(
                  tableId: tableId,
                  token: adminToken!,
                  freeSeats: freeSeats,
                ),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      link,
                      key: const Key('invite-link'),
                      style: const TextStyle(
                        fontFamily: 'GeistMono',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Gap(8),
                  OutlineButton(
                    key: const Key('invite-copy'),
                    size: ButtonSize.small,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      showAdminToast(context, l10n.adminLinkCopied);
                    },
                    leading: const Icon(LucideIcons.copy),
                    child: Text(l10n.adminCopyLink),
                  ),
                ],
              ),
              const Gap(12),
              Center(
                child: Container(
                  color: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(data: link, size: 180),
                ),
              ),
              section(l10n.invitePlayers(players.length)),
              if (players.isEmpty) Text(l10n.inviteNobody).muted().small(),
              for (final p in players)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      PlayerAvatar(index: p.avatar, size: 24),
                      const Gap(8),
                      Expanded(child: Text(p.name)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.connected
                              ? const Color(0xFF43A047)
                              : theme.colorScheme.destructive,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        p.connected
                            ? l10n.connConnected
                            : l10n.badgeDisconnected,
                      ).muted().small(),
                    ],
                  ),
                ),
              section(l10n.inviteSpectators(spectators.length)),
              if (spectators.isEmpty) Text(l10n.inviteNobody).muted().small(),
              for (final name in spectators)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.eye,
                        size: 16,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const Gap(8),
                      Expanded(child: Text(name)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        PrimaryButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// The friends who could be asked to this table, and the ones already at
/// it. Nothing for a guest, or on an instance without profiles.
class _InviteFriends extends ConsumerStatefulWidget {
  const _InviteFriends({required this.tableId, required this.snapshot});

  final String tableId;
  final Snapshot? snapshot;

  @override
  ConsumerState<_InviteFriends> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends ConsumerState<_InviteFriends> {
  final _asked = <String>{};
  String? _busy;
  String? _error;

  Future<void> _invite(Friend friend) async {
    final token = ref.read(accountProvider.notifier).token;
    if (token == null) return;
    setState(() {
      _busy = friend.handle;
      _error = null;
    });
    try {
      await ref
          .read(friendsApiProvider)
          .invite(token, widget.tableId, friend.handle);
      if (mounted) setState(() => _asked.add(friend.handle));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
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
    final friends = ref.watch(friendsProvider).value?.friends ?? const [];
    // Who is already sitting here needs no invitation.
    final here = {
      for (final sv in widget.snapshot?.seats ?? const <SeatView>[])
        if (sv.player?.account != null) sv.player!.account!,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            children: [
              const Icon(LucideIcons.users, size: 13),
              const Gap(6),
              Text(l10n.friendsInvite).semiBold().small(),
            ],
          ),
        ),
        if (friends.isEmpty)
          Text(l10n.friendsInviteNone).muted().xSmall()
        else ...[
          Text(l10n.friendsInviteHint).muted().xSmall(),
          for (final f in friends)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(LucideIcons.userCheck, size: 14),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      f.displayName,
                      overflow: TextOverflow.ellipsis,
                    ).small(),
                  ),
                  const Gap(8),
                  if (here.contains(f.handle))
                    Text(l10n.friendsInviteHere).muted().xSmall()
                  else if (_asked.contains(f.handle))
                    Text(l10n.friendsAsked).muted().xSmall()
                  else
                    OutlineButton(
                      key: Key('invite-friend-${f.handle}'),
                      size: ButtonSize.small,
                      enabled: _busy == null,
                      onPressed: () => _invite(f),
                      child: Text(l10n.friendsInvite),
                    ),
                ],
              ),
            ),
        ],
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.destructive),
          ).xSmall(),
        const Gap(8),
        const Divider(),
      ],
    );
  }
}

/// Fills a free seat with a bot the server plays. Host only: seating
/// somebody is the host's call, the same way kicking them is. To get rid of
/// one again, the host kicks it like any other player.
class _AddBot extends ConsumerStatefulWidget {
  const _AddBot({
    required this.tableId,
    required this.token,
    required this.freeSeats,
  });
  final String tableId;
  final String token;
  final int freeSeats;

  @override
  ConsumerState<_AddBot> createState() => _AddBotState();
}

class _AddBotState extends ConsumerState<_AddBot> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    final name = await guardAdmin(
      ref,
      context,
      widget.tableId,
      () => ref.read(adminApiProvider).addBot(widget.token, widget.tableId),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (name != null) showAdminToast(context, context.l10n.botAdded(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final full = widget.freeSeats == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bot, size: 14),
              const Gap(6),
              Text(l10n.botSection).semiBold().small(),
            ],
          ),
          const Gap(4),
          Text(full ? l10n.botTableFull : l10n.botHint).muted().xSmall(),
          const Gap(6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlineButton(
              key: const Key('invite-add-bot'),
              size: ButtonSize.small,
              onPressed: full || _busy ? null : _add,
              leading: const Icon(LucideIcons.plus),
              child: Text(l10n.botAdd),
            ),
          ),
        ],
      ),
    );
  }
}
