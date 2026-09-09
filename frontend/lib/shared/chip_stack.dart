import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/preferences.dart';
import '../core/formatting.dart';

/// A small painted chip icon followed by a formatted amount (coins or big
/// blinds, per the display preference when [bigBlind] is known).
class ChipAmount extends ConsumerWidget {
  const ChipAmount({
    super.key,
    required this.amount,
    this.size = 14,
    this.style,
    this.bigBlind = 0,
  });

  final int amount;
  final double size;
  final TextStyle? style;
  final int bigBlind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final mode = ref.watch(chipDisplayProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChipIcon(size: size, color: chipAmountColor(amount)),
        const Gap(4),
        Text(
          formatAmount(amount, mode: mode, bigBlind: bigBlind, locale: locale),
          style: style,
        ),
      ],
    );
  }
}

/// The colour of the single chip icon next to an amount.
Color chipAmountColor(int amount) {
  if (amount >= 5000) return const Color(0xFF8E24AA);
  if (amount >= 1000) return const Color(0xFF1E1E1E);
  if (amount >= 500) return const Color(0xFF3949AB);
  if (amount >= 100) return const Color(0xFF43A047);
  return const Color(0xFFE53935);
}

/// A single poker chip drawn with a [CustomPainter].
class ChipIcon extends StatelessWidget {
  const ChipIcon({
    super.key,
    this.size = 16,
    this.color = const Color(0xFFE53935),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ChipPainter(color));
}

class _ChipPainter extends CustomPainter {
  _ChipPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22,
    );
    final edge = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = r * 0.3
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < 6; i++) {
      final a = i * 3.14159265 / 3;
      final from = c + Offset.fromDirection(a, r * 0.78);
      final to = c + Offset.fromDirection(a, r);
      canvas.drawLine(from, to, edge);
    }
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.color != color;
}
