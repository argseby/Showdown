import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/preferences.dart';
import '../../core/peer_prefs.dart';
import '../../protocol/protocol.dart';
import '../../shared/avatars.dart';

/// The pencil: off, drawing, or erasing. Lives outside the widget tree so
/// the top bar and the table share it.
enum DrawTool { none, pen, eraser }

class DrawToolNotifier extends Notifier<DrawTool> {
  @override
  DrawTool build() => DrawTool.none;

  void set(DrawTool tool) => state = tool;

  void toggle(DrawTool tool) => state = state == tool ? DrawTool.none : tool;
}

final drawToolProvider = NotifierProvider<DrawToolNotifier, DrawTool>(
  DrawToolNotifier.new,
);

/// Points per stroke sent: the server takes 400, but a stroke must stay
/// well under the 8 KiB message cap, and 200 points at three decimals is
/// under 3 KiB (a full-precision 400-point stroke was 16 KiB, and the
/// server closed the connection on it).
const maxStrokePoints = 200;

/// Rounds a normalized coordinate to three decimals (a tenth of a percent
/// of the table; finer is invisible and only costs bytes).
double roundCoord(double v) => (v.clamp(0.0, 1.0) * 1000).round() / 1000;

/// Reduces a stroke to at most [maxStrokePoints] points, keeping its ends.
List<Offset> thinStroke(List<Offset> points) {
  if (points.length <= maxStrokePoints) return points;
  final step = points.length / (maxStrokePoints - 1);
  return [
    for (var i = 0; i < maxStrokePoints - 1; i++) points[(i * step).floor()],
    points.last,
  ];
}

/// The drawings over the table: everyone's strokes (unless hidden), the
/// stroke being drawn, and the pointer handling of the pen and eraser.
/// Points travel normalized to this layer's size, so screens of different
/// sizes see the same picture (stretched a little when the aspect differs).
class DrawingLayer extends ConsumerStatefulWidget {
  const DrawingLayer({
    super.key,
    required this.strokes,
    required this.myPlayerId,
    this.onDraw,
    this.onErase,
  });

  final List<Stroke> strokes;
  final String? myPlayerId;

  /// Sends a finished stroke (normalized x,y pairs); null = cannot draw.
  final ValueChanged<List<double>>? onDraw;

  /// Erases strokes by id.
  final ValueChanged<List<int>>? onErase;

  @override
  ConsumerState<DrawingLayer> createState() => _DrawingLayerState();
}

class _DrawingLayerState extends ConsumerState<DrawingLayer> {
  final _current = <Offset>[];
  final _erased = <int>{};

  List<Stroke> _visible(Map<String, PeerPrefs> prefs, bool show) {
    if (!show) return const [];
    return [
      for (final s in widget.strokes)
        if (s.playerId == widget.myPlayerId ||
            !(prefs[s.playerId]?.hideDrawings ?? false))
          s,
    ];
  }

  void _eraseAt(Offset p, Size size, List<Stroke> strokes) {
    const reach = 14.0;
    for (final s in strokes) {
      if (_erased.contains(s.id)) continue;
      for (var i = 0; i + 1 < s.points.length; i += 2) {
        final q = Offset(
          s.points[i] * size.width,
          s.points[i + 1] * size.height,
        );
        if ((q - p).distance <= reach) {
          _erased.add(s.id);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(drawToolProvider);
    final show = ref.watch(showDrawingsProvider);
    final prefs = ref.watch(peerPrefsProvider);
    final strokes = _visible(prefs, show);
    final active =
        tool != DrawTool.none &&
        (tool == DrawTool.pen ? widget.onDraw != null : widget.onErase != null);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final paint = CustomPaint(
          key: const Key('drawing-layer'),
          size: size,
          painter: _StrokesPainter(strokes, _current, _erased, size),
        );
        if (!active) {
          return IgnorePointer(child: paint);
        }
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: GestureDetector(
            key: const Key('drawing-surface'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => setState(() {
              _current
                ..clear()
                ..add(d.localPosition);
              if (tool == DrawTool.eraser) {
                _eraseAt(d.localPosition, size, strokes);
              }
            }),
            onPanUpdate: (d) => setState(() {
              if (tool == DrawTool.pen) {
                _current.add(d.localPosition);
              } else {
                _eraseAt(d.localPosition, size, strokes);
              }
            }),
            onPanEnd: (_) => _finish(size),
            onPanCancel: () => _finish(size),
            child: paint,
          ),
        );
      },
    );
  }

  void _finish(Size size) {
    final tool = ref.read(drawToolProvider);
    if (tool == DrawTool.pen && _current.length >= 2) {
      final pts = thinStroke(List.of(_current));
      widget.onDraw?.call([
        for (final p in pts) ...[
          roundCoord(p.dx / size.width),
          roundCoord(p.dy / size.height),
        ],
      ]);
    }
    if (tool == DrawTool.eraser && _erased.isNotEmpty) {
      widget.onErase?.call(_erased.toList());
    }
    setState(() {
      _current.clear();
      _erased.clear();
    });
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes, this.current, this.erased, this.size);

  final List<Stroke> strokes;
  final List<Offset> current;
  final Set<int> erased;
  final Size size;

  @override
  void paint(Canvas canvas, Size _) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      if (s.points.length < 4) continue;
      paint.color = avatarColor(s.avatar)
          .withValues(alpha: erased.contains(s.id) ? 0.25 : 0.9);
      final path = Path()
        ..moveTo(s.points[0] * size.width, s.points[1] * size.height);
      for (var i = 2; i + 1 < s.points.length; i += 2) {
        path.lineTo(s.points[i] * size.width, s.points[i + 1] * size.height);
      }
      canvas.drawPath(path, paint);
    }
    if (current.length >= 2) {
      paint.color = const Color(0xFF9E9E9E);
      final path = Path()..moveTo(current[0].dx, current[0].dy);
      for (final p in current.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => true;
}
