import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';
import 'protocol_error.dart';

part 'messages.freezed.dart';

/// Every message the server can push. Decode with [decodeServerMessage].
@freezed
sealed class ServerMessage with _$ServerMessage {
  const factory ServerMessage.welcome(Welcome payload) = WelcomeMessage;
  const factory ServerMessage.snapshot(Snapshot payload) = SnapshotMessage;
  const factory ServerMessage.events(EventsPayload payload) = EventsMessage;
  const factory ServerMessage.chat(ChatMessage payload) = ChatServerMessage;
  const factory ServerMessage.chatHistory(ChatHistory payload) =
      ChatHistoryMessage;
  const factory ServerMessage.chatRemoved(ChatRemoved payload) =
      ChatRemovedMessage;
  const factory ServerMessage.ack(Ack payload) = AckMessage;
  const factory ServerMessage.error(ErrorPayload payload) = ErrorMessage;
  const factory ServerMessage.kicked(Kicked payload) = KickedMessage;
  const factory ServerMessage.tableEnded(TableEnded payload) =
      TableEndedMessage;
  const factory ServerMessage.serverRestarting() = ServerRestartingMessage;
  const factory ServerMessage.pong(Pong payload) = PongMessage;
  const factory ServerMessage.voiceSignal(VoiceSignal payload) =
      VoiceSignalMessage;
  const factory ServerMessage.phrase(PhrasePayload payload) = PhraseMessage;
}

/// Every message the client can send. [toEnvelope] adds the command id.
@freezed
sealed class ClientMessage with _$ClientMessage {
  const factory ClientMessage.hello(Hello payload) = HelloMessage;
  const factory ClientMessage.action(ActionPayload payload) = ActionMessage;
  const factory ClientMessage.sitOut() = SitOutMessage;
  const factory ClientMessage.sitIn() = SitInMessage;
  const factory ClientMessage.rebuy() = RebuyMessage;
  const factory ClientMessage.leave() = LeaveMessage;
  const factory ClientMessage.showCards(ShowCardsPayload payload) =
      ShowCardsMessage;
  const factory ClientMessage.preAction(PreActionPayload payload) =
      PreActionMessage;
  const factory ClientMessage.rabbitHunt() = RabbitHuntMessage;
  const factory ClientMessage.changeSeat(ChangeSeatPayload payload) =
      ChangeSeatMessage;
  const factory ClientMessage.voice(VoicePayload payload) = VoiceMessage;
  const factory ClientMessage.voiceSignal(VoiceSignal payload) =
      VoiceSignalClientMessage;
  const factory ClientMessage.say(SayPayload payload) = SayMessage;
  const factory ClientMessage.chat(ChatPayload payload) = ChatClientMessage;
  const factory ClientMessage.ping() = PingMessage;
}

/// Wire type names.
class MessageTypes {
  const MessageTypes._();
  static const hello = 'hello';
  static const action = 'action';
  static const sitOut = 'sit_out';
  static const sitIn = 'sit_in';
  static const rebuy = 'rebuy';
  static const leave = 'leave';
  static const showCards = 'show_cards';
  static const preAction = 'pre_action';
  static const rabbitHunt = 'rabbit_hunt';
  static const changeSeat = 'change_seat';
  static const voice = 'voice';
  static const voiceSignal = 'voice_signal';
  static const say = 'say';
  static const chat = 'chat';
  static const ping = 'ping';
  static const welcome = 'welcome';
  static const snapshot = 'snapshot';
  static const events = 'events';
  static const chatHistory = 'chat_history';
  static const chatRemoved = 'chat_removed';
  static const ack = 'ack';
  static const error = 'error';
  static const kicked = 'kicked';
  static const tableEnded = 'table_ended';
  static const serverRestarting = 'server_restarting';
  static const pong = 'pong';
  static const phrase = 'phrase';
}

Map<String, dynamic> _payload(Envelope env) => env.payload ?? const {};

