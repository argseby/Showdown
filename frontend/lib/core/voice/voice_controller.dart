import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

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
  }) => VoiceState(
    enabled: enabled ?? this.enabled,
    muted: muted ?? this.muted,
    hostMuted: hostMuted ?? this.hostMuted,
    unavailable: unavailable ?? this.unavailable,
    connected: connected ?? this.connected,
    speaking: speaking ?? this.speaking,
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

  /// Joins the voice chat; [muted] restores a muted microphone after a
  /// reload.
  Future<void> enable({bool muted = false}) async {
    if (state.enabled) return;
    final engine = (engineFactory ?? VoiceEngine.create)();
    final stun = await ref.read(restClientProvider).voiceStunUrls();
    if (!await engine.start(stunUrls: stun)) {
      state = state.copyWith(unavailable: true);
      return;
    }
    _engine = engine;
    _eventSub = engine.events.listen(_onEngineEvent);
    _signalSub = _session.voiceSignals.listen(_onSignal);
    engine.setMuted(muted);
    state = state.copyWith(enabled: true, muted: muted, unavailable: false);
    _confirmedOn = false;
    await _session.setVoice(muted ? 'muted' : 'on');
    _persist(voice: true, voiceMuted: muted);
    _sync(ref.read(tableSessionProvider(tableId)));
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
    await _session.setVoice(muted ? 'muted' : 'on');
    _persist(voiceMuted: muted);
  }

  /// Remembers the voice choice with the table session so that a reload
  /// comes back with the same microphone state.
  void _persist({bool? voice, bool? voiceMuted}) {
    final store = ref.read(sessionStoreProvider);
    store.load(tableId).then((s) async {
      if (s == null) return;
      await store.save(
        tableId,
        s.copyWith(voice: voice, voiceMuted: voiceMuted),
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
        engine
            .createOffer(id)
            .then((offer) => _session.sendVoiceSignal(id, 'offer', offer));
      }
    }
  }

  Future<void> _onSignal(VoiceSignal sig) async {
    final engine = _engine;
    final from = sig.from;
    if (engine == null || from == null) return;
    switch (sig.kind) {
      case 'offer':
        _peers.add(from);
        final answer = await engine.acceptOffer(from, sig.data);
        await _session.sendVoiceSignal(from, 'answer', answer);
      case 'answer':
        await engine.acceptAnswer(from, sig.data);
      case 'ice':
        await engine.addIceCandidate(from, sig.data);
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
        final set = {...state.connected};
        if (connected) {
          set.add(peerId);
        } else {
          set.remove(peerId);
        }
        state = state.copyWith(connected: set);
    }
  }
}

final voiceControllerProvider =
    NotifierProvider.family<VoiceController, VoiceState, String>(
      VoiceController.new,
    );
