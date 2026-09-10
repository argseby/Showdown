import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/core/ws_client.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/features/table/widgets/seat_widget.dart';
import 'package:showdown/features/table/widgets/table_view.dart';
import 'package:showdown/protocol/protocol.dart';
import 'package:showdown/shared/playing_card.dart';
import 'package:showdown/shared/pot_colors.dart';

import 'test_helpers.dart';

/// Puts the hand line on the felt; below the table is the default.
class _BoardHandLine extends HandLineNotifier {
  @override
  HandLinePlacement build() => HandLinePlacement.board;
}

final _onBoard = [handLineProvider.overrideWith(_BoardHandLine.new)];

/// Numbers only, no chip stacks.
class _NoStacks extends ChipStacksNotifier {
  @override
  bool build() => false;
}

void main() {
  test('seat positions rotate the viewer to the bottom', () {
    expect(TableView.positionOf(4, 4, 9), 0);
    expect(TableView.positionOf(5, 4, 9), 1);
    expect(TableView.positionOf(3, 4, 9), 8);
    const oval = Rect.fromLTWH(0, 0, 400, 200);
    final bottom = TableView.seatPoint(0, 9, oval);
    expect(bottom.dx, closeTo(200, 0.01));
    expect(bottom.dy, closeTo(200, 0.01));
  });

  testWidgets('a failed voice link shows a badge on that seat', (tester) async {
    final snap = fixtureSnapshot();
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 1000,
          height: 600,
          child: TableView(session: session, voiceFailed: const {'p4'}),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('no-audio-4')), findsOneWidget);
    expect(find.text('No audio'), findsOneWidget);
  });

  testWidgets('renders own cards face up and omitted hole cards face down', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump();

    final cards = tester
        .widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget))
        .toList();
    // Alice: 2 face-up hole cards; Bob (hole_cards omitted): 2 face-down; board: 3.
    final faceUp = cards
        .where((c) => c.card != null)
        .map((c) => c.card!)
        .toList();
    final faceDown = cards.where((c) => c.card == null).length;
    expect(faceUp, containsAll(['As', 'Kd', 'Ah', '7c', '2d']));
    expect(faceUp.length, 5);
    expect(faceDown, 2);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Main pot: '), findsOneWidget);
    expect(
      find.text('Empty'),
      findsOneWidget,
    ); // the fixture lists seats 0, 1 and 4 only
    expect(find.bySemanticsLabel('face-down card'), findsNWidgets(2));
  });

  testWidgets('spectator sees every hand face down', (tester) async {
    final snap = fixtureSnapshot();
    final stripped = snap.copyWith(
      seats: [
        for (final sv in snap.seats)
          sv.copyWith(player: sv.player?.copyWith(holeCards: null)),
      ],
      you: const You(
        isAdmin: false,
        role: 'spectator',
        options: null,
        handDescription: '',
        canRebuy: false,
        canShowCards: false,
        preAction: 'none',
        canRabbitHunt: false,
      ),
    );
    final session = TableSessionState(
      snapshot: stripped,
      identity: const YouIdentity(role: 'spectator'),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('face-down card'), findsNWidgets(4));
    expect(find.bySemanticsLabel('Ace of spades'), findsNothing);
  });

  testWidgets('the host opens player actions by tapping another avatar', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    String? tapped;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 1000,
          height: 600,
          child: TableView(
            session: session,
            onAdminTap: (p) => tapped = p.name,
          ),
        ),
      ),
    );
    await tester.pump();
    // The host's own seat has no menu; Bob's does.
    expect(find.byKey(const Key('admin-seat-0')), findsNothing);
    await tester.tap(find.byKey(const Key('admin-seat-4')));
    expect(tapped, 'Bob');
  });
  _moreTests();
  _potTests();
  _showdownTests();
  _markerTests();
}

