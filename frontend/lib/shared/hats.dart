import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/l10n.dart';
import 'avatars.dart';

/// The hats a player may wear on their avatar, drawn on the client from a
/// few vector shapes (no assets, no network). Must match the server's
/// protocol.Hats; the server only knows the ids.
const hatIds = <String>[
  'top_hat',
  'cowboy',
  'crown',
  'party',
  'beanie',
  'wizard',
  'chef',
  'pirate',
  'cap',
  'halo',
  'viking',
  'sombrero',
  'fedora',
  'bowler',
  'santa',
  'tiara',
  'propeller',
  'bunny_ears',
  'flower_crown',
  'headband',
];

/// The wire value that takes the hat off.
const hatNone = 'none';

/// True when [hat] names a hat to draw.
bool wearsHat(String? hat) => hat != null && hat.isNotEmpty && hat != hatNone;

/// The translated name of a hat ("No hat" for none).
String hatLabel(AppLocalizations l10n, String? hat) =>
    wearsHat(hat) ? l10n.hatName(hat!) : l10n.hatNone;

/// How far (in avatar sizes) a hat reaches above the avatar disc, so that
/// it sits on top of the head (on a seat it may overlap the hole cards).
/// Pickers reserve this much space above each option.
const hatOverflow = 0.42;

/// Hat width relative to the avatar size.
const hatWidth = 1.0;

/// One hat, [width] wide, drawn to sit on the top of an avatar disc of the
/// same width. Its bottom quarter overlaps the disc.
class PlayerHat extends StatelessWidget {
  const PlayerHat({super.key, required this.hat, required this.width});

  final String hat;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('hat-worn-$hat'),
      width: width,
      height: width * _hatHeight,
      child: CustomPaint(painter: HatPainter(hat)),
    );
  }
}

/// Height of the hat box relative to its width.
const _hatHeight = 0.62;

/// A grid of every hat (plus "no hat") on the player's own avatar, the
/// chosen one outlined. [onSelected] receives a hat id or [hatNone].
class HatPicker extends StatelessWidget {
  const HatPicker({
    super.key,
    required this.selected,
    required this.avatar,
    required this.onSelected,
    this.size = 44,
  });

  /// The hat worn now; null, empty or [hatNone] for none.
  final String? selected;

