import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'voice_engine.dart';

/// WebRTC mesh over `package:web`: one peer connection per other player,
/// audio plus an optional small camera stream, no STUN/TURN by default
/// (same network or a direct route).
class _WebVoiceEngine implements VoiceEngine {
  web.MediaStream? _local;
  web.MediaStream? _camera;
  web.AudioContext? _ctx;
  final _peers = <String, web.RTCPeerConnection>{};
  final _audios = <String, web.HTMLAudioElement>{};
  final _videos = <String, web.HTMLVideoElement>{};
  final _streams = <String, web.MediaStream>{};
  bool _receiveVideo = true;
  final _videoSenders = <String, web.RTCRtpSender>{};
  static var _viewSeq = 0;
  final _analysers = <String, web.AnalyserNode>{};
  final _speaking = <String, bool>{};
  final _events = StreamController<VoiceEvent>.broadcast();
  Timer? _meter;
  List<IceServer> _iceServers = const [];

  // Perfect negotiation (https://w3c.github.io/webrtc-pc/#perfect-negotiation-example):
  // the side that answered the first offer is polite and yields when both
  // sides offer at once; the impolite side ignores the colliding offer.
  final _polite = <String, bool>{};
  final _makingOffer = <String, bool>{};

  // ICE candidates that arrived before the remote description was set are
  // kept until it is (a candidate applied too early is rejected).
  final _remoteReady = <String>{};
  final _pendingIce = <String, List<web.RTCIceCandidateInit>>{};

  @override
  Stream<VoiceEvent> get events => _events.stream;

  @override
  Future<bool> start({List<IceServer> iceServers = const []}) async {
    _iceServers = iceServers;
    try {
      final devices = web.window.navigator.mediaDevices;
      final stream = await devices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
      _local = stream;
      _ctx ??= web.AudioContext();
      _attachAnalyser(VoiceEngine.self, stream);
      _meter = Timer.periodic(const Duration(milliseconds: 120), (_) {
        _measure();
      });
      return true;
    } on Object catch (_) {
      // Insecure context, permission denied, or no microphone.
      return false;
    }
  }

  @override
  void stop() {
    _meter?.cancel();
    _meter = null;
    for (final id in _peers.keys.toList()) {
      closePeer(id);
    }
    final local = _local;
    if (local != null) {
      for (final t in local.getAudioTracks().toDart) {
        t.stop();
      }
    }
    _local = null;
    stopCamera();
    _analysers.clear();
    _speaking.clear();
  }

