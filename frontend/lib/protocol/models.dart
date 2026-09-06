import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Protocol version sent in hello.
const int protocolVersion = 1;

/// Close codes sent by the server.
class CloseCodes {
  const CloseCodes._();
  static const int badToken = 4001;
  static const int unsupportedVersion = 4002;
  static const int tableGone = 4003;
  static const int replaced = 4004;
  static const int kicked = 4005;
  static const int policy = 1008;

  /// Codes after which the client must not reconnect automatically.
  static bool isTerminal(int? code) =>
      code == badToken ||
      code == unsupportedVersion ||
      code == tableGone ||
      code == replaced ||
      code == kicked;
}

// ---- envelope --------------------------------------------------------------------------

@freezed
abstract class Envelope with _$Envelope {
  const factory Envelope({
    required String type,
    @JsonKey(includeIfNull: false) String? id,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? payload,
  }) = _Envelope;

  factory Envelope.fromJson(Map<String, dynamic> json) =>
      _$EnvelopeFromJson(json);
}

// ---- client payloads ---------------------------------------------------------------------

/// show_cards payload: which cards to show ("both", "first", "second").
@freezed
abstract class ShowCardsPayload with _$ShowCardsPayload {
  const factory ShowCardsPayload({
    @JsonKey(includeIfNull: false) String? cards,
  }) = _ShowCardsPayload;
  factory ShowCardsPayload.fromJson(Map<String, dynamic> json) =>
      _$ShowCardsPayloadFromJson(json);
}

/// voice payload: the sender's voice-chat state ("off", "on", "muted").
@freezed
abstract class VoicePayload with _$VoicePayload {
  const factory VoicePayload({
    required String state,
    @JsonKey(includeIfNull: false) bool? camera,
  }) = _VoicePayload;
  factory VoicePayload.fromJson(Map<String, dynamic> json) =>
      _$VoicePayloadFromJson(json);
}

/// One WebRTC setup message relayed by the server (opaque data).
@freezed
abstract class VoiceSignal with _$VoiceSignal {
  const factory VoiceSignal({
    @JsonKey(includeIfNull: false) String? to,
    @JsonKey(includeIfNull: false) String? from,
    required String kind,
    required String data,
  }) = _VoiceSignal;
  factory VoiceSignal.fromJson(Map<String, dynamic> json) =>
      _$VoiceSignalFromJson(json);
}

/// straddle payload: arm or disarm the straddle.
@freezed
abstract class StraddlePayload with _$StraddlePayload {
  const factory StraddlePayload({required bool on}) = _StraddlePayload;
  factory StraddlePayload.fromJson(Map<String, dynamic> json) =>
      _$StraddlePayloadFromJson(json);
}

/// run_twice payload: the answer to the run-it-twice vote.
@freezed
abstract class RunTwicePayload with _$RunTwicePayload {
  const factory RunTwicePayload({required bool agree}) = _RunTwicePayload;
  factory RunTwicePayload.fromJson(Map<String, dynamic> json) =>
      _$RunTwicePayloadFromJson(json);
}

/// say payload: one of the predefined quick phrases.
@freezed
abstract class SayPayload with _$SayPayload {
  const factory SayPayload({required String phrase}) = _SayPayload;
  factory SayPayload.fromJson(Map<String, dynamic> json) =>
      _$SayPayloadFromJson(json);
}

/// phrase push: a quick phrase shown next to the player's avatar.
@freezed
abstract class PhrasePayload with _$PhrasePayload {
  const factory PhrasePayload({
    required int seat,
    required String name,
    required String phrase,
    required int ts,
  }) = _PhrasePayload;
  factory PhrasePayload.fromJson(Map<String, dynamic> json) =>
      _$PhrasePayloadFromJson(json);
}

/// change_seat payload: the free seat to move to at the next deal.
@freezed
abstract class ChangeSeatPayload with _$ChangeSeatPayload {
  const factory ChangeSeatPayload({required int seat}) = _ChangeSeatPayload;
  factory ChangeSeatPayload.fromJson(Map<String, dynamic> json) =>
      _$ChangeSeatPayloadFromJson(json);
}

/// pre_action payload: "none", "check_fold" or "call_any".
@freezed
abstract class PreActionPayload with _$PreActionPayload {
  const factory PreActionPayload({required String kind}) = _PreActionPayload;
  factory PreActionPayload.fromJson(Map<String, dynamic> json) =>
      _$PreActionPayloadFromJson(json);
}

@freezed
abstract class Hello with _$Hello {
  const factory Hello({
    required int v,
    required String token,
    @JsonKey(includeIfNull: false) String? adminToken,
  }) = _Hello;
  factory Hello.fromJson(Map<String, dynamic> json) => _$HelloFromJson(json);
}

