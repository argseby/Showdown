// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServerMessage {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ServerMessage()';
}


}

/// @nodoc
class $ServerMessageCopyWith<$Res>  {
$ServerMessageCopyWith(ServerMessage _, $Res Function(ServerMessage) __);
}


/// Adds pattern-matching-related methods to [ServerMessage].
extension ServerMessagePatterns on ServerMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WelcomeMessage value)?  welcome,TResult Function( SnapshotMessage value)?  snapshot,TResult Function( EventsMessage value)?  events,TResult Function( ChatServerMessage value)?  chat,TResult Function( ChatHistoryMessage value)?  chatHistory,TResult Function( ChatRemovedMessage value)?  chatRemoved,TResult Function( AckMessage value)?  ack,TResult Function( ErrorMessage value)?  error,TResult Function( KickedMessage value)?  kicked,TResult Function( TableEndedMessage value)?  tableEnded,TResult Function( ServerRestartingMessage value)?  serverRestarting,TResult Function( PongMessage value)?  pong,TResult Function( VoiceSignalMessage value)?  voiceSignal,TResult Function( PhraseMessage value)?  phrase,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WelcomeMessage() when welcome != null:
return welcome(_that);case SnapshotMessage() when snapshot != null:
return snapshot(_that);case EventsMessage() when events != null:
return events(_that);case ChatServerMessage() when chat != null:
return chat(_that);case ChatHistoryMessage() when chatHistory != null:
return chatHistory(_that);case ChatRemovedMessage() when chatRemoved != null:
return chatRemoved(_that);case AckMessage() when ack != null:
return ack(_that);case ErrorMessage() when error != null:
return error(_that);case KickedMessage() when kicked != null:
return kicked(_that);case TableEndedMessage() when tableEnded != null:
return tableEnded(_that);case ServerRestartingMessage() when serverRestarting != null:
return serverRestarting(_that);case PongMessage() when pong != null:
return pong(_that);case VoiceSignalMessage() when voiceSignal != null:
return voiceSignal(_that);case PhraseMessage() when phrase != null:
return phrase(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WelcomeMessage value)  welcome,required TResult Function( SnapshotMessage value)  snapshot,required TResult Function( EventsMessage value)  events,required TResult Function( ChatServerMessage value)  chat,required TResult Function( ChatHistoryMessage value)  chatHistory,required TResult Function( ChatRemovedMessage value)  chatRemoved,required TResult Function( AckMessage value)  ack,required TResult Function( ErrorMessage value)  error,required TResult Function( KickedMessage value)  kicked,required TResult Function( TableEndedMessage value)  tableEnded,required TResult Function( ServerRestartingMessage value)  serverRestarting,required TResult Function( PongMessage value)  pong,required TResult Function( VoiceSignalMessage value)  voiceSignal,required TResult Function( PhraseMessage value)  phrase,}){
final _that = this;
switch (_that) {
case WelcomeMessage():
return welcome(_that);case SnapshotMessage():
return snapshot(_that);case EventsMessage():
return events(_that);case ChatServerMessage():
return chat(_that);case ChatHistoryMessage():
return chatHistory(_that);case ChatRemovedMessage():
return chatRemoved(_that);case AckMessage():
return ack(_that);case ErrorMessage():
return error(_that);case KickedMessage():
return kicked(_that);case TableEndedMessage():
return tableEnded(_that);case ServerRestartingMessage():
return serverRestarting(_that);case PongMessage():
return pong(_that);case VoiceSignalMessage():
return voiceSignal(_that);case PhraseMessage():
return phrase(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WelcomeMessage value)?  welcome,TResult? Function( SnapshotMessage value)?  snapshot,TResult? Function( EventsMessage value)?  events,TResult? Function( ChatServerMessage value)?  chat,TResult? Function( ChatHistoryMessage value)?  chatHistory,TResult? Function( ChatRemovedMessage value)?  chatRemoved,TResult? Function( AckMessage value)?  ack,TResult? Function( ErrorMessage value)?  error,TResult? Function( KickedMessage value)?  kicked,TResult? Function( TableEndedMessage value)?  tableEnded,TResult? Function( ServerRestartingMessage value)?  serverRestarting,TResult? Function( PongMessage value)?  pong,TResult? Function( VoiceSignalMessage value)?  voiceSignal,TResult? Function( PhraseMessage value)?  phrase,}){
final _that = this;
switch (_that) {
case WelcomeMessage() when welcome != null:
return welcome(_that);case SnapshotMessage() when snapshot != null:
return snapshot(_that);case EventsMessage() when events != null:
return events(_that);case ChatServerMessage() when chat != null:
return chat(_that);case ChatHistoryMessage() when chatHistory != null:
return chatHistory(_that);case ChatRemovedMessage() when chatRemoved != null:
return chatRemoved(_that);case AckMessage() when ack != null:
return ack(_that);case ErrorMessage() when error != null:
return error(_that);case KickedMessage() when kicked != null:
return kicked(_that);case TableEndedMessage() when tableEnded != null:
return tableEnded(_that);case ServerRestartingMessage() when serverRestarting != null:
return serverRestarting(_that);case PongMessage() when pong != null:
return pong(_that);case VoiceSignalMessage() when voiceSignal != null:
return voiceSignal(_that);case PhraseMessage() when phrase != null:
return phrase(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Welcome payload)?  welcome,TResult Function( Snapshot payload)?  snapshot,TResult Function( EventsPayload payload)?  events,TResult Function( ChatMessage payload)?  chat,TResult Function( ChatHistory payload)?  chatHistory,TResult Function( ChatRemoved payload)?  chatRemoved,TResult Function( Ack payload)?  ack,TResult Function( ErrorPayload payload)?  error,TResult Function( Kicked payload)?  kicked,TResult Function( TableEnded payload)?  tableEnded,TResult Function()?  serverRestarting,TResult Function( Pong payload)?  pong,TResult Function( VoiceSignal payload)?  voiceSignal,TResult Function( PhrasePayload payload)?  phrase,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WelcomeMessage() when welcome != null:
return welcome(_that.payload);case SnapshotMessage() when snapshot != null:
return snapshot(_that.payload);case EventsMessage() when events != null:
return events(_that.payload);case ChatServerMessage() when chat != null:
return chat(_that.payload);case ChatHistoryMessage() when chatHistory != null:
return chatHistory(_that.payload);case ChatRemovedMessage() when chatRemoved != null:
return chatRemoved(_that.payload);case AckMessage() when ack != null:
return ack(_that.payload);case ErrorMessage() when error != null:
return error(_that.payload);case KickedMessage() when kicked != null:
return kicked(_that.payload);case TableEndedMessage() when tableEnded != null:
return tableEnded(_that.payload);case ServerRestartingMessage() when serverRestarting != null:
return serverRestarting();case PongMessage() when pong != null:
return pong(_that.payload);case VoiceSignalMessage() when voiceSignal != null:
return voiceSignal(_that.payload);case PhraseMessage() when phrase != null:
return phrase(_that.payload);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Welcome payload)  welcome,required TResult Function( Snapshot payload)  snapshot,required TResult Function( EventsPayload payload)  events,required TResult Function( ChatMessage payload)  chat,required TResult Function( ChatHistory payload)  chatHistory,required TResult Function( ChatRemoved payload)  chatRemoved,required TResult Function( Ack payload)  ack,required TResult Function( ErrorPayload payload)  error,required TResult Function( Kicked payload)  kicked,required TResult Function( TableEnded payload)  tableEnded,required TResult Function()  serverRestarting,required TResult Function( Pong payload)  pong,required TResult Function( VoiceSignal payload)  voiceSignal,required TResult Function( PhrasePayload payload)  phrase,}) {final _that = this;
switch (_that) {
case WelcomeMessage():
return welcome(_that.payload);case SnapshotMessage():
return snapshot(_that.payload);case EventsMessage():
return events(_that.payload);case ChatServerMessage():
return chat(_that.payload);case ChatHistoryMessage():
return chatHistory(_that.payload);case ChatRemovedMessage():
return chatRemoved(_that.payload);case AckMessage():
return ack(_that.payload);case ErrorMessage():
return error(_that.payload);case KickedMessage():
return kicked(_that.payload);case TableEndedMessage():
return tableEnded(_that.payload);case ServerRestartingMessage():
return serverRestarting();case PongMessage():
return pong(_that.payload);case VoiceSignalMessage():
return voiceSignal(_that.payload);case PhraseMessage():
return phrase(_that.payload);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Welcome payload)?  welcome,TResult? Function( Snapshot payload)?  snapshot,TResult? Function( EventsPayload payload)?  events,TResult? Function( ChatMessage payload)?  chat,TResult? Function( ChatHistory payload)?  chatHistory,TResult? Function( ChatRemoved payload)?  chatRemoved,TResult? Function( Ack payload)?  ack,TResult? Function( ErrorPayload payload)?  error,TResult? Function( Kicked payload)?  kicked,TResult? Function( TableEnded payload)?  tableEnded,TResult? Function()?  serverRestarting,TResult? Function( Pong payload)?  pong,TResult? Function( VoiceSignal payload)?  voiceSignal,TResult? Function( PhrasePayload payload)?  phrase,}) {final _that = this;
switch (_that) {
case WelcomeMessage() when welcome != null:
return welcome(_that.payload);case SnapshotMessage() when snapshot != null:
return snapshot(_that.payload);case EventsMessage() when events != null:
return events(_that.payload);case ChatServerMessage() when chat != null:
return chat(_that.payload);case ChatHistoryMessage() when chatHistory != null:
return chatHistory(_that.payload);case ChatRemovedMessage() when chatRemoved != null:
return chatRemoved(_that.payload);case AckMessage() when ack != null:
return ack(_that.payload);case ErrorMessage() when error != null:
return error(_that.payload);case KickedMessage() when kicked != null:
return kicked(_that.payload);case TableEndedMessage() when tableEnded != null:
return tableEnded(_that.payload);case ServerRestartingMessage() when serverRestarting != null:
return serverRestarting();case PongMessage() when pong != null:
return pong(_that.payload);case VoiceSignalMessage() when voiceSignal != null:
return voiceSignal(_that.payload);case PhraseMessage() when phrase != null:
return phrase(_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class WelcomeMessage implements ServerMessage {
  const WelcomeMessage(this.payload);
  

 final  Welcome payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WelcomeMessageCopyWith<WelcomeMessage> get copyWith => _$WelcomeMessageCopyWithImpl<WelcomeMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WelcomeMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.welcome(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WelcomeMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $WelcomeMessageCopyWith(WelcomeMessage value, $Res Function(WelcomeMessage) _then) = _$WelcomeMessageCopyWithImpl;
@useResult
$Res call({
 Welcome payload
});


$WelcomeCopyWith<$Res> get payload;

}
/// @nodoc
class _$WelcomeMessageCopyWithImpl<$Res>
    implements $WelcomeMessageCopyWith<$Res> {
  _$WelcomeMessageCopyWithImpl(this._self, this._then);

  final WelcomeMessage _self;
  final $Res Function(WelcomeMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WelcomeMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Welcome,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WelcomeCopyWith<$Res> get payload {
  
  return $WelcomeCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class SnapshotMessage implements ServerMessage {
  const SnapshotMessage(this.payload);
  

 final  Snapshot payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnapshotMessageCopyWith<SnapshotMessage> get copyWith => _$SnapshotMessageCopyWithImpl<SnapshotMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SnapshotMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.snapshot(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $SnapshotMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $SnapshotMessageCopyWith(SnapshotMessage value, $Res Function(SnapshotMessage) _then) = _$SnapshotMessageCopyWithImpl;
@useResult
$Res call({
 Snapshot payload
});


$SnapshotCopyWith<$Res> get payload;

}
/// @nodoc
class _$SnapshotMessageCopyWithImpl<$Res>
    implements $SnapshotMessageCopyWith<$Res> {
  _$SnapshotMessageCopyWithImpl(this._self, this._then);

  final SnapshotMessage _self;
  final $Res Function(SnapshotMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(SnapshotMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Snapshot,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SnapshotCopyWith<$Res> get payload {
  
  return $SnapshotCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class EventsMessage implements ServerMessage {
  const EventsMessage(this.payload);
  

 final  EventsPayload payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventsMessageCopyWith<EventsMessage> get copyWith => _$EventsMessageCopyWithImpl<EventsMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EventsMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.events(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $EventsMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $EventsMessageCopyWith(EventsMessage value, $Res Function(EventsMessage) _then) = _$EventsMessageCopyWithImpl;
@useResult
$Res call({
 EventsPayload payload
});


$EventsPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$EventsMessageCopyWithImpl<$Res>
    implements $EventsMessageCopyWith<$Res> {
  _$EventsMessageCopyWithImpl(this._self, this._then);

  final EventsMessage _self;
  final $Res Function(EventsMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(EventsMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as EventsPayload,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventsPayloadCopyWith<$Res> get payload {
  
  return $EventsPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ChatServerMessage implements ServerMessage {
  const ChatServerMessage(this.payload);
  

 final  ChatMessage payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatServerMessageCopyWith<ChatServerMessage> get copyWith => _$ChatServerMessageCopyWithImpl<ChatServerMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatServerMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.chat(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ChatServerMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $ChatServerMessageCopyWith(ChatServerMessage value, $Res Function(ChatServerMessage) _then) = _$ChatServerMessageCopyWithImpl;
@useResult
$Res call({
 ChatMessage payload
});


$ChatMessageCopyWith<$Res> get payload;

}
/// @nodoc
class _$ChatServerMessageCopyWithImpl<$Res>
    implements $ChatServerMessageCopyWith<$Res> {
  _$ChatServerMessageCopyWithImpl(this._self, this._then);

  final ChatServerMessage _self;
  final $Res Function(ChatServerMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ChatServerMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ChatMessage,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res> get payload {
  
  return $ChatMessageCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ChatHistoryMessage implements ServerMessage {
  const ChatHistoryMessage(this.payload);
  

 final  ChatHistory payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatHistoryMessageCopyWith<ChatHistoryMessage> get copyWith => _$ChatHistoryMessageCopyWithImpl<ChatHistoryMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatHistoryMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.chatHistory(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ChatHistoryMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $ChatHistoryMessageCopyWith(ChatHistoryMessage value, $Res Function(ChatHistoryMessage) _then) = _$ChatHistoryMessageCopyWithImpl;
@useResult
$Res call({
 ChatHistory payload
});


$ChatHistoryCopyWith<$Res> get payload;

}
/// @nodoc
class _$ChatHistoryMessageCopyWithImpl<$Res>
    implements $ChatHistoryMessageCopyWith<$Res> {
  _$ChatHistoryMessageCopyWithImpl(this._self, this._then);

  final ChatHistoryMessage _self;
  final $Res Function(ChatHistoryMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ChatHistoryMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ChatHistory,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatHistoryCopyWith<$Res> get payload {
  
  return $ChatHistoryCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ChatRemovedMessage implements ServerMessage {
  const ChatRemovedMessage(this.payload);
  

 final  ChatRemoved payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRemovedMessageCopyWith<ChatRemovedMessage> get copyWith => _$ChatRemovedMessageCopyWithImpl<ChatRemovedMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRemovedMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.chatRemoved(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ChatRemovedMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $ChatRemovedMessageCopyWith(ChatRemovedMessage value, $Res Function(ChatRemovedMessage) _then) = _$ChatRemovedMessageCopyWithImpl;
@useResult
$Res call({
 ChatRemoved payload
});


$ChatRemovedCopyWith<$Res> get payload;

}
/// @nodoc
class _$ChatRemovedMessageCopyWithImpl<$Res>
    implements $ChatRemovedMessageCopyWith<$Res> {
  _$ChatRemovedMessageCopyWithImpl(this._self, this._then);

  final ChatRemovedMessage _self;
  final $Res Function(ChatRemovedMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ChatRemovedMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ChatRemoved,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatRemovedCopyWith<$Res> get payload {
  
  return $ChatRemovedCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class AckMessage implements ServerMessage {
  const AckMessage(this.payload);
  

 final  Ack payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AckMessageCopyWith<AckMessage> get copyWith => _$AckMessageCopyWithImpl<AckMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AckMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.ack(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $AckMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $AckMessageCopyWith(AckMessage value, $Res Function(AckMessage) _then) = _$AckMessageCopyWithImpl;
@useResult
$Res call({
 Ack payload
});


$AckCopyWith<$Res> get payload;

}
/// @nodoc
class _$AckMessageCopyWithImpl<$Res>
    implements $AckMessageCopyWith<$Res> {
  _$AckMessageCopyWithImpl(this._self, this._then);

  final AckMessage _self;
  final $Res Function(AckMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(AckMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Ack,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AckCopyWith<$Res> get payload {
  
  return $AckCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ErrorMessage implements ServerMessage {
  const ErrorMessage(this.payload);
  

 final  ErrorPayload payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorMessageCopyWith<ErrorMessage> get copyWith => _$ErrorMessageCopyWithImpl<ErrorMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.error(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ErrorMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $ErrorMessageCopyWith(ErrorMessage value, $Res Function(ErrorMessage) _then) = _$ErrorMessageCopyWithImpl;
@useResult
$Res call({
 ErrorPayload payload
});


$ErrorPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$ErrorMessageCopyWithImpl<$Res>
    implements $ErrorMessageCopyWith<$Res> {
  _$ErrorMessageCopyWithImpl(this._self, this._then);

  final ErrorMessage _self;
  final $Res Function(ErrorMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ErrorMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ErrorPayload,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorPayloadCopyWith<$Res> get payload {
  
  return $ErrorPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class KickedMessage implements ServerMessage {
  const KickedMessage(this.payload);
  

 final  Kicked payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickedMessageCopyWith<KickedMessage> get copyWith => _$KickedMessageCopyWithImpl<KickedMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is KickedMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.kicked(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $KickedMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $KickedMessageCopyWith(KickedMessage value, $Res Function(KickedMessage) _then) = _$KickedMessageCopyWithImpl;
@useResult
$Res call({
 Kicked payload
});


$KickedCopyWith<$Res> get payload;

}
/// @nodoc
class _$KickedMessageCopyWithImpl<$Res>
    implements $KickedMessageCopyWith<$Res> {
  _$KickedMessageCopyWithImpl(this._self, this._then);

  final KickedMessage _self;
  final $Res Function(KickedMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(KickedMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Kicked,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickedCopyWith<$Res> get payload {
  
  return $KickedCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class TableEndedMessage implements ServerMessage {
  const TableEndedMessage(this.payload);
  

 final  TableEnded payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableEndedMessageCopyWith<TableEndedMessage> get copyWith => _$TableEndedMessageCopyWithImpl<TableEndedMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TableEndedMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.tableEnded(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $TableEndedMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $TableEndedMessageCopyWith(TableEndedMessage value, $Res Function(TableEndedMessage) _then) = _$TableEndedMessageCopyWithImpl;
@useResult
$Res call({
 TableEnded payload
});


$TableEndedCopyWith<$Res> get payload;

}
/// @nodoc
class _$TableEndedMessageCopyWithImpl<$Res>
    implements $TableEndedMessageCopyWith<$Res> {
  _$TableEndedMessageCopyWithImpl(this._self, this._then);

  final TableEndedMessage _self;
  final $Res Function(TableEndedMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(TableEndedMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as TableEnded,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TableEndedCopyWith<$Res> get payload {
  
  return $TableEndedCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ServerRestartingMessage implements ServerMessage {
  const ServerRestartingMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerRestartingMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ServerMessage.serverRestarting()';
}


}




/// @nodoc


class PongMessage implements ServerMessage {
  const PongMessage(this.payload);
  

 final  Pong payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PongMessageCopyWith<PongMessage> get copyWith => _$PongMessageCopyWithImpl<PongMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PongMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.pong(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $PongMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $PongMessageCopyWith(PongMessage value, $Res Function(PongMessage) _then) = _$PongMessageCopyWithImpl;
@useResult
$Res call({
 Pong payload
});


$PongCopyWith<$Res> get payload;

}
/// @nodoc
class _$PongMessageCopyWithImpl<$Res>
    implements $PongMessageCopyWith<$Res> {
  _$PongMessageCopyWithImpl(this._self, this._then);

  final PongMessage _self;
  final $Res Function(PongMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(PongMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Pong,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PongCopyWith<$Res> get payload {
  
  return $PongCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class VoiceSignalMessage implements ServerMessage {
  const VoiceSignalMessage(this.payload);
  

 final  VoiceSignal payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoiceSignalMessageCopyWith<VoiceSignalMessage> get copyWith => _$VoiceSignalMessageCopyWithImpl<VoiceSignalMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VoiceSignalMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.voiceSignal(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $VoiceSignalMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $VoiceSignalMessageCopyWith(VoiceSignalMessage value, $Res Function(VoiceSignalMessage) _then) = _$VoiceSignalMessageCopyWithImpl;
@useResult
$Res call({
 VoiceSignal payload
});


$VoiceSignalCopyWith<$Res> get payload;

}
/// @nodoc
class _$VoiceSignalMessageCopyWithImpl<$Res>
    implements $VoiceSignalMessageCopyWith<$Res> {
  _$VoiceSignalMessageCopyWithImpl(this._self, this._then);

  final VoiceSignalMessage _self;
  final $Res Function(VoiceSignalMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(VoiceSignalMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as VoiceSignal,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoiceSignalCopyWith<$Res> get payload {
  
  return $VoiceSignalCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class PhraseMessage implements ServerMessage {
  const PhraseMessage(this.payload);
  

 final  PhrasePayload payload;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhraseMessageCopyWith<PhraseMessage> get copyWith => _$PhraseMessageCopyWithImpl<PhraseMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PhraseMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ServerMessage.phrase(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $PhraseMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory $PhraseMessageCopyWith(PhraseMessage value, $Res Function(PhraseMessage) _then) = _$PhraseMessageCopyWithImpl;
@useResult
$Res call({
 PhrasePayload payload
});


$PhrasePayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$PhraseMessageCopyWithImpl<$Res>
    implements $PhraseMessageCopyWith<$Res> {
  _$PhraseMessageCopyWithImpl(this._self, this._then);

  final PhraseMessage _self;
  final $Res Function(PhraseMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(PhraseMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as PhrasePayload,
  ));
}

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhrasePayloadCopyWith<$Res> get payload {
  
  return $PhrasePayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc
mixin _$ClientMessage {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage()';
}


}

/// @nodoc
class $ClientMessageCopyWith<$Res>  {
$ClientMessageCopyWith(ClientMessage _, $Res Function(ClientMessage) __);
}


/// Adds pattern-matching-related methods to [ClientMessage].
extension ClientMessagePatterns on ClientMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HelloMessage value)?  hello,TResult Function( ActionMessage value)?  action,TResult Function( SitOutMessage value)?  sitOut,TResult Function( SitInMessage value)?  sitIn,TResult Function( RebuyMessage value)?  rebuy,TResult Function( LeaveMessage value)?  leave,TResult Function( ShowCardsMessage value)?  showCards,TResult Function( PreActionMessage value)?  preAction,TResult Function( RabbitHuntMessage value)?  rabbitHunt,TResult Function( ChangeSeatMessage value)?  changeSeat,TResult Function( VoiceMessage value)?  voice,TResult Function( VoiceSignalClientMessage value)?  voiceSignal,TResult Function( SayMessage value)?  say,TResult Function( ChatClientMessage value)?  chat,TResult Function( PingMessage value)?  ping,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HelloMessage() when hello != null:
return hello(_that);case ActionMessage() when action != null:
return action(_that);case SitOutMessage() when sitOut != null:
return sitOut(_that);case SitInMessage() when sitIn != null:
return sitIn(_that);case RebuyMessage() when rebuy != null:
return rebuy(_that);case LeaveMessage() when leave != null:
return leave(_that);case ShowCardsMessage() when showCards != null:
return showCards(_that);case PreActionMessage() when preAction != null:
return preAction(_that);case RabbitHuntMessage() when rabbitHunt != null:
return rabbitHunt(_that);case ChangeSeatMessage() when changeSeat != null:
return changeSeat(_that);case VoiceMessage() when voice != null:
return voice(_that);case VoiceSignalClientMessage() when voiceSignal != null:
return voiceSignal(_that);case SayMessage() when say != null:
return say(_that);case ChatClientMessage() when chat != null:
return chat(_that);case PingMessage() when ping != null:
return ping(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HelloMessage value)  hello,required TResult Function( ActionMessage value)  action,required TResult Function( SitOutMessage value)  sitOut,required TResult Function( SitInMessage value)  sitIn,required TResult Function( RebuyMessage value)  rebuy,required TResult Function( LeaveMessage value)  leave,required TResult Function( ShowCardsMessage value)  showCards,required TResult Function( PreActionMessage value)  preAction,required TResult Function( RabbitHuntMessage value)  rabbitHunt,required TResult Function( ChangeSeatMessage value)  changeSeat,required TResult Function( VoiceMessage value)  voice,required TResult Function( VoiceSignalClientMessage value)  voiceSignal,required TResult Function( SayMessage value)  say,required TResult Function( ChatClientMessage value)  chat,required TResult Function( PingMessage value)  ping,}){
final _that = this;
switch (_that) {
case HelloMessage():
return hello(_that);case ActionMessage():
return action(_that);case SitOutMessage():
return sitOut(_that);case SitInMessage():
return sitIn(_that);case RebuyMessage():
return rebuy(_that);case LeaveMessage():
return leave(_that);case ShowCardsMessage():
return showCards(_that);case PreActionMessage():
return preAction(_that);case RabbitHuntMessage():
return rabbitHunt(_that);case ChangeSeatMessage():
return changeSeat(_that);case VoiceMessage():
return voice(_that);case VoiceSignalClientMessage():
return voiceSignal(_that);case SayMessage():
return say(_that);case ChatClientMessage():
return chat(_that);case PingMessage():
return ping(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HelloMessage value)?  hello,TResult? Function( ActionMessage value)?  action,TResult? Function( SitOutMessage value)?  sitOut,TResult? Function( SitInMessage value)?  sitIn,TResult? Function( RebuyMessage value)?  rebuy,TResult? Function( LeaveMessage value)?  leave,TResult? Function( ShowCardsMessage value)?  showCards,TResult? Function( PreActionMessage value)?  preAction,TResult? Function( RabbitHuntMessage value)?  rabbitHunt,TResult? Function( ChangeSeatMessage value)?  changeSeat,TResult? Function( VoiceMessage value)?  voice,TResult? Function( VoiceSignalClientMessage value)?  voiceSignal,TResult? Function( SayMessage value)?  say,TResult? Function( ChatClientMessage value)?  chat,TResult? Function( PingMessage value)?  ping,}){
final _that = this;
switch (_that) {
case HelloMessage() when hello != null:
return hello(_that);case ActionMessage() when action != null:
return action(_that);case SitOutMessage() when sitOut != null:
return sitOut(_that);case SitInMessage() when sitIn != null:
return sitIn(_that);case RebuyMessage() when rebuy != null:
return rebuy(_that);case LeaveMessage() when leave != null:
return leave(_that);case ShowCardsMessage() when showCards != null:
return showCards(_that);case PreActionMessage() when preAction != null:
return preAction(_that);case RabbitHuntMessage() when rabbitHunt != null:
return rabbitHunt(_that);case ChangeSeatMessage() when changeSeat != null:
return changeSeat(_that);case VoiceMessage() when voice != null:
return voice(_that);case VoiceSignalClientMessage() when voiceSignal != null:
return voiceSignal(_that);case SayMessage() when say != null:
return say(_that);case ChatClientMessage() when chat != null:
return chat(_that);case PingMessage() when ping != null:
return ping(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Hello payload)?  hello,TResult Function( ActionPayload payload)?  action,TResult Function()?  sitOut,TResult Function()?  sitIn,TResult Function()?  rebuy,TResult Function()?  leave,TResult Function( ShowCardsPayload payload)?  showCards,TResult Function( PreActionPayload payload)?  preAction,TResult Function()?  rabbitHunt,TResult Function( ChangeSeatPayload payload)?  changeSeat,TResult Function( VoicePayload payload)?  voice,TResult Function( VoiceSignal payload)?  voiceSignal,TResult Function( SayPayload payload)?  say,TResult Function( ChatPayload payload)?  chat,TResult Function()?  ping,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HelloMessage() when hello != null:
return hello(_that.payload);case ActionMessage() when action != null:
return action(_that.payload);case SitOutMessage() when sitOut != null:
return sitOut();case SitInMessage() when sitIn != null:
return sitIn();case RebuyMessage() when rebuy != null:
return rebuy();case LeaveMessage() when leave != null:
return leave();case ShowCardsMessage() when showCards != null:
return showCards(_that.payload);case PreActionMessage() when preAction != null:
return preAction(_that.payload);case RabbitHuntMessage() when rabbitHunt != null:
return rabbitHunt();case ChangeSeatMessage() when changeSeat != null:
return changeSeat(_that.payload);case VoiceMessage() when voice != null:
return voice(_that.payload);case VoiceSignalClientMessage() when voiceSignal != null:
return voiceSignal(_that.payload);case SayMessage() when say != null:
return say(_that.payload);case ChatClientMessage() when chat != null:
return chat(_that.payload);case PingMessage() when ping != null:
return ping();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Hello payload)  hello,required TResult Function( ActionPayload payload)  action,required TResult Function()  sitOut,required TResult Function()  sitIn,required TResult Function()  rebuy,required TResult Function()  leave,required TResult Function( ShowCardsPayload payload)  showCards,required TResult Function( PreActionPayload payload)  preAction,required TResult Function()  rabbitHunt,required TResult Function( ChangeSeatPayload payload)  changeSeat,required TResult Function( VoicePayload payload)  voice,required TResult Function( VoiceSignal payload)  voiceSignal,required TResult Function( SayPayload payload)  say,required TResult Function( ChatPayload payload)  chat,required TResult Function()  ping,}) {final _that = this;
switch (_that) {
case HelloMessage():
return hello(_that.payload);case ActionMessage():
return action(_that.payload);case SitOutMessage():
return sitOut();case SitInMessage():
return sitIn();case RebuyMessage():
return rebuy();case LeaveMessage():
return leave();case ShowCardsMessage():
return showCards(_that.payload);case PreActionMessage():
return preAction(_that.payload);case RabbitHuntMessage():
return rabbitHunt();case ChangeSeatMessage():
return changeSeat(_that.payload);case VoiceMessage():
return voice(_that.payload);case VoiceSignalClientMessage():
return voiceSignal(_that.payload);case SayMessage():
return say(_that.payload);case ChatClientMessage():
return chat(_that.payload);case PingMessage():
return ping();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Hello payload)?  hello,TResult? Function( ActionPayload payload)?  action,TResult? Function()?  sitOut,TResult? Function()?  sitIn,TResult? Function()?  rebuy,TResult? Function()?  leave,TResult? Function( ShowCardsPayload payload)?  showCards,TResult? Function( PreActionPayload payload)?  preAction,TResult? Function()?  rabbitHunt,TResult? Function( ChangeSeatPayload payload)?  changeSeat,TResult? Function( VoicePayload payload)?  voice,TResult? Function( VoiceSignal payload)?  voiceSignal,TResult? Function( SayPayload payload)?  say,TResult? Function( ChatPayload payload)?  chat,TResult? Function()?  ping,}) {final _that = this;
switch (_that) {
case HelloMessage() when hello != null:
return hello(_that.payload);case ActionMessage() when action != null:
return action(_that.payload);case SitOutMessage() when sitOut != null:
return sitOut();case SitInMessage() when sitIn != null:
return sitIn();case RebuyMessage() when rebuy != null:
return rebuy();case LeaveMessage() when leave != null:
return leave();case ShowCardsMessage() when showCards != null:
return showCards(_that.payload);case PreActionMessage() when preAction != null:
return preAction(_that.payload);case RabbitHuntMessage() when rabbitHunt != null:
return rabbitHunt();case ChangeSeatMessage() when changeSeat != null:
return changeSeat(_that.payload);case VoiceMessage() when voice != null:
return voice(_that.payload);case VoiceSignalClientMessage() when voiceSignal != null:
return voiceSignal(_that.payload);case SayMessage() when say != null:
return say(_that.payload);case ChatClientMessage() when chat != null:
return chat(_that.payload);case PingMessage() when ping != null:
return ping();case _:
  return null;

}
}

}

/// @nodoc


class HelloMessage implements ClientMessage {
  const HelloMessage(this.payload);
  

 final  Hello payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelloMessageCopyWith<HelloMessage> get copyWith => _$HelloMessageCopyWithImpl<HelloMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HelloMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.hello(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $HelloMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $HelloMessageCopyWith(HelloMessage value, $Res Function(HelloMessage) _then) = _$HelloMessageCopyWithImpl;
@useResult
$Res call({
 Hello payload
});


$HelloCopyWith<$Res> get payload;

}
/// @nodoc
class _$HelloMessageCopyWithImpl<$Res>
    implements $HelloMessageCopyWith<$Res> {
  _$HelloMessageCopyWithImpl(this._self, this._then);

  final HelloMessage _self;
  final $Res Function(HelloMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(HelloMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Hello,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelloCopyWith<$Res> get payload {
  
  return $HelloCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ActionMessage implements ClientMessage {
  const ActionMessage(this.payload);
  

 final  ActionPayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionMessageCopyWith<ActionMessage> get copyWith => _$ActionMessageCopyWithImpl<ActionMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.action(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ActionMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $ActionMessageCopyWith(ActionMessage value, $Res Function(ActionMessage) _then) = _$ActionMessageCopyWithImpl;
@useResult
$Res call({
 ActionPayload payload
});


$ActionPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$ActionMessageCopyWithImpl<$Res>
    implements $ActionMessageCopyWith<$Res> {
  _$ActionMessageCopyWithImpl(this._self, this._then);

  final ActionMessage _self;
  final $Res Function(ActionMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ActionMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ActionPayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActionPayloadCopyWith<$Res> get payload {
  
  return $ActionPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class SitOutMessage implements ClientMessage {
  const SitOutMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SitOutMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage.sitOut()';
}


}




/// @nodoc


class SitInMessage implements ClientMessage {
  const SitInMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SitInMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage.sitIn()';
}


}




/// @nodoc


class RebuyMessage implements ClientMessage {
  const RebuyMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RebuyMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage.rebuy()';
}


}




/// @nodoc


class LeaveMessage implements ClientMessage {
  const LeaveMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaveMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage.leave()';
}


}




/// @nodoc


class ShowCardsMessage implements ClientMessage {
  const ShowCardsMessage(this.payload);
  

 final  ShowCardsPayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowCardsMessageCopyWith<ShowCardsMessage> get copyWith => _$ShowCardsMessageCopyWithImpl<ShowCardsMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowCardsMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.showCards(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ShowCardsMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $ShowCardsMessageCopyWith(ShowCardsMessage value, $Res Function(ShowCardsMessage) _then) = _$ShowCardsMessageCopyWithImpl;
@useResult
$Res call({
 ShowCardsPayload payload
});


$ShowCardsPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$ShowCardsMessageCopyWithImpl<$Res>
    implements $ShowCardsMessageCopyWith<$Res> {
  _$ShowCardsMessageCopyWithImpl(this._self, this._then);

  final ShowCardsMessage _self;
  final $Res Function(ShowCardsMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ShowCardsMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ShowCardsPayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShowCardsPayloadCopyWith<$Res> get payload {
  
  return $ShowCardsPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class PreActionMessage implements ClientMessage {
  const PreActionMessage(this.payload);
  

 final  PreActionPayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreActionMessageCopyWith<PreActionMessage> get copyWith => _$PreActionMessageCopyWithImpl<PreActionMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PreActionMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.preAction(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $PreActionMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $PreActionMessageCopyWith(PreActionMessage value, $Res Function(PreActionMessage) _then) = _$PreActionMessageCopyWithImpl;
@useResult
$Res call({
 PreActionPayload payload
});


$PreActionPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$PreActionMessageCopyWithImpl<$Res>
    implements $PreActionMessageCopyWith<$Res> {
  _$PreActionMessageCopyWithImpl(this._self, this._then);

  final PreActionMessage _self;
  final $Res Function(PreActionMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(PreActionMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as PreActionPayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreActionPayloadCopyWith<$Res> get payload {
  
  return $PreActionPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class RabbitHuntMessage implements ClientMessage {
  const RabbitHuntMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RabbitHuntMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage.rabbitHunt()';
}


}




/// @nodoc


class ChangeSeatMessage implements ClientMessage {
  const ChangeSeatMessage(this.payload);
  

 final  ChangeSeatPayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeSeatMessageCopyWith<ChangeSeatMessage> get copyWith => _$ChangeSeatMessageCopyWithImpl<ChangeSeatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeSeatMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.changeSeat(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ChangeSeatMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $ChangeSeatMessageCopyWith(ChangeSeatMessage value, $Res Function(ChangeSeatMessage) _then) = _$ChangeSeatMessageCopyWithImpl;
@useResult
$Res call({
 ChangeSeatPayload payload
});


$ChangeSeatPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$ChangeSeatMessageCopyWithImpl<$Res>
    implements $ChangeSeatMessageCopyWith<$Res> {
  _$ChangeSeatMessageCopyWithImpl(this._self, this._then);

  final ChangeSeatMessage _self;
  final $Res Function(ChangeSeatMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ChangeSeatMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ChangeSeatPayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChangeSeatPayloadCopyWith<$Res> get payload {
  
  return $ChangeSeatPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class VoiceMessage implements ClientMessage {
  const VoiceMessage(this.payload);
  

 final  VoicePayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoiceMessageCopyWith<VoiceMessage> get copyWith => _$VoiceMessageCopyWithImpl<VoiceMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VoiceMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.voice(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $VoiceMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $VoiceMessageCopyWith(VoiceMessage value, $Res Function(VoiceMessage) _then) = _$VoiceMessageCopyWithImpl;
@useResult
$Res call({
 VoicePayload payload
});


$VoicePayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$VoiceMessageCopyWithImpl<$Res>
    implements $VoiceMessageCopyWith<$Res> {
  _$VoiceMessageCopyWithImpl(this._self, this._then);

  final VoiceMessage _self;
  final $Res Function(VoiceMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(VoiceMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as VoicePayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoicePayloadCopyWith<$Res> get payload {
  
  return $VoicePayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class VoiceSignalClientMessage implements ClientMessage {
  const VoiceSignalClientMessage(this.payload);
  

 final  VoiceSignal payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoiceSignalClientMessageCopyWith<VoiceSignalClientMessage> get copyWith => _$VoiceSignalClientMessageCopyWithImpl<VoiceSignalClientMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VoiceSignalClientMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.voiceSignal(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $VoiceSignalClientMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $VoiceSignalClientMessageCopyWith(VoiceSignalClientMessage value, $Res Function(VoiceSignalClientMessage) _then) = _$VoiceSignalClientMessageCopyWithImpl;
@useResult
$Res call({
 VoiceSignal payload
});


$VoiceSignalCopyWith<$Res> get payload;

}
/// @nodoc
class _$VoiceSignalClientMessageCopyWithImpl<$Res>
    implements $VoiceSignalClientMessageCopyWith<$Res> {
  _$VoiceSignalClientMessageCopyWithImpl(this._self, this._then);

  final VoiceSignalClientMessage _self;
  final $Res Function(VoiceSignalClientMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(VoiceSignalClientMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as VoiceSignal,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoiceSignalCopyWith<$Res> get payload {
  
  return $VoiceSignalCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class SayMessage implements ClientMessage {
  const SayMessage(this.payload);
  

 final  SayPayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SayMessageCopyWith<SayMessage> get copyWith => _$SayMessageCopyWithImpl<SayMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SayMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.say(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $SayMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $SayMessageCopyWith(SayMessage value, $Res Function(SayMessage) _then) = _$SayMessageCopyWithImpl;
@useResult
$Res call({
 SayPayload payload
});


$SayPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$SayMessageCopyWithImpl<$Res>
    implements $SayMessageCopyWith<$Res> {
  _$SayMessageCopyWithImpl(this._self, this._then);

  final SayMessage _self;
  final $Res Function(SayMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(SayMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as SayPayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SayPayloadCopyWith<$Res> get payload {
  
  return $SayPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class ChatClientMessage implements ClientMessage {
  const ChatClientMessage(this.payload);
  

 final  ChatPayload payload;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatClientMessageCopyWith<ChatClientMessage> get copyWith => _$ChatClientMessageCopyWithImpl<ChatClientMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatClientMessage&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,payload);
}

@override
String toString() {
    return 'ClientMessage.chat(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ChatClientMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory $ChatClientMessageCopyWith(ChatClientMessage value, $Res Function(ChatClientMessage) _then) = _$ChatClientMessageCopyWithImpl;
@useResult
$Res call({
 ChatPayload payload
});


$ChatPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$ChatClientMessageCopyWithImpl<$Res>
    implements $ChatClientMessageCopyWith<$Res> {
  _$ChatClientMessageCopyWithImpl(this._self, this._then);

  final ChatClientMessage _self;
  final $Res Function(ChatClientMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ChatClientMessage(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ChatPayload,
  ));
}

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPayloadCopyWith<$Res> get payload {
  
  return $ChatPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class PingMessage implements ClientMessage {
  const PingMessage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PingMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClientMessage.ping()';
}


}




// dart format on
