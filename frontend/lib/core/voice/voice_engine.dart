import 'dart:async';

import 'voice_engine_stub.dart'
    if (dart.library.js_interop) 'voice_engine_web.dart'
    as impl;

/// One ICE server entry as the instance hands it out: STUN servers without
/// credentials, a TURN relay with its username and credential.
class IceServer {
  const IceServer(this.urls, {this.username, this.credential});
  final List<String> urls;
  final String? username;
  final String? credential;
}

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

/// A remote (or, for [VoiceEngine.self], the local) video stream appeared or
/// went away. [viewType] is the platform view registered for it.
class VoiceVideoEvent extends VoiceEvent {
  const VoiceVideoEvent(super.peerId, this.viewType);
  final String? viewType;
}

/// The connection to [peerId] needs a new offer (a track was added); the
/// controller relays [offer] like an initial one.
class VoiceOfferEvent extends VoiceEvent {
  const VoiceOfferEvent(super.peerId, this.offer);
  final String offer;
}

/// Browser-to-browser audio (WebRTC mesh). The server never carries audio;
/// it only relays the setup messages that this engine produces and consumes.
/// Non-web platforms get a stub that reports the feature as unavailable.
abstract class VoiceEngine {
  static const self = 'me';

  /// Asks for the microphone; false when the browser refuses (insecure
  /// context, no permission, no device). [iceServers] are the STUN/TURN
  /// servers the instance provides (empty = direct connections only).
  Future<bool> start({List<IceServer> iceServers = const []});
  void stop();
  void setMuted(bool muted);

  /// Adds a small camera stream (160x120, 10 fps) to every connection.
  /// Returns null on success, otherwise the browser's reason (permission,
  /// no device, insecure context) for the user.
  Future<String?> startCamera();
  void stopCamera();

  /// Whether to receive the other players' video at all (off saves the
  /// bandwidth: the peers stop sending). Sending is unaffected.
  void setReceiveVideo(bool on);

  /// Creates an offer for [peerId] and returns its serialized description.
  Future<String> createOffer(String peerId);

  /// Accepts a remote offer and returns the serialized answer, or null when
  /// the offer was ignored because this side is in the middle of its own
  /// offer and is the impolite peer (perfect negotiation).
  Future<String?> acceptOffer(String peerId, String offer);
  Future<void> acceptAnswer(String peerId, String answer);
  Future<void> addIceCandidate(String peerId, String candidate);
  void closePeer(String peerId);

  Stream<VoiceEvent> get events;

  static VoiceEngine create() => impl.createVoiceEngine();
}
