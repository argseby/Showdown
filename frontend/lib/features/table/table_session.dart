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
    this.ended,
    this.kicked,
    this.serverRestarting = false,
    this.revealed = const {},
    this.best = const {},
    this.winners = const {},
    this.shown = const {},
    this.winnerLines = const [],
    this.phrases = const {},
    this.chatBubbles = const {},
    this.spotlight,
    this.winnerPotIndex,
    this.winnerAmounts = const {},
    this.collecting = const {},
    this.collectingPots,
    this.collectId = 0,
    this.lastError,
  });

  final WsState connection;
  final Snapshot? snapshot;
  final YouIdentity? identity;
  final List<ChatMessage> chat;
  final int unreadChat;
  final List<LogEntry> log;
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

  /// Chat lines just written by seated players, shown next to their avatar
  /// for a few seconds, by seat.
  final Map<int, String> chatBubbles;

  /// The pot whose award is being presented (0 = main pot, 1 = first side
  /// pot, ...); null when no pot is on display. Colours the winner visuals.
  final int? winnerPotIndex;

  /// Chips won this hand per seat, summed over the pots presented so far
  /// (shown as "+amount" next to the stack until the next deal).
  final Map<int, int> winnerAmounts;

  /// Bets by seat that just left for the pot (street end, or the end of
  /// the hand): the chips fly there for [chipCollectDuration].
  final Map<int, int> collecting;

  /// The pots as they were before those bets arrived, shown until the
  /// chips land; null when nothing is in flight.
  final List<PotView>? collectingPots;

  /// Counts the collections, so every flight gets its own animation.
  final int collectId;

  /// The hand under the spotlight at the showdown: the last revealed hand
  /// while players show one after another, the winner once the pots are
  /// awarded. Null outside the showdown.
  final Spotlight? spotlight;
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
    TableEnded? ended,
    Kicked? kicked,
    bool? serverRestarting,
    Set<int>? revealed,
    Map<int, List<String>>? best,
    Set<int>? winners,
    Map<int, List<bool>>? shown,
    List<String>? winnerLines,
    Map<int, PhrasePayload>? phrases,
    Map<int, String>? chatBubbles,
    Spotlight? spotlight,
    bool clearSpotlight = false,
    int? winnerPotIndex,
    bool clearWinnerPot = false,
    Map<int, int>? winnerAmounts,
    Map<int, int>? collecting,
    List<PotView>? collectingPots,
    bool clearCollectingPots = false,
    int? collectId,
    ServerError? lastError,
    bool clearError = false,
  }) => TableSessionState(
    connection: connection ?? this.connection,
    snapshot: snapshot ?? this.snapshot,
    identity: identity ?? this.identity,
    chat: chat ?? this.chat,
    unreadChat: unreadChat ?? this.unreadChat,
    log: log ?? this.log,
    ended: ended ?? this.ended,
    kicked: kicked ?? this.kicked,
    serverRestarting: serverRestarting ?? this.serverRestarting,
    revealed: revealed ?? this.revealed,
    best: best ?? this.best,
    winners: winners ?? this.winners,
    shown: shown ?? this.shown,
    winnerLines: winnerLines ?? this.winnerLines,
    phrases: phrases ?? this.phrases,
    chatBubbles: chatBubbles ?? this.chatBubbles,
    spotlight: clearSpotlight ? null : (spotlight ?? this.spotlight),
    winnerPotIndex: clearWinnerPot
        ? null
        : (winnerPotIndex ?? this.winnerPotIndex),
    winnerAmounts: winnerAmounts ?? this.winnerAmounts,
    collecting: collecting ?? this.collecting,
    collectingPots: clearCollectingPots
        ? null
        : (collectingPots ?? this.collectingPots),
    collectId: collectId ?? this.collectId,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

const int logCapacity = 500;
const int chatCapacity = 200;

/// A hand under the showdown spotlight: whose, which five cards, its name.
class Spotlight {
  const Spotlight({
    required this.seat,
    required this.name,
    required this.cards,
    required this.description,
    this.winner = false,
    this.potIndex,
  });
  final int seat;
  final String name;
  final List<String> cards;
  final String description;
  final bool winner;

  /// The pot a winner spotlight belongs to (colours it).
  final int? potIndex;
}

/// One pot of a finished hand as it is presented: its winners, the strip
/// lines and the spotlight of the (first) winner.
class PotStage {
  const PotStage({
    required this.potIndex,
    required this.seats,
    required this.lines,
    this.amounts = const {},
    this.spotlight,
  });
  final int potIndex;
  final Set<int> seats;
  final List<String> lines;

  /// Chips of this pot per winning seat.
  final Map<int, int> amounts;
  final Spotlight? spotlight;
}

/// How long each pot of a multi-pot showdown stays on display before the
/// next one (the server extends the showdown by the same amount per pot).
const Duration potAwardStageDuration = Duration(milliseconds: 2500);

/// How long a chat line stays next to the author's avatar.
const Duration chatBubbleDuration = Duration(seconds: 5);

/// How long collected bets stay in flight (and the pots keep their old
/// amounts) after a snapshot moved them into the pot.
const Duration chipCollectDuration = Duration(milliseconds: 1100);

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

  Timer? _collectTimer;

  /// Applies a snapshot; bets that were on the felt and are gone now, in
  /// the same hand, went into the pot: they fly there and the pots keep
  /// their previous amounts until the chips land.
  void _onSnapshot(Snapshot next) {
    final prev = state.snapshot;
    var collecting = state.collecting;
    var collectingPots = state.collectingPots;
    var collectId = state.collectId;
    if (prev?.hand != null &&
        next.hand != null &&
        prev!.table.handNumber == next.table.handNumber) {
      final now = {
        for (final sv in next.seats)
          if (sv.player != null) sv.seat: sv.player!.betThisStreet,
      };
      final moved = <int, int>{
        for (final sv in prev.seats)
          if (sv.player != null &&
              sv.player!.betThisStreet > 0 &&
              (now[sv.seat] ?? 0) == 0)
            sv.seat: sv.player!.betThisStreet,
      };
      if (moved.isNotEmpty) {
        collecting = moved;
        collectingPots = prev.hand!.pots;
        collectId++;
        _collectTimer?.cancel();
        _collectTimer = Timer(chipCollectDuration, () {
          state = state.copyWith(
            collecting: const {},
            clearCollectingPots: true,
          );
        });
      }
    }
    state = state.copyWith(
      snapshot: next,
      collecting: collecting,
      collectingPots: collectingPots,
      collectId: collectId,
    );
  }

  void _teardown() {
    _stageTimer?.cancel();
    _collectTimer?.cancel();
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
        _onSnapshot(payload);
      case EventsMessage(:final payload):
        _applyEvents(payload);
      case ChatServerMessage(:final payload):
        _appendChat([payload]);
        _showChatBubble(payload);
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

  /// Shows a player's chat line next to their avatar for a moment.
  void _showChatBubble(ChatMessage m) {
    if (m.authorKind != 'player' && m.authorKind != 'admin') return;
    final name = m.authorName.toLowerCase();
    int? seat;
    for (final sv in state.snapshot?.seats ?? const <SeatView>[]) {
      if (sv.player?.name.toLowerCase() == name) seat = sv.seat;
    }
    if (seat == null) return;
    final at = seat;
    state = state.copyWith(chatBubbles: {...state.chatBubbles, at: m.text});
    Timer(chatBubbleDuration, () {
      if (state.chatBubbles[at] == m.text) {
        state = state.copyWith(chatBubbles: {...state.chatBubbles}..remove(at));
      }
    });
  }

  Timer? _stageTimer;
  List<PotStage> _stages = const [];
  int _stageIndex = 0;

  /// Presents the pots of a finished hand one after another: side pots
  /// first, the main pot last, each with its own winners and colour.
  void _startStages(List<PotStage> stages) {
    _stageTimer?.cancel();
    _stages = stages;
    _stageIndex = 0;
    _applyStage();
  }

  void _applyStage() {
    if (_stageIndex >= _stages.length) return;
    final stage = _stages[_stageIndex];
    final amounts = {...state.winnerAmounts};
    for (final e in stage.amounts.entries) {
      amounts[e.key] = (amounts[e.key] ?? 0) + e.value;
    }
    state = state.copyWith(
      winners: stage.seats,
      winnerLines: stage.lines,
      winnerPotIndex: stage.potIndex,
      winnerAmounts: amounts,
      spotlight: stage.spotlight != null
          ? Spotlight(
              seat: stage.spotlight!.seat,
              name: stage.spotlight!.name,
              cards:
                  state.best[stage.spotlight!.seat] ?? stage.spotlight!.cards,
              description: stage.spotlight!.description,
              winner: true,
              potIndex: stage.potIndex,
            )
          : null,
      clearSpotlight:
          stage.spotlight == null && state.spotlight?.winner == true,
    );
    if (_stageIndex + 1 < _stages.length) {
      _stageTimer = Timer(potAwardStageDuration, () {
        _stageIndex++;
        _applyStage();
      });
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

  final _events = StreamController<GameEvent>.broadcast();

  /// Every hand/table event as it arrives (sounds, animations).
  Stream<GameEvent> get events => _events.stream;

  void _applyEvents(EventsPayload payload) {
    for (final e in payload.events) {
      _events.add(e);
    }
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
    Spotlight? spotlight = state.spotlight;
    var clearSpotlight = false;
    var clearWinnerPot = false;
    var winnerAmounts = state.winnerAmounts;
    // Pot awards of this batch, grouped by pot in the order they arrive.
    final awards = <int, List<GameEvent>>{};
    for (final e in payload.events) {
      switch (e.kind) {
        case 'hand_started':
          _stageTimer?.cancel();
          _stages = const [];
          revealed = const {};
          best = const {};
          winners = const {};
          shown = const {};
          winnerLines = const [];
          spotlight = null;
          clearSpotlight = true;
          clearWinnerPot = true;
          winnerAmounts = const {};
        case 'hand_ended':
          // The final results carry every revealed hand's best five, which
          // covers run-outs revealed before the board was complete.
          final seats = e.results?.seats ?? const {};
          best = {
            ...best,
            for (final entry in seats.entries)
              if (entry.value.best != null && entry.value.best!.isNotEmpty)
                int.parse(entry.key): entry.value.best!,
          };
        case 'pot_awarded':
          if (e.seat != null) {
            awards.putIfAbsent(e.potIndex ?? 0, () => []).add(e);
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
          for (final r in e.reveals ?? const <Reveal>[]) {
            if (r.best != null &&
                r.best!.isNotEmpty &&
                r.description.isNotEmpty &&
                (spotlight == null || !spotlight.winner)) {
              spotlight = Spotlight(
                seat: r.seat,
                name: names[r.seat] ?? e.name ?? '?',
                cards: r.best!,
                description: r.description,
              );
              clearSpotlight = false;
            }
          }
      }
    }
    // The stages: one per pot, side pots first, the main pot last, so the
    // presentation ends on the main pot. A single pot (or an uncontested
    // hand) is one stage.
    final stages = <PotStage>[];
    final potIndexes = awards.keys.toList()..sort((a, b) => b.compareTo(a));
    final contested = awards.values.any(
      (l) => l.any((e) => (e.description ?? '').isNotEmpty),
    );
    for (final pi in potIndexes) {
      final events = awards[pi]!;
      final seats = <int>{};
      final lines = <String>[];
      final amounts = <int, int>{};
      Spotlight? stageSpot;
      for (final e in events) {
        seats.add(e.seat!);
        amounts[e.seat!] = (amounts[e.seat!] ?? 0) + (e.amount ?? 0);
        final name = e.name?.isNotEmpty == true
            ? e.name!
            : names[e.seat!] ?? '?';
        lines.add('$name|${e.amount ?? 0}|${e.description ?? ''}');
        if ((e.description ?? '').isNotEmpty && stageSpot == null) {
          stageSpot = Spotlight(
            seat: e.seat!,
            name: name,
            cards: best[e.seat!] ?? const [],
            description: e.description!,
            winner: true,
            potIndex: pi,
          );
        }
      }
      stages.add(
        PotStage(
          potIndex: pi,
          seats: seats,
          lines: lines,
          amounts: amounts,
          spotlight: stageSpot,
        ),
      );
    }
    if (stages.isNotEmpty && (!contested || stages.length == 1)) {
      // Everything at once, coloured as the main pot.
      final merged = <int, int>{};
      for (final st in stages) {
        for (final e in st.amounts.entries) {
          merged[e.key] = (merged[e.key] ?? 0) + e.value;
        }
      }
      final all = PotStage(
        potIndex: 0,
        seats: {for (final st in stages) ...st.seats},
        lines: [for (final st in stages.reversed) ...st.lines],
        amounts: merged,
        spotlight: stages.last.spotlight,
      );
      stages
        ..clear()
        ..add(all);
    }
    state = state.copyWith(
      log: List.unmodifiable(trimmed),
      revealed: revealed,
      best: best,
      winners: winners,
      shown: shown,
      winnerLines: winnerLines,
      // The batch may carry pot_awarded before hand_ended, and a hand
      // revealed during a run-out was described on an incomplete board, so
      // the spotlight always takes the latest best five known for its seat.
      spotlight: spotlight != null && best[spotlight.seat] != null
          ? Spotlight(
              seat: spotlight.seat,
              name: spotlight.name,
              cards: best[spotlight.seat]!,
              description: spotlight.description,
              winner: spotlight.winner,
            )
          : spotlight,
      clearSpotlight: clearSpotlight && spotlight == null,
      clearWinnerPot: clearWinnerPot,
      winnerAmounts: winnerAmounts,
    );
    if (stages.isNotEmpty) _startStages(stages);
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
  Future<void> setVoice(String state, {bool camera = false}) => _send(
    ClientMessage.voice(
      VoicePayload(state: state, camera: camera ? true : null),
    ),
  );
  Future<void> setStraddle(bool on) =>
      _send(ClientMessage.straddle(StraddlePayload(on: on)));
  Future<void> runTwice(bool agree) =>
      _send(ClientMessage.runTwice(RunTwicePayload(agree: agree)));

  /// Relays one WebRTC signal and reports a refusal to the caller instead of
  /// raising the table's error banner: a rejected signal (an SDP the server
  /// will not carry, say) concerns the voice chat alone.
  Future<ServerError?> sendVoiceSignal(
    String to,
    String kind,
    String data,
  ) async {
    final client = _client;
    if (client == null) {
      return const ServerError('disconnected', 'not connected');
    }
    try {
      await client.send(
        ClientMessage.voiceSignal(VoiceSignal(to: to, kind: kind, data: data)),
      );
      return null;
    } on ServerError catch (e) {
      return e;
    }
  }

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
