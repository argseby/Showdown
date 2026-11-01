import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../app/preferences.dart';
import '../../core/account.dart';
import '../../core/providers.dart';
import '../../core/rest_client.dart';
import 'revoked_button.dart';

/// "Sign in with Revoked", under the password fields.
///
/// Which device a person's Revoked app is on cannot be known from a web page:
/// a `revoked://` link with no app behind it simply does nothing. So the button
/// opens a panel that works either way, with the request as a QR code for a
/// phone and as a link for this device, and waits for the answer.
///
/// The app answers on the server it is signed into, and only the server shown
/// here is accepted. It starts as this instance's default and the player can
/// change it, which is remembered.
class RevokedSignInSection extends ConsumerStatefulWidget {
  const RevokedSignInSection({super.key});

  @override
  ConsumerState<RevokedSignInSection> createState() =>
      _RevokedSignInSectionState();
}

class _RevokedSignInSectionState extends ConsumerState<RevokedSignInSection> {
  final _server = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _editing = false;

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  String get _defaultServer =>
      ref.read(revokedDefaultServerProvider).value ?? '';

  String get _chosenServer {
    final chosen = ref.read(revokedServerProvider);
    return chosen.isNotEmpty ? chosen : _defaultServer;
  }

  void _startEditing() {
    _server.text = _withoutScheme(_chosenServer);
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  void _stopEditing() => setState(() {
    _editing = false;
    _error = null;
  });

  void _useDefault() {
    ref.read(revokedServerProvider.notifier).set('');
    _stopEditing();
  }

  Future<void> _go() async {
    final l10n = context.l10n;
    final issuer = _editing ? _server.text.trim() : _chosenServer;
    if (_editing && issuer.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? problem;
    try {
      final start = await ref
          .read(accountApiProvider)
          .revokedStart(issuer: issuer);
      if (!mounted) return;
      if (_editing) {
        ref
            .read(revokedServerProvider.notifier)
            .set(start.issuer == _defaultServer ? '' : start.issuer);
        setState(() => _editing = false);
      }
      final answer = await showRevokedWaitDialog(context, start);
      if (answer != null) {
        if (answer.error.isNotEmpty) {
          problem = revokedErrorText(l10n, answer.error);
        } else {
          await _finish(answer.code);
        }
      }
    } on ApiException catch (e) {
      // The server's own words for a bad address: it is the one that
      // tried to reach it and knows what went wrong.
      problem = e.code == 'revoked_sign_in_expired'
          ? l10n.revokedExpired
          : e.message;
    } catch (e, stack) {
      // The player gets one sentence; whoever is looking at the console
      // gets the reason.
      debugPrint('revoked sign-in could not finish: $e\n$stack');
      problem = l10n.revokedFailed;
    }
    if (!mounted) return;
    if (ref.read(accountProvider).value != null) {
      unawaited(closeOverlay<void>(context));
      return;
    }
    setState(() {
      _busy = false;
      _error = problem;
    });
  }

  /// Spends the code: the player is signed in, or is asked for a handle
  /// first because the identity is new here.
  Future<void> _finish(String code) async {
    final res = await ref.read(accountApiProvider).revokedFinish(code);
    switch (res) {
      case RevokedSignedIn():
        await ref.read(accountProvider.notifier).adoptRevoked(res);
      case RevokedNeedsHandle():
        if (mounted) await showRevokedHandleDialog(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (ref.watch(revokedSignInEnabledProvider).value != true) {
      return const SizedBox.shrink();
    }
    final fallback = ref.watch(revokedDefaultServerProvider).value ?? '';
    final chosen = ref.watch(revokedServerProvider);
    final server = chosen.isNotEmpty ? chosen : fallback;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(14),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(l10n.revokedOr).muted().small(),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const Gap(12),
        if (_editing) ...[
          Text(l10n.revokedServerBody).muted().small(),
          const Gap(8),
          TextField(
            key: const Key('revoked-server'),
            controller: _server,
            placeholder: Text(l10n.revokedServerHint),
            autofocus: true,
            onSubmitted: (_) => _busy ? null : _go(),
          ),
          const Gap(10),
        ],
        Align(
          child: RevokedButton(
            key: const Key('revoked-continue'),
            label: l10n.revokedSignIn,
            onPressed: _busy ? null : _go,
          ),
        ),
        if (_error != null) ...[
          const Gap(8),
          Text(
            _error!,
            key: const Key('revoked-error'),
            style: TextStyle(
              color: theme.colorScheme.destructive,
              fontSize: 12,
            ),
          ),
        ],
        const Gap(8),
        if (_editing)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              GhostButton(
                key: const Key('revoked-server-back'),
                onPressed: _stopEditing,
                child: Text(l10n.revokedBack).small(),
              ),
              if (chosen.isNotEmpty && fallback.isNotEmpty)
                GhostButton(
                  key: const Key('revoked-server-default'),
                  onPressed: _useDefault,
                  child: Text(
                    l10n.revokedServerUseDefault(_withoutScheme(fallback)),
                  ).small(),
                ),
            ],
          )
        else if (server.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.revokedServerLabel).muted().small(),
                    Text(
                      _withoutScheme(server),
                      key: const Key('revoked-server-current'),
                      overflow: TextOverflow.ellipsis,
                    ).small(),
                  ],
                ),
              ),
              GhostButton(
                key: const Key('revoked-server-edit'),
                onPressed: _startEditing,
                child: Text(l10n.revokedServerChange).small(),
              ),
            ],
          ),
      ],
    );
  }
}

String _withoutScheme(String origin) =>
    origin.replaceFirst(RegExp(r'^https?://'), '');

