import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/rest_client.dart';
import 'revoked_button.dart';
import 'revoked_connect_panel.dart';

/// "Now playing": the table a player is at, kept in their own Revoked
/// vault.
///
/// Showdown is connected as a tool, is given a section of the vault of its
/// own, and keeps one entry there. A share over that section resolves at
/// read time, so the one link the player hands out always points at the
/// table they are at now. None of it is this instance's to keep: the
/// player pauses, narrows or revokes it from their app.
Future<void> showNowPlayingDialog(BuildContext context) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => const NowPlayingDialog(),
).future;

class NowPlayingDialog extends ConsumerStatefulWidget {
  const NowPlayingDialog({super.key});

  @override
  ConsumerState<NowPlayingDialog> createState() => _NowPlayingDialogState();
}

class _NowPlayingDialogState extends ConsumerState<NowPlayingDialog> {
  bool _busy = false;
  String? _error;
  bool _copied = false;
  bool _confirmingOff = false;

  /// Connects the vault: the app shows what is being asked for, the player
  /// approves it there, and this page collects the answer.
  Future<void> _connect() async {
    final l10n = context.l10n;
    final api = ref.read(accountApiProvider);
    final token = ref.read(accountProvider.notifier).token;
    if (token == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? problem;
    try {
      final start = await api.revokedConnectStart(token);
      if (!mounted) return;
      final answer = await showRevokedConnectDialog(
        context,
        start,
        title: l10n.nowPlayingConnectTitle,
        poll: (wait) => api.revokedConnectWait(token, wait),
      );
      if (answer != null && answer.error.isNotEmpty) {
        problem = _answerText(l10n, answer.error);
      }
      ref.invalidate(nowPlayingProvider);
    } on ApiException catch (e) {
      problem = switch (e.code) {
        'revoked_identity_required' => l10n.nowPlayingNeedsRevoked,
        'revoked_sign_in_expired' => l10n.revokedExpired,
        _ => e.message,
      };
    } catch (_) {
      problem = l10n.nowPlayingFailed;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = problem;
    });
  }

  /// Ends the share and gives the connection up.
  Future<void> _turnOff() async {
    final token = ref.read(accountProvider.notifier).token;
    if (token == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountApiProvider).nowPlayingOff(token);
      ref.invalidate(nowPlayingProvider);
      if (mounted) setState(() => _confirmingOff = false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.nowPlayingFailed);
    }
    if (mounted) setState(() => _busy = false);
  }

  /// What the player is told when the app's answer was not a yes.
  String _answerText(AppLocalizations l10n, String reason) => switch (reason) {
    'access_denied' => l10n.revokedDeclined,
    'not_permitted' => l10n.nowPlayingNotPermitted,
    'issuer_mismatch' => l10n.revokedWrongServer,
    'expired' || 'state_mismatch' => l10n.revokedExpired,
    _ => l10n.nowPlayingFailed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(nowPlayingProvider).value ?? nowPlayingNone;
    final playing = state.playing.isEmpty ? l10n.nowPlayingIdle : state.playing;

    final body = <Widget>[Text(l10n.nowPlayingBody).muted().small()];
    if (state.connected) {
      body.addAll([
        const Gap(12),
        Text(l10n.nowPlayingLinkLabel).muted().small(),
        const Gap(4),
        SelectableText(state.url, key: const Key('now-playing-url')).small(),
        const Gap(8),
        OutlineButton(
          key: const Key('now-playing-copy'),
          onPressed: state.url.isEmpty
              ? null
              : () {
                  unawaited(Clipboard.setData(ClipboardData(text: state.url)));
                  setState(() => _copied = true);
                },
          leading: const Icon(LucideIcons.copy, size: 14),
          child: Text(_copied ? l10n.nowPlayingCopied : l10n.nowPlayingCopy),
        ),
        const Gap(12),
        Text(
          l10n.nowPlayingAt(playing),
          key: const Key('now-playing-current'),
        ).small(),
        const Gap(10),
        Text(l10n.nowPlayingYours).muted().xSmall(),
      ]);
      // A pause or a lapse is the player's own doing, in their app, so
      // they are told which it is rather than that something failed.
      final trouble = switch (state.trouble) {
        'paused' => l10n.nowPlayingPaused,
        'expired' || 'gone' => l10n.nowPlayingLapsed,
        _ => null,
      };
      if (trouble != null) {
        body.addAll([
          const Gap(8),
          Text(
            trouble,
            key: const Key('now-playing-trouble'),
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ).small(),
        ]);
      }
      if (_confirmingOff) {
        body.addAll([
          const Gap(10),
          Text(l10n.nowPlayingOffBody).muted().small(),
        ]);
      }
    } else {
      body.addAll([
        const Gap(14),
        Align(
          child: RevokedButton(
            key: const Key('now-playing-connect'),
            label: l10n.nowPlayingConnect,
            onPressed: _busy ? null : _connect,
          ),
        ),
      ]);
    }
    if (_error != null) {
      body.addAll([
        const Gap(8),
        Text(
          _error!,
          key: const Key('now-playing-error'),
          style: TextStyle(color: theme.colorScheme.destructive, fontSize: 12),
        ),
      ]);
    }

    return AlertDialog(
      title: Text(l10n.nowPlayingTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: body,
        ),
      ),
      actions: [
        if (state.connected)
          DestructiveButton(
            key: const Key('now-playing-off'),
            onPressed: _busy
                ? null
                : () => _confirmingOff
                      ? _turnOff()
                      : setState(() => _confirmingOff = true),
            child: Text(l10n.nowPlayingOff),
          ),
        PrimaryButton(
          key: const Key('now-playing-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
