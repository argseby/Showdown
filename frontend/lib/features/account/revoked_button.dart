import 'package:shadcn_flutter/shadcn_flutter.dart';

/// The Revoked mark: four bars, as the official button's inline SVG draws
/// them (viewBox `100 100 300 300`, so the origin below is that corner).
class _RevokedMark extends CustomPainter {
  const _RevokedMark(this.color);

  final Color color;

  /// x, y, width, height in the 300×300 box, taken from the published
  /// snippet with the viewBox origin subtracted.
  static const _bars = <List<double>>[
    [0, 0, 300, 44],
    [40, 85.33, 220, 44],
    [0, 170.67, 300, 44],
    [80, 256, 140, 44],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 300;
    final paint = Paint()..color = color;
    for (final b in _bars) {
      canvas.drawRect(
        Rect.fromLTWH(b[0] * s, b[1] * s, b[2] * s, b[3] * s),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RevokedMark old) => old.color != color;
}

/// "Sign in with Revoked", drawn the way revoked publishes it: black with
/// white text and mark, 10px corners, the mark 18px with a 10px gap. One
/// button covers a light and a dark page, so it does not follow our theme.
class RevokedButton extends StatelessWidget {
  const RevokedButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: onPressed == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(painter: _RevokedMark(white)),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: white,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
