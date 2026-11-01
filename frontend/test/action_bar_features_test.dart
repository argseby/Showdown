import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/core/strength.dart';
import 'package:showdown/features/table/widgets/action_bar.dart';
import 'package:showdown/protocol/protocol.dart';
import 'package:showdown/shared/shown_cards_icon.dart';

import 'test_helpers.dart';

void main() {
  Future<(ActionBarState, List<String>)> pump(
    WidgetTester tester,
    Snapshot snap, {
    String myStatus = 'active',
    ChipDisplay chipDisplay = ChipDisplay.coins,
    List<bool> shown = const [],
    bool potOdds = false,
    Strength? strength,
    List<HandNote> notes = const [],
    String? handLine,
    VoidCallback? onRankings,
    Size size = const Size(1000, 700),
  }) async {
    final key = GlobalKey<ActionBarState>();
    final acted = <String>[];
    tester.view.physicalSize = size;
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
          potOdds: potOdds,
          strength: strength,
          notes: notes,
          handLine: handLine,
          onRankings: onRankings,
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

  testWidgets('on a narrow screen the show-cards buttons are card icons', (
    tester,
  ) async {
    final s = fixtureSnapshot();
    final result = s.copyWith(
      you: s.you.copyWith(options: null, canShowCards: true),
    );
    final (_, acted) = await pump(tester, result, size: const Size(400, 800));
    expect(find.text('Show 1st'), findsNothing);
    expect(find.text('Show cards'), findsNothing);
    ShownCardsIcon iconIn(String key) => tester.widget<ShownCardsIcon>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(ShownCardsIcon),
      ),
    );
    // White card = shown: first only, second only, both.
    expect(
      (iconIn('show-first').first, iconIn('show-first').second),
      (true, false),
    );
    expect(
      (iconIn('show-second').first, iconIn('show-second').second),
      (false, true),
    );
    expect(
      (iconIn('show-both').first, iconIn('show-both').second),
      (true, true),
    );
    await tester.tap(find.byKey(const Key('show-both')));
    expect(acted, ['show:both']);
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

  testWidgets('rebuy and sit out share the top row, the show-cards buttons '
      'take the bottom row', (tester) async {
    final s = fixtureSnapshot();
    final broke = s.copyWith(
      you: s.you.copyWith(options: null, canRebuy: true, canShowCards: true),
    );
    final (_, acted) = await pump(tester, broke);
    // Once the hand is over for the viewer the show-cards buttons replace
    // the action buttons at full size.
    for (final k in ['action-fold', 'action-check-call', 'action-raise']) {
      expect(find.byKey(Key(k)), findsNothing, reason: k);
    }
    final toggles = tester.getCenter(find.byKey(const Key('pre-check-fold')));
    final rebuy = tester.getCenter(find.byKey(const Key('rebuy')));
    final sitOut = tester.getCenter(find.byKey(const Key('sit-out')));
    final first = tester.getCenter(find.byKey(const Key('show-first')));
    final show = tester.getCenter(find.byKey(const Key('show-both')));
    // Rebuy and sit out sit on the pre-action row; the show buttons share
    // one row below it, as wide as the action buttons would be.
    expect(rebuy.dy, closeTo(toggles.dy, 1));
    expect(sitOut.dy, closeTo(toggles.dy, 1));
    expect(show.dy, greaterThan(toggles.dy));
    expect(first.dy, closeTo(show.dy, 1));
    expect(
      tester.getSize(find.byKey(const Key('show-both'))).width,
      greaterThan(200),
    );
    await tester.tap(find.byKey(const Key('rebuy')));
    await tester.tap(find.byKey(const Key('sit-out')));
    expect(acted, ['rebuy', 'sit_out']);
  });

  testWidgets('the top row scrolls sideways instead of wrapping', (
    tester,
  ) async {
    final s = fixtureSnapshot();
    final offTurn = s.copyWith(
      you: s.you.copyWith(options: null, canRebuy: true),
      table: s.table.copyWith(
        settings: s.table.settings.copyWith(allowStraddle: true),
      ),
    );
    await pump(tester, offTurn, size: const Size(320, 700));
    final toggles = tester.getCenter(find.byKey(const Key('pre-check-fold')));
    final sitOut = tester.getCenter(find.byKey(const Key('sit-out')));
    // Everything stays on one line; the far end is simply off screen.
    expect(sitOut.dy, closeTo(toggles.dy, 1));
    expect(sitOut.dx, greaterThan(320));
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

  group('sitting out', () {
    testWidgets('the bar says nothing about a hand you left', (tester) async {
      final s = fixtureSnapshot();
      await pump(
        tester,
        s,
        myStatus: 'sitting_out',
        potOdds: true,
        strength: const Strength(
          equity: 0.6,
          opponents: 1,
          tier: 'good',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(action: 'call', reason: 'worth_price', need: 0.3),
        ),
        notes: const [HandNote(id: 'flush_possible', suit: 'h')],
        // Everything is handed to the bar; away from the table it shows
        // none of it, without relying on the page to hold it back.
        handLine: 'Pair of Aces',
      );
      expect(find.byKey(const Key('your-hand-bottom')), findsNothing);
      expect(find.byKey(const Key('board-notes')), findsNothing);
      expect(find.byKey(const Key('advice-box')), findsNothing);
      expect(find.byKey(const Key('pot-odds')), findsNothing);
      expect(find.byKey(const Key('sit-in')), findsOneWidget);
    });
  });

  group('the result buttons', () {
    testWidgets('so does the show-cards button', (tester) async {
      final s = fixtureSnapshot();
      await pump(
        tester,
        s.copyWith(you: s.you.copyWith(options: null, canShowCards: true)),
      );
      final icon = find.byIcon(LucideIcons.eye);
      final text = find.text('Show cards');
      expect(icon, findsOneWidget);
      expect(text, findsOneWidget);
      final gap = tester.getTopLeft(text).dx - tester.getBottomRight(icon).dx;
      expect(gap, lessThan(16), reason: 'icon ${gap.round()}px from its label');
    });

    testWidgets('the rabbit keeps its icon next to its label', (tester) async {
      final s = fixtureSnapshot();
      await pump(
        tester,
        s.copyWith(
          you: s.you.copyWith(
            options: null,
            canShowCards: false,
            canRabbitHunt: true,
          ),
        ),
      );
      final icon = find.byIcon(LucideIcons.rabbit);
      final text = find.text('Rabbit hunt');
      expect(icon, findsOneWidget);
      expect(text, findsOneWidget);
      // A button that fills the bar must not leave its icon at the far
      // left with the label adrift in the middle: the two are one label.
      final gap = tester.getTopLeft(text).dx - tester.getBottomRight(icon).dx;
      expect(
        gap,
        lessThan(16),
        reason: 'the icon sits ${gap.round()}px from its own label',
      );
    });
  });

  group('advice', () {
    testWidgets('the box carries the way into the hand rankings', (
      tester,
    ) async {
      var opened = false;
      final s = fixtureSnapshot();
      await pump(
        tester,
        s,
        onRankings: () => opened = true,
        strength: const Strength(
          equity: 0.6,
          opponents: 1,
          tier: 'good',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(action: 'call', reason: 'worth_price', need: 0.3),
        ),
        // What the page passes once the box names the hand: no line under
        // the buttons, because the box is already saying it.
        handLine: null,
      );
      expect(find.byKey(const Key('your-hand-bottom')), findsNothing);
      await tester.tap(find.byKey(const Key('advice-rankings')));
      await tester.pump();
      expect(opened, isTrue);
    });

    testWidgets('every part of the box is on screen, none of it clipped', (
      tester,
    ) async {
      await pump(
        tester,
        fixtureSnapshot(),
        handLine: 'Pair of Aces',
        notes: const [HandNote(id: 'flush_possible', suit: 'h')],
        strength: const Strength(
          equity: 0.6,
          opponents: 1,
          tier: 'good',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(action: 'call', reason: 'worth_price', need: 0.3),
        ),
      );
      // A box that animates its own height clips whatever it has not
      // measured yet — which was the hand at the top of it.
      final box = tester.getRect(find.byKey(const Key('advice-box')));
      for (final part in [
        find.byKey(const Key('box-hand')),
        find.byKey(const Key('board-notes')),
        find.byKey(const Key('advice-hint-label')),
        find.byKey(const Key('advice-verdict')),
      ]) {
        final r = tester.getRect(part);
        expect(
          box.top <= r.top + 0.5 && r.bottom <= box.bottom + 0.5,
          isTrue,
          reason: 'part at $r falls outside the box at $box',
        );
      }
    });

    testWidgets('it is one box, and the box says it is a suggestion', (
      tester,
    ) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          equity: 0.62,
          opponents: 2,
          tier: 'strong',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(action: 'call', reason: 'worth_price', need: 0.33),
        ),
      );
      expect(find.byKey(const Key('advice-box')), findsOneWidget);
      // Not buried in a settings page: the heading says what it is every
      // time it is on screen.
      expect(find.text('SUGGESTION'), findsOneWidget);
      // And the rest of the truth is one tap away.
      await tester.tap(find.byKey(const Key('advice-explain')));
      await tester.pumpAndSettle();
      expect(find.text('A suggestion, not a rule'), findsOneWidget);
      expect(find.textContaining('never tell you to bluff'), findsOneWidget);
      await tester.tap(find.byKey(const Key('advice-explain-close')));
      await tester.pumpAndSettle();
      expect(find.text('A suggestion, not a rule'), findsNothing);
    });

    testWidgets('the hand comes in words, and a draw says it is a draw', (
      tester,
    ) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          equity: 0.38,
          opponents: 1,
          tier: 'good',
          description: 'Ace high',
          category: 0,
          advice: Advice(action: 'call', reason: 'worth_price', need: 0.25),
        ),
        notes: const [HandNote(id: 'flush_draw', suit: 'h')],
        handLine: 'Ace high',
      );
      // The hand itself, named precisely and as the player's own.
      expect(find.text('Your hand: Ace high'), findsOneWidget);
      // And the line says why, not how often.
      expect(find.text('Worth a call'), findsOneWidget);
      expect(
        find.text('what you hold is worth what they are asking'),
        findsOneWidget,
      );
      expect(
        find.text('Four hearts — one more makes a flush.'),
        findsOneWidget,
      );
      // And no arithmetic unless it was asked for.
      expect(find.byKey(const Key('advice-numbers')), findsNothing);
      expect(find.byKey(const Key('advice-need-mark')), findsNothing);
    });

    testWidgets('a made hand is named, not rated', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          equity: 0.9,
          opponents: 1,
          tier: 'monster',
          description: 'Three of a Kind, Aces',
          category: 3,
          advice: Advice(
            action: 'raise',
            amount: 900,
            sizing: 'big',
            reason: 'ahead',
          ),
        ),
        handLine: 'Three of a kind, Aces',
      );
      // What they hold, in words they can check against their own cards.
      expect(find.text('Your hand: Three of a kind, Aces'), findsOneWidget);
      expect(find.text('Raise a lot, to 900'), findsOneWidget);
      expect(
        find.text('you are likely ahead of them right now'),
        findsOneWidget,
      );
    });

    testWidgets('before the flop the two cards are the hand', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          street: 'preflop',
          equity: 0.45,
          opponents: 2,
          tier: 'good',
          description: 'Ace-Ten offsuit',
          category: 0,
          advice: Advice(
            action: 'raise',
            amount: 300,
            sizing: 'big',
            reason: 'strong_start',
          ),
        ),
        handLine: 'Ace-Ten offsuit',
      );
      expect(find.text('Your hand: Ace-Ten offsuit'), findsOneWidget);
      expect(find.text('Raise a lot, to 300'), findsOneWidget);
    });

    testWidgets('a pocket pair is named before the flop', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          street: 'preflop',
          equity: 0.8,
          opponents: 1,
          tier: 'monster',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(
            action: 'raise',
            amount: 300,
            sizing: 'big',
            reason: 'strong_start',
          ),
        ),
        handLine: 'Pair of Aces',
      );
      expect(find.text('Your hand: Pair of Aces'), findsOneWidget);
    });

    testWidgets('the hand is named once, and only in the box', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          equity: 0.5,
          opponents: 1,
          tier: 'good',
          description: 'Pair of Twos',
          category: 1,
          advice: Advice(action: 'check', reason: 'nothing_to_bet'),
        ),
        handLine: 'Pair of Twos',
      );
      expect(find.text('Your hand: Pair of Twos'), findsOneWidget);
      // Said once: the box is the only place any of it appears.
      expect(find.byKey(const Key('box-hand')), findsOneWidget);
    });

    testWidgets('off turn the box still holds the hand and the board', (
      tester,
    ) async {
      final s = fixtureSnapshot();
      await pump(
        tester,
        s.copyWith(you: s.you.copyWith(options: null)),
        handLine: 'Pair of Twos',
        notes: const [HandNote(id: 'flush_possible', suit: 'h')],
      );
      // No turn means no line to take, but the hand and what the board
      // makes of it belong in the box all the same.
      expect(find.byKey(const Key('advice-box')), findsOneWidget);
      expect(find.text('Your hand: Pair of Twos'), findsOneWidget);
      expect(find.byKey(const Key('board-notes')), findsOneWidget);
      expect(find.byKey(const Key('advice-hint-label')), findsNothing);
    });

    testWidgets('a small raise says so', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        strength: const Strength(
          equity: 0.55,
          opponents: 2,
          tier: 'good',
          description: 'Pair of Nines',
          category: 1,
          advice: Advice(action: 'raise', amount: 450, sizing: 'small'),
        ),
      );
      expect(find.text('Raise a little, to 450'), findsOneWidget);
    });

    testWidgets('the verdict leads and the numbers explain it', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        potOdds: true,
        strength: const Strength(
          equity: 0.62,
          opponents: 2,
          tier: 'strong',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(action: 'call', need: 0.33),
        ),
      );
      expect(find.text('Worth a call'), findsOneWidget);
      expect(
        find.text('You win about 62% of the time; the call asks for 33%.'),
        findsOneWidget,
      );
      // The mark on the bar is what makes the two numbers comparable.
      expect(find.byKey(const Key('advice-need-mark')), findsOneWidget);
      // The advice replaces the bare price rather than sitting next to it.
      expect(find.byKey(const Key('pot-odds')), findsNothing);
    });

    testWidgets('a fold against odds that just clear says why', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        potOdds: true,
        strength: const Strength(
          equity: 0.32,
          opponents: 1,
          tier: 'weak',
          description: 'Four high',
          category: 0,
          advice: Advice(action: 'fold', need: 0.31),
        ),
      );
      // The picture and the verdict look at odds with each other; the
      // line that explains it is the one lesson worth teaching here.
      expect(find.byKey(const Key('advice-close')), findsOneWidget);
      expect(find.text('Better to fold this one'), findsOneWidget);
    });

    testWidgets('a plain fold needs no excuse', (tester) async {
      await pump(
        tester,
        fixtureSnapshot(),
        potOdds: true,
        strength: const Strength(
          equity: 0.12,
          opponents: 2,
          tier: 'weak',
          description: 'Seven high',
          category: 0,
          advice: Advice(action: 'fold', need: 0.33),
        ),
      );
      expect(find.byKey(const Key('advice-close')), findsNothing);
    });

    testWidgets('a raise is not measured against a call it is not making', (
      tester,
    ) async {
      await pump(
        tester,
        fixtureSnapshot(),
        potOdds: true,
        strength: const Strength(
          equity: 0.34,
          opponents: 2,
          tier: 'marginal',
          description: 'Ten-Nine suited',
          category: 0,
          // Below the price of a call, and still a raise: a steal is not
          // a call, so the price has no say and no mark on the bar.
          advice: Advice(
            action: 'raise',
            amount: 300,
            sizing: 'big',
            need: 0.4,
          ),
        ),
      );
      expect(find.text('You win about 34% of the time.'), findsOneWidget);
      expect(find.byKey(const Key('advice-need-mark')), findsNothing);
    });

    testWidgets('with nothing to call there is no price to beat', (
      tester,
    ) async {
      await pump(
        tester,
        fixtureSnapshot(),
        potOdds: true,
        strength: const Strength(
          equity: 0.4,
          opponents: 3,
          tier: 'good',
          description: 'Pair of Aces',
          category: 1,
          advice: Advice(action: 'check'),
        ),
      );
      expect(find.text('Checking costs nothing here'), findsOneWidget);
      expect(find.text('You win about 40% of the time.'), findsOneWidget);
      expect(find.byKey(const Key('advice-need-mark')), findsNothing);
    });
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
