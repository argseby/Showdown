import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/features/table/action_model.dart';
import 'package:showdown/features/table/widgets/action_bar.dart';
import 'package:showdown/protocol/protocol.dart';

import 'test_helpers.dart';

void main() {
  group('ActionBarModel', () {
    test('derives buttons and presets from the fixture snapshot', () {
      final m = ActionBarModel.from(fixtureSnapshot())!;
      expect(m.canFold, isTrue);
      expect(m.canCheck, isFalse);
      expect(m.callAmount, 300);
      expect(m.canRaise, isTrue);
      expect(m.raise!.min, 600);
      expect(m.raise!.max, 8450);
      expect(m.allIn, 8450);
      expect(m.isOpeningBet, isFalse);
      // Pot for presets: 300 in the pot + 300 bet by Bob this street.
      expect(m.potForPresets, 600);
      expect(m.preset(0), 600); // min
      expect(m.preset(double.infinity), 8450); // all-in
      // Pot preset: 0 (my bet) + 300 (call) + 1 * (600 + 300) = 1200.
      expect(m.preset(1.0), 1200);
      expect(
        m.preset(0.5),
        700,
      ); // 300 + 450 = 750, rounded down to a big-blind multiple
      expect(m.clamp(50), 600);
      expect(m.clamp(99999), 8450);
    });

    test('is null when it is not the viewer turn', () {
      final s = fixtureSnapshot();
      final notMyTurn = s.copyWith(you: s.you.copyWith(options: null));
      expect(ActionBarModel.from(notMyTurn), isNull);
    });
  });

  group('ActionBar widget', () {
    Future<(ActionBarState, List<String>)> pump(
      WidgetTester tester,
      Snapshot? snap, {
      bool isPlayer = true,
    }) async {
      final key = GlobalKey<ActionBarState>();
      final acted = <String>[];
      await tester.pumpWidget(
        wrap(
          ActionBar(
            key: key,
            snapshot: snap,
            isPlayer: isPlayer,
            myStatus: 'active',
            textFieldFocusChanged: (_) {},
            callbacks: ActionCallbacks(
              act: (kind, {amount}) =>
                  acted.add(amount == null ? kind : '$kind:$amount'),
              rebuy: () => acted.add('rebuy'),
              sitOut: () => acted.add('sit_out'),
              sitIn: () => acted.add('sit_in'),
              showCards: (which) => acted.add('show_cards:$which'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (key.currentState!, acted);
    }

    bool enabled(WidgetTester tester, Key key) {
      final button = find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate((w) => w is Button),
      );
      return tester.widget<Button>(button).onPressed != null;
    }

    testWidgets('options enable exactly the legal buttons', (tester) async {
      await pump(tester, fixtureSnapshot());
      expect(enabled(tester, const Key('action-fold')), isTrue);
      expect(enabled(tester, const Key('action-check-call')), isTrue);
      expect(find.text('Call 300'), findsOneWidget);
      expect(enabled(tester, const Key('action-raise')), isTrue);
      expect(find.text('Raise'), findsOneWidget);
      // All-in lives with the presets, not as a fourth button.
      expect(find.byKey(const Key('action-all-in')), findsNothing);
    });

    testWidgets('no action buttons when it is not your turn', (tester) async {
      final s = fixtureSnapshot();
      await pump(tester, s.copyWith(you: s.you.copyWith(options: null)));
      for (final k in ['action-fold', 'action-check-call', 'action-raise']) {
        expect(find.byKey(Key(k)), findsNothing, reason: k);
      }
      expect(find.byKey(const Key('sit-out')), findsOneWidget);
    });

    testWidgets('check option shows Check and raising closed disables raise', (
      tester,
    ) async {
      final s = fixtureSnapshot();
      const opts = OptionsView(
        fold: true,
        check: true,
        call: 0,
        raise: null,
        allIn: 0,
      );
      await pump(tester, s.copyWith(you: s.you.copyWith(options: opts)));
      expect(find.text('Check'), findsOneWidget);
      expect(enabled(tester, const Key('action-check-call')), isTrue);
      expect(enabled(tester, const Key('action-raise')), isFalse);
    });

    testWidgets('raise control clamps, presets and confirms', (tester) async {
      final (state, acted) = await pump(tester, fixtureSnapshot());
      expect(find.byKey(const Key('raise-control')), findsNothing);
      state.openRaise(focusInput: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('raise-control')), findsOneWidget);
      // Presets and all-in are equal-width buttons inside the panel.
      expect(find.byKey(const Key('preset-3')), findsOneWidget);
      expect(find.byKey(const Key('action-all-in')), findsOneWidget);
      state.preset(3); // pot
      await tester.pumpAndSettle();
      expect(find.text('Raise to 1,200'), findsOneWidget);
      state.adjust(1);
      await tester.pumpAndSettle();
      expect(find.text('Raise to 1,300'), findsOneWidget);
      // Typing an out-of-range value shows the allowed range inline and clamps.
      await tester.enterText(find.byKey(const Key('raise-amount')), '99999');
      await tester.pumpAndSettle();
      expect(find.text('Allowed: 600 - 8,450'), findsOneWidget);
      expect(state.confirm(), isTrue);
      expect(acted, ['raise:8450']);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('raise-control')), findsNothing);
    });

    testWidgets('fold and call callbacks', (tester) async {
      final (state, acted) = await pump(tester, fixtureSnapshot());
      state.checkOrCall();
      state.fold();
      expect(acted, ['call', 'fold']);
      expect(state.cancel(), isFalse);
    });

    testWidgets('spectators see no buttons', (tester) async {
      await pump(tester, fixtureSnapshot(), isPlayer: false);
      expect(find.byKey(const Key('action-fold')), findsNothing);
      expect(find.text('Spectating'), findsOneWidget);
    });
  });
}
