import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/formatting.dart';
import '../../../core/time_sync.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';
import '../../../shared/chips.dart';
import '../../../shared/playing_card.dart';

/// One seat on the table: avatar with countdown ring, name, stack, badges,
/// hole cards and the last action.
class SeatWidget extends ConsumerWidget {
  const SeatWidget({
    super.key,
    required this.seat,
    required this.player,
    required this.hand,
    required this.isViewer,
    required this.turnTimeMs,
    required this.best,
    required this.compact,
    this.winner = false,
    this.winnerColor = winnerGold,
    this.handNumber = 0,
    this.bigBlind = 0,
    this.chipDisplay = ChipDisplay.coins,
    this.onTakeSeat,
    this.pendingForViewer = false,
    this.speaking = false,
    this.scale = 1.0,
    this.phrase,
    this.onAdminTap,
    this.onSayTap,
    this.equity,
    this.timeBankActive = false,
    this.videoViewType,
    this.wonAmount,
    this.timeBankSeconds = 0,
    this.voiceLinkDown = false,
  });

  /// Voice chat: the player is in it, but the audio connection between the
  /// two browsers failed (no common route) and is being tried again.
  final bool voiceLinkDown;

  /// The table's time bank maximum; above zero the player's remaining bank
  /// is shown left of the stack.
  final int timeBankSeconds;

  /// The seat's net gain in the current hand once its pot is presented
  /// (shown as "+amount" next to the stack).
  final int? wonAmount;

  /// Pot share in percent during a run-out.
  final double? equity;

  /// The seat is on turn and spending its time bank.
  final bool timeBankActive;

  /// Platform view of the player's camera; replaces the avatar picture.
  final String? videoViewType;

  /// Own seat only: opens the quick-phrase picker (small bubble button).
  final VoidCallback? onSayTap;

  /// A quick phrase the player just said (already translated).
  final String? phrase;

  /// Host only: tapping the avatar opens the player actions.
  final VoidCallback? onAdminTap;

  /// Accessibility scale for cards and avatars (1.0 = normal).
  final double scale;

  final int seat;
  final PlayerView? player;
  final HandView? hand;
  final bool isViewer;
  final int turnTimeMs;

  /// Best five cards of this seat when it won a pot (gold highlight).
  final List<String>? best;
  final bool compact;

  /// Won a pot in the current hand: glowing avatar ring.
  final bool winner;

  /// Colour of the winner visuals: gold for the main pot, silver and bronze
  /// for the side pots while they are presented.
  final Color winnerColor;

  /// Current hand number: keys the deal animation.
  final int handNumber;
  final int bigBlind;
  final ChipDisplay chipDisplay;

  /// For an empty seat: the viewer may move here (tap the plus).
  final VoidCallback? onTakeSeat;

  /// For an empty seat: the viewer moves here at the next deal.
  final bool pendingForViewer;

