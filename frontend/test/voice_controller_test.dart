import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/voice/network_check.dart';
import 'package:showdown/core/voice/voice_controller.dart';
import 'package:showdown/core/voice/voice_engine.dart';
import 'package:showdown/core/ws_client.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/table/table_session.dart';

import 'test_helpers.dart';

/// Engine that records calls and lets the test push events.
class FakeEngine implements VoiceEngine {
  final calls = <String>[];
  final pushed = StreamController<VoiceEvent>.broadcast();
  bool available = true;
  List<IceServer> ice = const [];
  @override
  Future<bool> start({List<IceServer> iceServers = const []}) async {
    calls.add('start');
    ice = iceServers;
    return available;
  }

  @override
  void stop() => calls.add('stop');
  @override
  void setMuted(bool muted) => calls.add('mute:$muted');
  @override
  Future<String?> startCamera() async => 'unsupported';
  @override
  void stopCamera() {}
  @override
  void setReceiveVideo(bool on) {}
  @override
  Future<String> createOffer(String peerId) async {
    calls.add('offer:$peerId');
    return 'offer-for-$peerId';
  }

  /// When set, answers take a moment to apply (as setRemoteDescription
  /// does in a browser), so the order of the calls shows whether the
  /// controller serialises the signals of one peer.
  bool slow = false;

  @override
  Future<String?> acceptOffer(String peerId, String offer) async {
    calls.add('accept:$peerId:$offer');
    return 'answer-for-$peerId';
  }

  @override
  Future<void> acceptAnswer(String peerId, String answer) async {
    if (slow) await Future<void>.delayed(const Duration(milliseconds: 5));
    calls.add('answer:$peerId:$answer');
  }

  @override
  Future<void> addIceCandidate(String peerId, String candidate) async =>
      calls.add('ice:$peerId:$candidate');
  @override
  void closePeer(String peerId) => calls.add('close:$peerId');

  /// What the network check reports.
  NetworkReport report = const NetworkReport.unknown();
  @override
  Future<NetworkReport> checkNetwork(List<IceServer> iceServers) async {
    calls.add('check');
    return report;
  }

  @override
  Stream<VoiceEvent> get events => pushed.stream;
}

/// Transport that answers the hello with a welcome and records sends. Like
/// the server it shows every player's voice presence in its snapshots: the
/// viewer's own ("p1") follows the `voice` commands (snapshot before the
/// ack, as the server sends them), the others are set by the test.
class ScriptedTransport implements WsTransport {
  ScriptedTransport({Map<String, String>? voices}) : voices = {...?voices};
  final Map<String, String> voices;
  final controller = StreamController<String>.broadcast();
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
      push('welcome', {
        'you': {'role': 'player', 'player_id': 'p1', 'seat': 0},
        'snapshot': snapshotJson(),
      });
      return;
    }
    if (env['type'] == 'voice') {
      voices['p1'] =
          (env['payload'] as Map<String, dynamic>)['state'] as String;
      pushSnapshot();
    }
    if (env['id'] != null) push('ack', {'id': env['id']});
  }

  Map<String, dynamic> snapshotJson() {
    final snap = fixtureSnapshot();
    return {
      ...snap.toJson(),
      'seats': [
        for (final sv in snap.seats)
          if (sv.player != null && voices.containsKey(sv.player!.id))
            {
              ...sv.toJson(),
              'player': {
                ...sv.player!.toJson(),
                'voice': voices[sv.player!.id],
              },
            }
          else
            sv.toJson(),
      ],
    };
  }

  void pushSnapshot() => push('snapshot', snapshotJson());

  /// The states of the `voice` commands sent so far.
  List<String> get voiceStates => [
    for (final e in sent)
      if (e['type'] == 'voice')
        (e['payload'] as Map<String, dynamic>)['state'] as String,
  ];

  void push(String type, Map<String, dynamic> payload) =>
      controller.add(jsonEncode({'type': type, 'payload': payload}));
  @override
  Future<void> close([int code = 1000, String? reason]) => controller.close();
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

