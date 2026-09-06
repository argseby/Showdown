import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/formatting.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/chip_stack.dart';
import '../../../shared/phrases.dart';
import '../../../shared/playing_card.dart';
import '../../../shared/pot_colors.dart';
import '../table_session.dart';
import 'seat_widget.dart';

/// The oval table with seats around it, the viewer rotated to the bottom.
class TableView extends ConsumerWidget {
  const TableView({
    super.key,
    required this.session,
    this.onTakeSeat,
    this.speaking = const {},
    this.onAdminTap,
    this.onSayTap,
    this.videoViews = const {},
  });

  /// Player id -> platform view type of a live camera stream (the viewer's
  /// own under [VoiceEngine.self]).
  final Map<String, String> videoViews;

  final TableSessionState session;

  /// Called with a free seat the viewer wants to move to (null = read-only).
  final ValueChanged<int>? onTakeSeat;

  /// Player ids currently speaking in the voice chat ("me" for the viewer).
  final Set<String> speaking;

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
    // Once a pot is awarded, every one of its winners has their best five
    // highlighted (board and hole cards) in the pot's colour, a split pot
    // included. Nothing else is ever framed.
    List<String>? bestOf(int seat) {
      for (final sv in snap.seats) {
        if (sv.seat == seat && (sv.player?.bestCards?.isNotEmpty ?? false)) {
          return sv.player!.bestCards;
        }
      }
      return session.best[seat];
    }