void _moreTests() {
  testWidgets('folded cards stay on the table, dimmed', (tester) async {
    final snap = fixtureSnapshot();
    final folded = snap.copyWith(
      seats: [
        for (final sv in snap.seats)
          sv.seat == 4
              ? sv.copyWith(player: sv.player?.copyWith(folded: true))
              : sv,
      ],
    );
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: folded,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    // Bob's two face-down cards are still drawn, at reduced opacity.
    expect(find.bySemanticsLabel('face-down card'), findsNWidgets(2));
    final fade = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('hole-cards-4')),
    );
    expect(fade.opacity, foldedCardOpacity);
    expect(fade.opacity, greaterThan(0.2));
    final own = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('hole-cards-0')),
    );
    expect(own.opacity, 1);
  });

  testWidgets('every seat shows its last action on the felt side', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    // Bob (top of the table) bet 300; Alice (bottom, the viewer) checked;
    // a third seat is on turn so both labels are showing.
    final withActions = snap.copyWith(
      hand: snap.hand!.copyWith(toActSeat: 3),
      seats: [
        for (final sv in snap.seats)
          sv.seat == 0
              ? sv.copyWith(
                  player: sv.player?.copyWith(
                    lastAction: const LastAction(kind: 'check', amount: 0),
                  ),
                )
              : sv,
      ],
    );
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: withActions,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump();
    final table = tester.getRect(find.byType(TableView));
    final center = table.center;
    Offset seatCenter(int seat) => tester.getCenter(
      find.byWidgetPredicate((w) => w is SeatWidget && w.seat == seat),
    );
    // Alice's "Check" and Bob's "Bet 300" both sit between their seat and
    // the middle of the table, not on the far side of the seat box.
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('Bet 300'), findsOneWidget);
    final check = tester.getCenter(find.text('Check'));
    final bet = tester.getCenter(find.text('Bet 300'));
    expect(
      (check - center).distance,
      lessThan((seatCenter(0) - center).distance),
    );
    expect(check.dy, lessThan(seatCenter(0).dy));
    expect(
      (bet - center).distance,
      lessThan((seatCenter(4) - center).distance),
    );
    // The label is not inside the seat box any more.
    final seatBox = tester.getRect(
      find.byWidgetPredicate((w) => w is SeatWidget && w.seat == 0),
    );
    expect(seatBox.contains(check), isFalse);
  });

  testWidgets('the spotlight follows the snapshot after later streets', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    // Bob showed a pair of queens on the flop; by the river the snapshot
    // says the board gave him a set, and that is what the table shows.
    final river = snap.copyWith(
      hand: snap.hand!.copyWith(
        street: 'river',
        board: ['Ah', '7c', '2d', 'Qh', '3s'],
        phase: 'runout',
        toActSeat: null,
      ),
      seats: [
        for (final sv in snap.seats)
          sv.seat == 4
              ? sv.copyWith(
                  player: sv.player?.copyWith(
                    holeCards: ['Qs', 'Qd'],
                    handDescription: 'Three of a Kind, Queens',
                    bestCards: ['Qs', 'Qd', 'Qh', 'Ah', '7c'],
                  ),
                )
              : sv,
      ],
    );
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: river,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
      revealed: const {4},
      best: const {
        4: ['Qs', 'Qd', 'Ah', '7c', '2d'],
      },
      spotlight: const Spotlight(
        seat: 4,
        name: 'Bob',
        cards: ['Qs', 'Qd', 'Ah', '7c', '2d'],
        description: 'Pair of Queens',
      ),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump();
    expect(find.text('Bob: Three of a Kind, Queens'), findsOneWidget);
    expect(find.text('Bob: Pair of Queens'), findsNothing);
    final highlighted = tester
        .widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget))
        .where((c) => c.highlighted)
        .map((c) => c.card)
        .toSet();
    expect(highlighted, {'Qs', 'Qd', 'Qh', 'Ah', '7c'});
  });
}

void _potTests() {
  testWidgets('the hand line sits on the felt under the board', (tester) async {
    final snap = fixtureSnapshot();
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
        overrides: _onBoard,
      ),
    );
    await tester.pump();
    final line = find.byKey(const Key('your-hand'));
    expect(line, findsOneWidget);
    expect(find.text('Your hand: Pair of Aces'), findsOneWidget);
    final table = tester.getRect(find.byType(TableView));
    final board = tester.getCenter(find.bySemanticsLabel('Ace of hearts'));
    final at = tester.getCenter(line);
    expect(at.dy, greaterThan(board.dy));
    expect((at.dx - table.center.dx).abs(), lessThan(40));
    expect(at.dy, lessThan(table.center.dy + 80));
  });

  testWidgets('pots and winner visuals wear the pot colour', (tester) async {
    final snap = fixtureSnapshot();
    final twoPots = snap.copyWith(
      hand: snap.hand!.copyWith(
        pots: const [
          PotView(amount: 300, eligibleSeats: [0, 4]),
          PotView(amount: 100, eligibleSeats: [4]),
        ],
        phase: 'showdown',
        toActSeat: null,
      ),
    );
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: twoPots,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
      winners: const {4},
      winnerPotIndex: 1,
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump();
    expect(find.text('Main pot: '), findsOneWidget);
    expect(find.text('Side pot 1: '), findsOneWidget);
    Color borderOf(String key) {
      final box =
          tester.widget<Container>(find.byKey(ValueKey(key))).decoration
              as BoxDecoration;
      return box.border!.top.color;
    }

    expect(borderOf('pot-0'), potGold.withValues(alpha: 0.8));
    expect(borderOf('pot-1'), potSilver.withValues(alpha: 0.8));
    // Bob won the side pot: his ring is silver, not gold.
    final bob = tester.widget<SeatWidget>(
      find.byWidgetPredicate((w) => w is SeatWidget && w.seat == 4),
    );
    expect(bob.winner, isTrue);
    expect(bob.winnerColor, potSilver);
    expect(find.byKey(const Key('winner-4')), findsOneWidget);
    expect(find.byKey(const Key('winner-0')), findsNothing);
  });
}