void main() {
  late FakeEngine engine;
  late ScriptedTransport transport;
  late ProviderContainer container;

  setUp(() {
    engine = FakeEngine();
    transport = ScriptedTransport();
    VoiceController.engineFactory = () => engine;
    TableSessionNotifier.transportFactoryOverride = (_) => transport;
    TableSessionNotifier.urlOverride = (id) => Uri.parse('ws://test/$id');
    container = ProviderContainer();
  });
  tearDown(() {
    VoiceController.engineFactory = null;
    VoiceController.retryBase = const Duration(seconds: 2);
    TableSessionNotifier.transportFactoryOverride = null;
    TableSessionNotifier.urlOverride = null;
    container.dispose();
  });

  List<String> sentTypes() =>
      transport.sent.map((e) => e['type'] as String).toList();

  test('the smaller id offers, the other answers, ice is relayed', () async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await Future<void>.delayed(Duration.zero);
    final voice = container.read(voiceControllerProvider('t1').notifier);
    // A second player (id "p4" > "p1") is in the voice chat: we offer.
    transport.voices['p4'] = 'on';
    transport.pushSnapshot();
    await Future<void>.delayed(Duration.zero);
    await voice.enable();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceControllerProvider('t1')).enabled, isTrue);
    expect(transport.voiceStates, ['on']);
    expect(engine.calls, contains('offer:p4'));
    final offerMsg = transport.sent.lastWhere(
      (e) => e['type'] == 'voice_signal',
    );
    expect(offerMsg['payload'], {
      'to': 'p4',
      'kind': 'offer',
      'data': 'offer-for-p4',
    });
    // Their answer and a candidate arrive through the relay.
    transport.push('voice_signal', {
      'from': 'p4',
      'kind': 'answer',
      'data': 'their-answer',
    });
    transport.push('voice_signal', {
      'from': 'p4',
      'kind': 'ice',
      'data': 'cand',
    });
    await Future<void>.delayed(Duration.zero);
    expect(engine.calls, contains('answer:p4:their-answer'));
    expect(engine.calls, contains('ice:p4:cand'));
    // An offer from a player with a smaller id ("p0") is answered.
    transport.push('voice_signal', {
      'from': 'p0',
      'kind': 'offer',
      'data': 'their-offer',
    });
    await Future<void>.delayed(Duration.zero);
    expect(engine.calls, contains('accept:p0:their-offer'));
    expect(transport.sent.last['payload'], {
      'to': 'p0',
      'kind': 'answer',
      'data': 'answer-for-p0',
    });
    // Our ICE candidates go out; speaking events reach the state.
    engine.pushed.add(const VoiceIceEvent('p4', 'my-cand'));
    engine.pushed.add(const VoiceSpeakingEvent('p4', true));
    await Future<void>.delayed(Duration.zero);
    expect(transport.sent.last['payload'], {
      'to': 'p4',
      'kind': 'ice',
      'data': 'my-cand',
    });
    expect(container.read(voiceControllerProvider('t1')).speaking, {'p4'});
    // Mute and leave.
    await voice.toggleMute();
    expect(engine.calls, contains('mute:true'));
    expect(transport.sent.last['payload'], {'state': 'muted'});
    await voice.disable();
    expect(engine.calls, contains('stop'));
    expect(transport.sent.last['payload'], {'state': 'off'});
  });

  test(
    'after a reconnect the presence is announced again and the peers rebuilt',
    () async {
      // Every connection gets its own transport; the new one starts, like
      // the server after a drop, with the viewer's voice off.
      final transports = <ScriptedTransport>[];
      TableSessionNotifier.transportFactoryOverride = (_) {
        final t = ScriptedTransport(voices: {'p4': 'on'});
        transports.add(t);
        return t;
      };
      final session = container.read(tableSessionProvider('t1').notifier);
      session.start('tok');
      await Future<void>.delayed(Duration.zero);
      final voice = container.read(voiceControllerProvider('t1').notifier);
      await voice.enable();
      await Future<void>.delayed(Duration.zero);
      final first = transports.single;
      expect(first.voiceStates, ['on']);
      expect(engine.calls, contains('offer:p4'));
      engine.calls.clear();
      // The connection drops and comes back.
      await first.controller.close();
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(tableSessionProvider('t1')).connection.status,
        WsStatus.disconnected,
      );
      session.reconnectNow();
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(transports, hasLength(2));
      final second = transports.last;
      // The stale peer is closed, "off" resets the peers' side, then the
      // real state follows and the peer is offered to again.
      expect(engine.calls, contains('close:p4'));
      expect(second.voiceStates, ['off', 'on']);
      expect(engine.calls, contains('offer:p4'));
      expect(container.read(voiceControllerProvider('t1')).enabled, isTrue);
      // The microphone state itself was kept.
      expect(container.read(voiceControllerProvider('t1')).muted, isFalse);
    },
  );

  test('a failed peer connection is tried again after a pause', () async {
    VoiceController.retryBase = const Duration(milliseconds: 20);
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await Future<void>.delayed(Duration.zero);
    final voice = container.read(voiceControllerProvider('t1').notifier);
    transport.voices['p4'] = 'on';
    transport.pushSnapshot();
    await Future<void>.delayed(Duration.zero);
    await voice.enable();
    await Future<void>.delayed(Duration.zero);
    expect(engine.calls, contains('offer:p4'));
    engine.calls.clear();
    // ICE gave up: the engine dropped the peer.
    engine.pushed.add(const VoicePeerGoneEvent('p4'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceControllerProvider('t1')).failed, {'p4'});
    expect(engine.calls, isNot(contains('offer:p4')));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(engine.calls, contains('offer:p4'));
    // Once it connects the peer is fine again.
    engine.pushed.add(const VoiceConnectedEvent('p4', true));
    await Future<void>.delayed(Duration.zero);
    final s = container.read(voiceControllerProvider('t1'));
    expect(s.failed, isEmpty);
    expect(s.connected, {'p4'});
  });

  test('the network is checked after joining and on request', () async {
    engine.report = const NetworkReport(
      verdict: NetworkVerdict.symmetricNat,
      stunConfigured: true,
      stunReachable: true,
      symmetric: true,
    );
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await Future<void>.delayed(Duration.zero);
    final voice = container.read(voiceControllerProvider('t1').notifier);
    await voice.enable();
    await Future<void>.delayed(Duration.zero);
    var s = container.read(voiceControllerProvider('t1'));
    expect(engine.calls.where((c) => c == 'check'), hasLength(1));
    expect(s.network?.verdict, NetworkVerdict.symmetricNat);
    expect(s.network?.problem, isTrue);
    expect(s.networkChecking, isFalse);
    engine.report = const NetworkReport(
      verdict: NetworkVerdict.relayOk,
      turnConfigured: true,
      relayWorks: true,
    );
    await voice.checkNetwork();
    s = container.read(voiceControllerProvider('t1'));
    expect(engine.calls.where((c) => c == 'check'), hasLength(2));
    expect(s.network?.verdict, NetworkVerdict.relayOk);
    // Leaving the voice chat forgets the report.
    await voice.disable();
    expect(container.read(voiceControllerProvider('t1')).network, isNull);
  });

  test('a refused microphone marks the feature unavailable', () async {
    engine.available = false;
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await Future<void>.delayed(Duration.zero);
    await container.read(voiceControllerProvider('t1').notifier).enable();
    final s = container.read(voiceControllerProvider('t1'));
    expect(s.enabled, isFalse);
    expect(s.unavailable, isTrue);
    expect(sentTypes(), isNot(contains('voice')));
  });
  _orderTests();
}

