import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/shared/avatars.dart';
import 'package:showdown/shared/fire_ring.dart';
import 'package:showdown/shared/hats.dart';

import 'test_helpers.dart';

void main() {
  test('hat ids are distinct and "none" means no hat', () {
    expect(hatIds.toSet().length, hatIds.length);
    expect(hatIds, isNot(contains(hatNone)));
    expect(wearsHat(null), isFalse);
    expect(wearsHat(''), isFalse);
    expect(wearsHat(hatNone), isFalse);
    expect(wearsHat('crown'), isTrue);
  });

  testWidgets('an avatar draws its hat above the disc', (tester) async {
    await tester.pumpWidget(
      wrap(const Center(child: PlayerAvatar(index: 3, size: 40, hat: 'crown'))),
    );
    expect(find.byKey(const ValueKey('hat-worn-crown')), findsOneWidget);
    await tester.pumpWidget(
      wrap(const Center(child: PlayerAvatar(index: 3, size: 40))),
    );
    expect(find.byType(PlayerHat), findsNothing);
  });

  testWidgets('every hat paints', (tester) async {
    for (final id in hatIds) {
      await tester.pumpWidget(
        wrap(Center(child: PlayerHat(hat: id, width: 60))),
      );
      expect(find.byKey(ValueKey('hat-worn-$id')), findsOneWidget);
    }
  });

  testWidgets('the fire ring paints and flickers at every intensity', (
    tester,
  ) async {
    for (final i in [1, 2, 3]) {
      await tester.pumpWidget(
        wrap(
          Center(
            child: SizedBox(
              width: 54,
              height: 54,
              child: FireRing(intensity: i, ringSize: 54),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FireRing), findsOneWidget);
    }
  });

  testWidgets('the picker lists every hat plus none and reports the tap', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      wrap(
        HatPicker(selected: 'cap', avatar: 0, onSelected: (id) => picked = id),
      ),
    );
    for (final id in [hatNone, ...hatIds]) {
      expect(find.byKey(Key('hat-option-$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('hat-option-wizard')));
    expect(picked, 'wizard');
    await tester.tap(find.byKey(const Key('hat-option-none')));
    expect(picked, hatNone);
  });
}
