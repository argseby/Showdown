import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Casino colours by denomination rung: white, red, green, black, purple,
/// orange, yellow, light blue, pink, brown; rungs beyond that wrap around.
const List<Color> chipRungColors = [
  Color(0xFFF2F2F2),
  Color(0xFFD32F2F),
  Color(0xFF2E7D32),
  Color(0xFF212121),
  Color(0xFF7B1FA2),
  Color(0xFFEF6C00),
  Color(0xFFFBC02D),
  Color(0xFF4FC3F7),
  Color(0xFFEC407A),
  Color(0xFF6D4C41),
];

/// The colour of denomination rung [rung].
Color chipRungColor(int rung) => chipRungColors[rung % chipRungColors.length];

/// The denominations of a table. One unit is half a big blind (so a small
/// blind is a whole chip), then the classic 1 / 5 / 25 / 100 / 500 / 2,500 /
/// 10,000 ladder and five times the previous rung for every rung beyond;
/// the ladder is open-ended so any stack finds its colours.
class ChipLadder {
  ChipLadder.forBigBlind(int bigBlind) : unit = math.max(1, bigBlind ~/ 2);

  /// The value of the smallest chip.
  final int unit;

  static const _base = [1, 5, 25, 100, 500, 2500, 10000];

  /// The chip value of rung [rung] (0 = white).
  int value(int rung) {
    if (rung < _base.length) return unit * _base[rung];
    var v = unit * _base.last;
    for (var i = _base.length; i <= rung; i++) {
      v *= 5;
    }
    return v;
  }

  /// The highest rung whose chip fits into [amount] (0 when nothing does).
  int topRung(int amount) {
    var rung = 0;
    while (value(rung + 1) <= amount) {
      rung++;
    }
    return rung;
  }
}

/// Chips of one denomination in a stack.
class ChipPile {
  const ChipPile({
    required this.rung,
    required this.value,
    required this.count,
  });

  final int rung;
  final int value;
  final int count;

  Color get color => chipRungColor(rung);

  ChipPile copyWith({int? count}) =>
      ChipPile(rung: rung, value: value, count: count ?? this.count);
}

/// How many chips a stack of [amount] should show at least: about two per
/// order of magnitude above one unit, so bigger amounts are visibly bigger
/// without a 300-chip pile.
int chipTargetCount(int amount, ChipLadder ladder, {int maxChips = 14}) {
  if (amount <= 0) return 0;
  final units = amount / ladder.unit;
  if (units < 1) return 1;
  final target = (2 * math.log(units) / math.ln10).round() + 1;
  return target.clamp(1, maxChips);
}

/// Breaks [amount] into denomination piles for display, biggest value
/// first. Chips are made greedily; while the stack is smaller than
/// [chipTargetCount] the smallest breakable chip is changed into the next
/// rung down, and beyond [maxChips] the smallest piles are dropped
/// (the exact amount is always shown as text next to a stack).
List<ChipPile> decomposeChips(
  int amount, {
  required int bigBlind,
  int maxChips = 14,
}) {
  if (amount <= 0) return const [];
  final ladder = ChipLadder.forBigBlind(bigBlind);
  if (amount < ladder.unit) {
    return [ChipPile(rung: 0, value: ladder.value(0), count: 1)];
  }
  final top = ladder.topRung(amount);
  final counts = List<int>.filled(top + 1, 0);
  var rest = amount;
  for (var rung = top; rung >= 0; rung--) {
    final v = ladder.value(rung);
    counts[rung] = rest ~/ v;
    rest -= counts[rung] * v;
  }
  int total() => counts.fold(0, (a, b) => a + b);
  // Pad small stacks: change the smallest chip that has a rung below it
  // into that rung's chips (four or five of them, the ladder is uneven).
  final target = chipTargetCount(amount, ladder, maxChips: maxChips);
  while (total() < target) {
    var broke = false;
    for (var rung = 1; rung <= top; rung++) {
      final into = ladder.value(rung) ~/ ladder.value(rung - 1);
      if (counts[rung] > 0 && total() + into - 1 <= maxChips) {
        counts[rung]--;
        counts[rung - 1] += into;
        broke = true;
        break;
      }
    }
    if (!broke) break;
  }
  // Trim big stacks: drop the smallest piles first.
  for (var rung = 0; rung <= top && total() > maxChips; rung++) {
    final over = total() - maxChips;
    counts[rung] = math.max(0, counts[rung] - over);
  }
  return [
    for (var rung = top; rung >= 0; rung--)
      if (counts[rung] > 0)
        ChipPile(rung: rung, value: ladder.value(rung), count: counts[rung]),
  ];
}

