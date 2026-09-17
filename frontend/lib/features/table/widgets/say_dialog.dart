import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../shared/phrases.dart';
import '../../../shared/stickers.dart';
import '../table_session.dart';

/// Lets a player pick a quick phrase or a sticker that everyone sees next
/// to their avatar for a few seconds.
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
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sayPhrases.toUpperCase()).muted().xSmall().semiBold(),
              const Gap(6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final key in phraseKeys)
                    OutlineButton(
                      key: Key('say-$key'),
                      size: ButtonSize.small,
                      onPressed: () {
                        closeOverlay<void>(dialog);
                        ref
                            .read(tableSessionProvider(tableId).notifier)
                            .say(phrase: key);
                      },
                      child: Text(phraseLabel(l10n, key)),
                    ),
                ],
              ),
              const Gap(12),
              Text(l10n.sayStickers.toUpperCase()).muted().xSmall().semiBold(),
              const Gap(6),
              StickerPicker(
                onSelected: (id) {
                  closeOverlay<void>(dialog);
                  ref
                      .read(tableSessionProvider(tableId).notifier)
                      .say(sticker: id);
                },
              ),
            ],
          ),
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
