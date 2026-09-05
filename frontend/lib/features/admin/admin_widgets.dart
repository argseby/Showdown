import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/rest_client.dart';
import '../../core/session_store.dart';

/// Runs an admin call for [tableId]. A 401 means the stored admin key is not
/// (or no longer) valid for this table: it is dropped and the user is told.
Future<T?> guardAdmin<T>(
  WidgetRef ref,
  BuildContext context,
  String tableId,
  Future<T> Function() call,
) async {
  try {
    return await call();
  } on ApiException catch (e) {
    if (e.status == 401) {
      await ref.read(adminTokenProvider(tableId).notifier).clear();
      if (context.mounted) {
        showAdminToast(context, context.l10n.adminKeyRejected);
      }
      return null;
    }
    if (context.mounted) {
      showAdminToast(context, context.l10n.errGeneric(e.message));
    }
    return null;
  }
}

/// Test hook: widget tests disable toasts because their auto-close timer
/// outlives the test body.
bool adminToastsEnabled = true;

void showAdminToast(BuildContext context, String text) {
  if (!adminToastsEnabled) return;
  showToast(
    context: context,
    location: ToastLocation.bottomCenter,
    builder: (context, overlay) => SurfaceCard(child: Text(text)),
  );
}

/// Full join link for a table, based on the current page origin.
String joinLinkFor(String tableId) {
  final base = Uri.base;
  final origin =
      '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
  return '$origin/t/$tableId';
}

/// Badge for a table state.
class StateBadge extends StatelessWidget {
  const StateBadge({super.key, required this.state});
  final String state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (state) {
      'waiting' => l10n.joinStateWaiting,
      'running' => l10n.joinStateRunning,
      'paused' => l10n.joinStatePaused,
      _ => l10n.joinStateEnded,
    };
    return state == 'running'
        ? PrimaryBadge(child: Text(label))
        : SecondaryBadge(child: Text(label));
  }
}

Future<void> showQrDialog(BuildContext context, String title, String link) {
  final l10n = context.l10n;
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.all(8),
            child: QrImageView(data: link, size: 220),
          ),
          const Gap(12),
          SelectableText(
            link,
            style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12),
          ),
        ],
      ),
      actions: [
        PrimaryButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    ),
  ).future;
}