/// The player's words for why a sign-in ended without one.
String revokedErrorText(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'access_denied' => l10n.revokedDeclined,
      'expired' || 'state_mismatch' => l10n.revokedExpired,
      'issuer_mismatch' => l10n.revokedWrongServer,
      _ => l10n.revokedFailed,
    };

/// Shows the request and waits for the answer. Null when the player closed
/// the panel without one.
Future<RevokedAnswer?> showRevokedWaitDialog(
  BuildContext context,
  RevokedStart start,
) => showOverlay<RevokedAnswer?>(
  context,
  const DialogConfiguration(),
  builder: (context) => _RevokedWaitDialog(start: start),
).future;

class _RevokedWaitDialog extends ConsumerStatefulWidget {
  const _RevokedWaitDialog({required this.start});

  final RevokedStart start;

  @override
  ConsumerState<_RevokedWaitDialog> createState() => _RevokedWaitDialogState();
}

class _RevokedWaitDialogState extends ConsumerState<_RevokedWaitDialog> {
  static const _askEvery = Duration(seconds: 2);
  static const _qrSize = 240.0;

  Timer? _timer;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_askEvery, (_) => _ask());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _ask() async {
    if (_asking) return;
    _asking = true;
    try {
      final answer = await ref
          .read(accountApiProvider)
          .revokedWait(widget.start.wait);
      if (answer != null) _close(answer);
    } on ApiException catch (e) {
      if (e.code == 'revoked_sign_in_expired') {
        _close((code: '', error: 'expired'));
      }
      // Anything else is a bad moment, not an answer: ask again.
    } catch (_) {
      // Likewise: a phone browser loses its connection when it is put away.
    } finally {
      _asking = false;
    }
  }

  void _close(RevokedAnswer? answer) {
    _timer?.cancel();
    if (mounted) unawaited(closeOverlay<RevokedAnswer?>(context, answer));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = widget.start;
    // A web page cannot tell whether the app is here. A phone most likely
    // holds it, so there the link leads; on a computer the code does.
    final onPhone =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    void open() => ref.read(revokedBrowserProvider).go(start.appLink);
    final openHere = onPhone
        ? PrimaryButton(
            key: const Key('revoked-open-here'),
            onPressed: open,
            child: Text(l10n.revokedOpenHere),
          )
        : OutlineButton(
            key: const Key('revoked-open-here'),
            onPressed: open,
            child: Text(l10n.revokedOpenHere),
          );
    final scan = <Widget>[
      Text(onPhone ? l10n.revokedScanElsewhere : l10n.revokedScan).small(),
      const Gap(10),
      Center(
        child: Container(
          key: const Key('revoked-qr'),
          color: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.all(8),
          child: QrImageView(data: start.appLink, size: _qrSize),
        ),
      ),
    ];
    return AlertDialog(
      title: Text(l10n.revokedSignIn),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onPhone) ...[openHere, const Gap(16)],
              ...scan,
              const Gap(12),
              Text(
                l10n.revokedCheckCode(start.checkCode),
                key: const Key('revoked-check-code'),
                textAlign: TextAlign.center,
              ).small(),
              if (!onPhone) ...[const Gap(12), openHere],
              const Gap(12),
              Text(l10n.revokedNeedsApp).muted().small(),
            ],
          ),
        ),
      ),
      actions: [
        OutlineButton(
          key: const Key('revoked-wait-close'),
          onPressed: () => _close(null),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// Asks for the name a brand-new revoked identity will play under.
///
/// A profile is not made behind anyone's back: the revoked server has
/// vouched, but the handle is the player's to pick, and it is the only
/// thing this instance needs from them.
Future<void> showRevokedHandleDialog(
  BuildContext context,
  RevokedNeedsHandle pending,
) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => _RevokedHandleDialog(pending: pending),
).future;

class _RevokedHandleDialog extends ConsumerStatefulWidget {
  const _RevokedHandleDialog({required this.pending});

  final RevokedNeedsHandle pending;

  @override
  ConsumerState<_RevokedHandleDialog> createState() =>
      _RevokedHandleDialogState();
}

class _RevokedHandleDialogState extends ConsumerState<_RevokedHandleDialog> {
  late final _handle = TextEditingController(
    text: widget.pending.suggestedHandle,
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final handle = _handle.text.trim();
    if (handle.isEmpty) {
      setState(() => _error = l10n.accountMissingFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(accountProvider.notifier)
          .claimRevoked(
            claim: widget.pending.claim,
            handle: handle,
            displayName: widget.pending.name.isEmpty
                ? null
                : widget.pending.name,
          );
      if (mounted) unawaited(closeOverlay<void>(context));
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            // The claim survives a taken name, so the player just picks
            // another one rather than signing in again.
            'handle_taken' => l10n.accountHandleTaken,
            'revoked_sign_in_expired' => l10n.revokedExpired,
            _ => e.message,
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.errGeneric('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // The address, without the scheme: that is how the player typed it.
    final server = widget.pending.issuer.replaceFirst(
      RegExp(r'^https?://'),
      '',
    );
    return AlertDialog(
      title: Text(l10n.revokedChooseTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.revokedChooseBody(server)).muted().small(),
            const Gap(12),
            TextField(
              key: const Key('revoked-handle'),
              controller: _handle,
              placeholder: Text(l10n.accountHandle),
              autofocus: true,
              onSubmitted: (_) => _busy ? null : _create(),
            ),
            if (_error != null) ...[
              const Gap(8),
              Text(
                _error!,
                key: const Key('revoked-handle-error'),
                style: TextStyle(
                  color: theme.colorScheme.destructive,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('revoked-claim'),
          onPressed: _busy ? null : _create,
          child: Text(l10n.accountCreate),
        ),
      ],
    );
  }
}