void _orderTests() {
  group('signal order', () {
    late FakeEngine engine;
    late ScriptedTransport transport;
    late ProviderContainer container;
    setUp(() {
      engine = FakeEngine();
      transport = ScriptedTransport();
      VoiceController.engineFactory = () => engine;
      TableSessionNotifier.transportFactoryOverride = (_) => transport;
      TableSessionNotifier.urlOverride = (id) => Uri.parse('ws://test/$id');
      container = ProviderContainer();
    });
    tearDown(() {
      VoiceController.engineFactory = null;
      TableSessionNotifier.transportFactoryOverride = null;
      TableSessionNotifier.urlOverride = null;
      container.dispose();
    });

    test(
      'an ice candidate never overtakes the answer of the same peer',
      () async {
        engine.slow = true;
        container.read(tableSessionProvider('t1').notifier).start('tok');
        await Future<void>.delayed(Duration.zero);
        final voice = container.read(voiceControllerProvider('t1').notifier);
        await voice.enable();
        transport.push('voice_signal', {
          'from': 'p4',
          'kind': 'answer',
          'data': 'a',
        });
        transport.push('voice_signal', {
          'from': 'p4',
          'kind': 'ice',
          'data': 'c',
        });
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final order = engine.calls
            .where((c) => c.startsWith('answer:') || c.startsWith('ice:'))
            .toList();
        expect(order, ['answer:p4:a', 'ice:p4:c']);
      },
    );
  });
}