  /// Voice chat: this player is talking right now (client-side detection).
  final bool speaking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = player;
    final width = compact ? 84.0 : 112.0;
    if (p == null) {
      final active = onTakeSeat != null || pendingForViewer;
      final disc = Container(
        width: compact ? 36 : 44,
        height: compact ? 36 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pendingForViewer
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : null,
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.border,
            width: 1.5,
          ),
        ),
        child: Icon(
          pendingForViewer ? LucideIcons.armchair : LucideIcons.plus,
          size: 16,
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.mutedForeground,
        ),
      );
      final cardWidth = (compact ? 26.0 : 34.0) * scale;
      return SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Same vertical rhythm as an occupied seat (cards, avatar, name).
            SizedBox(height: cardWidth * 1.4 + 4),
            if (onTakeSeat != null)
              Tooltip(
                tooltip: TooltipContainer(child: Text(l10n.takeSeatHint)).call,
                child: GestureDetector(
                  key: Key('take-seat-$seat'),
                  onTap: onTakeSeat,
                  child: disc,
                ),
              )
            else
              disc,
            const Gap(4),
            Text(
              pendingForViewer ? l10n.seatPendingYou : l10n.emptySeat,
              style: TextStyle(
                fontSize: 11,
                color: pendingForViewer
                    ? theme.colorScheme.primary
                    : theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }
    final isTurn = hand?.toActSeat == seat && hand?.phase == 'betting';
    final inHand = hand != null && p.inHand;
    // Folded cards stay on the table, dimmed, so everyone can still see
    // that the player was dealt in and threw the hand away.
    final showsCards = inHand;
    final folded = inHand && p.folded;
    final fourColor = ref.watch(fourColorDeckProvider);
    final cardWidth = (compact ? 26.0 : 34.0) * scale;
    final avatarSize = (compact ? 34.0 : 42.0) * scale;
    final ringSize = (compact ? 44.0 : 54.0) * scale;
    final locale = Localizations.localeOf(context).toString();

    final badges = <Widget>[];
    if (winner) {
      badges.add(
        _Badge(
          l10n.winnerBadge,
          key: Key('winner-$seat'),
          gold: true,
          goldColor: winnerColor,
        ),
      );
    }
    // Dealer button and blind markers are drawn on the felt by the table
    // view, not on the seat.
    if (p.status == 'sitting_out') badges.add(_Badge(l10n.badgeSittingOut));
    if (p.status == 'busted') badges.add(_Badge(l10n.badgeBusted));
    if (!p.connected) {
      badges.add(_Badge(l10n.badgeDisconnected, destructive: true));
    }
    if (voiceLinkDown) {
      badges.add(
        _Badge(
          l10n.badgeNoAudio,
          key: Key('no-audio-$seat'),
          destructive: true,
        ),
      );
    }
    if (inHand && p.allIn) badges.add(_Badge(l10n.badgeAllIn, primary: true));
    if (inHand && p.folded) badges.add(_Badge(l10n.badgeFolded));
    if (hand?.straddleSeat == seat) badges.add(_Badge(l10n.badgeStraddle));
    if (timeBankActive) {
      badges.add(
        _Badge(
          l10n.timeBankLeft(p.timeBank ?? 0),
          key: Key('timebank-$seat'),
          primary: true,
        ),
      );
    }
    if (equity != null && inHand && !p.folded) {
      badges.add(
        _Badge('${equity!.round()}%', key: Key('equity-$seat'), primary: true),
      );
    }
    if (inHand && (p.mucked ?? false)) badges.add(_Badge(l10n.badgeMucked));
    if (hand != null && !p.inHand && p.status == 'active') {
      badges.add(_Badge(l10n.badgeWaiting));
    }

    final avatarStack = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (isTurn && hand?.deadlineTs != null)
          _CountdownRing(
            deadlineTs: hand!.deadlineTs!,
            totalMs: turnTimeMs,
            size: ringSize,
          )
        else
          SizedBox(width: ringSize, height: ringSize),
        // A crisp gold ring marks the winner; the viewer's own seat
        // keeps its primary ring otherwise.
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: EdgeInsets.all(winner ? 2 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: winner
                ? Border.all(color: winnerColor, width: 3)
                : speaking && p.voice == 'on'
                ? Border.all(color: const Color(0xFF43A047), width: 3)
                : isViewer
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: videoViewType != null
              ? ClipOval(
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: HtmlElementView(
                      key: ValueKey(videoViewType),
                      viewType: videoViewType!,
                    ),
                  ),
                )
              : PlayerAvatar(index: p.avatar, size: avatarSize),
        ),
        if (winner)
          Positioned(
            left: compact ? -2 : 0,
            top: compact ? -2 : 0,
            child: _WinnerMark(size: compact ? 18 : 22, color: winnerColor),
          ),
      ],
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showsCards)
          _DealIn(
            key: ValueKey('deal-$seat-$handNumber'),
            child: AnimatedOpacity(
              key: ValueKey('hole-cards-$seat'),
              duration: const Duration(milliseconds: 700),
              opacity: folded ? foldedCardOpacity : 1,
              alwaysIncludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 2; i++)
                    Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                      child: PlayingCardWidget(
                        card: p.holeCards != null && p.holeCards!.length > i
                            ? p.holeCards![i]
                            : null,
                        width: cardWidth,
                        fourColor: fourColor,
                        highlighted: _inBest(p, i),
                        highlightColor: winnerColor,
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          SizedBox(height: cardWidth * 1.4),
        const Gap(4),
        if (onAdminTap != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: Key('admin-seat-$seat'),
              behavior: HitTestBehavior.opaque,
              onTap: onAdminTap,
              child: avatarStack,
            ),
          )
        else
          avatarStack,
        const Gap(2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: isTurn ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (onSayTap != null) ...[
              const Gap(4),
              Tooltip(
                tooltip: TooltipContainer(child: Text(l10n.sayButton)).call,
                child: GestureDetector(
                  key: const Key('say-button'),
                  onTap: onSayTap,
                  child: Icon(
                    LucideIcons.messageCircleMore,
                    size: compact ? 13 : 15,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timeBankSeconds > 0) ...[
              Tooltip(
                tooltip: TooltipContainer(
                  child: Text(l10n.timeBankLeft(p.timeBank ?? 0)),
                ).call,
                child: _TimeBankLeft(
                  key: Key('timebank-stack-$seat'),
                  seconds: p.timeBank ?? 0,
                  // While the bank is running, the seconds count down from
                  // the server deadline instead of showing the balance.
                  deadlineTs: timeBankActive ? hand?.deadlineTs : null,
                  compact: compact,
                ),
              ),
              const Gap(6),
            ],
            // The stack as a few small chips, so its size can be read at a
            // glance; the number stays next to it.
            if (ref.watch(chipStacksProvider) && p.stack > 0) ...[
              ChipStackView(
                key: Key('seat-stack-$seat'),
                amount: p.stack,
                bigBlind: bigBlind,
                chipWidth: compact ? 7 : 8,
                maxChips: 8,
              ),
              const Gap(4),
            ],
            Text(
              formatAmount(
                p.stack,
                mode: chipDisplay,
                bigBlind: bigBlind,
                locale: locale,
              ),
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: theme.colorScheme.mutedForeground,
                fontFamily: 'GeistMono',
              ),
            ),
            if ((wonAmount ?? 0) > 0) ...[
              const Gap(4),
              Text(
                '+${formatAmount(wonAmount!, mode: chipDisplay, bigBlind: bigBlind, locale: locale)}',
                key: Key('won-$seat'),
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF43A047),
                  fontFamily: 'GeistMono',
                ),
              ),
            ],
          ],
        ),
        if (badges.isNotEmpty) ...[
          const Gap(2),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: badges,
          ),
        ],
        // The last action is not part of the seat box: the table view shows
        // it next to the bet chips, on the felt side of every seat.
      ],
    );
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          column,
          if (phrase != null)
            Positioned(
              top: cardWidth * 0.5,
              child: _PhraseBubble(
                key: ValueKey('phrase-$seat-$phrase'),
                text: phrase!,
              ),
            ),
        ],
      ),
    );
  }

  /// Whether hole card [i] belongs to the winning five at the showdown.
  bool _inBest(PlayerView p, int i) {
    final cards = p.holeCards;
    if (cards == null || cards.length <= i) return false;
    return best?.contains(cards[i]) ?? false;
  }
}

