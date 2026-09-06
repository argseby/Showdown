import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../features/table/table_session.dart';
import '../../protocol/protocol.dart';
import '../providers.dart';
import '../session_store.dart';
import 'voice_engine.dart';

/// Voice-chat state for one table.
class VoiceState {
  const VoiceState({
    this.enabled = false,
    this.muted = false,
    this.hostMuted = false,
    this.unavailable = false,
    this.connected = const {},
    this.speaking = const {},
    this.camera = false,
    this.cameraUnavailable = false,
    this.cameraError,
    this.hostCameraOff = false,
    this.videoViews = const {},
  });

  /// The browser's reason when the camera could not be started.
  final String? cameraError;

  /// The local camera is on.
  final bool camera;

  /// The browser refused the camera.
  final bool cameraUnavailable;

  /// The host turned the camera off (shown once).
  final bool hostCameraOff;

  /// Platform view type per player id with a live video (self under
  /// [VoiceEngine.self]).
  final Map<String, String> videoViews;

  final bool enabled;
  final bool muted;

  /// The last mute came from the host, not the player.
  final bool hostMuted;

  /// The browser refused the microphone (needs HTTPS or localhost).
  final bool unavailable;

  /// Player ids with an established audio connection.
  final Set<String> connected;

  /// Player ids currently speaking; contains [VoiceEngine.self] for the
  /// local microphone.
  final Set<String> speaking;

  VoiceState copyWith({
    bool? enabled,
    bool? muted,
    bool? hostMuted,
    bool? unavailable,
    Set<String>? connected,
    Set<String>? speaking,
    bool? camera,
    bool? cameraUnavailable,
    String? cameraError,
    bool? hostCameraOff,
    Map<String, String>? videoViews,
  }) => VoiceState(
    enabled: enabled ?? this.enabled,
    muted: muted ?? this.muted,
    hostMuted: hostMuted ?? this.hostMuted,
    unavailable: unavailable ?? this.unavailable,
    connected: connected ?? this.connected,
    speaking: speaking ?? this.speaking,
    camera: camera ?? this.camera,
    cameraUnavailable: cameraUnavailable ?? this.cameraUnavailable,
    cameraError: cameraError ?? this.cameraError,
    hostCameraOff: hostCameraOff ?? this.hostCameraOff,
    videoViews: videoViews ?? this.videoViews,
  );
}

/// Drives the WebRTC mesh from the table snapshot: every player whose
/// `voice` is on gets a connection; the player with the smaller id makes the
/// offer. Signals travel through the table session (server relay).
class VoiceController extends Notifier<VoiceState> {
  VoiceController(this.tableId);

  final String tableId;

  /// Test hook for a fake engine.
  static VoiceEngine Function()? engineFactory;

  VoiceEngine? _engine;
  StreamSubscription<VoiceEvent>? _eventSub;
  StreamSubscription<VoiceSignal>? _signalSub;
  final _peers = <String>{};

  /// Signals of one peer are applied strictly in order (an ICE candidate
  /// right behind an answer must not overtake it).
  final _chains = <String, Future<void>>{};

  /// One line per signalling step in the browser console, so a failing
  /// connection can be traced from the two ends.
  static void log(String message) => debugPrint('voice: $message');

  @override
  VoiceState build() {
    // On dispose only release the audio; the session may already be gone.
    ref.onDispose(() {
      _eventSub?.cancel();
      _signalSub?.cancel();
      _engine?.stop();
      _engine = null;
    });
    ref.listen(tableSessionProvider(tableId), (_, next) => _sync(next));
    return const VoiceState();
  }

  TableSessionNotifier get _session =>
      ref.read(tableSessionProvider(tableId).notifier);

  String? get _myId =>
      ref.read(tableSessionProvider(tableId)).identity?.playerId;

  /// True once a snapshot showed this player's microphone as "on" after
  /// the last state we sent; a "muted" snapshot after that is the host's
  /// doing, not a stale echo of our own change.
  bool _confirmedOn = false;

