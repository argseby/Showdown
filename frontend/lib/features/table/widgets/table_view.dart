import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/formatting.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/chip_stack.dart';
import '../../../shared/phrases.dart';
import '../../../shared/playing_card.dart';
import '../table_session.dart';
import 'seat_widget.dart';

/// The oval table with seats around it, the viewer rotated to the bottom.
class TableView extends ConsumerWidget {
  const TableView({
    super.key,
    required this.session,
    this.onTakeSeat,
    this.speaking = const {},
    this.onToggleMute,
    this.onAdminTap,
    this.onSayTap,
  });

  final TableSessionState session;

  /// Called with a free seat the viewer wants to move to (null = read-only).
  final ValueChanged<int>? onTakeSeat;

  /// Player ids currently speaking in the voice chat ("me" for the viewer).
  final Set<String> speaking;

  /// Viewer's mute toggle (null when not in the voice chat).
  final VoidCallback? onToggleMute;

  /// Host only: opens the player actions for a seat that is not the host's.
  final ValueChanged<PlayerView>? onAdminTap;

  /// Players only: the quick-phrase button on the viewer's own seat.
  final VoidCallback? onSayTap;

  /// Position index (0 = bottom center, clockwise) of a seat for a viewer.
  static int positionOf(int seat, int viewerSeat, int maxPlayers) =>
      ((seat - viewerSeat) % maxPlayers + maxPlayers) % maxPlayers;