/// Opacity of a folded player's cards: still on the table, clearly out.
const double foldedCardOpacity = 0.35;

/// The text of a seat's last action ("Check", "Raise to 300").
String actionLabel(
  AppLocalizations l10n,
  LastAction a, {
  required ChipDisplay chipDisplay,
  required int bigBlind,
  required String locale,
}) {
  String amt(int v) =>
      formatAmount(v, mode: chipDisplay, bigBlind: bigBlind, locale: locale);
  switch (a.kind) {
    case 'fold':
      return l10n.fold;
    case 'check':
      return l10n.check;
    case 'call':
      return l10n.call(amt(a.amount));
    case 'bet':
      return l10n.betAmount(amt(a.amount));
    case 'raise':
      return l10n.raiseTo(amt(a.amount));
  }
  return a.kind;
}

/// Fades and slides a freshly dealt hand in from the table center.
class _DealIn extends StatefulWidget {
  const _DealIn({super.key, required this.child});
  final Widget child;

  @override
  State<_DealIn> createState() => _DealInState();
}

class _DealInState extends State<_DealIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
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
          begin: const Offset(0, 0.8),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

const _gold = winnerGold;

/// Gold used for everything that marks a winner: ring, badge, card borders.
const winnerGold = Color(0xFFE6B422);

