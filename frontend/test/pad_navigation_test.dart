import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/gamepad/pad_navigation.dart';

void main() {
  // A settings page: the back arrow top left, three rows with a button at
  // the right end of each.
  const back = Rect.fromLTWH(10, 10, 30, 30);
  const row1 = Rect.fromLTWH(300, 60, 80, 24);
  const row2 = Rect.fromLTWH(300, 100, 80, 24);
  const row3 = Rect.fromLTWH(300, 140, 80, 24);
  const rows = [row1, row2, row3];

  test('down from the back arrow reaches the first row button', () {
    expect(padNeighbour(back, rows, TraversalDirection.down), 0);
    expect(padNeighbour(row1, [back, row2, row3], TraversalDirection.down), 1);
    expect(padNeighbour(row3, [back, row1, row2], TraversalDirection.up), 2);
  });

  test('nothing lies in the direction: the cursor stays', () {
    expect(padNeighbour(back, rows, TraversalDirection.up), isNull);
    expect(padNeighbour(back, rows, TraversalDirection.left), isNull);
    expect(
      padNeighbour(row3, [back, row1, row2], TraversalDirection.down),
      isNull,
    );
  });

  test('a control in the same column wins over a closer one to the side', () {
    const from = Rect.fromLTWH(100, 100, 80, 24);
    const below = Rect.fromLTWH(100, 200, 80, 24);
    const aside = Rect.fromLTWH(240, 130, 80, 24);
    expect(padNeighbour(from, [aside, below], TraversalDirection.down), 1);
    expect(padNeighbour(from, [aside, below], TraversalDirection.right), 0);
  });
}
