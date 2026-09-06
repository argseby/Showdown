import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/voice/voice_controller.dart';
import 'package:showdown/core/voice/voice_engine.dart';
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

  @override
  Future<String> acceptOffer(String peerId, String offer) async {
    calls.add('accept:$peerId:$offer');
    return 'answer-for-$peerId';
  }

  @override
  Future<void> acceptAnswer(String peerId, String answer) async =>
      calls.add('answer:$peerId:$answer');
  @override
  Future<void> addIceCandidate(String peerId, String candidate) async =>
      calls.add('ice:$peerId:$candidate');
  @override
  void closePeer(String peerId) => calls.add('close:$peerId');
  @override
  Stream<VoiceEvent> get events => pushed.stream;
}

/// Transport that answers the hello with a welcome and records sends.
class ScriptedTransport implements WsTransport {
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
        'snapshot': fixtureSnapshot().toJson(),
      });
    } else if (env['id'] != null) {
      push('ack', {'id': env['id']});
    }
  }

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
    final snap = fixtureSnapshot();
    transport.push('snapshot', {
      ...snap.toJson(),
      'seats': [
        for (final sv in snap.seats)
          if (sv.player?.id == 'p4')
            {
              ...sv.toJson(),
              'player': {...sv.player!.toJson(), 'voice': 'on'},
            }
          else
            sv.toJson(),
      ],
    });
    await Future<void>.delayed(Duration.zero);
    await voice.enable();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceControllerProvider('t1')).enabled, isTrue);
    expect(sentTypes(), contains('voice'));
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
}
