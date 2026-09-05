import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_api.dart';
import '../../core/config.dart';
import '../../core/time_sync.dart';
import '../../core/ws_client.dart';
import '../../core/ws_transport.dart';
import '../../protocol/protocol.dart';
import '../admin/admin_session.dart';

/// One event with the names that were current when it arrived.
class LogEntry {
  const LogEntry({
    required this.handNumber,
    required this.event,
    required this.names,
  });

  final int handNumber;
  final GameEvent event;

  /// seat -> name at the time of the event.
  final Map<int, String> names;
}

/// Everything the table screen renders.
class TableSessionState {
  const TableSessionState({
    this.connection = const WsState(),
    this.snapshot,
    this.identity,
    this.chat = const [],
    this.unreadChat = 0,
    this.log = const [],
    this.unreadLog = 0,
    this.ended,
    this.kicked,
    this.serverRestarting = false,
    this.revealed = const {},
    this.best = const {},
    this.winners = const {},
    this.shown = const {},
    this.winnerLines = const [],
    this.phrases = const {},
    this.lastError,
  });

  final WsState connection;
  final Snapshot? snapshot;
  final YouIdentity? identity;
  final List<ChatMessage> chat;
  final int unreadChat;
  final List<LogEntry> log;
  final int unreadLog;
  final TableEnded? ended;
  final Kicked? kicked;
  final bool serverRestarting;

  /// Seats revealed in the current hand.
  final Set<int> revealed;

  /// seat -> best five cards (from hands_revealed) in the current hand.
  final Map<int, List<String>> best;

  /// Seats that won a pot in the current hand (winner highlight).
  final Set<int> winners;

  /// Per seat: which of the two cards were voluntarily shown this hand
  /// (partial reveals); both true once fully revealed.
  final Map<int, List<bool>> shown;

  /// One entry per pot awarded in the current hand: "name|amount|description".
  final List<String> winnerLines;

  /// Quick phrases currently shown next to avatars, by seat.
  final Map<int, PhrasePayload> phrases;
  final ServerError? lastError;

  bool get isPlayer => identity?.role == 'player';
  int? get mySeat => identity?.seat;

