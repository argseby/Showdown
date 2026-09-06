import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/ws_client.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/features/table/widgets/action_bar.dart';
import 'package:showdown/features/table/widgets/table_view.dart';
import 'package:showdown/protocol/protocol.dart';

import 'test_helpers.dart';

void main() {
  TableSessionState session(Snapshot snap) => TableSessionState(
    connection: const WsState(status: WsStatus.ready),
    snapshot: snap,
    identity: const YouIdentity(role: 'player', playerId: 'p1', seat: 0),
  );

  testWidgets('run-out shows equity, a second board and the straddle badge', (
    tester,
  ) async {
    final base = fixtureSnapshot();
    final snap = base.copyWith(
      hand: base.hand!.copyWith(
        phase: 'runout',
        toActSeat: null,
        straddleSeat: 4,
        runTwice: true,
        board2: const ['Ah', '7c', '2d', 'Kd'],
      ),
      seats: [
        for (final sv in base.seats)
          sv.copyWith(
            player: sv.player?.copyWith(equity: sv.seat == 0 ? 62.5 : 37.5),
          ),
      ],
    );
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 1000,
          height: 600,
          child: TableView(session: session(snap)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('equity-0')), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.text('38%'), findsOneWidget);
    expect(find.byKey(const Key('board-2')), findsOneWidget);
    expect(find.text('STR'), findsOneWidget);
  });

  testWidgets('the action bar offers the straddle and the run-it-twice vote', (
    tester,
  ) async {
    final base = fixtureSnapshot();
    final acted = <String>[];
    Widget bar(Snapshot snap) => wrap(
      ActionBar(
        snapshot: snap,
        isPlayer: true,
        myStatus: 'active',
        textFieldFocusChanged: (_) {},
        callbacks: ActionCallbacks(
          act: (kind, {amount}) => acted.add(kind),
          rebuy: () {},
          sitOut: () {},
          sitIn: () {},
          showCards: (_) {},
          preAction: (_) {},
          straddle: (on) => acted.add('straddle:$on'),
          runTwice: (agree) => acted.add('run_twice:$agree'),
        ),
      ),
    );
    final offTurn = base.copyWith(
      you: base.you.copyWith(options: null),
      table: base.table.copyWith(
        settings: base.table.settings.copyWith(allowStraddle: true),
      ),
    );
    await tester.pumpWidget(bar(offTurn));
    await tester.pump();
    await tester.tap(find.byKey(const Key('straddle-toggle')));
    expect(acted, ['straddle:true']);
    final vote = offTurn.copyWith(
      you: offTurn.you.copyWith(canRunTwice: true),
      hand: offTurn.hand!.copyWith(phase: 'runout', runTwiceEndsTs: 1),
    );
    await tester.pumpWidget(bar(vote));
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-twice-yes')));
    expect(acted.last, 'run_twice:true');
    final voted = vote.copyWith(
      you: vote.you.copyWith(canRunTwice: null, runTwiceVote: true),
    );
    await tester.pumpWidget(bar(voted));
    await tester.pump();
    expect(find.byKey(const Key('run-twice-status')), findsOneWidget);
    expect(find.byKey(const Key('run-twice-yes')), findsNothing);
  });
}
