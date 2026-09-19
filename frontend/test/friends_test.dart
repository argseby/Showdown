import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/account.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/user_socket.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/friends/friends_dialog.dart';
import 'package:showdown/features/friends/friends_playing_card.dart';
import 'package:showdown/features/friends/notifications_overlay.dart';

import 'test_helpers.dart';

/// A profile store that keeps one token, like a signed-in browser.
class _Tokens extends AccountTokenStore {
  _Tokens([this.token]);
  String? token;
  @override
  Future<String?> load() async => token;
  @override
  Future<void> save(String t) async => token = t;
  @override
  Future<void> clear() async => token = null;
}

/// A socket the test drives: frames go in, nothing goes out.
class _FakeTransport implements WsTransport {
  final _in = StreamController<String>.broadcast();
  final sent = <String>[];
  bool closed = false;

  void push(Map<String, dynamic> envelope) => _in.add(jsonEncode(envelope));

  @override
  Future<void> connect() async {}
  @override
  Stream<String> get messages => _in.stream;
  @override
  void send(String data) => sent.add(data);
  @override
  Future<void> close([int code = 1000, String? reason]) async {
    closed = true;
    await _in.close();
  }

  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every call the test made, newest last: "METHOD path".
  final calls = <String>[];

  MockClient api() => MockClient((req) async {
    final path = req.url.path;
    calls.add('${req.method} $path');
    if (path == '/api/accounts/me') {
      return http.Response(
        jsonEncode({
          'account': {
            'id': 'u1',
            'handle': 'alice',
            'display_name': 'Alice',
            'visibility': {'profile': 'private'},
          },
        }),
        200,
      );
    }
    if (path == '/api/friends' && req.method == 'GET') {
      return http.Response(
        jsonEncode({
          'friends': [
            {
              'id': 'u2',
              'handle': 'ben',
              'display_name': 'Ben',
              'since': 1788000000000,
              'relation': 'friend',
            },
          ],
          'incoming': [
            {
              'id': 'u3',
              'handle': 'cid',
              'display_name': 'Cid',
              'since': 1788600000000,
              'relation': 'pending_in',
            },
          ],
          'outgoing': <Map<String, dynamic>>[],
          'blocked': <Map<String, dynamic>>[],
          'invites': [
            {
              'id': 'i1',
              'table_id': 'tbl123',
              'table_name': 'Kitchen table',
              'from': 'ben',
              'created_at': 1788600000000,
              'expires_at': 1799600000000,
            },
          ],
        }),
        200,
      );
    }
    if (path == '/api/friends/search') {
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 'u4',
              'handle': 'dora',
              'display_name': 'Dora',
              'since': 0,
              'relation': 'none',
            },
          ],
        }),
        200,
      );
    }
    if (path == '/api/friends/playing') {
      return http.Response(
        jsonEncode({
          'tables': [
            {
              'id': 'tbl123',
              'name': 'Kitchen table',
              'state': 'running',
              'blinds': {'small_blind': 25, 'big_blind': 50},
              'seated': 3,
              'max_players': 6,
              'free_seats': 3,
              'requires_password': false,
              'join_policy': 'always',
              'allow_spectators': true,
              'tournament': false,
              'friends': [
                {
                  'handle': 'ben',
                  'display_name': 'Ben',
                  'name': 'Ben',
                  'connected': true,
                },
              ],
            },
          ],
        }),
        200,
      );
    }
    return http.Response('{}', 200);
  });

  List<Override> overrides(_FakeTransport transport) => [
    restClientProvider.overrideWithValue(
      RestClient(baseUrl: 'http://test', client: api()),
    ),
    accountTokenStoreProvider.overrideWithValue(_Tokens('tok')),
    accountsEnabledProvider.overrideWith((ref) async => true),
  ];

  setUp(() {
    calls.clear();
    UserSocketNotifier.urlOverride = Uri.parse('ws://test/ws/me');
  });

  tearDown(() {
    UserSocketNotifier.transportFactoryOverride = null;
    UserSocketNotifier.urlOverride = null;
  });

  testWidgets('the friends screen lists friends, asks and invitations', (
    tester,
  ) async {
    final transport = _FakeTransport();
    await tester.pumpWidget(
      wrap(const FriendsDialog(), overrides: overrides(transport)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ben'), findsOneWidget);

    // The requests tab carries both what is asked and what is offered.
    await tester.tap(find.byKey(const Key('friends-tab-requests')));
    await tester.pumpAndSettle();
    expect(find.text('Cid'), findsOneWidget);
    expect(find.textContaining('Kitchen table'), findsOneWidget);
    expect(find.byKey(const Key('friend-accept-cid')), findsOneWidget);

    await tester.tap(find.byKey(const Key('friend-accept-cid')));
    await tester.pumpAndSettle();
    expect(calls, contains('POST /api/friends/requests/cid/accept'));
  });

  testWidgets('somebody is found by name and asked', (tester) async {
    final transport = _FakeTransport();
    await tester.pumpWidget(
      wrap(const FriendsDialog(tab: 2), overrides: overrides(transport)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('friends-search')), 'do');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Dora'), findsOneWidget);

    await tester.tap(find.byKey(const Key('friend-add-dora')));
    await tester.pumpAndSettle();
    expect(calls, contains('POST /api/friends/requests'));
  });

  testWidgets('a friend request arrives wherever the player is', (
    tester,
  ) async {
    final transport = _FakeTransport();
    UserSocketNotifier.transportFactoryOverride = (_) => transport;
    await tester.pumpWidget(
      wrap(
        const NotificationsScope(child: Text('somewhere in the app')),
        overrides: overrides(transport),
      ),
    );
    await tester.pumpAndSettle();

    transport.push({
      'type': 'user_event',
      'payload': {
        'kind': 'friend_request',
        'handle': 'cid',
        'display_name': 'Cid',
        'at': 1788600000000,
      },
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Cid wants to be friends'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification-accept-cid')));
    await tester.pumpAndSettle();
    expect(calls, contains('POST /api/friends/requests/cid/accept'));
    // Answered and gone.
    expect(find.textContaining('wants to be friends'), findsNothing);
  });

  testWidgets('an invitation offers the way to the table', (tester) async {
    final transport = _FakeTransport();
    UserSocketNotifier.transportFactoryOverride = (_) => transport;
    await tester.pumpWidget(
      wrap(
        const NotificationsScope(child: Text('somewhere in the app')),
        overrides: overrides(transport),
      ),
    );
    await tester.pumpAndSettle();

    transport.push({
      'type': 'user_event',
      'payload': {
        'kind': 'table_invite',
        'handle': 'ben',
        'display_name': 'Ben',
        'invite_id': 'i1',
        'table_id': 'tbl123',
        'table_name': 'Kitchen table',
      },
    });
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Ben invites you to Kitchen table'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('notification-join-tbl123')), findsOneWidget);
  });

  testWidgets('the home screen says where friends are playing', (tester) async {
    final transport = _FakeTransport();
    await tester.pumpWidget(
      wrap(const FriendsPlayingCard(), overrides: overrides(transport)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('friends-playing')), findsOneWidget);
    expect(find.text('Kitchen table'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('3 of 6 seats free'), findsOneWidget);
    expect(find.byKey(const Key('friends-join-tbl123')), findsOneWidget);
  });

  testWidgets('a guest sees no friends anywhere', (tester) async {
    await tester.pumpWidget(
      wrap(
        const FriendsPlayingCard(),
        overrides: [
          restClientProvider.overrideWithValue(
            RestClient(baseUrl: 'http://test', client: api()),
          ),
          accountTokenStoreProvider.overrideWithValue(_Tokens()),
          accountsEnabledProvider.overrideWith((ref) async => true),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('friends-playing')), findsNothing);
    expect(calls, isNot(contains('GET /api/friends/playing')));
  });
}
