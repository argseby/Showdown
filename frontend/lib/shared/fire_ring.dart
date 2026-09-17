import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Flames around a seat's avatar ring for a player running hot. The heat
/// levels are hands won in a row: 1 = two (small licks over the top of the
/// avatar), 2 = three (flames all around, taller), 3 = four or more (a
/// blaze with a white-hot core and a glow). The flames flicker continuously.
class FireRing extends StatefulWidget {
  const FireRing({super.key, required this.intensity, required this.ringSize});

  /// 1..3.
  final int intensity;

  /// Diameter of the ring the flames rise from.
  final double ringSize;

  @override
  State<FireRing> createState() => _FireRingState();
}

class _FireRingState extends State<FireRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.intensity.clamp(1, 3);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: FireRingPainter(
            intensity: i,
            ringSize: widget.ringSize,
            t: _c.value,
          ),
        ),
      ),
    );
  }
}

/// Paints fire as layered blobs around a circle of [ringSize]: each layer
/// is the circle plus a wavy, time-varying flame height, drawn from the
/// outside in (red, orange, yellow, then a pale core), so the tongues show
/// a hot center with cooler edges. Flames lean upwards like real fire: the
/// height is biased to the top of the ring. [t] in 0..1 is the animation
/// phase. Overflows its box by design (the stack does not clip).
class FireRingPainter extends CustomPainter {
  const FireRingPainter({
    required this.intensity,
    required this.ringSize,
    required this.t,
  });

  final int intensity;
  final double ringSize;
  final double t;

  /// Tallest flame per level, relative to the ring size.
  static const _height = [0.0, 0.3, 0.42, 0.58];

  /// How much of the ring the flames cover: level 1 mostly the upper half,
  /// level 3 everything.
  static const _bottom = [0.0, 0.08, 0.3, 0.55];

  static const _layers = [
    (scale: 1.0, color: Color(0xE6D32F2F)),
    (scale: 0.78, color: Color(0xFFFF6D00)),
    (scale: 0.55, color: Color(0xFFFFC107)),
    (scale: 0.32, color: Color(0xFFFFF8E1)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = ringSize / 2 - 1;
    final maxH = ringSize * _height[intensity];
    final phase = t * 2 * math.pi;
    const samples = 96;

    // Flame height at an angle: several travelling waves make tongues that
    // rise and fall; the product of two waves keeps them narrow and
    // irregular. Angles are measured clockwise from 3 o'clock (Flutter), so
    // the top of the ring is -pi/2.
    double height(double a) {
      final up = (-math.sin(a) + 1) / 2; // 1 at the top, 0 at the bottom
      final cover = _bottom[intensity] + (1 - _bottom[intensity]) * up;
      final w1 = 0.5 + 0.5 * math.sin(5 * a + 2 * phase);
      final w2 = 0.5 + 0.5 * math.sin(8 * a - 3 * phase + 1.3);
      final w3 = 0.5 + 0.5 * math.sin(13 * a + 5 * phase + 2.1);
      final tongues = math.pow(w1 * w2, 0.6) * (0.7 + 0.3 * w3);
      return maxH * cover * (0.22 + 0.78 * tongues);
    }

    Path blob(double scale) {
      final path = Path();
      for (var i = 0; i <= samples; i++) {
        final a = 2 * math.pi * i / samples;
        final radius = r + height(a) * scale;
        final p = center + Offset(math.cos(a), math.sin(a)) * radius;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      return path..close();
    }

    // Glow: a soft warm halo behind everything, brighter per level.
    canvas.drawCircle(
      center,
      r + maxH * 0.45,
      Paint()
        ..color = const Color(0xFFFF6D00)
            .withValues(alpha: 0.12 + 0.12 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxH * 0.6),
    );
    // Level 1 shows two layers, level 2 three, level 3 all four.
    final layers = _layers.take(intensity + 1).toList();
    for (var i = 0; i < layers.length; i++) {
      final l = layers[i];
      final paint = Paint()..color = l.color;
      if (i == 0) {
        // Soft outer edge; the inner layers stay crisp.
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, maxH * 0.06);
      }
      canvas.drawPath(blob(l.scale), paint);
    }
  }

  @override
  bool shouldRepaint(FireRingPainter old) =>
      old.t != t || old.intensity != intensity || old.ringSize != ringSize;
}
