import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/features/table/widgets/table_view.dart';

/// Whether [p] lies inside the stadium [felt] (rectangle with round ends).
bool _inFelt(Rect felt, Offset p) {
  final h = felt.height / 2;
  final half = math.max(0.0, felt.width / 2 - h);
  final x = (p.dx - felt.center.dx).clamp(-half, half);
  return (p - Offset(felt.center.dx + x, felt.center.dy)).distance <= h;
}

void main() {
  for (final (size, seats, clear) in [
    (const Size(1020, 758), 9, true),
    (const Size(1300, 700), 10, true),
    (const Size(700, 400), 9, true),
    // A phone in portrait: no clear felt could hold the board, so the
    // plain inset applies and only its size is checked.
    (const Size(380, 520), 6, false),
  ]) {
    test('the felt clears every seat box at $size with $seats seats', () {
      final compact = size.width < 700 || size.height < 480;
      final seatW = math.min(compact ? 84.0 : 112.0, size.width / 4.4);
      final seatH = math.min(compact ? 150.0 : 180.0, size.height / 3.2);
      final oval = Rect.fromLTWH(
        seatW / 2 + 4,
        seatH / 2 + 4,
        math.max(40, size.width - seatW - 8),
        math.max(40, size.height - seatH - 8),
      );
      final boxes = <Rect>[];
      for (var pos = 0; pos < seats; pos++) {
        final p = TableView.seatPoint(pos, seats, oval);
        boxes.add(
          Rect.fromLTWH(
            (p.dx - seatW / 2).clamp(0.0, size.width - seatW),
            (p.dy - seatH / 2).clamp(0.0, size.height - seatH),
            seatW,
            seatH,
          ),
        );
      }
      final felt = feltRect(
        oval: oval,
        boxes: boxes,
        seatW: seatW,
        seatH: seatH,
        compact: compact,
      );
      // No box edge point may be inside the felt.
      for (final b in clear ? boxes : const <Rect>[]) {
        for (var t = 0.0; t <= 1.0; t += 0.05) {
          final pts = [
            Offset(b.left + b.width * t, b.top),
            Offset(b.left + b.width * t, b.bottom),
            Offset(b.left, b.top + b.height * t),
            Offset(b.right, b.top + b.height * t),
          ];
          for (final p in pts) {
            expect(_inFelt(felt, p), isFalse, reason: 'box $b touches $felt');
          }
        }
      }
      // And the felt is still a usable table, not a dot.
      expect(felt.width, greaterThan(size.width * 0.45));
      expect(felt.height, greaterThan(size.height * 0.2));
      expect(felt.width, greaterThanOrEqualTo(felt.height));
      // Every seat's action point lies inside the felt.
      for (final b in boxes) {
        expect(_inFelt(felt, actionPoint(felt, b.center)), isTrue);
      }
    });
  }
}
