import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/session_store.dart';
import 'package:showdown/features/admin/admin_widgets.dart';
import 'package:showdown/features/landing/landing_page.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    adminToastsEnabled = false;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => adminToastsEnabled = true);

  RestClient client(List<String> log) => RestClient(
    baseUrl: 'http://test',
    client: MockClient((req) async {
      log.add('${req.method} ${req.url.path} ${req.body}');
      if (req.url.path == '/api/tables' && req.method == 'POST') {
        expect(req.headers.containsKey('Authorization'), isFalse);
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final settings = body['settings'] as Map<String, dynamic>;
        if (settings['big_blind'] == 999999) {
          return http.Response(
            '{"error":{"code":"validation_failed","message":"nope","field":"big_blind","fields":[{"field":"big_blind","message":"server says no"}]}}',
            400,
          );
        }
        return http.Response(
          '{"id":"newid","name":"${body['name']}","state":"waiting","hand_number":0,"created_at":1,"settings":{"requires_password":false,"max_players":9,"start_money":10000,"small_blind":50,"big_blind":100,"ante":0,"turn_time":30,"disconnected_turn_time":10,"sit_out_after_missed_turns":2,"join_policy":"always","allow_spectators":true,"spectator_chat":true,"chat_enabled":true,"allow_rebuy":true,"showdown_reveal":"all","auto_start":true,"hand_delay_ms":5000},"players":[],"spectators":0,"connections":0,"join_url":"/t/newid","admin_token":"secret-admin-token"}',
          201,
        );
      }
      return http.Response(
        '{"error":{"code":"not_found","message":"no"}}',
        404,
      );
    }),
  );

  testWidgets('creating a table stores the admin key and opens the join page', (
    tester,
  ) async {
    final log = <String>[];
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    late ProviderContainer container;
    await tester.pumpWidget(
      wrapRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              container = ProviderScope.containerOf(context);
              return const LandingPage();
            },
          ),
          GoRoute(
            path: '/t/:id',
            builder: (context, state) =>
                Scaffold(child: Text('JOIN ${state.pathParameters['id']}')),
          ),
        ],
        overrides: [restClientProvider.overrideWithValue(client(log))],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('landing-create')));
    await tester.pumpAndSettle();

    // Local validation first: an empty name is rejected without a request.
    await tester.tap(find.byKey(const Key('admin-create')));
    await tester.pumpAndSettle();
    expect(log.where((l) => l.startsWith('POST /api/tables')), isEmpty);

    await tester.enterText(find.byKey(const Key('field-name')), 'Friday');
    await tester.enterText(find.byKey(const Key('field-big_blind')), '999999');
    await tester.tap(find.byKey(const Key('admin-create')));
    await tester.pumpAndSettle();
    expect(find.text('server says no'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field-big_blind')), '100');
    await tester.tap(find.byKey(const Key('admin-create')));
    await tester.pumpAndSettle();
    expect(find.text('JOIN newid'), findsOneWidget);
    expect(
      await container.read(sessionStoreProvider).loadAdminToken('newid'),
      'secret-admin-token',
    );
    final body = log.lastWhere((l) => l.startsWith('POST /api/tables'));
    expect(body, contains('"name":"Friday"'));
    expect(body, contains('"big_blind":100'));
  });
}
