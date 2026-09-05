import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/ws_client.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/protocol/protocol.dart';

/// Scripted transport: records what the client sends and lets the test push
/// server frames or close the socket.
class FakeTransport implements WsTransport {
  FakeTransport({this.failConnect = false});

  final bool failConnect;
  final controller = StreamController<String>();
  final sent = <Map<String, dynamic>>[];
  int? _closeCode;
  String? _closeReason;

  @override
  Future<void> connect() async {
    if (failConnect) throw Exception('refused');
  }

  @override
  Stream<String> get messages => controller.stream;

  @override
  void send(String data) => sent.add(jsonDecode(data) as Map<String, dynamic>);

  @override
  Future<void> close([int code = 1000, String? reason]) async {
    _closeCode = code;
    await controller.close();
  }

  void serverClose(int code, [String reason = '']) {
    _closeCode = code;
    _closeReason = reason;
    controller.close();
  }

  void push(String type, Map<String, dynamic> payload, {String? id}) {
    controller.add(jsonEncode({'type': type, 'id': ?id, 'payload': payload}));
  }

  @override
  int? get closeCode => _closeCode;
  @override
  String? get closeReason => _closeReason;
}

Map<String, dynamic> welcomePayload() => {
  'you': {'role': 'spectator'},
  'snapshot': {
    'server_ts': 1789000000000,
    'table': {
      'id': 't',
      'name': 'T',
      'state': 'waiting',
      'hand_number': 0,
      'settings': {
        'small_blind': 50,
        'big_blind': 100,
        'ante': 0,
        'turn_time': 30,
        'max_players': 9,
        'start_money': 10000,
        'join_policy': 'always',
        'allow_rebuy': true,
        'showdown_reveal': 'all',
        'chat_enabled': true,
        'spectator_chat': true,
        'requires_password': false,
        'allow_rabbit_hunt': true,
        'blinds_up_minutes': 0,
        'blinds_up_percent': 100,
      },
    },
    'seats': <Object?>[],
    'hand': null,
    'you': {
      'role': 'spectator',
      'is_admin': false,
      'options': null,
      'pre_action': 'none',
      'can_rabbit_hunt': false,
      'hand_description': '',
      'can_rebuy': false,
      'can_show_cards': false,
    },
    'leaderboard': <Object?>[],
    'spectators': 1,
  },
};

void main() {
  test('hello, welcome, ack/error correlation and ping', () {
    fakeAsync((async) {
      final transports = <FakeTransport>[];
      final client = WsClient(
        url: Uri.parse('ws://x/ws/table/t'),
        token: 'tok',
        transportFactory: (_) {
          final t = FakeTransport();
          transports.add(t);
          return t;
        },
        pingInterval: const Duration(seconds: 5),
      );
      final states = <WsStatus>[];
      client.states.listen((s) => states.add(s.status));
      final received = <ServerMessage>[];
      client.messages.listen(received.add);

      client.connect();
      async.flushMicrotasks();
      final t = transports.single;
      expect(t.sent.single['type'], 'hello');
      expect(t.sent.single['payload'], {'v': 1, 'token': 'tok'});
      expect(client.state.status, WsStatus.helloSent);

      t.push('welcome', welcomePayload());
      async.flushMicrotasks();
      expect(client.state.status, WsStatus.ready);
      expect(received.single, isA<WelcomeMessage>());

      // A command completes on ack and fails on error.
      var acked = false;
      client.send(const ClientMessage.sitOut()).then((_) => acked = true);
      async.flushMicrotasks();
      final id = t.sent.last['id'] as String;
      expect(t.sent.last['type'], 'sit_out');
      t.push('ack', {'id': id});
      async.flushMicrotasks();
      expect(acked, isTrue);

      Object? failure;
      client
          .send(const ClientMessage.rebuy())
          .catchError((Object e) => failure = e);
      async.flushMicrotasks();
      final id2 = t.sent.last['id'] as String;
      t.push('error', {
        'id': id2,
        'code': 'rebuy_not_allowed',
        'message': 'no',
      });
      async.flushMicrotasks();
      expect(failure, isA<ServerError>());
      expect((failure! as ServerError).code, 'rebuy_not_allowed');

      // Heartbeat pings while ready.
      async.elapse(const Duration(seconds: 11));
      expect(t.sent.where((m) => m['type'] == 'ping').length, 2);
      expect(states, [WsStatus.connecting, WsStatus.helloSent, WsStatus.ready]);
      client.dispose();
    });
  });

  test('reconnects with backoff after a non-terminal close and stops on terminal codes', () {
    fakeAsync((async) {
      final transports = <FakeTransport>[];
      final client = WsClient(
        url: Uri.parse('ws://x/ws/table/t'),
        token: 'tok',
        transportFactory: (_) {
          final t = FakeTransport();
          transports.add(t);
          return t;
        },
        random: Random(1),
      );
      client.connect();
      async.flushMicrotasks();
      transports[0].push('welcome', welcomePayload());
      async.flushMicrotasks();
      transports[0].serverClose(1006, 'lost');
      async.flushMicrotasks();
      expect(client.state.status, WsStatus.disconnected);
      expect(client.state.attempt, 1);
      expect(client.state.terminal, isFalse);
      // Pending commands fail when the socket drops.
      expect(
        client.send(const ClientMessage.sitIn()),
        throwsA(isA<ServerError>()),
      );

      async.elapse(const Duration(milliseconds: 700));
      expect(transports.length, 2, reason: 'reconnected after ~0.5 s');
      expect(transports[1].sent.single['type'], 'hello');
      transports[1].serverClose(1006);
      async.flushMicrotasks();
      expect(client.state.attempt, 2);
      async.elapse(const Duration(milliseconds: 700));
      expect(transports.length, 2, reason: 'second backoff is about 1 s');
      async.elapse(const Duration(milliseconds: 700));
      expect(transports.length, 3);

      // Backoff is capped at 10 s (with jitter).
      expect(client.backoffFor(20).inMilliseconds, lessThanOrEqualTo(12500));
      expect(client.backoffFor(20).inMilliseconds, greaterThanOrEqualTo(7500));

      transports[2].serverClose(4005, 'kicked');
      async.flushMicrotasks();
      expect(client.state.terminal, isTrue);
      expect(client.state.closeCode, 4005);
      async.elapse(const Duration(seconds: 30));
      expect(
        transports.length,
        3,
        reason: 'no reconnect after a terminal close',
      );

      client.reconnectNow();
      async.flushMicrotasks();
      expect(transports.length, 4);
      client.dispose();
    });
  });

  test('connect failures are retried', () {
    fakeAsync((async) {
      var calls = 0;
      final client = WsClient(
        url: Uri.parse('ws://x'),
        token: 't',
        transportFactory: (_) {
          calls++;
          return FakeTransport(failConnect: calls == 1);
        },
        random: Random(2),
      );
      client.connect();
      async.flushMicrotasks();
      expect(client.state.status, WsStatus.disconnected);
      expect(client.state.attempt, 1);
      async.elapse(const Duration(seconds: 1));
      expect(calls, 2);
      expect(client.state.status, WsStatus.helloSent);
      client.dispose();
    });
  });
}