  TableSessionState copyWith({
    WsState? connection,
    Snapshot? snapshot,
    YouIdentity? identity,
    List<ChatMessage>? chat,
    int? unreadChat,
    List<LogEntry>? log,
    int? unreadLog,
    TableEnded? ended,
    Kicked? kicked,
    bool? serverRestarting,
    Set<int>? revealed,
    Map<int, List<String>>? best,
    Set<int>? winners,
    Map<int, List<bool>>? shown,
    List<String>? winnerLines,
    Map<int, PhrasePayload>? phrases,
    ServerError? lastError,
    bool clearError = false,
  }) => TableSessionState(
    connection: connection ?? this.connection,
    snapshot: snapshot ?? this.snapshot,
    identity: identity ?? this.identity,
    chat: chat ?? this.chat,
    unreadChat: unreadChat ?? this.unreadChat,
    log: log ?? this.log,
    unreadLog: unreadLog ?? this.unreadLog,
    ended: ended ?? this.ended,
    kicked: kicked ?? this.kicked,
    serverRestarting: serverRestarting ?? this.serverRestarting,
    revealed: revealed ?? this.revealed,
    best: best ?? this.best,
    winners: winners ?? this.winners,
    shown: shown ?? this.shown,
    winnerLines: winnerLines ?? this.winnerLines,
    phrases: phrases ?? this.phrases,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

const int logCapacity = 500;
const int chatCapacity = 200;

/// Recorded hands loaded into the log after a reload.
const int historyHands = 30;

/// How long a quick phrase stays next to the avatar.
const Duration phraseDuration = Duration(seconds: 4);

/// Chat-relevant system events.
const systemChatKinds = {
  'player_joined',
  'player_left',
  'player_kicked',
  'player_busted',
  'player_rebought',
  'pot_awarded',
  'hand_voided',
  'table_started',
  'table_paused',
  'table_resumed',
  'table_ended',
  'chips_adjusted',
};

/// Owns the WebSocket client of one table and folds inbound messages into
/// [TableSessionState].
class TableSessionNotifier extends Notifier<TableSessionState> {
  TableSessionNotifier(this.tableId);

  final String tableId;
  WsClient? _client;
  StreamSubscription<ServerMessage>? _msgSub;
  StreamSubscription<WsState>? _stateSub;

  /// Injectable for tests.
  static TransportFactory? transportFactoryOverride;
  static Uri Function(String tableId)? urlOverride;

  @override
  TableSessionState build() {
    ref.onDispose(_teardown);
    return const TableSessionState();
  }

  Uri _url() {
    if (urlOverride != null) return urlOverride!(tableId);
    var base = AppConfig.wsBase;
    if (base.isEmpty) {
      final origin = Uri.base;
      final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
      base =
          '$scheme://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}';
    }
    return Uri.parse('$base/ws/table/$tableId');
  }

  String? _token;
  String? _adminToken;

  /// Connects with the stored token. Calling it again with the same tokens is
  /// a no-op; a different token (new join) discards the old session state.
  void start(String token, {String? adminToken}) {
    if (_client != null && _token == token && _adminToken == adminToken) {
      return;
    }
    _teardown();
    _token = token;
    _adminToken = adminToken;
    state = const TableSessionState();
    final client = WsClient(
      url: _url(),
      token: token,
      adminToken: adminToken,
      transportFactory: transportFactoryOverride,
    );
    _client = client;
    _stateSub = client.states.listen((s) {
      state = state.copyWith(
        connection: s,
        serverRestarting: s.status == WsStatus.ready ? false : null,
      );
    });
    _msgSub = client.messages.listen(_onMessage);
    client.connect();
  }

  void _teardown() {
    _msgSub?.cancel();
    _stateSub?.cancel();
    _client?.dispose();
    _client = null;
    _token = null;
    _adminToken = null;
  }

  Map<int, String> _names(Snapshot? s) {
    if (s == null) return const {};
    return {
      for (final sv in s.seats)
        if (sv.player != null) sv.seat: sv.player!.name,
    };
  }

  void _onMessage(ServerMessage msg) {
    switch (msg) {
      case WelcomeMessage(:final payload):
        ref.read(timeSyncProvider.notifier).update(payload.snapshot.serverTs);
        state = state.copyWith(
          identity: payload.you,
          snapshot: payload.snapshot,
          ended: null,
          kicked: null,
          serverRestarting: false,
        );
        if (state.log.isEmpty) _loadHistory();
      case SnapshotMessage(:final payload):
        ref.read(timeSyncProvider.notifier).update(payload.serverTs);
        state = state.copyWith(snapshot: payload);
      case EventsMessage(:final payload):
        _applyEvents(payload);
      case ChatServerMessage(:final payload):
        _appendChat([payload]);
      case ChatHistoryMessage(:final payload):
        state = state.copyWith(
          chat: List.unmodifiable(payload.messages.take(chatCapacity)),
        );
      case ChatRemovedMessage(:final payload):
        state = state.copyWith(
          chat: List.unmodifiable(state.chat.where((m) => m.id != payload.id)),
        );
      case ErrorMessage(:final payload):
        state = state.copyWith(
          lastError: ServerError(payload.code, payload.message),
        );
      case KickedMessage(:final payload):
        state = state.copyWith(kicked: payload);
      case TableEndedMessage(:final payload):
        state = state.copyWith(ended: payload);
      case ServerRestartingMessage():
        state = state.copyWith(serverRestarting: true);
      case PongMessage(:final payload):
        ref.read(timeSyncProvider.notifier).update(payload.serverTs);
      case VoiceSignalMessage(:final payload):
        _voiceSignals.add(payload);
      case PhraseMessage(:final payload):
        state = state.copyWith(
          phrases: {...state.phrases, payload.seat: payload},
        );
        Timer(phraseDuration, () {
          if (state.phrases[payload.seat] == payload) {
            state = state.copyWith(
              phrases: {...state.phrases}..remove(payload.seat),
            );
          }
        });
      case AckMessage():
        break;
    }
  }

  /// Rebuilds the hand log from the recorded hands after a (re)load, so a
  /// refresh does not wipe the history.
  Future<void> _loadHistory() async {
    final token = _token;
    if (token == null) return;
    List<HandRecord> hands;
    try {
      hands = await ref
          .read(adminApiProvider)
          .sessionHands(token, tableId, limit: historyHands);
    } catch (_) {
      return;
    }
    if (_token != token || state.log.isNotEmpty) return;
    final entries = <LogEntry>[];
    for (final h in hands.reversed) {
      final names = <int, String>{};
      for (final raw in h.events) {
        final e = GameEvent.fromJson(raw);
        if (e.seat != null && e.name != null && e.name!.isNotEmpty) {
          names[e.seat!] = e.name!;
        }
      }
      for (final raw in h.events) {
        final e = GameEvent.fromJson(raw);
        if (e.kind == 'pots_updated') continue;
        entries.add(
          LogEntry(handNumber: h.number, event: e, names: Map.of(names)),
        );
      }
    }
    if (entries.isEmpty) return;
    final trimmed = entries.length > logCapacity
        ? entries.sublist(entries.length - logCapacity)
        : entries;
    state = state.copyWith(log: List.unmodifiable([...trimmed, ...state.log]));
  }

  void _applyEvents(EventsPayload payload) {
    final names = _names(state.snapshot);
    final entries = [
      ...state.log,
      for (final e in payload.events)
        LogEntry(handNumber: payload.handNumber, event: e, names: names),
    ];
    final trimmed = entries.length > logCapacity
        ? entries.sublist(entries.length - logCapacity)
        : entries;
    var revealed = state.revealed;
    var best = state.best;
    var winners = state.winners;
    var shown = state.shown;
    var winnerLines = state.winnerLines;
    for (final e in payload.events) {
      switch (e.kind) {
        case 'hand_started':
          revealed = const {};
          best = const {};
          winners = const {};
          shown = const {};
          winnerLines = const [];
        case 'pot_awarded':
          if (e.seat != null) {
            winners = {...winners, e.seat!};
            final name = e.name?.isNotEmpty == true
                ? e.name!
                : names[e.seat!] ?? '?';
            winnerLines = [
              ...winnerLines,
              '$name|${e.amount ?? 0}|${e.description ?? ''}',
            ];
          }
        case 'hands_revealed':
          revealed = {
            ...revealed,
            for (final r in e.reveals ?? const <Reveal>[])
              if (r.cards.every((c) => c.isNotEmpty)) r.seat,
          };
          shown = {
            ...shown,
            for (final r in e.reveals ?? const <Reveal>[])
              r.seat: [for (final c in r.cards) c.isNotEmpty],
          };
          best = {
            ...best,
            for (final r in e.reveals ?? const <Reveal>[])
              if (r.best != null) r.seat: r.best!,
          };
      }
    }
    final visible = payload.events
        .where((e) => e.kind != 'pots_updated')
        .length;
    state = state.copyWith(
      log: List.unmodifiable(trimmed),
      unreadLog: state.unreadLog + visible,
      revealed: revealed,
      best: best,
      winners: winners,
      shown: shown,
      winnerLines: winnerLines,
    );
  }

  void _appendChat(List<ChatMessage> msgs) {
    final all = [...state.chat, ...msgs];
    final trimmed = all.length > chatCapacity
        ? all.sublist(all.length - chatCapacity)
        : all;
    state = state.copyWith(
      chat: List.unmodifiable(trimmed),
      unreadChat: state.unreadChat + msgs.length,
    );
  }

  void markChatRead() {
    if (state.unreadChat != 0) state = state.copyWith(unreadChat: 0);
  }

  void markLogRead() {
    if (state.unreadLog != 0) state = state.copyWith(unreadLog: 0);
  }

  void clearError() {
    if (state.lastError != null) state = state.copyWith(clearError: true);
  }

  Future<void> _send(ClientMessage msg) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.send(msg);
      clearError();
    } on ServerError catch (e) {
      state = state.copyWith(lastError: e);
    }
  }

