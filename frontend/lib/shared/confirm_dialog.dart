import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Shows a yes/no dialog and resolves to true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showOverlay<bool>(
    context,
    const DialogConfiguration(),
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        OutlineButton(
          onPressed: () => closeOverlay<bool>(context, false),
          child: Text(cancelLabel),
        ),
        if (destructive)
          DestructiveButton(
            onPressed: () => closeOverlay<bool>(context, true),
            child: Text(confirmLabel),
          )
        else
          PrimaryButton(
            onPressed: () => closeOverlay<bool>(context, true),
            child: Text(confirmLabel),
          ),
      ],
    ),
  ).future;
  return result ?? false;
}
