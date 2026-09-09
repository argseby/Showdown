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
    // On the viewer's turn the toggles stay in place but are disabled.
    await pump(tester, s);
    expect(
      tester
          .widget<OutlineButton>(find.byKey(const Key('pre-check-fold')))
          .onPressed,
      isNull,
    );
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

  testWidgets('a folded player sees the notice in place of the buttons, at '
      'the same height', (tester) async {
    final s = fixtureSnapshot();
    final offTurn = s.copyWith(you: s.you.copyWith(options: null));
    final folded = offTurn.copyWith(
      seats: [
        for (final sv in offTurn.seats)
          sv.seat == offTurn.you.seat
              ? sv.copyWith(player: sv.player!.copyWith(folded: true))
              : sv,
      ],
    );
    await pump(tester, folded);
    expect(find.byKey(const Key('folded-notice')), findsOneWidget);
    final foldedHeight = tester.getSize(find.byType(ActionBar)).height;
    // The buttons are still in the tree (they set the height) but hidden
    // and inert; the notice covers exactly their footprint.
    final fold = find.byKey(const Key('action-fold'));
    expect(fold, findsOneWidget);
    final hidden = tester.widget<Visibility>(
      find.ancestor(of: fold, matching: find.byType(Visibility)).first,
    );
    expect(hidden.visible, isFalse);
    expect(hidden.maintainSize, isTrue);
    expect(
      tester
          .widget<Button>(
            find.descendant(of: fold, matching: find.byType(Button)),
          )
          .onPressed,
      isNull,
    );
    final notice = tester.getRect(find.byKey(const Key('folded-notice')));
    final buttons = tester
        .getRect(fold)
        .expandToInclude(tester.getRect(find.byKey(const Key('action-raise'))));
    expect(notice, buttons);
    // Out of the hand, the pre-actions are moot: both toggles are disabled.
    for (final k in const ['pre-check-fold', 'pre-call-any']) {
      expect(
        tester.widget<OutlineButton>(find.byKey(Key(k))).onPressed,
        isNull,
        reason: '$k should be disabled after folding',
      );
    }
    // Still in the hand: no notice, the toggles work, and the bar is
    // exactly as tall.
    await pump(tester, offTurn);
    expect(find.byKey(const Key('folded-notice')), findsNothing);
    expect(
      tester
          .widget<OutlineButton>(find.byKey(const Key('pre-check-fold')))
          .onPressed,
      isNotNull,
    );
    expect(tester.getSize(find.byType(ActionBar)).height, foldedHeight);
  });

  testWidgets('rebuy and sit out share the top row, the action buttons stay '
      'at the bottom', (tester) async {
    final s = fixtureSnapshot();
    final broke = s.copyWith(
      you: s.you.copyWith(options: null, canRebuy: true, canShowCards: true),
    );
    final (_, acted) = await pump(tester, broke);
    // The three action buttons are still the bottom row, disabled.
    for (final k in ['action-fold', 'action-check-call', 'action-raise']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      expect(
        tester
            .widget<Button>(
              find.descendant(
                of: find.byKey(Key(k)),
                matching: find.byType(Button),
              ),
            )
            .onPressed,
        isNull,
        reason: k,
      );
    }
    final toggles = tester.getCenter(find.byKey(const Key('pre-check-fold')));
    final rebuy = tester.getCenter(find.byKey(const Key('rebuy')));
    final sitOut = tester.getCenter(find.byKey(const Key('sit-out')));
    final show = tester.getCenter(find.byKey(const Key('show-both')));
    final fold = tester.getCenter(find.byKey(const Key('action-fold')));
    // Rebuy and sit out sit on the pre-action row; the result controls
    // take the row between it and the action buttons.
    expect(rebuy.dy, closeTo(toggles.dy, 1));
    expect(sitOut.dy, closeTo(toggles.dy, 1));
    expect(show.dy, greaterThan(toggles.dy));
    expect(fold.dy, greaterThan(show.dy));
    await tester.tap(find.byKey(const Key('rebuy')));
    await tester.tap(find.byKey(const Key('sit-out')));
    expect(acted, ['rebuy', 'sit_out']);
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
  _graceTests();
}

void _graceTests() {
  testWidgets('the action buttons arm shortly after the turn arrives', (
    tester,
  ) async {
    final s = fixtureSnapshot();
    final offTurn = s.copyWith(you: s.you.copyWith(options: null));
    // Off turn: the buttons are there, disabled, under a pre-action row.
    await tester.pumpWidget(
      wrap(
        ActionBar(
          snapshot: offTurn,
          callbacks: ActionCallbacks(
            act: (_, {amount}) {},
            rebuy: () {},
            sitOut: () {},
            sitIn: () {},
            showCards: (_) {},
            preAction: (_) {},
          ),
          isPlayer: true,
          myStatus: 'active',
          textFieldFocusChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('action-fold')), findsOneWidget);
    expect(find.byKey(const Key('pre-check-fold')), findsOneWidget);
    // The pre-action row is above the action row.
    final toggles = tester.getCenter(find.byKey(const Key('pre-check-fold')));
    final fold = tester.getCenter(find.byKey(const Key('action-fold')));
    expect(toggles.dy, lessThan(fold.dy));
    // The turn arrives: the buttons stay disabled for the grace period.
    await tester.pumpWidget(
      wrap(
        ActionBar(
          snapshot: s,
          callbacks: ActionCallbacks(
            act: (_, {amount}) {},
            rebuy: () {},
            sitOut: () {},
            sitIn: () {},
            showCards: (_) {},
            preAction: (_) {},
          ),
          isPlayer: true,
          myStatus: 'active',
          textFieldFocusChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    bool foldEnabled() =>
        tester
            .widget<Button>(
              find.descendant(
                of: find.byKey(const Key('action-fold')),
                matching: find.byType(Button),
              ),
            )
            .onPressed !=
        null;

    expect(foldEnabled(), isFalse);
    await tester.pump(ActionBar.armDelay + const Duration(milliseconds: 50));
    expect(foldEnabled(), isTrue);
  });
}