@freezed
abstract class ActionPayload with _$ActionPayload {
  const factory ActionPayload({
    required String kind,
    @JsonKey(includeIfNull: false) int? amount,
  }) = _ActionPayload;
  factory ActionPayload.fromJson(Map<String, dynamic> json) =>
      _$ActionPayloadFromJson(json);
}

@freezed
abstract class ChatPayload with _$ChatPayload {
  const factory ChatPayload({required String text}) = _ChatPayload;
  factory ChatPayload.fromJson(Map<String, dynamic> json) =>
      _$ChatPayloadFromJson(json);
}

// ---- server payloads ---------------------------------------------------------------------

@freezed
abstract class YouIdentity with _$YouIdentity {
  const factory YouIdentity({
    required String role,
    @JsonKey(includeIfNull: false) String? playerId,
    @JsonKey(includeIfNull: false) int? seat,
  }) = _YouIdentity;
  factory YouIdentity.fromJson(Map<String, dynamic> json) =>
      _$YouIdentityFromJson(json);
}

@freezed
abstract class Welcome with _$Welcome {
  const factory Welcome({
    required YouIdentity you,
    required Snapshot snapshot,
  }) = _Welcome;
  factory Welcome.fromJson(Map<String, dynamic> json) =>
      _$WelcomeFromJson(json);
}

@freezed
abstract class Snapshot with _$Snapshot {
  const factory Snapshot({
    required int serverTs,
    required TableInfo table,
    required List<SeatView> seats,
    required HandView? hand,
    required You you,
    required List<LeaderboardEntry> leaderboard,
    required int spectators,
    @JsonKey(includeIfNull: false) List<String>? spectatorNames,
  }) = _Snapshot;
  factory Snapshot.fromJson(Map<String, dynamic> json) =>
      _$SnapshotFromJson(json);
}

@freezed
abstract class TableInfo with _$TableInfo {
  const factory TableInfo({
    required String id,
    required String name,
    required String state,
    required int handNumber,
    required PublicSettings settings,
    @JsonKey(includeIfNull: false) int? nextBlindsUpTs,
    @JsonKey(includeIfNull: false) int? nextHandTs,
  }) = _TableInfo;
  factory TableInfo.fromJson(Map<String, dynamic> json) =>
      _$TableInfoFromJson(json);
}

@freezed
abstract class PublicSettings with _$PublicSettings {
  const factory PublicSettings({
    required int smallBlind,
    required int bigBlind,
    required int ante,
    required int turnTime,
    required int maxPlayers,
    required int startMoney,
    required String joinPolicy,
    required bool allowRebuy,
    required String showdownReveal,
    required bool chatEnabled,
    required bool spectatorChat,
    required bool requiresPassword,
    required bool allowRabbitHunt,
    required int blindsUpMinutes,
    required int blindsUpPercent,
    @Default(0) int timeBankSeconds,
    @Default(1) int timeBankRefillSeconds,
    @Default(false) bool allowStraddle,
    @Default(false) bool runItTwice,
  }) = _PublicSettings;
  factory PublicSettings.fromJson(Map<String, dynamic> json) =>
      _$PublicSettingsFromJson(json);
}

@freezed
abstract class SeatView with _$SeatView {
  const factory SeatView({required int seat, required PlayerView? player}) =
      _SeatView;
  factory SeatView.fromJson(Map<String, dynamic> json) =>
      _$SeatViewFromJson(json);
}

@freezed
abstract class PlayerView with _$PlayerView {
  const factory PlayerView({
    required String id,
    required String name,
    required int avatar,
    @Default('off') String voice,
    @JsonKey(includeIfNull: false) bool? muted,
    @JsonKey(includeIfNull: false) bool? mucked,
    @JsonKey(includeIfNull: false) bool? camera,
    @JsonKey(includeIfNull: false) double? equity,
    @JsonKey(includeIfNull: false) int? timeBank,
    @JsonKey(includeIfNull: false) int? place,
    required int stack,
    required String status,
    required bool connected,
    required bool inHand,
    required bool folded,
    required bool allIn,
    required int betThisStreet,
    required int totalBet,
    @JsonKey(includeIfNull: false) List<String>? holeCards,
    required LastAction? lastAction,

    /// A fully revealed hand described against the current board (follows
    /// every run-out street); absent for hidden hands.
    @JsonKey(includeIfNull: false) String? handDescription,
    @JsonKey(includeIfNull: false) List<String>? bestCards,
  }) = _PlayerView;
  factory PlayerView.fromJson(Map<String, dynamic> json) =>
      _$PlayerViewFromJson(json);
}

