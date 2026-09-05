import 'dart:async';

import 'voice_engine_stub.dart'
    if (dart.library.js_interop) 'voice_engine_web.dart'
    as impl;

/// One event from the audio layer.
sealed class VoiceEvent {
  const VoiceEvent(this.peerId);
  final String peerId;
}

/// A local ICE candidate for [peerId] that must be relayed to that peer.
class VoiceIceEvent extends VoiceEvent {
  const VoiceIceEvent(super.peerId, this.candidate);
  final String candidate;
}

/// Speaking state changed; [VoiceEngine.self] as peer id means the local mic.
class VoiceSpeakingEvent extends VoiceEvent {
  const VoiceSpeakingEvent(super.peerId, this.speaking);
  final bool speaking;
}

/// The peer connection is up (or gone).
class VoiceConnectedEvent extends VoiceEvent {
  const VoiceConnectedEvent(super.peerId, this.connected);
  final bool connected;
}

/// Browser-to-browser audio (WebRTC mesh). The server never carries audio;
/// it only relays the setup messages that this engine produces and consumes.
/// Non-web platforms get a stub that reports the feature as unavailable.
abstract class VoiceEngine {
  static const self = 'me';

  /// Asks for the microphone; false when the browser refuses (insecure
  /// context, no permission, no device). [stunUrls] are the ICE servers the
  /// instance provides (empty = direct connections only).
  Future<bool> start({List<String> stunUrls = const []});
  void stop();
  void setMuted(bool muted);

  /// Creates an offer for [peerId] and returns its serialized description.
  Future<String> createOffer(String peerId);

  /// Accepts a remote offer and returns the serialized answer.
  Future<String> acceptOffer(String peerId, String offer);
  Future<void> acceptAnswer(String peerId, String answer);
  Future<void> addIceCandidate(String peerId, String candidate);
  void closePeer(String peerId);

  Stream<VoiceEvent> get events;

  static VoiceEngine create() => impl.createVoiceEngine();
}
