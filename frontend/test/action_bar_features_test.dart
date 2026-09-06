import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/features/table/widgets/action_bar.dart';
import 'package:showdown/protocol/protocol.dart';

import 'test_helpers.dart';

void main() {
  Future<(ActionBarState, List<String>)> pump(
    WidgetTester tester,
    Snapshot snap, {
    String myStatus = 'active',
    ChipDisplay chipDisplay = ChipDisplay.coins,
    List<bool> shown = const [],
  }) async {
    final key = GlobalKey<ActionBarState>();
    final acted = <String>[];
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrap(
        ActionBar(
          key: key,
          snapshot: snap,
          isPlayer: true,
          myStatus: myStatus,
          chipDisplay: chipDisplay,
          shown: shown,
          textFieldFocusChanged: (_) {},
          callbacks: ActionCallbacks(
            act: (kind, {amount}) =>
                acted.add(amount == null ? kind : '$kind:$amount'),
            rebuy: () => acted.add('rebuy'),
            sitOut: () => acted.add('sit_out'),
            sitIn: () => acted.add('sit_in'),
            showCards: (which) => acted.add('show:$which'),
            preAction: (kind) => acted.add('pre:$kind'),
            rabbitHunt: () => acted.add('rabbit'),
          ),
        ),
      ),
    );
    await tester.pump();
    return (key.currentState!, acted);
  }

  testWidgets('folding with a free check asks first', (tester) async {
    final s = fixtureSnapshot();
    final checkable = s.copyWith(
      you: s.you.copyWith(
        options: const OptionsView(
          fold: true,
          check: true,
          call: 0,
          raise: RaiseView(min: 100, max: 8450),
          allIn: 8450,
        ),
      ),
    );
    final (_, acted) = await pump(tester, checkable);
    await tester.tap(find.byKey(const Key('action-fold')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fold-check-instead')), findsOneWidget);
    expect(acted, isEmpty);
    await tester.tap(find.byKey(const Key('fold-check-instead')));
    await tester.pumpAndSettle();
    expect(acted, ['check']);
    // Facing a bet, fold is immediate.
    final (_, acted2) = await pump(tester, s);
    await tester.tap(find.byKey(const Key('action-fold')));
    await tester.pump();
    expect(acted2, ['fold']);
  });

  testWidgets('pre-actions show off-turn and toggle through the callback', (
    tester,
  ) async {
    final s = fixtureSnapshot();
    final offTurn = s.copyWith(you: s.you.copyWith(options: null));
    final (_, acted) = await pump(tester, offTurn);
    expect(find.byKey(const Key('pre-check-fold')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pre-call-any')));
    expect(acted, ['pre:call_any']);
    // An active pre-action is rendered as selected and toggles off.
    final selected = offTurn.copyWith(
      you: offTurn.you.copyWith(preAction: 'call_any'),
    );
    final (_, acted2) = await pump(tester, selected);
    expect(
      tester.widget(find.byKey(const Key('pre-call-any'))),
      isA<PrimaryButton>(),
    );
    await tester.tap(find.byKey(const Key('pre-call-any')));
    expect(acted2, ['pre:none']);
    // On the viewer's turn the toggles disappear.
    await pump(tester, s);
    expect(find.byKey(const Key('pre-check-fold')), findsNothing);
  });

  testWidgets('sitting out hides the betting buttons', (tester) async {
    final s = fixtureSnapshot();
    final (_, acted) = await pump(tester, s, myStatus: 'sitting_out');
    expect(find.byKey(const Key('action-fold')), findsNothing);
    expect(find.byKey(const Key('pre-check-fold')), findsNothing);
    await tester.tap(find.byKey(const Key('sit-in')));
    expect(acted, ['sit_in']);
  });

  testWidgets('show one card and rabbit hunt after the hand', (tester) async {
    final s = fixtureSnapshot();
    final result = s.copyWith(
      you: s.you.copyWith(
        options: null,
        canShowCards: true,
        canRabbitHunt: true,
        handDescription: 'Pair of Aces',
      ),
    );
    final (_, acted) = await pump(tester, result, shown: const [true, false]);
    // The hand line lives on the felt now, not in the action bar.
    expect(find.byKey(const Key('your-hand')), findsNothing);
    expect(
      tester
          .widget<OutlineButton>(find.byKey(const Key('show-first')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('show-second')));
    await tester.tap(find.byKey(const Key('rabbit-hunt')));
    expect(acted, ['show:second', 'rabbit']);
  });

  testWidgets('big-blind mode formats the call and parses the raise input', (
    tester,
  ) async {
    final s = fixtureSnapshot();
    final (state, acted) = await pump(
      tester,
      s,
      chipDisplay: ChipDisplay.bigBlinds,
    );
    expect(find.text('Call 3 BB'), findsOneWidget);
    state.openRaise();
    await tester.pump();
    await tester.enterText(find.byKey(const Key('raise-amount')), '7.5');
    await tester.pump();
    state.confirm();
    await tester.pump();
    expect(acted, ['raise:750']);
  });
}