/// Decodes a server envelope; throws [ProtocolError] on unknown types or
/// malformed payloads.
ServerMessage decodeServerMessage(Envelope env) {
  try {
    switch (env.type) {
      case MessageTypes.welcome:
        return ServerMessage.welcome(Welcome.fromJson(_payload(env)));
      case MessageTypes.snapshot:
        return ServerMessage.snapshot(Snapshot.fromJson(_payload(env)));
      case MessageTypes.events:
        return ServerMessage.events(EventsPayload.fromJson(_payload(env)));
      case MessageTypes.chat:
        return ServerMessage.chat(ChatMessage.fromJson(_payload(env)));
      case MessageTypes.chatHistory:
        return ServerMessage.chatHistory(ChatHistory.fromJson(_payload(env)));
      case MessageTypes.chatRemoved:
        return ServerMessage.chatRemoved(ChatRemoved.fromJson(_payload(env)));
      case MessageTypes.ack:
        return ServerMessage.ack(Ack.fromJson(_payload(env)));
      case MessageTypes.error:
        return ServerMessage.error(ErrorPayload.fromJson(_payload(env)));
      case MessageTypes.kicked:
        return ServerMessage.kicked(Kicked.fromJson(_payload(env)));
      case MessageTypes.tableEnded:
        return ServerMessage.tableEnded(TableEnded.fromJson(_payload(env)));
      case MessageTypes.serverRestarting:
        return const ServerMessage.serverRestarting();
      case MessageTypes.pong:
        return ServerMessage.pong(Pong.fromJson(_payload(env)));
      case MessageTypes.voiceSignal:
        return ServerMessage.voiceSignal(VoiceSignal.fromJson(_payload(env)));
      case MessageTypes.phrase:
        return ServerMessage.phrase(PhrasePayload.fromJson(_payload(env)));
    }
  } on ProtocolError {
    rethrow;
  } catch (e) {
    throw ProtocolError('malformed payload: $e', type: env.type);
  }
  throw ProtocolError('unknown message type', type: env.type);
}

/// Re-encodes a server message into its envelope (used by tests).
Envelope encodeServerMessage(ServerMessage msg) => switch (msg) {
  WelcomeMessage(:final payload) => Envelope(
    type: MessageTypes.welcome,
    payload: payload.toJson(),
  ),
  SnapshotMessage(:final payload) => Envelope(
    type: MessageTypes.snapshot,
    payload: payload.toJson(),
  ),
  EventsMessage(:final payload) => Envelope(
    type: MessageTypes.events,
    payload: payload.toJson(),
  ),
  ChatServerMessage(:final payload) => Envelope(
    type: MessageTypes.chat,
    payload: payload.toJson(),
  ),
  ChatHistoryMessage(:final payload) => Envelope(
    type: MessageTypes.chatHistory,
    payload: payload.toJson(),
  ),
  ChatRemovedMessage(:final payload) => Envelope(
    type: MessageTypes.chatRemoved,
    payload: payload.toJson(),
  ),
  AckMessage(:final payload) => Envelope(
    type: MessageTypes.ack,
    payload: payload.toJson(),
  ),
  ErrorMessage(:final payload) => Envelope(
    type: MessageTypes.error,
    payload: payload.toJson(),
  ),
  KickedMessage(:final payload) => Envelope(
    type: MessageTypes.kicked,
    payload: payload.toJson(),
  ),
  TableEndedMessage(:final payload) => Envelope(
    type: MessageTypes.tableEnded,
    payload: payload.toJson(),
  ),
  ServerRestartingMessage() => const Envelope(
    type: MessageTypes.serverRestarting,
    payload: {},
  ),
  PongMessage(:final payload) => Envelope(
    type: MessageTypes.pong,
    payload: payload.toJson(),
  ),
  VoiceSignalMessage(:final payload) => Envelope(
    type: MessageTypes.voiceSignal,
    payload: payload.toJson(),
  ),
  PhraseMessage(:final payload) => Envelope(
    type: MessageTypes.phrase,
    payload: payload.toJson(),
  ),
};

