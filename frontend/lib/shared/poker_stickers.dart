import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'chip_stack.dart';
import 'playing_card.dart';

/// Poker stickers drawn in code from the app's own cards and chips (no
/// assets, no licence to carry): short looping scenes. Ids must match the
/// server's protocol.Stickers.
const pokerStickerIds = <String>[
  'all_in',
  'pocket_aces',
  'seven_deuce',
  'fold',
  'royal_flush',
  'chip_rain',
  'shuffle',
  'dealer_button',
  'chip_flip',
  'bad_beat',
  'quads',
  'straight',
  'hearts',
  'tilt',
  'cooler',
  'river',
  'pot_splash',
  'fish',
  'shark',
  'knock',
  'raise',
  'time',
];

/// One looping poker scene, [size] square.
class PokerSticker extends StatefulWidget {
  const PokerSticker({super.key, required this.id, required this.size});

  final String id;
  final double size;

  @override
  State<PokerSticker> createState() => _PokerStickerState();
}

class _PokerStickerState extends State<PokerSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            _Scene(id: widget.id, t: _c.value, size: widget.size),
      ),
    );
  }
}

/// Builds the scene for [id] at phase [t] (0..1) in a [size] square.
class _Scene extends StatelessWidget {
  const _Scene({required this.id, required this.t, required this.size});

  final String id;
  final double t;
  final double size;

  double get cw => size * 0.34; // card width
  double get ch => cw * 1.4;

