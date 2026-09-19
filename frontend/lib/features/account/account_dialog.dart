import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/rest_client.dart';

/// Sign in, or make a profile. Profiles are optional everywhere: this
/// dialog is only ever reached by a player who went looking for it.
Future<void> showAccountDialog(BuildContext context, {bool register = false}) =>
    showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (context) => AccountDialog(register: register),
    ).future;

class AccountDialog extends ConsumerStatefulWidget {
  const AccountDialog({super.key, this.register = false});

  /// Opens on the sign-up side; the dialog switches either way.
  final bool register;

  @override
  ConsumerState<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<AccountDialog> {
  late bool _register = widget.register;
  final _handle = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Shown once after sign-up: the only way back in without the password.
  String? _recoveryCode;

  @override
  void dispose() {
    _handle.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final handle = _handle.text.trim();
    final password = _password.text;
    if (handle.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.accountMissingFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(accountProvider.notifier);
      if (_register) {
        final code = await notifier.register(
          handle: handle,
          password: password,
        );
        if (mounted) setState(() => _recoveryCode = code);
      } else {
        await notifier.signIn(handle: handle, password: password);
        if (mounted) unawaited(closeOverlay<void>(context));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'handle_taken' => l10n.accountHandleTaken,
            'bad_credentials' => l10n.accountBadCredentials,
            'accounts_disabled' => l10n.accountsOff,
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
    final code = _recoveryCode;
    if (code != null) {
      // Sign-up is done; this code is shown once and never again.
      return AlertDialog(
        title: Text(l10n.accountRecoveryTitle),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.accountRecoveryBody).muted().small(),
              const Gap(12),
              Container(
                key: const Key('account-recovery-code'),
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
          ),
        ),
        actions: [
          PrimaryButton(
            key: const Key('account-recovery-done'),
            onPressed: () => closeOverlay<void>(context),
            child: Text(l10n.accountRecoveryDone),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(
        _register ? l10n.accountCreateTitle : l10n.accountSignInTitle,
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_register ? l10n.accountCreateBody : l10n.accountSignInBody)
                .muted()
                .small(),
            const Gap(12),
            TextField(
              key: const Key('account-handle'),
              controller: _handle,
              placeholder: Text(l10n.accountHandle),
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const Gap(8),
            TextField(
              key: const Key('account-password'),
              controller: _password,
              placeholder: Text(l10n.accountPassword),
              obscureText: true,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const Gap(8),
              Text(
                _error!,
                key: const Key('account-error'),
                style: TextStyle(
                  color: theme.colorScheme.destructive,
                  fontSize: 12,
                ),
              ),
            ],
            const Gap(10),
            GhostButton(
              key: const Key('account-switch-mode'),
              onPressed: () => setState(() {
                _register = !_register;
                _error = null;
              }),
              child: Text(_register ? l10n.accountHaveOne : l10n.accountNeedOne)
                  .small(),
            ),
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.cancel),
        ),
        PrimaryButton(
          key: const Key('account-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_register ? l10n.accountCreate : l10n.accountSignIn),
        ),
      ],
    );
  }
}
