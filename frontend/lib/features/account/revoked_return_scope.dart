import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/providers.dart';
import '../../core/rest_client.dart';
import '../../core/revoked_browser.dart';
import 'revoked_sign_in.dart';

/// Picks the revoked sign-in back up where it left off.
///
/// The sign-in leaves this page entirely, so the player returns to a fresh
/// app with a one-time code in the address. This sits above the router and
/// spends that code once, on the first frame: either the session is taken
/// and the player is simply signed in, or the identity is new here and the
/// handle dialog opens. An address with neither parameter costs nothing.
class RevokedReturnScope extends ConsumerStatefulWidget {
  const RevokedReturnScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RevokedReturnScope> createState() => _RevokedReturnScopeState();
}

class _RevokedReturnScopeState extends ConsumerState<RevokedReturnScope> {
  @override
  void initState() {
    super.initState();
    // take() also strips the parameters, so a reload cannot try to spend
    // a code that is already gone.
    final ret = ref.read(revokedBrowserProvider).take();
    if (ret.code == null && ret.error == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle(ret));
  }

  Future<void> _handle(RevokedReturn ret) async {
    if (!mounted) return;
    final l10n = context.l10n;

    if (ret.error != null) {
      _toast(switch (ret.error) {
        'access_denied' => l10n.revokedDeclined,
        'expired' || 'state_mismatch' => l10n.revokedExpired,
        _ => l10n.revokedFailed,
      });
      return;
    }
    try {
      final res = await ref.read(accountApiProvider).revokedFinish(ret.code!);
      if (!mounted) return;
      switch (res) {
        case RevokedSignedIn():
          await ref.read(accountProvider.notifier).adoptRevoked(res);
        case RevokedNeedsHandle():
          if (mounted) await showRevokedHandleDialog(context, res);
      }
    } on ApiException catch (e) {
      if (mounted) {
        _toast(
          e.code == 'revoked_sign_in_expired' ? l10n.revokedExpired : e.message,
        );
      }
    } catch (_) {
      if (mounted) _toast(l10n.revokedFailed);
    }
  }

  void _toast(String text) {
    showToast(
      context: context,
      location: ToastLocation.bottomCenter,
      builder: (context, overlay) => SurfaceCard(child: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
