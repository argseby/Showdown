import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/shared/chips.dart';

import 'test_helpers.dart';

void main() {
  test('the ladder starts at half a big blind and climbs by fives', () {
    final l = ChipLadder.forBigBlind(100);
    expect(l.unit, 50);
    expect(
      [for (var r = 0; r < 9; r++) l.value(r)],
      [50, 250, 1250, 5000, 25000, 125000, 500000, 2500000, 12500000],
    );
    expect(l.topRung(49), 0);
    expect(l.topRung(5000), 3);
    expect(l.topRung(300000), 5);
    // Unknown or tiny blinds still give a one-chip unit.
    expect(ChipLadder.forBigBlind(0).unit, 1);
    expect(ChipLadder.forBigBlind(1).unit, 1);
  });

  test('piles add up to the amount, biggest first, in rung colours', () {
    final piles = decomposeChips(300000, bigBlind: 100);
    final sum = piles.fold(0, (s, p) => s + p.value * p.count);
    expect(sum, 300000);
    expect(piles.first.rung, 5);
    expect(piles.first.color, chipRungColor(5));
    for (var i = 1; i < piles.length; i++) {
      expect(piles[i].value, lessThan(piles[i - 1].value));
    }
    // Ten big blinds on a 50/100 table: two black chips would be too few,
    // so one is changed into greens.
    final tenBB = decomposeChips(1000, bigBlind: 100);
    expect(tenBB.fold(0, (s, p) => s + p.value * p.count), 1000);
    expect(
      chipCount(tenBB),
      chipTargetCount(1000, ChipLadder.forBigBlind(100)),
    );
    // Less than a unit is still one white chip.
    final tiny = decomposeChips(1, bigBlind: 100);
    expect(tiny.single.rung, 0);
    expect(tiny.single.count, 1);
    expect(decomposeChips(0, bigBlind: 100), isEmpty);
  });

  test('bigger amounts never show fewer chips than the log scale asks', () {
    final ladder = ChipLadder.forBigBlind(100);
    var lastTarget = 0;
    for (final amount in [
      50,
      100,
      300,
      1000,
      4999,
      5000,
      10000,
      300000,
      5000000,
    ]) {
      final piles = decomposeChips(amount, bigBlind: 100);
      final target = chipTargetCount(amount, ladder);
      expect(target, greaterThanOrEqualTo(lastTarget), reason: '$amount');
      lastTarget = target;
      final n = chipCount(piles);
      expect(n, inInclusiveRange(1, 14), reason: '$amount');
      expect(n, greaterThanOrEqualTo(target), reason: '$amount');
    }
    // The cap holds even for awkward change.
    expect(
      chipCount(decomposeChips(4999 * 50, bigBlind: 100)),
      lessThanOrEqualTo(14),
    );
    expect(
      chipCount(decomposeChips(123456789, bigBlind: 100, maxChips: 8)),
      lessThanOrEqualTo(8),
    );
  });

  test('columns hold at most eight chips and the drawn size follows', () {
    final piles = decomposeChips(14 * 50, bigBlind: 100, maxChips: 14);
    final cols = ChipStackView.columns(piles);
    for (final c in cols) {
      expect(c.$2, lessThanOrEqualTo(chipsPerColumn));
    }
    expect(chipColors(piles).length, chipCount(piles));
    final small = ChipStackView.sizeFor(
      ChipStackView.columns(decomposeChips(100, bigBlind: 100)),
      12,
    );
    final big = ChipStackView.sizeFor(cols, 12);
    expect(big.height, greaterThan(small.height));
  });

  testWidgets('the stack widget paints and grows with the amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Row(
          children: [
            ChipStackView(key: Key('small'), amount: 100, bigBlind: 100),
            ChipStackView(key: Key('big'), amount: 300000, bigBlind: 100),
          ],
        ),
      ),
    );
    await tester.pump();
    final small = tester.getSize(find.byKey(const Key('small')));
    final big = tester.getSize(find.byKey(const Key('big')));
    expect(big.width, greaterThan(small.width));
    expect(big.height, greaterThanOrEqualTo(small.height));
  });
}
