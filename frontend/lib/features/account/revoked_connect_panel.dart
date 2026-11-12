import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/providers.dart';
import '../../core/rest_client.dart';

/// Shows a `revoked://connect` request and waits for the answer. Null when
/// the player closed the panel without one.
///
/// Signing in has a panel of its own: the official button brings one. This
/// is the other gesture the Revoked app is asked for — letting this instance
/// keep the table link in a vault — and the shape is the same from the
/// player's side: a code to compare, and a tap in the app.
Future<RevokedAnswer?> showRevokedConnectDialog(
  BuildContext context,
  RevokedStart start, {
  required String title,
  required Future<RevokedAnswer?> Function(String wait) poll,
}) => showOverlay<RevokedAnswer?>(
  context,
  const DialogConfiguration(),
  builder: (context) =>
      _RevokedConnectDialog(start: start, title: title, poll: poll),
).future;

class _RevokedConnectDialog extends ConsumerStatefulWidget {
  const _RevokedConnectDialog({
    required this.start,
    required this.title,
    required this.poll,
  });

  final RevokedStart start;
  final String title;
  final Future<RevokedAnswer?> Function(String wait) poll;

  @override
  ConsumerState<_RevokedConnectDialog> createState() =>
      _RevokedConnectDialogState();
}

class _RevokedConnectDialogState extends ConsumerState<_RevokedConnectDialog> {
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
      final answer = await widget.poll(widget.start.wait);
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
      title: Text(widget.title),
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
