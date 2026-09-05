import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'playing_card.dart';

/// Paints a card suit as a vector shape so that no glyph fallback font is
/// ever needed (the web engine would otherwise fetch Noto fonts).
void paintSuit(Canvas canvas, Rect r, String suit, Color color) {
  final paint = Paint()..color = color;
  final w = r.width;
  final h = r.height;
  final cx = r.center.dx;
  final path = Path();
  switch (suit) {
    case 'h':
      path.moveTo(cx, r.bottom);
      path.cubicTo(
        r.left - w * 0.05,
        r.top + h * 0.55,
        r.left + w * 0.05,
        r.top - h * 0.05,
        cx,
        r.top + h * 0.28,
      );
      path.cubicTo(
        r.right - w * 0.05,
        r.top - h * 0.05,
        r.right + w * 0.05,
        r.top + h * 0.55,
        cx,
        r.bottom,
      );
      path.close();
      canvas.drawPath(path, paint);
    case 'd':
      path.moveTo(cx, r.top);
      path.lineTo(r.right, r.center.dy);
      path.lineTo(cx, r.bottom);
      path.lineTo(r.left, r.center.dy);
      path.close();
      canvas.drawPath(path, paint);
    case 's':
      final body = Rect.fromLTWH(r.left, r.top, w, h * 0.78);
      path.moveTo(cx, body.top);
      path.cubicTo(
        body.right + w * 0.05,
        body.top + h * 0.35,
        body.right,
        body.bottom,
        cx,
        body.bottom - h * 0.12,
      );
      path.cubicTo(
        body.left,
        body.bottom,
        body.left - w * 0.05,
        body.top + h * 0.35,
        cx,
        body.top,
      );
      path.close();
      canvas.drawPath(path, paint);
      _stem(canvas, r, paint);
    default:
      final rad = w * 0.24;
      canvas.drawCircle(Offset(cx, r.top + rad), rad, paint);
      canvas.drawCircle(Offset(r.left + rad, r.top + h * 0.5), rad, paint);
      canvas.drawCircle(Offset(r.right - rad, r.top + h * 0.5), rad, paint);
      canvas.drawCircle(Offset(cx, r.top + h * 0.5), rad * 0.9, paint);
      _stem(canvas, r, paint);
  }
}

void _stem(Canvas canvas, Rect r, Paint paint) {
  final cx = r.center.dx;
  final stem = Path()
    ..moveTo(cx, r.top + r.height * 0.55)
    ..lineTo(cx + r.width * 0.22, r.bottom)
    ..lineTo(cx - r.width * 0.22, r.bottom)
    ..close();
  canvas.drawPath(stem, paint);
}

/// A small suit symbol widget.
class SuitIcon extends StatelessWidget {
  const SuitIcon(
    this.suit, {
    super.key,
    this.size = 12,
    this.fourColor = false,
    this.blackSuit,
  });

  final String suit;
  final double size;
  final bool fourColor;

  /// Color for the black suits (spades, and clubs without the four-color
  /// deck). Inline text uses the theme foreground so that the suits stay
  /// visible on a dark background.
  final Color? blackSuit;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _SuitIconPainter(
      suit,
      inlineSuitColor(suit, fourColor: fourColor, blackSuit: blackSuit),
    ),
  );
}

/// Suit color for inline text: like [suitColor], but black suits take
/// [blackSuit] when given.
Color inlineSuitColor(String suit, {bool fourColor = false, Color? blackSuit}) {
  final black = suit == 's' || (suit == 'c' && !fourColor);
  if (black && blackSuit != null) return blackSuit;
  return suitColor(suit, fourColor: fourColor);
}

class _SuitIconPainter extends CustomPainter {
  _SuitIconPainter(this.suit, this.color);
  final String suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintSuit(
    canvas,
    (Offset.zero & size).deflate(size.width * 0.05),
    suit,
    color,
  );

  @override
  bool shouldRepaint(_SuitIconPainter old) =>
      old.suit != suit || old.color != color;
}

final _cardToken = RegExp('(10|[2-9TJQKA])([♠♥♦♣])');
const _symbolToSuit = {'♠': 's', '♥': 'h', '♦': 'd', '♣': 'c'};

/// Turns text containing card symbols (e.g. "A♥ 7♣") into spans where each
/// suit is a painted [SuitIcon]; plain text is kept as-is.
List<InlineSpan> cardSpans(
  String text, {
  TextStyle? style,
  double iconSize = 11,
  bool fourColor = false,
  Color? blackSuit,
}) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _cardToken.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: style));
    }
    final suit = _symbolToSuit[m.group(2)]!;
    spans.add(
      TextSpan(
        text: m.group(1),
        style: (style ?? const TextStyle()).copyWith(
          color: inlineSuitColor(
            suit,
            fourColor: fourColor,
            blackSuit: blackSuit,
          ),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(left: 1, right: 2),
          child: SuitIcon(
            suit,
            size: iconSize,
            fourColor: fourColor,
            blackSuit: blackSuit,
          ),
        ),
      ),
    );
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: style));
  }
  return spans;
}