  /// Progress of a sub-animation between [a] and [b], eased, clamped.
  double seg(double a, double b, [Curve curve = Curves.easeInOut]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  Offset p(double x, double y) => Offset(x * size, y * size);

  /// A card centred at [c], rotated by [angle], squashed by [scaleX] (a
  /// flip), faded by [opacity]. [face] null = back.
  Widget card(
    String? face, {
    required Offset c,
    double angle = 0,
    double scaleX = 1,
    double opacity = 1,
    double scale = 1,
  }) => Positioned(
    left: c.dx - cw / 2,
    top: c.dy - ch / 2,
    child: Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scaleX: scaleX * scale,
          scaleY: scale,
          child: PlayingCardWidget(card: face, width: cw),
        ),
      ),
    ),
  );

  /// A card flipping from its back to [face] between [a] and [b].
  Widget flip(
    String face, {
    required double a,
    required double b,
    required Offset c,
    double angle = 0,
  }) {
    final s = seg(a, b, Curves.linear);
    final shown = s > 0.5;
    return card(
      shown ? face : null,
      c: c,
      angle: angle,
      scaleX: math.cos(s * math.pi).abs(),
    );
  }

  Widget chip(Offset c, Color color, {double d = 0.22, double scaleY = 1}) =>
      Positioned(
        left: c.dx - d * size / 2,
        top: c.dy - d * size / 2,
        child: Transform.scale(
          scaleY: scaleY,
          child: ChipIcon(size: d * size, color: color),
        ),
      );

  /// A bold label popping in from [a].
  Widget label(
    String text, {
    required double a,
    Color color = const Color(0xFFFFD54F),
    double y = 0.86,
  }) {
    final s = seg(a, a + 0.15, Curves.easeOutBack);
    return Positioned(
      left: 0,
      right: 0,
      top: y * size - size * 0.08,
      child: Transform.scale(
        scale: s,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size * 0.16,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1,
            shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 4)],
          ),
        ),
      ),
    );
  }

  static const _chipColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF212121),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: _children()),
    );
  }

  List<Widget> _children() {
    switch (id) {
      case 'all_in':
        // A stack slides to the middle, then its top chips hop off.
        final slide = seg(0.05, 0.45, Curves.easeOutCubic);
        final x = 0.22 + 0.28 * slide;
        final hop = seg(0.5, 0.85, Curves.easeOut);
        return [
          for (var i = 0; i < 7; i++)
            () {
              var c = p(x, 0.72 - i * 0.06);
              if (i >= 4 && hop > 0) {
                final k = i - 3;
                c += Offset(
                  size * 0.12 * k * hop,
                  -size * 0.25 * math.sin(hop * math.pi) +
                      size * 0.02 * k * hop,
                );
              }
              return chip(c, _chipColors[i % _chipColors.length]);
            }(),
          label('ALL IN', a: 0.5, y: 0.3),
        ];
      case 'pocket_aces':
        return [
          flip('As', a: 0.25, b: 0.5, c: p(0.4, 0.5), angle: -0.12),
          flip('Ah', a: 0.4, b: 0.65, c: p(0.6, 0.52), angle: 0.12),
          _sparkle(p(0.2, 0.2), 0.7),
          _sparkle(p(0.82, 0.25), 0.8),
        ];
      case 'seven_deuce':
        return [
          flip('7s', a: 0.25, b: 0.5, c: p(0.4, 0.5), angle: -0.12),
          flip('2h', a: 0.4, b: 0.65, c: p(0.6, 0.52), angle: 0.12),
          label('BLUFF', a: 0.7, color: const Color(0xFFFF7043)),
        ];
      case 'fold':
        // Two cards flung off to the top right, spinning and fading.
        final s = seg(0.2, 0.75, Curves.easeInCubic);
        return [
          for (var i = 0; i < 2; i++)
            card(
              null,
              c: p(0.4 + 0.15 * i + 0.5 * s, 0.6 - 0.05 * i - 0.6 * s),
              angle: (i == 0 ? -0.15 : 0.15) + s * 3 * (i == 0 ? 1 : -1),
              opacity: 1 - s * 0.9,
            ),
          label('FOLD', a: 0.55, color: const Color(0xFFB0BEC5)),
        ];
      case 'royal_flush':
        // Five spades fan out from a stack; stars twinkle once open.
        final fan = seg(0.1, 0.6, Curves.easeOutBack);
        const faces = ['Ts', 'Js', 'Qs', 'Ks', 'As'];
        return [
          for (var i = 0; i < 5; i++)
            card(
              faces[i],
              c: p(
                0.5 + (i - 2) * 0.13 * fan,
                0.58 + (i - 2).abs() * 0.02 * fan,
              ),
              angle: (i - 2) * 0.28 * fan,
              scale: 0.9,
            ),
          _sparkle(p(0.15, 0.2), 0.65),
          _sparkle(p(0.5, 0.1), 0.75),
          _sparkle(p(0.85, 0.2), 0.85),
        ];
      case 'chip_rain':
        // Chips fall on their own rhythms and bounce at the bottom.
        return [
          for (var i = 0; i < 8; i++)
            () {
              final phase = (t + i * 0.137) % 1;
              final fall = Curves.easeIn.transform(math.min(1, phase * 1.3));
              final bounce = phase > 0.77
                  ? math.sin((phase - 0.77) / 0.23 * math.pi) * 0.08
                  : 0.0;
              final x = 0.1 + (i * 0.37) % 0.8;
              return chip(
                p(x, -0.15 + 1.0 * fall - bounce),
                _chipColors[i % _chipColors.length],
                d: 0.16,
              );
            }(),
        ];
      case 'shuffle':
        // A riffle: cards from two halves drop into the middle in turns.
        return [
          for (var i = 0; i < 8; i++)
            () {
              final left = i.isEven;
              final phase = ((t * 2 + i * 0.12) % 1);
              final lift = math.sin(phase * math.pi);
              final x = left ? 0.3 + 0.2 * phase : 0.7 - 0.2 * phase;
              return card(
                null,
                c: p(x, 0.55 - lift * 0.18 - i * 0.012),
                angle:
                    (left ? -0.25 : 0.25) * (1 - phase) +
                    (left ? 0.5 : -0.5) * lift,
                scale: 0.8,
              );
            }(),
        ];
      case 'dealer_button':
        // The D button spins on its edge with a passing shine.
        final spin = math.cos(t * 2 * math.pi);
        final d = size * 0.6;
        return [
          Positioned(
            left: (size - d) / 2,
            top: (size - d) / 2,
            child: Transform.scale(
              scaleX: spin.abs().clamp(0.08, 1.0),
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFAFAFA),
                  border: Border.all(
                    color: const Color(0xFF9E9E9E),
                    width: d * 0.05,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'D',
                  style: TextStyle(
                    fontSize: d * 0.55,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF212121),
                  ),
                ),
              ),
            ),
          ),
        ];
      case 'chip_flip':
        // A chip tossed up, flipping edge over edge, caught again.
        final up = math.sin(t * math.pi);
        return [
          chip(
            p(0.5, 0.78 - 0.55 * up),
            const Color(0xFFE53935),
            d: 0.34,
            scaleY: math.cos(t * 6 * math.pi).abs().clamp(0.06, 1.0),
          ),
          Positioned(
            left: size * 0.32,
            top: size * 0.86,
            child: Container(
              width: size * 0.36,
              height: size * 0.06,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                color: Color.fromRGBO(0, 0, 0, 0.35 * (1 - up)),
              ),
            ),
          ),
        ];
      case 'bad_beat':
        // Aces struck by lightning; the cards shake after the hit.
        final strike = seg(0.35, 0.5, Curves.easeOut);
        final after = t > 0.45 ? (1 - seg(0.45, 0.9, Curves.linear)) : 0.0;
        final shake = math.sin(t * 60) * size * 0.02 * after;
        return [
          card('Ah', c: p(0.4, 0.62) + Offset(shake, 0), angle: -0.12),
          card('Ad', c: p(0.6, 0.64) + Offset(-shake, 0), angle: 0.12),
          if (strike > 0 && t < 0.75)
            Positioned(
              left: size * 0.3,
              top: 0,
              child: Opacity(
                opacity: t < 0.6 ? 1 : 1 - seg(0.6, 0.75, Curves.linear),
                child: CustomPaint(
                  size: Size(size * 0.4, size * 0.55 * strike),
                  painter: const _BoltPainter(),
                ),
              ),
            ),
        ];
      case 'quads':
        // Four aces turn over one after another.
        return [
          for (var i = 0; i < 4; i++)
            flip(
              const ['As', 'Ah', 'Ad', 'Ac'][i],
              a: 0.08 + 0.14 * i,
              b: 0.28 + 0.14 * i,
              c: p(0.26 + 0.16 * i, 0.5),
              angle: (i - 1.5) * 0.06,
            ),
          label('QUADS', a: 0.75),
        ];
      case 'straight':
        // Five to nine slide in from the left like carriages of a train.
        const faces = ['5h', '6s', '7d', '8c', '9h'];
        return [
          for (var i = 0; i < 5; i++)
            () {
              final s = seg(
                0.05 + 0.08 * i,
                0.4 + 0.08 * i,
                Curves.easeOutBack,
              );
              return card(
                faces[i],
                c: p(-0.3 + (0.18 + 0.16 * i + 0.3) * s, 0.5),
                angle: (1 - s) * -0.3,
                scale: 0.85,
              );
            }(),
          label('STRAIGHT', a: 0.7),
        ];
      case 'hearts':
        // A fan of hearts with little hearts floating up.
        final fan = seg(0.1, 0.6, Curves.easeOutBack);
        const faces = ['Th', 'Jh', 'Qh', 'Kh', 'Ah'];
        return [
          for (var i = 0; i < 5; i++)
            card(
              faces[i],
              c: p(
                0.5 + (i - 2) * 0.13 * fan,
                0.6 + (i - 2).abs() * 0.02 * fan,
              ),
              angle: (i - 2) * 0.28 * fan,
              scale: 0.9,
            ),
          for (var i = 0; i < 3; i++)
            () {
              final phase = (t + i * 0.33) % 1;
              return Positioned(
                left: size * (0.2 + 0.3 * i) - size * 0.07,
                top: size * (0.45 - 0.45 * phase),
                child: Opacity(
                  opacity: (1 - phase).clamp(0.0, 1.0),
                  child: Icon(
                    LucideIcons.heart,
                    size: size * (0.1 + 0.05 * phase),
                    color: const Color(0xFFE53935),
                  ),
                ),
              );
            }(),
        ];
      case 'tilt':
        // Cards and chips rattle inside a red haze.
        final j = math.sin(t * 90) * size * 0.02;
        final k = math.cos(t * 70) * 0.06;
        return [
          Positioned(
            left: size * 0.1,
            top: size * 0.1,
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(
                  229,
                  57,
                  53,
                  0.25 + 0.15 * math.sin(t * 2 * math.pi),
                ),
              ),
            ),
          ),
          card('Kh', c: p(0.38, 0.55) + Offset(j, -j), angle: -0.15 + k),
          card('Ks', c: p(0.58, 0.57) + Offset(-j, j), angle: 0.15 - k),
          for (var i = 0; i < 3; i++)
            chip(
              p(0.8, 0.78 - i * 0.07) + Offset(-j * (i + 1), 0),
              _chipColors[i],
              d: 0.16,
            ),
          label('TILT', a: 0.0, color: const Color(0xFFFF5252), y: 0.25),
        ];
      case 'cooler':
        // Kings frozen by an ace: frost gathers on the cards.
        final frost = seg(0.2, 0.7, Curves.easeOut);
        return [
          card('Kd', c: p(0.38, 0.55), angle: -0.12),
          card('Kc', c: p(0.58, 0.57), angle: 0.12),
          for (var i = 0; i < 4; i++)
            Positioned(
              left: size * const [0.22, 0.62, 0.42, 0.72][i] - size * 0.08,
              top: size * const [0.3, 0.28, 0.72, 0.62][i] - size * 0.08,
              child: Transform.rotate(
                angle: t * 2 * math.pi * (i.isEven ? 1 : -1),
                child: Opacity(
                  opacity: frost,
                  child: Icon(
                    LucideIcons.snowflake,
                    size: size * 0.16,
                    color: const Color(0xFF81D4FA),
                  ),
                ),
              ),
            ),
          label('COOLER', a: 0.55, color: const Color(0xFF81D4FA), y: 0.92),
        ];
      case 'river':
        // Four on the board, the fifth slams down with a splash.
        final drop = seg(0.2, 0.45, Curves.easeInCubic);
        final splash = seg(0.45, 0.8, Curves.easeOut);
        return [
          for (var i = 0; i < 4; i++)
            card(
              const ['As', 'Kd', '7c', '2d'][i],
              c: p(0.2 + 0.15 * i, 0.32),
              scale: 0.6,
            ),
          card(
            'Qh',
            c: p(0.8, 0.32 - 0.6 * (1 - drop)),
            scale: 0.6 + 0.3 * (1 - drop),
          ),
          if (splash > 0)
            for (var i = 0; i < 6; i++)
              () {
                final a = -math.pi * (0.15 + 0.14 * i);
                final r = size * 0.22 * splash;
                final c =
                    p(0.8, 0.45) +
                    Offset(
                      math.cos(a) * r,
                      math.sin(a) * r + size * 0.15 * splash * splash,
                    );
                return Positioned(
                  left: c.dx - size * 0.05,
                  top: c.dy - size * 0.05,
                  child: Opacity(
                    opacity: 1 - splash,
                    child: Icon(
                      LucideIcons.droplet,
                      size: size * 0.1,
                      color: const Color(0xFF4FC3F7),
                    ),
                  ),
                );
              }(),
          label('RIVER!', a: 0.5, color: const Color(0xFF4FC3F7), y: 0.82),
        ];
      case 'pot_splash':
        // Chips burst out of the middle and rain down.
        final burst = seg(0.1, 0.7, Curves.easeOut);
        return [
          for (var i = 0; i < 10; i++)
            () {
              final a = 2 * math.pi * i / 10 - math.pi / 2;
              final r = size * 0.42 * burst;
              final c =
                  p(0.5, 0.5) +
                  Offset(
                    math.cos(a) * r,
                    math.sin(a) * r + size * 0.35 * burst * burst,
                  );
              return Positioned(
                left: c.dx - size * 0.08,
                top: c.dy - size * 0.08,
                child: Opacity(
                  opacity: (1.4 - burst).clamp(0.0, 1.0),
                  child: ChipIcon(
                    size: size * 0.16,
                    color: _chipColors[i % _chipColors.length],
                  ),
                ),
              );
            }(),
          chip(
            p(0.5, 0.55),
            const Color(0xFFFDD835),
            d: 0.26 * (1 - burst * 0.5),
          ),
          label('SPLASH', a: 0.4, y: 0.9),
        ];
      case 'fish':
        // A fish swims back and forth, blowing bubbles.
        final x = 0.5 + 0.28 * math.sin(t * 2 * math.pi);
        final facingLeft = math.cos(t * 2 * math.pi) < 0;
        return [
          for (var i = 0; i < 3; i++)
            () {
              final phase = (t * 1.5 + i * 0.33) % 1;
              return Positioned(
                left: size * (0.3 + 0.2 * i) - size * 0.03,
                top: size * (0.5 - 0.45 * phase),
                child: Opacity(
                  opacity: 1 - phase,
                  child: Container(
                    width: size * 0.06 * (0.5 + phase),
                    height: size * 0.06 * (0.5 + phase),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF81D4FA),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            }(),
          Positioned(
            left: size * x - size * 0.25,
            top: size * (0.42 + 0.04 * math.sin(t * 6 * math.pi)) - size * 0.25,
            child: Transform.scale(
              scaleX: facingLeft ? 1 : -1,
              child: Icon(
                LucideIcons.fish,
                size: size * 0.5,
                color: const Color(0xFFFFA726),
              ),
            ),
          ),
          label('FISH', a: 0.0, color: const Color(0xFF81D4FA)),
        ];
      case 'shark':
        return [
          Positioned.fill(child: CustomPaint(painter: _SharkPainter(t))),
          label('SHARK', a: 0.0, color: const Color(0xFFB0BEC5), y: 0.2),
        ];
      case 'knock':
        // Two knocks on the felt: rings ripple out from a fist-sized spot.
        Widget ring(double start) {
          final s = seg(start, start + 0.45, Curves.easeOut);
          if (s == 0 || s == 1) return const SizedBox();
          final d = size * (0.2 + 0.7 * s);
          return Positioned(
            left: (size - d) / 2,
            top: (size - d) / 2 + size * 0.05,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromRGBO(255, 255, 255, 1 - s),
                  width: size * 0.03,
                ),
              ),
            ),
          );
        }
        final press = math.max(
          seg(0.1, 0.18, Curves.easeOut) * (1 - seg(0.18, 0.3, Curves.easeOut)),
          seg(0.45, 0.53, Curves.easeOut) *
              (1 - seg(0.53, 0.65, Curves.easeOut)),
        );
        return [
          ring(0.18),
          ring(0.53),
          chip(
            p(0.5, 0.55 + 0.03 * press),
            const Color(0xFF43A047),
            d: 0.3 - 0.04 * press,
          ),
          label('CHECK', a: 0.7),
        ];
      case 'raise':
        // Three columns of chips, each one taller than the last.
        return [
          for (var col = 0; col < 3; col++)
            for (var i = 0; i < 3 + 3 * col; i++)
              () {
                final appear = seg(
                  0.08 + 0.09 * col + 0.05 * i,
                  0.18 + 0.09 * col + 0.05 * i,
                  Curves.easeOutBack,
                );
                if (appear == 0) return const SizedBox();
                return chip(
                  p(0.22 + 0.28 * col, 0.82 - i * 0.055 - 0.1 * (1 - appear)),
                  _chipColors[(col * 2 + i) % _chipColors.length],
                  d: 0.19 * appear,
                );
              }(),
          label('RAISE', a: 0.75, y: 0.22),
        ];
      case 'time':
        // The hourglass turns over, then the sand runs (pulsing label).
        final turn = seg(0.35, 0.6, Curves.easeInOut);
        final pulse = 1 + 0.08 * math.sin(t * 8 * math.pi);
        return [
          Positioned(
            left: size * 0.5 - size * 0.25,
            top: size * 0.45 - size * 0.25,
            child: Transform.rotate(
              angle: turn * math.pi,
              child: Icon(
                LucideIcons.hourglass,
                size: size * 0.5,
                color: const Color(0xFFFFCA28),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: size * 0.8,
            child: Transform.scale(
              scale: pulse,
              child: Text(
                'TIME!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF5252),
                  shadows: const [
                    Shadow(color: Color(0xCC000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  /// A twinkling star.
  Widget _sparkle(Offset c, double phase) {
    final glow = (math.sin((t - phase) * 2 * math.pi) + 1) / 2;
    return Positioned(
      left: c.dx - size * 0.08,
      top: c.dy - size * 0.08,
      child: Opacity(
        opacity: glow,
        child: Icon(
          LucideIcons.sparkles,
          size: size * 0.16,
          color: const Color(0xFFFFD54F),
        ),
      ),
    );
  }
}

/// A shark fin cruising through waves.
class _SharkPainter extends CustomPainter {
  const _SharkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Fin: rides left to right, tilted into the swim direction.
    final x = w * (0.15 + 0.7 * ((t + 0.25) % 1));
    final fin = Path()
      ..moveTo(x - w * 0.14, h * 0.62)
      ..quadraticBezierTo(x - w * 0.02, h * 0.55, x + w * 0.05, h * 0.3)
      ..quadraticBezierTo(x + w * 0.08, h * 0.5, x + w * 0.16, h * 0.62)
      ..close();
    canvas.drawPath(fin, Paint()..color = const Color(0xFF546E7A));
    // Two wave lines in front of the fin.
    for (var i = 0; i < 2; i++) {
      final wave = Path()..moveTo(0, h * (0.64 + 0.1 * i));
      for (var px = 0.0; px <= w; px += w / 24) {
        wave.lineTo(
          px,
          h * (0.64 + 0.1 * i) +
              math.sin(px / w * 4 * math.pi + t * 2 * math.pi * (i + 1)) *
                  h *
                  0.025,
        );
      }
      canvas.drawPath(
        wave,
        Paint()
          ..color = i == 0 ? const Color(0xFF4FC3F7) : const Color(0xFF0288D1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }
    // Water below the first wave hides the fin's base.
    final water = Path()
      ..moveTo(0, h * 0.66)
      ..lineTo(w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(water, Paint()..color = const Color(0x8801579B));
  }

  @override
  bool shouldRepaint(_SharkPainter old) => old.t != t;
}

/// A lightning bolt filling its box from the top.
class _BoltPainter extends CustomPainter {
  const _BoltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bolt = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w * 0.25, h * 0.55)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.35, h)
      ..lineTo(w * 0.8, h * 0.4)
      ..lineTo(w * 0.55, h * 0.4)
      ..lineTo(w * 0.75, 0)
      ..close();
    canvas.drawPath(
      bolt,
      Paint()
        ..color = const Color(0x88FFEE58)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFEE58));
  }

  @override
  bool shouldRepaint(_BoltPainter old) => false;
}