    final winnerBest = <String>{
      for (final seat in session.winners) ...?bestOf(seat),
    };
    // Showdown spotlight (preference): the hand being shown, or the winner,
    // gets its five cards lifted and highlighted with its name in the middle.
    final spotlightOn = ref.watch(showdownSpotlightProvider);
    final spot = _currentSpotlight(
      spotlightOn ? session.spotlight : null,
      snap,
    );
    final spotCards = spot?.cards.toSet() ?? const <String>{};
    final locale = Localizations.localeOf(context).toString();
    // Winner visuals take the colour of the pot being presented: gold for
    // the main pot, silver for the first side pot, bronze after that.
    final winnerColor = potColor(session.winnerPotIndex ?? 0);
    final highlightColor = spot != null && spot.winner
        ? potColor(spot.potIndex ?? session.winnerPotIndex ?? 0)
        : winnerColor;
    final yourHand =
        session.isPlayer &&
            ref.watch(handLineProvider) == HandLinePlacement.board
        ? snap.you.handDescription
        : '';

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
        // A little air between the viewer's seat and the action bar.
        const bottomAir = 12.0;
        final oval = Rect.fromLTWH(
          seatW / 2 + 4,
          seatH / 2 + 4,
          math.max(40, size.width - seatW - 8),
          math.max(40, size.height - seatH - 8 - bottomAir),
        );
        // A seat's content (cards, avatar, name, stack, badges) is shorter
        // than its box; the spare height is kept on the felt side, so the
        // upper seats hug the top of their box and the lower seats the
        // bottom, and the felt may use that slack.
        final contentH = (compact ? 130.0 : 156.0) * scale;
        final slack = (seatH - contentH).clamp(0.0, seatH * 0.2);
        // Every seat box (occupied or not) at its clamped place, and the
        // part of it the content really occupies.
        final boxes = <int, Rect>{};
        final lowerHalf = <int, bool>{};
        final occupied = <Rect>[];
        for (var seat = 0; seat < maxPlayers; seat++) {
          final pos = positionOf(seat, viewerSeat, maxPlayers);
          final point = seatPoint(pos, maxPlayers, oval);
          final box = Rect.fromLTWH(
            (point.dx - seatW / 2).clamp(0.0, size.width - seatW),
            (point.dy - seatH / 2).clamp(0.0, size.height - seatH),
            seatW,
            seatH,
          );
          boxes[seat] = box;
          final lower = point.dy > oval.center.dy;
          lowerHalf[seat] = lower;
          occupied.add(
            lower
                ? Rect.fromLTRB(
                    box.left,
                    box.top + slack,
                    box.right,
                    box.bottom,
                  )
                : Rect.fromLTRB(
                    box.left,
                    box.top,
                    box.right,
                    box.bottom - slack,
                  ),
          );
        }
        // The felt is the largest stadium inside the ring that stays clear
        // of every seat's content by a margin, so no card ever touches its
        // line.
        final felt = feltRect(
          oval: oval,
          boxes: occupied,
          seatW: seatW,
          seatH: seatH,
          compact: compact,
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
                      best: winnerBest.isNotEmpty
                          ? winnerBest.toList()
                          : spot?.cards,
                      lift: spotCards,
                      rabbit: hand.rabbitCards ?? const [],
                      fourColor: fourColor,
                      compact: compact,
                      scale: scale,
                      highlightColor: highlightColor,
                    ),
                    if (spot != null) ...[
                      const Gap(4),
                      Text(
                        '${spot.name}: ${spot.description}',
                        key: const Key('spotlight-label'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w700,
                          color: spot.winner
                              ? highlightColor
                              : theme.colorScheme.foreground,
                        ),
                      ),
                    ],
                    if (yourHand.isNotEmpty) ...[
                      // The viewer's own hand, right under the community
                      // cards where the eyes already are; it stays after a
                      // fold and through the showdown.
                      const Gap(4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 12,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          const Gap(6),
                          Text(
                            l10n.yourHand(yourHand),
                            key: const Key('your-hand'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (hand.runTwice ?? false) ...[
                      const Gap(4),
                      _Board(
                        key: const Key('board-2'),
                        board: hand.board2 ?? const [],
                        best: null,
                        rabbit: const [],
                        fourColor: fourColor,
                        compact: compact,
                        scale: scale * 0.8,
                      ),
                    ],
                    const Gap(8),
                    _Pots(
                      pots: hand.pots,
                      phase: hand.phase,
                      compact: compact,
                      bigBlind: bigBlind,
                      chipDisplay: chipDisplay,
                      activeIndex: session.winnerPotIndex,
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
          final box =
              boxes[sv.seat] ??
              Rect.fromCenter(center: point, width: seatW, height: seatH);
          children.add(
            Positioned(
              left: box.left,
              top: box.top,
              width: seatW,
              height: seatH,
              child: Align(
                alignment: lowerHalf[sv.seat] ?? false
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: SeatWidget(
                  seat: sv.seat,
                  player: sv.player,
                  hand: hand,
                  isViewer: session.isPlayer && sv.seat == session.mySeat,
                  turnTimeMs: snap.table.settings.turnTime * 1000,
                  best: session.winners.contains(sv.seat)
                      ? bestOf(sv.seat)
                      : spot != null && spot.seat == sv.seat
                      ? spot.cards
                      : null,
                  wonAmount: session.winnerAmounts[sv.seat],
                  timeBankSeconds: snap.table.settings.timeBankSeconds,
                  handNumber: snap.table.handNumber,
                  bigBlind: bigBlind,
                  chipDisplay: chipDisplay,
                  winner: session.winners.contains(sv.seat),
                  winnerColor: winnerColor,
                  compact: compact,
                  scale: scale,
                  // A quick phrase or a fresh chat line next to the avatar.
                  phrase: session.phrases[sv.seat] != null
                      ? phraseLabel(l10n, session.phrases[sv.seat]!.phrase)
                      : session.chatBubbles[sv.seat],
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
                  onSayTap: sv.seat == session.mySeat && session.isPlayer
                      ? onSayTap
                      : null,
                  equity: sv.player?.equity,
                  timeBankActive:
                      (hand?.timeBankActive ?? false) &&
                      hand?.toActSeat == sv.seat,
                  videoViewType: sv.player == null
                      ? null
                      : sv.seat == session.mySeat && session.isPlayer
                      ? videoViews[VoiceEngine.self]
                      : videoViews[sv.player!.id],
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
          final player = sv.player;
          final bet = player?.betThisStreet ?? 0;
          final inHand = hand != null && (player?.inHand ?? false);
          final showBet = inHand && bet > 0;
          final isTurn = hand?.toActSeat == sv.seat && hand?.phase == 'betting';
          final lastAction = inHand && !isTurn ? player?.lastAction : null;
          // The bet chips and the last action ("Check", "Raise to 300")
          // straddle the felt's edge on the straight line from the seat to
          // the middle of the table: the same spot for every seat, out of
          // the middle where the board and the pots are, and off the seat's
          // cards thanks to the slack kept on the felt side.
          final betPoint = actionPoint(felt, box.center);
          // The dealer button and the blind markers (D white, SB yellow,
          // BB red) are part of the seat's pill, left of its label and
          // chips, so they are always aligned with that seat's entries.
          final role = hand == null || player == null
              ? null
              : hand.buttonSeat == sv.seat
              ? _SeatRole.dealer
              : hand.sbSeat == sv.seat
              ? _SeatRole.smallBlind
              : hand.bbSeat == sv.seat
              ? _SeatRole.bigBlind
              : null;
          final entries = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lastAction != null)
                FadingActionLabel(
                  key: ValueKey(
                    'action-${sv.seat}-${lastAction.kind}-${lastAction.amount}-${hand?.street}',
                  ),
                  text: actionLabel(
                    l10n,
                    lastAction,
                    chipDisplay: chipDisplay,
                    bigBlind: bigBlind,
                    locale: locale,
                  ),
                ),
              // Bets fade out when the street ends and the chips move
              // to the pot.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !showBet
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey('bet-${sv.seat}-$bet'),
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
            ],
          );
          children.add(
            Positioned(
              key: ValueKey('seat-action-${sv.seat}'),
              left: betPoint.dx - 80,
              top: betPoint.dy - 20,
              width: 160,
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (role != null) ...[
                    _RoleMarker(
                      key: ValueKey('marker-${sv.seat}'),
                      role: role,
                      compact: compact,
                    ),
                    const Gap(5),
                  ],
                  entries,
                ],
              ),
            ),
          );
        }
        // Chips fly from the pot on display to each of its winners.
        if (hand != null && session.winnerPotIndex != null) {
          final from = Offset(
            felt.center.dx,
            felt.center.dy + (compact ? 34 : 48),
          );
          for (final seat in session.winners) {
            final box = boxes[seat];
            if (box == null) continue;
            children.add(
              _FlyingChips(
                key: ValueKey(
                  'fly-${snap.table.handNumber}-${session.winnerPotIndex}-$seat',
                ),
                from: from,
                to: box.center,
                color: winnerColor,
              ),
            );
          }
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

/// The largest stadium (a rectangle with semicircular ends, which is what
/// the felt is drawn as) centred in [oval] that keeps a margin from every
/// seat box. For a given height the straight part is as long as the boxes
/// beside the ends allow; the height is chosen so that the stadium's area
/// is the largest (a flatter felt clears the diagonal seats with a longer
/// straight part), never below a third of the ring's height.
Rect feltRect({
  required Rect oval,
  required Iterable<Rect> boxes,
  required double seatW,
  required double seatH,
  required bool compact,
}) {
  final c = oval.center;
  final margin = compact ? 6.0 : 10.0;
  // Never larger than the plain inset of the ring by half a box.
  var hMax = oval.height / 2 - seatH * 0.55 - 8;
  final maxW = oval.width / 2 - seatW * (compact ? 0.5 : 0.55) - margin;
  final gaps = <(double, double)>[];
  for (final b in boxes) {
    final dx = math.max(0.0, math.max(b.left - c.dx, c.dx - b.right));
    final dy = math.max(0.0, math.max(b.top - c.dy, c.dy - b.bottom));
    gaps.add((dx, dy));
    // The rounded ends have radius h, so no box corner may come closer
    // than h plus the margin to the centre line.
    hMax = math.min(hMax, math.sqrt(dx * dx + dy * dy) - margin);
  }
  hMax = math.max(hMax, 20);
  final hMin = math.max(20.0, math.min(hMax, oval.height / 6));
  double straight(double h) {
    final r = h + margin;
    var l = math.max(0.0, maxW - h);
    for (final (dx, dy) in gaps) {
      if (dy >= r) continue;
      l = math.min(l, dx - math.sqrt(r * r - dy * dy));
    }
    return math.max(l, 0);
  }

  var bestH = hMax;
  var bestL = straight(hMax);
  var bestArea = (bestH + bestL) * bestH;
  const steps = 40;
  for (var i = 1; i <= steps; i++) {
    final h = hMax - (hMax - hMin) * i / steps;
    final l = straight(h);
    final area = (h + l) * h;
    if (area > bestArea) {
      bestH = h;
      bestL = l;
      bestArea = area;
    }
  }
  final best = Rect.fromCenter(
    center: c,
    width: 2 * (bestH + bestL),
    height: 2 * bestH,
  );
  // On a phone the seat boxes leave no room for a clear felt that still
  // holds the board; there the plain inset of the ring wins, overlaps and
  // all, as before.
  final fallback = Rect.fromLTRB(
    oval.left + seatW * (compact ? 0.5 : 0.55) + (compact ? 4 : 10),
    oval.top + seatH * 0.55 + 8,
    oval.right - seatW * (compact ? 0.5 : 0.55) - (compact ? 4 : 10),
    oval.bottom - seatH * 0.55 - 8,
  );
  final minWidth = math.min(fallback.width, compact ? 190.0 : 320.0);
  return best.width < minWidth ? fallback : best;
}

/// Where a seat's bet chips and action label go: at the point of the
/// felt's edge nearest to the seat (straight in front of it, whatever the
/// width of the table), pulled in a little so the pill straddles the edge.
Offset actionPoint(Rect felt, Offset seat) {
  final c = felt.center;
  final h = felt.height / 2;
  final half = math.max(0.0, felt.width / 2 - h);
  // The felt is a stadium: the nearest edge point lies on the ray from the
  // nearest point of its centre segment to the seat.
  final anchor = Offset((seat.dx - c.dx).clamp(-half, half) + c.dx, c.dy);
  final toSeat = seat - anchor;
  final dist = toSeat.distance;
  if (dist == 0) return anchor;
  final dir = toSeat / dist;
  // The pill straddles the edge: a little more than half of it lies on
  // the felt (it is wider than tall, so the pull-in follows the direction).
  final inset = dir.dx.abs() * 30 + dir.dy.abs() * 10;
  return anchor + dir * math.max(0.0, math.min(h, dist) - inset);
}

/// The spotlight as it should be drawn now: the reveal event names the hand
/// as it was when the cards were turned over, but during a run-out the
/// board keeps growing, so the snapshot's description and best five of the
/// revealed seat win whenever the server provides them.
Spotlight? _currentSpotlight(Spotlight? spot, Snapshot snap) {
  if (spot == null) return null;
  for (final sv in snap.seats) {
    if (sv.seat != spot.seat) continue;
    final p = sv.player;
    if (p == null || !p.inHand || p.folded) return spot;
    final cards = p.bestCards;
    final description = p.handDescription;
    if (cards == null || cards.isEmpty || description == null) return spot;
    if (cards.length == spot.cards.length &&
        cards.toSet().containsAll(spot.cards) &&
        description == spot.description) {
      return spot;
    }
    return Spotlight(
      seat: spot.seat,
      name: spot.name,
      cards: cards,
      description: description.isEmpty ? spot.description : description,
      winner: spot.winner,
      potIndex: spot.potIndex,
    );
  }
  return spot;
}

class _Board extends StatelessWidget {
  const _Board({
    super.key,
    required this.board,
    required this.best,
    required this.rabbit,
    required this.fourColor,
    required this.compact,
    required this.scale,
    this.lift = const {},
    this.highlightColor = winnerGold,
  });
  final List<String> board;
  final List<String>? best;

  /// Frame colour of the highlighted cards (the pot's colour).
  final Color highlightColor;

  /// Cards drawn a little higher (the hand under the spotlight).
  final Set<String> lift;

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
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      offset: lift.contains(board[i])
                          ? const Offset(0, -0.18)
                          : Offset.zero,
                      child: PlayingCardWidget(
                        card: board[i],
                        width: w,
                        fourColor: fourColor,
                        highlighted: best != null && best!.contains(board[i]),
                        highlightColor: highlightColor,
                      ),
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

enum _SeatRole { dealer, smallBlind, bigBlind }

/// The dealer button (white) and the blind markers (SB yellow, BB red) on
/// the felt.
class _RoleMarker extends StatelessWidget {
  const _RoleMarker({super.key, required this.role, required this.compact});
  final _SeatRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (bg, fg, text) = switch (role) {
      _SeatRole.dealer => (
        const Color(0xFFF5F5F5),
        const Color(0xFF111111),
        l10n.badgeDealer,
      ),
      _SeatRole.smallBlind => (
        const Color(0xFFFFC107),
        const Color(0xFF3A2A00),
        l10n.badgeSmallBlind,
      ),
      _SeatRole.bigBlind => (
        const Color(0xFFE53935),
        const Color(0xFFFFFFFF),
        l10n.badgeBigBlind,
      ),
    };
    final size = compact ? 20.0 : 22.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: text.length > 1 ? 8 : 10,
          fontWeight: FontWeight.w800,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

/// A stack of chips sliding from the pot to a winner's seat, fading out
/// as it arrives.
class _FlyingChips extends StatelessWidget {
  const _FlyingChips({
    super.key,
    required this.from,
    required this.to,
    required this.color,
  });
  final Offset from;
  final Offset to;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (context, t, child) {
        final p = Offset.lerp(from, to, t)!;
        final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
        return Positioned(
          left: p.dx - 14,
          top: p.dy - 14,
          child: IgnorePointer(
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
      child: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 8,
              child: ChipIcon(size: 18, color: color),
            ),
            Positioned(
              left: 6,
              top: 4,
              child: ChipIcon(size: 18, color: color),
            ),
            Positioned(
              left: 12,
              top: 0,
              child: ChipIcon(size: 18, color: color),
            ),
          ],
        ),
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
    this.activeIndex,
  });
  final List<PotView> pots;
  final String phase;
  final bool compact;
  final int bigBlind;
  final ChipDisplay chipDisplay;

  /// The pot being presented right now: drawn filled in its colour and a
  /// little larger, the others muted.
  final int? activeIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (pots.isEmpty) return const SizedBox(height: 18);
    final locale = Localizations.localeOf(context).toString();
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < pots.length; i++)
          AnimatedScale(
            scale: activeIndex == i ? 1.12 : 1,
            duration: const Duration(milliseconds: 250),
            child: AnimatedOpacity(
              opacity: activeIndex == null || activeIndex == i ? 1 : 0.45,
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey('pot-$i'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeIndex == i
                      ? potColor(i)
                      : theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(12),
                  // Main pot gold, first side pot silver, the rest bronze.
                  border: Border.all(
                    color: potColor(i).withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${i == 0 ? l10n.mainPot : l10n.sidePot(i)}: ',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: activeIndex == i
                            ? potInk
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                    ChipIcon(
                      size: 12,
                      color: activeIndex == i ? potInk : potColor(i),
                    ),
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
                        color: activeIndex == i ? potInk : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
