import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../core/friends.dart';
import '../../core/rest_client.dart';
import '../../shared/confirm_dialog.dart';
import 'profile_dialog.dart';

/// The friends screen: who your friends are, who is asking, who you are
/// waiting on, and who you have shut out.
Future<void> showFriendsDialog(BuildContext context, {int tab = 0}) =>
    showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (context) => FriendsDialog(tab: tab),
    ).future;

enum FriendsTab { all, requests, find, blocked }

class FriendsDialog extends ConsumerStatefulWidget {
  const FriendsDialog({super.key, this.tab = 0});

  final int tab;

  @override
  ConsumerState<FriendsDialog> createState() => _FriendsDialogState();
}

class _FriendsDialogState extends ConsumerState<FriendsDialog> {
  late FriendsTab _tab = FriendsTab.values[widget.tab];
  final _search = TextEditingController();
  Timer? _debounce;
  List<Friend>? _results;
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String? get _token => ref.read(accountProvider.notifier).token;

  /// Runs an action against the API and reloads the lists it changed.
  Future<void> _act(Future<void> Function(String token) action) async {
    final token = _token;
    if (token == null) return;
    setState(() => _error = null);
    try {
      await action(token);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    ref.invalidate(friendsProvider);
    ref.invalidate(friendsPlayingProvider);
    if (_search.text.isNotEmpty) await _runSearch(_search.text);
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    final token = _token;
    if (token == null) return;
    setState(() => _searching = true);
    try {
      final found = await ref.read(friendsApiProvider).search(token, q.trim());
      if (mounted) setState(() => _results = found);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = ref.watch(friendsProvider).value ?? const FriendsView();

    return AlertDialog(
      title: Text(l10n.friendsTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tabs(
              index: _tab.index,
              onChanged: (i) => setState(() => _tab = FriendsTab.values[i]),
              expand: true,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              children: [
                _tabItem(
                  const Key('friends-tab-all'),
                  LucideIcons.users,
                  l10n.friendsTabAll,
                  view.friends.length,
                ),
                _tabItem(
                  const Key('friends-tab-requests'),
                  LucideIcons.userPlus,
                  l10n.friendsTabRequests,
                  view.waiting,
                ),
                _tabItem(
                  const Key('friends-tab-find'),
                  LucideIcons.search,
                  l10n.friendsTabFind,
                  0,
                ),
                _tabItem(
                  const Key('friends-tab-blocked'),
                  LucideIcons.ban,
                  l10n.friendsTabBlocked,
                  0,
                ),
              ],
            ),
            const Gap(12),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.destructive,
                ),
              ).small(),
              const Gap(8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: switch (_tab) {
                  FriendsTab.all => _friends(view),
                  FriendsTab.requests => _requests(view),
                  FriendsTab.find => _find(),
                  FriendsTab.blocked => _blocked(view),
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('friends-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  TabItem _tabItem(Key key, IconData icon, String label, int count) => TabItem(
    key: key,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13),
        const Gap(5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis).small()),
        if (count > 0) ...[const Gap(4), _Count(count)],
      ],
    ),
  );

  Widget _friends(FriendsView view) {
    final l10n = context.l10n;
    if (view.friends.isEmpty) {
      return Text(l10n.friendsNone, key: const Key('friends-empty')).muted();
    }
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in view.friends)
          _FriendRow(
            friend: f,
            subtitle: l10n.friendsSince(formatDate(f.since, locale)),
            onTap: () => showProfileDialog(context, f.handle),
            actions: [
              _IconAction(
                icon: LucideIcons.userMinus,
                tooltip: l10n.friendsRemove,
                onPressed: () async {
                  final yes = await showConfirmDialog(
                    context,
                    title: l10n.friendsRemove,
                    body: l10n.friendsRemoveConfirm(f.displayName),
                    confirmLabel: l10n.friendsRemove,
                    cancelLabel: l10n.cancel,
                    destructive: true,
                  );
                  if (yes) await _act((t) => _api.unfriend(t, f.handle));
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _requests(FriendsView view) {
    final l10n = context.l10n;
    if (view.waiting == 0 && view.outgoing.isEmpty) {
      return Text(
        l10n.friendsNoRequests,
        key: const Key('friends-no-requests'),
      ).muted();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.invites.isNotEmpty) ...[
          _heading(LucideIcons.mailOpen, l10n.friendsInvites),
          for (final i in view.invites) _InviteRow(invite: i, act: _act),
        ],
        if (view.incoming.isNotEmpty) ...[
          _heading(LucideIcons.userPlus, l10n.friendsIncoming),
          for (final f in view.incoming)
            _FriendRow(
              friend: f,
              onTap: () => showProfileDialog(context, f.handle),
              actions: [
                _IconAction(
                  key: Key('friend-accept-${f.handle}'),
                  icon: LucideIcons.check,
                  tooltip: l10n.friendsAccept,
                  onPressed: () =>
                      _act((t) => _api.answer(t, f.handle, 'accept')),
                ),
                _IconAction(
                  icon: LucideIcons.x,
                  tooltip: l10n.friendsDecline,
                  onPressed: () =>
                      _act((t) => _api.answer(t, f.handle, 'decline')),
                ),
                _IconAction(
                  icon: LucideIcons.ban,
                  tooltip: l10n.friendsBlock,
                  destructive: true,
                  onPressed: () async {
                    final yes = await showConfirmDialog(
                      context,
                      title: l10n.friendsBlock,
                      body: l10n.friendsBlockConfirm(f.displayName),
                      confirmLabel: l10n.friendsBlock,
                      cancelLabel: l10n.cancel,
                      destructive: true,
                    );
                    if (yes) {
                      await _act((t) => _api.answer(t, f.handle, 'block'));
                    }
                  },
                ),
              ],
            ),
        ],
        if (view.outgoing.isNotEmpty) ...[
          _heading(LucideIcons.clock, l10n.friendsOutgoing),
          for (final f in view.outgoing)
            _FriendRow(
              friend: f,
              onTap: () => showProfileDialog(context, f.handle),
              actions: const [],
            ),
        ],
      ],
    );
  }

  Widget _find() {
    final l10n = context.l10n;
    final results = _results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('friends-search'),
          controller: _search,
          placeholder: Text(l10n.friendsFindPlaceholder),
          onChanged: _onQuery,
        ),
        const Gap(10),
        if (_searching && results == null)
          const Center(child: CircularProgressIndicator())
        else if (results != null && results.isEmpty)
          Text(l10n.friendsFindNothing).muted().small()
        else if (results != null)
          for (final f in results)
            _FriendRow(
              friend: f,
              subtitle: '@${f.handle}',
              onTap: () => showProfileDialog(context, f.handle),
              actions: [
                switch (f.relation) {
                  Relation.friend => _Tag(l10n.friendsTabAll),
                  Relation.pendingOut => _Tag(l10n.friendsAsked),
                  Relation.pendingIn => _IconAction(
                    icon: LucideIcons.check,
                    tooltip: l10n.friendsAccept,
                    onPressed: () =>
                        _act((t) => _api.answer(t, f.handle, 'accept')),
                  ),
                  _ => _IconAction(
                    key: Key('friend-add-${f.handle}'),
                    icon: LucideIcons.userPlus,
                    tooltip: l10n.friendsAdd,
                    onPressed: () => _act((t) => _api.request(t, f.handle)),
                  ),
                },
              ],
            ),
      ],
    );
  }

