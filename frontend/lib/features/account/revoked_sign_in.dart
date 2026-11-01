import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/providers.dart';
import '../../core/rest_client.dart';
import 'revoked_button.dart';

/// "Sign in with Revoked", under the password fields.
///
/// Every revoked server is self-hosted, so which one a person uses is not
/// known here — but their Revoked app knows. The button therefore carries
/// the request itself, as a `revoked://signin` link, and the app answers
/// on whichever server it is signed into; this instance learns which that
/// was from the `iss` of the answer. Naming a server by hand is the
/// fallback, folded away until asked for.
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

  /// The address field stays hidden until asked for: the app knows the
  /// server, so naming one is the exception.
  bool _naming = false;

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final l10n = context.l10n;
    final issuer = _naming ? _server.text.trim() : '';
    if (_naming && issuer.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(accountApiProvider)
          .revokedStart(issuer: issuer);
      // With a server named, the browser goes to that server's page,
      // which opens the app with the same request. Otherwise straight to
      // the app, which answers on the server the person already uses.
      final target = res.authorizeUrl.isNotEmpty
          ? res.authorizeUrl
          : res.appLink;
      // The tab leaves here and comes back to RevokedReturnScope. With no
      // app installed a revoked:// link simply does nothing and the page
      // stays, which is what the hint under the button is for.
      ref.read(revokedBrowserProvider).go(target);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          // The server's own words for a bad address: it is the one that
          // tried to reach it and knows what went wrong.
          _error = e.message;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = l10n.errGeneric('$e');
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (ref.watch(revokedSignInEnabledProvider).value != true) {
      return const SizedBox.shrink();
    }
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
        if (_naming) ...[
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
            label: _busy ? l10n.revokedOpening : l10n.revokedSignIn,
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
        // Without the app the link leads nowhere and the page just stays,
        // so say what is missing rather than let the button look broken.
        Text(l10n.revokedNeedsApp).muted().small(),
        GhostButton(
          key: const Key('revoked-name-server'),
          onPressed: () => setState(() {
            _naming = !_naming;
            _error = null;
          }),
          child: Text(_naming ? l10n.revokedBack : l10n.revokedNameServer)
              .small(),
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
