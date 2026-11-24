import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/standings.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';

/// The categorical series colors of the leaderboard chart, in fixed order
/// (validated for colour-vision deficiency on the light and the dark
/// surface). A player keeps their colour whatever is filtered: it follows
/// their place on the all-time board, not their rank in the chart.
const _seriesLight = [
  Color(0xFF2A78D6),
  Color(0xFFEB6834),
  Color(0xFF1BAF7A),
  Color(0xFFEDA100),
  Color(0xFFE87BA4),
  Color(0xFF008300),
  Color(0xFF6250D6),
  Color(0xFFE34948),
];
const _seriesDark = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
  Color(0xFF0CA30C),
  Color(0xFF9085E9),
  Color(0xFFE66767),
];

/// How many players the chart draws; the rest stay in the board.
const chartTopPlayers = 6;

Color seriesColor(int slot, Brightness brightness) {
  final list = brightness == Brightness.dark ? _seriesDark : _seriesLight;
  return list[slot % list.length];
}

/// The running net of the leading players over the rounds, with a hover (or
/// tap) crosshair that reads every line out at one round.
class NetChart extends StatefulWidget {
  const NetChart({
    super.key,
    required this.labels,
    required this.series,
    required this.slotOf,
    required this.amount,
    this.liveLast = false,
  });

  /// One label per point on the x axis ("1", "2", … "now").
  final List<String> labels;
  final List<NetSeries> series;

  /// The colour slot of a player (see [seriesColor]).
  final int Function(String name) slotOf;
  final String Function(int) amount;

  /// The last point is the round being played: drawn dashed, it still moves.
  final bool liveLast;

  @override
  State<NetChart> createState() => _NetChartState();
}

class _NetChartState extends State<NetChart> {
  int? _hover;

  static const _height = 150.0;
  static const _left = 6.0;
  static const _right = 10.0;
  static const _top = 8.0;
  static const _bottom = 18.0;

  int _indexAt(double dx, double width) {
    final n = widget.labels.length;
    if (n <= 1) return 0;
    final step = (width - _left - _right) / (n - 1);
    return ((dx - _left) / step).round().clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final brightness = theme.colorScheme.brightness;
    final muted = TextStyle(
      fontSize: 11,
      color: theme.colorScheme.mutedForeground,
    );
    final colors = [
      for (final s in widget.series)
        seriesColor(widget.slotOf(s.name), brightness),
    ];

    final hover = _hover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            void track(Offset p) {
              final i = _indexAt(p.dx, width);
              if (i != _hover) setState(() => _hover = i);
            }

            return MouseRegion(
              onHover: (e) => track(e.localPosition),
              onExit: (_) => setState(() => _hover = null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => track(d.localPosition),
                onHorizontalDragUpdate: (d) => track(d.localPosition),
                child: SizedBox(
                  key: const Key('leaderboard-chart'),
                  width: width,
                  height: _height,
                  child: CustomPaint(
                    painter: _NetChartPainter(
                      labels: widget.labels,
                      series: widget.series,
                      colors: colors,
                      hover: hover,
                      liveLast: widget.liveLast,
                      surface: theme.colorScheme.background,
                      grid: theme.colorScheme.border,
                      axisText: muted,
                      amount: widget.amount,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (hover != null) ...[
          const Gap(4),
          _ChartReadout(
            title: hover == widget.labels.length - 1 && widget.liveLast
                ? l10n.lbIncludesLive
                : l10n.lbChartAfterRound(
                    int.tryParse(widget.labels[hover]) ?? 0,
                  ),
            rows: [
              for (var i = 0; i < widget.series.length; i++)
                if (widget.series[i].points[hover] != null)
                  (
                    name: widget.series[i].name,
                    color: colors[i],
                    value: widget.series[i].points[hover]!,
                  ),
            ]..sort((a, b) => b.value.compareTo(a.value)),
            amount: widget.amount,
          ),
        ],
        const Gap(6),
        // The legend: identity is never colour alone.
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (var i = 0; i < widget.series.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      widget.series[i].name,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ChartReadout extends StatelessWidget {
  const _ChartReadout({
    required this.title,
    required this.rows,
    required this.amount,
  });

  final String title;
  final List<({String name, Color color, int value})> rows;
  final String Function(int) amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title).xSmall().semiBold(),
          for (final r in rows)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: r.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(6),
                Expanded(
                  child: Text(r.name, overflow: TextOverflow.ellipsis).xSmall(),
                ),
                Text(r.value > 0 ? '+${amount(r.value)}' : amount(r.value))
                    .xSmall()
                    .semiBold(),
              ],
            ),
        ],
      ),
    );
  }
}

class _NetChartPainter extends CustomPainter {
  _NetChartPainter({
    required this.labels,
    required this.series,
    required this.colors,
    required this.hover,
    required this.liveLast,
    required this.surface,
    required this.grid,
    required this.axisText,
    required this.amount,
  });