@freezed
abstract class LastAction with _$LastAction {
  const factory LastAction({required String kind, required int amount}) =
      _LastAction;
  factory LastAction.fromJson(Map<String, dynamic> json) =>
      _$LastActionFromJson(json);
}

@freezed
abstract class HandView with _$HandView {
  const factory HandView({
    required String street,
    required List<String> board,
    required int buttonSeat,
    required int sbSeat,
    required int bbSeat,
    required int? toActSeat,
    required int? deadlineTs,
    required int currentBet,
    required int minRaiseTo,
    required List<PotView> pots,
    required String phase,
    @JsonKey(includeIfNull: false) List<String>? rabbitCards,
    @JsonKey(includeIfNull: false) int? phaseEndsTs,
    @JsonKey(includeIfNull: false) List<String>? board2,
    @JsonKey(includeIfNull: false) int? straddleSeat,
    @JsonKey(includeIfNull: false) bool? timeBankActive,
    @JsonKey(includeIfNull: false) bool? runTwice,
    @JsonKey(includeIfNull: false) int? runTwiceEndsTs,
  }) = _HandView;
  factory HandView.fromJson(Map<String, dynamic> json) =>
      _$HandViewFromJson(json);
}

@freezed
abstract class PotView with _$PotView {
  const factory PotView({
    required int amount,
    required List<int> eligibleSeats,
  }) = _PotView;
  factory PotView.fromJson(Map<String, dynamic> json) =>
      _$PotViewFromJson(json);
}

@freezed
abstract class You with _$You {
  const factory You({
    required String role,
    required bool isAdmin,
    @JsonKey(includeIfNull: false) String? playerId,
    @JsonKey(includeIfNull: false) int? seat,
    required OptionsView? options,
    required String handDescription,
    required bool canRebuy,
    required bool canShowCards,
    required String preAction,
    @JsonKey(includeIfNull: false) List<String>? bestCards,
    required bool canRabbitHunt,
    @JsonKey(includeIfNull: false) int? pendingSeat,
    @Default(false) bool canChangeSeat,
    @JsonKey(includeIfNull: false) bool? straddle,
    @JsonKey(includeIfNull: false) bool? canRunTwice,
    @JsonKey(includeIfNull: false) bool? runTwiceVote,
  }) = _You;
  factory You.fromJson(Map<String, dynamic> json) => _$YouFromJson(json);
}

@freezed
abstract class OptionsView with _$OptionsView {
  const factory OptionsView({
    required bool fold,
    required bool check,
    required int call,
    required RaiseView? raise,
    required int allIn,
  }) = _OptionsView;
  factory OptionsView.fromJson(Map<String, dynamic> json) =>
      _$OptionsViewFromJson(json);
}

@freezed
abstract class RaiseView with _$RaiseView {
  const factory RaiseView({required int min, required int max}) = _RaiseView;
  factory RaiseView.fromJson(Map<String, dynamic> json) =>
      _$RaiseViewFromJson(json);
}

@freezed
abstract class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String name,
    required int stack,
    required int net,
    required int handsWon,
    required int biggestPot,
    @JsonKey(includeIfNull: false) int? handsPlayed,
    @JsonKey(includeIfNull: false) int? vpipHands,
    @JsonKey(includeIfNull: false) int? showdowns,
    @JsonKey(includeIfNull: false) int? showdownsWon,
    @JsonKey(includeIfNull: false) int? place,
  }) = _LeaderboardEntry;
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

@freezed
abstract class EventsPayload with _$EventsPayload {
  const factory EventsPayload({
    required int handNumber,
    required List<GameEvent> events,
  }) = _EventsPayload;
  factory EventsPayload.fromJson(Map<String, dynamic> json) =>
      _$EventsPayloadFromJson(json);
}

/// One hand or table event. Only the fields relevant to [kind] are set.
@freezed
abstract class GameEvent with _$GameEvent {
  const factory GameEvent({
    required int seq,
    required int ts,
    required String kind,
    @JsonKey(includeIfNull: false) int? seat,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) int? amount,
    @JsonKey(includeIfNull: false) int? delta,
    @JsonKey(includeIfNull: false) bool? allIn,
    @JsonKey(includeIfNull: false) String? action,
    @JsonKey(includeIfNull: false) String? blind,
    @JsonKey(includeIfNull: false) String? resolvedAs,
    @JsonKey(includeIfNull: false) String? street,
    @JsonKey(includeIfNull: false) List<String>? cards,
    @JsonKey(includeIfNull: false) List<PotView>? pots,
    @JsonKey(includeIfNull: false) List<Reveal>? reveals,
    @JsonKey(includeIfNull: false) int? potIndex,
    @JsonKey(includeIfNull: false) int? board,
    @JsonKey(includeIfNull: false) String? description,
    @JsonKey(includeIfNull: false) HandResults? results,
    @JsonKey(includeIfNull: false) String? reason,
    @JsonKey(includeIfNull: false) List<String>? fields,
    @JsonKey(includeIfNull: false) int? buttonSeat,
    @JsonKey(includeIfNull: false) int? sbSeat,
    @JsonKey(includeIfNull: false) int? bbSeat,
    @JsonKey(includeIfNull: false) Blinds? blinds,
    @JsonKey(includeIfNull: false) int? ante,
    @JsonKey(includeIfNull: false) Map<String, int>? stacks,
  }) = _GameEvent;
  factory GameEvent.fromJson(Map<String, dynamic> json) =>
      _$GameEventFromJson(json);
}

