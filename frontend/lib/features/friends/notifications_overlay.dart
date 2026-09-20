import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../app/router.dart';
import '../../core/account.dart';
import '../../core/friends.dart';
import '../../core/rest_client.dart';
import '../../core/user_socket.dart';

/// Wraps the whole app: keeps the user socket alive while somebody is
/// signed in and stacks what it pushes in the corner. A notification is
/// about the person, so it follows them from the home screen to the table
/// and back.
class NotificationsScope extends ConsumerWidget {
  const NotificationsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching it is what holds the socket open.
    ref.watch(userSocketProvider);
    final notifications = ref.watch(notificationsProvider);
    return Stack(
      children: [
        child,
        if (notifications.isNotEmpty)
          Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Newest at the bottom, nearest the eye.
                  for (final n in notifications.take(4))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _NotificationCard(notification: n),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _busy = false;

  Future<void> _answer(String action) async {
    final token = ref.read(accountProvider.notifier).token;
    if (token == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(friendsApiProvider)
          .answer(token, widget.notification.handle, action);
      ref.invalidate(friendsProvider);
      ref.invalidate(friendsPlayingProvider);
    } on ApiException {
      // The friends screen shows the truth either way.
    } finally {
      _dismiss();
    }
  }

  /// Taking up an invitation: go to the table first, then spend it. The
  /// card is taken off the screen last — removing it disposes this widget,
  /// and a disposed widget can neither navigate nor reach the API.
  ///
  /// The router comes from the provider, not from the context: these cards
  /// hang above the whole app, which is one layer further out than the
  /// router's own subtree, so context.go would find nothing there.
  Future<void> _joinTable() async {
    final n = widget.notification;
    ref.read(routerProvider).go('/t/${n.tableId}');
    await _spendInvite();
    _dismiss();
  }

  Future<void> _dismissInvite() async {
    await _spendInvite();
    _dismiss();
  }

  /// Drops the invitation server-side; it expires by itself either way.
  Future<void> _spendInvite() async {
    final n = widget.notification;
    final token = ref.read(accountProvider.notifier).token;
    if (token == null || n.inviteId.isEmpty) return;
    try {
      await ref.read(friendsApiProvider).dismissInvite(token, n.inviteId);
      ref.invalidate(friendsProvider);
    } on ApiException {
      // Taking up the invitation matters more than tidying it away.
    }
  }

  void _dismiss() =>
      ref.read(notificationsProvider.notifier).remove(widget.notification.id);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = widget.notification;
    final (icon, text) = switch (n.kind) {
      UserEventKind.friendRequest => (
        LucideIcons.userPlus,
        l10n.notifFriendRequest(n.name),
      ),
      UserEventKind.tableInvite => (
        LucideIcons.mailOpen,
        l10n.notifInvite(n.name, n.tableName),
      ),
      _ => (LucideIcons.userCheck, l10n.notifFriendAccepted(n.name)),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Card(
        key: Key('notification-${n.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const Gap(8),
                Flexible(child: Text(text).small()),
              ],
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: switch (n.kind) {
                UserEventKind.friendRequest => [
                  GhostButton(
                    size: ButtonSize.small,
                    enabled: !_busy,
                    onPressed: () => _answer('block'),
                    child: Text(l10n.friendsBlock),
                  ),
                  const Gap(4),
                  OutlineButton(
                    size: ButtonSize.small,
                    enabled: !_busy,
                    onPressed: () => _answer('decline'),
                    child: Text(l10n.friendsDecline),
                  ),
                  const Gap(4),
                  PrimaryButton(
                    key: Key('notification-accept-${n.handle}'),
                    size: ButtonSize.small,
                    enabled: !_busy,
                    onPressed: () => _answer('accept'),
                    child: Text(l10n.friendsAccept),
                  ),
                ],
                UserEventKind.tableInvite => [
                  OutlineButton(
                    size: ButtonSize.small,
                    onPressed: _dismissInvite,
                    child: Text(l10n.friendsDismiss),
                  ),
                  const Gap(4),
                  PrimaryButton(
                    key: Key('notification-join-${n.tableId}'),
                    size: ButtonSize.small,
                    onPressed: _joinTable,
                    child: Text(l10n.friendsJoin),
                  ),
                ],
                _ => [
                  OutlineButton(
                    size: ButtonSize.small,
                    onPressed: _dismiss,
                    child: Text(l10n.notifOk),
                  ),
                ],
              },
            ),
          ],
        ),
      ),
    );
  }
}