/// Decodes a client envelope (used by tests and fixtures).
ClientMessage decodeClientMessage(Envelope env) {
  try {
    switch (env.type) {
      case MessageTypes.hello:
        return ClientMessage.hello(Hello.fromJson(_payload(env)));
      case MessageTypes.action:
        return ClientMessage.action(ActionPayload.fromJson(_payload(env)));
      case MessageTypes.sitOut:
        return const ClientMessage.sitOut();
      case MessageTypes.sitIn:
        return const ClientMessage.sitIn();
      case MessageTypes.rebuy:
        return const ClientMessage.rebuy();
      case MessageTypes.leave:
        return const ClientMessage.leave();
      case MessageTypes.showCards:
        return ClientMessage.showCards(
          ShowCardsPayload.fromJson(_payload(env)),
        );
      case MessageTypes.preAction:
        return ClientMessage.preAction(
          PreActionPayload.fromJson(_payload(env)),
        );
      case MessageTypes.rabbitHunt:
        return const ClientMessage.rabbitHunt();
      case MessageTypes.changeSeat:
        return ClientMessage.changeSeat(
          ChangeSeatPayload.fromJson(_payload(env)),
        );
      case MessageTypes.voice:
        return ClientMessage.voice(VoicePayload.fromJson(_payload(env)));
      case MessageTypes.voiceSignal:
        return ClientMessage.voiceSignal(VoiceSignal.fromJson(_payload(env)));
      case MessageTypes.say:
        return ClientMessage.say(SayPayload.fromJson(_payload(env)));
      case MessageTypes.chat:
        return ClientMessage.chat(ChatPayload.fromJson(_payload(env)));
      case MessageTypes.ping:
        return const ClientMessage.ping();
    }
  } on ProtocolError {
    rethrow;
  } catch (e) {
    throw ProtocolError('malformed payload: $e', type: env.type);
  }
  throw ProtocolError('unknown message type', type: env.type);
}

/// Encodes a client message with the given command id.
Envelope encodeClientMessage(ClientMessage msg, {String? id}) => switch (msg) {
  HelloMessage(:final payload) => Envelope(
    type: MessageTypes.hello,
    id: id,
    payload: payload.toJson(),
  ),
  ActionMessage(:final payload) => Envelope(
    type: MessageTypes.action,
    id: id,
    payload: payload.toJson(),
  ),
  SitOutMessage() => Envelope(type: MessageTypes.sitOut, id: id, payload: {}),
  SitInMessage() => Envelope(type: MessageTypes.sitIn, id: id, payload: {}),
  RebuyMessage() => Envelope(type: MessageTypes.rebuy, id: id, payload: {}),
  LeaveMessage() => Envelope(type: MessageTypes.leave, id: id, payload: {}),
  ShowCardsMessage(:final payload) => Envelope(
    type: MessageTypes.showCards,
    id: id,
    payload: payload.toJson(),
  ),
  PreActionMessage(:final payload) => Envelope(
    type: MessageTypes.preAction,
    id: id,
    payload: payload.toJson(),
  ),
  RabbitHuntMessage() => Envelope(
    type: MessageTypes.rabbitHunt,
    id: id,
    payload: {},
  ),
  ChangeSeatMessage(:final payload) => Envelope(
    type: MessageTypes.changeSeat,
    id: id,
    payload: payload.toJson(),
  ),
  VoiceMessage(:final payload) => Envelope(
    type: MessageTypes.voice,
    id: id,
    payload: payload.toJson(),
  ),
  VoiceSignalClientMessage(:final payload) => Envelope(
    type: MessageTypes.voiceSignal,
    id: id,
    payload: payload.toJson(),
  ),
  SayMessage(:final payload) => Envelope(
    type: MessageTypes.say,
    id: id,
    payload: payload.toJson(),
  ),
  ChatClientMessage(:final payload) => Envelope(
    type: MessageTypes.chat,
    id: id,
    payload: payload.toJson(),
  ),
  PingMessage() => Envelope(type: MessageTypes.ping, id: id, payload: {}),
};