  Widget _blocked(FriendsView view) {
    final l10n = context.l10n;
    if (view.blocked.isEmpty) {
      return Text(l10n.friendsBlockedNone).muted();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.friendsBlockedHint).muted().xSmall(),
        const Gap(8),
        for (final f in view.blocked)
          _FriendRow(
            friend: f,
            subtitle: '@${f.handle}',
            actions: [
              _IconAction(
                icon: LucideIcons.rotateCcw,
                tooltip: l10n.friendsUnblock,
                onPressed: () => _act((t) => _api.unblock(t, f.handle)),
              ),
            ],
          ),
      ],
    );
  }

  FriendsApi get _api => ref.read(friendsApiProvider);

  Widget _heading(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
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
}

/// One person in a list: who they are, and what can be done about it.
class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.actions,
    this.subtitle,
    this.onTap,
  });

  final Friend friend;
  final List<Widget> actions;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(LucideIcons.userCheck, size: 16),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friend.displayName,
                  overflow: TextOverflow.ellipsis,
                ).small(),
                if (subtitle != null) Text(subtitle!).muted().xSmall(),
              ],
            ),
          ),
          const Gap(8),
          ...actions,
        ],
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

/// An invitation waiting to be taken up.
class _InviteRow extends ConsumerWidget {
  const _InviteRow({required this.invite, required this.act});

  final TableInvite invite;
  final Future<void> Function(Future<void> Function(String token)) act;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(LucideIcons.mailOpen, size: 16),
          const Gap(8),
          Expanded(
            child: Text(
              l10n.friendsInviteFrom(invite.from, invite.tableName),
              overflow: TextOverflow.ellipsis,
            ).small(),
          ),
          const Gap(8),
          PrimaryButton(
            key: Key('invite-join-${invite.id}'),
            size: ButtonSize.small,
            onPressed: () {
              closeOverlay<void>(context);
              context.go('/t/${invite.tableId}');
            },
            child: Text(l10n.friendsJoin),
          ),
          const Gap(4),
          _IconAction(
            icon: LucideIcons.x,
            tooltip: l10n.friendsDismiss,
            onPressed: () => act(
              (t) => ref.read(friendsApiProvider).dismissInvite(t, invite.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small round button with a tooltip, for the row actions.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Tooltip(
    tooltip: TooltipContainer(child: Text(tooltip)).call,
    child: GhostButton(
      density: ButtonDensity.icon,
      onPressed: onPressed,
      child: Icon(
        icon,
        size: 16,
        color: destructive ? Theme.of(context).colorScheme.destructive : null,
      ),
    ),
  );
}

/// A plain label where an action would otherwise be.
class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text).muted().xSmall();
}

/// The number on a tab: how much is waiting there.
class _Count extends StatelessWidget {
  const _Count(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.primaryForeground,
        ),
      ),
    );
  }
}
