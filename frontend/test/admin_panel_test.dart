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
import 'package:showdown/features/admin/table_rules_pending.dart';
import 'package:showdown/features/admin/table_rules_section.dart';
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

RestClient restFor(List<String> log, {String detail = detailJson}) {
  // The fake keeps what it was told, like the real one: a second change
  // must not undo the first.
  final table = jsonDecode(detail) as Map<String, dynamic>;
  final settings = table['settings'] as Map<String, dynamic>;
  return RestClient(
    baseUrl: 'http://test',
    client: MockClient((req) async {
      log.add('${req.method} ${req.url.path} ${req.body}');
      if (req.headers['Authorization'] != 'Bearer adm') {
        return http.Response(
          '{"error":{"code":"unauthorized","message":"no"}}',
          401,
        );
      }
      if (req.url.path == '/api/admin/tables/k7m2p9xq4w' &&
          req.method == 'GET') {
        return http.Response(jsonEncode(table), 200);
      }
      if (req.url.path.endsWith('/hands')) {
        return http.Response('{"hands":[]}', 200);
      }
      if (req.url.path.endsWith('/settings')) {
        final patch = jsonDecode(req.body) as Map<String, dynamic>;
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
      return http.Response(
        '{"error":{"code":"not_found","message":"no"}}',
        404,
      );
    }),
  );
}

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

  testWidgets('every rule settles on its own, with no save for the lot', (
    tester,
  ) async {
    final log = <String>[];
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    // The table rules are a section of the Settings tab.
    await tester.pumpWidget(
      wrap(
        const SingleChildScrollView(
          child: TableRulesSection(tableId: 'k7m2p9xq4w', token: 'adm'),
        ),
        overrides: [restClientProvider.overrideWithValue(restFor(log))],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('applies from the next hand'), findsWidgets);
    // There is no save button for the lot, and nothing to apply yet.
    expect(find.byKey(const Key('admin-unsaved')), findsNothing);
    expect(find.byKey(const Key('admin-save')), findsNothing);
    expect(find.byKey(const Key('apply-big_blind')), findsNothing);

    // A typed value waits for its tick, and takes nothing else with it.
    await tester.enterText(find.byKey(const Key('field-big_blind')), '200');
    await tester.enterText(find.byKey(const Key('field-small_blind')), '100');
    await tester.pumpAndSettle();
    expect(log.where((l) => l.contains('/settings')), isEmpty);
    await tester.tap(find.byKey(const Key('apply-big_blind')));
    await tester.pumpAndSettle();
    var patch = log.lastWhere((l) => l.contains('/settings'));
    expect(patch, contains('"big_blind":200'));
    expect(patch, isNot(contains('small_blind')));
    expect(patch, isNot(contains('max_players')));

    // The cross puts a typed value back and sends nothing.
    final before = log.length;
    await tester.tap(find.byKey(const Key('reset-small_blind')));
    await tester.pumpAndSettle();
    expect(log.length, before);
    expect(find.byKey(const Key('apply-small_blind')), findsNothing);
    // And the box itself shows the old value again, not the typing it
    // replaced.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('field-small_blind')))
          .controller
          ?.text,
      '50', // what the server says, not the 100 that was typed
    );

    // A switch means it straight away.
    await tester.ensureVisible(find.byKey(const Key('field-allow_rebuy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('field-allow_rebuy')));
    await tester.pumpAndSettle();
    patch = log.lastWhere((l) => l.contains('/settings'));
    expect(patch, contains('"allow_rebuy"'));
    expect(patch, isNot(contains('big_blind')));

    // The table type is its own control, not one switch among many.
    expect(find.byKey(const Key('table-type-cash')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('table-type-tournament')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('table-type-tournament')));
    await tester.pumpAndSettle();
    // A tournament is a one-way door once a hand is dealt, so it asks.
    expect(find.text('Make this a tournament?'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Tournament'));
    await tester.pumpAndSettle();
    patch = log.lastWhere((l) => l.contains('/settings'));
    expect(patch, contains('"tournament":true'));

    // The Host tab keeps the controls, the key and the players.
    await tester.pumpWidget(
      wrap(
        const AdminPanel(tableId: 'k7m2p9xq4w', token: 'adm'),
        overrides: [restClientProvider.overrideWithValue(restFor(log))],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-start')), findsOneWidget);
    expect(find.byKey(const Key('admin-copy-key')), findsOneWidget);
    expect(find.byKey(const Key('field-big_blind')), findsNothing);
    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Kick'), findsOneWidget);
  });

  testWidgets('the title row settles or drops everything at once', (
    tester,
  ) async {
    final log = <String>[];
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            TableRulesPendingActions(),
            Expanded(
              child: SingleChildScrollView(
                child: TableRulesSection(tableId: 'k7m2p9xq4w', token: 'adm'),
              ),
            ),
          ],
        ),
        overrides: [restClientProvider.overrideWithValue(restFor(log))],
      ),
    );
    await tester.pumpAndSettle();
    // Nothing typed: the title row offers nothing.
    expect(find.byKey(const Key('rules-apply-all')), findsNothing);

    await tester.enterText(find.byKey(const Key('field-big_blind')), '200');
    await tester.enterText(find.byKey(const Key('field-ante')), '5');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rules-apply-all')), findsOneWidget);
    expect(find.text('2'), findsWidgets); // two fields waiting

    await tester.tap(find.byKey(const Key('rules-apply-all')));
    await tester.pumpAndSettle();
    final sent = log.where((l) => l.contains('/settings')).toList();
    expect(sent.length, 2);
    expect(sent.join(), contains('"big_blind":200'));
    expect(sent.join(), contains('"ante":5'));
    // Everything settled, so the title row is empty again.
    expect(find.byKey(const Key('rules-apply-all')), findsNothing);

    // And the cross drops the lot without sending anything.
    await tester.enterText(find.byKey(const Key('field-turn_time')), '45');
    await tester.pumpAndSettle();
    final before = log.length;
    await tester.tap(find.byKey(const Key('rules-discard-all')));
    await tester.pumpAndSettle();
    expect(log.length, before);
    expect(find.byKey(const Key('rules-discard-all')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('field-turn_time')))
          .controller
          ?.text,
      '30',
    );
  });

  testWidgets('a tournament has no chips button on the players page', (
    tester,
  ) async {
    final log = <String>[];
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrap(
        const AdminPanel(tableId: 'k7m2p9xq4w', token: 'adm'),
        overrides: [
          restClientProvider.overrideWithValue(
            restFor(
              log,
              detail: detailJson.replaceFirst(
                '"auto_start":true',
                '"auto_start":true,"tournament":true',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();
    expect(find.text('Kick'), findsOneWidget);
    expect(find.text('Chips'), findsNothing);
  });

  testWidgets('the settings menu shows the host pages only with a token', (
    tester,
  ) async {
    final log = <String>[];
    Widget panel(String? token) => wrap(
      SizedBox(
        width: 400,
        height: 800,
        child: SidePanel(
          tableId: 'k7m2p9xq4w',
          tab: PanelTab.settings,
          onTabChanged: (_) {},
          chatFocusNode: FocusNode(),
          onSendChat: (_) {},
          settings: (_) => const SizedBox.shrink(),
          adminToken: token,
        ),
      ),
      overrides: [restClientProvider.overrideWithValue(restFor(log))],
    );
    await tester.pumpWidget(panel(null));
    await tester.pump();
    expect(find.byKey(const Key('settings-host-rules')), findsNothing);
    await tester.pumpWidget(panel('adm'));
    await tester.pump();
    expect(find.byKey(const Key('settings-host-rules')), findsOneWidget);
    // A host page opens below the tabs, with a way back.
    await tester.tap(find.byKey(const Key('settings-host-players')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-back')), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.byKey(const Key('admin-start')), findsNothing);
  });
}