void _showdownTests() {
  testWidgets('a split pot highlights the cards of both winners', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    final split = snap.copyWith(
      hand: snap.hand!.copyWith(
        board: ['Ah', '7c', '2d', 'Qh', '3s'],
        phase: 'showdown',
        toActSeat: null,
      ),
      seats: [
        for (final sv in snap.seats)
          sv.seat == 4
              ? sv.copyWith(
                  player: sv.player?.copyWith(
                    holeCards: ['As', 'Kc'],
                    bestCards: ['As', 'Ah', 'Kc', 'Qh', '7c'],
                  ),
                )
              : sv.seat == 0
              ? sv.copyWith(
                  player: sv.player?.copyWith(
                    bestCards: ['As', 'Ah', 'Kd', 'Qh', '7c'],
                  ),
                )
              : sv,
      ],
    );
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: split,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
      winners: const {0, 4},
      winnerPotIndex: 0,
      winnerAmounts: const {0: 450, 4: 450},
      spotlight: const Spotlight(
        seat: 0,
        name: 'Alice',
        cards: ['As', 'Ah', 'Kd', 'Qh', '7c'],
        description: 'Pair of Aces',
        winner: true,
        potIndex: 0,
      ),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
        overrides: _onBoard,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final highlighted = tester
        .widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget))
        .where((c) => c.highlighted)
        .map((c) => c.card)
        .toSet();
    // Both hole cards of both winners, plus the shared board cards.
    expect(highlighted, containsAll(['As', 'Kd', 'Kc', 'Ah', 'Qh', '7c']));
    expect(find.byKey(const Key('won-0')), findsOneWidget);
    expect(find.byKey(const Key('won-4')), findsOneWidget);
    expect(find.text('+450'), findsNWidgets(2));
    // The hand line stays visible next to the spotlight.
    expect(find.byKey(const Key('your-hand')), findsOneWidget);
    expect(find.byKey(const Key('spotlight-label')), findsOneWidget);
    // The main pot is the one on display.
    final pot = tester.widget<Container>(find.byKey(const ValueKey('pot-0')));
    expect((pot.decoration as BoxDecoration).color, potGold);
  });
}

void _markerTests() {
  testWidgets('dealer and blind markers sit on the felt, not on the seat', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    // Fixture: button seat 3 (empty), SB seat 4 (Bob), BB seat 0 (Alice).
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('marker-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('marker-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('marker-3')), findsNothing);
    expect(find.text('BB'), findsOneWidget);
    expect(find.text('SB'), findsOneWidget);
    // Inside the felt, away from the seat box.
    final table = tester.getRect(find.byType(TableView));
    final bb = tester.getCenter(find.byKey(const ValueKey('marker-0')));
    final seat = tester.getRect(
      find.byWidgetPredicate((w) => w is SeatWidget && w.seat == 0),
    );
    expect(seat.contains(bb), isFalse);
    expect(
      (bb - table.center).distance,
      lessThan((seat.center - table.center).distance),
    );
  });

  testWidgets('bets, pots and seats are drawn as chip stacks', (tester) async {
    final snap = fixtureSnapshot();
    Widget view(TableSessionState session) => wrap(
      SizedBox(width: 1000, height: 600, child: TableView(session: session)),
    );
    // Bob's 300 on the felt is a stack next to the amount.
    await tester.pumpWidget(
      view(
        TableSessionState(
          connection: const WsState(status: WsStatus.ready),
          snapshot: snap,
          identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('bet-stack-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('pot-stack-0')), findsOneWidget);
    expect(find.byKey(const Key('seat-stack-4')), findsOneWidget);
  });

  testWidgets('chip stacks can be switched off for numbers only', (
    tester,
  ) async {
    final snap = fixtureSnapshot();
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 1000, height: 600, child: TableView(session: session)),
        overrides: [chipStacksProvider.overrideWith(_NoStacks.new)],
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('bet-stack-4')), findsNothing);
    expect(find.byKey(const ValueKey('pot-stack-0')), findsNothing);
    expect(find.byKey(const Key('seat-stack-4')), findsNothing);
    // The amounts are still there.
    expect(find.text('300'), findsWidgets);
  });

  testWidgets('the hand line follows the placement preference', (tester) async {
    final snap = fixtureSnapshot();
    final session = TableSessionState(
      connection: const WsState(status: WsStatus.ready),
      snapshot: snap,
      identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrap(
          SizedBox(
            width: 1000,
            height: 600,
            child: TableView(session: session),
          ),
        ),
      ),
    );
    await tester.pump();
    // Below the table by default: nothing on the felt.
    expect(find.byKey(const Key('your-hand')), findsNothing);
    container.read(handLineProvider.notifier).set(HandLinePlacement.board);
    await tester.pump();
    expect(find.byKey(const Key('your-hand')), findsOneWidget);
    container.read(handLineProvider.notifier).set(HandLinePlacement.off);
    await tester.pump();
    expect(find.byKey(const Key('your-hand')), findsNothing);
  });
}
