import 'dart:async';

import 'voice_engine.dart';

class _StubVoiceEngine implements VoiceEngine {
  final _events = StreamController<VoiceEvent>.broadcast();
  @override
  Future<bool> start({List<String> stunUrls = const []}) async => false;
  @override
  void stop() {}
  @override
  void setMuted(bool muted) {}
  @override
  Future<String> createOffer(String peerId) async => '';
  @override
  Future<String> acceptOffer(String peerId, String offer) async => '';
  @override
  Future<void> acceptAnswer(String peerId, String answer) async {}
  @override
  Future<void> addIceCandidate(String peerId, String candidate) async {}
  @override
  void closePeer(String peerId) {}
  @override
  Stream<VoiceEvent> get events => _events.stream;
}

VoiceEngine createVoiceEngine() => _StubVoiceEngine();