  /// True once a snapshot showed the camera on after we switched it on.
  bool _confirmedCamera = false;

  /// Joins the voice chat; [muted] and [camera] restore the state after a
  /// reload.
  Future<void> enable({bool muted = false, bool camera = false}) async {
    if (state.enabled) return;
    final engine = (engineFactory ?? VoiceEngine.create)();
    final ice = await ref.read(restClientProvider).iceServers();
    if (!await engine.start(iceServers: ice)) {
      state = state.copyWith(unavailable: true);
      return;
    }
    _engine = engine;
    _eventSub = engine.events.listen(_onEngineEvent);
    _signalSub = _session.voiceSignals.listen(_onSignal);
    engine.setMuted(muted);
    engine.setReceiveVideo(ref.read(showCamerasProvider));
    state = state.copyWith(enabled: true, muted: muted, unavailable: false);
    _confirmedOn = false;
    await _session.setVoice(muted ? 'muted' : 'on');
    _persist(voice: true, voiceMuted: muted);
    _sync(ref.read(tableSessionProvider(tableId)));
    if (camera) await toggleCamera();
  }

  /// Receive (or stop receiving) the other players' video.
  void setReceiveVideo(bool on) {
    _engine?.setReceiveVideo(on);
    if (!on) {
      state = state.copyWith(
        videoViews: {
          for (final e in state.videoViews.entries)
            if (e.key == VoiceEngine.self) e.key: e.value,
        },
      );
    }
  }

  /// Turns the small camera stream on or off (voice chat must be on).
  Future<void> toggleCamera() async {
    final engine = _engine;
    if (engine == null || !state.enabled) return;
    if (state.camera) {
      engine.stopCamera();
      state = state.copyWith(camera: false, hostCameraOff: false);
      _confirmedCamera = false;
    } else {
      final error = await engine.startCamera();
      if (error != null) {
        state = state.copyWith(cameraUnavailable: true, cameraError: error);
        return;
      }
      state = state.copyWith(
        camera: true,
        cameraUnavailable: false,
        hostCameraOff: false,
      );
      _confirmedCamera = false;
    }
    await _session.setVoice(state.muted ? 'muted' : 'on', camera: state.camera);
    _persist(voiceCamera: state.camera);
  }

  Future<void> disable() async {
    if (!state.enabled) return;
    await _eventSub?.cancel();
    await _signalSub?.cancel();
    _engine?.stop();
    _engine = null;
    _peers.clear();
    state = const VoiceState();
    _confirmedOn = false;
    await _session.setVoice('off');
    _persist(voice: false, voiceMuted: false);
  }

  Future<void> toggleMute() async {
    if (!state.enabled) return;
    final muted = !state.muted;
    _engine?.setMuted(muted);
    state = state.copyWith(muted: muted, hostMuted: false);
    _confirmedOn = false;
    await _session.setVoice(muted ? 'muted' : 'on', camera: state.camera);
    _persist(voiceMuted: muted);
  }

  /// Remembers the voice choice with the table session so that a reload
  /// comes back with the same microphone state.
  void _persist({bool? voice, bool? voiceMuted, bool? voiceCamera}) {
    final store = ref.read(sessionStoreProvider);
    store.load(tableId).then((s) async {
      if (s == null) return;
      await store.save(
        tableId,
        s.copyWith(
          voice: voice,
          voiceMuted: voiceMuted,
          voiceCamera: voiceCamera,
        ),
      );
    }).ignore();
  }

