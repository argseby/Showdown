import '../../../protocol/protocol.dart';
import '../table_session.dart';

/// One seat's state while replaying a hand.
class ReplaySeat {
  ReplaySeat({required this.name, required this.avatar, required this.stack});
  final String name;
  final int avatar;
  int stack;
  int bet = 0;
  int total = 0;
  bool folded = false;
  bool allIn = false;
  List<String>? cards;
  LastAction? lastAction;
}

/// Rebuilds a hand step by step from its event log. Each step yields a
/// [Snapshot] that the normal table view can render; the client never
/// evaluates anything, it only replays what the server recorded.
class ReplayReducer {
  ReplayReducer({
    required this.events,
    required this.base,
    required this.handNumber,
    required this.names,
    required this.avatars,
    this.viewerSeat,
  });

  /// The events of the hand (from the hand history).
  final List<GameEvent> events;

  /// A snapshot of the table for name, settings and seat count.
  final Snapshot base;
  final int handNumber;
  final Map<int, String> names;
  final Map<int, int> avatars;
  final int? viewerSeat;

  /// State after applying events[0..step) — step 0 is before the deal.
  ReplayFrame frame(int step) {
    final seats = <int, ReplaySeat>{};
    var board = <String>[];
    var board2 = <String>[];
    var pots = <PotView>[];
    var street = 'preflop';
    var phase = 'betting';
    int button = 0, sb = 0, bb = 0;
    final best = <int, List<String>>{};
    final revealed = <int>{};
    final winners = <int>{};
    // The pot on display, the chips won so far and the winner spotlight,
    // exactly as the live table shows them one pot at a time.
    int? potIndex;
    final amounts = <int, int>{};
    Spotlight? spotlight;
    List<String>? rabbit;
    GameEvent? last;
    for (final e in events.take(step)) {
      last = e;
      final seat = e.seat;
      final p = seat == null ? null : seats[seat];
      switch (e.kind) {
        case 'hand_started':
          button = e.buttonSeat ?? 0;
          sb = e.sbSeat ?? 0;
          bb = e.bbSeat ?? 0;
          for (final entry in (e.stacks ?? const {}).entries) {
            final s = int.tryParse(entry.key);
            if (s == null) continue;
            seats[s] = ReplaySeat(
              name: names[s] ?? 'Seat ${s + 1}',
              avatar: avatars[s] ?? 0,
              stack: entry.value,
            );
          }
        case 'ante_posted':
        case 'blind_posted':
          if (p != null) {
            final amount = e.amount ?? 0;
            p.stack -= amount;
            p.bet += amount;
            p.total += amount;
            p.allIn = e.allIn ?? false;
          }
        case 'hole_cards_dealt':
          // Keep the suspense: other players' cards appear at the showdown
          // (hands_revealed), only the viewer sees their own from the deal.
          if (p != null && e.cards != null && seat == viewerSeat) {
            p.cards = e.cards;
          }
        case 'action':
        case 'timeout':
          if (p == null) break;
          final kind = e.kind == 'timeout' ? e.resolvedAs : e.action;
          final amount = e.amount ?? 0;
          switch (kind) {
            case 'fold':
              p.folded = true;
            case 'call':
              p.stack -= amount;
              p.bet += amount;
              p.total += amount;
            case 'bet':
            case 'raise':
              final delta = amount - p.bet;
              p.stack -= delta;
              p.bet = amount;
              p.total += delta;
          }
          if (e.allIn == true) p.allIn = true;
          p.lastAction = LastAction(kind: kind ?? 'check', amount: amount);
        case 'uncalled_returned':
          if (p != null) {
            final amount = e.amount ?? 0;
            p.stack += amount;
            p.bet -= amount;
            p.total -= amount;
          }
        case 'pots_updated':
          pots = e.pots ?? pots;
          for (final s in seats.values) {
            s.bet = 0;
          }
        case 'street_dealt':
          if (e.board == 2) {
            board2 = [...board2, ...?e.cards];
            break;
          }
          board = [...board, ...?e.cards];
          street = e.street ?? street;
          for (final s in seats.values) {
            s.bet = 0;
            s.lastAction = null;
          }
        case 'hands_revealed':
          for (final r in e.reveals ?? const <Reveal>[]) {
            seats[r.seat]?.cards = r.cards;
            if (r.cards.every((c) => c.isNotEmpty)) revealed.add(r.seat);
            if (r.best != null) best[r.seat] = r.best!;
          }
        case 'pot_awarded':
          if (p != null) p.stack += e.amount ?? 0;
          final pi = e.potIndex ?? 0;
          if (pi != potIndex) {
            // A new pot takes the stage: only its winners are shown.
            winners.clear();
            spotlight = null;
          }
          potIndex = pi;
          if (seat != null) {
            winners.add(seat);
            amounts[seat] = (amounts[seat] ?? 0) + (e.amount ?? 0);
            if ((e.description ?? '').isNotEmpty && spotlight == null) {
              spotlight = Spotlight(
                seat: seat,
                name: e.name?.isNotEmpty == true ? e.name! : names[seat] ?? '?',
                cards: best[seat] ?? const [],
                description: e.description!,
                winner: true,
                potIndex: pi,
              );
            }
          }
          phase = 'showdown';
        case 'hand_ended':
          phase = 'result';
        case 'rabbit_hunt':
          rabbit = e.cards;
      }
    }
    final maxPlayers = base.table.settings.maxPlayers;
    final seatViews = <SeatView>[
      for (var i = 0; i < maxPlayers; i++)
        SeatView(
          seat: i,
          player: seats[i] == null
              ? null
              : PlayerView(
                  id: 'replay-$i',
                  name: seats[i]!.name,
                  avatar: seats[i]!.avatar,
                  stack: seats[i]!.stack,
                  status: 'active',
                  connected: true,
                  inHand: true,
                  folded: seats[i]!.folded,
                  allIn: seats[i]!.allIn,
                  betThisStreet: seats[i]!.bet,
                  totalBet: seats[i]!.total,
                  holeCards: seats[i]!.cards,
                  lastAction: seats[i]!.lastAction,
                ),
        ),
    ];
    final snapshot = Snapshot(
      serverTs: 0,
      table: base.table.copyWith(handNumber: handNumber, nextBlindsUpTs: null),
      seats: seatViews,
      hand: step == 0
          ? null
          : HandView(
              street: street,
              board: board,
              buttonSeat: button,
              sbSeat: sb,
              bbSeat: bb,
              toActSeat: null,
              deadlineTs: null,
              currentBet: 0,
              minRaiseTo: 0,
              pots: pots,
              phase: phase,
              rabbitCards: rabbit,
              board2: board2.isEmpty ? null : board2,
              runTwice: board2.isEmpty ? null : true,
            ),
      you: You(
        role: viewerSeat == null ? 'spectator' : 'player',
        isAdmin: false,
        seat: viewerSeat,
        options: null,
        handDescription: '',
        canRebuy: false,
        canShowCards: false,
        preAction: 'none',
        canRabbitHunt: false,
      ),
      leaderboard: const [],
      spectators: 0,
    );
    return ReplayFrame(
      snapshot: snapshot,
      best: best,
      revealed: revealed,
      winners: winners,
      potIndex: potIndex,
      amounts: amounts,
      spotlight: spotlight,
      event: last,
    );
  }
}

/// One rendered replay step.
class ReplayFrame {
  const ReplayFrame({
    required this.snapshot,
    required this.best,
    required this.revealed,
    required this.winners,
    required this.event,
    this.potIndex,
    this.amounts = const {},
    this.spotlight,
  });
  final Snapshot snapshot;
  final Map<int, List<String>> best;
  final Set<int> revealed;
  final Set<int> winners;

  /// The pot whose award this step shows (null before any award).
  final int? potIndex;

  /// Chips won per seat up to this step.
  final Map<int, int> amounts;

  /// The winner under the spotlight at this step.
  final Spotlight? spotlight;
  final GameEvent? event;
}