  @override
  Future<String?> startCamera() async {
    if (_camera != null) return null;
    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              audio: false.toJS,
              video: web.MediaTrackConstraints(
                width: 160.toJS,
                height: 120.toJS,
                frameRate: 10.toJS,
                facingMode: 'user'.toJS,
              ),
            ),
          )
          .toDart;
      _camera = stream;
      final track = stream.getVideoTracks().toDart.first;
      for (final entry in _peers.entries) {
        _videoSenders[entry.key] = entry.value.addTrack(track, stream);
      }
      _showVideo(VoiceEngine.self, stream, mirror: true);
      return null;
    } on Object catch (e) {
      // A DOMException prints as "NotAllowedError: ..." / "NotFoundError:
      // ..." / "NotReadableError: ...", which is the reason the user needs.
      return e.toString();
    }
  }

  @override
  void setReceiveVideo(bool on) {
    if (_receiveVideo == on) return;
    _receiveVideo = on;
    for (final entry in _peers.entries) {
      _applyVideoDirection(entry.value);
      if (!on && entry.key != VoiceEngine.self) _dropVideo(entry.key);
    }
  }

  /// Sets every video transceiver's direction from what we send and whether
  /// we want to receive; a change triggers renegotiation.
  void _applyVideoDirection(web.RTCPeerConnection pc) {
    final sending = _camera != null;
    final wanted = sending
        ? (_receiveVideo ? 'sendrecv' : 'sendonly')
        : (_receiveVideo ? 'recvonly' : 'inactive');
    for (final t in pc.getTransceivers().toDart) {
      final kind = t.receiver.track.kind;
      if (kind != 'video') continue;
      try {
        if (t.direction != wanted) t.direction = wanted;
      } on Object catch (_) {
        // A stopped transceiver rejects direction changes.
      }
    }
  }

  @override
  void stopCamera() {
    final cam = _camera;
    if (cam == null) return;
    for (final t in cam.getVideoTracks().toDart) {
      t.stop();
    }
    for (final entry in _videoSenders.entries) {
      try {
        _peers[entry.key]?.removeTrack(entry.value);
      } on Object catch (_) {
        // The connection may be gone already.
      }
    }
    _videoSenders.clear();
    _camera = null;
    _dropVideo(VoiceEngine.self);
  }

  /// Registers a platform view for [stream] and tells the controller. The
  /// factory builds a fresh <video> per view instance: Flutter re-creates the
  /// platform view whenever the seat is laid out again (side panel opening,
  /// resize), and a DOM element cannot live in two hosts.
  void _showVideo(
    String peerId,
    web.MediaStream stream, {
    bool mirror = false,
  }) {
    _dropVideo(peerId);
    final viewType = 'showdown-video-${_viewSeq++}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        ..playsInline = true
        ..srcObject = stream;
      video.style
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'cover'
        ..borderRadius = '50%';
      if (mirror) video.style.transform = 'scaleX(-1)';
      _videos[peerId] = video;
      return video;
    });
    _streams[peerId] = stream;
    _events.add(VoiceVideoEvent(peerId, viewType));
  }

  void _dropVideo(String peerId) {
    _videos.remove(peerId);
    if (_streams.remove(peerId) != null) {
      _events.add(VoiceVideoEvent(peerId, null));
    }
  }

  @override
  void setMuted(bool muted) {
    final local = _local;
    if (local == null) return;
    for (final t in local.getAudioTracks().toDart) {
      t.enabled = !muted;
    }
  }

  web.RTCPeerConnection _pc(String peerId) {
    final existing = _peers[peerId];
    if (existing != null) return existing;
    final pc = _iceServers.isEmpty
        ? web.RTCPeerConnection()
        : web.RTCPeerConnection(
            web.RTCConfiguration(
              iceServers: [
                for (final s in _iceServers)
                  if (s.username != null && s.credential != null)
                    web.RTCIceServer(
                      urls: [for (final u in s.urls) u.toJS].toJS,
                      username: s.username!,
                      credential: s.credential!,
                    )
                  else
                    web.RTCIceServer(
                      urls: [for (final u in s.urls) u.toJS].toJS,
                    ),
              ].toJS,
            ),
          );
    final local = _local;
    if (local != null) {
      for (final t in local.getAudioTracks().toDart) {
        pc.addTrack(t, local);
      }
    }
    final cam = _camera;
    if (cam != null) {
      for (final t in cam.getVideoTracks().toDart) {
        _videoSenders[peerId] = pc.addTrack(t, cam);
      }
    }
    pc.onnegotiationneeded = ((web.Event _) {
      // A track was added to a live connection: send a fresh offer. The
      // initial offer goes through createOffer, so skip until connected.
      if ((_makingOffer[peerId] ?? false) ||
          pc.connectionState != 'connected') {
        return;
      }
      _makingOffer[peerId] = true;
      () async {
        try {
          final offer = (await pc.createOffer().toDart)!;
          await pc
              .setLocalDescription(
                web.RTCLocalSessionDescriptionInit(
                  type: offer.type,
                  sdp: offer.sdp,
                ),
              )
              .toDart;
          _events.add(
            VoiceOfferEvent(
              peerId,
              jsonEncode({'type': offer.type, 'sdp': offer.sdp}),
            ),
          );
        } on Object catch (_) {
          // Renegotiation failed; audio keeps working.
        } finally {
          _makingOffer[peerId] = false;
        }
      }();
    }).toJS;
    pc.onicecandidate = ((web.RTCPeerConnectionIceEvent e) {
      final c = e.candidate;
      if (c == null) return;
      _events.add(
        VoiceIceEvent(
          peerId,
          jsonEncode({
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          }),
        ),
      );
    }).toJS;
    pc.ontrack = ((web.RTCTrackEvent e) {
      final streams = e.streams.toDart;
      if (streams.isEmpty) return;
      if (e.track.kind == 'video') {
        if (!_receiveVideo) return;
        _showVideo(peerId, streams.first);
        e.track.onended = ((web.Event _) => _dropVideo(peerId)).toJS;
        e.track.onmute = ((web.Event _) => _dropVideo(peerId)).toJS;
        return;
      }
      _play(peerId, streams.first);
    }).toJS;
    pc.onconnectionstatechange = ((web.Event _) {
      final state = pc.connectionState;
      _events.add(VoiceConnectedEvent(peerId, state == 'connected'));
      if (state == 'failed' || state == 'closed') closePeer(peerId);
    }).toJS;
    _peers[peerId] = pc;
    return pc;
  }

  void _play(String peerId, web.MediaStream stream) {
    _audios[peerId]?.remove();
    final audio = web.HTMLAudioElement()
      ..autoplay = true
      ..srcObject = stream;
    web.document.body?.append(audio);
    _audios[peerId] = audio;
    _attachAnalyser(peerId, stream);
  }

  void _attachAnalyser(String id, web.MediaStream stream) {
    final ctx = _ctx;
    if (ctx == null) return;
    try {
      final source = ctx.createMediaStreamSource(stream);
      final analyser = ctx.createAnalyser()..fftSize = 512;
      source.connect(analyser);
      _analysers[id] = analyser;
    } on Object catch (_) {
      // Analysis is a nicety; audio still plays without it.
    }
  }

  void _measure() {
    for (final entry in _analysers.entries) {
      final buf = Uint8List(entry.value.fftSize);
      entry.value.getByteTimeDomainData(buf.toJS);
      var sum = 0.0;
      for (final v in buf) {
        final d = (v - 128) / 128;
        sum += d * d;
      }
      final rms = buf.isEmpty ? 0.0 : sum / buf.length;
      final speaking = rms > 0.0016; // about -28 dBFS
      if (_speaking[entry.key] != speaking) {
        _speaking[entry.key] = speaking;
        _events.add(VoiceSpeakingEvent(entry.key, speaking));
      }
    }
  }

  @override
  Future<String> createOffer(String peerId) async {
    final pc = _pc(peerId);
    // The side that offers first is the impolite one.
    _polite.putIfAbsent(peerId, () => false);
    _makingOffer[peerId] = true;
    try {
      final offer = (await pc.createOffer().toDart)!;
      await pc
          .setLocalDescription(
            web.RTCLocalSessionDescriptionInit(
              type: offer.type,
              sdp: offer.sdp,
            ),
          )
          .toDart;
      return jsonEncode({'type': offer.type, 'sdp': offer.sdp});
    } finally {
      _makingOffer[peerId] = false;
    }
  }

  @override
  Future<String?> acceptOffer(String peerId, String offer) async {
    final pc = _pc(peerId);
    // The side that answers first is the polite one.
    final polite = _polite.putIfAbsent(peerId, () => true);
    final collision =
        (_makingOffer[peerId] ?? false) || pc.signalingState != 'stable';
    if (collision && !polite) {
      // Both sides offered at once: the impolite side keeps its own offer
      // and expects the polite side to answer it.
      return null;
    }
    final o = jsonDecode(offer) as Map<String, dynamic>;
    // A polite side in the middle of its own offer rolls it back here
    // (implicit rollback of setRemoteDescription).
    await pc
        .setRemoteDescription(
          web.RTCSessionDescriptionInit(
            type: o['type'] as String,
            sdp: o['sdp'] as String,
          ),
        )
        .toDart;
    await _remoteSet(peerId, pc);
    if (!_receiveVideo) _applyVideoDirection(pc);
    final answer = (await pc.createAnswer().toDart)!;
    await pc
        .setLocalDescription(
          web.RTCLocalSessionDescriptionInit(
            type: answer.type,
            sdp: answer.sdp,
          ),
        )
        .toDart;
    return jsonEncode({'type': answer.type, 'sdp': answer.sdp});
  }

  @override
  Future<void> acceptAnswer(String peerId, String answer) async {
    final pc = _pc(peerId);
    if (pc.signalingState != 'have-local-offer') {
      // A stale answer (our offer was withdrawn by a collision).
      return;
    }
    final a = jsonDecode(answer) as Map<String, dynamic>;
    await pc
        .setRemoteDescription(
          web.RTCSessionDescriptionInit(
            type: a['type'] as String,
            sdp: a['sdp'] as String,
          ),
        )
        .toDart;
    await _remoteSet(peerId, pc);
  }

  /// The remote description is in place: apply the candidates that came
  /// before it.
  Future<void> _remoteSet(String peerId, web.RTCPeerConnection pc) async {
    _remoteReady.add(peerId);
    final pending = _pendingIce.remove(peerId) ?? const [];
    for (final c in pending) {
      try {
        await pc.addIceCandidate(c).toDart;
      } on Object catch (_) {
        // A candidate for a description that was rolled back.
      }
    }
  }

  @override
  Future<void> addIceCandidate(String peerId, String candidate) async {
    final pc = _pc(peerId);
    final c = jsonDecode(candidate) as Map<String, dynamic>;
    final init = web.RTCIceCandidateInit(
      candidate: c['candidate'] as String,
      sdpMid: c['sdpMid'] as String?,
      sdpMLineIndex: c['sdpMLineIndex'] as int?,
    );
    if (!_remoteReady.contains(peerId)) {
      _pendingIce.putIfAbsent(peerId, () => []).add(init);
      return;
    }
    try {
      await pc.addIceCandidate(init).toDart;
    } on Object catch (_) {
      // A candidate for a description that was rolled back.
    }
  }

  @override
  void closePeer(String peerId) {
    _polite.remove(peerId);
    _makingOffer.remove(peerId);
    _remoteReady.remove(peerId);
    _pendingIce.remove(peerId);
    _peers.remove(peerId)?.close();
    _audios.remove(peerId)?.remove();
    _videoSenders.remove(peerId);
    _dropVideo(peerId);
    _analysers.remove(peerId);
    if (_speaking.remove(peerId) == true) {
      _events.add(VoiceSpeakingEvent(peerId, false));
    }
  }
}

VoiceEngine createVoiceEngine() => _WebVoiceEngine();