  /// Point on the ellipse for a position. Seats are spread by equal arc
  /// length (not equal angle), so they look evenly spaced on a wide oval.
  static Offset seatPoint(int position, int maxPlayers, Rect oval) {
    final a = oval.width / 2;
    final b = oval.height / 2;
    // Sample the perimeter and pick the point at the wanted fraction of
    // the total arc length, starting at the bottom center going clockwise.
    const samples = 720;
    var total = 0.0;
    final lengths = List<double>.filled(samples + 1, 0);
    Offset at(int i) {
      final t = math.pi / 2 + 2 * math.pi * i / samples;
      return Offset(a * math.cos(t), b * math.sin(t));
    }

    var prev = at(0);
    for (var i = 1; i <= samples; i++) {
      final cur = at(i);
      total += (cur - prev).distance;
      lengths[i] = total;
      prev = cur;
    }
    final target = total * position / maxPlayers;
    var i = 0;
    while (i < samples && lengths[i + 1] < target) {
      i++;
    }
    final point = at(i);
    return Offset(oval.center.dx + point.dx, oval.center.dy + point.dy);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = session.snapshot;
    if (snap == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final fourColor = ref.watch(fourColorDeckProvider);
    final maxPlayers = snap.table.settings.maxPlayers;
    final viewerSeat = session.mySeat ?? 0;
    final hand = snap.hand;
    final chipDisplay = ref.watch(chipDisplayProvider);
    final scale = ref.watch(uiScaleProvider);
    final bigBlind = snap.table.settings.bigBlind;
    // Once the pots are awarded, the winners' best five are highlighted in
    // gold (board and hole cards). Nothing else is ever framed.
    final winnerBest = <String>{
      for (final seat in session.winners) ...?session.best[seat],
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final compact = size.width < 700 || size.height < 480;
        // Seat boxes shrink with the viewport so that the oval keeps room on
        // phones in portrait; the felt must never collapse to zero.
        final seatW = math.min(
          (compact ? 84.0 : 112.0) * scale,
          size.width / 4.4,
        );
        final seatH = math.min(
          (compact ? 150.0 : 180.0) * scale,
          size.height / 3.2,
        );
        // The seat ring: seat boxes are centered on this ellipse and stay
        // fully inside the available area (the bottom seat can never run
        // under the action bar).
        final oval = Rect.fromLTWH(
          seatW / 2 + 4,
          seatH / 2 + 4,
          math.max(40, size.width - seatW - 8),
          math.max(40, size.height - seatH - 8),
        );
        // The felt sits inside the ring, clear of every seat box (the boxes
        // are centered on the ring, so half a box plus a margin keeps them
        // off the table at any position).
        final felt = Rect.fromLTRB(
          oval.left + seatW * (compact ? 0.5 : 0.55) + (compact ? 4 : 10),
          oval.top + seatH * 0.55 + 8,
          oval.right - seatW * (compact ? 0.5 : 0.55) - (compact ? 4 : 10),
          oval.bottom - seatH * 0.55 - 8,
        );
        final children = <Widget>[
          Positioned(
            left: felt.left,
            top: felt.top,
            width: felt.width,
            height: felt.height,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1000),
                color: theme.colorScheme.card,
                border: Border.all(color: theme.colorScheme.border, width: 2),
              ),
            ),
          ),
          Positioned(
            left: felt.left,
            top: felt.top,
            width: felt.width,
            height: felt.height,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hand != null) ...[
                    _Board(
                      board: hand.board,
                      best: winnerBest.isEmpty ? null : winnerBest.toList(),
                      rabbit: hand.rabbitCards ?? const [],
                      fourColor: fourColor,
                      compact: compact,
                      scale: scale,
                    ),
                    const Gap(8),
                    _Pots(
                      pots: hand.pots,
                      phase: hand.phase,
                      compact: compact,
                      bigBlind: bigBlind,
                      chipDisplay: chipDisplay,
                    ),
                  ] else
                    Text(
                      snap.table.state == 'paused'
                          ? l10n.tablePaused
                          : snap.table.state == 'waiting'
                          ? l10n.tableWaiting
                          : l10n.waitingForPlayers,
                      style: TextStyle(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ];
        for (final sv in snap.seats) {
          final pos = positionOf(sv.seat, viewerSeat, maxPlayers);
          final point = seatPoint(pos, maxPlayers, oval);
          final left = (point.dx - seatW / 2).clamp(0.0, size.width - seatW);
          final top = (point.dy - seatH / 2).clamp(0.0, size.height - seatH);
          children.add(
            Positioned(
              left: left,
              top: top,
              width: seatW,
              height: seatH,
              child: Align(
                alignment: Alignment.topCenter,
                child: SeatWidget(
                  seat: sv.seat,
                  player: sv.player,
                  hand: hand,
                  isViewer: session.isPlayer && sv.seat == session.mySeat,
                  turnTimeMs: snap.table.settings.turnTime * 1000,
                  best: session.winners.contains(sv.seat)
                      ? session.best[sv.seat]
                      : null,
                  handNumber: snap.table.handNumber,
                  bigBlind: bigBlind,
                  chipDisplay: chipDisplay,
                  winner: session.winners.contains(sv.seat),
                  compact: compact,
                  scale: scale,
                  phrase: session.phrases[sv.seat] == null
                      ? null
                      : phraseLabel(l10n, session.phrases[sv.seat]!.phrase),
                  onAdminTap:
                      onAdminTap != null &&
                          sv.player != null &&
                          sv.player!.id != session.identity?.playerId
                      ? () => onAdminTap!(sv.player!)
                      : null,
                  pendingForViewer: snap.you.pendingSeat == sv.seat,
                  speaking:
                      sv.player != null &&
                      (speaking.contains(sv.player!.id) ||
                          (sv.seat == session.mySeat &&
                              speaking.contains('me'))),
                  onVoiceTap: sv.seat == session.mySeat ? onToggleMute : null,
                  onSayTap: sv.seat == session.mySeat && session.isPlayer
                      ? onSayTap
                      : null,
                  onTakeSeat:
                      sv.player == null &&
                          onTakeSeat != null &&
                          session.isPlayer &&
                          snap.you.canChangeSeat &&
                          snap.you.pendingSeat == null
                      ? () => onTakeSeat!(sv.seat)
                      : null,
                ),
              ),
            ),
          );
          final bet = sv.player?.betThisStreet ?? 0;
          final showBet =
              hand != null && bet > 0 && (sv.player?.inHand ?? false);
          // Bet chips sit just outside the seat box, towards the table,
          // never over the seat's cards.
          final toCenter = oval.center - point;
          final dist = toCenter.distance;
          final dir = dist == 0 ? const Offset(0, -1) : toCenter / dist;
          final exitX = dir.dx == 0
              ? double.infinity
              : (seatW / 2) / dir.dx.abs();
          final exitY = dir.dy == 0
              ? double.infinity
              : (seatH / 2) / dir.dy.abs();
          final betDist = math.min(math.min(exitX, exitY) + 16, dist * 0.6);
          final betPoint = point + dir * betDist;
          children.add(
            Positioned(
              left: betPoint.dx - 40,
              top: betPoint.dy - 10,
              width: 80,
              // Bets fade out when the street ends and the chips move to the pot.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !showBet
                    ? const SizedBox.shrink()
                    : Center(
                        key: ValueKey('bet-${sv.seat}-$bet'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.background.withValues(
                              alpha: 0.85,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ChipAmount(
                            amount: bet,
                            bigBlind: bigBlind,
                            size: 12,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              fontFamily: 'GeistMono',
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          );
        }
        if (hand == null && snap.spectators > 0) {
          children.add(
            Positioned(
              right: 8,
              bottom: 4,
              child: Text(
                l10n.spectatorsCount(snap.spectators),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          );
        }
        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.board,
    required this.best,
    required this.rabbit,
    required this.fourColor,
    required this.compact,
    required this.scale,
  });
  final List<String> board;
  final List<String>? best;

  /// Rabbit hunt: the cards that would have completed the board, shown
  /// ghosted after the real ones.
  final List<String> rabbit;
  final bool fourColor;
  final bool compact;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final w = (compact ? 30.0 : 46.0) * scale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : (compact ? 3 : 4)),
            child: i < board.length
                ? _DealCard(
                    key: ValueKey('board-$i-${board[i]}'),
                    child: PlayingCardWidget(
                      card: board[i],
                      width: w,
                      fourColor: fourColor,
                      highlighted: best != null && best!.contains(board[i]),
                      highlightColor: winnerGold,
                    ),
                  )
                : i - board.length < rabbit.length
                ? Opacity(
                    key: ValueKey('rabbit-$i-${rabbit[i - board.length]}'),
                    opacity: 0.55,
                    child: PlayingCardWidget(
                      card: rabbit[i - board.length],
                      width: w,
                      fourColor: fourColor,
                    ),
                  )
                : Container(
                    width: w,
                    height: w * 1.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(w * 0.12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.border,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Slides and fades a community card in when it is dealt.
class _DealCard extends StatefulWidget {
  const _DealCard({super.key, required this.child});
  final Widget child;

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      alwaysIncludeSemantics: true,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.4, 0),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

class _Pots extends StatelessWidget {
  const _Pots({
    required this.pots,
    required this.phase,
    required this.compact,
    required this.bigBlind,
    required this.chipDisplay,
  });
  final List<PotView> pots;
  final String phase;
  final bool compact;
  final int bigBlind;
  final ChipDisplay chipDisplay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (pots.isEmpty) return const SizedBox(height: 18);
    final locale = Localizations.localeOf(context).toString();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < pots.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${i == 0 ? l10n.mainPot : l10n.sidePot(i)}: ',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                ChipIcon(size: 12, color: theme.colorScheme.primary),
                const Gap(4),
                Text(
                  formatAmount(
                    pots[i].amount,
                    mode: chipDisplay,
                    bigBlind: bigBlind,
                    locale: locale,
                  ),
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontFamily: 'GeistMono',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
