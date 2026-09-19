import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/app/preferences.dart';
import 'package:showdown/core/gamepad/gamepad.dart';
import 'package:showdown/core/gamepad/pad_section.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/session_store.dart';
import 'package:showdown/core/voice/network_check.dart';
import 'package:showdown/core/voice/voice_controller.dart';
import 'package:showdown/core/voice/voice_engine.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/table/play_page.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/features/table/widgets/side_panel.dart';
import 'package:showdown/features/table/widgets/table_rules_dialog.dart';
import 'package:showdown/shared/playing_card.dart';

import 'test_helpers.dart';

/// A transport that answers hello with the snapshot fixture as welcome and
/// records what the client sends.
class ScriptedTransport implements WsTransport {
  final controller = StreamController<String>();
  final sent = <Map<String, dynamic>>[];

  /// The welcome flags the viewer as the table's host.
  bool admin = false;

  @override
  Future<void> connect() async {}

  @override
  Stream<String> get messages => controller.stream;

  @override
  void send(String data) {
    final env = jsonDecode(data) as Map<String, dynamic>;
    sent.add(env);
    if (env['type'] == 'hello') {
      final snap = jsonDecode(
        File('../docs/protocol/fixtures/snapshot.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final payload = snap['payload'] as Map<String, dynamic>;
      if (admin) (payload['you'] as Map<String, dynamic>)['is_admin'] = true;
      controller.add(
        jsonEncode({
          'type': 'welcome',
          'payload': {
            'you': {'role': 'player', 'player_id': 'p1', 'seat': 0},
            'snapshot': payload,
          },
        }),
      );
    } else if (env['id'] != null) {
      controller.add(
        jsonEncode({
          'type': 'ack',
          'payload': {'id': env['id']},
        }),
      );
    }
  }

  @override
  Future<void> close([int code = 1000, String? reason]) async {
    await controller.close();
  }

  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

/// The stored admin key of the test table.
class _AdminToken extends AdminTokenNotifier {
  _AdminToken() : super('k7m2p9xq4w');

  @override
  Future<String?> build() async => 'adm';
}

/// A connected controller whose presses the test feeds in.
class _FakePad extends GamepadNotifier {
  final ctrl = StreamController<PadButton>.broadcast(sync: true);

  @override
  bool build() => false;

  @override
  void start() {}

  /// The first button press makes the browser report the pad.
  void connect() => state = true;

  @override
  Stream<PadButton> get presses => ctrl.stream;

  void press(PadButton b) => ctrl.add(b);
}

/// Controller hints switched on.
class _HintsOn extends PadHintsNotifier {
  @override
  bool build() => true;
}

/// Fresh from the join page.
class _JustJoined extends JustJoinedNotifier {
  @override
  String? build() => 'k7m2p9xq4w';
}

/// The snapshot fixture with Bob's voice state set.
Map<String, dynamic> _bobVoice(String voice) {
  final snap = jsonDecode(
    File('../docs/protocol/fixtures/snapshot.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final payload = snap['payload'] as Map<String, dynamic>;
  (payload['you'] as Map<String, dynamic>)['is_admin'] = true;
  for (final sv in payload['seats'] as List<dynamic>) {
    final p = (sv as Map<String, dynamic>)['player'] as Map<String, dynamic>?;
    if (p != null && p['id'] == 'p4') p['voice'] = voice;
  }
  return payload;
}

class _MemorySessionStore extends SessionStore {
  _MemorySessionStore(this.session);
  final StoredSession? session;

  /// Set when the seat was given up; closing the standings must not.
  bool cleared = false;
  @override
  Future<StoredSession?> load(String tableId) async => session;
  @override
  Future<void> save(String tableId, StoredSession session) async {}
  @override
  Future<void> clear(String tableId) async {
    cleared = true;
  }

  @override
  Future<String?> loadAdminToken(String tableId) async => null;
  @override
  Future<void> saveAdminToken(String tableId, String token) async {}
  @override
  Future<void> clearAdminToken(String tableId) async {}
}

void main() {
  late ScriptedTransport transport;

  setUp(() {
    transport = ScriptedTransport();
    TableSessionNotifier.transportFactoryOverride = (_) => transport;
    TableSessionNotifier.urlOverride = (id) =>
        Uri.parse('ws://test/ws/table/$id');
  });

  tearDown(() {
    TableSessionNotifier.transportFactoryOverride = null;
    TableSessionNotifier.urlOverride = null;
  });

  late _MemorySessionStore store;

  Future<void> pumpPlay(
    WidgetTester tester, {
    List<Override> extra = const [],
  }) async {
    store = _MemorySessionStore(
      const StoredSession(
        token: 'tok',
        role: 'player',
        name: 'Alice',
        playerId: 'p1',
      ),
    );
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrapRouter(
        initialLocation: '/t/k7m2p9xq4w/play',
        routes: [
          GoRoute(
            path: '/t/:tableId',
            builder: (context, state) =>
                const Scaffold(child: Text('JOIN PAGE')),
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
          sessionStoreProvider.overrideWithValue(store),
          ...extra,
          // The REST API answers nothing: the table needs only the socket.
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
    // Session and admin-key load, post-frame connect, hello/welcome round trip.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  List<String> sentTypes() =>
      transport.sent.map((e) => e['type'] as String).toList();

  testWidgets('renders the table after the welcome and dispatches shortcuts', (
    tester,
  ) async {
    await pumpPlay(tester);
    expect(sentTypes().first, 'hello');
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Call 300'), findsOneWidget);

    // R opens the raise control without focusing the amount field; N does.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(find.byKey(const Key('raise-control')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pump();
    // While the amount input has focus letters are not shortcuts, Escape leaves it.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(sentTypes().where((t) => t == 'action'), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4); // pot preset -> 1,200
    await tester.pump();
    expect(find.text('Raise to 1,200'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final action = transport.sent.lastWhere((e) => e['type'] == 'action');
    expect(action['payload'], {'kind': 'raise', 'amount': 1200});

    // C calls, F folds (buttons are still enabled: the scripted server never changes the snapshot).
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump();
    expect(transport.sent.last['payload'], {'kind': 'call'});
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(transport.sent.last['payload'], {'kind': 'fold'});

    // T focuses the chat; typing there must not trigger shortcuts; Escape returns.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    final before = transport.sent.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(transport.sent.length, before);
    await tester.enterText(find.byKey(const Key('chat-input')), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(transport.sent.last['payload'], {'text': 'hello'});
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .focusNode!
          .hasFocus,
      isFalse,
    );

    // ? opens the shortcuts overlay.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.slash, character: '?');
    await tester.pump();
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
  });

  testWidgets('the settings tab holds the preferences and the leave actions', (
    tester,
  ) async {
    await pumpPlay(tester);
    // The bar keeps invite, microphone and the panel toggle; no menu.
    expect(find.byKey(const Key('panel-toggle')), findsOneWidget);
    expect(find.byKey(const Key('table-menu')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('tab-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pump(const Duration(milliseconds: 600));
    // The settings tab is a menu of pages; a page replaces the tab strip
    // with a back button.
    expect(find.byKey(const Key('settings-voice')), findsOneWidget);
    expect(find.byKey(const Key('settings-preferences')), findsOneWidget);
    expect(find.byKey(const Key('settings-table')), findsOneWidget);
    // Not the host: no host pages.
    expect(find.byKey(const Key('settings-host-rules')), findsNothing);
    await tester.tap(find.byKey(const Key('settings-voice')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('drawer-voice')), findsOneWidget);
    expect(find.byKey(const Key('tab-settings')), findsNothing);
    await tester.tap(find.byKey(const Key('settings-back')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('tab-settings')), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-preferences')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('drawer-sound')), findsOneWidget);
    expect(find.byKey(const Key('drawer-chip-stacks')), findsOneWidget);
    expect(find.byKey(const Key('drawer-chips')), findsOneWidget);
    expect(find.byKey(const Key('drawer-hats')), findsOneWidget);
    expect(find.byKey(const Key('drawer-heat')), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-back')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('settings-table')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('menu-leave')), findsOneWidget);
    expect(find.byKey(const Key('menu-other-table')), findsOneWidget);
    // A seated player is not offered "take a seat".
    expect(find.byKey(const Key('menu-take-seat')), findsNothing);
  });

  testWidgets('the settings tab changes the hat and sends the pick', (
    tester,
  ) async {
    await pumpPlay(tester);
    // Bob wears a cowboy hat in the fixture.
    expect(find.byKey(const ValueKey('hat-worn-cowboy')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('tab-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('settings-table')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('drawer-look')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('drawer-look')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('look-tab-hat')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('hat-option-pirate')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('look-done')));
    await tester.pump(const Duration(milliseconds: 600));
    final hat = transport.sent.lastWhere((e) => e['type'] == 'hat');
    expect(hat['payload'], {'hat': 'pirate'});
    // The avatar was not touched: no avatar message.
    expect(transport.sent.where((e) => e['type'] == 'avatar'), isEmpty);
  });

  testWidgets('the pencil draws a stroke, shows others and erases', (
    tester,
  ) async {
    await pumpPlay(tester);
    // Without a tool the layer ignores pointers: no surface to drag on.
    expect(find.byKey(const Key('drawing-surface')), findsNothing);
    await tester.tap(find.byKey(const Key('draw-pen')));
    await tester.pump();
    expect(find.byKey(const Key('draw-eraser')), findsOneWidget);
    final surface = find.byKey(const Key('drawing-surface'));
    expect(surface, findsOneWidget);
    final box = tester.getRect(surface);
    await tester.timedDrag(
      surface,
      const Offset(80, 40),
      const Duration(milliseconds: 200),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final draw = transport.sent.lastWhere((e) => e['type'] == 'draw');
    final pts = (draw['payload'] as Map)['points'] as List<dynamic>;
    expect(pts.length, greaterThanOrEqualTo(4));
    expect(pts.length.isEven, isTrue);
    for (final v in pts) {
      expect(v as num, inInclusiveRange(0, 1));
      // Three decimals: the message stays far under the server's cap.
      expect(((v * 1000).round() / 1000 - v).abs(), lessThan(1e-9));
    }
    expect(pts.length, lessThanOrEqualTo(400));
    expect(jsonEncode(draw).length, lessThan(6000));
    // A stroke from Bob arrives; the eraser drags over it and asks the
    // server to remove it.
    transport.controller.add(
      jsonEncode({
        'type': 'drawing',
        'payload': {
          'id': 9,
          'player_id': 'p4',
          'seat': 4,
          'name': 'Bob',
          'avatar': 0,
          'points': [0.5, 0.5, 0.6, 0.5],
          'ts': 1,
        },
      }),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('draw-eraser')));
    await tester.pump();
    final at = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final gesture = await tester.startGesture(at);
    await gesture.moveBy(const Offset(20, 0));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    final erase = transport.sent.lastWhere((e) => e['type'] == 'draw_erase');
    expect((erase['payload'] as Map)['ids'], [9]);
    // Clear all goes out as one message.
    await tester.tap(find.byKey(const Key('draw-clear-all')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(transport.sent.last['type'], 'draw_clear');
    expect(transport.sent.last['payload'], {'all': true});
  });

  testWidgets('the host switches follow the next snapshot', (tester) async {
    transport.admin = true;
    await pumpPlay(
      tester,
      extra: [adminTokenProvider('k7m2p9xq4w').overrideWith(_AdminToken.new)],
    );
    // Bob is in the voice chat: the microphone switch is on and live.
    transport.controller.add(
      jsonEncode({'type': 'snapshot', 'payload': _bobVoice('on')}),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player-seat-4')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('FOR EVERYONE (HOST)'), findsOneWidget);
    var mic = tester.widget<Switch>(find.byKey(const Key('host-mic')));
    expect(mic.value, isTrue);
    expect(mic.onChanged, isNotNull);
    // The server mutes him and pushes a snapshot: the open menu updates.
    transport.controller.add(
      jsonEncode({'type': 'snapshot', 'payload': _bobVoice('muted')}),
    );
    await tester.pump(const Duration(milliseconds: 300));
    mic = tester.widget<Switch>(find.byKey(const Key('host-mic')));
    expect(mic.value, isFalse);
    expect(mic.onChanged, isNull);
  });

  testWidgets('a tournament has no chips button in the player menu', (
    tester,
  ) async {
    transport.admin = true;
    await pumpPlay(
      tester,
      extra: [adminTokenProvider('k7m2p9xq4w').overrideWith(_AdminToken.new)],
    );
    final payload = _bobVoice('on');
    final table = payload['table'] as Map<String, dynamic>;
    (table['settings'] as Map<String, dynamic>)['tournament'] = true;
    transport.controller.add(
      jsonEncode({'type': 'snapshot', 'payload': payload}),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player-seat-4')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('FOR EVERYONE (HOST)'), findsOneWidget);
    expect(find.byKey(const Key('player-action-kick')), findsOneWidget);
    expect(find.byKey(const Key('player-action-chips')), findsNothing);
  });

  testWidgets('the table rules open once right after joining', (tester) async {
    await pumpPlay(
      tester,
      extra: [justJoinedProvider.overrideWith(_JustJoined.new)],
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TableRulesDialog), findsOneWidget);
    expect(find.text('Rules at this table'), findsOneWidget);
    expect(find.byKey(const Key('rules-cash')), findsOneWidget);
    expect(find.text('50 / 100'), findsOneWidget);
    expect(find.text('Give or take chips'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rules-close')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TableRulesDialog), findsNothing);
    // A later snapshot does not bring it back.
    transport.controller.add(
      jsonEncode({'type': 'snapshot', 'payload': _bobVoice('on')}),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TableRulesDialog), findsNothing);
  });

  testWidgets('a controller plays the table and drives the dialogs', (
    tester,
  ) async {
    final pad = _FakePad();
    // A focus move, the legend's post-frame refresh, and its rebuild.
    Future<void> settle() async {
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
    }

    await pumpPlay(
      tester,
      extra: [
        gamepadProvider.overrideWith(() => pad),
        padHintsProvider.overrideWith(_HintsOn.new),
      ],
    );
    pad.connect();
    await tester.pump(const Duration(milliseconds: 300));
    // A toast says so, and the hints show the controller buttons now.
    expect(find.textContaining('Controller connected'), findsOneWidget);
    expect(find.text('X'), findsWidgets);
    // Y opens the raise control, → → → → walks to the pot preset, A confirms.
    pad.press(PadButton.y);
    await tester.pump();
    expect(find.byKey(const Key('raise-control')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      pad.press(PadButton.right);
    }
    await tester.pump();
    expect(find.text('Raise to 1,200'), findsOneWidget);
    pad.press(PadButton.a);
    await tester.pump();
    var action = transport.sent.lastWhere((e) => e['type'] == 'action');
    expect(action['payload'], {'kind': 'raise', 'amount': 1200});
    expect(find.byKey(const Key('raise-control')), findsNothing);
    // X folds.
    pad.press(PadButton.x);
    await tester.pump();
    action = transport.sent.lastWhere((e) => e['type'] == 'action');
    expect(action['payload'], {'kind': 'fold'});
    // Start opens the help; ↓ focuses its Close button and A presses it.
    pad.press(PadButton.start);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(
      find.text('Jump into the side panel and back out (opens it)'),
      findsOneWidget,
    );
    pad.press(PadButton.down);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!.widget;
    expect(
      find.ancestor(
        of: find.byWidget(focused),
        matching: find.byKey(const Key('shortcuts-close')),
      ),
      findsOneWidget,
    );
    pad.press(PadButton.a);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Keyboard shortcuts'), findsNothing);
    // Open again: B closes it without any focus inside.
    pad.press(PadButton.start);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    pad.press(PadButton.b);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Keyboard shortcuts'), findsNothing);
    // No stray actions went out for the dialog presses.
    expect(transport.sent.where((e) => e['type'] == 'action').length, 2);
    Finder focusedIn(PadSection s) => find.ancestor(
      of: find.byWidget(FocusManager.instance.primaryFocus!.context!.widget),
      matching: find.byWidgetPredicate(
        (w) => w is PadSectionScope && w.section == s,
      ),
    );
    // RT from the table switches the panel to the next tab and puts the
    // cursor on that tab; ← walks the strip (Settings, Leaderboard, Log,
    // Chat) and one more ← from the left edge crosses into the table.
    pad.press(PadButton.rt);
    await settle();
    await settle();
    expect(focusedIn(PadSection.panel), findsOneWidget);
    expect(find.text('Side panel · Chat'), findsOneWidget);
    pad.press(PadButton.lt);
    await settle();
    expect(find.text('Side panel · Settings'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      pad.press(PadButton.left);
      await settle();
      expect(focusedIn(PadSection.panel), findsOneWidget);
    }
    // A on the Log tab selects it.
    pad.press(PadButton.right);
    await settle();
    pad.press(PadButton.a);
    await settle();
    expect(find.text('Side panel · Log'), findsOneWidget);
    pad.press(PadButton.left);
    await settle();
    pad.press(PadButton.left);
    await settle();
    expect(focusedIn(PadSection.panel), findsNothing);
    // Back to the Settings tab (LT twice from Log), then LB to the action
    // bar so that the walk below starts from the table.
    pad.press(PadButton.lt);
    await settle();
    pad.press(PadButton.lt);
    await settle();
    expect(find.text('Side panel · Settings'), findsOneWidget);
    pad.press(PadButton.lb);
    await settle();
    pad.press(PadButton.b);
    await settle();
    // Back jumps into the side panel, LB / RB cycle the sections, and
    // Back from the panel closes it and returns to the action bar.
    // The legend says where the cursor is.
    expect(find.byKey(const Key('pad-hint')), findsOneWidget);
    expect(find.text('Action bar'), findsOneWidget);
    pad.press(PadButton.back);
    await settle();
    expect(focusedIn(PadSection.panel), findsOneWidget);
    expect(find.text('Side panel · Settings'), findsOneWidget);
    // The legend shows the LT / RT caps while the cursor is inside.
    expect(find.text('LT'), findsWidgets);
    expect(find.text('RT'), findsWidgets);
    // LT / RT switch the tabs and keep the cursor in the panel.
    pad.press(PadButton.rt);
    await settle();
    expect(find.byKey(const Key('chat-input')), findsOneWidget);
    expect(find.text('Side panel · Chat'), findsOneWidget);
    expect(focusedIn(PadSection.panel), findsOneWidget);
    pad.press(PadButton.lt);
    await settle();
    expect(find.text('Side panel · Settings'), findsOneWidget);
    // A on a settings row opens its page and the cursor stays inside;
    // B goes back to the settings menu.
    Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byKey(const Key('settings-table')),
              matching: find.byType(Text),
            )
            .first,
      ),
    ).requestFocus();
    await tester.pump();
    pad.press(PadButton.a);
    await settle();
    expect(find.byKey(const Key('settings-back')), findsOneWidget);
    expect(find.byKey(const Key('menu-rules')), findsOneWidget);
    expect(focusedIn(PadSection.panel), findsOneWidget);
    expect(find.text('Side panel · Settings · Table'), findsOneWidget);
    // ↓ walks the page's rows and stays in the panel (never a seat or
    // an action button elsewhere on the screen).
    for (var i = 0; i < 3; i++) {
      pad.press(PadButton.down);
      await settle();
      expect(focusedIn(PadSection.panel), findsOneWidget);
    }
    expect(
      find.ancestor(
        of: find.byWidget(FocusManager.instance.primaryFocus!.context!.widget),
        matching: find.byKey(const Key('menu-other-table')),
      ),
      findsOneWidget,
    );
    pad.press(PadButton.b);
    await settle();
    expect(find.byKey(const Key('settings-back')), findsNothing);
    expect(focusedIn(PadSection.panel), findsOneWidget);
    pad.press(PadButton.rb);
    await tester.pump();
    expect(focusedIn(PadSection.actions), findsOneWidget);
    pad.press(PadButton.rb);
    await tester.pump();
    expect(focusedIn(PadSection.table), findsOneWidget);
    pad.press(PadButton.lb);
    await tester.pump();
    expect(focusedIn(PadSection.actions), findsOneWidget);
    pad.press(PadButton.back);
    await settle();
    expect(focusedIn(PadSection.panel), findsOneWidget);
    pad.press(PadButton.back);
    await settle();
    expect(find.byType(SidePanel), findsNothing);
    expect(focusedIn(PadSection.actions), findsOneWidget);
    // A seat is a control too: focus lands on it and A opens its menu.
    // Any widget inside the seat's Clickable resolves to its focus node.
    Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byKey(const Key('player-seat-4')),
              matching: find.byType(Stack),
            )
            .last,
      ),
    ).requestFocus();
    await tester.pump();
    pad.press(PadButton.a);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('player-menu-close')), findsOneWidget);
    pad.press(PadButton.b);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('player-menu-close')), findsNothing);
    // The connection toast closes by itself.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('tapping the own avatar opens the self menu', (tester) async {
    await pumpPlay(tester);
    await tester.tap(find.byKey(const Key('player-seat-0')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('self-voice')), findsOneWidget);
    expect(find.byKey(const Key('self-camera')), findsOneWidget);
    await tester.tap(find.byKey(const Key('self-look')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('avatar-5')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('look-done')));
    await tester.pump(const Duration(milliseconds: 600));
    final avatar = transport.sent.lastWhere((e) => e['type'] == 'avatar');
    expect(avatar['payload'], {'avatar': 5});
    expect(transport.sent.where((e) => e['type'] == 'hat'), isEmpty);
  });

  testWidgets('the player menu mutes and hides another player locally', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.byKey(const Key('player-seat-4')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Bob'), findsWidgets);
    expect(find.text('ONLY FOR YOU'), findsOneWidget);
    // Not the host: no table-wide actions.
    expect(find.text('FOR EVERYONE (HOST)'), findsNothing);
    await tester.tap(find.byKey(const Key('peer-mute')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('peer-hide-hat')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('peer-reset')), findsOneWidget);
    await tester.tap(find.byKey(const Key('player-menu-close')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('peer-muted-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('hat-worn-cowboy')), findsNothing);
    // Nothing went to the server.
    expect(sentTypes().where((t) => t != 'hello' && t != 'ping'), isEmpty);
  });

  testWidgets('a free seat asks before moving and sends change_seat', (
    tester,
  ) async {
    await pumpPlay(tester);
    // Seat 1 is empty in the fixture; the viewer may move there.
    await tester.tap(find.byKey(const Key('take-seat-1')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Move to seat 2?'), findsOneWidget);
    await tester.tap(find.text('Move'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sentTypes(), contains('change_seat'));
  });

  testWidgets('the invite button copies the link and lists everyone', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.byKey(const Key('invite')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Invite players'), findsOneWidget);
    expect(find.byKey(const Key('invite-link')), findsOneWidget);
    expect(find.text('Players (2)'), findsOneWidget);
    expect(find.text('Spectators (0)'), findsOneWidget);
    expect(find.text('Bob'), findsWidgets);
    // Let the "link copied" toast expire.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('the display size is adjustable from the drawer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPlay(tester);
    final before = tester
        .widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget))
        .first
        .width;
    await tester.ensureVisible(find.byKey(const Key('tab-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tab-settings')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const Key('settings-preferences')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('display-size')));
    await tester.pump();
    // Normal -> Large -> Extra large.
    await tester.tap(find.byKey(const Key('display-size')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('display-size')));
    await tester.pump();
    final after = tester
        .widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget))
        .first
        .width;
    expect(after, greaterThan(before));
  });

  testWidgets('a bad network check is explained in a toast and the tab', (
    tester,
  ) async {
    VoiceController.engineFactory = _ProbeEngine.new;
    addTearDown(() => VoiceController.engineFactory = null);
    await pumpPlay(tester);
    await tester.tap(find.byKey(const Key('mic-button')));
    await tester.pump(const Duration(milliseconds: 300));
    // The toast names the problem, and so does the voice page.
    expect(find.textContaining('symmetric NAT'), findsWidgets);
    await tester.tap(find.byKey(const Key('settings-voice')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('drawer-network')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('microphone and camera are one-press toggles in the bar', (
    tester,
  ) async {
    await pumpPlay(tester);
    expect(find.byKey(const Key('mic-button')), findsOneWidget);
    expect(find.byKey(const Key('camera-button')), findsOneWidget);
    // Without a microphone (test engine) the press reports "unavailable".
    await tester.tap(find.byKey(const Key('mic-button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Voice chat is not available'), findsWidgets);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a quick phrase is sent and shown next to the seat', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.byKey(const Key('say-button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('say-gg')));
    await tester.pump(const Duration(milliseconds: 300));
    final say = transport.sent.lastWhere((e) => e['type'] == 'say');
    expect(say['payload'], {'phrase': 'gg'});
    // A sticker goes the same way and pops up over the seat.
    await tester.tap(find.byKey(const Key('say-button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('sticker-all_in')));
    await tester.pump(const Duration(milliseconds: 300));
    final sticker = transport.sent.lastWhere((e) => e['type'] == 'say');
    expect(sticker['payload'], {'sticker': 'all_in'});
    transport.controller.add(
      jsonEncode({
        'type': 'phrase',
        'payload': {'seat': 4, 'name': 'Bob', 'sticker': 'skull', 'ts': 2},
      }),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('sticker-bubble-4')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('sticker-bubble-4')), findsNothing);
    transport.controller.add(
      jsonEncode({
        'type': 'phrase',
        'payload': {'seat': 4, 'name': 'Bob', 'phrase': 'nice_call', 'ts': 1},
      }),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Nice call'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Nice call'), findsNothing);
  });

  testWidgets('the winner is highlighted when a pot is awarded', (
    tester,
  ) async {
    await pumpPlay(tester);
    _pushEvents(transport);
    // The snapshot that follows the events puts the hand into its result phase.
    final snap = jsonDecode(
      File('../docs/protocol/fixtures/snapshot.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final payload = snap['payload'] as Map<String, dynamic>;
    final hand = payload['hand'] as Map<String, dynamic>;
    hand['phase'] = 'result';
    hand['to_act_seat'] = null;
    hand['phase_ends_ts'] = 1789000005000;
    transport.controller.add(
      jsonEncode({'type': 'snapshot', 'payload': payload}),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('winner-0')), findsOneWidget);
    // The strip stays a plain phase line; the table tells who won.
    expect(find.byKey(const Key('winner-line')), findsNothing);
    expect(find.text('Alice wins 900 with Pair of Aces'), findsNothing);
    expect(find.byKey(const Key('won-0')), findsOneWidget);
    // The pot was 900 of which 600 were Alice's own: the badge shows the
    // net gain from the results, not the pot.
    expect(find.text('+300'), findsOneWidget);
    expect(find.text('+900'), findsNothing);
  });

  group('the standing of a finished round', () {
    /// A snapshot of this table in [state], carrying the standing of the
    /// round that ended (and no hand unless [dealtIn]).
    void pushSnapshot(
      ScriptedTransport transport, {
      required String state,
      bool dealtIn = false,
    }) {
      final snap = jsonDecode(
        File('../docs/protocol/fixtures/snapshot.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final payload = snap['payload'] as Map<String, dynamic>;
      (payload['table'] as Map<String, dynamic>)['state'] = state;
      if (!dealtIn) {
        payload['hand'] = null;
        for (final sv in payload['seats'] as List<dynamic>) {
          final p = (sv as Map<String, dynamic>)['player'];
          if (p != null) (p as Map<String, dynamic>)['in_hand'] = false;
        }
      }
      payload['last_round'] = {
        'ended_at': 1789000000000,
        'hands': 12,
        'standings': [
          {
            'name': 'Bob',
            'stack': 30000,
            'net': 20000,
            'hands_won': 9,
            'biggest_pot': 4000,
            'place': 1,
          },
          {
            'name': 'Alice',
            'stack': 0,
            'net': -10000,
            'hands_won': 3,
            'biggest_pot': 2200,
            'place': 2,
          },
        ],
      };
      transport.controller.add(
        jsonEncode({'type': 'snapshot', 'payload': payload}),
      );
    }

    testWidgets('stays on screen when the host opens a new round', (
      tester,
    ) async {
      transport.admin = true;
      await pumpPlay(
        tester,
        extra: [adminTokenProvider('k7m2p9xq4w').overrideWith(_AdminToken.new)],
      );

      pushSnapshot(transport, state: 'ended');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Table ended'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // The host is offered the new round right where the standings are.
      expect(find.byKey(const Key('result-new-round')), findsOneWidget);

      // The new round must not pull the result away: the card stays until
      // the player closes it, only the heading and the button change.
      pushSnapshot(transport, state: 'waiting');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('New round started'), findsOneWidget);
      expect(find.text('Table ended'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);

      await tester.tap(find.byKey(const Key('result-back-to-table')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('New round started'), findsNothing);
      // The card was the whole body; the table and its panel are back.
      expect(find.byKey(const Key('tab-settings')), findsOneWidget);
    });

    testWidgets('closes without costing the player their seat', (tester) async {
      await pumpPlay(tester);
      pushSnapshot(transport, state: 'ended');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Table ended'), findsOneWidget);

      await tester.tap(find.byKey(const Key('result-close')));
      await tester.pump(const Duration(milliseconds: 50));
      // Closing the standings is not leaving: the stored session survives,
      // so the next round finds the player in their seat instead of at the
      // join page asking for a name.
      expect(store.cleared, isFalse);
      expect(find.text('JOIN PAGE'), findsNothing);
      expect(find.byKey(const Key('tab-settings')), findsOneWidget);
      expect(find.byKey(const Key('result-close')), findsNothing);

      // Another snapshot of the same ended table does not bring it back.
      pushSnapshot(transport, state: 'ended');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('result-close')), findsNothing);
    });

    testWidgets('gives way to a hand dealt to the player', (tester) async {
      await pumpPlay(tester);
      pushSnapshot(transport, state: 'ended');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Table ended'), findsOneWidget);

      pushSnapshot(transport, state: 'running', dealtIn: true);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Table ended'), findsNothing);
      expect(find.byKey(const Key('tab-settings')), findsOneWidget);
    });

    testWidgets('is kept in the leaderboard tab of the new round', (
      tester,
    ) async {
      await pumpPlay(tester);
      pushSnapshot(transport, state: 'waiting');
      await tester.pump(const Duration(milliseconds: 50));
      // No card (this client did not see the end), but the result is there.
      expect(find.text('New round started'), findsNothing);
      await tester.tap(find.text('Leaderboard'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Last round'), findsOneWidget);
      expect(find.text('This round'), findsOneWidget);
    });
  });
}

void _pushEvents(ScriptedTransport transport) {
  transport.controller.add(
    jsonEncode({
      'type': 'events',
      'payload': {
        'hand_number': 12,
        'events': [
          {
            'seq': 40,
            'ts': 0,
            'kind': 'pot_awarded',
            'pot_index': 0,
            'seat': 0,
            'name': 'Alice',
            'amount': 900,
            'description': 'Pair of Aces',
          },
          {
            'seq': 41,
            'ts': 0,
            'kind': 'hand_ended',
            'results': {
              'pots': <Object>[],
              'seats': {
                '0': {
                  'net': 300,
                  'won': 900,
                  'folded': false,
                  'revealed': true,
                },
                '3': {'net': -300, 'won': 0, 'folded': true, 'revealed': false},
              },
            },
          },
        ],
      },
    }),
  );
}

/// Engine with a microphone whose network check finds a symmetric NAT.
class _ProbeEngine implements VoiceEngine {
  final _events = StreamController<VoiceEvent>.broadcast();
  @override
  Future<bool> start({List<IceServer> iceServers = const []}) async => true;
  @override
  void stop() {}
  @override
  void setMuted(bool muted) {}
  @override
  Future<String?> startCamera() async => 'unsupported';
  @override
  void stopCamera() {}
  @override
  void setReceiveVideo(bool on) {}
  @override
  void setPeerVolume(String peerId, double volume) {}
  @override
  void setPeerVideo(String peerId, bool on) {}
  @override
  Future<String> createOffer(String peerId) async => '';
  @override
  Future<String?> acceptOffer(String peerId, String offer) async => '';
  @override
  Future<void> acceptAnswer(String peerId, String answer) async {}
  @override
  Future<void> addIceCandidate(String peerId, String candidate) async {}
  @override
  void closePeer(String peerId) {}
  @override
  Future<NetworkReport> checkNetwork(List<IceServer> iceServers) async =>
      const NetworkReport(
        verdict: NetworkVerdict.symmetricNat,
        stunConfigured: true,
        stunReachable: true,
        symmetric: true,
      );
  @override
  Stream<VoiceEvent> get events => _events.stream;
}