  Future<void> act(String kind, {int? amount}) =>
      _send(ClientMessage.action(ActionPayload(kind: kind, amount: amount)));
  Future<void> sitOut() => _send(const ClientMessage.sitOut());
  Future<void> sitIn() => _send(const ClientMessage.sitIn());
  Future<void> rebuy() => _send(const ClientMessage.rebuy());

  /// Shows the hole cards after an uncontested win: "both" (default),
  /// "first" or "second".
  Future<void> showCards([String which = 'both']) => _send(
    ClientMessage.showCards(
      ShowCardsPayload(cards: which == 'both' ? null : which),
    ),
  );
  Future<void> preAction(String kind) =>
      _send(ClientMessage.preAction(PreActionPayload(kind: kind)));
  Future<void> rabbitHunt() => _send(const ClientMessage.rabbitHunt());
  Future<void> changeSeat(int seat) =>
      _send(ClientMessage.changeSeat(ChangeSeatPayload(seat: seat)));

  final _voiceSignals = StreamController<VoiceSignal>.broadcast();

  /// WebRTC setup messages addressed to this client (relayed by the server).
  Stream<VoiceSignal> get voiceSignals => _voiceSignals.stream;
  Future<void> setVoice(String state) =>
      _send(ClientMessage.voice(VoicePayload(state: state)));
  Future<void> sendVoiceSignal(String to, String kind, String data) => _send(
    ClientMessage.voiceSignal(VoiceSignal(to: to, kind: kind, data: data)),
  );
  Future<void> chat(String text) =>
      _send(ClientMessage.chat(ChatPayload(text: text)));
  Future<void> say(String phrase) =>
      _send(ClientMessage.say(SayPayload(phrase: phrase)));

  /// Leaves the table. The server frees the seat and closes the socket;
  /// the client must not reconnect afterwards (its token is revoked).
  Future<void> leave() async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .send(const ClientMessage.leave())
          .timeout(const Duration(seconds: 3));
    } on Object catch (_) {
      // The close frame may overtake the ack; either way we are done here.
    }
    _teardown();
    state = state.copyWith(
      connection: const WsState(terminal: true, closeCode: 1000),
    );
  }

  /// Takes the seat back after a 4004 (replaced) close.
  void reconnectNow() => _client?.reconnectNow();
}

final tableSessionProvider =
    NotifierProvider.family<TableSessionNotifier, TableSessionState, String>(
      TableSessionNotifier.new,
    );

/// Convenience views (docs §10.5 names).
final wsConnectionProvider = Provider.family<WsState, String>(
  (ref, id) => ref.watch(tableSessionProvider(id).select((s) => s.connection)),
);
final snapshotProvider = Provider.family<Snapshot?, String>(
  (ref, id) => ref.watch(tableSessionProvider(id).select((s) => s.snapshot)),
);
final handLogProvider = Provider.family<List<LogEntry>, String>(
  (ref, id) => ref.watch(tableSessionProvider(id).select((s) => s.log)),
);
final chatProvider = Provider.family<List<ChatMessage>, String>(
  (ref, id) => ref.watch(tableSessionProvider(id).select((s) => s.chat)),
);
