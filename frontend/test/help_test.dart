import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/app/l10n.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/session_store.dart';
import 'package:showdown/core/strength.dart';
import 'package:showdown/features/join/join_page.dart';
import 'package:showdown/features/table/widgets/hand_rankings_dialog.dart';
import 'package:showdown/protocol/protocol.dart';
import 'package:showdown/shared/board_notes.dart';
import 'package:showdown/shared/playing_card.dart';

import 'test_helpers.dart';

void main() {
  // The two catalogues, so a name can be checked in both languages
  // without pumping a widget for each one.
  final enL10n = lookupAppLocalizations(const Locale('en'));
  final deL10n = lookupAppLocalizations(const Locale('de'));

  group('help levels', () {
    test('a level is a reading of the three switches', () {
      expect(
        helpLevelOf(
          line: HandLinePlacement.off,
          highlight: false,
          notes: false,
          potOdds: false,
          advice: false,
        ),
        HelpLevel.none,
      );
      expect(
        helpLevelOf(
          line: HandLinePlacement.bottom,
          highlight: false,
          notes: false,
          potOdds: false,
          advice: false,
        ),
        HelpLevel.hand,
      );
      expect(
        helpLevelOf(
          line: HandLinePlacement.board,
          highlight: true,
          notes: true,
          potOdds: false,
          advice: false,
        ),
        HelpLevel.cards,
      );
      expect(
        helpLevelOf(
          line: HandLinePlacement.bottom,
          highlight: true,
          notes: true,
          potOdds: true,
          advice: true,
        ),
        HelpLevel.full,
      );
      // A mix no level stands for is a mix, not a level.
      expect(
        helpLevelOf(
          line: HandLinePlacement.off,
          highlight: false,
          notes: false,
          potOdds: true,
          advice: true,
        ),
        HelpLevel.custom,
      );
    });

    testWidgets('picking a level writes the switches it stands for', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef ref;
      await tester.pumpWidget(
        wrap(
          Consumer(
            builder: (context, r, _) {
              ref = r;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      HelpLevel current() => helpLevelOf(
        line: ref.read(handLineProvider),
        highlight: ref.read(handHighlightProvider),
        notes: ref.read(boardNotesProvider),
        potOdds: ref.read(potOddsProvider),
        advice: ref.read(adviceProvider),
      );

      // Out of the box the table names the hand and stops there.
      expect(current(), HelpLevel.hand);

      applyHelpLevel(ref, HelpLevel.full);
      expect(current(), HelpLevel.full);
      expect(ref.read(adviceProvider), isTrue);
      // The percentages are nobody's level: the advice speaks in words.
      expect(ref.read(potOddsProvider), isFalse);

      // Asking for them keeps the answer the player gave.
      ref.read(potOddsProvider.notifier).set(true);
      expect(current(), HelpLevel.full);
      applyHelpLevel(ref, HelpLevel.cards);
      expect(current(), HelpLevel.cards);
      expect(ref.read(potOddsProvider), isTrue);
      // Except where the answer is "tell me nothing".
      applyHelpLevel(ref, HelpLevel.none);
      expect(ref.read(potOddsProvider), isFalse);
      applyHelpLevel(ref, HelpLevel.full);

      applyHelpLevel(ref, HelpLevel.none);
      expect(current(), HelpLevel.none);
      expect(ref.read(handLineProvider), HandLinePlacement.off);
      expect(ref.read(handHighlightProvider), isFalse);

      // Coming back from none, the line returns below the table.
      applyHelpLevel(ref, HelpLevel.hand);
      expect(ref.read(handLineProvider), HandLinePlacement.bottom);
      expect(current(), HelpLevel.hand);

      // The placement a player chose survives a level change.
      ref.read(handLineProvider.notifier).set(HandLinePlacement.board);
      applyHelpLevel(ref, HelpLevel.cards);
      expect(ref.read(handLineProvider), HandLinePlacement.board);

      // Custom is a reading, so it sets nothing.
      applyHelpLevel(ref, HelpLevel.custom);
      expect(current(), HelpLevel.cards);
    });

    testWidgets('a server that refuses advice keeps the rest of the help', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef ref;
      await tester.pumpWidget(
        wrap(
          Consumer(
            builder: (context, r, _) {
              ref = r;
              return const SizedBox.shrink();
            },
          ),
          overrides: [playerAdviceEnabledProvider.overrideWith((ref) => false)],
        ),
      );
      await tester.pumpAndSettle();
      applyHelpLevel(ref, HelpLevel.full);
      // The recommendation is refused, and only the recommendation: the
      // player's own cards are read back to them on any instance.
      expect(ref.read(adviceProvider), isTrue);
      expect(ref.read(shownAdviceProvider), isFalse);
      // The percentages are the advice's own working, so they go with it:
      // switching the advice off must not leave the bare sums behind.
      expect(ref.read(shownPotOddsProvider), isFalse);
      expect(ref.read(handHighlightProvider), isTrue);
      expect(ref.read(handLineProvider), isNot(HandLinePlacement.off));
    });
  });

  group('naming a hand', () {
    test('every hand reads in the player\'s own language', () {
      // The server sends the category and the ranks that name the hand;
      // the words are the client's, which is the whole point.
      const cases = [
        (1, ['K'], 'Pair of Kings', 'Paar Königen'),
        (
          2,
          ['K', '9'],
          'Two pair, Kings and Nines',
          'Zwei Paare, Königen und Neunen',
        ),
        (3, ['7'], 'Three of a kind, Sevens', 'Drilling Siebenen'),
        (4, ['T'], 'Straight, Ten high', 'Straße bis Zehn'),
        (5, ['A'], 'Flush, Ace high', 'Flush, Ass hoch'),
        (
          6,
          ['J', '8'],
          'Full house, Jacks over Eights',
          'Full House, Buben über Achten',
        ),
        (7, ['Q'], 'Four of a kind, Queens', 'Vierling Damen'),
        (0, ['A'], 'Ace high', 'Ass hoch'),
      ];
      for (final (category, ranks, en, de) in cases) {
        expect(
          handName(enL10n, category: category, ranks: ranks),
          en,
          reason: 'category $category in English',
        );
        expect(
          handName(deL10n, category: category, ranks: ranks),
          de,
          reason: 'category $category in German',
        );
      }
      // Before the flop the two cards are the hand.
      expect(
        handName(
          enL10n,
          category: 0,
          ranks: ['A', 'K'],
          preflop: true,
          suited: true,
        ),
        'Ace-King suited',
      );
      expect(
        handName(deL10n, category: 1, ranks: ['A'], preflop: true),
        'Paar Assen',
      );
    });
  });

  group('reading the board', () {
    testWidgets('each note becomes a sentence, in the reader\'s language', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const BoardNotes(
            notes: [
              HandNote(id: 'flush_draw', suit: 'h'),
              HandNote(id: 'board_paired', rank: '7'),
              HandNote(id: 'overcard', rank: 'K'),
              HandNote(id: 'scary_for_everyone'),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('Four hearts — one more makes a flush.'),
        findsOneWidget,
      );
      expect(
        find.text('A pair of Sevens on the board — a full house is in reach.'),
        findsOneWidget,
      );
      // One card of a rank, not the plural, and no article in front of
      // it: German gives every rank its own.
      expect(
        find.text('King on the board: anyone holding one beats your pair.'),
        findsOneWidget,
      );
      // The even-handed one: the danger is named for both sides, so the
      // reader does not learn only to fold.
      expect(
        find.textContaining('for them as much as for you'),
        findsOneWidget,
      );
    });

    testWidgets('a note this client does not know is left unsaid', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const BoardNotes(
            notes: [
              HandNote(id: 'something_a_newer_server_knows'),
              HandNote(id: 'gutshot'),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('something_a_newer'), findsNothing);
      expect(find.textContaining('middle'), findsOneWidget);
    });

    testWidgets('German reads as German', (tester) async {
      await tester.pumpWidget(
        wrap(
          const BoardNotes(
            notes: [HandNote(id: 'flush_possible', suit: 'd')],
          ),
          locale: const Locale('de'),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Drei Karo liegen aus'), findsOneWidget);
    });
  });

  group('asking for advice', () {
    test('one ask per spot, and a new ask when the spot changes', () {
      final snap = fixtureSnapshot();
      final spot = StrengthNotifier.spotOf(snap);
      expect(spot, isNotNull);
      // The same turn asked twice is the same spot.
      expect(StrengthNotifier.spotOf(fixtureSnapshot()), spot);
      // A different price is a different question.
      final raised = snap.copyWith(
        you: snap.you.copyWith(options: snap.you.options!.copyWith(call: 900)),
      );
      expect(StrengthNotifier.spotOf(raised), isNot(spot));
      // So is a later street.
      final turn = snap.copyWith(hand: snap.hand!.copyWith(street: 'turn'));
      expect(StrengthNotifier.spotOf(turn), isNot(spot));
      // Off turn there is nothing to ask.
      expect(
        StrengthNotifier.spotOf(
          snap.copyWith(you: snap.you.copyWith(options: null)),
        ),
        isNull,
      );
    });
  });

  group('hand rankings', () {
    Future<void> open(
      WidgetTester tester, {
      int? category,
      bool royal = false,
      String? description,
    }) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => PrimaryButton(
              onPressed: () => showHandRankingsDialog(
                context,
                category: category,
                royal: royal,
                description: description,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('every hand is listed, best first, with the viewer\'s marked', (
      tester,
    ) async {
      // Two pair, as the server numbers it.
      await open(tester, category: 2, description: 'Two Pair, Kings and Nines');
      expect(find.text('Royal flush'), findsOneWidget);
      expect(find.text('High card'), findsOneWidget);
      expect(find.byKey(const Key('rankings-mine')), findsOneWidget);
      expect(find.text('You have Two Pair, Kings and Nines'), findsOneWidget);
      // Ten rows of five examples each.
      expect(find.byType(PlayingCardWidget), findsNWidgets(50));
    });

    testWidgets('a royal flush marks the royal row, not the straight flush', (
      tester,
    ) async {
      await open(tester, category: 8, royal: true);
      final mine = find.byKey(const Key('rankings-mine'));
      expect(mine, findsOneWidget);
      expect(
        find.descendant(of: mine, matching: find.text('Royal flush')),
        findsOneWidget,
      );
    });

    testWidgets('a narrow phone fits the names and the examples', (
      tester,
    ) async {
      // A row is a name and five cards; on the narrowest phone in the wild
      // that is the layout most likely to overflow, and an overflow fails
      // the test loudly.
      tester.view.physicalSize = const Size(320, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, category: 5, description: 'Flush, Ace High');
      expect(find.text('Flush'), findsOneWidget);
      expect(find.byKey(const Key('rankings-mine')), findsOneWidget);
    });

    testWidgets('with no hand to mark, nothing is', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('rankings-mine')), findsNothing);
    });
  });

  group('the join form asks', () {
    const infoJson =
        '{"name":"Friday","state":"waiting","requires_password":false,'
        '"join_policy":"always","allow_spectators":true,"seated":2,'
        '"max_players":9,"blinds":{"small_blind":50,"big_blind":100}}';

    RestClient client({bool playerHelp = true}) => RestClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        if (req.url.path == '/api/tables/k7m2p9xq4w/info') {
          return http.Response(infoJson, 200);
        }
        if (req.url.path == '/api/config') {
          return http.Response(
            jsonEncode({'accounts': false, 'player_advice': playerHelp}),
            200,
          );
        }
        return http.Response('{"error":{"code":"not_found"}}', 404);
      }),
    );

    Widget page(RestClient rest) => wrapRouter(
      initialLocation: '/t/k7m2p9xq4w',
      routes: [
        GoRoute(
          path: '/t/:tableId',
          builder: (context, state) =>
              JoinPage(tableId: state.pathParameters['tableId']!),
        ),
      ],
      overrides: [
        restClientProvider.overrideWithValue(rest),
        sessionStoreProvider.overrideWithValue(_MemorySessionStore()),
      ],
    );

    testWidgets('a first-time player is asked, and the answer sticks', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(page(client()));
      await tester.pumpAndSettle();
      // Open on a first visit: the question is asked, not offered.
      expect(find.text('How much help do you want?'), findsOneWidget);
      final full = find.byKey(const Key('help-level-full'));
      await tester.ensureVisible(full);
      await tester.tap(full);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(JoinPage)),
      );
      expect(container.read(adviceProvider), isTrue);
      expect(container.read(handHighlightProvider), isTrue);
      expect(container.read(helpAskedProvider), isTrue);
      // Answered, it folds away into a line naming the answer.
      expect(find.text('How much help do you want?'), findsNothing);
      expect(find.textContaining('New to poker'), findsOneWidget);
    });

    testWidgets('a player who has answered before is not asked again', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'flutter.pref:help_asked': true});
      await tester.pumpWidget(page(client()));
      await tester.pumpAndSettle();
      expect(find.text('How much help do you want?'), findsNothing);
      expect(find.byKey(const Key('join-help-toggle')), findsOneWidget);
    });

    testWidgets('the question is asked even where advice is refused', (
      tester,
    ) async {
      // The levels below "new to poker" are the player's own cards read
      // back to them; an instance that refuses recommendations has no say
      // in those, so the question still belongs on the form.
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(page(client(playerHelp: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('join-help-toggle')), findsOneWidget);
    });
  });
}

class _MemorySessionStore extends SessionStore {
  final _map = <String, StoredSession>{};
  @override
  Future<StoredSession?> load(String tableId) async => _map[tableId];
  @override
  Future<void> save(String tableId, StoredSession session) async =>
      _map[tableId] = session;
  @override
  Future<void> clear(String tableId) async => _map.remove(tableId);
}