/// A speech bubble with a quick phrase; pops in and is removed by the
/// session after a few seconds.
class _PhraseBubble extends StatelessWidget {
  const _PhraseBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.popover,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.popoverForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small trophy disc pinned to the winner's avatar; pops in with a
/// short scale animation.
class _WinnerMark extends StatelessWidget {
  const _WinnerMark({required this.size, this.color = _gold});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: const Color(0xFF3A2A00), width: 1),
        ),
        child: Icon(
          LucideIcons.trophy,
          size: size * 0.55,
          color: const Color(0xFF3A2A00),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.text, {
    super.key,
    this.primary = false,
    this.destructive = false,
    this.gold = false,
    this.goldColor = _gold,
  });
  final String text;
  final bool primary;
  final bool destructive;

  /// Winner: pot colour on dark, matching the avatar ring.
  final bool gold;
  final Color goldColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = gold
        ? goldColor
        : primary
        ? theme.colorScheme.primary
        : destructive
        ? theme.colorScheme.destructive
        : theme.colorScheme.secondary;
    final fg = gold
        ? const Color(0xFF3A2A00)
        : primary
        ? theme.colorScheme.primaryForeground
        : destructive
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.secondaryForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// A label that fades a few seconds after it appears (the last action of a
/// seat, shown on the felt side next to the bet chips).
class FadingActionLabel extends StatefulWidget {
  const FadingActionLabel({super.key, required this.text});
  final String text;

  @override
  State<FadingActionLabel> createState() => _FadingLabelState();
}

class _FadingLabelState extends State<FadingActionLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.35,
      ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.5, 1))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.foreground,
          ),
        ),
      ),
    );
  }
}

/// The time bank left of the stack: the balance, or, while the bank is
/// running, the seconds still left on the server deadline (ticking).
class _TimeBankLeft extends ConsumerStatefulWidget {
  const _TimeBankLeft({
    super.key,
    required this.seconds,
    required this.deadlineTs,
    required this.compact,
  });
  final int seconds;
  final int? deadlineTs;
  final bool compact;

  @override
  ConsumerState<_TimeBankLeft> createState() => _TimeBankLeftState();
}

class _TimeBankLeftState extends ConsumerState<_TimeBankLeft>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _TimeBankLeft old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.deadlineTs != null) {
      _ticker ??= createTicker((_) => setState(() {}))..start();
    } else {
      _ticker?.dispose();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.deadlineTs != null;
    var seconds = widget.seconds;
    if (active) {
      final now = ref.read(timeSyncProvider.notifier).serverNow();
      seconds = ((widget.deadlineTs! - now) / 1000).clamp(0, 9999).ceil();
    }
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.timer, size: widget.compact ? 10 : 11, color: color),
        const Gap(2),
        Text(
          '${seconds}s',
          style: TextStyle(
            fontSize: widget.compact ? 10 : 11,
            color: color,
            fontFamily: 'GeistMono',
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Countdown ring driven by the server deadline and the clock offset.
class _CountdownRing extends ConsumerStatefulWidget {
  const _CountdownRing({
    required this.deadlineTs,
    required this.totalMs,
    required this.size,
  });
  final int deadlineTs;
  final int totalMs;
  final double size;

  @override
  ConsumerState<_CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends ConsumerState<_CountdownRing>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.read(timeSyncProvider.notifier).serverNow();
    final remaining = (widget.deadlineTs - now).clamp(0, widget.totalMs);
    final fraction = widget.totalMs == 0 ? 0.0 : remaining / widget.totalMs;
    final theme = Theme.of(context);
    final color = fraction < 0.25
        ? theme.colorScheme.destructive
        : theme.colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _RingPainter(fraction, color, theme.colorScheme.border),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.track);
  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawArc(
      rect,
      0,
      6.2831853,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      rect,
      -1.5707963,
      6.2831853 * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
