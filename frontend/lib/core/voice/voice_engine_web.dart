import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'voice_engine.dart';

/// WebRTC mesh over `package:web`: one peer connection per other player,
/// audio only, no STUN/TURN by default (same network or a direct route).
class _WebVoiceEngine implements VoiceEngine {
  web.MediaStream? _local;
  web.AudioContext? _ctx;
  final _peers = <String, web.RTCPeerConnection>{};
  final _audios = <String, web.HTMLAudioElement>{};
  final _analysers = <String, web.AnalyserNode>{};
  final _speaking = <String, bool>{};
  final _events = StreamController<VoiceEvent>.broadcast();
  Timer? _meter;
  List<String> _stunUrls = const [];

  @override
  Stream<VoiceEvent> get events => _events.stream;

  @override
  Future<bool> start({List<String> stunUrls = const []}) async {
    _stunUrls = stunUrls;
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
    _analysers.clear();
    _speaking.clear();
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
    final pc = _stunUrls.isEmpty
        ? web.RTCPeerConnection()
        : web.RTCPeerConnection(
            web.RTCConfiguration(
              iceServers: [
                web.RTCIceServer(
                  urls: [for (final u in _stunUrls) u.toJS].toJS,
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
      if (streams.isNotEmpty) _play(peerId, streams.first);
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
    final offer = (await pc.createOffer().toDart)!;
    await pc
        .setLocalDescription(
          web.RTCLocalSessionDescriptionInit(type: offer.type, sdp: offer.sdp),
        )
        .toDart;
    return jsonEncode({'type': offer.type, 'sdp': offer.sdp});
  }

  @override
  Future<String> acceptOffer(String peerId, String offer) async {
    final pc = _pc(peerId);
    final o = jsonDecode(offer) as Map<String, dynamic>;
    await pc
        .setRemoteDescription(
          web.RTCSessionDescriptionInit(
            type: o['type'] as String,
            sdp: o['sdp'] as String,
          ),
        )
        .toDart;
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
    final a = jsonDecode(answer) as Map<String, dynamic>;
    await pc
        .setRemoteDescription(
          web.RTCSessionDescriptionInit(
            type: a['type'] as String,
            sdp: a['sdp'] as String,
          ),
        )
        .toDart;
  }

  @override
  Future<void> addIceCandidate(String peerId, String candidate) async {
    final pc = _pc(peerId);
    final c = jsonDecode(candidate) as Map<String, dynamic>;
    await pc
        .addIceCandidate(
          web.RTCIceCandidateInit(
            candidate: c['candidate'] as String,
            sdpMid: c['sdpMid'] as String?,
            sdpMLineIndex: c['sdpMLineIndex'] as int?,
          ),
        )
        .toDart;
  }

  @override
  void closePeer(String peerId) {
    _peers.remove(peerId)?.close();
    _audios.remove(peerId)?.remove();
    _analysers.remove(peerId);
    if (_speaking.remove(peerId) == true) {
      _events.add(VoiceSpeakingEvent(peerId, false));
    }
  }
}

VoiceEngine createVoiceEngine() => _WebVoiceEngine();
