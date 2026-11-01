import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/providers.dart';
import 'revoked_sign_in.dart';

/// Says why a sign-in failed when the answer arrived through the address.
///
/// The page that started a sign-in waits for the answer itself, so this only
/// shows when the Revoked app could not reach this server and opened a
/// browser instead. An address without the parameter costs nothing.
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
    // take() also strips the parameter, so a reload says it only once.
    final error = ref.read(revokedBrowserProvider).take();
    if (error == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = revokedErrorText(context.l10n, error);
      showToast(
        context: context,
        location: ToastLocation.bottomCenter,
        builder: (context, overlay) => SurfaceCard(child: Text(text)),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
