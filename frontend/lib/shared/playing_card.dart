import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'suit_painter.dart';

/// A playing card drawn with a [CustomPainter] (no image assets). Pass null
/// for a face-down card. Card strings are two characters, e.g. "As", "Td".
class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    this.card,
    this.width = 44,
    this.highlighted = false,
    this.highlightColor,
    this.fourColor = false,
  });

  final String? card;
  final double width;

  /// Part of the highlighted hand (the winner's five at showdown, or the
  /// viewer's live hand).
  final bool highlighted;

  /// Border colour of the highlight (theme primary when null).
  final Color? highlightColor;
  final bool fourColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // "" marks a card that stays face down in a partial reveal.
    final card = this.card == null || this.card!.isEmpty ? null : this.card;
    return Semantics(
      label: card == null ? 'face-down card' : cardLabel(card),
      child: CustomPaint(
        size: Size(width, width * 1.4),
        painter: _CardPainter(
          card: card,
          highlight: highlighted
              ? (highlightColor ?? theme.colorScheme.primary)
              : null,
          backColor: cardBack,
          backAccent: const Color(0xFFFFFFFF),
          fourColor: fourColor,
        ),
      ),
    );
  }
}

/// Card back: a fixed navy in both themes (a theme colour turned the backs
/// into black blocks in the light theme).
const cardBack = Color(0xFF2B4C7E);

const _rankNames = {
  'A': 'Ace',
  'K': 'King',
  'Q': 'Queen',
  'J': 'Jack',
  'T': 'Ten',
  '9': 'Nine',
  '8': 'Eight',
  '7': 'Seven',
  '6': 'Six',
  '5': 'Five',
  '4': 'Four',
  '3': 'Three',
  '2': 'Two',
};
const _suitNames = {
  's': 'spades',
  'h': 'hearts',
  'd': 'diamonds',
  'c': 'clubs',
};

/// Accessible label such as "Ace of spades".
String cardLabel(String card) {
  if (card.length != 2) return card;
  return '${_rankNames[card[0]] ?? card[0]} of ${_suitNames[card[1]] ?? card[1]}';
}

/// Suit color: red/black, or the four-color deck.
Color suitColor(String suit, {bool fourColor = false}) {
  switch (suit) {
    case 'h':
      return const Color(0xFFD32F2F);
    case 'd':
      return fourColor ? const Color(0xFF1E88E5) : const Color(0xFFD32F2F);
    case 'c':
      return fourColor ? const Color(0xFF2E7D32) : const Color(0xFF111111);
    default:
      return const Color(0xFF111111);
  }
}

class _CardPainter extends CustomPainter {
  _CardPainter({
    required this.card,
    required this.highlight,
    required this.backColor,
    required this.backAccent,
    required this.fourColor,
  });

  final String? card;
  final Color? highlight;
  final Color backColor;
  final Color backAccent;
  final bool fourColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.12),
    );
    canvas.drawShadow(Path()..addRRect(r), const Color(0x66000000), 2, false);
    if (card == null) {
      canvas.drawRRect(r, Paint()..color = backColor);
      final inner = r.deflate(size.width * 0.1);
      canvas.drawRRect(
        inner,
        Paint()
          ..color = backAccent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final stripe = Paint()
        ..color = backAccent.withValues(alpha: 0.25)
        ..strokeWidth = 1;
      for (var y = inner.top + 6; y < inner.bottom; y += 6) {
        canvas.drawLine(
          Offset(inner.left + 3, y),
          Offset(inner.right - 3, y),
          stripe,
        );
      }
      return;
    }
    canvas.drawRRect(r, Paint()..color = const Color(0xFFFFFFFF));
    if (highlight != null) {
      canvas.drawRRect(
        r.deflate(1.5),
        Paint()
          ..color = highlight!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else {
      canvas.drawRRect(
        r.deflate(0.5),
        Paint()
          ..color = const Color(0xFFBDBDBD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    final rank = card![0] == 'T' ? '10' : card![0];
    final suit = card![1];
    final color = suitColor(suit, fourColor: fourColor);

    final rankPainter = TextPainter(
      text: TextSpan(
        text: rank,
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.42,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    rankPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.06));

    final small = size.width * 0.26;
    paintSuit(
      canvas,
      Rect.fromLTWH(
        size.width * 0.11,
        size.height * 0.06 + rankPainter.height + 1,
        small,
        small,
      ),
      suit,
      color,
    );
    final big = size.width * 0.5;
    paintSuit(
      canvas,
      Rect.fromLTWH(
        size.width - big - size.width * 0.12,
        size.height - big - size.height * 0.08,
        big,
        big,
      ),
      suit,
      color,
    );
  }

  @override
  bool shouldRepaint(_CardPainter old) =>
      old.card != card ||
      old.highlight != highlight ||
      old.fourColor != fourColor ||
      old.backColor != backColor;
}
