import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/session_store.dart';
import 'package:showdown/features/join/join_page.dart';
import 'package:showdown/features/join/name_rules.dart';

import 'test_helpers.dart';

void main() {
  test('NameRules mirror the server rules', () {
    expect(NameRules.normalize('  Alice   B '), 'Alice B');
    expect(NameRules.normalize('Jürgen.Ö_1-x'), 'Jürgen.Ö_1-x');
    expect(NameRules.normalize(''), isNull);
    expect(NameRules.normalize('   '), isNull);
    expect(NameRules.normalize('Al!ce'), isNull);
    expect(NameRules.normalize('a' * 21), isNull);
    expect(NameRules.normalize('Admin'), isNull);
  });

  const infoJson =
      '{"name":"Friday","state":"waiting","requires_password":true,"join_policy":"always",'
      '"allow_spectators":true,"seated":2,"max_players":9,"blinds":{"small_blind":50,"big_blind":100}}';

  RestClient client(Map<String, http.Response Function(http.Request)> routes) =>
      RestClient(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          final key = '${req.method} ${req.url.path}';
          final handler = routes[key];
          if (handler == null) {
            return http.Response(
              '{"error":{"code":"not_found","message":"no"}}',
              404,
            );
          }
          return handler(req);
        }),
      );

  Widget page(RestClient rest) => wrapRouter(
    initialLocation: '/t/k7m2p9xq4w',
    routes: [
      GoRoute(
        path: '/t/:tableId',
        builder: (context, state) =>
            JoinPage(tableId: state.pathParameters['tableId']!),
        routes: [
          GoRoute(
            path: 'play',
            builder: (context, state) =>
                const Scaffold(child: Text('PLAY PAGE')),
          ),
        ],
      ),
    ],
    overrides: [
      restClientProvider.overrideWithValue(rest),
      sessionStoreProvider.overrideWithValue(_MemorySessionStore()),
    ],
  );

  testWidgets('validates name and password before submitting', (tester) async {
    var joins = 0;
    final rest = client({
      'GET /api/tables/k7m2p9xq4w/info': (_) => http.Response(infoJson, 200),
      'POST /api/tables/k7m2p9xq4w/join': (_) {
        joins++;
        return http.Response(
          '{"player_token":"t","player_id":"p1","seat":2,"name":"Alice"}',
          201,
        );
      },
    });
    await tester.pumpWidget(page(rest));
    await tester.pumpAndSettle();
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('2 of 9 seats taken'), findsOneWidget);
    expect(find.byKey(const Key('join-password')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('join-submit')));

    await tester.tap(find.byKey(const Key('join-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-name-error')), findsOneWidget);
    expect(find.byKey(const Key('join-password-error')), findsOneWidget);
    expect(joins, 0);

    await tester.enterText(find.byKey(const Key('join-name')), 'Al!ce');
    await tester.enterText(find.byKey(const Key('join-password')), 'secret');
    await tester.ensureVisible(find.byKey(const Key('join-submit')));
    await tester.tap(find.byKey(const Key('join-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-name-error')), findsOneWidget);
    expect(find.byKey(const Key('join-password-error')), findsNothing);
    expect(joins, 0);

    await tester.enterText(find.byKey(const Key('join-name')), '  Alice  ');
    await tester.ensureVisible(find.byKey(const Key('join-submit')));
    await tester.tap(find.byKey(const Key('join-submit')));
    await tester.pumpAndSettle();
    expect(joins, 1);
    expect(
      find.text('PLAY PAGE'),
      findsOneWidget,
      reason: 'navigates to the table after joining',
    );
  });

  testWidgets('Enter in the name field submits', (tester) async {
    var joins = 0;
    final rest = client({
      'GET /api/tables/k7m2p9xq4w/info': (_) => http.Response(
        infoJson.replaceAll(
          '"requires_password":true',
          '"requires_password":false',
        ),
        200,
      ),
      'POST /api/tables/k7m2p9xq4w/join': (_) {
        joins++;
        return http.Response(
          '{"player_token":"t","player_id":"p1","seat":2,"name":"Alice"}',
          201,
        );
      },
    });
    await tester.pumpWidget(page(rest));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-name')), 'Alice');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(joins, 1);
    expect(find.text('PLAY PAGE'), findsOneWidget);
  });

  testWidgets('shows server errors per field', (tester) async {
    final rest = client({
      'GET /api/tables/k7m2p9xq4w/info': (_) => http.Response(infoJson, 200),
      'POST /api/tables/k7m2p9xq4w/join': (_) => http.Response(
        '{"error":{"code":"wrong_password","message":"wrong"}}',
        403,
      ),
    });
    await tester.pumpWidget(page(rest));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-name')), 'Alice');
    await tester.enterText(find.byKey(const Key('join-password')), 'nope');
    await tester.ensureVisible(find.byKey(const Key('join-submit')));
    await tester.tap(find.byKey(const Key('join-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Wrong password'), findsOneWidget);
  });

  testWidgets('unknown table shows not found', (tester) async {
    await tester.pumpWidget(page(client({})));
    await tester.pumpAndSettle();
    expect(find.text('Table not found'), findsOneWidget);
  });

  testWidgets('the join page offers the display size', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rest = client({
      'GET /api/tables/k7m2p9xq4w/info': (_) => http.Response(infoJson, 200),
    });
    await tester.pumpWidget(page(rest));
    await tester.pumpAndSettle();
    expect(find.text('Display size'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('display-size-1')));
    await tester.tap(find.byKey(const Key('display-size-1')));
    await tester.pump();
    final element = tester.element(find.byKey(const Key('display-size-1')));
    expect(ProviderScope.containerOf(element).read(uiScaleProvider), 1.25);
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