@freezed
abstract class Blinds with _$Blinds {
  const factory Blinds({required int small, required int big}) = _Blinds;
  factory Blinds.fromJson(Map<String, dynamic> json) => _$BlindsFromJson(json);
}

@freezed
abstract class Reveal with _$Reveal {
  const factory Reveal({
    required int seat,
    required List<String> cards,
    required String description,
    @JsonKey(includeIfNull: false) List<String>? best,
  }) = _Reveal;
  factory Reveal.fromJson(Map<String, dynamic> json) => _$RevealFromJson(json);
}

@freezed
abstract class HandResults with _$HandResults {
  const factory HandResults({
    required List<PotResult> pots,
    required Map<String, SeatResult> seats,
  }) = _HandResults;
  factory HandResults.fromJson(Map<String, dynamic> json) =>
      _$HandResultsFromJson(json);
}

@freezed
abstract class PotResult with _$PotResult {
  const factory PotResult({
    required int index,
    required int amount,
    required List<PotWinner> winners,
    required String description,
  }) = _PotResult;
  factory PotResult.fromJson(Map<String, dynamic> json) =>
      _$PotResultFromJson(json);
}

@freezed
abstract class PotWinner with _$PotWinner {
  const factory PotWinner({required int seat, required int amount}) =
      _PotWinner;
  factory PotWinner.fromJson(Map<String, dynamic> json) =>
      _$PotWinnerFromJson(json);
}

@freezed
abstract class SeatResult with _$SeatResult {
  const factory SeatResult({
    required int net,
    required int won,
    required bool folded,
    required bool revealed,
    @JsonKey(includeIfNull: false) List<String>? cards,
    @JsonKey(includeIfNull: false) String? description,
    @JsonKey(includeIfNull: false) List<String>? best,
  }) = _SeatResult;
  factory SeatResult.fromJson(Map<String, dynamic> json) =>
      _$SeatResultFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    required String authorKind,
    required String authorName,
    required String text,
    required int ts,
  }) = _ChatMessage;
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

@freezed
abstract class ChatHistory with _$ChatHistory {
  const factory ChatHistory({required List<ChatMessage> messages}) =
      _ChatHistory;
  factory ChatHistory.fromJson(Map<String, dynamic> json) =>
      _$ChatHistoryFromJson(json);
}

@freezed
abstract class ChatRemoved with _$ChatRemoved {
  const factory ChatRemoved({required int id}) = _ChatRemoved;
  factory ChatRemoved.fromJson(Map<String, dynamic> json) =>
      _$ChatRemovedFromJson(json);
}

@freezed
abstract class Ack with _$Ack {
  const factory Ack({required String id}) = _Ack;
  factory Ack.fromJson(Map<String, dynamic> json) => _$AckFromJson(json);
}

@freezed
abstract class ErrorPayload with _$ErrorPayload {
  const factory ErrorPayload({
    @JsonKey(includeIfNull: false) String? id,
    required String code,
    required String message,
  }) = _ErrorPayload;
  factory ErrorPayload.fromJson(Map<String, dynamic> json) =>
      _$ErrorPayloadFromJson(json);
}

@freezed
abstract class Kicked with _$Kicked {
  const factory Kicked({required String reason}) = _Kicked;
  factory Kicked.fromJson(Map<String, dynamic> json) => _$KickedFromJson(json);
}

@freezed
abstract class TableEnded with _$TableEnded {
  const factory TableEnded({required List<LeaderboardEntry> finalLeaderboard}) =
      _TableEnded;
  factory TableEnded.fromJson(Map<String, dynamic> json) =>
      _$TableEndedFromJson(json);
}

@freezed
abstract class Pong with _$Pong {
  const factory Pong({required int serverTs}) = _Pong;
  factory Pong.fromJson(Map<String, dynamic> json) => _$PongFromJson(json);
}
