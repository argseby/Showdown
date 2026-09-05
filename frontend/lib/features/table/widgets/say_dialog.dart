import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../shared/phrases.dart';
import '../table_session.dart';

/// Lets a player pick a quick phrase that everyone sees next to their
/// avatar for a few seconds.
Future<void> showSayDialog(
  BuildContext context,
  WidgetRef ref,
  String tableId,
) {
  final l10n = context.l10n;
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => AlertDialog(
      title: Text(l10n.sayTitle),
      content: SizedBox(
        width: 340,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final key in phraseKeys)
              OutlineButton(
                key: Key('say-$key'),
                size: ButtonSize.small,
                onPressed: () {
                  closeOverlay<void>(dialog);
                  ref.read(tableSessionProvider(tableId).notifier).say(key);
                },
                child: Text(phraseLabel(l10n, key)),
              ),
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => closeOverlay<void>(dialog),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  ).future;
}
