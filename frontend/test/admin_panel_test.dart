import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/admin/admin_panel.dart';
import 'package:showdown/features/admin/admin_widgets.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/features/table/widgets/side_panel.dart';

import 'test_helpers.dart';

/// Transport that never delivers anything (the live view is not exercised).
class SilentTransport implements WsTransport {
  final _c = StreamController<String>();
  @override
  Future<void> connect() async {}
  @override
  Stream<String> get messages => _c.stream;
  @override
  void send(String data) {}
  @override
  Future<void> close([int code = 1000, String? reason]) => _c.close();
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

const detailJson =
    '{"id":"k7m2p9xq4w","name":"Friday","state":"waiting","hand_number":3,"created_at":1,'
    '"settings":{"requires_password":false,"max_players":9,"start_money":10000,"small_blind":50,"big_blind":100,"ante":0,'
    '"turn_time":30,"disconnected_turn_time":10,"sit_out_after_missed_turns":2,"join_policy":"always","allow_spectators":true,'
    '"spectator_chat":true,"chat_enabled":true,"allow_rebuy":true,"showdown_reveal":"all","auto_start":true,"hand_delay_ms":5000},'
    '"players":[{"id":"p1","name":"Alice","seat":0,"stack":12000,"status":"active","connected":true,"muted":false,"missed_turns":0,'
    '"buy_in_total":10000,"hands_played":3,"hands_won":2,"biggest_pot":900,"joined_at":1}],"spectators":1,"connections":2,"join_url":"/t/k7m2p9xq4w"}';

RestClient restFor(List<String> log) => RestClient(
  baseUrl: 'http://test',
  client: MockClient((req) async {
    log.add('${req.method} ${req.url.path} ${req.body}');
    if (req.headers['Authorization'] != 'Bearer adm') {
      return http.Response(
        '{"error":{"code":"unauthorized","message":"no"}}',
        401,
      );
    }
    if (req.url.path == '/api/admin/tables/k7m2p9xq4w' && req.method == 'GET') {
      return http.Response(detailJson, 200);
    }
    if (req.url.path.endsWith('/hands')) {
      return http.Response('{"hands":[]}', 200);
    }
    if (req.url.path.endsWith('/settings')) {
      final patch = jsonDecode(req.body) as Map<String, dynamic>;
      final settings =
          (jsonDecode(detailJson) as Map<String, dynamic>)['settings']
              as Map<String, dynamic>;
      settings.addAll(patch);
      return http.Response(
        jsonEncode({
          'changed': patch.keys.toList(),
          'applies_next_hand': ['big_blind'],
          'settings': settings,
        }),
        200,
      );
    }
    return http.Response('{"error":{"code":"not_found","message":"no"}}', 404);
  }),
);

void main() {
  setUp(() {
    adminToastsEnabled = false;
    SharedPreferences.setMockInitialValues({});
    TableSessionNotifier.transportFactoryOverride = (_) => SilentTransport();
    TableSessionNotifier.urlOverride = (id) => Uri.parse('ws://test/$id');
  });
  tearDown(() {
    adminToastsEnabled = true;
    TableSessionNotifier.transportFactoryOverride = null;
    TableSessionNotifier.urlOverride = null;
  });

  testWidgets('the admin panel loads the table and saves only changed fields', (
    tester,
  ) async {
    final log = <String>[];
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrap(
        const AdminPanel(tableId: 'k7m2p9xq4w', token: 'adm'),
        overrides: [restClientProvider.overrideWithValue(restFor(log))],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-start')), findsOneWidget);
    expect(find.byKey(const Key('admin-copy-key')), findsOneWidget);
    expect(find.text('applies from the next hand'), findsWidgets);
    // Nothing changed: no unsaved-changes bar, no Save button.
    expect(find.byKey(const Key('admin-unsaved')), findsNothing);
    expect(find.byKey(const Key('admin-save')), findsNothing);
    await tester.enterText(find.byKey(const Key('field-big_blind')), '200');
    await tester.enterText(find.byKey(const Key('field-small_blind')), '100');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-unsaved')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-save')));
    await tester.pumpAndSettle();
    final patch = log.lastWhere((l) => l.contains('/settings'));
    expect(patch, contains('"big_blind":200'));
    expect(patch, contains('"small_blind":100'));
    expect(patch, isNot(contains('max_players')));

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Kick'), findsOneWidget);
  });

  testWidgets('the side panel shows the Admin tab only with an admin token', (
    tester,
  ) async {
    final log = <String>[];
    Widget panel(String? token) => wrap(
      SizedBox(
        width: 400,
        height: 800,
        child: SidePanel(
          tableId: 'k7m2p9xq4w',
          tab: PanelTab.chat,
          onTabChanged: (_) {},
          chatFocusNode: FocusNode(),
          onSendChat: (_) {},
          adminToken: token,
        ),
      ),
      overrides: [restClientProvider.overrideWithValue(restFor(log))],
    );
    await tester.pumpWidget(panel(null));
    await tester.pump();
    expect(find.byKey(const Key('tab-admin')), findsNothing);
    await tester.pumpWidget(panel('adm'));
    await tester.pump();
    expect(find.byKey(const Key('tab-admin')), findsOneWidget);
  });
}
