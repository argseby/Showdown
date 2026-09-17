import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/shared/poker_stickers.dart';
import 'package:showdown/shared/stickers.dart';

import 'test_helpers.dart';

void main() {
  test('every sticker id has its animation bundled, and nothing else', () {
    final files = Directory('assets/stickers')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.json'))
        .map((n) => n.substring(0, n.length - 5))
        .toSet();
    expect(emojiStickerIds.toSet(), files);
    expect(stickerIds.toSet().length, stickerIds.length);
    expect(stickerIds.take(pokerStickerIds.length), pokerStickerIds);
    expect(File('assets/stickers/README.md').existsSync(), isTrue);
  });

  testWidgets('every poker sticker builds and animates', (tester) async {
    for (final id in pokerStickerIds) {
      await tester.pumpWidget(
        wrap(Center(child: PokerSticker(id: id, size: 80))),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 450));
      }
      expect(find.byType(PokerSticker), findsOneWidget, reason: id);
      expect(tester.takeException(), isNull, reason: id);
    }
  });

  testWidgets('the picker lists every sticker and reports the tap', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      wrap(
        SingleChildScrollView(
          child: StickerPicker(onSelected: (id) => picked = id),
        ),
      ),
    );
    await tester.pump();
    for (final id in stickerIds) {
      expect(find.byKey(Key('sticker-$id')), findsOneWidget);
    }
    await tester.ensureVisible(find.byKey(const Key('sticker-fire')));
    await tester.tap(find.byKey(const Key('sticker-fire')));
    expect(picked, 'fire');
  });
}