/// The number of chips in [piles].
int chipCount(List<ChipPile> piles) => piles.fold(0, (sum, p) => sum + p.count);

/// Every chip of [piles] as its own colour, biggest value first.
List<Color> chipColors(List<ChipPile> piles) => [
  for (final p in piles)
    for (var i = 0; i < p.count; i++) p.color,
];

/// Chips per column before a pile continues in the next column.
const int chipsPerColumn = 8;

/// A drawn stack of chips for [amount]: one column per denomination,
/// biggest value on the left, seen from a low angle.
class ChipStackView extends StatelessWidget {
  const ChipStackView({
    super.key,
    required this.amount,
    required this.bigBlind,
    this.chipWidth = 12,
    this.maxChips = 14,
  });

  final int amount;
  final int bigBlind;

  /// The diameter of one chip; the thickness and the spacing follow.
  final double chipWidth;
  final int maxChips;

  /// The columns of the stack: (colour, chips) left to right.
  static List<(Color, int)> columns(List<ChipPile> piles) => [
    for (final p in piles)
      for (var left = p.count; left > 0; left -= chipsPerColumn)
        (p.color, math.min(left, chipsPerColumn)),
  ];

  /// The painted size of a stack with [columns] at [chipWidth].
  static Size sizeFor(List<(Color, int)> columns, double chipWidth) {
    if (columns.isEmpty) return Size.zero;
    final tallest = columns.fold(0, (m, c) => math.max(m, c.$2));
    return Size(
      chipWidth + (columns.length - 1) * chipWidth * 0.92,
      _StackPainter.height(tallest, chipWidth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final piles = decomposeChips(
      amount,
      bigBlind: bigBlind,
      maxChips: maxChips,
    );
    final cols = columns(piles);
    return CustomPaint(
      size: sizeFor(cols, chipWidth),
      painter: _StackPainter(cols, chipWidth),
    );
  }
}

class _StackPainter extends CustomPainter {
  _StackPainter(this.columns, this.chipWidth);

  final List<(Color, int)> columns;
  final double chipWidth;

  static double thickness(double w) => w * 0.24;
  static double ry(double w) => w * 0.2;
  static double height(int chips, double w) =>
      chips <= 0 ? 0 : (chips - 1) * thickness(w) + 2 * ry(w);

  @override
  void paint(Canvas canvas, Size size) {
    final w = chipWidth;
    final rx = w / 2;
    final t = thickness(w);
    var x = rx;
    for (final (color, count) in columns) {
      for (var i = 0; i < count; i++) {
        final cy = size.height - ry(w) - i * t;
        paintChipSide(
          canvas,
          Offset(x, cy),
          rx,
          ry(w),
          color,
          top: i == count - 1,
        );
      }
      x += w * 0.92;
    }
  }

  @override
  bool shouldRepaint(_StackPainter old) =>
      old.chipWidth != chipWidth || !_sameColumns(old.columns, columns);

  static bool _sameColumns(List<(Color, int)> a, List<(Color, int)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Paints one chip of a stack seen from a low angle: an ellipse in the
/// chip's colour with a darker rim; the top chip also shows its edge marks
/// and inner ring.
void paintChipSide(
  Canvas canvas,
  Offset center,
  double rx,
  double ry,
  Color color, {
  required bool top,
}) {
  final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
  final rim = Color.lerp(color, const Color(0xFF000000), 0.35)!;
  canvas.drawOval(rect, Paint()..color = color);
  canvas.drawOval(
    rect,
    Paint()
      ..color = rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, rx * 0.12),
  );
  if (!top) return;
  final marks = Paint()
    ..color = _edgeColor(color)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, rx * 0.22);
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3;
    final from = Offset(
      center.dx + math.cos(a) * rx * 0.72,
      center.dy + math.sin(a) * ry * 0.72,
    );
    final to = Offset(
      center.dx + math.cos(a) * rx * 0.98,
      center.dy + math.sin(a) * ry * 0.98,
    );
    canvas.drawLine(from, to, marks);
  }
  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 1.1, height: ry * 1.1),
    Paint()
      ..color = _edgeColor(color).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, rx * 0.12),
  );
}

/// White edge marks on dark chips, dark ones on the white chip.
Color _edgeColor(Color chip) => chip.computeLuminance() > 0.6
    ? const Color(0xFF3A3A3A)
    : const Color(0xFFFFFFFF);