  final List<String> labels;
  final List<NetSeries> series;
  final List<Color> colors;
  final int? hover;
  final bool liveLast;
  final Color surface;
  final Color grid;
  final TextStyle axisText;
  final String Function(int) amount;

  @override
  void paint(Canvas canvas, Size size) {
    const l = _NetChartState._left, r = _NetChartState._right;
    const t = _NetChartState._top, b = _NetChartState._bottom;
    final n = labels.length;
    if (n == 0) return;
    var lo = 0, hi = 0;
    for (final s in series) {
      for (final p in s.points) {
        if (p == null) continue;
        lo = math.min(lo, p);
        hi = math.max(hi, p);
      }
    }
    if (lo == hi) hi = lo + 1;
    final plotW = size.width - l - r;
    final plotH = size.height - t - b;
    double x(int i) => n == 1 ? l + plotW / 2 : l + plotW * i / (n - 1);
    double y(int v) => t + plotH * (hi - v) / (hi - lo);

    // Zero is the line that matters: above it is up, below it is down.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(l, y(0)), Offset(size.width - r, y(0)), gridPaint);

    void label(String text, Offset at, {bool right = false, bool top = false}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: axisText.copyWith(fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      var dx = right ? at.dx - tp.width : at.dx - tp.width / 2;
      dx = dx.clamp(0, size.width - tp.width);
      tp.paint(canvas, Offset(dx, top ? at.dy : at.dy - tp.height));
    }

    // Recessive axis: the extremes on the left, the rounds underneath —
    // every one while they fit, otherwise every few.
    label('+${amount(hi)}', const Offset(l, t + 10));
    if (lo < 0) label(amount(lo), Offset(l, size.height - b));
    final every = math.max(1, (n / math.max(1, plotW / 28)).ceil());
    for (var i = 0; i < n; i++) {
      if (i % every != 0 && i != n - 1) continue;
      label(labels[i], Offset(x(i), size.height - b + 4), top: true);
    }

    if (hover != null) {
      canvas.drawLine(
        Offset(x(hover!), t),
        Offset(x(hover!), size.height - b),
        gridPaint,
      );
    }

    for (var s = 0; s < series.length; s++) {
      final pts = series[s].points;
      final line = Paint()
        ..color = colors[s]
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      Offset? prev;
      for (var i = 0; i < pts.length; i++) {
        final v = pts[i];
        if (v == null) continue;
        final p = Offset(x(i), y(v));
        if (prev != null) {
          if (liveLast && i == n - 1) {
            _dashed(canvas, prev, p, line);
          } else {
            canvas.drawLine(prev, p, line);
          }
        }
        prev = p;
      }
      // Markers with a surface ring, so crossing lines stay apart.
      for (var i = 0; i < pts.length; i++) {
        final v = pts[i];
        if (v == null) continue;
        final p = Offset(x(i), y(v));
        final big = hover == i;
        canvas.drawCircle(p, big ? 6 : 4.5, Paint()..color = surface);
        canvas.drawCircle(p, big ? 4.5 : 3, Paint()..color = colors[s]);
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    const dash = 4.0, gap = 3.0;
    final dir = d / len;
    for (var s = 0.0; s < len; s += dash + gap) {
      final e = math.min(s + dash, len);
      canvas.drawLine(a + dir * s, a + dir * e, paint);
    }
  }

  @override
  bool shouldRepaint(_NetChartPainter old) =>
      old.hover != hover ||
      old.series != series ||
      old.labels != labels ||
      old.colors.length != colors.length ||
      old.surface != surface;
}

/// One finished round in the list of rounds: who won it, and its biggest
/// pot when the round has one recorded.
class RoundSummaryRow extends StatelessWidget {
  const RoundSummaryRow({
    super.key,
    required this.round,
    required this.amount,
    required this.muted,
  });

  final RoundStanding round;
  final String Function(int) amount;
  final TextStyle muted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final winner = round.standings.isEmpty ? null : round.standings.first;
    final best = round.biggestPot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.lbRoundTitle(round.index),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: ' · ${l10n.lastRoundHands(round.hands)}',
                  style: muted,
                ),
                if (winner != null)
                  TextSpan(
                    text: ' · ${l10n.lbRoundWonBy(winner.name)}',
                    style: muted,
                  ),
              ],
            ),
            style: const TextStyle(fontSize: 13),
          ),
          if (best != null)
            Text(
              [
                l10n.lbBiggestPotLine(
                  amount(best.amount),
                  best.winners.join(', '),
                  best.hand,
                ),
                if (best.description.isNotEmpty) best.description,
              ].join(' · '),
              style: muted,
            ),
        ],
      ),
    );
  }
}

