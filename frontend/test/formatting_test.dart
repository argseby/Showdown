import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/core/formatting.dart';

void main() {
  test('amounts switch between chips and big blinds', () {
    expect(formatAmount(300, mode: ChipDisplay.coins, bigBlind: 100), '300');
    expect(
      formatAmount(300, mode: ChipDisplay.bigBlinds, bigBlind: 100),
      '3 BB',
    );
    expect(
      formatAmount(250, mode: ChipDisplay.bigBlinds, bigBlind: 100),
      '2.5 BB',
    );
    expect(
      formatAmount(25, mode: ChipDisplay.bigBlinds, bigBlind: 100),
      '0.25 BB',
    );
    // Without a known big blind the coins are shown.
    expect(formatAmount(300, mode: ChipDisplay.bigBlinds, bigBlind: 0), '300');
    expect(parseBigBlinds('3', 100), 300);
    expect(parseBigBlinds('2,5', 100), 250);
    expect(parseBigBlinds('x', 100), isNull);
  });
}
