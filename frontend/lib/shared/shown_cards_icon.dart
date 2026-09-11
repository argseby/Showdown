import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Two hole cards as a small icon: a white card carries a little ace and
/// is the one on show, a black card is still hidden. Used where the
/// show-cards buttons have no room for words.
class ShownCardsIcon extends StatelessWidget {
  const ShownCardsIcon({
    super.key,
    required this.first,
    required this.second,
    this.size = 20,
  });

  /// Whether the first / second card is drawn face up (white).
  final bool first;
  final bool second;

  /// Height of the icon; the two cards side by side are 1.4 times as wide.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.4, size),
      painter: _ShownCardsPainter(first: first, second: second),
    );
  }
}

class _ShownCardsPainter extends CustomPainter {
  const _ShownCardsPainter({required this.first, required this.second});
  final bool first;
  final bool second;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = h * 0.72;
    final gap = h * 0.08;
    final left = (size.width - (2 * w + gap)) / 2;
    _card(canvas, Rect.fromLTWH(left, 0, w, h), first);
    _card(canvas, Rect.fromLTWH(left + w + gap, 0, w, h), second);
  }

  void _card(Canvas canvas, Rect r, bool faceUp) {
    final radius = Radius.circular(r.height * 0.12);
    final rr = RRect.fromRectAndRadius(r, radius);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = faceUp ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = faceUp ? const Color(0xFF444444) : const Color(0xFFBBBBBB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.height * 0.06,
    );
    if (!faceUp) return;
    // The little ace: an "A" drawn as strokes in the top-left corner, as
    // on the card itself (no glyph, so no fallback font is ever needed).
    final a = Rect.fromLTWH(
      r.left + r.width * 0.14,
      r.top + r.height * 0.1,
      r.width * 0.34,
      r.height * 0.3,
    );
    final stroke = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.height * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(a.left, a.bottom)
      ..lineTo(a.center.dx, a.top)
      ..lineTo(a.right, a.bottom)
      ..moveTo(a.left + a.width * 0.22, a.top + a.height * 0.62)
      ..lineTo(a.right - a.width * 0.22, a.top + a.height * 0.62);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ShownCardsPainter old) =>
      old.first != first || old.second != second;
}