  /// The avatar the hats are previewed on.
  final int avatar;
  final ValueChanged<String> onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = wearsHat(selected) ? selected : hatNone;
    return Padding(
      padding: EdgeInsets.only(top: size * hatOverflow),
      child: Wrap(
        spacing: 8,
        runSpacing: size * hatOverflow + 6,
        children: [
          for (final id in [hatNone, ...hatIds])
            Tooltip(
              tooltip: TooltipContainer(
                child: Text(hatLabel(l10n, id == hatNone ? null : id)),
              ).call,
              child: GestureDetector(
                key: Key('hat-option-$id'),
                onTap: () => onSelected(id),
                child: PlayerAvatar(
                  index: avatar,
                  size: size,
                  hat: id == hatNone ? null : id,
                  selected: id == current,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints one hat into a box; coordinates below are fractions of the box
/// (x 0..1 left to right, y 0..1 top to bottom). The bottom of the box lies
/// inside the avatar disc, so brims and cuffs may reach down to y = 0.9.
class HatPainter extends CustomPainter {
  const HatPainter(this.hat);

  final String hat;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset o(double x, double y) => Offset(x * w, y * h);
    Rect r(double x1, double y1, double x2, double y2) =>
        Rect.fromLTRB(x1 * w, y1 * h, x2 * w, y2 * h);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..color = const Color(0x55000000);
    void shape(Path path, Color color, {bool edge = true}) {
      canvas.drawPath(path, Paint()..color = color);
      if (edge) canvas.drawPath(path, outline);
    }

    void box(double x1, double y1, double x2, double y2, Color color) {
      shape(
        Path()..addRRect(
          RRect.fromRectAndRadius(r(x1, y1, x2, y2), Radius.circular(h * 0.06)),
        ),
        color,
      );
    }

    void dot(double x, double y, double radius, Color color) {
      canvas.drawCircle(o(x, y), radius * w, Paint()..color = color);
    }

    // A dome from (x1, base) to (x2, base) with its top at y = top.
    Path dome(double x1, double x2, double base, double top) => Path()
      ..moveTo(x1 * w, base * h)
      ..quadraticBezierTo(x1 * w, top * h, w / 2, top * h)
      ..quadraticBezierTo(x2 * w, top * h, x2 * w, base * h)
      ..close();

    switch (hat) {
      case 'top_hat':
        _tilt(canvas, size, -0.12);
        box(0.28, 0.02, 0.72, 0.8, const Color(0xFF263238));
        box(0.28, 0.6, 0.72, 0.72, const Color(0xFFD32F2F));
        box(0.06, 0.74, 0.94, 0.9, const Color(0xFF263238));
      case 'cowboy':
        final crown = Path()
          ..moveTo(0.32 * w, 0.74 * h)
          ..lineTo(0.3 * w, 0.25 * h)
          ..quadraticBezierTo(0.4 * w, 0.02 * h, 0.5 * w, 0.2 * h)
          ..quadraticBezierTo(0.6 * w, 0.02 * h, 0.7 * w, 0.25 * h)
          ..lineTo(0.68 * w, 0.74 * h)
          ..close();
        shape(crown, const Color(0xFF8D6E63));
        box(0.31, 0.6, 0.69, 0.72, const Color(0xFF3E2723));
        final brim = Path()
          ..moveTo(0.02 * w, 0.5 * h)
          ..quadraticBezierTo(0.04 * w, 0.92 * h, 0.3 * w, 0.88 * h)
          ..lineTo(0.7 * w, 0.88 * h)
          ..quadraticBezierTo(0.96 * w, 0.92 * h, 0.98 * w, 0.5 * h)
          ..quadraticBezierTo(0.9 * w, 0.74 * h, 0.7 * w, 0.74 * h)
          ..lineTo(0.3 * w, 0.74 * h)
          ..quadraticBezierTo(0.1 * w, 0.74 * h, 0.02 * w, 0.5 * h)
          ..close();
        shape(brim, const Color(0xFF795548));
      case 'crown':
        final points = Path()
          ..moveTo(0.15 * w, 0.9 * h)
          ..lineTo(0.15 * w, 0.22 * h)
          ..lineTo(0.32 * w, 0.5 * h)
          ..lineTo(0.5 * w, 0.06 * h)
          ..lineTo(0.68 * w, 0.5 * h)
          ..lineTo(0.85 * w, 0.22 * h)
          ..lineTo(0.85 * w, 0.9 * h)
          ..close();
        shape(points, const Color(0xFFFFC107));
        box(0.15, 0.74, 0.85, 0.9, const Color(0xFFFFA000));
        dot(0.3, 0.66, 0.045, const Color(0xFFE53935));
        dot(0.5, 0.66, 0.045, const Color(0xFF1E88E5));
        dot(0.7, 0.66, 0.045, const Color(0xFF43A047));
      case 'party':
        _tilt(canvas, size, 0.14);
        final cone = Path()
          ..moveTo(0.5 * w, 0.04 * h)
          ..lineTo(0.78 * w, 0.9 * h)
          ..lineTo(0.22 * w, 0.9 * h)
          ..close();
        shape(cone, const Color(0xFFEC407A));
        dot(0.5, 0.42, 0.045, const Color(0xFFFFEB3B));
        dot(0.4, 0.7, 0.045, const Color(0xFFFFEB3B));
        dot(0.6, 0.7, 0.045, const Color(0xFFFFEB3B));
        dot(0.5, 0.07, 0.09, const Color(0xFF29B6F6));
      case 'beanie':
        shape(dome(0.14, 0.86, 0.8, 0.12), const Color(0xFF1E88E5));
        box(0.1, 0.7, 0.9, 0.92, const Color(0xFF1565C0));
        dot(0.5, 0.13, 0.1, const Color(0xFFFAFAFA));
      case 'wizard':
        final cone = Path()
          ..moveTo(0.28 * w, 0.8 * h)
          ..lineTo(0.47 * w, 0.18 * h)
          ..quadraticBezierTo(0.5 * w, 0.0, 0.64 * w, 0.02 * h)
          ..quadraticBezierTo(0.55 * w, 0.08 * h, 0.56 * w, 0.2 * h)
          ..lineTo(0.72 * w, 0.8 * h)
          ..close();
        shape(cone, const Color(0xFF6A1B9A));
        box(0.04, 0.74, 0.96, 0.9, const Color(0xFF4A148C));
        dot(0.5, 0.5, 0.04, const Color(0xFFFFEE58));
        dot(0.42, 0.66, 0.03, const Color(0xFFFFEE58));
        dot(0.59, 0.66, 0.03, const Color(0xFFFFEE58));
      case 'chef':
        const white = Color(0xFFFAFAFA);
        final grey = outline..color = const Color(0x66757575);
        for (final (x, y, rad) in [
          (0.32, 0.4, 0.2),
          (0.68, 0.4, 0.2),
          (0.5, 0.28, 0.22),
        ]) {
          final puff = Path()
            ..addOval(Rect.fromCircle(center: o(x, y), radius: rad * w));
          canvas.drawPath(puff, Paint()..color = white);
          canvas.drawPath(puff, grey);
        }
        final band = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              r(0.24, 0.52, 0.76, 0.9),
              Radius.circular(h * 0.06),
            ),
          );
        canvas.drawPath(band, Paint()..color = white);
        canvas.drawPath(band, grey);
      case 'pirate':
        const black = Color(0xFF212121);
        shape(dome(0.28, 0.72, 0.7, 0.16), black);
        final brim = Path()
          ..moveTo(0.02 * w, 0.72 * h)
          ..quadraticBezierTo(0.08 * w, 0.3 * h, 0.2 * w, 0.62 * h)
          ..lineTo(0.8 * w, 0.62 * h)
          ..quadraticBezierTo(0.92 * w, 0.3 * h, 0.98 * w, 0.72 * h)
          ..quadraticBezierTo(0.75 * w, 0.94 * h, 0.5 * w, 0.92 * h)
          ..quadraticBezierTo(0.25 * w, 0.94 * h, 0.02 * w, 0.72 * h)
          ..close();
        shape(brim, black);
        dot(0.5, 0.46, 0.075, const Color(0xFFFAFAFA));
        dot(0.47, 0.44, 0.02, black);
        dot(0.53, 0.44, 0.02, black);
      case 'cap':
        shape(dome(0.16, 0.84, 0.76, 0.14), const Color(0xFFE53935));
        box(0.5, 0.7, 0.98, 0.84, const Color(0xFFB71C1C));
        dot(0.5, 0.15, 0.035, const Color(0xFFB71C1C));
      case 'halo':
        final ring = r(0.18, 0.28, 0.82, 0.56);
        canvas.drawOval(
          ring,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * 0.18
            ..color = const Color(0x44FFD54F),
        );
        canvas.drawOval(
          ring,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * 0.08
            ..color = const Color(0xFFFFD54F),
        );
      case 'viking':
        const horn = Color(0xFFFFF8E1);
        final left = Path()
          ..moveTo(0.3 * w, 0.64 * h)
          ..quadraticBezierTo(0.08 * w, 0.56 * h, 0.05 * w, 0.12 * h)
          ..quadraticBezierTo(0.18 * w, 0.34 * h, 0.32 * w, 0.42 * h)
          ..close();
        final right = Path()
          ..moveTo(0.7 * w, 0.64 * h)
          ..quadraticBezierTo(0.92 * w, 0.56 * h, 0.95 * w, 0.12 * h)
          ..quadraticBezierTo(0.82 * w, 0.34 * h, 0.68 * w, 0.42 * h)
          ..close();
        shape(left, horn);
        shape(right, horn);
        shape(dome(0.24, 0.76, 0.84, 0.2), const Color(0xFF90A4AE));
        box(0.22, 0.7, 0.78, 0.86, const Color(0xFF607D8B));
      case 'sombrero':
        final brim = Path()..addOval(r(0.0, 0.6, 1.0, 0.92));
        shape(brim, const Color(0xFFFBC02D));
        canvas.drawOval(
          r(0.06, 0.66, 0.94, 0.86),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * 0.04
            ..color = const Color(0xFFF57F17),
        );
        shape(dome(0.34, 0.66, 0.76, 0.06), const Color(0xFFF9A825));
        box(0.34, 0.58, 0.66, 0.7, const Color(0xFFD84315));
      case 'fedora':
        final crown = Path()
          ..moveTo(0.25 * w, 0.74 * h)
          ..lineTo(0.3 * w, 0.16 * h)
          ..quadraticBezierTo(0.5 * w, 0.02 * h, 0.7 * w, 0.16 * h)
          ..lineTo(0.75 * w, 0.74 * h)
          ..close();
        shape(crown, const Color(0xFF5D4037));
        // The pinch in the crown.
        canvas.drawLine(
          o(0.5, 0.1),
          o(0.5, 0.3),
          Paint()
            ..color = const Color(0x55000000)
            ..strokeWidth = w * 0.03
            ..strokeCap = StrokeCap.round,
        );
        box(0.25, 0.58, 0.75, 0.7, const Color(0xFF212121));
        shape(
          Path()..addOval(r(0.02, 0.62, 0.98, 0.9)),
          const Color(0xFF6D4C41),
        );
      case 'bowler':
        const dark = Color(0xFF263238);
        shape(dome(0.26, 0.74, 0.76, 0.1), dark);
        box(0.26, 0.62, 0.74, 0.72, const Color(0xFF455A64));
        shape(Path()..addOval(r(0.06, 0.64, 0.94, 0.9)), dark);
      case 'santa':
        final cap = Path()
          ..moveTo(0.22 * w, 0.78 * h)
          ..quadraticBezierTo(0.3 * w, 0.2 * h, 0.6 * w, 0.08 * h)
          ..quadraticBezierTo(0.82 * w, 0.0, 0.9 * w, 0.18 * h)
          ..quadraticBezierTo(0.72 * w, 0.14 * h, 0.64 * w, 0.32 * h)
          ..lineTo(0.78 * w, 0.78 * h)
          ..close();
        shape(cap, const Color(0xFFE53935));
        box(0.14, 0.72, 0.86, 0.92, const Color(0xFFFAFAFA));
        dot(0.9, 0.18, 0.09, const Color(0xFFFAFAFA));
      case 'tiara':
        final points = Path()
          ..moveTo(0.22 * w, 0.86 * h)
          ..lineTo(0.26 * w, 0.52 * h)
          ..lineTo(0.38 * w, 0.68 * h)
          ..lineTo(0.5 * w, 0.28 * h)
          ..lineTo(0.62 * w, 0.68 * h)
          ..lineTo(0.74 * w, 0.52 * h)
          ..lineTo(0.78 * w, 0.86 * h)
          ..close();
        shape(points, const Color(0xFFE0E0E0));
        dot(0.5, 0.5, 0.055, const Color(0xFFEC407A));
        dot(0.3, 0.68, 0.03, const Color(0xFF80DEEA));
        dot(0.7, 0.68, 0.03, const Color(0xFF80DEEA));
      case 'propeller':
        shape(dome(0.16, 0.84, 0.82, 0.3), const Color(0xFFFFB300));
        final wedge = Path()
          ..moveTo(0.5 * w, 0.82 * h)
          ..quadraticBezierTo(0.5 * w, 0.3 * h, 0.5 * w, 0.3 * h)
          ..quadraticBezierTo(0.7 * w, 0.32 * h, 0.78 * w, 0.82 * h)
          ..close();
        shape(wedge, const Color(0xFF1E88E5));
        canvas.drawLine(
          o(0.5, 0.3),
          o(0.5, 0.12),
          Paint()
            ..color = const Color(0xFF616161)
            ..strokeWidth = w * 0.035,
        );
        shape(
          Path()..addOval(r(0.18, 0.06, 0.5, 0.18)),
          const Color(0xFFE53935),
        );
        shape(
          Path()..addOval(r(0.5, 0.06, 0.82, 0.18)),
          const Color(0xFF43A047),
        );
        dot(0.5, 0.12, 0.04, const Color(0xFF616161));
      case 'bunny_ears':
        const fur = Color(0xFFFAFAFA);
        const inner = Color(0xFFF8BBD0);
        for (final x in [0.34, 0.66]) {
          shape(Path()..addOval(r(x - 0.11, 0.0, x + 0.11, 0.8)), fur);
          canvas.drawOval(
            r(x - 0.05, 0.1, x + 0.05, 0.68),
            Paint()..color = inner,
          );
        }
        box(0.18, 0.74, 0.82, 0.86, const Color(0xFF9E9E9E));
      case 'flower_crown':
        box(0.08, 0.62, 0.92, 0.8, const Color(0xFF66BB6A));
        for (final (x, y, c) in [
          (0.22, 0.7, const Color(0xFFF48FB1)),
          (0.42, 0.6, const Color(0xFFFFEE58)),
          (0.62, 0.62, const Color(0xFFFAFAFA)),
          (0.82, 0.7, const Color(0xFFCE93D8)),
        ]) {
          dot(x, y, 0.075, c);
          dot(x, y, 0.03, const Color(0xFFFFA000));
        }
      case 'headband':
        box(0.1, 0.5, 0.9, 0.74, const Color(0xFFEF5350));
        canvas.drawRect(
          r(0.1, 0.58, 0.9, 0.65),
          Paint()..color = const Color(0xFFFAFAFA),
        );
      default:
        // An id this client does not know (a newer server): draw nothing.
        break;
    }
  }

  /// Rotates the rest of the drawing by [radians] around the box center,
  /// for a jaunty angle.
  void _tilt(Canvas canvas, Size size, double radians) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(radians);
    canvas.translate(-size.width / 2, -size.height / 2);
  }

  @override
  bool shouldRepaint(HatPainter old) => old.hat != hat;
}
