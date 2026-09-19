import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../core/friends.dart';
import '../../core/rest_client.dart';
import '../friends/friends_dialog.dart';
import 'stats_dialog.dart';
import 'visibility_dialog.dart';

/// The profile behind the person in the app bar: who you are signed in as,
/// a new password when you want one, and the way out.
Future<void> showAccountSheet(BuildContext context) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => const AccountSheet(),
).future;

class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key});

  @override
  ConsumerState<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _changing = false;
  bool _busy = false;
  String? _error;

  /// The code from the last password change, shown once.
  String? _recoveryCode;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final l10n = context.l10n;
    if (_current.text.isEmpty || _next.text.isEmpty) {
      setState(() => _error = l10n.accountMissingFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref
          .read(accountProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) {
        setState(() {
          _recoveryCode = code;
          _changing = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'bad_credentials' => l10n.accountBadCredentials,
            'validation_failed' => e.message,
            _ => e.message,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = ref.watch(accountProvider).value;
    if (account == null) return const SizedBox.shrink();
    final code = _recoveryCode;

    Widget body;
    if (code != null) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.accountRecoveryBody).muted().small(),
          const Gap(12),
          Container(
            key: const Key('account-new-code'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(fontFamily: 'GeistMono', fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(8),
          OutlineButton(
            onPressed: () =>
                unawaited(Clipboard.setData(ClipboardData(text: code))),
            leading: const Icon(LucideIcons.copy, size: 14),
            child: Text(l10n.accountRecoveryCopy),
          ),
        ],
      );
    } else if (_changing) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.accountPasswordHint).muted().small(),
          const Gap(10),
          TextField(
            key: const Key('account-current-password'),
            controller: _current,
            placeholder: Text(l10n.accountCurrentPassword),
            obscureText: true,
            autofocus: true,
          ),
          const Gap(8),
          TextField(
            key: const Key('account-new-password'),
            controller: _next,
            placeholder: Text(l10n.accountNewPassword),
            obscureText: true,
            onSubmitted: (_) => _change(),
          ),
          if (_error != null) ...[
            const Gap(8),
            Text(
              _error!,
              key: const Key('account-sheet-error'),
              style: TextStyle(
                color: theme.colorScheme.destructive,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    } else {
      Widget row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.mutedForeground),
            const Gap(8),
            SizedBox(width: 110, child: Text(label).muted().small()),
            Expanded(child: Text(value).small()),
          ],
        ),
      );
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(LucideIcons.atSign, l10n.accountHandleLabel, account.handle),
          row(LucideIcons.user, l10n.accountDisplayName, account.displayName),
          const Gap(12),
          // The headline of the record, with the rest a tap away.
          Consumer(
            builder: (context, ref, _) {
              final async = ref.watch(accountStatsProvider);
              // While the record is on its way, hold the line's place:
              // "nothing yet" would be wrong for a profile that has played.
              if (async.isLoading) return const SizedBox(height: 18);
              final stats = async.value;
              if (stats == null || stats.empty) {
                return Text(l10n.statsEmpty).muted().small();
              }
              // In chips, like everything else the player sees; the
              // big-blind rate is a tap away in the dialog.
              final net = formatChips(
                stats.net,
                Localizations.localeOf(context).toString(),
              );
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '${stats.hands} ${l10n.statsHands.toLowerCase()} · '
                      '${stats.net > 0 ? '+' : ''}$net',
                      key: const Key('account-stats-line'),
                    ).small(),
                  ),
                ],
              );
            },
          ),
          const Gap(12),
          OutlineButton(
            key: const Key('account-stats'),
            onPressed: () => showStatsDialog(context),
            leading: const Icon(LucideIcons.chartNoAxesColumn, size: 14),
            child: Text(l10n.statsOpen),
          ),
          const Gap(6),
          Consumer(
            builder: (context, ref, _) {
              final waiting = ref.watch(friendsProvider).value?.waiting ?? 0;
              return OutlineButton(
                key: const Key('account-friends'),
                onPressed: () => showFriendsDialog(context),
                leading: const Icon(LucideIcons.users, size: 14),
                trailing: waiting == 0
                    ? null
                    : Text('$waiting').xSmall().semiBold(),
                child: Text(l10n.friendsOpen),
              );
            },
          ),
          const Gap(6),
          OutlineButton(
            key: const Key('account-visibility'),
            onPressed: () => showVisibilityDialog(context),
            leading: const Icon(LucideIcons.eye, size: 14),
            child: Text(l10n.visOpen),
          ),
          const Gap(6),
          OutlineButton(
            key: const Key('account-change-password'),
            onPressed: () => setState(() {
              _changing = true;
              _error = null;
            }),
            leading: const Icon(LucideIcons.keyRound, size: 14),
            child: Text(l10n.accountChangePassword),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('@${account.handle}'),
      content: SizedBox(width: 340, child: body),
      actions: [
        if (code != null)
          PrimaryButton(
            key: const Key('account-code-done'),
            onPressed: () => closeOverlay<void>(context),
            child: Text(l10n.accountRecoveryDone),
          )
        else if (_changing) ...[
          OutlineButton(
            onPressed: () => setState(() {
              _changing = false;
              _error = null;
            }),
            child: Text(l10n.cancel),
          ),
          PrimaryButton(
            key: const Key('account-save-password'),
            onPressed: _busy ? null : _change,
            child: Text(l10n.accountSavePassword),
          ),
        ] else ...[
          DestructiveButton(
            key: const Key('account-sign-out'),
            onPressed: () async {
              await ref.read(accountProvider.notifier).signOut();
              if (context.mounted) unawaited(closeOverlay<void>(context));
            },
            leading: const Icon(LucideIcons.logOut, size: 14),
            child: Text(l10n.accountSignOut),
          ),
          PrimaryButton(
            key: const Key('account-close'),
            onPressed: () => closeOverlay<void>(context),
            child: Text(l10n.close),
          ),
        ],
      ],
    );
  }
}