/// A player's whole record at the table: the totals, the rates the board
/// has no room for, and every round they sat in.
Future<void> showPlayerStandings(
  BuildContext context, {
  required AllTimeEntry entry,
  required String Function(int) amount,
  int? liveRound,
}) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final muted = TextStyle(
    fontSize: 12,
    color: theme.colorScheme.mutedForeground,
  );
  String pct(int part, int whole) =>
      whole == 0 ? '–' : '${(100 * part / whole).round()} %';
  String signed(int v) => v > 0 ? '+${amount(v)}' : amount(v);
  final stats = <(String, String)>[
    (l10n.lbNet, signed(entry.net)),
    (l10n.lbStatRounds, '${entry.rounds} / ${entry.wins}'),
    if (entry.bestPlace > 0)
      (l10n.lbBestPlace, l10n.placeLabel(entry.bestPlace)),
    (l10n.lbHandsPlayed, '${entry.handsPlayed}'),
    (
      l10n.lbColHandsWon,
      '${entry.handsWon} (${pct(entry.handsWon, entry.handsPlayed)})',
    ),
    (l10n.lbVpip, pct(entry.vpipHands, entry.handsPlayed)),
    (
      l10n.lbShowdowns,
      '${entry.showdownsWon} / ${entry.showdowns} '
          '(${pct(entry.showdownsWon, entry.showdowns)})',
    ),
    (l10n.lbBiggestPot, amount(entry.biggestPot)),
  ];
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => AlertDialog(
      title: Row(
        children: [
          PlayerAvatar(index: entry.avatar, size: 32),
          const Gap(10),
          Flexible(child: Text(entry.name, overflow: TextOverflow.ellipsis)),
          if (entry.bot) ...[
            const Gap(6),
            Text('(${l10n.lbBot})', style: muted),
          ],
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            key: const Key('player-standings'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in stats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: muted)),
                      Text(value).small().semiBold(),
                    ],
                  ),
                ),
              const Gap(12),
              Text(l10n.lbHistory.toUpperCase()).muted().xSmall().semiBold(),
              const Gap(4),
              for (final h in entry.history.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          h.round == liveRound
                              ? '${l10n.thisRound} (${l10n.lbLiveRound})'
                              : l10n.lbRoundTitle(h.round),
                        ).small(),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          h.place > 0 ? l10n.placeLabel(h.place) : '',
                          style: muted,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          signed(h.net),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: h.net > 0
                                ? Colors.green
                                : h.net < 0
                                ? theme.colorScheme.destructive
                                : theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        OutlineButton(
          key: const Key('player-standings-close'),
          onPressed: () => closeOverlay<void>(dialog),
          child: Text(l10n.close),
        ),
      ],
    ),
  ).future;
}
