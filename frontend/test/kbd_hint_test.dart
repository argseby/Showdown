import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/features/table/shortcuts.dart';
import 'package:showdown/shared/kbd_hint.dart';

import 'test_helpers.dart';

void main() {
  /// A keyboard-sized window: the caps hide themselves on phones.
  Future<void> pumpHint(WidgetTester tester, {required bool holding}) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(wrap(KbdHint('O', holding: holding)));
  }

  double fill(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .widthFactor!;

  testWidgets('a held key cap fills up over the hold time', (tester) async {
    await pumpHint(tester, holding: true);
    expect(find.text('O'), findsOneWidget);
    expect(fill(tester), lessThan(0.2));
    await tester.pump(shortcutHoldDuration * 0.5);
    expect(fill(tester), greaterThan(0.3));
    await tester.pump(shortcutHoldDuration);
    expect(fill(tester), closeTo(1, 0.001));
  });

  testWidgets('a cap that is not held stays empty', (tester) async {
    await pumpHint(tester, holding: false);
    await tester.pump(shortcutHoldDuration);
    expect(fill(tester), 0);
  });
}