  /// Connects to every other player in the voice chat and drops peers that
  /// left it; also applies a mute the host imposed.
  void _sync(TableSessionState s) {
    final engine = _engine;
    final me = _myId;
    if (engine == null || me == null || !state.enabled) return;
    final snap = s.snapshot;
    if (snap == null) return;
    for (final sv in snap.seats) {
      final p = sv.player;
      if (p == null || p.id != me) continue;
      if (p.voice == 'on' && !state.muted) _confirmedOn = true;
      if (p.voice == 'muted' && !state.muted && _confirmedOn) {
        engine.setMuted(true);
        state = state.copyWith(muted: true, hostMuted: true);
        _confirmedOn = false;
        _persist(voiceMuted: true);
      }
      if ((p.camera ?? false) && state.camera) _confirmedCamera = true;
      if (!(p.camera ?? false) && state.camera && _confirmedCamera) {
        // The host turned the camera off.
        engine.stopCamera();
        state = state.copyWith(camera: false, hostCameraOff: true);
        _confirmedCamera = false;
        _persist(voiceCamera: false);
      }
    }
    final wanted = <String>{
      for (final sv in snap.seats)
        if (sv.player != null &&
            sv.player!.id != me &&
            sv.player!.voice != 'off')
          sv.player!.id,
    };
    for (final id in _peers.toList()) {
      if (!wanted.contains(id)) {
        engine.closePeer(id);
        _peers.remove(id);
        state = state.copyWith(
          connected: {...state.connected}..remove(id),
          speaking: {...state.speaking}..remove(id),
        );
      }
    }
    for (final id in wanted) {
      if (_peers.contains(id)) continue;
      if (me.compareTo(id) < 0) {
        _peers.add(id);
        log('offering to $id');
        engine
            .createOffer(id)
            .then((offer) => _session.sendVoiceSignal(id, 'offer', offer))
            .catchError((Object e) {
              log('offer to $id failed: $e');
              _peers.remove(id);
            });
      }
    }
  }

  void _onSignal(VoiceSignal sig) {
    final from = sig.from;
    if (from == null) return;
    final previous = _chains[from] ?? Future<void>.value();
    _chains[from] = previous.then((_) => _handleSignal(from, sig));
  }

  Future<void> _handleSignal(String from, VoiceSignal sig) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      switch (sig.kind) {
        case 'offer':
          _peers.add(from);
          log('offer from $from');
          final answer = await engine.acceptOffer(from, sig.data);
          if (answer == null) {
            log('offer from $from ignored (collision, our offer stands)');
            return;
          }
          await _session.sendVoiceSignal(from, 'answer', answer);
        case 'answer':
          log('answer from $from');
          await engine.acceptAnswer(from, sig.data);
        case 'ice':
          await engine.addIceCandidate(from, sig.data);
        default:
          log('unknown signal ${sig.kind} from $from');
      }
    } on Object catch (e) {
      log('${sig.kind} from $from failed: $e');
    }
  }

  void _onEngineEvent(VoiceEvent e) {
    switch (e) {
      case VoiceIceEvent(:final peerId, :final candidate):
        _session.sendVoiceSignal(peerId, 'ice', candidate);
      case VoiceSpeakingEvent(:final peerId, :final speaking):
        final set = {...state.speaking};
        if (speaking) {
          set.add(peerId);
        } else {
          set.remove(peerId);
        }
        state = state.copyWith(speaking: set);
      case VoiceConnectedEvent(:final peerId, :final connected):
        log('connection to $peerId ${connected ? 'up' : 'down'}');
        final set = {...state.connected};
        if (connected) {
          set.add(peerId);
        } else {
          set.remove(peerId);
        }
        state = state.copyWith(connected: set);
      case VoiceVideoEvent(:final peerId, :final viewType):
        final views = {...state.videoViews};
        if (viewType == null) {
          views.remove(peerId);
        } else {
          views[peerId] = viewType;
        }
        state = state.copyWith(videoViews: views);
      case VoiceOfferEvent(:final peerId, :final offer):
        _session.sendVoiceSignal(peerId, 'offer', offer);
    }
  }
}

final voiceControllerProvider =
    NotifierProvider.family<VoiceController, VoiceState, String>(
      VoiceController.new,
    );
