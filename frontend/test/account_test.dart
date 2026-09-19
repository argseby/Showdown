import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/account.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/features/account/account_dialog.dart';
import 'package:showdown/shared/top_bar.dart';

import 'test_helpers.dart';

/// A profile store that lives in memory, like a browser that keeps nothing.
class _MemoryTokens extends AccountTokenStore {
  _MemoryTokens([this.token]);
  String? token;
  @override
  Future<String?> load() async => token;
  @override
  Future<void> save(String t) async => token = t;
  @override
  Future<void> clear() async => token = null;
}

/// One royal flush, one big pot, one earned milestone and one still ahead.
const _highlights = {
  'best_hands': [
    {
      'category': 8,
      'royal': true,
      'description': 'Royal flush',
      'cards': ['As', 'Ks', 'Qs', 'Js', 'Ts'],
      'net': 1200,
      'won': 2400,
      'won_bb': 48.0,
      'big_blind': 50,
      'table_name': 'Kitchen table',
      'hand_number': 12,
      'ended_at': 1788000000000,
      'shown': true,
      'counted': true,
    },
  ],
  'biggest_wins': [
    {
      'category': 1,
      'royal': false,
      'description': 'Pair of Kings',
      'cards': ['Kh', 'Kd', '9c', '7s', '2h'],
      'net': 5000,
      'won': 9000,
      'won_bb': 180.0,
      'big_blind': 50,
      'table_name': 'Kitchen table',
      'hand_number': 44,
      'ended_at': 1788600000000,
      'shown': false,
      'counted': true,
    },
  ],
  'achievements': [
    {'id': 'royal_flush', 'earned_at': 1788000000000, 'progress': 0, 'goal': 0},
    {'id': 'hands_1000', 'earned_at': 0, 'progress': 120, 'goal': 1000},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The sections a test patched, newest last.
  final patched = <String>[];

  /// A fake API: register and sign-in answer, everything else 404s.
  MockClient api({
    String handle = 'alice',
    int registerStatus = 201,
    String registerCode = 'bad_request',
  }) {
    final visibility = {
      'profile': 'private',
      'winnings': 'private',
      'best_hands': 'private',
      'achievements': 'private',
      'activity': 'private',
    };
    Map<String, dynamic> account() => {
      'id': 'u1',
      'handle': handle,
      'display_name': handle,
      'visibility': visibility,
    };
    return MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/accounts' && req.method == 'POST') {
        if (registerStatus != 201) {
          return http.Response(
            jsonEncode({
              'error': {'code': registerCode, 'message': 'no'},
            }),
            registerStatus,
          );
        }
        return http.Response(
          jsonEncode({
            'token': 'tok-new',
            'account': {
              'id': 'u1',
              'handle': handle,
              'display_name': handle,
              'visibility': {'profile': 'private'},
            },
            'recovery_code': 'ABCD-EFGH-IJKL',
          }),
          201,
        );
      }
      if (path == '/api/accounts/session' && req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (body['password'] != 'hunter22') {
          return http.Response(
            jsonEncode({
              'error': {'code': 'bad_credentials', 'message': 'no'},
            }),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'token': 'tok-in',
            'account': {'id': 'u1', 'handle': handle, 'display_name': handle},
          }),
          200,
        );
      }
      if (path == '/api/accounts/me/stats' && req.method == 'GET') {
        return http.Response(
          jsonEncode({
            'hands': 120,
            'tables': 3,
            'rounds': 2,
            'first_hand': 1788000000000,
            'last_hand': 1789000000000,
            'net': 4200,
            'net_bb': 42.0,
            'bb_per_100': 35.0,
            'counted_hands': 90,
            'counted_net': 3000,
            'counted_net_bb': 30.0,
            'biggest_pot': 2600,
            'biggest_win': 1800,
            'best_round': 2500,
            'hands_won': 31,
            'rounds_won': 1,
            'podiums': 2,
            'tournaments': 1,
            'vpip': 48,
            'showdowns': 20,
            'showdowns_won': 12,
            'won_without_showdown': 19,
            'folded': 72,
            'all_ins': 4,
            'hand_classes': [
              {'category': 8, 'royal': true, 'made': 1, 'shown': 1},
              {'category': 7, 'royal': false, 'made': 2, 'shown': 1},
              {'category': 1, 'royal': false, 'made': 40, 'shown': 9},
            ],
          }),
          200,
        );
      }
      if (path == '/api/accounts/me' && req.method == 'GET') {
        if (req.headers['Authorization'] != 'Bearer tok-kept') {
          return http.Response(
            jsonEncode({
              'error': {'code': 'unauthorized', 'message': 'no'},
            }),
            401,
          );
        }
        return http.Response(jsonEncode({'account': account()}), 200);
      }
      if (path == '/api/accounts/me' && req.method == 'PATCH') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final wanted = body['visibility'] as Map<String, dynamic>? ?? const {};
        wanted.forEach((k, v) => visibility[k] = v as String);
        patched.add(wanted.keys.join(','));
        return http.Response(jsonEncode({'account': account()}), 200);
      }
      if (path == '/api/accounts/me/highlights' && req.method == 'GET') {
        return http.Response(jsonEncode(_highlights), 200);
      }
      return http.Response('{}', 404);
    });
  }

  ProviderContainer container(MockClient client, _MemoryTokens tokens) {
    final c = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(
          RestClient(baseUrl: 'http://test', client: client),
        ),
        accountTokenStoreProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a stored token is resolved to the profile on start', () async {
    final c = container(api(), _MemoryTokens('tok-kept'));
    final account = await c.read(accountProvider.future);
    expect(account?.handle, 'alice');
    expect(c.read(accountProvider.notifier).token, 'tok-kept');
  });

  test('a token the server no longer knows is dropped', () async {
    final tokens = _MemoryTokens('tok-stale');
    final c = container(api(), tokens);
    expect(await c.read(accountProvider.future), isNull);
    expect(tokens.token, isNull, reason: 'the dead token is not kept');
  });

  test('signing up keeps the token and returns the recovery code', () async {
    final tokens = _MemoryTokens();
    final c = container(api(), tokens);
    await c.read(accountProvider.future);
    final code = await c
        .read(accountProvider.notifier)
        .register(handle: 'alice', password: 'hunter22');
    expect(code, 'ABCD-EFGH-IJKL');
    expect(tokens.token, 'tok-new');
    expect(c.read(accountProvider).value?.handle, 'alice');
  });

  test('signing out forgets the token', () async {
    final tokens = _MemoryTokens('tok-kept');
    final c = container(api(), tokens);
    await c.read(accountProvider.future);
    await c.read(accountProvider.notifier).signOut();
    expect(tokens.token, isNull);
    expect(c.read(accountProvider).value, isNull);
    expect(c.read(accountProvider.notifier).token, isNull);
  });

  testWidgets('the dialog signs in and reports a wrong password', (
    tester,
  ) async {
    final tokens = _MemoryTokens();
    await tester.pumpWidget(
      wrap(
        const AccountDialog(),
        overrides: [
          restClientProvider.overrideWithValue(
            RestClient(baseUrl: 'http://test', client: api()),
          ),
          accountTokenStoreProvider.overrideWithValue(tokens),
        ],
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('account-handle')), 'alice');
    await tester.enterText(find.byKey(const Key('account-password')), 'nope');
    await tester.tap(find.byKey(const Key('account-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Wrong name or password.'), findsOneWidget);
    expect(tokens.token, isNull);

    await tester.enterText(
      find.byKey(const Key('account-password')),
      'hunter22',
    );
    await tester.tap(find.byKey(const Key('account-submit')));
    await tester.pumpAndSettle();
    expect(tokens.token, 'tok-in');
  });

  testWidgets('signing up shows the recovery code once', (tester) async {
    final tokens = _MemoryTokens();
    await tester.pumpWidget(
      wrap(
        const AccountDialog(register: true),
        overrides: [
          restClientProvider.overrideWithValue(
            RestClient(baseUrl: 'http://test', client: api()),
          ),
          accountTokenStoreProvider.overrideWithValue(tokens),
        ],
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('account-handle')), 'alice');
    await tester.enterText(
      find.byKey(const Key('account-password')),
      'hunter22',
    );
    await tester.tap(find.byKey(const Key('account-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-recovery-code')), findsOneWidget);
    expect(find.text('ABCD-EFGH-IJKL'), findsOneWidget);
    expect(find.byKey(const Key('account-recovery-done')), findsOneWidget);
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    required bool accountsOn,
    _MemoryTokens? tokens,
  }) async {
    await tester.pumpWidget(
      wrap(
        const TopBar(title: Text('Showdown')),
        overrides: [
          restClientProvider.overrideWithValue(
            RestClient(baseUrl: 'http://test', client: api()),
          ),
          accountTokenStoreProvider.overrideWithValue(
            tokens ?? _MemoryTokens(),
          ),
          accountsEnabledProvider.overrideWith((ref) async => accountsOn),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an instance without profiles shows no person', (tester) async {
    await pumpBar(tester, accountsOn: false);
    expect(find.byKey(const Key('account-button')), findsNothing);
  });

  testWidgets('the app bar says Sign in and opens it', (tester) async {
    await pumpBar(tester, accountsOn: true);
    expect(find.byKey(const Key('account-button')), findsOneWidget);
    // What it does, not what it is: a guest should not have to guess.
    expect(find.text('Sign in'), findsWidgets);
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-handle')), findsOneWidget);
  });

  testWidgets('the app bar carries the handle once signed in', (tester) async {
    await pumpBar(tester, accountsOn: true, tokens: _MemoryTokens('tok-kept'));
    expect(find.text('@alice'), findsOneWidget);
  });

  testWidgets('the sheet shows the profile and signs out', (tester) async {
    final tokens = _MemoryTokens('tok-kept');
    await pumpBar(tester, accountsOn: true, tokens: tokens);
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();
    // The bar and the sheet both name the profile.
    expect(find.text('@alice'), findsNWidgets(2));
    expect(find.byKey(const Key('account-change-password')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-sign-out')));
    await tester.pumpAndSettle();
    expect(tokens.token, isNull);
  });

  testWidgets('the record is summarised and spelled out', (tester) async {
    await pumpBar(tester, accountsOn: true, tokens: _MemoryTokens('tok-kept'));
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();
    // The sheet carries the headline …
    expect(find.byKey(const Key('account-stats-line')), findsOneWidget);
    expect(find.textContaining('120'), findsOneWidget);

    // … and the dialog the whole record, a tab at a time. What the player
    // is up is in chips, and it is the first thing on the page.
    await tester.tap(find.byKey(const Key('account-stats')));
    await tester.pumpAndSettle();
    expect(find.text('Your statistics'), findsOneWidget);
    expect(find.text('+4,200'), findsOneWidget);
    expect(find.textContaining('over 120 hands'), findsOneWidget);
    expect(find.textContaining('90 of 120'), findsOneWidget);
    // Big blinds are a rate on the results tab, next to their explanation.
    expect(find.text('+42.0 bb'), findsNothing);
    await tester.tap(find.byKey(const Key('stats-tab-results')));
    await tester.pumpAndSettle();
    expect(find.text('+3,500'), findsOneWidget); // 4,200 over 120 hands
    expect(find.text('+42.0 bb'), findsOneWidget);
    expect(find.text('+35.0 bb'), findsOneWidget);
    expect(find.textContaining('forced bet'), findsOneWidget);
    expect(find.text('2,600'), findsOneWidget);

    // 48 of 120 hands played on.
    await tester.tap(find.byKey(const Key('stats-tab-style')));
    await tester.pumpAndSettle();
    expect(find.text('40 %'), findsOneWidget);
    expect(find.textContaining('12/20'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stats-tab-hands')));
    await tester.pumpAndSettle();
    // The class and the kept hand itself both name it.
    expect(find.text('Royal flush'), findsNWidgets(2));
    expect(find.text('Four of a kind'), findsOneWidget);
    // Made and shown are told apart.
    expect(find.textContaining('(1 shown)'), findsWidgets);
  });

  testWidgets('the kept hands and the milestones have their own pages', (
    tester,
  ) async {
    await pumpBar(tester, accountsOn: true, tokens: _MemoryTokens('tok-kept'));
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-stats')));
    await tester.pumpAndSettle();

    // The hands tab keeps the distribution and the hands themselves.
    await tester.tap(find.byKey(const Key('stats-tab-hands')));
    await tester.pumpAndSettle();
    expect(find.text('BEST HANDS'), findsOneWidget);
    expect(find.text('BIGGEST POTS'), findsOneWidget);
    expect(find.text('A♠ K♠ Q♠ J♠ 10♠'), findsOneWidget);
    expect(find.textContaining('Kitchen table'), findsWidgets);
    // A hand the table never saw says so.
    expect(find.text('mucked'), findsOneWidget);
    expect(find.text('shown'), findsOneWidget);

    // The awards tab tells earned from still open, with the way there.
    await tester.tap(find.byKey(const Key('stats-tab-awards')));
    await tester.pumpAndSettle();
    expect(find.text('Royal flush'), findsOneWidget);
    expect(find.text('Made the best hand in poker.'), findsOneWidget);
    expect(find.text('Veteran'), findsOneWidget);
    expect(find.text('STILL AHEAD'), findsOneWidget);
    expect(find.text('120 of 1000'), findsOneWidget);
  });

  testWidgets('a section is made public from the profile sheet', (
    tester,
  ) async {
    patched.clear();
    await pumpBar(tester, accountsOn: true, tokens: _MemoryTokens('tok-kept'));
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-visibility')));
    await tester.pumpAndSettle();
    // Everything starts private and the dialog says so.
    expect(find.text('Nothing is public yet.'), findsOneWidget);
    expect(find.text('Private'), findsNWidgets(5));

    // Each section is private, friends-only or public.
    expect(find.byKey(const Key('vis-winnings-friends')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('vis-winnings-public')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vis-winnings-public')));
    await tester.pumpAndSettle();
    expect(patched, ['winnings']);
    // The control follows the server's answer, not the tap: the fake API
    // stored it, so public is now the chosen one for winnings.
    expect(
      tester.widget(find.byKey(const Key('vis-winnings-public'))),
      isA<PrimaryButton>(),
    );
    expect(
      tester.widget(find.byKey(const Key('vis-profile-private'))),
      isA<PrimaryButton>(),
    );
    expect(find.text('Nothing is public yet.'), findsNothing);
  });

  testWidgets('a profile that never played says so', (tester) async {
    await pumpBar(tester, accountsOn: true, tokens: _MemoryTokens('tok-empty'));
    await tester.pumpAndSettle();
    // tok-empty is unknown to the fake API, so the profile is signed out;
    // an empty record reads as such rather than as zeros everywhere.
    expect(find.byKey(const Key('account-button')), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('a taken name is named as such', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AccountDialog(register: true),
        overrides: [
          restClientProvider.overrideWithValue(
            RestClient(
              baseUrl: 'http://test',
              client: api(registerStatus: 409, registerCode: 'handle_taken'),
            ),
          ),
          accountTokenStoreProvider.overrideWithValue(_MemoryTokens()),
        ],
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('account-handle')), 'alice');
    await tester.enterText(
      find.byKey(const Key('account-password')),
      'hunter22',
    );
    await tester.tap(find.byKey(const Key('account-submit')));
    await tester.pumpAndSettle();
    expect(find.text('That name is taken.'), findsOneWidget);
  });
}
