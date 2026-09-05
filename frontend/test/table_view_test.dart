import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/ws_client.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/features/table/widgets/table_view.dart';
import 'package:showdown/protocol/protocol.dart';
import 'package:showdown/shared/playing_card.dart';

import 'test_helpers.dart';

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
}
