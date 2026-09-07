import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/core/session_store.dart';
import 'package:showdown/core/voice/network_check.dart';
import 'package:showdown/core/voice/voice_controller.dart';
import 'package:showdown/core/voice/voice_engine.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/table/play_page.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/shared/playing_card.dart';

import 'test_helpers.dart';

/// A transport that answers hello with the snapshot fixture as welcome and
/// records what the client sends.
class ScriptedTransport implements WsTransport {
  final controller = StreamController<String>();
  final sent = <Map<String, dynamic>>[];

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
      controller.add(
        jsonEncode({
          'type': 'welcome',
          'payload': {
            'you': {'role': 'player', 'player_id': 'p1', 'seat': 0},
            'snapshot': snap['payload'],
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

class _MemorySessionStore extends SessionStore {
  _MemorySessionStore(this.session);
  final StoredSession? session;
  @override
  Future<StoredSession?> load(String tableId) async => session;
  @override
  Future<void> save(String tableId, StoredSession session) async {}
  @override
  Future<void> clear(String tableId) async {}
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

  Future<void> pumpPlay(WidgetTester tester) async {
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
          sessionStoreProvider.overrideWithValue(
            _MemorySessionStore(
              const StoredSession(
                token: 'tok',
                role: 'player',
                name: 'Alice',
                playerId: 'p1',
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
    await tester.ensureVisible(find.byIcon(LucideIcons.settings));
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.settings));
    await tester.pump(const Duration(milliseconds: 600));
    // The gear tab: voice, preferences, table actions.
    expect(find.byKey(const Key('drawer-voice')), findsOneWidget);
    expect(find.byKey(const Key('drawer-sound')), findsOneWidget);
    expect(find.byKey(const Key('drawer-chips')), findsOneWidget);
    expect(find.byKey(const Key('menu-leave')), findsOneWidget);
    expect(find.byKey(const Key('menu-other-table')), findsOneWidget);
    // A seated player is not offered "take a seat".
    expect(find.byKey(const Key('menu-take-seat')), findsNothing);
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
    await tester.ensureVisible(find.byIcon(LucideIcons.settings));
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.settings));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
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
    // The toast and the settings row both name the problem.
    expect(find.textContaining('symmetric NAT'), findsWidgets);
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
