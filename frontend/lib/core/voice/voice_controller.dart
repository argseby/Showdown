import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../features/table/table_session.dart';
import '../../protocol/protocol.dart';
import '../providers.dart';
import '../session_store.dart';
import '../ws_client.dart';
import 'network_check.dart';
import 'voice_engine.dart';

/// Voice-chat state for one table.
class VoiceState {
  const VoiceState({
    this.enabled = false,
    this.muted = false,
    this.hostMuted = false,
    this.unavailable = false,
    this.connected = const {},
    this.failed = const {},
    this.speaking = const {},
    this.camera = false,
    this.cameraUnavailable = false,
    this.cameraError,
    this.hostCameraOff = false,
    this.videoViews = const {},
    this.network,
    this.networkChecking = false,
  });

  /// What the browser found out about this network (null until the check
  /// after joining is through).
  final NetworkReport? network;
  final bool networkChecking;

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

  /// Player ids in the voice chat whose connection to us failed (no route
  /// between the browsers, or it went away); a new attempt is pending.
  final Set<String> failed;

  /// Player ids currently speaking; contains [VoiceEngine.self] for the
  /// local microphone.
  final Set<String> speaking;

  VoiceState copyWith({
    bool? enabled,
    bool? muted,
    bool? hostMuted,
    bool? unavailable,
    Set<String>? connected,
    Set<String>? failed,
    Set<String>? speaking,
    bool? camera,
    bool? cameraUnavailable,
    String? cameraError,
    bool? hostCameraOff,
    Map<String, String>? videoViews,
    NetworkReport? network,
    bool? networkChecking,
  }) => VoiceState(
    enabled: enabled ?? this.enabled,
    muted: muted ?? this.muted,
    hostMuted: hostMuted ?? this.hostMuted,
    unavailable: unavailable ?? this.unavailable,
    connected: connected ?? this.connected,
    failed: failed ?? this.failed,
    speaking: speaking ?? this.speaking,
    camera: camera ?? this.camera,
    cameraUnavailable: cameraUnavailable ?? this.cameraUnavailable,
    cameraError: cameraError ?? this.cameraError,
    hostCameraOff: hostCameraOff ?? this.hostCameraOff,
    videoViews: videoViews ?? this.videoViews,
    network: network ?? this.network,
    networkChecking: networkChecking ?? this.networkChecking,
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

  /// A peer whose connection failed is tried again after a pause that
  /// doubles from [retryBase] up to [retryMax] with every failure in a row
  /// (reset once it connects), so an unreachable peer costs little.
  static Duration retryBase = const Duration(seconds: 2);
  static const retryMax = Duration(seconds: 30);
  final _retryTimers = <String, Timer>{};
  final _retryDelay = <String, Duration>{};

  /// Minimum pause between two rejoins, so that a server which keeps
  /// refusing the announcement cannot trigger a storm of them.
  static Duration rejoinMinInterval = const Duration(seconds: 3);
  DateTime? _lastRejoin;
  Timer? _rejoinTimer;
  bool _rejoinPending = false;

  /// The game connection was up at the last look. When it drops and comes
  /// back, the server has forgotten our voice presence (it resets on
  /// disconnect) and the peers have closed their side: everything must be
  /// announced and built again.
  bool _wasReady = false;

  /// A `voice` announcement is on its way: snapshots that still show us
  /// "off" are stale, and no offer goes out until it is through.
  bool _announcing = false;

  /// One line per signalling step in the browser console, so a failing
  /// connection can be traced from the two ends.
  static void log(String message) => debugPrint('voice: $message');

  /// Sends one signal and says so when the server refused it. A dropped
  /// signal otherwise leaves the connection stuck in "connecting" with
  /// nothing to show for it.
  void _signal(String to, String kind, String data) {
    _session.sendVoiceSignal(to, kind, data).then((err) {
      if (err != null) {
        log('$kind to $to refused: ${err.code} (${err.message})');
      }
    });
  }

  @override
  VoiceState build() {
    // On dispose only release the audio; the session may already be gone.
    ref.onDispose(() {
      _eventSub?.cancel();
      _signalSub?.cancel();
      _cancelRetries();
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

  bool get _connectionReady =>
      ref.read(tableSessionProvider(tableId)).connection.status ==
      WsStatus.ready;

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
    _wasReady = _connectionReady;
    _announcing = true;
    state = state.copyWith(enabled: true, muted: muted, unavailable: false);
    _confirmedOn = false;
    try {
      await _session.setVoice(muted ? 'muted' : 'on');
    } finally {
      _announced();
    }
    _persist(voice: true, voiceMuted: muted);
    _sync(ref.read(tableSessionProvider(tableId)));
    unawaited(checkNetwork());
    if (camera) await toggleCamera();
  }

  /// Finds out what this network allows (STUN reachable, symmetric NAT,
  /// relay working) and keeps the report in the state; runs after joining
  /// and on request from the settings tab.
  Future<void> checkNetwork() async {
    final engine = _engine;
    if (engine == null || state.networkChecking) return;
    state = state.copyWith(networkChecking: true);
    final ice = await ref.read(restClientProvider).iceServers();
    final report = await engine.checkNetwork(ice);
    if (_engine != engine) return;
    log(
      'network check: ${report.verdict.name} (stun reachable '
      '${report.stunReachable}, symmetric ${report.symmetric}, '
      'relay ${report.relayWorks})',
    );
    state = state.copyWith(network: report, networkChecking: false);
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
    _cancelRetries();
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
    final ready = s.connection.status == WsStatus.ready;
    final cameBack = ready && !_wasReady;
    _wasReady = ready;
    if (!ready) return;
    final snap = s.snapshot;
    if (snap == null) return;
    if (cameBack) {
      _rejoin(engine, 'connection restored');
      return;
    }
    for (final sv in snap.seats) {
      final p = sv.player;
      if (p == null || p.id != me) continue;
      if (p.voice == 'off' && !_announcing) {
        // The server lists us as off although the microphone is on: it
        // forgot the presence (a drop it noticed before we did, or a
        // restart). Announce again.
        _rejoin(engine, 'presence lost');
        return;
      }
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
        _retryTimers.remove(id)?.cancel();
        _retryDelay.remove(id);
        state = state.copyWith(
          connected: {...state.connected}..remove(id),
          speaking: {...state.speaking}..remove(id),
          failed: {...state.failed}..remove(id),
        );
      }
    }
    // No offer while our own announcement is on its way: the peers reset
    // their side when they see it and would drop an offer sent before.
    if (_announcing) return;
    for (final id in wanted) {
      if (_peers.contains(id)) continue;
      if (me.compareTo(id) < 0) {
        _peers.add(id);
        log('offering to $id');
        engine
            .createOffer(id)
            .then((offer) => _signal(id, 'offer', offer))
            .catchError((Object e) {
              log('offer to $id failed: $e');
              _peers.remove(id);
            });
      }
    }
  }

  /// Announces the voice state afresh and rebuilds every peer connection.
  /// After a reconnect the server shows us "off" and the peers have closed
  /// their side; when the server never noticed the drop (the new
  /// connection replaced the old one) they still hold a dead connection.
  /// "off" goes out first so that every peer starts over, then the real
  /// state; offers wait until both are through.
  Future<void> _rejoin(VoiceEngine engine, String reason) async {
    if (_announcing) {
      _rejoinPending = true;
      return;
    }
    final now = DateTime.now();
    final last = _lastRejoin;
    if (last != null && now.difference(last) < rejoinMinInterval) {
      // Too soon: look again when the pause is over (the snapshot by then
      // decides whether a rejoin is still needed).
      _rejoinTimer ??= Timer(rejoinMinInterval - now.difference(last), () {
        _rejoinTimer = null;
        if (state.enabled) _sync(ref.read(tableSessionProvider(tableId)));
      });
      return;
    }
    _lastRejoin = now;
    _announcing = true;
    log('$reason: rejoining the voice chat');
    _cancelRetries();
    for (final id in _peers) {
      engine.closePeer(id);
    }
    _peers.clear();
    state = state.copyWith(
      connected: const {},
      failed: const {},
      speaking: {
        if (state.speaking.contains(VoiceEngine.self)) VoiceEngine.self,
      },
    );
    _confirmedOn = false;
    _confirmedCamera = false;
    try {
      await _session.setVoice('off');
      if (state.enabled) {
        await _session.setVoice(
          state.muted ? 'muted' : 'on',
          camera: state.camera,
        );
      }
    } finally {
      _announced();
    }
    if (state.enabled) _sync(ref.read(tableSessionProvider(tableId)));
  }

  /// An announcement is through; a rejoin asked for meanwhile runs now.
  void _announced() {
    _announcing = false;
    if (!_rejoinPending) return;
    _rejoinPending = false;
    final engine = _engine;
    if (engine != null && state.enabled) {
      _rejoin(engine, 'connection restored');
    }
  }

  /// The engine dropped [peerId] (ICE failed). Forget the peer so that the
  /// next sync offers again (when we are the offering side; the other side
  /// does the same on its end), after a pause that grows with every
  /// failure in a row.
  void _peerGone(String peerId) {
    if (!_peers.remove(peerId)) return;
    final delay = _retryDelay[peerId] ?? retryBase;
    _retryDelay[peerId] = delay * 2 > retryMax ? retryMax : delay * 2;
    log('connection to $peerId failed, trying again in ${delay.inSeconds} s');
    state = state.copyWith(
      connected: {...state.connected}..remove(peerId),
      speaking: {...state.speaking}..remove(peerId),
      failed: {...state.failed, peerId},
    );
    _retryTimers[peerId]?.cancel();
    _retryTimers[peerId] = Timer(delay, () {
      _retryTimers.remove(peerId);
      if (state.enabled) _sync(ref.read(tableSessionProvider(tableId)));
    });
  }

  void _cancelRetries() {
    for (final t in _retryTimers.values) {
      t.cancel();
    }
    _retryTimers.clear();
    _retryDelay.clear();
    _rejoinTimer?.cancel();
    _rejoinTimer = null;
    _rejoinPending = false;
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
          final err = await _session.sendVoiceSignal(from, 'answer', answer);
          if (err != null) {
            log('answer to $from refused: ${err.code} (${err.message})');
          }
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
        _signal(peerId, 'ice', candidate);
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
          _retryDelay.remove(peerId);
        } else {
          set.remove(peerId);
        }
        state = state.copyWith(
          connected: set,
          failed: connected ? ({...state.failed}..remove(peerId)) : null,
        );
      case VoicePeerGoneEvent(:final peerId):
        _peerGone(peerId);
      case VoiceVideoEvent(:final peerId, :final viewType):
        final views = {...state.videoViews};
        if (viewType == null) {
          views.remove(peerId);
        } else {
          views[peerId] = viewType;
        }
        state = state.copyWith(videoViews: views);
      case VoiceOfferEvent(:final peerId, :final offer):
        _signal(peerId, 'offer', offer);
    }
  }
}

final voiceControllerProvider =
    NotifierProvider.family<VoiceController, VoiceState, String>(
      VoiceController.new,
    );
