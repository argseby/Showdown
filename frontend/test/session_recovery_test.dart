import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/session_store.dart';
import 'package:showdown/features/table/play_page.dart';

import 'test_helpers.dart';

const tableId = 'k7m2p9xq4w';

Future<void> pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    wrapRouter(
      initialLocation: '/t/$tableId/play',
      routes: [
        GoRoute(
          path: '/t/:tableId',
          builder: (context, state) => const Scaffold(child: Text('JOIN PAGE')),
          routes: [
            GoRoute(
              path: 'play',
              builder: (context, state) =>
                  PlayPage(tableId: state.pathParameters['tableId']!),
            ),
          ],
        ),
      ],
      overrides: [
        restClientProvider.overrideWithValue(
          RestClient(
            baseUrl: 'http://test',
            client: MockClient(
              (req) async => http.Response(
                '{"error":{"code":"not_found","message":"no"}}',
                404,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('a stored session that cannot be read', () {
    testWidgets('sends the player back to the join page', (tester) async {
      // A session written by an older build, a half-written value, anything
      // whose shape no longer parses. The player must land somewhere they
      // can act — not on a table they are not connected to.
      SharedPreferences.setMockInitialValues({
        'flutter.session:$tableId': jsonEncode({'name': 'chubby'}), // no token
      });
      await pump(tester);
      expect(find.text('JOIN PAGE'), findsOneWidget);
    });

    testWidgets('does not leave the table open as a spectator', (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.session:$tableId': 'not json at all',
      });
      await pump(tester);
      expect(find.text('JOIN PAGE'), findsOneWidget);
    });
  });

  group('SessionStore.load', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('returns null for a value that is not an object', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.session:$tableId': '["not", "an", "object"]',
      });
      expect(await SessionStore().load(tableId), isNull);
    });

    test('returns null when the token is missing', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.session:$tableId': jsonEncode({'role': 'player'}),
      });
      expect(await SessionStore().load(tableId), isNull);
    });

    test('returns null when the role is missing', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.session:$tableId': jsonEncode({'token': 'tok'}),
      });
      expect(await SessionStore().load(tableId), isNull);
    });

    test('returns null when the value is not a string at all', () async {
      // Whatever a future or foreign writer leaves under the key: reading it
      // must not throw, or the provider errors and the play page strands.
      SharedPreferences.setMockInitialValues({'flutter.session:$tableId': 42});
      expect(await SessionStore().load(tableId), isNull);
      expect(await SessionStore().loadAdminToken(tableId), isNull);
    });

    test('still reads a well-formed session', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.session:$tableId': jsonEncode({
          'token': 'tok',
          'role': 'player',
          'name': 'chubby',
          'player_id': 'p1',
        }),
      });
      final s = await SessionStore().load(tableId);
      expect(s?.token, 'tok');
      expect(s?.role, 'player');
      expect(s?.playerId, 'p1');
    });
  });
}
