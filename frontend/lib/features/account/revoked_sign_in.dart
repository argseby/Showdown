import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revoked_sign_in/revoked_sign_in.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../app/preferences.dart';
import '../../core/account.dart';
import '../../core/providers.dart';
import '../../core/rest_client.dart';

/// "Sign in with Revoked", under the password fields.
///
/// The button and the panel behind it are revoked's own: `revoked_sign_in`
/// draws them to the published spec, calls this server's `start` and `wait`
/// routes and hands over the answer. What is left here is what belongs to
/// this instance — which server the request goes to, and what to do with a
/// finished sign-in.
///
/// The app answers on the server it is signed into, and only the server
/// shown here is accepted. It starts as this instance's default and the
/// player can change it, which is remembered.
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

  /// Takes the address the player typed, once this server has shown it can
  /// reach it. The check is a sign-in this page then throws away: it is the
  /// server that has to talk to that address, so it is the one that says
  /// whether it can, and in its own words.
  Future<void> _useTyped() async {
    final l10n = context.l10n;
    final typed = _server.text.trim();
    if (typed.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final start = await ref
          .read(accountApiProvider)
          .revokedStart(issuer: typed);
      if (!mounted) return;
      ref
          .read(revokedServerProvider.notifier)
          .set(start.issuer == _defaultServer ? '' : start.issuer);
      setState(() {
        _editing = false;
        _error = null;
      });
    } on ApiException catch (e) {
      // The server's own words for a bad address.
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      debugPrint('revoked server could not be checked: $e\n$stack');
      if (mounted) setState(() => _error = l10n.revokedFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The approval came back: the answer carries the one-time code this page
  /// spends for a session.
  Future<void> _signedIn(Map<String, dynamic> answer) async {
    final l10n = context.l10n;
    final code = answer['code'];
    if (code is! String || code.isEmpty) {
      setState(() => _error = l10n.revokedFailed);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? problem;
    try {
      await _finish(code);
    } on ApiException catch (e) {
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

  /// Opening the app is this page's job on the web: the request is handed to
  /// the address bar, so an answer the app could not deliver to this server
  /// lands back here rather than in a window of its own.
  Future<bool> _openApp(Uri link) async {
    ref.read(revokedBrowserProvider).go(link.toString());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (ref.watch(revokedSignInEnabledProvider).value != true) {
      return const SizedBox.shrink();
    }
    final rest = ref.watch(restClientProvider);
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
            onSubmitted: (_) => _busy ? null : _useTyped(),
          ),
          const Gap(8),
          PrimaryButton(
            key: const Key('revoked-server-use'),
            onPressed: _busy ? null : _useTyped,
            child: Text(l10n.revokedServerUse),
          ),
          const Gap(10),
        ],
        Align(
          // A second press while the code is being spent would start a
          // sign-in the first one is about to make pointless.
          child: IgnorePointer(
            ignoring: _busy,
            child: RevokedSignInButton(
              key: const Key('revoked-continue'),
              // The chosen server travels in the start URL: the button
              // posts a body of its own.
              start: rest.endpoint('/api/accounts/revoked/start', {
                if (server.isNotEmpty) 'issuer': server,
              }),
              wait: rest.endpoint('/api/accounts/revoked/wait'),
              // One client for the whole app, and the fake one in a test.
              httpClient: rest.httpClient,
              openApp: _openApp,
              label: RevokedLabel.signIn,
              // Black for a light page, white for a dark one.
              theme: theme.brightness == Brightness.dark
                  ? RevokedTheme.white
                  : RevokedTheme.black,
              onSignedIn: (answer) => unawaited(_signedIn(answer)),
            ),
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
