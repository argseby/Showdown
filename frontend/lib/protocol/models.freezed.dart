// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Envelope {

 String get type;@JsonKey(includeIfNull: false) String? get id;@JsonKey(includeIfNull: false) Map<String, dynamic>? get payload;
/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvelopeCopyWith<Envelope> get copyWith => _$EnvelopeCopyWithImpl<Envelope>(this as Envelope, _$identity);

  /// Serializes this Envelope to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Envelope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Envelope&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Envelope;
  return Object.hash(runtimeType,_this.type,_this.id,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as Envelope;
  return 'Envelope(type: ${_this.type}, id: ${_this.id}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $EnvelopeCopyWith<$Res>  {
  factory $EnvelopeCopyWith(Envelope value, $Res Function(Envelope) _then) = _$EnvelopeCopyWithImpl;
@useResult
$Res call({
 String type,@JsonKey(includeIfNull: false) String? id,@JsonKey(includeIfNull: false) Map<String, dynamic>? payload
});




}
/// @nodoc
class _$EnvelopeCopyWithImpl<$Res>
    implements $EnvelopeCopyWith<$Res> {
  _$EnvelopeCopyWithImpl(this._self, this._then);

  final Envelope _self;
  final $Res Function(Envelope) _then;

/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = freezed,Object? payload = freezed,}) {
  return _then(Envelope(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Envelope].
extension EnvelopePatterns on Envelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Envelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Envelope() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Envelope value)  $default,){
final _that = this;
switch (_that) {
case _Envelope():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Envelope value)?  $default,){
final _that = this;
switch (_that) {
case _Envelope() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type, @JsonKey(includeIfNull: false)  String? id, @JsonKey(includeIfNull: false)  Map<String, dynamic>? payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Envelope() when $default != null:
return $default(_that.type,_that.id,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type, @JsonKey(includeIfNull: false)  String? id, @JsonKey(includeIfNull: false)  Map<String, dynamic>? payload)  $default,) {final _that = this;
switch (_that) {
case _Envelope():
return $default(_that.type,_that.id,_that.payload);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type, @JsonKey(includeIfNull: false)  String? id, @JsonKey(includeIfNull: false)  Map<String, dynamic>? payload)?  $default,) {final _that = this;
switch (_that) {
case _Envelope() when $default != null:
return $default(_that.type,_that.id,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Envelope implements Envelope {
  const _Envelope({required this.type, @JsonKey(includeIfNull: false) this.id, @JsonKey(includeIfNull: false)  Map<String, dynamic>? payload}): _payload = payload;
  factory _Envelope.fromJson(Map<String, dynamic> json) => _$EnvelopeFromJson(json);

@override final  String type;
@override@JsonKey(includeIfNull: false) final  String? id;
 final  Map<String, dynamic>? _payload;
@override@JsonKey(includeIfNull: false) Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnvelopeCopyWith<_Envelope> get copyWith => __$EnvelopeCopyWithImpl<_Envelope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnvelopeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Envelope&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,id,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'Envelope(type: $type, id: $id, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$EnvelopeCopyWith<$Res> implements $EnvelopeCopyWith<$Res> {
  factory _$EnvelopeCopyWith(_Envelope value, $Res Function(_Envelope) _then) = __$EnvelopeCopyWithImpl;
@override @useResult
$Res call({
 String type,@JsonKey(includeIfNull: false) String? id,@JsonKey(includeIfNull: false) Map<String, dynamic>? payload
});




}
/// @nodoc
class __$EnvelopeCopyWithImpl<$Res>
    implements _$EnvelopeCopyWith<$Res> {
  __$EnvelopeCopyWithImpl(this._self, this._then);

  final _Envelope _self;
  final $Res Function(_Envelope) _then;

/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = freezed,Object? payload = freezed,}) {
  return _then(_Envelope(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$ShowCardsPayload {

@JsonKey(includeIfNull: false) String? get cards;
/// Create a copy of ShowCardsPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowCardsPayloadCopyWith<ShowCardsPayload> get copyWith => _$ShowCardsPayloadCopyWithImpl<ShowCardsPayload>(this as ShowCardsPayload, _$identity);

  /// Serializes this ShowCardsPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShowCardsPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowCardsPayload&&(identical(other.cards, _this.cards) || other.cards == _this.cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShowCardsPayload;
  return Object.hash(runtimeType,_this.cards);
}

@override
String toString() {
  final _this = this as ShowCardsPayload;
  return 'ShowCardsPayload(cards: ${_this.cards})';
}


}

/// @nodoc
abstract mixin class $ShowCardsPayloadCopyWith<$Res>  {
  factory $ShowCardsPayloadCopyWith(ShowCardsPayload value, $Res Function(ShowCardsPayload) _then) = _$ShowCardsPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? cards
});




}
/// @nodoc
class _$ShowCardsPayloadCopyWithImpl<$Res>
    implements $ShowCardsPayloadCopyWith<$Res> {
  _$ShowCardsPayloadCopyWithImpl(this._self, this._then);

  final ShowCardsPayload _self;
  final $Res Function(ShowCardsPayload) _then;

/// Create a copy of ShowCardsPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cards = freezed,}) {
  return _then(ShowCardsPayload(
cards: freezed == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShowCardsPayload].
extension ShowCardsPayloadPatterns on ShowCardsPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShowCardsPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowCardsPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShowCardsPayload value)  $default,){
final _that = this;
switch (_that) {
case _ShowCardsPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShowCardsPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ShowCardsPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? cards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowCardsPayload() when $default != null:
return $default(_that.cards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? cards)  $default,) {final _that = this;
switch (_that) {
case _ShowCardsPayload():
return $default(_that.cards);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? cards)?  $default,) {final _that = this;
switch (_that) {
case _ShowCardsPayload() when $default != null:
return $default(_that.cards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowCardsPayload implements ShowCardsPayload {
  const _ShowCardsPayload({@JsonKey(includeIfNull: false) this.cards});
  factory _ShowCardsPayload.fromJson(Map<String, dynamic> json) => _$ShowCardsPayloadFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? cards;

/// Create a copy of ShowCardsPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowCardsPayloadCopyWith<_ShowCardsPayload> get copyWith => __$ShowCardsPayloadCopyWithImpl<_ShowCardsPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShowCardsPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowCardsPayload&&(identical(other.cards, cards) || other.cards == cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,cards);
}

@override
String toString() {
    return 'ShowCardsPayload(cards: $cards)';
}


}

/// @nodoc
abstract mixin class _$ShowCardsPayloadCopyWith<$Res> implements $ShowCardsPayloadCopyWith<$Res> {
  factory _$ShowCardsPayloadCopyWith(_ShowCardsPayload value, $Res Function(_ShowCardsPayload) _then) = __$ShowCardsPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? cards
});




}
/// @nodoc
class __$ShowCardsPayloadCopyWithImpl<$Res>
    implements _$ShowCardsPayloadCopyWith<$Res> {
  __$ShowCardsPayloadCopyWithImpl(this._self, this._then);

  final _ShowCardsPayload _self;
  final $Res Function(_ShowCardsPayload) _then;

/// Create a copy of ShowCardsPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cards = freezed,}) {
  return _then(_ShowCardsPayload(
cards: freezed == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VoicePayload {

 String get state;@JsonKey(includeIfNull: false) bool? get camera;
/// Create a copy of VoicePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoicePayloadCopyWith<VoicePayload> get copyWith => _$VoicePayloadCopyWithImpl<VoicePayload>(this as VoicePayload, _$identity);

  /// Serializes this VoicePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VoicePayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoicePayload&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.camera, _this.camera) || other.camera == _this.camera));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VoicePayload;
  return Object.hash(runtimeType,_this.state,_this.camera);
}

@override
String toString() {
  final _this = this as VoicePayload;
  return 'VoicePayload(state: ${_this.state}, camera: ${_this.camera})';
}


}

/// @nodoc
abstract mixin class $VoicePayloadCopyWith<$Res>  {
  factory $VoicePayloadCopyWith(VoicePayload value, $Res Function(VoicePayload) _then) = _$VoicePayloadCopyWithImpl;
@useResult
$Res call({
 String state,@JsonKey(includeIfNull: false) bool? camera
});




}
/// @nodoc
class _$VoicePayloadCopyWithImpl<$Res>
    implements $VoicePayloadCopyWith<$Res> {
  _$VoicePayloadCopyWithImpl(this._self, this._then);

  final VoicePayload _self;
  final $Res Function(VoicePayload) _then;

/// Create a copy of VoicePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? camera = freezed,}) {
  return _then(VoicePayload(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,camera: freezed == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [VoicePayload].
extension VoicePayloadPatterns on VoicePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoicePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoicePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoicePayload value)  $default,){
final _that = this;
switch (_that) {
case _VoicePayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoicePayload value)?  $default,){
final _that = this;
switch (_that) {
case _VoicePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String state, @JsonKey(includeIfNull: false)  bool? camera)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoicePayload() when $default != null:
return $default(_that.state,_that.camera);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String state, @JsonKey(includeIfNull: false)  bool? camera)  $default,) {final _that = this;
switch (_that) {
case _VoicePayload():
return $default(_that.state,_that.camera);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String state, @JsonKey(includeIfNull: false)  bool? camera)?  $default,) {final _that = this;
switch (_that) {
case _VoicePayload() when $default != null:
return $default(_that.state,_that.camera);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoicePayload implements VoicePayload {
  const _VoicePayload({required this.state, @JsonKey(includeIfNull: false) this.camera});
  factory _VoicePayload.fromJson(Map<String, dynamic> json) => _$VoicePayloadFromJson(json);

@override final  String state;
@override@JsonKey(includeIfNull: false) final  bool? camera;

/// Create a copy of VoicePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoicePayloadCopyWith<_VoicePayload> get copyWith => __$VoicePayloadCopyWithImpl<_VoicePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoicePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoicePayload&&(identical(other.state, state) || other.state == state)&&(identical(other.camera, camera) || other.camera == camera));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,state,camera);
}

@override
String toString() {
    return 'VoicePayload(state: $state, camera: $camera)';
}


}

/// @nodoc
abstract mixin class _$VoicePayloadCopyWith<$Res> implements $VoicePayloadCopyWith<$Res> {
  factory _$VoicePayloadCopyWith(_VoicePayload value, $Res Function(_VoicePayload) _then) = __$VoicePayloadCopyWithImpl;
@override @useResult
$Res call({
 String state,@JsonKey(includeIfNull: false) bool? camera
});




}
/// @nodoc
class __$VoicePayloadCopyWithImpl<$Res>
    implements _$VoicePayloadCopyWith<$Res> {
  __$VoicePayloadCopyWithImpl(this._self, this._then);

  final _VoicePayload _self;
  final $Res Function(_VoicePayload) _then;

/// Create a copy of VoicePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? camera = freezed,}) {
  return _then(_VoicePayload(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,camera: freezed == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$VoiceSignal {

@JsonKey(includeIfNull: false) String? get to;@JsonKey(includeIfNull: false) String? get from; String get kind; String get data;
/// Create a copy of VoiceSignal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoiceSignalCopyWith<VoiceSignal> get copyWith => _$VoiceSignalCopyWithImpl<VoiceSignal>(this as VoiceSignal, _$identity);

  /// Serializes this VoiceSignal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VoiceSignal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoiceSignal&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.data, _this.data) || other.data == _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VoiceSignal;
  return Object.hash(runtimeType,_this.to,_this.from,_this.kind,_this.data);
}

@override
String toString() {
  final _this = this as VoiceSignal;
  return 'VoiceSignal(to: ${_this.to}, from: ${_this.from}, kind: ${_this.kind}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $VoiceSignalCopyWith<$Res>  {
  factory $VoiceSignalCopyWith(VoiceSignal value, $Res Function(VoiceSignal) _then) = _$VoiceSignalCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? to,@JsonKey(includeIfNull: false) String? from, String kind, String data
});




}
/// @nodoc
class _$VoiceSignalCopyWithImpl<$Res>
    implements $VoiceSignalCopyWith<$Res> {
  _$VoiceSignalCopyWithImpl(this._self, this._then);

  final VoiceSignal _self;
  final $Res Function(VoiceSignal) _then;

/// Create a copy of VoiceSignal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? to = freezed,Object? from = freezed,Object? kind = null,Object? data = null,}) {
  return _then(VoiceSignal(
to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VoiceSignal].
extension VoiceSignalPatterns on VoiceSignal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoiceSignal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoiceSignal() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoiceSignal value)  $default,){
final _that = this;
switch (_that) {
case _VoiceSignal():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoiceSignal value)?  $default,){
final _that = this;
switch (_that) {
case _VoiceSignal() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? to, @JsonKey(includeIfNull: false)  String? from,  String kind,  String data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoiceSignal() when $default != null:
return $default(_that.to,_that.from,_that.kind,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? to, @JsonKey(includeIfNull: false)  String? from,  String kind,  String data)  $default,) {final _that = this;
switch (_that) {
case _VoiceSignal():
return $default(_that.to,_that.from,_that.kind,_that.data);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? to, @JsonKey(includeIfNull: false)  String? from,  String kind,  String data)?  $default,) {final _that = this;
switch (_that) {
case _VoiceSignal() when $default != null:
return $default(_that.to,_that.from,_that.kind,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoiceSignal implements VoiceSignal {
  const _VoiceSignal({@JsonKey(includeIfNull: false) this.to, @JsonKey(includeIfNull: false) this.from, required this.kind, required this.data});
  factory _VoiceSignal.fromJson(Map<String, dynamic> json) => _$VoiceSignalFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? to;
@override@JsonKey(includeIfNull: false) final  String? from;
@override final  String kind;
@override final  String data;

/// Create a copy of VoiceSignal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoiceSignalCopyWith<_VoiceSignal> get copyWith => __$VoiceSignalCopyWithImpl<_VoiceSignal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoiceSignalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoiceSignal&&(identical(other.to, to) || other.to == to)&&(identical(other.from, from) || other.from == from)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,to,from,kind,data);
}

@override
String toString() {
    return 'VoiceSignal(to: $to, from: $from, kind: $kind, data: $data)';
}


}

/// @nodoc
abstract mixin class _$VoiceSignalCopyWith<$Res> implements $VoiceSignalCopyWith<$Res> {
  factory _$VoiceSignalCopyWith(_VoiceSignal value, $Res Function(_VoiceSignal) _then) = __$VoiceSignalCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? to,@JsonKey(includeIfNull: false) String? from, String kind, String data
});




}
/// @nodoc
class __$VoiceSignalCopyWithImpl<$Res>
    implements _$VoiceSignalCopyWith<$Res> {
  __$VoiceSignalCopyWithImpl(this._self, this._then);

  final _VoiceSignal _self;
  final $Res Function(_VoiceSignal) _then;

/// Create a copy of VoiceSignal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? to = freezed,Object? from = freezed,Object? kind = null,Object? data = null,}) {
  return _then(_VoiceSignal(
to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StraddlePayload {

 bool get on;
/// Create a copy of StraddlePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StraddlePayloadCopyWith<StraddlePayload> get copyWith => _$StraddlePayloadCopyWithImpl<StraddlePayload>(this as StraddlePayload, _$identity);

  /// Serializes this StraddlePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StraddlePayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StraddlePayload&&(identical(other.on, _this.on) || other.on == _this.on));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StraddlePayload;
  return Object.hash(runtimeType,_this.on);
}

@override
String toString() {
  final _this = this as StraddlePayload;
  return 'StraddlePayload(on: ${_this.on})';
}


}

/// @nodoc
abstract mixin class $StraddlePayloadCopyWith<$Res>  {
  factory $StraddlePayloadCopyWith(StraddlePayload value, $Res Function(StraddlePayload) _then) = _$StraddlePayloadCopyWithImpl;
@useResult
$Res call({
 bool on
});




}
/// @nodoc
class _$StraddlePayloadCopyWithImpl<$Res>
    implements $StraddlePayloadCopyWith<$Res> {
  _$StraddlePayloadCopyWithImpl(this._self, this._then);

  final StraddlePayload _self;
  final $Res Function(StraddlePayload) _then;

/// Create a copy of StraddlePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? on = null,}) {
  return _then(StraddlePayload(
on: null == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StraddlePayload].
extension StraddlePayloadPatterns on StraddlePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StraddlePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StraddlePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StraddlePayload value)  $default,){
final _that = this;
switch (_that) {
case _StraddlePayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StraddlePayload value)?  $default,){
final _that = this;
switch (_that) {
case _StraddlePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool on)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StraddlePayload() when $default != null:
return $default(_that.on);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool on)  $default,) {final _that = this;
switch (_that) {
case _StraddlePayload():
return $default(_that.on);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool on)?  $default,) {final _that = this;
switch (_that) {
case _StraddlePayload() when $default != null:
return $default(_that.on);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StraddlePayload implements StraddlePayload {
  const _StraddlePayload({required this.on});
  factory _StraddlePayload.fromJson(Map<String, dynamic> json) => _$StraddlePayloadFromJson(json);

@override final  bool on;

/// Create a copy of StraddlePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StraddlePayloadCopyWith<_StraddlePayload> get copyWith => __$StraddlePayloadCopyWithImpl<_StraddlePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StraddlePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StraddlePayload&&(identical(other.on, on) || other.on == on));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,on);
}

@override
String toString() {
    return 'StraddlePayload(on: $on)';
}


}

/// @nodoc
abstract mixin class _$StraddlePayloadCopyWith<$Res> implements $StraddlePayloadCopyWith<$Res> {
  factory _$StraddlePayloadCopyWith(_StraddlePayload value, $Res Function(_StraddlePayload) _then) = __$StraddlePayloadCopyWithImpl;
@override @useResult
$Res call({
 bool on
});




}
/// @nodoc
class __$StraddlePayloadCopyWithImpl<$Res>
    implements _$StraddlePayloadCopyWith<$Res> {
  __$StraddlePayloadCopyWithImpl(this._self, this._then);

  final _StraddlePayload _self;
  final $Res Function(_StraddlePayload) _then;

/// Create a copy of StraddlePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? on = null,}) {
  return _then(_StraddlePayload(
on: null == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RunTwicePayload {

 bool get agree;
/// Create a copy of RunTwicePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunTwicePayloadCopyWith<RunTwicePayload> get copyWith => _$RunTwicePayloadCopyWithImpl<RunTwicePayload>(this as RunTwicePayload, _$identity);

  /// Serializes this RunTwicePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RunTwicePayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunTwicePayload&&(identical(other.agree, _this.agree) || other.agree == _this.agree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RunTwicePayload;
  return Object.hash(runtimeType,_this.agree);
}

@override
String toString() {
  final _this = this as RunTwicePayload;
  return 'RunTwicePayload(agree: ${_this.agree})';
}


}

/// @nodoc
abstract mixin class $RunTwicePayloadCopyWith<$Res>  {
  factory $RunTwicePayloadCopyWith(RunTwicePayload value, $Res Function(RunTwicePayload) _then) = _$RunTwicePayloadCopyWithImpl;
@useResult
$Res call({
 bool agree
});




}
/// @nodoc
class _$RunTwicePayloadCopyWithImpl<$Res>
    implements $RunTwicePayloadCopyWith<$Res> {
  _$RunTwicePayloadCopyWithImpl(this._self, this._then);

  final RunTwicePayload _self;
  final $Res Function(RunTwicePayload) _then;

/// Create a copy of RunTwicePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agree = null,}) {
  return _then(RunTwicePayload(
agree: null == agree ? _self.agree : agree // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RunTwicePayload].
extension RunTwicePayloadPatterns on RunTwicePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RunTwicePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RunTwicePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RunTwicePayload value)  $default,){
final _that = this;
switch (_that) {
case _RunTwicePayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RunTwicePayload value)?  $default,){
final _that = this;
switch (_that) {
case _RunTwicePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool agree)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RunTwicePayload() when $default != null:
return $default(_that.agree);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool agree)  $default,) {final _that = this;
switch (_that) {
case _RunTwicePayload():
return $default(_that.agree);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool agree)?  $default,) {final _that = this;
switch (_that) {
case _RunTwicePayload() when $default != null:
return $default(_that.agree);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RunTwicePayload implements RunTwicePayload {
  const _RunTwicePayload({required this.agree});
  factory _RunTwicePayload.fromJson(Map<String, dynamic> json) => _$RunTwicePayloadFromJson(json);

@override final  bool agree;

/// Create a copy of RunTwicePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunTwicePayloadCopyWith<_RunTwicePayload> get copyWith => __$RunTwicePayloadCopyWithImpl<_RunTwicePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RunTwicePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RunTwicePayload&&(identical(other.agree, agree) || other.agree == agree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,agree);
}

@override
String toString() {
    return 'RunTwicePayload(agree: $agree)';
}


}

/// @nodoc
abstract mixin class _$RunTwicePayloadCopyWith<$Res> implements $RunTwicePayloadCopyWith<$Res> {
  factory _$RunTwicePayloadCopyWith(_RunTwicePayload value, $Res Function(_RunTwicePayload) _then) = __$RunTwicePayloadCopyWithImpl;
@override @useResult
$Res call({
 bool agree
});




}
/// @nodoc
class __$RunTwicePayloadCopyWithImpl<$Res>
    implements _$RunTwicePayloadCopyWith<$Res> {
  __$RunTwicePayloadCopyWithImpl(this._self, this._then);

  final _RunTwicePayload _self;
  final $Res Function(_RunTwicePayload) _then;

/// Create a copy of RunTwicePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agree = null,}) {
  return _then(_RunTwicePayload(
agree: null == agree ? _self.agree : agree // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SayPayload {

 String get phrase;
/// Create a copy of SayPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SayPayloadCopyWith<SayPayload> get copyWith => _$SayPayloadCopyWithImpl<SayPayload>(this as SayPayload, _$identity);

  /// Serializes this SayPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SayPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SayPayload&&(identical(other.phrase, _this.phrase) || other.phrase == _this.phrase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SayPayload;
  return Object.hash(runtimeType,_this.phrase);
}

@override
String toString() {
  final _this = this as SayPayload;
  return 'SayPayload(phrase: ${_this.phrase})';
}


}

/// @nodoc
abstract mixin class $SayPayloadCopyWith<$Res>  {
  factory $SayPayloadCopyWith(SayPayload value, $Res Function(SayPayload) _then) = _$SayPayloadCopyWithImpl;
@useResult
$Res call({
 String phrase
});




}
/// @nodoc
class _$SayPayloadCopyWithImpl<$Res>
    implements $SayPayloadCopyWith<$Res> {
  _$SayPayloadCopyWithImpl(this._self, this._then);

  final SayPayload _self;
  final $Res Function(SayPayload) _then;

/// Create a copy of SayPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phrase = null,}) {
  return _then(SayPayload(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SayPayload].
extension SayPayloadPatterns on SayPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SayPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SayPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SayPayload value)  $default,){
final _that = this;
switch (_that) {
case _SayPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SayPayload value)?  $default,){
final _that = this;
switch (_that) {
case _SayPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phrase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SayPayload() when $default != null:
return $default(_that.phrase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phrase)  $default,) {final _that = this;
switch (_that) {
case _SayPayload():
return $default(_that.phrase);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phrase)?  $default,) {final _that = this;
switch (_that) {
case _SayPayload() when $default != null:
return $default(_that.phrase);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SayPayload implements SayPayload {
  const _SayPayload({required this.phrase});
  factory _SayPayload.fromJson(Map<String, dynamic> json) => _$SayPayloadFromJson(json);

@override final  String phrase;

/// Create a copy of SayPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SayPayloadCopyWith<_SayPayload> get copyWith => __$SayPayloadCopyWithImpl<_SayPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SayPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SayPayload&&(identical(other.phrase, phrase) || other.phrase == phrase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,phrase);
}

@override
String toString() {
    return 'SayPayload(phrase: $phrase)';
}


}

/// @nodoc
abstract mixin class _$SayPayloadCopyWith<$Res> implements $SayPayloadCopyWith<$Res> {
  factory _$SayPayloadCopyWith(_SayPayload value, $Res Function(_SayPayload) _then) = __$SayPayloadCopyWithImpl;
@override @useResult
$Res call({
 String phrase
});




}
/// @nodoc
class __$SayPayloadCopyWithImpl<$Res>
    implements _$SayPayloadCopyWith<$Res> {
  __$SayPayloadCopyWithImpl(this._self, this._then);

  final _SayPayload _self;
  final $Res Function(_SayPayload) _then;

/// Create a copy of SayPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phrase = null,}) {
  return _then(_SayPayload(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PhrasePayload {

 int get seat; String get name; String get phrase; int get ts;
/// Create a copy of PhrasePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhrasePayloadCopyWith<PhrasePayload> get copyWith => _$PhrasePayloadCopyWithImpl<PhrasePayload>(this as PhrasePayload, _$identity);

  /// Serializes this PhrasePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PhrasePayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhrasePayload&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phrase, _this.phrase) || other.phrase == _this.phrase)&&(identical(other.ts, _this.ts) || other.ts == _this.ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PhrasePayload;
  return Object.hash(runtimeType,_this.seat,_this.name,_this.phrase,_this.ts);
}

@override
String toString() {
  final _this = this as PhrasePayload;
  return 'PhrasePayload(seat: ${_this.seat}, name: ${_this.name}, phrase: ${_this.phrase}, ts: ${_this.ts})';
}


}

/// @nodoc
abstract mixin class $PhrasePayloadCopyWith<$Res>  {
  factory $PhrasePayloadCopyWith(PhrasePayload value, $Res Function(PhrasePayload) _then) = _$PhrasePayloadCopyWithImpl;
@useResult
$Res call({
 int seat, String name, String phrase, int ts
});




}
/// @nodoc
class _$PhrasePayloadCopyWithImpl<$Res>
    implements $PhrasePayloadCopyWith<$Res> {
  _$PhrasePayloadCopyWithImpl(this._self, this._then);

  final PhrasePayload _self;
  final $Res Function(PhrasePayload) _then;

/// Create a copy of PhrasePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seat = null,Object? name = null,Object? phrase = null,Object? ts = null,}) {
  return _then(PhrasePayload(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PhrasePayload].
extension PhrasePayloadPatterns on PhrasePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhrasePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhrasePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhrasePayload value)  $default,){
final _that = this;
switch (_that) {
case _PhrasePayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhrasePayload value)?  $default,){
final _that = this;
switch (_that) {
case _PhrasePayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seat,  String name,  String phrase,  int ts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhrasePayload() when $default != null:
return $default(_that.seat,_that.name,_that.phrase,_that.ts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seat,  String name,  String phrase,  int ts)  $default,) {final _that = this;
switch (_that) {
case _PhrasePayload():
return $default(_that.seat,_that.name,_that.phrase,_that.ts);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seat,  String name,  String phrase,  int ts)?  $default,) {final _that = this;
switch (_that) {
case _PhrasePayload() when $default != null:
return $default(_that.seat,_that.name,_that.phrase,_that.ts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhrasePayload implements PhrasePayload {
  const _PhrasePayload({required this.seat, required this.name, required this.phrase, required this.ts});
  factory _PhrasePayload.fromJson(Map<String, dynamic> json) => _$PhrasePayloadFromJson(json);

@override final  int seat;
@override final  String name;
@override final  String phrase;
@override final  int ts;

/// Create a copy of PhrasePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhrasePayloadCopyWith<_PhrasePayload> get copyWith => __$PhrasePayloadCopyWithImpl<_PhrasePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhrasePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhrasePayload&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.name, name) || other.name == name)&&(identical(other.phrase, phrase) || other.phrase == phrase)&&(identical(other.ts, ts) || other.ts == ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seat,name,phrase,ts);
}

@override
String toString() {
    return 'PhrasePayload(seat: $seat, name: $name, phrase: $phrase, ts: $ts)';
}


}

/// @nodoc
abstract mixin class _$PhrasePayloadCopyWith<$Res> implements $PhrasePayloadCopyWith<$Res> {
  factory _$PhrasePayloadCopyWith(_PhrasePayload value, $Res Function(_PhrasePayload) _then) = __$PhrasePayloadCopyWithImpl;
@override @useResult
$Res call({
 int seat, String name, String phrase, int ts
});




}
/// @nodoc
class __$PhrasePayloadCopyWithImpl<$Res>
    implements _$PhrasePayloadCopyWith<$Res> {
  __$PhrasePayloadCopyWithImpl(this._self, this._then);

  final _PhrasePayload _self;
  final $Res Function(_PhrasePayload) _then;

/// Create a copy of PhrasePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seat = null,Object? name = null,Object? phrase = null,Object? ts = null,}) {
  return _then(_PhrasePayload(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChangeSeatPayload {

 int get seat;
/// Create a copy of ChangeSeatPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeSeatPayloadCopyWith<ChangeSeatPayload> get copyWith => _$ChangeSeatPayloadCopyWithImpl<ChangeSeatPayload>(this as ChangeSeatPayload, _$identity);

  /// Serializes this ChangeSeatPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangeSeatPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeSeatPayload&&(identical(other.seat, _this.seat) || other.seat == _this.seat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangeSeatPayload;
  return Object.hash(runtimeType,_this.seat);
}

@override
String toString() {
  final _this = this as ChangeSeatPayload;
  return 'ChangeSeatPayload(seat: ${_this.seat})';
}


}

/// @nodoc
abstract mixin class $ChangeSeatPayloadCopyWith<$Res>  {
  factory $ChangeSeatPayloadCopyWith(ChangeSeatPayload value, $Res Function(ChangeSeatPayload) _then) = _$ChangeSeatPayloadCopyWithImpl;
@useResult
$Res call({
 int seat
});




}
/// @nodoc
class _$ChangeSeatPayloadCopyWithImpl<$Res>
    implements $ChangeSeatPayloadCopyWith<$Res> {
  _$ChangeSeatPayloadCopyWithImpl(this._self, this._then);

  final ChangeSeatPayload _self;
  final $Res Function(ChangeSeatPayload) _then;

/// Create a copy of ChangeSeatPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seat = null,}) {
  return _then(ChangeSeatPayload(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangeSeatPayload].
extension ChangeSeatPayloadPatterns on ChangeSeatPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangeSeatPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangeSeatPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangeSeatPayload value)  $default,){
final _that = this;
switch (_that) {
case _ChangeSeatPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangeSeatPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ChangeSeatPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangeSeatPayload() when $default != null:
return $default(_that.seat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seat)  $default,) {final _that = this;
switch (_that) {
case _ChangeSeatPayload():
return $default(_that.seat);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seat)?  $default,) {final _that = this;
switch (_that) {
case _ChangeSeatPayload() when $default != null:
return $default(_that.seat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangeSeatPayload implements ChangeSeatPayload {
  const _ChangeSeatPayload({required this.seat});
  factory _ChangeSeatPayload.fromJson(Map<String, dynamic> json) => _$ChangeSeatPayloadFromJson(json);

@override final  int seat;

/// Create a copy of ChangeSeatPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeSeatPayloadCopyWith<_ChangeSeatPayload> get copyWith => __$ChangeSeatPayloadCopyWithImpl<_ChangeSeatPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangeSeatPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangeSeatPayload&&(identical(other.seat, seat) || other.seat == seat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seat);
}

@override
String toString() {
    return 'ChangeSeatPayload(seat: $seat)';
}


}

/// @nodoc
abstract mixin class _$ChangeSeatPayloadCopyWith<$Res> implements $ChangeSeatPayloadCopyWith<$Res> {
  factory _$ChangeSeatPayloadCopyWith(_ChangeSeatPayload value, $Res Function(_ChangeSeatPayload) _then) = __$ChangeSeatPayloadCopyWithImpl;
@override @useResult
$Res call({
 int seat
});




}
/// @nodoc
class __$ChangeSeatPayloadCopyWithImpl<$Res>
    implements _$ChangeSeatPayloadCopyWith<$Res> {
  __$ChangeSeatPayloadCopyWithImpl(this._self, this._then);

  final _ChangeSeatPayload _self;
  final $Res Function(_ChangeSeatPayload) _then;

/// Create a copy of ChangeSeatPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seat = null,}) {
  return _then(_ChangeSeatPayload(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PreActionPayload {

 String get kind;
/// Create a copy of PreActionPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreActionPayloadCopyWith<PreActionPayload> get copyWith => _$PreActionPayloadCopyWithImpl<PreActionPayload>(this as PreActionPayload, _$identity);

  /// Serializes this PreActionPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PreActionPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreActionPayload&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PreActionPayload;
  return Object.hash(runtimeType,_this.kind);
}

@override
String toString() {
  final _this = this as PreActionPayload;
  return 'PreActionPayload(kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $PreActionPayloadCopyWith<$Res>  {
  factory $PreActionPayloadCopyWith(PreActionPayload value, $Res Function(PreActionPayload) _then) = _$PreActionPayloadCopyWithImpl;
@useResult
$Res call({
 String kind
});




}
/// @nodoc
class _$PreActionPayloadCopyWithImpl<$Res>
    implements $PreActionPayloadCopyWith<$Res> {
  _$PreActionPayloadCopyWithImpl(this._self, this._then);

  final PreActionPayload _self;
  final $Res Function(PreActionPayload) _then;

/// Create a copy of PreActionPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,}) {
  return _then(PreActionPayload(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PreActionPayload].
extension PreActionPayloadPatterns on PreActionPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreActionPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreActionPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreActionPayload value)  $default,){
final _that = this;
switch (_that) {
case _PreActionPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreActionPayload value)?  $default,){
final _that = this;
switch (_that) {
case _PreActionPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreActionPayload() when $default != null:
return $default(_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind)  $default,) {final _that = this;
switch (_that) {
case _PreActionPayload():
return $default(_that.kind);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind)?  $default,) {final _that = this;
switch (_that) {
case _PreActionPayload() when $default != null:
return $default(_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreActionPayload implements PreActionPayload {
  const _PreActionPayload({required this.kind});
  factory _PreActionPayload.fromJson(Map<String, dynamic> json) => _$PreActionPayloadFromJson(json);

@override final  String kind;

/// Create a copy of PreActionPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreActionPayloadCopyWith<_PreActionPayload> get copyWith => __$PreActionPayloadCopyWithImpl<_PreActionPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreActionPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreActionPayload&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind);
}

@override
String toString() {
    return 'PreActionPayload(kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$PreActionPayloadCopyWith<$Res> implements $PreActionPayloadCopyWith<$Res> {
  factory _$PreActionPayloadCopyWith(_PreActionPayload value, $Res Function(_PreActionPayload) _then) = __$PreActionPayloadCopyWithImpl;
@override @useResult
$Res call({
 String kind
});




}
/// @nodoc
class __$PreActionPayloadCopyWithImpl<$Res>
    implements _$PreActionPayloadCopyWith<$Res> {
  __$PreActionPayloadCopyWithImpl(this._self, this._then);

  final _PreActionPayload _self;
  final $Res Function(_PreActionPayload) _then;

/// Create a copy of PreActionPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(_PreActionPayload(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Hello {

 int get v; String get token;@JsonKey(includeIfNull: false) String? get adminToken;
/// Create a copy of Hello
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelloCopyWith<Hello> get copyWith => _$HelloCopyWithImpl<Hello>(this as Hello, _$identity);

  /// Serializes this Hello to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Hello;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Hello&&(identical(other.v, _this.v) || other.v == _this.v)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.adminToken, _this.adminToken) || other.adminToken == _this.adminToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Hello;
  return Object.hash(runtimeType,_this.v,_this.token,_this.adminToken);
}

@override
String toString() {
  final _this = this as Hello;
  return 'Hello(v: ${_this.v}, token: ${_this.token}, adminToken: ${_this.adminToken})';
}


}

/// @nodoc
abstract mixin class $HelloCopyWith<$Res>  {
  factory $HelloCopyWith(Hello value, $Res Function(Hello) _then) = _$HelloCopyWithImpl;
@useResult
$Res call({
 int v, String token,@JsonKey(includeIfNull: false) String? adminToken
});




}
/// @nodoc
class _$HelloCopyWithImpl<$Res>
    implements $HelloCopyWith<$Res> {
  _$HelloCopyWithImpl(this._self, this._then);

  final Hello _self;
  final $Res Function(Hello) _then;

/// Create a copy of Hello
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? v = null,Object? token = null,Object? adminToken = freezed,}) {
  return _then(Hello(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,adminToken: freezed == adminToken ? _self.adminToken : adminToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Hello].
extension HelloPatterns on Hello {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Hello value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Hello() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Hello value)  $default,){
final _that = this;
switch (_that) {
case _Hello():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Hello value)?  $default,){
final _that = this;
switch (_that) {
case _Hello() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int v,  String token, @JsonKey(includeIfNull: false)  String? adminToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Hello() when $default != null:
return $default(_that.v,_that.token,_that.adminToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int v,  String token, @JsonKey(includeIfNull: false)  String? adminToken)  $default,) {final _that = this;
switch (_that) {
case _Hello():
return $default(_that.v,_that.token,_that.adminToken);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int v,  String token, @JsonKey(includeIfNull: false)  String? adminToken)?  $default,) {final _that = this;
switch (_that) {
case _Hello() when $default != null:
return $default(_that.v,_that.token,_that.adminToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Hello implements Hello {
  const _Hello({required this.v, required this.token, @JsonKey(includeIfNull: false) this.adminToken});
  factory _Hello.fromJson(Map<String, dynamic> json) => _$HelloFromJson(json);

@override final  int v;
@override final  String token;
@override@JsonKey(includeIfNull: false) final  String? adminToken;

/// Create a copy of Hello
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelloCopyWith<_Hello> get copyWith => __$HelloCopyWithImpl<_Hello>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelloToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Hello&&(identical(other.v, v) || other.v == v)&&(identical(other.token, token) || other.token == token)&&(identical(other.adminToken, adminToken) || other.adminToken == adminToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,v,token,adminToken);
}

@override
String toString() {
    return 'Hello(v: $v, token: $token, adminToken: $adminToken)';
}


}

/// @nodoc
abstract mixin class _$HelloCopyWith<$Res> implements $HelloCopyWith<$Res> {
  factory _$HelloCopyWith(_Hello value, $Res Function(_Hello) _then) = __$HelloCopyWithImpl;
@override @useResult
$Res call({
 int v, String token,@JsonKey(includeIfNull: false) String? adminToken
});




}
/// @nodoc
class __$HelloCopyWithImpl<$Res>
    implements _$HelloCopyWith<$Res> {
  __$HelloCopyWithImpl(this._self, this._then);

  final _Hello _self;
  final $Res Function(_Hello) _then;

/// Create a copy of Hello
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? v = null,Object? token = null,Object? adminToken = freezed,}) {
  return _then(_Hello(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,adminToken: freezed == adminToken ? _self.adminToken : adminToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ActionPayload {

 String get kind;@JsonKey(includeIfNull: false) int? get amount;
/// Create a copy of ActionPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionPayloadCopyWith<ActionPayload> get copyWith => _$ActionPayloadCopyWithImpl<ActionPayload>(this as ActionPayload, _$identity);

  /// Serializes this ActionPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActionPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionPayload&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.amount, _this.amount) || other.amount == _this.amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActionPayload;
  return Object.hash(runtimeType,_this.kind,_this.amount);
}

@override
String toString() {
  final _this = this as ActionPayload;
  return 'ActionPayload(kind: ${_this.kind}, amount: ${_this.amount})';
}


}

/// @nodoc
abstract mixin class $ActionPayloadCopyWith<$Res>  {
  factory $ActionPayloadCopyWith(ActionPayload value, $Res Function(ActionPayload) _then) = _$ActionPayloadCopyWithImpl;
@useResult
$Res call({
 String kind,@JsonKey(includeIfNull: false) int? amount
});




}
/// @nodoc
class _$ActionPayloadCopyWithImpl<$Res>
    implements $ActionPayloadCopyWith<$Res> {
  _$ActionPayloadCopyWithImpl(this._self, this._then);

  final ActionPayload _self;
  final $Res Function(ActionPayload) _then;

/// Create a copy of ActionPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? amount = freezed,}) {
  return _then(ActionPayload(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionPayload].
extension ActionPayloadPatterns on ActionPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionPayload value)  $default,){
final _that = this;
switch (_that) {
case _ActionPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ActionPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind, @JsonKey(includeIfNull: false)  int? amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionPayload() when $default != null:
return $default(_that.kind,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind, @JsonKey(includeIfNull: false)  int? amount)  $default,) {final _that = this;
switch (_that) {
case _ActionPayload():
return $default(_that.kind,_that.amount);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind, @JsonKey(includeIfNull: false)  int? amount)?  $default,) {final _that = this;
switch (_that) {
case _ActionPayload() when $default != null:
return $default(_that.kind,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionPayload implements ActionPayload {
  const _ActionPayload({required this.kind, @JsonKey(includeIfNull: false) this.amount});
  factory _ActionPayload.fromJson(Map<String, dynamic> json) => _$ActionPayloadFromJson(json);

@override final  String kind;
@override@JsonKey(includeIfNull: false) final  int? amount;

/// Create a copy of ActionPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionPayloadCopyWith<_ActionPayload> get copyWith => __$ActionPayloadCopyWithImpl<_ActionPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionPayload&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,amount);
}

@override
String toString() {
    return 'ActionPayload(kind: $kind, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$ActionPayloadCopyWith<$Res> implements $ActionPayloadCopyWith<$Res> {
  factory _$ActionPayloadCopyWith(_ActionPayload value, $Res Function(_ActionPayload) _then) = __$ActionPayloadCopyWithImpl;
@override @useResult
$Res call({
 String kind,@JsonKey(includeIfNull: false) int? amount
});




}
/// @nodoc
class __$ActionPayloadCopyWithImpl<$Res>
    implements _$ActionPayloadCopyWith<$Res> {
  __$ActionPayloadCopyWithImpl(this._self, this._then);

  final _ActionPayload _self;
  final $Res Function(_ActionPayload) _then;

/// Create a copy of ActionPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? amount = freezed,}) {
  return _then(_ActionPayload(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ChatPayload {

 String get text;
/// Create a copy of ChatPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatPayloadCopyWith<ChatPayload> get copyWith => _$ChatPayloadCopyWithImpl<ChatPayload>(this as ChatPayload, _$identity);

  /// Serializes this ChatPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatPayload&&(identical(other.text, _this.text) || other.text == _this.text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatPayload;
  return Object.hash(runtimeType,_this.text);
}

@override
String toString() {
  final _this = this as ChatPayload;
  return 'ChatPayload(text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $ChatPayloadCopyWith<$Res>  {
  factory $ChatPayloadCopyWith(ChatPayload value, $Res Function(ChatPayload) _then) = _$ChatPayloadCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ChatPayloadCopyWithImpl<$Res>
    implements $ChatPayloadCopyWith<$Res> {
  _$ChatPayloadCopyWithImpl(this._self, this._then);

  final ChatPayload _self;
  final $Res Function(ChatPayload) _then;

/// Create a copy of ChatPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,}) {
  return _then(ChatPayload(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatPayload].
extension ChatPayloadPatterns on ChatPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatPayload value)  $default,){
final _that = this;
switch (_that) {
case _ChatPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ChatPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatPayload() when $default != null:
return $default(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text)  $default,) {final _that = this;
switch (_that) {
case _ChatPayload():
return $default(_that.text);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text)?  $default,) {final _that = this;
switch (_that) {
case _ChatPayload() when $default != null:
return $default(_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatPayload implements ChatPayload {
  const _ChatPayload({required this.text});
  factory _ChatPayload.fromJson(Map<String, dynamic> json) => _$ChatPayloadFromJson(json);

@override final  String text;

/// Create a copy of ChatPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatPayloadCopyWith<_ChatPayload> get copyWith => __$ChatPayloadCopyWithImpl<_ChatPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatPayload&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text);
}

@override
String toString() {
    return 'ChatPayload(text: $text)';
}


}

/// @nodoc
abstract mixin class _$ChatPayloadCopyWith<$Res> implements $ChatPayloadCopyWith<$Res> {
  factory _$ChatPayloadCopyWith(_ChatPayload value, $Res Function(_ChatPayload) _then) = __$ChatPayloadCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class __$ChatPayloadCopyWithImpl<$Res>
    implements _$ChatPayloadCopyWith<$Res> {
  __$ChatPayloadCopyWithImpl(this._self, this._then);

  final _ChatPayload _self;
  final $Res Function(_ChatPayload) _then;

/// Create a copy of ChatPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_ChatPayload(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$YouIdentity {

 String get role;@JsonKey(includeIfNull: false) String? get playerId;@JsonKey(includeIfNull: false) int? get seat;
/// Create a copy of YouIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouIdentityCopyWith<YouIdentity> get copyWith => _$YouIdentityCopyWithImpl<YouIdentity>(this as YouIdentity, _$identity);

  /// Serializes this YouIdentity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as YouIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouIdentity&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.seat, _this.seat) || other.seat == _this.seat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as YouIdentity;
  return Object.hash(runtimeType,_this.role,_this.playerId,_this.seat);
}

@override
String toString() {
  final _this = this as YouIdentity;
  return 'YouIdentity(role: ${_this.role}, playerId: ${_this.playerId}, seat: ${_this.seat})';
}


}

/// @nodoc
abstract mixin class $YouIdentityCopyWith<$Res>  {
  factory $YouIdentityCopyWith(YouIdentity value, $Res Function(YouIdentity) _then) = _$YouIdentityCopyWithImpl;
@useResult
$Res call({
 String role,@JsonKey(includeIfNull: false) String? playerId,@JsonKey(includeIfNull: false) int? seat
});




}
/// @nodoc
class _$YouIdentityCopyWithImpl<$Res>
    implements $YouIdentityCopyWith<$Res> {
  _$YouIdentityCopyWithImpl(this._self, this._then);

  final YouIdentity _self;
  final $Res Function(YouIdentity) _then;

/// Create a copy of YouIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? playerId = freezed,Object? seat = freezed,}) {
  return _then(YouIdentity(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String?,seat: freezed == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouIdentity].
extension YouIdentityPatterns on YouIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouIdentity() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouIdentity value)  $default,){
final _that = this;
switch (_that) {
case _YouIdentity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _YouIdentity() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role, @JsonKey(includeIfNull: false)  String? playerId, @JsonKey(includeIfNull: false)  int? seat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouIdentity() when $default != null:
return $default(_that.role,_that.playerId,_that.seat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role, @JsonKey(includeIfNull: false)  String? playerId, @JsonKey(includeIfNull: false)  int? seat)  $default,) {final _that = this;
switch (_that) {
case _YouIdentity():
return $default(_that.role,_that.playerId,_that.seat);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role, @JsonKey(includeIfNull: false)  String? playerId, @JsonKey(includeIfNull: false)  int? seat)?  $default,) {final _that = this;
switch (_that) {
case _YouIdentity() when $default != null:
return $default(_that.role,_that.playerId,_that.seat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YouIdentity implements YouIdentity {
  const _YouIdentity({required this.role, @JsonKey(includeIfNull: false) this.playerId, @JsonKey(includeIfNull: false) this.seat});
  factory _YouIdentity.fromJson(Map<String, dynamic> json) => _$YouIdentityFromJson(json);

@override final  String role;
@override@JsonKey(includeIfNull: false) final  String? playerId;
@override@JsonKey(includeIfNull: false) final  int? seat;

/// Create a copy of YouIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouIdentityCopyWith<_YouIdentity> get copyWith => __$YouIdentityCopyWithImpl<_YouIdentity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YouIdentityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouIdentity&&(identical(other.role, role) || other.role == role)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.seat, seat) || other.seat == seat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,role,playerId,seat);
}

@override
String toString() {
    return 'YouIdentity(role: $role, playerId: $playerId, seat: $seat)';
}


}

/// @nodoc
abstract mixin class _$YouIdentityCopyWith<$Res> implements $YouIdentityCopyWith<$Res> {
  factory _$YouIdentityCopyWith(_YouIdentity value, $Res Function(_YouIdentity) _then) = __$YouIdentityCopyWithImpl;
@override @useResult
$Res call({
 String role,@JsonKey(includeIfNull: false) String? playerId,@JsonKey(includeIfNull: false) int? seat
});




}
/// @nodoc
class __$YouIdentityCopyWithImpl<$Res>
    implements _$YouIdentityCopyWith<$Res> {
  __$YouIdentityCopyWithImpl(this._self, this._then);

  final _YouIdentity _self;
  final $Res Function(_YouIdentity) _then;

/// Create a copy of YouIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? playerId = freezed,Object? seat = freezed,}) {
  return _then(_YouIdentity(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String?,seat: freezed == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Welcome {

 YouIdentity get you; Snapshot get snapshot;
/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WelcomeCopyWith<Welcome> get copyWith => _$WelcomeCopyWithImpl<Welcome>(this as Welcome, _$identity);

  /// Serializes this Welcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Welcome;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Welcome&&(identical(other.you, _this.you) || other.you == _this.you)&&(identical(other.snapshot, _this.snapshot) || other.snapshot == _this.snapshot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Welcome;
  return Object.hash(runtimeType,_this.you,_this.snapshot);
}

@override
String toString() {
  final _this = this as Welcome;
  return 'Welcome(you: ${_this.you}, snapshot: ${_this.snapshot})';
}


}

/// @nodoc
abstract mixin class $WelcomeCopyWith<$Res>  {
  factory $WelcomeCopyWith(Welcome value, $Res Function(Welcome) _then) = _$WelcomeCopyWithImpl;
@useResult
$Res call({
 YouIdentity you, Snapshot snapshot
});


$YouIdentityCopyWith<$Res> get you;$SnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class _$WelcomeCopyWithImpl<$Res>
    implements $WelcomeCopyWith<$Res> {
  _$WelcomeCopyWithImpl(this._self, this._then);

  final Welcome _self;
  final $Res Function(Welcome) _then;

/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? you = null,Object? snapshot = null,}) {
  return _then(Welcome(
you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as YouIdentity,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as Snapshot,
  ));
}
/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouIdentityCopyWith<$Res> get you {
  
  return $YouIdentityCopyWith<$Res>(_self.you, (value) {
    return _then(_self.copyWith(you: value));
  });
}/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SnapshotCopyWith<$Res> get snapshot {
  
  return $SnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [Welcome].
extension WelcomePatterns on Welcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Welcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Welcome() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Welcome value)  $default,){
final _that = this;
switch (_that) {
case _Welcome():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Welcome value)?  $default,){
final _that = this;
switch (_that) {
case _Welcome() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( YouIdentity you,  Snapshot snapshot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Welcome() when $default != null:
return $default(_that.you,_that.snapshot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( YouIdentity you,  Snapshot snapshot)  $default,) {final _that = this;
switch (_that) {
case _Welcome():
return $default(_that.you,_that.snapshot);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( YouIdentity you,  Snapshot snapshot)?  $default,) {final _that = this;
switch (_that) {
case _Welcome() when $default != null:
return $default(_that.you,_that.snapshot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Welcome implements Welcome {
  const _Welcome({required this.you, required this.snapshot});
  factory _Welcome.fromJson(Map<String, dynamic> json) => _$WelcomeFromJson(json);

@override final  YouIdentity you;
@override final  Snapshot snapshot;

/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WelcomeCopyWith<_Welcome> get copyWith => __$WelcomeCopyWithImpl<_Welcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WelcomeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Welcome&&(identical(other.you, you) || other.you == you)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,you,snapshot);
}

@override
String toString() {
    return 'Welcome(you: $you, snapshot: $snapshot)';
}


}

/// @nodoc
abstract mixin class _$WelcomeCopyWith<$Res> implements $WelcomeCopyWith<$Res> {
  factory _$WelcomeCopyWith(_Welcome value, $Res Function(_Welcome) _then) = __$WelcomeCopyWithImpl;
@override @useResult
$Res call({
 YouIdentity you, Snapshot snapshot
});


@override $YouIdentityCopyWith<$Res> get you;@override $SnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class __$WelcomeCopyWithImpl<$Res>
    implements _$WelcomeCopyWith<$Res> {
  __$WelcomeCopyWithImpl(this._self, this._then);

  final _Welcome _self;
  final $Res Function(_Welcome) _then;

/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? you = null,Object? snapshot = null,}) {
  return _then(_Welcome(
you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as YouIdentity,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as Snapshot,
  ));
}

/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouIdentityCopyWith<$Res> get you {
  
  return $YouIdentityCopyWith<$Res>(_self.you, (value) {
    return _then(_self.copyWith(you: value));
  });
}/// Create a copy of Welcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SnapshotCopyWith<$Res> get snapshot {
  
  return $SnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// @nodoc
mixin _$Snapshot {

 int get serverTs; TableInfo get table; List<SeatView> get seats; HandView? get hand; You get you; List<LeaderboardEntry> get leaderboard; int get spectators;@JsonKey(includeIfNull: false) List<String>? get spectatorNames;
/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnapshotCopyWith<Snapshot> get copyWith => _$SnapshotCopyWithImpl<Snapshot>(this as Snapshot, _$identity);

  /// Serializes this Snapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Snapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Snapshot&&(identical(other.serverTs, _this.serverTs) || other.serverTs == _this.serverTs)&&(identical(other.table, _this.table) || other.table == _this.table)&&const DeepCollectionEquality().equals(other.seats, _this.seats)&&(identical(other.hand, _this.hand) || other.hand == _this.hand)&&(identical(other.you, _this.you) || other.you == _this.you)&&const DeepCollectionEquality().equals(other.leaderboard, _this.leaderboard)&&(identical(other.spectators, _this.spectators) || other.spectators == _this.spectators)&&const DeepCollectionEquality().equals(other.spectatorNames, _this.spectatorNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Snapshot;
  return Object.hash(runtimeType,_this.serverTs,_this.table,const DeepCollectionEquality().hash(_this.seats),_this.hand,_this.you,const DeepCollectionEquality().hash(_this.leaderboard),_this.spectators,const DeepCollectionEquality().hash(_this.spectatorNames));
}

@override
String toString() {
  final _this = this as Snapshot;
  return 'Snapshot(serverTs: ${_this.serverTs}, table: ${_this.table}, seats: ${_this.seats}, hand: ${_this.hand}, you: ${_this.you}, leaderboard: ${_this.leaderboard}, spectators: ${_this.spectators}, spectatorNames: ${_this.spectatorNames})';
}


}

/// @nodoc
abstract mixin class $SnapshotCopyWith<$Res>  {
  factory $SnapshotCopyWith(Snapshot value, $Res Function(Snapshot) _then) = _$SnapshotCopyWithImpl;
@useResult
$Res call({
 int serverTs, TableInfo table, List<SeatView> seats, HandView? hand, You you, List<LeaderboardEntry> leaderboard, int spectators,@JsonKey(includeIfNull: false) List<String>? spectatorNames
});


$TableInfoCopyWith<$Res> get table;$HandViewCopyWith<$Res>? get hand;$YouCopyWith<$Res> get you;

}
/// @nodoc
class _$SnapshotCopyWithImpl<$Res>
    implements $SnapshotCopyWith<$Res> {
  _$SnapshotCopyWithImpl(this._self, this._then);

  final Snapshot _self;
  final $Res Function(Snapshot) _then;

/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverTs = null,Object? table = null,Object? seats = null,Object? hand = freezed,Object? you = null,Object? leaderboard = null,Object? spectators = null,Object? spectatorNames = freezed,}) {
  return _then(Snapshot(
serverTs: null == serverTs ? _self.serverTs : serverTs // ignore: cast_nullable_to_non_nullable
as int,table: null == table ? _self.table : table // ignore: cast_nullable_to_non_nullable
as TableInfo,seats: null == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as List<SeatView>,hand: freezed == hand ? _self.hand : hand // ignore: cast_nullable_to_non_nullable
as HandView?,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as You,leaderboard: null == leaderboard ? _self.leaderboard : leaderboard // ignore: cast_nullable_to_non_nullable
as List<LeaderboardEntry>,spectators: null == spectators ? _self.spectators : spectators // ignore: cast_nullable_to_non_nullable
as int,spectatorNames: freezed == spectatorNames ? _self.spectatorNames : spectatorNames // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TableInfoCopyWith<$Res> get table {
  
  return $TableInfoCopyWith<$Res>(_self.table, (value) {
    return _then(_self.copyWith(table: value));
  });
}/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HandViewCopyWith<$Res>? get hand {
    if (_self.hand == null) {
    return null;
  }

  return $HandViewCopyWith<$Res>(_self.hand!, (value) {
    return _then(_self.copyWith(hand: value));
  });
}/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouCopyWith<$Res> get you {
  
  return $YouCopyWith<$Res>(_self.you, (value) {
    return _then(_self.copyWith(you: value));
  });
}
}


/// Adds pattern-matching-related methods to [Snapshot].
extension SnapshotPatterns on Snapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Snapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Snapshot value)  $default,){
final _that = this;
switch (_that) {
case _Snapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Snapshot value)?  $default,){
final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int serverTs,  TableInfo table,  List<SeatView> seats,  HandView? hand,  You you,  List<LeaderboardEntry> leaderboard,  int spectators, @JsonKey(includeIfNull: false)  List<String>? spectatorNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
return $default(_that.serverTs,_that.table,_that.seats,_that.hand,_that.you,_that.leaderboard,_that.spectators,_that.spectatorNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int serverTs,  TableInfo table,  List<SeatView> seats,  HandView? hand,  You you,  List<LeaderboardEntry> leaderboard,  int spectators, @JsonKey(includeIfNull: false)  List<String>? spectatorNames)  $default,) {final _that = this;
switch (_that) {
case _Snapshot():
return $default(_that.serverTs,_that.table,_that.seats,_that.hand,_that.you,_that.leaderboard,_that.spectators,_that.spectatorNames);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int serverTs,  TableInfo table,  List<SeatView> seats,  HandView? hand,  You you,  List<LeaderboardEntry> leaderboard,  int spectators, @JsonKey(includeIfNull: false)  List<String>? spectatorNames)?  $default,) {final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
return $default(_that.serverTs,_that.table,_that.seats,_that.hand,_that.you,_that.leaderboard,_that.spectators,_that.spectatorNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Snapshot implements Snapshot {
  const _Snapshot({required this.serverTs, required this.table, required  List<SeatView> seats, required this.hand, required this.you, required  List<LeaderboardEntry> leaderboard, required this.spectators, @JsonKey(includeIfNull: false)  List<String>? spectatorNames}): _seats = seats,_leaderboard = leaderboard,_spectatorNames = spectatorNames;
  factory _Snapshot.fromJson(Map<String, dynamic> json) => _$SnapshotFromJson(json);

@override final  int serverTs;
@override final  TableInfo table;
 final  List<SeatView> _seats;
@override List<SeatView> get seats {
  if (_seats is EqualUnmodifiableListView) return _seats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seats);
}

@override final  HandView? hand;
@override final  You you;
 final  List<LeaderboardEntry> _leaderboard;
@override List<LeaderboardEntry> get leaderboard {
  if (_leaderboard is EqualUnmodifiableListView) return _leaderboard;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_leaderboard);
}

@override final  int spectators;
 final  List<String>? _spectatorNames;
@override@JsonKey(includeIfNull: false) List<String>? get spectatorNames {
  final value = _spectatorNames;
  if (value == null) return null;
  if (_spectatorNames is EqualUnmodifiableListView) return _spectatorNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnapshotCopyWith<_Snapshot> get copyWith => __$SnapshotCopyWithImpl<_Snapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Snapshot&&(identical(other.serverTs, serverTs) || other.serverTs == serverTs)&&(identical(other.table, table) || other.table == table)&&const DeepCollectionEquality().equals(other.seats, _seats)&&(identical(other.hand, hand) || other.hand == hand)&&(identical(other.you, you) || other.you == you)&&const DeepCollectionEquality().equals(other.leaderboard, _leaderboard)&&(identical(other.spectators, spectators) || other.spectators == spectators)&&const DeepCollectionEquality().equals(other.spectatorNames, _spectatorNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,serverTs,table,const DeepCollectionEquality().hash(_seats),hand,you,const DeepCollectionEquality().hash(_leaderboard),spectators,const DeepCollectionEquality().hash(_spectatorNames));
}

@override
String toString() {
    return 'Snapshot(serverTs: $serverTs, table: $table, seats: $seats, hand: $hand, you: $you, leaderboard: $leaderboard, spectators: $spectators, spectatorNames: $spectatorNames)';
}


}

/// @nodoc
abstract mixin class _$SnapshotCopyWith<$Res> implements $SnapshotCopyWith<$Res> {
  factory _$SnapshotCopyWith(_Snapshot value, $Res Function(_Snapshot) _then) = __$SnapshotCopyWithImpl;
@override @useResult
$Res call({
 int serverTs, TableInfo table, List<SeatView> seats, HandView? hand, You you, List<LeaderboardEntry> leaderboard, int spectators,@JsonKey(includeIfNull: false) List<String>? spectatorNames
});


@override $TableInfoCopyWith<$Res> get table;@override $HandViewCopyWith<$Res>? get hand;@override $YouCopyWith<$Res> get you;

}
/// @nodoc
class __$SnapshotCopyWithImpl<$Res>
    implements _$SnapshotCopyWith<$Res> {
  __$SnapshotCopyWithImpl(this._self, this._then);

  final _Snapshot _self;
  final $Res Function(_Snapshot) _then;

/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverTs = null,Object? table = null,Object? seats = null,Object? hand = freezed,Object? you = null,Object? leaderboard = null,Object? spectators = null,Object? spectatorNames = freezed,}) {
  return _then(_Snapshot(
serverTs: null == serverTs ? _self.serverTs : serverTs // ignore: cast_nullable_to_non_nullable
as int,table: null == table ? _self.table : table // ignore: cast_nullable_to_non_nullable
as TableInfo,seats: null == seats ? _self._seats : seats // ignore: cast_nullable_to_non_nullable
as List<SeatView>,hand: freezed == hand ? _self.hand : hand // ignore: cast_nullable_to_non_nullable
as HandView?,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as You,leaderboard: null == leaderboard ? _self._leaderboard : leaderboard // ignore: cast_nullable_to_non_nullable
as List<LeaderboardEntry>,spectators: null == spectators ? _self.spectators : spectators // ignore: cast_nullable_to_non_nullable
as int,spectatorNames: freezed == spectatorNames ? _self._spectatorNames : spectatorNames // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TableInfoCopyWith<$Res> get table {
  
  return $TableInfoCopyWith<$Res>(_self.table, (value) {
    return _then(_self.copyWith(table: value));
  });
}/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HandViewCopyWith<$Res>? get hand {
    if (_self.hand == null) {
    return null;
  }

  return $HandViewCopyWith<$Res>(_self.hand!, (value) {
    return _then(_self.copyWith(hand: value));
  });
}/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouCopyWith<$Res> get you {
  
  return $YouCopyWith<$Res>(_self.you, (value) {
    return _then(_self.copyWith(you: value));
  });
}
}


/// @nodoc
mixin _$TableInfo {

 String get id; String get name; String get state; int get handNumber; PublicSettings get settings;@JsonKey(includeIfNull: false) int? get nextBlindsUpTs;@JsonKey(includeIfNull: false) int? get nextHandTs;
/// Create a copy of TableInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableInfoCopyWith<TableInfo> get copyWith => _$TableInfoCopyWithImpl<TableInfo>(this as TableInfo, _$identity);

  /// Serializes this TableInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TableInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.handNumber, _this.handNumber) || other.handNumber == _this.handNumber)&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&(identical(other.nextBlindsUpTs, _this.nextBlindsUpTs) || other.nextBlindsUpTs == _this.nextBlindsUpTs)&&(identical(other.nextHandTs, _this.nextHandTs) || other.nextHandTs == _this.nextHandTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TableInfo;
  return Object.hash(runtimeType,_this.id,_this.name,_this.state,_this.handNumber,_this.settings,_this.nextBlindsUpTs,_this.nextHandTs);
}

@override
String toString() {
  final _this = this as TableInfo;
  return 'TableInfo(id: ${_this.id}, name: ${_this.name}, state: ${_this.state}, handNumber: ${_this.handNumber}, settings: ${_this.settings}, nextBlindsUpTs: ${_this.nextBlindsUpTs}, nextHandTs: ${_this.nextHandTs})';
}


}

/// @nodoc
abstract mixin class $TableInfoCopyWith<$Res>  {
  factory $TableInfoCopyWith(TableInfo value, $Res Function(TableInfo) _then) = _$TableInfoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String state, int handNumber, PublicSettings settings,@JsonKey(includeIfNull: false) int? nextBlindsUpTs,@JsonKey(includeIfNull: false) int? nextHandTs
});


$PublicSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$TableInfoCopyWithImpl<$Res>
    implements $TableInfoCopyWith<$Res> {
  _$TableInfoCopyWithImpl(this._self, this._then);

  final TableInfo _self;
  final $Res Function(TableInfo) _then;

/// Create a copy of TableInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? state = null,Object? handNumber = null,Object? settings = null,Object? nextBlindsUpTs = freezed,Object? nextHandTs = freezed,}) {
  return _then(TableInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,handNumber: null == handNumber ? _self.handNumber : handNumber // ignore: cast_nullable_to_non_nullable
as int,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as PublicSettings,nextBlindsUpTs: freezed == nextBlindsUpTs ? _self.nextBlindsUpTs : nextBlindsUpTs // ignore: cast_nullable_to_non_nullable
as int?,nextHandTs: freezed == nextHandTs ? _self.nextHandTs : nextHandTs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of TableInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PublicSettingsCopyWith<$Res> get settings {
  
  return $PublicSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [TableInfo].
extension TableInfoPatterns on TableInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableInfo value)  $default,){
final _that = this;
switch (_that) {
case _TableInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableInfo value)?  $default,){
final _that = this;
switch (_that) {
case _TableInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String state,  int handNumber,  PublicSettings settings, @JsonKey(includeIfNull: false)  int? nextBlindsUpTs, @JsonKey(includeIfNull: false)  int? nextHandTs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableInfo() when $default != null:
return $default(_that.id,_that.name,_that.state,_that.handNumber,_that.settings,_that.nextBlindsUpTs,_that.nextHandTs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String state,  int handNumber,  PublicSettings settings, @JsonKey(includeIfNull: false)  int? nextBlindsUpTs, @JsonKey(includeIfNull: false)  int? nextHandTs)  $default,) {final _that = this;
switch (_that) {
case _TableInfo():
return $default(_that.id,_that.name,_that.state,_that.handNumber,_that.settings,_that.nextBlindsUpTs,_that.nextHandTs);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String state,  int handNumber,  PublicSettings settings, @JsonKey(includeIfNull: false)  int? nextBlindsUpTs, @JsonKey(includeIfNull: false)  int? nextHandTs)?  $default,) {final _that = this;
switch (_that) {
case _TableInfo() when $default != null:
return $default(_that.id,_that.name,_that.state,_that.handNumber,_that.settings,_that.nextBlindsUpTs,_that.nextHandTs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TableInfo implements TableInfo {
  const _TableInfo({required this.id, required this.name, required this.state, required this.handNumber, required this.settings, @JsonKey(includeIfNull: false) this.nextBlindsUpTs, @JsonKey(includeIfNull: false) this.nextHandTs});
  factory _TableInfo.fromJson(Map<String, dynamic> json) => _$TableInfoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String state;
@override final  int handNumber;
@override final  PublicSettings settings;
@override@JsonKey(includeIfNull: false) final  int? nextBlindsUpTs;
@override@JsonKey(includeIfNull: false) final  int? nextHandTs;

/// Create a copy of TableInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableInfoCopyWith<_TableInfo> get copyWith => __$TableInfoCopyWithImpl<_TableInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.state, state) || other.state == state)&&(identical(other.handNumber, handNumber) || other.handNumber == handNumber)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.nextBlindsUpTs, nextBlindsUpTs) || other.nextBlindsUpTs == nextBlindsUpTs)&&(identical(other.nextHandTs, nextHandTs) || other.nextHandTs == nextHandTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,state,handNumber,settings,nextBlindsUpTs,nextHandTs);
}

@override
String toString() {
    return 'TableInfo(id: $id, name: $name, state: $state, handNumber: $handNumber, settings: $settings, nextBlindsUpTs: $nextBlindsUpTs, nextHandTs: $nextHandTs)';
}


}

/// @nodoc
abstract mixin class _$TableInfoCopyWith<$Res> implements $TableInfoCopyWith<$Res> {
  factory _$TableInfoCopyWith(_TableInfo value, $Res Function(_TableInfo) _then) = __$TableInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String state, int handNumber, PublicSettings settings,@JsonKey(includeIfNull: false) int? nextBlindsUpTs,@JsonKey(includeIfNull: false) int? nextHandTs
});


@override $PublicSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$TableInfoCopyWithImpl<$Res>
    implements _$TableInfoCopyWith<$Res> {
  __$TableInfoCopyWithImpl(this._self, this._then);

  final _TableInfo _self;
  final $Res Function(_TableInfo) _then;

/// Create a copy of TableInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? state = null,Object? handNumber = null,Object? settings = null,Object? nextBlindsUpTs = freezed,Object? nextHandTs = freezed,}) {
  return _then(_TableInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,handNumber: null == handNumber ? _self.handNumber : handNumber // ignore: cast_nullable_to_non_nullable
as int,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as PublicSettings,nextBlindsUpTs: freezed == nextBlindsUpTs ? _self.nextBlindsUpTs : nextBlindsUpTs // ignore: cast_nullable_to_non_nullable
as int?,nextHandTs: freezed == nextHandTs ? _self.nextHandTs : nextHandTs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of TableInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PublicSettingsCopyWith<$Res> get settings {
  
  return $PublicSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// @nodoc
mixin _$PublicSettings {

 int get smallBlind; int get bigBlind; int get ante; int get turnTime; int get maxPlayers; int get startMoney; String get joinPolicy; bool get allowRebuy; String get showdownReveal; bool get chatEnabled; bool get spectatorChat; bool get requiresPassword; bool get allowRabbitHunt; int get blindsUpMinutes; int get blindsUpPercent; int get timeBankSeconds; bool get allowStraddle; bool get runItTwice;
/// Create a copy of PublicSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicSettingsCopyWith<PublicSettings> get copyWith => _$PublicSettingsCopyWithImpl<PublicSettings>(this as PublicSettings, _$identity);

  /// Serializes this PublicSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PublicSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicSettings&&(identical(other.smallBlind, _this.smallBlind) || other.smallBlind == _this.smallBlind)&&(identical(other.bigBlind, _this.bigBlind) || other.bigBlind == _this.bigBlind)&&(identical(other.ante, _this.ante) || other.ante == _this.ante)&&(identical(other.turnTime, _this.turnTime) || other.turnTime == _this.turnTime)&&(identical(other.maxPlayers, _this.maxPlayers) || other.maxPlayers == _this.maxPlayers)&&(identical(other.startMoney, _this.startMoney) || other.startMoney == _this.startMoney)&&(identical(other.joinPolicy, _this.joinPolicy) || other.joinPolicy == _this.joinPolicy)&&(identical(other.allowRebuy, _this.allowRebuy) || other.allowRebuy == _this.allowRebuy)&&(identical(other.showdownReveal, _this.showdownReveal) || other.showdownReveal == _this.showdownReveal)&&(identical(other.chatEnabled, _this.chatEnabled) || other.chatEnabled == _this.chatEnabled)&&(identical(other.spectatorChat, _this.spectatorChat) || other.spectatorChat == _this.spectatorChat)&&(identical(other.requiresPassword, _this.requiresPassword) || other.requiresPassword == _this.requiresPassword)&&(identical(other.allowRabbitHunt, _this.allowRabbitHunt) || other.allowRabbitHunt == _this.allowRabbitHunt)&&(identical(other.blindsUpMinutes, _this.blindsUpMinutes) || other.blindsUpMinutes == _this.blindsUpMinutes)&&(identical(other.blindsUpPercent, _this.blindsUpPercent) || other.blindsUpPercent == _this.blindsUpPercent)&&(identical(other.timeBankSeconds, _this.timeBankSeconds) || other.timeBankSeconds == _this.timeBankSeconds)&&(identical(other.allowStraddle, _this.allowStraddle) || other.allowStraddle == _this.allowStraddle)&&(identical(other.runItTwice, _this.runItTwice) || other.runItTwice == _this.runItTwice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PublicSettings;
  return Object.hash(runtimeType,_this.smallBlind,_this.bigBlind,_this.ante,_this.turnTime,_this.maxPlayers,_this.startMoney,_this.joinPolicy,_this.allowRebuy,_this.showdownReveal,_this.chatEnabled,_this.spectatorChat,_this.requiresPassword,_this.allowRabbitHunt,_this.blindsUpMinutes,_this.blindsUpPercent,_this.timeBankSeconds,_this.allowStraddle,_this.runItTwice);
}

@override
String toString() {
  final _this = this as PublicSettings;
  return 'PublicSettings(smallBlind: ${_this.smallBlind}, bigBlind: ${_this.bigBlind}, ante: ${_this.ante}, turnTime: ${_this.turnTime}, maxPlayers: ${_this.maxPlayers}, startMoney: ${_this.startMoney}, joinPolicy: ${_this.joinPolicy}, allowRebuy: ${_this.allowRebuy}, showdownReveal: ${_this.showdownReveal}, chatEnabled: ${_this.chatEnabled}, spectatorChat: ${_this.spectatorChat}, requiresPassword: ${_this.requiresPassword}, allowRabbitHunt: ${_this.allowRabbitHunt}, blindsUpMinutes: ${_this.blindsUpMinutes}, blindsUpPercent: ${_this.blindsUpPercent}, timeBankSeconds: ${_this.timeBankSeconds}, allowStraddle: ${_this.allowStraddle}, runItTwice: ${_this.runItTwice})';
}


}

/// @nodoc
abstract mixin class $PublicSettingsCopyWith<$Res>  {
  factory $PublicSettingsCopyWith(PublicSettings value, $Res Function(PublicSettings) _then) = _$PublicSettingsCopyWithImpl;
@useResult
$Res call({
 int smallBlind, int bigBlind, int ante, int turnTime, int maxPlayers, int startMoney, String joinPolicy, bool allowRebuy, String showdownReveal, bool chatEnabled, bool spectatorChat, bool requiresPassword, bool allowRabbitHunt, int blindsUpMinutes, int blindsUpPercent, int timeBankSeconds, bool allowStraddle, bool runItTwice
});




}
/// @nodoc
class _$PublicSettingsCopyWithImpl<$Res>
    implements $PublicSettingsCopyWith<$Res> {
  _$PublicSettingsCopyWithImpl(this._self, this._then);

  final PublicSettings _self;
  final $Res Function(PublicSettings) _then;

/// Create a copy of PublicSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? smallBlind = null,Object? bigBlind = null,Object? ante = null,Object? turnTime = null,Object? maxPlayers = null,Object? startMoney = null,Object? joinPolicy = null,Object? allowRebuy = null,Object? showdownReveal = null,Object? chatEnabled = null,Object? spectatorChat = null,Object? requiresPassword = null,Object? allowRabbitHunt = null,Object? blindsUpMinutes = null,Object? blindsUpPercent = null,Object? timeBankSeconds = null,Object? allowStraddle = null,Object? runItTwice = null,}) {
  return _then(PublicSettings(
smallBlind: null == smallBlind ? _self.smallBlind : smallBlind // ignore: cast_nullable_to_non_nullable
as int,bigBlind: null == bigBlind ? _self.bigBlind : bigBlind // ignore: cast_nullable_to_non_nullable
as int,ante: null == ante ? _self.ante : ante // ignore: cast_nullable_to_non_nullable
as int,turnTime: null == turnTime ? _self.turnTime : turnTime // ignore: cast_nullable_to_non_nullable
as int,maxPlayers: null == maxPlayers ? _self.maxPlayers : maxPlayers // ignore: cast_nullable_to_non_nullable
as int,startMoney: null == startMoney ? _self.startMoney : startMoney // ignore: cast_nullable_to_non_nullable
as int,joinPolicy: null == joinPolicy ? _self.joinPolicy : joinPolicy // ignore: cast_nullable_to_non_nullable
as String,allowRebuy: null == allowRebuy ? _self.allowRebuy : allowRebuy // ignore: cast_nullable_to_non_nullable
as bool,showdownReveal: null == showdownReveal ? _self.showdownReveal : showdownReveal // ignore: cast_nullable_to_non_nullable
as String,chatEnabled: null == chatEnabled ? _self.chatEnabled : chatEnabled // ignore: cast_nullable_to_non_nullable
as bool,spectatorChat: null == spectatorChat ? _self.spectatorChat : spectatorChat // ignore: cast_nullable_to_non_nullable
as bool,requiresPassword: null == requiresPassword ? _self.requiresPassword : requiresPassword // ignore: cast_nullable_to_non_nullable
as bool,allowRabbitHunt: null == allowRabbitHunt ? _self.allowRabbitHunt : allowRabbitHunt // ignore: cast_nullable_to_non_nullable
as bool,blindsUpMinutes: null == blindsUpMinutes ? _self.blindsUpMinutes : blindsUpMinutes // ignore: cast_nullable_to_non_nullable
as int,blindsUpPercent: null == blindsUpPercent ? _self.blindsUpPercent : blindsUpPercent // ignore: cast_nullable_to_non_nullable
as int,timeBankSeconds: null == timeBankSeconds ? _self.timeBankSeconds : timeBankSeconds // ignore: cast_nullable_to_non_nullable
as int,allowStraddle: null == allowStraddle ? _self.allowStraddle : allowStraddle // ignore: cast_nullable_to_non_nullable
as bool,runItTwice: null == runItTwice ? _self.runItTwice : runItTwice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicSettings].
extension PublicSettingsPatterns on PublicSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicSettings() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicSettings value)  $default,){
final _that = this;
switch (_that) {
case _PublicSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicSettings value)?  $default,){
final _that = this;
switch (_that) {
case _PublicSettings() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int smallBlind,  int bigBlind,  int ante,  int turnTime,  int maxPlayers,  int startMoney,  String joinPolicy,  bool allowRebuy,  String showdownReveal,  bool chatEnabled,  bool spectatorChat,  bool requiresPassword,  bool allowRabbitHunt,  int blindsUpMinutes,  int blindsUpPercent,  int timeBankSeconds,  bool allowStraddle,  bool runItTwice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicSettings() when $default != null:
return $default(_that.smallBlind,_that.bigBlind,_that.ante,_that.turnTime,_that.maxPlayers,_that.startMoney,_that.joinPolicy,_that.allowRebuy,_that.showdownReveal,_that.chatEnabled,_that.spectatorChat,_that.requiresPassword,_that.allowRabbitHunt,_that.blindsUpMinutes,_that.blindsUpPercent,_that.timeBankSeconds,_that.allowStraddle,_that.runItTwice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int smallBlind,  int bigBlind,  int ante,  int turnTime,  int maxPlayers,  int startMoney,  String joinPolicy,  bool allowRebuy,  String showdownReveal,  bool chatEnabled,  bool spectatorChat,  bool requiresPassword,  bool allowRabbitHunt,  int blindsUpMinutes,  int blindsUpPercent,  int timeBankSeconds,  bool allowStraddle,  bool runItTwice)  $default,) {final _that = this;
switch (_that) {
case _PublicSettings():
return $default(_that.smallBlind,_that.bigBlind,_that.ante,_that.turnTime,_that.maxPlayers,_that.startMoney,_that.joinPolicy,_that.allowRebuy,_that.showdownReveal,_that.chatEnabled,_that.spectatorChat,_that.requiresPassword,_that.allowRabbitHunt,_that.blindsUpMinutes,_that.blindsUpPercent,_that.timeBankSeconds,_that.allowStraddle,_that.runItTwice);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int smallBlind,  int bigBlind,  int ante,  int turnTime,  int maxPlayers,  int startMoney,  String joinPolicy,  bool allowRebuy,  String showdownReveal,  bool chatEnabled,  bool spectatorChat,  bool requiresPassword,  bool allowRabbitHunt,  int blindsUpMinutes,  int blindsUpPercent,  int timeBankSeconds,  bool allowStraddle,  bool runItTwice)?  $default,) {final _that = this;
switch (_that) {
case _PublicSettings() when $default != null:
return $default(_that.smallBlind,_that.bigBlind,_that.ante,_that.turnTime,_that.maxPlayers,_that.startMoney,_that.joinPolicy,_that.allowRebuy,_that.showdownReveal,_that.chatEnabled,_that.spectatorChat,_that.requiresPassword,_that.allowRabbitHunt,_that.blindsUpMinutes,_that.blindsUpPercent,_that.timeBankSeconds,_that.allowStraddle,_that.runItTwice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicSettings implements PublicSettings {
  const _PublicSettings({required this.smallBlind, required this.bigBlind, required this.ante, required this.turnTime, required this.maxPlayers, required this.startMoney, required this.joinPolicy, required this.allowRebuy, required this.showdownReveal, required this.chatEnabled, required this.spectatorChat, required this.requiresPassword, required this.allowRabbitHunt, required this.blindsUpMinutes, required this.blindsUpPercent, this.timeBankSeconds = 0, this.allowStraddle = false, this.runItTwice = false});
  factory _PublicSettings.fromJson(Map<String, dynamic> json) => _$PublicSettingsFromJson(json);

@override final  int smallBlind;
@override final  int bigBlind;
@override final  int ante;
@override final  int turnTime;
@override final  int maxPlayers;
@override final  int startMoney;
@override final  String joinPolicy;
@override final  bool allowRebuy;
@override final  String showdownReveal;
@override final  bool chatEnabled;
@override final  bool spectatorChat;
@override final  bool requiresPassword;
@override final  bool allowRabbitHunt;
@override final  int blindsUpMinutes;
@override final  int blindsUpPercent;
@override@JsonKey() final  int timeBankSeconds;
@override@JsonKey() final  bool allowStraddle;
@override@JsonKey() final  bool runItTwice;

/// Create a copy of PublicSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicSettingsCopyWith<_PublicSettings> get copyWith => __$PublicSettingsCopyWithImpl<_PublicSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicSettings&&(identical(other.smallBlind, smallBlind) || other.smallBlind == smallBlind)&&(identical(other.bigBlind, bigBlind) || other.bigBlind == bigBlind)&&(identical(other.ante, ante) || other.ante == ante)&&(identical(other.turnTime, turnTime) || other.turnTime == turnTime)&&(identical(other.maxPlayers, maxPlayers) || other.maxPlayers == maxPlayers)&&(identical(other.startMoney, startMoney) || other.startMoney == startMoney)&&(identical(other.joinPolicy, joinPolicy) || other.joinPolicy == joinPolicy)&&(identical(other.allowRebuy, allowRebuy) || other.allowRebuy == allowRebuy)&&(identical(other.showdownReveal, showdownReveal) || other.showdownReveal == showdownReveal)&&(identical(other.chatEnabled, chatEnabled) || other.chatEnabled == chatEnabled)&&(identical(other.spectatorChat, spectatorChat) || other.spectatorChat == spectatorChat)&&(identical(other.requiresPassword, requiresPassword) || other.requiresPassword == requiresPassword)&&(identical(other.allowRabbitHunt, allowRabbitHunt) || other.allowRabbitHunt == allowRabbitHunt)&&(identical(other.blindsUpMinutes, blindsUpMinutes) || other.blindsUpMinutes == blindsUpMinutes)&&(identical(other.blindsUpPercent, blindsUpPercent) || other.blindsUpPercent == blindsUpPercent)&&(identical(other.timeBankSeconds, timeBankSeconds) || other.timeBankSeconds == timeBankSeconds)&&(identical(other.allowStraddle, allowStraddle) || other.allowStraddle == allowStraddle)&&(identical(other.runItTwice, runItTwice) || other.runItTwice == runItTwice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,smallBlind,bigBlind,ante,turnTime,maxPlayers,startMoney,joinPolicy,allowRebuy,showdownReveal,chatEnabled,spectatorChat,requiresPassword,allowRabbitHunt,blindsUpMinutes,blindsUpPercent,timeBankSeconds,allowStraddle,runItTwice);
}

@override
String toString() {
    return 'PublicSettings(smallBlind: $smallBlind, bigBlind: $bigBlind, ante: $ante, turnTime: $turnTime, maxPlayers: $maxPlayers, startMoney: $startMoney, joinPolicy: $joinPolicy, allowRebuy: $allowRebuy, showdownReveal: $showdownReveal, chatEnabled: $chatEnabled, spectatorChat: $spectatorChat, requiresPassword: $requiresPassword, allowRabbitHunt: $allowRabbitHunt, blindsUpMinutes: $blindsUpMinutes, blindsUpPercent: $blindsUpPercent, timeBankSeconds: $timeBankSeconds, allowStraddle: $allowStraddle, runItTwice: $runItTwice)';
}


}

/// @nodoc
abstract mixin class _$PublicSettingsCopyWith<$Res> implements $PublicSettingsCopyWith<$Res> {
  factory _$PublicSettingsCopyWith(_PublicSettings value, $Res Function(_PublicSettings) _then) = __$PublicSettingsCopyWithImpl;
@override @useResult
$Res call({
 int smallBlind, int bigBlind, int ante, int turnTime, int maxPlayers, int startMoney, String joinPolicy, bool allowRebuy, String showdownReveal, bool chatEnabled, bool spectatorChat, bool requiresPassword, bool allowRabbitHunt, int blindsUpMinutes, int blindsUpPercent, int timeBankSeconds, bool allowStraddle, bool runItTwice
});




}
/// @nodoc
class __$PublicSettingsCopyWithImpl<$Res>
    implements _$PublicSettingsCopyWith<$Res> {
  __$PublicSettingsCopyWithImpl(this._self, this._then);

  final _PublicSettings _self;
  final $Res Function(_PublicSettings) _then;

/// Create a copy of PublicSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? smallBlind = null,Object? bigBlind = null,Object? ante = null,Object? turnTime = null,Object? maxPlayers = null,Object? startMoney = null,Object? joinPolicy = null,Object? allowRebuy = null,Object? showdownReveal = null,Object? chatEnabled = null,Object? spectatorChat = null,Object? requiresPassword = null,Object? allowRabbitHunt = null,Object? blindsUpMinutes = null,Object? blindsUpPercent = null,Object? timeBankSeconds = null,Object? allowStraddle = null,Object? runItTwice = null,}) {
  return _then(_PublicSettings(
smallBlind: null == smallBlind ? _self.smallBlind : smallBlind // ignore: cast_nullable_to_non_nullable
as int,bigBlind: null == bigBlind ? _self.bigBlind : bigBlind // ignore: cast_nullable_to_non_nullable
as int,ante: null == ante ? _self.ante : ante // ignore: cast_nullable_to_non_nullable
as int,turnTime: null == turnTime ? _self.turnTime : turnTime // ignore: cast_nullable_to_non_nullable
as int,maxPlayers: null == maxPlayers ? _self.maxPlayers : maxPlayers // ignore: cast_nullable_to_non_nullable
as int,startMoney: null == startMoney ? _self.startMoney : startMoney // ignore: cast_nullable_to_non_nullable
as int,joinPolicy: null == joinPolicy ? _self.joinPolicy : joinPolicy // ignore: cast_nullable_to_non_nullable
as String,allowRebuy: null == allowRebuy ? _self.allowRebuy : allowRebuy // ignore: cast_nullable_to_non_nullable
as bool,showdownReveal: null == showdownReveal ? _self.showdownReveal : showdownReveal // ignore: cast_nullable_to_non_nullable
as String,chatEnabled: null == chatEnabled ? _self.chatEnabled : chatEnabled // ignore: cast_nullable_to_non_nullable
as bool,spectatorChat: null == spectatorChat ? _self.spectatorChat : spectatorChat // ignore: cast_nullable_to_non_nullable
as bool,requiresPassword: null == requiresPassword ? _self.requiresPassword : requiresPassword // ignore: cast_nullable_to_non_nullable
as bool,allowRabbitHunt: null == allowRabbitHunt ? _self.allowRabbitHunt : allowRabbitHunt // ignore: cast_nullable_to_non_nullable
as bool,blindsUpMinutes: null == blindsUpMinutes ? _self.blindsUpMinutes : blindsUpMinutes // ignore: cast_nullable_to_non_nullable
as int,blindsUpPercent: null == blindsUpPercent ? _self.blindsUpPercent : blindsUpPercent // ignore: cast_nullable_to_non_nullable
as int,timeBankSeconds: null == timeBankSeconds ? _self.timeBankSeconds : timeBankSeconds // ignore: cast_nullable_to_non_nullable
as int,allowStraddle: null == allowStraddle ? _self.allowStraddle : allowStraddle // ignore: cast_nullable_to_non_nullable
as bool,runItTwice: null == runItTwice ? _self.runItTwice : runItTwice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SeatView {

 int get seat; PlayerView? get player;
/// Create a copy of SeatView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatViewCopyWith<SeatView> get copyWith => _$SeatViewCopyWithImpl<SeatView>(this as SeatView, _$identity);

  /// Serializes this SeatView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeatView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeatView&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&(identical(other.player, _this.player) || other.player == _this.player));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeatView;
  return Object.hash(runtimeType,_this.seat,_this.player);
}

@override
String toString() {
  final _this = this as SeatView;
  return 'SeatView(seat: ${_this.seat}, player: ${_this.player})';
}


}

/// @nodoc
abstract mixin class $SeatViewCopyWith<$Res>  {
  factory $SeatViewCopyWith(SeatView value, $Res Function(SeatView) _then) = _$SeatViewCopyWithImpl;
@useResult
$Res call({
 int seat, PlayerView? player
});


$PlayerViewCopyWith<$Res>? get player;

}
/// @nodoc
class _$SeatViewCopyWithImpl<$Res>
    implements $SeatViewCopyWith<$Res> {
  _$SeatViewCopyWithImpl(this._self, this._then);

  final SeatView _self;
  final $Res Function(SeatView) _then;

/// Create a copy of SeatView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seat = null,Object? player = freezed,}) {
  return _then(SeatView(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,player: freezed == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerView?,
  ));
}
/// Create a copy of SeatView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerViewCopyWith<$Res>? get player {
    if (_self.player == null) {
    return null;
  }

  return $PlayerViewCopyWith<$Res>(_self.player!, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [SeatView].
extension SeatViewPatterns on SeatView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeatView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeatView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeatView value)  $default,){
final _that = this;
switch (_that) {
case _SeatView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeatView value)?  $default,){
final _that = this;
switch (_that) {
case _SeatView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seat,  PlayerView? player)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeatView() when $default != null:
return $default(_that.seat,_that.player);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seat,  PlayerView? player)  $default,) {final _that = this;
switch (_that) {
case _SeatView():
return $default(_that.seat,_that.player);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seat,  PlayerView? player)?  $default,) {final _that = this;
switch (_that) {
case _SeatView() when $default != null:
return $default(_that.seat,_that.player);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeatView implements SeatView {
  const _SeatView({required this.seat, required this.player});
  factory _SeatView.fromJson(Map<String, dynamic> json) => _$SeatViewFromJson(json);

@override final  int seat;
@override final  PlayerView? player;

/// Create a copy of SeatView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatViewCopyWith<_SeatView> get copyWith => __$SeatViewCopyWithImpl<_SeatView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeatViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeatView&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.player, player) || other.player == player));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seat,player);
}

@override
String toString() {
    return 'SeatView(seat: $seat, player: $player)';
}


}

/// @nodoc
abstract mixin class _$SeatViewCopyWith<$Res> implements $SeatViewCopyWith<$Res> {
  factory _$SeatViewCopyWith(_SeatView value, $Res Function(_SeatView) _then) = __$SeatViewCopyWithImpl;
@override @useResult
$Res call({
 int seat, PlayerView? player
});


@override $PlayerViewCopyWith<$Res>? get player;

}
/// @nodoc
class __$SeatViewCopyWithImpl<$Res>
    implements _$SeatViewCopyWith<$Res> {
  __$SeatViewCopyWithImpl(this._self, this._then);

  final _SeatView _self;
  final $Res Function(_SeatView) _then;

/// Create a copy of SeatView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seat = null,Object? player = freezed,}) {
  return _then(_SeatView(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,player: freezed == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerView?,
  ));
}

/// Create a copy of SeatView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerViewCopyWith<$Res>? get player {
    if (_self.player == null) {
    return null;
  }

  return $PlayerViewCopyWith<$Res>(_self.player!, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// @nodoc
mixin _$PlayerView {

 String get id; String get name; int get avatar; String get voice;@JsonKey(includeIfNull: false) bool? get muted;@JsonKey(includeIfNull: false) bool? get mucked;@JsonKey(includeIfNull: false) bool? get camera;@JsonKey(includeIfNull: false) double? get equity;@JsonKey(includeIfNull: false) int? get timeBank;@JsonKey(includeIfNull: false) int? get place; int get stack; String get status; bool get connected; bool get inHand; bool get folded; bool get allIn; int get betThisStreet; int get totalBet;@JsonKey(includeIfNull: false) List<String>? get holeCards; LastAction? get lastAction;
/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerViewCopyWith<PlayerView> get copyWith => _$PlayerViewCopyWithImpl<PlayerView>(this as PlayerView, _$identity);

  /// Serializes this PlayerView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayerView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerView&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.avatar, _this.avatar) || other.avatar == _this.avatar)&&(identical(other.voice, _this.voice) || other.voice == _this.voice)&&(identical(other.muted, _this.muted) || other.muted == _this.muted)&&(identical(other.mucked, _this.mucked) || other.mucked == _this.mucked)&&(identical(other.camera, _this.camera) || other.camera == _this.camera)&&(identical(other.equity, _this.equity) || other.equity == _this.equity)&&(identical(other.timeBank, _this.timeBank) || other.timeBank == _this.timeBank)&&(identical(other.place, _this.place) || other.place == _this.place)&&(identical(other.stack, _this.stack) || other.stack == _this.stack)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.connected, _this.connected) || other.connected == _this.connected)&&(identical(other.inHand, _this.inHand) || other.inHand == _this.inHand)&&(identical(other.folded, _this.folded) || other.folded == _this.folded)&&(identical(other.allIn, _this.allIn) || other.allIn == _this.allIn)&&(identical(other.betThisStreet, _this.betThisStreet) || other.betThisStreet == _this.betThisStreet)&&(identical(other.totalBet, _this.totalBet) || other.totalBet == _this.totalBet)&&const DeepCollectionEquality().equals(other.holeCards, _this.holeCards)&&(identical(other.lastAction, _this.lastAction) || other.lastAction == _this.lastAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayerView;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.avatar,_this.voice,_this.muted,_this.mucked,_this.camera,_this.equity,_this.timeBank,_this.place,_this.stack,_this.status,_this.connected,_this.inHand,_this.folded,_this.allIn,_this.betThisStreet,_this.totalBet,const DeepCollectionEquality().hash(_this.holeCards),_this.lastAction]);
}

@override
String toString() {
  final _this = this as PlayerView;
  return 'PlayerView(id: ${_this.id}, name: ${_this.name}, avatar: ${_this.avatar}, voice: ${_this.voice}, muted: ${_this.muted}, mucked: ${_this.mucked}, camera: ${_this.camera}, equity: ${_this.equity}, timeBank: ${_this.timeBank}, place: ${_this.place}, stack: ${_this.stack}, status: ${_this.status}, connected: ${_this.connected}, inHand: ${_this.inHand}, folded: ${_this.folded}, allIn: ${_this.allIn}, betThisStreet: ${_this.betThisStreet}, totalBet: ${_this.totalBet}, holeCards: ${_this.holeCards}, lastAction: ${_this.lastAction})';
}


}

/// @nodoc
abstract mixin class $PlayerViewCopyWith<$Res>  {
  factory $PlayerViewCopyWith(PlayerView value, $Res Function(PlayerView) _then) = _$PlayerViewCopyWithImpl;
@useResult
$Res call({
 String id, String name, int avatar, String voice,@JsonKey(includeIfNull: false) bool? muted,@JsonKey(includeIfNull: false) bool? mucked,@JsonKey(includeIfNull: false) bool? camera,@JsonKey(includeIfNull: false) double? equity,@JsonKey(includeIfNull: false) int? timeBank,@JsonKey(includeIfNull: false) int? place, int stack, String status, bool connected, bool inHand, bool folded, bool allIn, int betThisStreet, int totalBet,@JsonKey(includeIfNull: false) List<String>? holeCards, LastAction? lastAction
});


$LastActionCopyWith<$Res>? get lastAction;

}
/// @nodoc
class _$PlayerViewCopyWithImpl<$Res>
    implements $PlayerViewCopyWith<$Res> {
  _$PlayerViewCopyWithImpl(this._self, this._then);

  final PlayerView _self;
  final $Res Function(PlayerView) _then;

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatar = null,Object? voice = null,Object? muted = freezed,Object? mucked = freezed,Object? camera = freezed,Object? equity = freezed,Object? timeBank = freezed,Object? place = freezed,Object? stack = null,Object? status = null,Object? connected = null,Object? inHand = null,Object? folded = null,Object? allIn = null,Object? betThisStreet = null,Object? totalBet = null,Object? holeCards = freezed,Object? lastAction = freezed,}) {
  return _then(PlayerView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,voice: null == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as String,muted: freezed == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool?,mucked: freezed == mucked ? _self.mucked : mucked // ignore: cast_nullable_to_non_nullable
as bool?,camera: freezed == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as bool?,equity: freezed == equity ? _self.equity : equity // ignore: cast_nullable_to_non_nullable
as double?,timeBank: freezed == timeBank ? _self.timeBank : timeBank // ignore: cast_nullable_to_non_nullable
as int?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as int?,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,inHand: null == inHand ? _self.inHand : inHand // ignore: cast_nullable_to_non_nullable
as bool,folded: null == folded ? _self.folded : folded // ignore: cast_nullable_to_non_nullable
as bool,allIn: null == allIn ? _self.allIn : allIn // ignore: cast_nullable_to_non_nullable
as bool,betThisStreet: null == betThisStreet ? _self.betThisStreet : betThisStreet // ignore: cast_nullable_to_non_nullable
as int,totalBet: null == totalBet ? _self.totalBet : totalBet // ignore: cast_nullable_to_non_nullable
as int,holeCards: freezed == holeCards ? _self.holeCards : holeCards // ignore: cast_nullable_to_non_nullable
as List<String>?,lastAction: freezed == lastAction ? _self.lastAction : lastAction // ignore: cast_nullable_to_non_nullable
as LastAction?,
  ));
}
/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastActionCopyWith<$Res>? get lastAction {
    if (_self.lastAction == null) {
    return null;
  }

  return $LastActionCopyWith<$Res>(_self.lastAction!, (value) {
    return _then(_self.copyWith(lastAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerView].
extension PlayerViewPatterns on PlayerView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerView value)  $default,){
final _that = this;
switch (_that) {
case _PlayerView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerView value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int avatar,  String voice, @JsonKey(includeIfNull: false)  bool? muted, @JsonKey(includeIfNull: false)  bool? mucked, @JsonKey(includeIfNull: false)  bool? camera, @JsonKey(includeIfNull: false)  double? equity, @JsonKey(includeIfNull: false)  int? timeBank, @JsonKey(includeIfNull: false)  int? place,  int stack,  String status,  bool connected,  bool inHand,  bool folded,  bool allIn,  int betThisStreet,  int totalBet, @JsonKey(includeIfNull: false)  List<String>? holeCards,  LastAction? lastAction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.voice,_that.muted,_that.mucked,_that.camera,_that.equity,_that.timeBank,_that.place,_that.stack,_that.status,_that.connected,_that.inHand,_that.folded,_that.allIn,_that.betThisStreet,_that.totalBet,_that.holeCards,_that.lastAction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int avatar,  String voice, @JsonKey(includeIfNull: false)  bool? muted, @JsonKey(includeIfNull: false)  bool? mucked, @JsonKey(includeIfNull: false)  bool? camera, @JsonKey(includeIfNull: false)  double? equity, @JsonKey(includeIfNull: false)  int? timeBank, @JsonKey(includeIfNull: false)  int? place,  int stack,  String status,  bool connected,  bool inHand,  bool folded,  bool allIn,  int betThisStreet,  int totalBet, @JsonKey(includeIfNull: false)  List<String>? holeCards,  LastAction? lastAction)  $default,) {final _that = this;
switch (_that) {
case _PlayerView():
return $default(_that.id,_that.name,_that.avatar,_that.voice,_that.muted,_that.mucked,_that.camera,_that.equity,_that.timeBank,_that.place,_that.stack,_that.status,_that.connected,_that.inHand,_that.folded,_that.allIn,_that.betThisStreet,_that.totalBet,_that.holeCards,_that.lastAction);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int avatar,  String voice, @JsonKey(includeIfNull: false)  bool? muted, @JsonKey(includeIfNull: false)  bool? mucked, @JsonKey(includeIfNull: false)  bool? camera, @JsonKey(includeIfNull: false)  double? equity, @JsonKey(includeIfNull: false)  int? timeBank, @JsonKey(includeIfNull: false)  int? place,  int stack,  String status,  bool connected,  bool inHand,  bool folded,  bool allIn,  int betThisStreet,  int totalBet, @JsonKey(includeIfNull: false)  List<String>? holeCards,  LastAction? lastAction)?  $default,) {final _that = this;
switch (_that) {
case _PlayerView() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.voice,_that.muted,_that.mucked,_that.camera,_that.equity,_that.timeBank,_that.place,_that.stack,_that.status,_that.connected,_that.inHand,_that.folded,_that.allIn,_that.betThisStreet,_that.totalBet,_that.holeCards,_that.lastAction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerView implements PlayerView {
  const _PlayerView({required this.id, required this.name, required this.avatar, this.voice = 'off', @JsonKey(includeIfNull: false) this.muted, @JsonKey(includeIfNull: false) this.mucked, @JsonKey(includeIfNull: false) this.camera, @JsonKey(includeIfNull: false) this.equity, @JsonKey(includeIfNull: false) this.timeBank, @JsonKey(includeIfNull: false) this.place, required this.stack, required this.status, required this.connected, required this.inHand, required this.folded, required this.allIn, required this.betThisStreet, required this.totalBet, @JsonKey(includeIfNull: false)  List<String>? holeCards, required this.lastAction}): _holeCards = holeCards;
  factory _PlayerView.fromJson(Map<String, dynamic> json) => _$PlayerViewFromJson(json);

@override final  String id;
@override final  String name;
@override final  int avatar;
@override@JsonKey() final  String voice;
@override@JsonKey(includeIfNull: false) final  bool? muted;
@override@JsonKey(includeIfNull: false) final  bool? mucked;
@override@JsonKey(includeIfNull: false) final  bool? camera;
@override@JsonKey(includeIfNull: false) final  double? equity;
@override@JsonKey(includeIfNull: false) final  int? timeBank;
@override@JsonKey(includeIfNull: false) final  int? place;
@override final  int stack;
@override final  String status;
@override final  bool connected;
@override final  bool inHand;
@override final  bool folded;
@override final  bool allIn;
@override final  int betThisStreet;
@override final  int totalBet;
 final  List<String>? _holeCards;
@override@JsonKey(includeIfNull: false) List<String>? get holeCards {
  final value = _holeCards;
  if (value == null) return null;
  if (_holeCards is EqualUnmodifiableListView) return _holeCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  LastAction? lastAction;

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerViewCopyWith<_PlayerView> get copyWith => __$PlayerViewCopyWithImpl<_PlayerView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerView&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.voice, voice) || other.voice == voice)&&(identical(other.muted, muted) || other.muted == muted)&&(identical(other.mucked, mucked) || other.mucked == mucked)&&(identical(other.camera, camera) || other.camera == camera)&&(identical(other.equity, equity) || other.equity == equity)&&(identical(other.timeBank, timeBank) || other.timeBank == timeBank)&&(identical(other.place, place) || other.place == place)&&(identical(other.stack, stack) || other.stack == stack)&&(identical(other.status, status) || other.status == status)&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.inHand, inHand) || other.inHand == inHand)&&(identical(other.folded, folded) || other.folded == folded)&&(identical(other.allIn, allIn) || other.allIn == allIn)&&(identical(other.betThisStreet, betThisStreet) || other.betThisStreet == betThisStreet)&&(identical(other.totalBet, totalBet) || other.totalBet == totalBet)&&const DeepCollectionEquality().equals(other.holeCards, _holeCards)&&(identical(other.lastAction, lastAction) || other.lastAction == lastAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,avatar,voice,muted,mucked,camera,equity,timeBank,place,stack,status,connected,inHand,folded,allIn,betThisStreet,totalBet,const DeepCollectionEquality().hash(_holeCards),lastAction]);
}

@override
String toString() {
    return 'PlayerView(id: $id, name: $name, avatar: $avatar, voice: $voice, muted: $muted, mucked: $mucked, camera: $camera, equity: $equity, timeBank: $timeBank, place: $place, stack: $stack, status: $status, connected: $connected, inHand: $inHand, folded: $folded, allIn: $allIn, betThisStreet: $betThisStreet, totalBet: $totalBet, holeCards: $holeCards, lastAction: $lastAction)';
}


}

/// @nodoc
abstract mixin class _$PlayerViewCopyWith<$Res> implements $PlayerViewCopyWith<$Res> {
  factory _$PlayerViewCopyWith(_PlayerView value, $Res Function(_PlayerView) _then) = __$PlayerViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int avatar, String voice,@JsonKey(includeIfNull: false) bool? muted,@JsonKey(includeIfNull: false) bool? mucked,@JsonKey(includeIfNull: false) bool? camera,@JsonKey(includeIfNull: false) double? equity,@JsonKey(includeIfNull: false) int? timeBank,@JsonKey(includeIfNull: false) int? place, int stack, String status, bool connected, bool inHand, bool folded, bool allIn, int betThisStreet, int totalBet,@JsonKey(includeIfNull: false) List<String>? holeCards, LastAction? lastAction
});


@override $LastActionCopyWith<$Res>? get lastAction;

}
/// @nodoc
class __$PlayerViewCopyWithImpl<$Res>
    implements _$PlayerViewCopyWith<$Res> {
  __$PlayerViewCopyWithImpl(this._self, this._then);

  final _PlayerView _self;
  final $Res Function(_PlayerView) _then;

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatar = null,Object? voice = null,Object? muted = freezed,Object? mucked = freezed,Object? camera = freezed,Object? equity = freezed,Object? timeBank = freezed,Object? place = freezed,Object? stack = null,Object? status = null,Object? connected = null,Object? inHand = null,Object? folded = null,Object? allIn = null,Object? betThisStreet = null,Object? totalBet = null,Object? holeCards = freezed,Object? lastAction = freezed,}) {
  return _then(_PlayerView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,voice: null == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as String,muted: freezed == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool?,mucked: freezed == mucked ? _self.mucked : mucked // ignore: cast_nullable_to_non_nullable
as bool?,camera: freezed == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as bool?,equity: freezed == equity ? _self.equity : equity // ignore: cast_nullable_to_non_nullable
as double?,timeBank: freezed == timeBank ? _self.timeBank : timeBank // ignore: cast_nullable_to_non_nullable
as int?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as int?,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,inHand: null == inHand ? _self.inHand : inHand // ignore: cast_nullable_to_non_nullable
as bool,folded: null == folded ? _self.folded : folded // ignore: cast_nullable_to_non_nullable
as bool,allIn: null == allIn ? _self.allIn : allIn // ignore: cast_nullable_to_non_nullable
as bool,betThisStreet: null == betThisStreet ? _self.betThisStreet : betThisStreet // ignore: cast_nullable_to_non_nullable
as int,totalBet: null == totalBet ? _self.totalBet : totalBet // ignore: cast_nullable_to_non_nullable
as int,holeCards: freezed == holeCards ? _self._holeCards : holeCards // ignore: cast_nullable_to_non_nullable
as List<String>?,lastAction: freezed == lastAction ? _self.lastAction : lastAction // ignore: cast_nullable_to_non_nullable
as LastAction?,
  ));
}

/// Create a copy of PlayerView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastActionCopyWith<$Res>? get lastAction {
    if (_self.lastAction == null) {
    return null;
  }

  return $LastActionCopyWith<$Res>(_self.lastAction!, (value) {
    return _then(_self.copyWith(lastAction: value));
  });
}
}


/// @nodoc
mixin _$LastAction {

 String get kind; int get amount;
/// Create a copy of LastAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastActionCopyWith<LastAction> get copyWith => _$LastActionCopyWithImpl<LastAction>(this as LastAction, _$identity);

  /// Serializes this LastAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LastAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastAction&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.amount, _this.amount) || other.amount == _this.amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LastAction;
  return Object.hash(runtimeType,_this.kind,_this.amount);
}

@override
String toString() {
  final _this = this as LastAction;
  return 'LastAction(kind: ${_this.kind}, amount: ${_this.amount})';
}


}

/// @nodoc
abstract mixin class $LastActionCopyWith<$Res>  {
  factory $LastActionCopyWith(LastAction value, $Res Function(LastAction) _then) = _$LastActionCopyWithImpl;
@useResult
$Res call({
 String kind, int amount
});




}
/// @nodoc
class _$LastActionCopyWithImpl<$Res>
    implements $LastActionCopyWith<$Res> {
  _$LastActionCopyWithImpl(this._self, this._then);

  final LastAction _self;
  final $Res Function(LastAction) _then;

/// Create a copy of LastAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? amount = null,}) {
  return _then(LastAction(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LastAction].
extension LastActionPatterns on LastAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastAction() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastAction value)  $default,){
final _that = this;
switch (_that) {
case _LastAction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastAction value)?  $default,){
final _that = this;
switch (_that) {
case _LastAction() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastAction() when $default != null:
return $default(_that.kind,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  int amount)  $default,) {final _that = this;
switch (_that) {
case _LastAction():
return $default(_that.kind,_that.amount);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _LastAction() when $default != null:
return $default(_that.kind,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastAction implements LastAction {
  const _LastAction({required this.kind, required this.amount});
  factory _LastAction.fromJson(Map<String, dynamic> json) => _$LastActionFromJson(json);

@override final  String kind;
@override final  int amount;

/// Create a copy of LastAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastActionCopyWith<_LastAction> get copyWith => __$LastActionCopyWithImpl<_LastAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastAction&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,amount);
}

@override
String toString() {
    return 'LastAction(kind: $kind, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$LastActionCopyWith<$Res> implements $LastActionCopyWith<$Res> {
  factory _$LastActionCopyWith(_LastAction value, $Res Function(_LastAction) _then) = __$LastActionCopyWithImpl;
@override @useResult
$Res call({
 String kind, int amount
});




}
/// @nodoc
class __$LastActionCopyWithImpl<$Res>
    implements _$LastActionCopyWith<$Res> {
  __$LastActionCopyWithImpl(this._self, this._then);

  final _LastAction _self;
  final $Res Function(_LastAction) _then;

/// Create a copy of LastAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? amount = null,}) {
  return _then(_LastAction(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HandView {

 String get street; List<String> get board; int get buttonSeat; int get sbSeat; int get bbSeat; int? get toActSeat; int? get deadlineTs; int get currentBet; int get minRaiseTo; List<PotView> get pots; String get phase;@JsonKey(includeIfNull: false) List<String>? get rabbitCards;@JsonKey(includeIfNull: false) int? get phaseEndsTs;@JsonKey(includeIfNull: false) List<String>? get board2;@JsonKey(includeIfNull: false) int? get straddleSeat;@JsonKey(includeIfNull: false) bool? get timeBankActive;@JsonKey(includeIfNull: false) bool? get runTwice;@JsonKey(includeIfNull: false) int? get runTwiceEndsTs;
/// Create a copy of HandView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandViewCopyWith<HandView> get copyWith => _$HandViewCopyWithImpl<HandView>(this as HandView, _$identity);

  /// Serializes this HandView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HandView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HandView&&(identical(other.street, _this.street) || other.street == _this.street)&&const DeepCollectionEquality().equals(other.board, _this.board)&&(identical(other.buttonSeat, _this.buttonSeat) || other.buttonSeat == _this.buttonSeat)&&(identical(other.sbSeat, _this.sbSeat) || other.sbSeat == _this.sbSeat)&&(identical(other.bbSeat, _this.bbSeat) || other.bbSeat == _this.bbSeat)&&(identical(other.toActSeat, _this.toActSeat) || other.toActSeat == _this.toActSeat)&&(identical(other.deadlineTs, _this.deadlineTs) || other.deadlineTs == _this.deadlineTs)&&(identical(other.currentBet, _this.currentBet) || other.currentBet == _this.currentBet)&&(identical(other.minRaiseTo, _this.minRaiseTo) || other.minRaiseTo == _this.minRaiseTo)&&const DeepCollectionEquality().equals(other.pots, _this.pots)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&const DeepCollectionEquality().equals(other.rabbitCards, _this.rabbitCards)&&(identical(other.phaseEndsTs, _this.phaseEndsTs) || other.phaseEndsTs == _this.phaseEndsTs)&&const DeepCollectionEquality().equals(other.board2, _this.board2)&&(identical(other.straddleSeat, _this.straddleSeat) || other.straddleSeat == _this.straddleSeat)&&(identical(other.timeBankActive, _this.timeBankActive) || other.timeBankActive == _this.timeBankActive)&&(identical(other.runTwice, _this.runTwice) || other.runTwice == _this.runTwice)&&(identical(other.runTwiceEndsTs, _this.runTwiceEndsTs) || other.runTwiceEndsTs == _this.runTwiceEndsTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HandView;
  return Object.hash(runtimeType,_this.street,const DeepCollectionEquality().hash(_this.board),_this.buttonSeat,_this.sbSeat,_this.bbSeat,_this.toActSeat,_this.deadlineTs,_this.currentBet,_this.minRaiseTo,const DeepCollectionEquality().hash(_this.pots),_this.phase,const DeepCollectionEquality().hash(_this.rabbitCards),_this.phaseEndsTs,const DeepCollectionEquality().hash(_this.board2),_this.straddleSeat,_this.timeBankActive,_this.runTwice,_this.runTwiceEndsTs);
}

@override
String toString() {
  final _this = this as HandView;
  return 'HandView(street: ${_this.street}, board: ${_this.board}, buttonSeat: ${_this.buttonSeat}, sbSeat: ${_this.sbSeat}, bbSeat: ${_this.bbSeat}, toActSeat: ${_this.toActSeat}, deadlineTs: ${_this.deadlineTs}, currentBet: ${_this.currentBet}, minRaiseTo: ${_this.minRaiseTo}, pots: ${_this.pots}, phase: ${_this.phase}, rabbitCards: ${_this.rabbitCards}, phaseEndsTs: ${_this.phaseEndsTs}, board2: ${_this.board2}, straddleSeat: ${_this.straddleSeat}, timeBankActive: ${_this.timeBankActive}, runTwice: ${_this.runTwice}, runTwiceEndsTs: ${_this.runTwiceEndsTs})';
}


}

/// @nodoc
abstract mixin class $HandViewCopyWith<$Res>  {
  factory $HandViewCopyWith(HandView value, $Res Function(HandView) _then) = _$HandViewCopyWithImpl;
@useResult
$Res call({
 String street, List<String> board, int buttonSeat, int sbSeat, int bbSeat, int? toActSeat, int? deadlineTs, int currentBet, int minRaiseTo, List<PotView> pots, String phase,@JsonKey(includeIfNull: false) List<String>? rabbitCards,@JsonKey(includeIfNull: false) int? phaseEndsTs,@JsonKey(includeIfNull: false) List<String>? board2,@JsonKey(includeIfNull: false) int? straddleSeat,@JsonKey(includeIfNull: false) bool? timeBankActive,@JsonKey(includeIfNull: false) bool? runTwice,@JsonKey(includeIfNull: false) int? runTwiceEndsTs
});




}
/// @nodoc
class _$HandViewCopyWithImpl<$Res>
    implements $HandViewCopyWith<$Res> {
  _$HandViewCopyWithImpl(this._self, this._then);

  final HandView _self;
  final $Res Function(HandView) _then;

/// Create a copy of HandView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? street = null,Object? board = null,Object? buttonSeat = null,Object? sbSeat = null,Object? bbSeat = null,Object? toActSeat = freezed,Object? deadlineTs = freezed,Object? currentBet = null,Object? minRaiseTo = null,Object? pots = null,Object? phase = null,Object? rabbitCards = freezed,Object? phaseEndsTs = freezed,Object? board2 = freezed,Object? straddleSeat = freezed,Object? timeBankActive = freezed,Object? runTwice = freezed,Object? runTwiceEndsTs = freezed,}) {
  return _then(HandView(
street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as List<String>,buttonSeat: null == buttonSeat ? _self.buttonSeat : buttonSeat // ignore: cast_nullable_to_non_nullable
as int,sbSeat: null == sbSeat ? _self.sbSeat : sbSeat // ignore: cast_nullable_to_non_nullable
as int,bbSeat: null == bbSeat ? _self.bbSeat : bbSeat // ignore: cast_nullable_to_non_nullable
as int,toActSeat: freezed == toActSeat ? _self.toActSeat : toActSeat // ignore: cast_nullable_to_non_nullable
as int?,deadlineTs: freezed == deadlineTs ? _self.deadlineTs : deadlineTs // ignore: cast_nullable_to_non_nullable
as int?,currentBet: null == currentBet ? _self.currentBet : currentBet // ignore: cast_nullable_to_non_nullable
as int,minRaiseTo: null == minRaiseTo ? _self.minRaiseTo : minRaiseTo // ignore: cast_nullable_to_non_nullable
as int,pots: null == pots ? _self.pots : pots // ignore: cast_nullable_to_non_nullable
as List<PotView>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,rabbitCards: freezed == rabbitCards ? _self.rabbitCards : rabbitCards // ignore: cast_nullable_to_non_nullable
as List<String>?,phaseEndsTs: freezed == phaseEndsTs ? _self.phaseEndsTs : phaseEndsTs // ignore: cast_nullable_to_non_nullable
as int?,board2: freezed == board2 ? _self.board2 : board2 // ignore: cast_nullable_to_non_nullable
as List<String>?,straddleSeat: freezed == straddleSeat ? _self.straddleSeat : straddleSeat // ignore: cast_nullable_to_non_nullable
as int?,timeBankActive: freezed == timeBankActive ? _self.timeBankActive : timeBankActive // ignore: cast_nullable_to_non_nullable
as bool?,runTwice: freezed == runTwice ? _self.runTwice : runTwice // ignore: cast_nullable_to_non_nullable
as bool?,runTwiceEndsTs: freezed == runTwiceEndsTs ? _self.runTwiceEndsTs : runTwiceEndsTs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HandView].
extension HandViewPatterns on HandView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HandView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HandView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HandView value)  $default,){
final _that = this;
switch (_that) {
case _HandView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HandView value)?  $default,){
final _that = this;
switch (_that) {
case _HandView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String street,  List<String> board,  int buttonSeat,  int sbSeat,  int bbSeat,  int? toActSeat,  int? deadlineTs,  int currentBet,  int minRaiseTo,  List<PotView> pots,  String phase, @JsonKey(includeIfNull: false)  List<String>? rabbitCards, @JsonKey(includeIfNull: false)  int? phaseEndsTs, @JsonKey(includeIfNull: false)  List<String>? board2, @JsonKey(includeIfNull: false)  int? straddleSeat, @JsonKey(includeIfNull: false)  bool? timeBankActive, @JsonKey(includeIfNull: false)  bool? runTwice, @JsonKey(includeIfNull: false)  int? runTwiceEndsTs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HandView() when $default != null:
return $default(_that.street,_that.board,_that.buttonSeat,_that.sbSeat,_that.bbSeat,_that.toActSeat,_that.deadlineTs,_that.currentBet,_that.minRaiseTo,_that.pots,_that.phase,_that.rabbitCards,_that.phaseEndsTs,_that.board2,_that.straddleSeat,_that.timeBankActive,_that.runTwice,_that.runTwiceEndsTs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String street,  List<String> board,  int buttonSeat,  int sbSeat,  int bbSeat,  int? toActSeat,  int? deadlineTs,  int currentBet,  int minRaiseTo,  List<PotView> pots,  String phase, @JsonKey(includeIfNull: false)  List<String>? rabbitCards, @JsonKey(includeIfNull: false)  int? phaseEndsTs, @JsonKey(includeIfNull: false)  List<String>? board2, @JsonKey(includeIfNull: false)  int? straddleSeat, @JsonKey(includeIfNull: false)  bool? timeBankActive, @JsonKey(includeIfNull: false)  bool? runTwice, @JsonKey(includeIfNull: false)  int? runTwiceEndsTs)  $default,) {final _that = this;
switch (_that) {
case _HandView():
return $default(_that.street,_that.board,_that.buttonSeat,_that.sbSeat,_that.bbSeat,_that.toActSeat,_that.deadlineTs,_that.currentBet,_that.minRaiseTo,_that.pots,_that.phase,_that.rabbitCards,_that.phaseEndsTs,_that.board2,_that.straddleSeat,_that.timeBankActive,_that.runTwice,_that.runTwiceEndsTs);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String street,  List<String> board,  int buttonSeat,  int sbSeat,  int bbSeat,  int? toActSeat,  int? deadlineTs,  int currentBet,  int minRaiseTo,  List<PotView> pots,  String phase, @JsonKey(includeIfNull: false)  List<String>? rabbitCards, @JsonKey(includeIfNull: false)  int? phaseEndsTs, @JsonKey(includeIfNull: false)  List<String>? board2, @JsonKey(includeIfNull: false)  int? straddleSeat, @JsonKey(includeIfNull: false)  bool? timeBankActive, @JsonKey(includeIfNull: false)  bool? runTwice, @JsonKey(includeIfNull: false)  int? runTwiceEndsTs)?  $default,) {final _that = this;
switch (_that) {
case _HandView() when $default != null:
return $default(_that.street,_that.board,_that.buttonSeat,_that.sbSeat,_that.bbSeat,_that.toActSeat,_that.deadlineTs,_that.currentBet,_that.minRaiseTo,_that.pots,_that.phase,_that.rabbitCards,_that.phaseEndsTs,_that.board2,_that.straddleSeat,_that.timeBankActive,_that.runTwice,_that.runTwiceEndsTs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HandView implements HandView {
  const _HandView({required this.street, required  List<String> board, required this.buttonSeat, required this.sbSeat, required this.bbSeat, required this.toActSeat, required this.deadlineTs, required this.currentBet, required this.minRaiseTo, required  List<PotView> pots, required this.phase, @JsonKey(includeIfNull: false)  List<String>? rabbitCards, @JsonKey(includeIfNull: false) this.phaseEndsTs, @JsonKey(includeIfNull: false)  List<String>? board2, @JsonKey(includeIfNull: false) this.straddleSeat, @JsonKey(includeIfNull: false) this.timeBankActive, @JsonKey(includeIfNull: false) this.runTwice, @JsonKey(includeIfNull: false) this.runTwiceEndsTs}): _board = board,_pots = pots,_rabbitCards = rabbitCards,_board2 = board2;
  factory _HandView.fromJson(Map<String, dynamic> json) => _$HandViewFromJson(json);

@override final  String street;
 final  List<String> _board;
@override List<String> get board {
  if (_board is EqualUnmodifiableListView) return _board;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_board);
}

@override final  int buttonSeat;
@override final  int sbSeat;
@override final  int bbSeat;
@override final  int? toActSeat;
@override final  int? deadlineTs;
@override final  int currentBet;
@override final  int minRaiseTo;
 final  List<PotView> _pots;
@override List<PotView> get pots {
  if (_pots is EqualUnmodifiableListView) return _pots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pots);
}

@override final  String phase;
 final  List<String>? _rabbitCards;
@override@JsonKey(includeIfNull: false) List<String>? get rabbitCards {
  final value = _rabbitCards;
  if (value == null) return null;
  if (_rabbitCards is EqualUnmodifiableListView) return _rabbitCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  int? phaseEndsTs;
 final  List<String>? _board2;
@override@JsonKey(includeIfNull: false) List<String>? get board2 {
  final value = _board2;
  if (value == null) return null;
  if (_board2 is EqualUnmodifiableListView) return _board2;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  int? straddleSeat;
@override@JsonKey(includeIfNull: false) final  bool? timeBankActive;
@override@JsonKey(includeIfNull: false) final  bool? runTwice;
@override@JsonKey(includeIfNull: false) final  int? runTwiceEndsTs;

/// Create a copy of HandView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandViewCopyWith<_HandView> get copyWith => __$HandViewCopyWithImpl<_HandView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HandView&&(identical(other.street, street) || other.street == street)&&const DeepCollectionEquality().equals(other.board, _board)&&(identical(other.buttonSeat, buttonSeat) || other.buttonSeat == buttonSeat)&&(identical(other.sbSeat, sbSeat) || other.sbSeat == sbSeat)&&(identical(other.bbSeat, bbSeat) || other.bbSeat == bbSeat)&&(identical(other.toActSeat, toActSeat) || other.toActSeat == toActSeat)&&(identical(other.deadlineTs, deadlineTs) || other.deadlineTs == deadlineTs)&&(identical(other.currentBet, currentBet) || other.currentBet == currentBet)&&(identical(other.minRaiseTo, minRaiseTo) || other.minRaiseTo == minRaiseTo)&&const DeepCollectionEquality().equals(other.pots, _pots)&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.rabbitCards, _rabbitCards)&&(identical(other.phaseEndsTs, phaseEndsTs) || other.phaseEndsTs == phaseEndsTs)&&const DeepCollectionEquality().equals(other.board2, _board2)&&(identical(other.straddleSeat, straddleSeat) || other.straddleSeat == straddleSeat)&&(identical(other.timeBankActive, timeBankActive) || other.timeBankActive == timeBankActive)&&(identical(other.runTwice, runTwice) || other.runTwice == runTwice)&&(identical(other.runTwiceEndsTs, runTwiceEndsTs) || other.runTwiceEndsTs == runTwiceEndsTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,street,const DeepCollectionEquality().hash(_board),buttonSeat,sbSeat,bbSeat,toActSeat,deadlineTs,currentBet,minRaiseTo,const DeepCollectionEquality().hash(_pots),phase,const DeepCollectionEquality().hash(_rabbitCards),phaseEndsTs,const DeepCollectionEquality().hash(_board2),straddleSeat,timeBankActive,runTwice,runTwiceEndsTs);
}

@override
String toString() {
    return 'HandView(street: $street, board: $board, buttonSeat: $buttonSeat, sbSeat: $sbSeat, bbSeat: $bbSeat, toActSeat: $toActSeat, deadlineTs: $deadlineTs, currentBet: $currentBet, minRaiseTo: $minRaiseTo, pots: $pots, phase: $phase, rabbitCards: $rabbitCards, phaseEndsTs: $phaseEndsTs, board2: $board2, straddleSeat: $straddleSeat, timeBankActive: $timeBankActive, runTwice: $runTwice, runTwiceEndsTs: $runTwiceEndsTs)';
}


}

/// @nodoc
abstract mixin class _$HandViewCopyWith<$Res> implements $HandViewCopyWith<$Res> {
  factory _$HandViewCopyWith(_HandView value, $Res Function(_HandView) _then) = __$HandViewCopyWithImpl;
@override @useResult
$Res call({
 String street, List<String> board, int buttonSeat, int sbSeat, int bbSeat, int? toActSeat, int? deadlineTs, int currentBet, int minRaiseTo, List<PotView> pots, String phase,@JsonKey(includeIfNull: false) List<String>? rabbitCards,@JsonKey(includeIfNull: false) int? phaseEndsTs,@JsonKey(includeIfNull: false) List<String>? board2,@JsonKey(includeIfNull: false) int? straddleSeat,@JsonKey(includeIfNull: false) bool? timeBankActive,@JsonKey(includeIfNull: false) bool? runTwice,@JsonKey(includeIfNull: false) int? runTwiceEndsTs
});




}
/// @nodoc
class __$HandViewCopyWithImpl<$Res>
    implements _$HandViewCopyWith<$Res> {
  __$HandViewCopyWithImpl(this._self, this._then);

  final _HandView _self;
  final $Res Function(_HandView) _then;

/// Create a copy of HandView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? street = null,Object? board = null,Object? buttonSeat = null,Object? sbSeat = null,Object? bbSeat = null,Object? toActSeat = freezed,Object? deadlineTs = freezed,Object? currentBet = null,Object? minRaiseTo = null,Object? pots = null,Object? phase = null,Object? rabbitCards = freezed,Object? phaseEndsTs = freezed,Object? board2 = freezed,Object? straddleSeat = freezed,Object? timeBankActive = freezed,Object? runTwice = freezed,Object? runTwiceEndsTs = freezed,}) {
  return _then(_HandView(
street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,board: null == board ? _self._board : board // ignore: cast_nullable_to_non_nullable
as List<String>,buttonSeat: null == buttonSeat ? _self.buttonSeat : buttonSeat // ignore: cast_nullable_to_non_nullable
as int,sbSeat: null == sbSeat ? _self.sbSeat : sbSeat // ignore: cast_nullable_to_non_nullable
as int,bbSeat: null == bbSeat ? _self.bbSeat : bbSeat // ignore: cast_nullable_to_non_nullable
as int,toActSeat: freezed == toActSeat ? _self.toActSeat : toActSeat // ignore: cast_nullable_to_non_nullable
as int?,deadlineTs: freezed == deadlineTs ? _self.deadlineTs : deadlineTs // ignore: cast_nullable_to_non_nullable
as int?,currentBet: null == currentBet ? _self.currentBet : currentBet // ignore: cast_nullable_to_non_nullable
as int,minRaiseTo: null == minRaiseTo ? _self.minRaiseTo : minRaiseTo // ignore: cast_nullable_to_non_nullable
as int,pots: null == pots ? _self._pots : pots // ignore: cast_nullable_to_non_nullable
as List<PotView>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,rabbitCards: freezed == rabbitCards ? _self._rabbitCards : rabbitCards // ignore: cast_nullable_to_non_nullable
as List<String>?,phaseEndsTs: freezed == phaseEndsTs ? _self.phaseEndsTs : phaseEndsTs // ignore: cast_nullable_to_non_nullable
as int?,board2: freezed == board2 ? _self._board2 : board2 // ignore: cast_nullable_to_non_nullable
as List<String>?,straddleSeat: freezed == straddleSeat ? _self.straddleSeat : straddleSeat // ignore: cast_nullable_to_non_nullable
as int?,timeBankActive: freezed == timeBankActive ? _self.timeBankActive : timeBankActive // ignore: cast_nullable_to_non_nullable
as bool?,runTwice: freezed == runTwice ? _self.runTwice : runTwice // ignore: cast_nullable_to_non_nullable
as bool?,runTwiceEndsTs: freezed == runTwiceEndsTs ? _self.runTwiceEndsTs : runTwiceEndsTs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PotView {

 int get amount; List<int> get eligibleSeats;
/// Create a copy of PotView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PotViewCopyWith<PotView> get copyWith => _$PotViewCopyWithImpl<PotView>(this as PotView, _$identity);

  /// Serializes this PotView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PotView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PotView&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&const DeepCollectionEquality().equals(other.eligibleSeats, _this.eligibleSeats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PotView;
  return Object.hash(runtimeType,_this.amount,const DeepCollectionEquality().hash(_this.eligibleSeats));
}

@override
String toString() {
  final _this = this as PotView;
  return 'PotView(amount: ${_this.amount}, eligibleSeats: ${_this.eligibleSeats})';
}


}

/// @nodoc
abstract mixin class $PotViewCopyWith<$Res>  {
  factory $PotViewCopyWith(PotView value, $Res Function(PotView) _then) = _$PotViewCopyWithImpl;
@useResult
$Res call({
 int amount, List<int> eligibleSeats
});




}
/// @nodoc
class _$PotViewCopyWithImpl<$Res>
    implements $PotViewCopyWith<$Res> {
  _$PotViewCopyWithImpl(this._self, this._then);

  final PotView _self;
  final $Res Function(PotView) _then;

/// Create a copy of PotView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? eligibleSeats = null,}) {
  return _then(PotView(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,eligibleSeats: null == eligibleSeats ? _self.eligibleSeats : eligibleSeats // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [PotView].
extension PotViewPatterns on PotView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PotView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PotView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PotView value)  $default,){
final _that = this;
switch (_that) {
case _PotView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PotView value)?  $default,){
final _that = this;
switch (_that) {
case _PotView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amount,  List<int> eligibleSeats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PotView() when $default != null:
return $default(_that.amount,_that.eligibleSeats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amount,  List<int> eligibleSeats)  $default,) {final _that = this;
switch (_that) {
case _PotView():
return $default(_that.amount,_that.eligibleSeats);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amount,  List<int> eligibleSeats)?  $default,) {final _that = this;
switch (_that) {
case _PotView() when $default != null:
return $default(_that.amount,_that.eligibleSeats);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PotView implements PotView {
  const _PotView({required this.amount, required  List<int> eligibleSeats}): _eligibleSeats = eligibleSeats;
  factory _PotView.fromJson(Map<String, dynamic> json) => _$PotViewFromJson(json);

@override final  int amount;
 final  List<int> _eligibleSeats;
@override List<int> get eligibleSeats {
  if (_eligibleSeats is EqualUnmodifiableListView) return _eligibleSeats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eligibleSeats);
}


/// Create a copy of PotView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PotViewCopyWith<_PotView> get copyWith => __$PotViewCopyWithImpl<_PotView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PotViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PotView&&(identical(other.amount, amount) || other.amount == amount)&&const DeepCollectionEquality().equals(other.eligibleSeats, _eligibleSeats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount,const DeepCollectionEquality().hash(_eligibleSeats));
}

@override
String toString() {
    return 'PotView(amount: $amount, eligibleSeats: $eligibleSeats)';
}


}

/// @nodoc
abstract mixin class _$PotViewCopyWith<$Res> implements $PotViewCopyWith<$Res> {
  factory _$PotViewCopyWith(_PotView value, $Res Function(_PotView) _then) = __$PotViewCopyWithImpl;
@override @useResult
$Res call({
 int amount, List<int> eligibleSeats
});




}
/// @nodoc
class __$PotViewCopyWithImpl<$Res>
    implements _$PotViewCopyWith<$Res> {
  __$PotViewCopyWithImpl(this._self, this._then);

  final _PotView _self;
  final $Res Function(_PotView) _then;

/// Create a copy of PotView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? eligibleSeats = null,}) {
  return _then(_PotView(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,eligibleSeats: null == eligibleSeats ? _self._eligibleSeats : eligibleSeats // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}


/// @nodoc
mixin _$You {

 String get role; bool get isAdmin;@JsonKey(includeIfNull: false) String? get playerId;@JsonKey(includeIfNull: false) int? get seat; OptionsView? get options; String get handDescription; bool get canRebuy; bool get canShowCards; String get preAction;@JsonKey(includeIfNull: false) List<String>? get bestCards; bool get canRabbitHunt;@JsonKey(includeIfNull: false) int? get pendingSeat; bool get canChangeSeat;@JsonKey(includeIfNull: false) bool? get straddle;@JsonKey(includeIfNull: false) bool? get canRunTwice;@JsonKey(includeIfNull: false) bool? get runTwiceVote;
/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouCopyWith<You> get copyWith => _$YouCopyWithImpl<You>(this as You, _$identity);

  /// Serializes this You to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as You;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is You&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.isAdmin, _this.isAdmin) || other.isAdmin == _this.isAdmin)&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&(identical(other.options, _this.options) || other.options == _this.options)&&(identical(other.handDescription, _this.handDescription) || other.handDescription == _this.handDescription)&&(identical(other.canRebuy, _this.canRebuy) || other.canRebuy == _this.canRebuy)&&(identical(other.canShowCards, _this.canShowCards) || other.canShowCards == _this.canShowCards)&&(identical(other.preAction, _this.preAction) || other.preAction == _this.preAction)&&const DeepCollectionEquality().equals(other.bestCards, _this.bestCards)&&(identical(other.canRabbitHunt, _this.canRabbitHunt) || other.canRabbitHunt == _this.canRabbitHunt)&&(identical(other.pendingSeat, _this.pendingSeat) || other.pendingSeat == _this.pendingSeat)&&(identical(other.canChangeSeat, _this.canChangeSeat) || other.canChangeSeat == _this.canChangeSeat)&&(identical(other.straddle, _this.straddle) || other.straddle == _this.straddle)&&(identical(other.canRunTwice, _this.canRunTwice) || other.canRunTwice == _this.canRunTwice)&&(identical(other.runTwiceVote, _this.runTwiceVote) || other.runTwiceVote == _this.runTwiceVote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as You;
  return Object.hash(runtimeType,_this.role,_this.isAdmin,_this.playerId,_this.seat,_this.options,_this.handDescription,_this.canRebuy,_this.canShowCards,_this.preAction,const DeepCollectionEquality().hash(_this.bestCards),_this.canRabbitHunt,_this.pendingSeat,_this.canChangeSeat,_this.straddle,_this.canRunTwice,_this.runTwiceVote);
}

@override
String toString() {
  final _this = this as You;
  return 'You(role: ${_this.role}, isAdmin: ${_this.isAdmin}, playerId: ${_this.playerId}, seat: ${_this.seat}, options: ${_this.options}, handDescription: ${_this.handDescription}, canRebuy: ${_this.canRebuy}, canShowCards: ${_this.canShowCards}, preAction: ${_this.preAction}, bestCards: ${_this.bestCards}, canRabbitHunt: ${_this.canRabbitHunt}, pendingSeat: ${_this.pendingSeat}, canChangeSeat: ${_this.canChangeSeat}, straddle: ${_this.straddle}, canRunTwice: ${_this.canRunTwice}, runTwiceVote: ${_this.runTwiceVote})';
}


}

/// @nodoc
abstract mixin class $YouCopyWith<$Res>  {
  factory $YouCopyWith(You value, $Res Function(You) _then) = _$YouCopyWithImpl;
@useResult
$Res call({
 String role, bool isAdmin,@JsonKey(includeIfNull: false) String? playerId,@JsonKey(includeIfNull: false) int? seat, OptionsView? options, String handDescription, bool canRebuy, bool canShowCards, String preAction,@JsonKey(includeIfNull: false) List<String>? bestCards, bool canRabbitHunt,@JsonKey(includeIfNull: false) int? pendingSeat, bool canChangeSeat,@JsonKey(includeIfNull: false) bool? straddle,@JsonKey(includeIfNull: false) bool? canRunTwice,@JsonKey(includeIfNull: false) bool? runTwiceVote
});


$OptionsViewCopyWith<$Res>? get options;

}
/// @nodoc
class _$YouCopyWithImpl<$Res>
    implements $YouCopyWith<$Res> {
  _$YouCopyWithImpl(this._self, this._then);

  final You _self;
  final $Res Function(You) _then;

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? isAdmin = null,Object? playerId = freezed,Object? seat = freezed,Object? options = freezed,Object? handDescription = null,Object? canRebuy = null,Object? canShowCards = null,Object? preAction = null,Object? bestCards = freezed,Object? canRabbitHunt = null,Object? pendingSeat = freezed,Object? canChangeSeat = null,Object? straddle = freezed,Object? canRunTwice = freezed,Object? runTwiceVote = freezed,}) {
  return _then(You(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String?,seat: freezed == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as OptionsView?,handDescription: null == handDescription ? _self.handDescription : handDescription // ignore: cast_nullable_to_non_nullable
as String,canRebuy: null == canRebuy ? _self.canRebuy : canRebuy // ignore: cast_nullable_to_non_nullable
as bool,canShowCards: null == canShowCards ? _self.canShowCards : canShowCards // ignore: cast_nullable_to_non_nullable
as bool,preAction: null == preAction ? _self.preAction : preAction // ignore: cast_nullable_to_non_nullable
as String,bestCards: freezed == bestCards ? _self.bestCards : bestCards // ignore: cast_nullable_to_non_nullable
as List<String>?,canRabbitHunt: null == canRabbitHunt ? _self.canRabbitHunt : canRabbitHunt // ignore: cast_nullable_to_non_nullable
as bool,pendingSeat: freezed == pendingSeat ? _self.pendingSeat : pendingSeat // ignore: cast_nullable_to_non_nullable
as int?,canChangeSeat: null == canChangeSeat ? _self.canChangeSeat : canChangeSeat // ignore: cast_nullable_to_non_nullable
as bool,straddle: freezed == straddle ? _self.straddle : straddle // ignore: cast_nullable_to_non_nullable
as bool?,canRunTwice: freezed == canRunTwice ? _self.canRunTwice : canRunTwice // ignore: cast_nullable_to_non_nullable
as bool?,runTwiceVote: freezed == runTwiceVote ? _self.runTwiceVote : runTwiceVote // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OptionsViewCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $OptionsViewCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}


/// Adds pattern-matching-related methods to [You].
extension YouPatterns on You {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _You value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _You() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _You value)  $default,){
final _that = this;
switch (_that) {
case _You():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _You value)?  $default,){
final _that = this;
switch (_that) {
case _You() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role,  bool isAdmin, @JsonKey(includeIfNull: false)  String? playerId, @JsonKey(includeIfNull: false)  int? seat,  OptionsView? options,  String handDescription,  bool canRebuy,  bool canShowCards,  String preAction, @JsonKey(includeIfNull: false)  List<String>? bestCards,  bool canRabbitHunt, @JsonKey(includeIfNull: false)  int? pendingSeat,  bool canChangeSeat, @JsonKey(includeIfNull: false)  bool? straddle, @JsonKey(includeIfNull: false)  bool? canRunTwice, @JsonKey(includeIfNull: false)  bool? runTwiceVote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _You() when $default != null:
return $default(_that.role,_that.isAdmin,_that.playerId,_that.seat,_that.options,_that.handDescription,_that.canRebuy,_that.canShowCards,_that.preAction,_that.bestCards,_that.canRabbitHunt,_that.pendingSeat,_that.canChangeSeat,_that.straddle,_that.canRunTwice,_that.runTwiceVote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role,  bool isAdmin, @JsonKey(includeIfNull: false)  String? playerId, @JsonKey(includeIfNull: false)  int? seat,  OptionsView? options,  String handDescription,  bool canRebuy,  bool canShowCards,  String preAction, @JsonKey(includeIfNull: false)  List<String>? bestCards,  bool canRabbitHunt, @JsonKey(includeIfNull: false)  int? pendingSeat,  bool canChangeSeat, @JsonKey(includeIfNull: false)  bool? straddle, @JsonKey(includeIfNull: false)  bool? canRunTwice, @JsonKey(includeIfNull: false)  bool? runTwiceVote)  $default,) {final _that = this;
switch (_that) {
case _You():
return $default(_that.role,_that.isAdmin,_that.playerId,_that.seat,_that.options,_that.handDescription,_that.canRebuy,_that.canShowCards,_that.preAction,_that.bestCards,_that.canRabbitHunt,_that.pendingSeat,_that.canChangeSeat,_that.straddle,_that.canRunTwice,_that.runTwiceVote);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role,  bool isAdmin, @JsonKey(includeIfNull: false)  String? playerId, @JsonKey(includeIfNull: false)  int? seat,  OptionsView? options,  String handDescription,  bool canRebuy,  bool canShowCards,  String preAction, @JsonKey(includeIfNull: false)  List<String>? bestCards,  bool canRabbitHunt, @JsonKey(includeIfNull: false)  int? pendingSeat,  bool canChangeSeat, @JsonKey(includeIfNull: false)  bool? straddle, @JsonKey(includeIfNull: false)  bool? canRunTwice, @JsonKey(includeIfNull: false)  bool? runTwiceVote)?  $default,) {final _that = this;
switch (_that) {
case _You() when $default != null:
return $default(_that.role,_that.isAdmin,_that.playerId,_that.seat,_that.options,_that.handDescription,_that.canRebuy,_that.canShowCards,_that.preAction,_that.bestCards,_that.canRabbitHunt,_that.pendingSeat,_that.canChangeSeat,_that.straddle,_that.canRunTwice,_that.runTwiceVote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _You implements You {
  const _You({required this.role, required this.isAdmin, @JsonKey(includeIfNull: false) this.playerId, @JsonKey(includeIfNull: false) this.seat, required this.options, required this.handDescription, required this.canRebuy, required this.canShowCards, required this.preAction, @JsonKey(includeIfNull: false)  List<String>? bestCards, required this.canRabbitHunt, @JsonKey(includeIfNull: false) this.pendingSeat, this.canChangeSeat = false, @JsonKey(includeIfNull: false) this.straddle, @JsonKey(includeIfNull: false) this.canRunTwice, @JsonKey(includeIfNull: false) this.runTwiceVote}): _bestCards = bestCards;
  factory _You.fromJson(Map<String, dynamic> json) => _$YouFromJson(json);

@override final  String role;
@override final  bool isAdmin;
@override@JsonKey(includeIfNull: false) final  String? playerId;
@override@JsonKey(includeIfNull: false) final  int? seat;
@override final  OptionsView? options;
@override final  String handDescription;
@override final  bool canRebuy;
@override final  bool canShowCards;
@override final  String preAction;
 final  List<String>? _bestCards;
@override@JsonKey(includeIfNull: false) List<String>? get bestCards {
  final value = _bestCards;
  if (value == null) return null;
  if (_bestCards is EqualUnmodifiableListView) return _bestCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  bool canRabbitHunt;
@override@JsonKey(includeIfNull: false) final  int? pendingSeat;
@override@JsonKey() final  bool canChangeSeat;
@override@JsonKey(includeIfNull: false) final  bool? straddle;
@override@JsonKey(includeIfNull: false) final  bool? canRunTwice;
@override@JsonKey(includeIfNull: false) final  bool? runTwiceVote;

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouCopyWith<_You> get copyWith => __$YouCopyWithImpl<_You>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YouToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _You&&(identical(other.role, role) || other.role == role)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.options, options) || other.options == options)&&(identical(other.handDescription, handDescription) || other.handDescription == handDescription)&&(identical(other.canRebuy, canRebuy) || other.canRebuy == canRebuy)&&(identical(other.canShowCards, canShowCards) || other.canShowCards == canShowCards)&&(identical(other.preAction, preAction) || other.preAction == preAction)&&const DeepCollectionEquality().equals(other.bestCards, _bestCards)&&(identical(other.canRabbitHunt, canRabbitHunt) || other.canRabbitHunt == canRabbitHunt)&&(identical(other.pendingSeat, pendingSeat) || other.pendingSeat == pendingSeat)&&(identical(other.canChangeSeat, canChangeSeat) || other.canChangeSeat == canChangeSeat)&&(identical(other.straddle, straddle) || other.straddle == straddle)&&(identical(other.canRunTwice, canRunTwice) || other.canRunTwice == canRunTwice)&&(identical(other.runTwiceVote, runTwiceVote) || other.runTwiceVote == runTwiceVote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,role,isAdmin,playerId,seat,options,handDescription,canRebuy,canShowCards,preAction,const DeepCollectionEquality().hash(_bestCards),canRabbitHunt,pendingSeat,canChangeSeat,straddle,canRunTwice,runTwiceVote);
}

@override
String toString() {
    return 'You(role: $role, isAdmin: $isAdmin, playerId: $playerId, seat: $seat, options: $options, handDescription: $handDescription, canRebuy: $canRebuy, canShowCards: $canShowCards, preAction: $preAction, bestCards: $bestCards, canRabbitHunt: $canRabbitHunt, pendingSeat: $pendingSeat, canChangeSeat: $canChangeSeat, straddle: $straddle, canRunTwice: $canRunTwice, runTwiceVote: $runTwiceVote)';
}


}

/// @nodoc
abstract mixin class _$YouCopyWith<$Res> implements $YouCopyWith<$Res> {
  factory _$YouCopyWith(_You value, $Res Function(_You) _then) = __$YouCopyWithImpl;
@override @useResult
$Res call({
 String role, bool isAdmin,@JsonKey(includeIfNull: false) String? playerId,@JsonKey(includeIfNull: false) int? seat, OptionsView? options, String handDescription, bool canRebuy, bool canShowCards, String preAction,@JsonKey(includeIfNull: false) List<String>? bestCards, bool canRabbitHunt,@JsonKey(includeIfNull: false) int? pendingSeat, bool canChangeSeat,@JsonKey(includeIfNull: false) bool? straddle,@JsonKey(includeIfNull: false) bool? canRunTwice,@JsonKey(includeIfNull: false) bool? runTwiceVote
});


@override $OptionsViewCopyWith<$Res>? get options;

}
/// @nodoc
class __$YouCopyWithImpl<$Res>
    implements _$YouCopyWith<$Res> {
  __$YouCopyWithImpl(this._self, this._then);

  final _You _self;
  final $Res Function(_You) _then;

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? isAdmin = null,Object? playerId = freezed,Object? seat = freezed,Object? options = freezed,Object? handDescription = null,Object? canRebuy = null,Object? canShowCards = null,Object? preAction = null,Object? bestCards = freezed,Object? canRabbitHunt = null,Object? pendingSeat = freezed,Object? canChangeSeat = null,Object? straddle = freezed,Object? canRunTwice = freezed,Object? runTwiceVote = freezed,}) {
  return _then(_You(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String?,seat: freezed == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as OptionsView?,handDescription: null == handDescription ? _self.handDescription : handDescription // ignore: cast_nullable_to_non_nullable
as String,canRebuy: null == canRebuy ? _self.canRebuy : canRebuy // ignore: cast_nullable_to_non_nullable
as bool,canShowCards: null == canShowCards ? _self.canShowCards : canShowCards // ignore: cast_nullable_to_non_nullable
as bool,preAction: null == preAction ? _self.preAction : preAction // ignore: cast_nullable_to_non_nullable
as String,bestCards: freezed == bestCards ? _self._bestCards : bestCards // ignore: cast_nullable_to_non_nullable
as List<String>?,canRabbitHunt: null == canRabbitHunt ? _self.canRabbitHunt : canRabbitHunt // ignore: cast_nullable_to_non_nullable
as bool,pendingSeat: freezed == pendingSeat ? _self.pendingSeat : pendingSeat // ignore: cast_nullable_to_non_nullable
as int?,canChangeSeat: null == canChangeSeat ? _self.canChangeSeat : canChangeSeat // ignore: cast_nullable_to_non_nullable
as bool,straddle: freezed == straddle ? _self.straddle : straddle // ignore: cast_nullable_to_non_nullable
as bool?,canRunTwice: freezed == canRunTwice ? _self.canRunTwice : canRunTwice // ignore: cast_nullable_to_non_nullable
as bool?,runTwiceVote: freezed == runTwiceVote ? _self.runTwiceVote : runTwiceVote // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of You
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OptionsViewCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $OptionsViewCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}


/// @nodoc
mixin _$OptionsView {

 bool get fold; bool get check; int get call; RaiseView? get raise; int get allIn;
/// Create a copy of OptionsView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionsViewCopyWith<OptionsView> get copyWith => _$OptionsViewCopyWithImpl<OptionsView>(this as OptionsView, _$identity);

  /// Serializes this OptionsView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionsView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionsView&&(identical(other.fold, _this.fold) || other.fold == _this.fold)&&(identical(other.check, _this.check) || other.check == _this.check)&&(identical(other.call, _this.call) || other.call == _this.call)&&(identical(other.raise, _this.raise) || other.raise == _this.raise)&&(identical(other.allIn, _this.allIn) || other.allIn == _this.allIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionsView;
  return Object.hash(runtimeType,_this.fold,_this.check,_this.call,_this.raise,_this.allIn);
}

@override
String toString() {
  final _this = this as OptionsView;
  return 'OptionsView(fold: ${_this.fold}, check: ${_this.check}, call: ${_this.call}, raise: ${_this.raise}, allIn: ${_this.allIn})';
}


}

/// @nodoc
abstract mixin class $OptionsViewCopyWith<$Res>  {
  factory $OptionsViewCopyWith(OptionsView value, $Res Function(OptionsView) _then) = _$OptionsViewCopyWithImpl;
@useResult
$Res call({
 bool fold, bool check, int call, RaiseView? raise, int allIn
});


$RaiseViewCopyWith<$Res>? get raise;

}
/// @nodoc
class _$OptionsViewCopyWithImpl<$Res>
    implements $OptionsViewCopyWith<$Res> {
  _$OptionsViewCopyWithImpl(this._self, this._then);

  final OptionsView _self;
  final $Res Function(OptionsView) _then;

/// Create a copy of OptionsView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fold = null,Object? check = null,Object? call = null,Object? raise = freezed,Object? allIn = null,}) {
  return _then(OptionsView(
fold: null == fold ? _self.fold : fold // ignore: cast_nullable_to_non_nullable
as bool,check: null == check ? _self.check : check // ignore: cast_nullable_to_non_nullable
as bool,call: null == call ? _self.call : call // ignore: cast_nullable_to_non_nullable
as int,raise: freezed == raise ? _self.raise : raise // ignore: cast_nullable_to_non_nullable
as RaiseView?,allIn: null == allIn ? _self.allIn : allIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of OptionsView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaiseViewCopyWith<$Res>? get raise {
    if (_self.raise == null) {
    return null;
  }

  return $RaiseViewCopyWith<$Res>(_self.raise!, (value) {
    return _then(_self.copyWith(raise: value));
  });
}
}


/// Adds pattern-matching-related methods to [OptionsView].
extension OptionsViewPatterns on OptionsView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionsView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionsView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionsView value)  $default,){
final _that = this;
switch (_that) {
case _OptionsView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionsView value)?  $default,){
final _that = this;
switch (_that) {
case _OptionsView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool fold,  bool check,  int call,  RaiseView? raise,  int allIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionsView() when $default != null:
return $default(_that.fold,_that.check,_that.call,_that.raise,_that.allIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool fold,  bool check,  int call,  RaiseView? raise,  int allIn)  $default,) {final _that = this;
switch (_that) {
case _OptionsView():
return $default(_that.fold,_that.check,_that.call,_that.raise,_that.allIn);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool fold,  bool check,  int call,  RaiseView? raise,  int allIn)?  $default,) {final _that = this;
switch (_that) {
case _OptionsView() when $default != null:
return $default(_that.fold,_that.check,_that.call,_that.raise,_that.allIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionsView implements OptionsView {
  const _OptionsView({required this.fold, required this.check, required this.call, required this.raise, required this.allIn});
  factory _OptionsView.fromJson(Map<String, dynamic> json) => _$OptionsViewFromJson(json);

@override final  bool fold;
@override final  bool check;
@override final  int call;
@override final  RaiseView? raise;
@override final  int allIn;

/// Create a copy of OptionsView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionsViewCopyWith<_OptionsView> get copyWith => __$OptionsViewCopyWithImpl<_OptionsView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionsViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionsView&&(identical(other.fold, fold) || other.fold == fold)&&(identical(other.check, check) || other.check == check)&&(identical(other.call, call) || other.call == call)&&(identical(other.raise, raise) || other.raise == raise)&&(identical(other.allIn, allIn) || other.allIn == allIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fold,check,call,raise,allIn);
}

@override
String toString() {
    return 'OptionsView(fold: $fold, check: $check, call: $call, raise: $raise, allIn: $allIn)';
}


}

/// @nodoc
abstract mixin class _$OptionsViewCopyWith<$Res> implements $OptionsViewCopyWith<$Res> {
  factory _$OptionsViewCopyWith(_OptionsView value, $Res Function(_OptionsView) _then) = __$OptionsViewCopyWithImpl;
@override @useResult
$Res call({
 bool fold, bool check, int call, RaiseView? raise, int allIn
});


@override $RaiseViewCopyWith<$Res>? get raise;

}
/// @nodoc
class __$OptionsViewCopyWithImpl<$Res>
    implements _$OptionsViewCopyWith<$Res> {
  __$OptionsViewCopyWithImpl(this._self, this._then);

  final _OptionsView _self;
  final $Res Function(_OptionsView) _then;

/// Create a copy of OptionsView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fold = null,Object? check = null,Object? call = null,Object? raise = freezed,Object? allIn = null,}) {
  return _then(_OptionsView(
fold: null == fold ? _self.fold : fold // ignore: cast_nullable_to_non_nullable
as bool,check: null == check ? _self.check : check // ignore: cast_nullable_to_non_nullable
as bool,call: null == call ? _self.call : call // ignore: cast_nullable_to_non_nullable
as int,raise: freezed == raise ? _self.raise : raise // ignore: cast_nullable_to_non_nullable
as RaiseView?,allIn: null == allIn ? _self.allIn : allIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of OptionsView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaiseViewCopyWith<$Res>? get raise {
    if (_self.raise == null) {
    return null;
  }

  return $RaiseViewCopyWith<$Res>(_self.raise!, (value) {
    return _then(_self.copyWith(raise: value));
  });
}
}


/// @nodoc
mixin _$RaiseView {

 int get min; int get max;
/// Create a copy of RaiseView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaiseViewCopyWith<RaiseView> get copyWith => _$RaiseViewCopyWithImpl<RaiseView>(this as RaiseView, _$identity);

  /// Serializes this RaiseView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RaiseView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaiseView&&(identical(other.min, _this.min) || other.min == _this.min)&&(identical(other.max, _this.max) || other.max == _this.max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RaiseView;
  return Object.hash(runtimeType,_this.min,_this.max);
}

@override
String toString() {
  final _this = this as RaiseView;
  return 'RaiseView(min: ${_this.min}, max: ${_this.max})';
}


}

/// @nodoc
abstract mixin class $RaiseViewCopyWith<$Res>  {
  factory $RaiseViewCopyWith(RaiseView value, $Res Function(RaiseView) _then) = _$RaiseViewCopyWithImpl;
@useResult
$Res call({
 int min, int max
});




}
/// @nodoc
class _$RaiseViewCopyWithImpl<$Res>
    implements $RaiseViewCopyWith<$Res> {
  _$RaiseViewCopyWithImpl(this._self, this._then);

  final RaiseView _self;
  final $Res Function(RaiseView) _then;

/// Create a copy of RaiseView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? min = null,Object? max = null,}) {
  return _then(RaiseView(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RaiseView].
extension RaiseViewPatterns on RaiseView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaiseView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaiseView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaiseView value)  $default,){
final _that = this;
switch (_that) {
case _RaiseView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaiseView value)?  $default,){
final _that = this;
switch (_that) {
case _RaiseView() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int min,  int max)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaiseView() when $default != null:
return $default(_that.min,_that.max);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int min,  int max)  $default,) {final _that = this;
switch (_that) {
case _RaiseView():
return $default(_that.min,_that.max);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int min,  int max)?  $default,) {final _that = this;
switch (_that) {
case _RaiseView() when $default != null:
return $default(_that.min,_that.max);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RaiseView implements RaiseView {
  const _RaiseView({required this.min, required this.max});
  factory _RaiseView.fromJson(Map<String, dynamic> json) => _$RaiseViewFromJson(json);

@override final  int min;
@override final  int max;

/// Create a copy of RaiseView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaiseViewCopyWith<_RaiseView> get copyWith => __$RaiseViewCopyWithImpl<_RaiseView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaiseViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaiseView&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,min,max);
}

@override
String toString() {
    return 'RaiseView(min: $min, max: $max)';
}


}

/// @nodoc
abstract mixin class _$RaiseViewCopyWith<$Res> implements $RaiseViewCopyWith<$Res> {
  factory _$RaiseViewCopyWith(_RaiseView value, $Res Function(_RaiseView) _then) = __$RaiseViewCopyWithImpl;
@override @useResult
$Res call({
 int min, int max
});




}
/// @nodoc
class __$RaiseViewCopyWithImpl<$Res>
    implements _$RaiseViewCopyWith<$Res> {
  __$RaiseViewCopyWithImpl(this._self, this._then);

  final _RaiseView _self;
  final $Res Function(_RaiseView) _then;

/// Create a copy of RaiseView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? min = null,Object? max = null,}) {
  return _then(_RaiseView(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LeaderboardEntry {

 String get name; int get stack; int get net; int get handsWon; int get biggestPot;@JsonKey(includeIfNull: false) int? get handsPlayed;@JsonKey(includeIfNull: false) int? get vpipHands;@JsonKey(includeIfNull: false) int? get showdowns;@JsonKey(includeIfNull: false) int? get showdownsWon;@JsonKey(includeIfNull: false) int? get place;
/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaderboardEntryCopyWith<LeaderboardEntry> get copyWith => _$LeaderboardEntryCopyWithImpl<LeaderboardEntry>(this as LeaderboardEntry, _$identity);

  /// Serializes this LeaderboardEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LeaderboardEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaderboardEntry&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.stack, _this.stack) || other.stack == _this.stack)&&(identical(other.net, _this.net) || other.net == _this.net)&&(identical(other.handsWon, _this.handsWon) || other.handsWon == _this.handsWon)&&(identical(other.biggestPot, _this.biggestPot) || other.biggestPot == _this.biggestPot)&&(identical(other.handsPlayed, _this.handsPlayed) || other.handsPlayed == _this.handsPlayed)&&(identical(other.vpipHands, _this.vpipHands) || other.vpipHands == _this.vpipHands)&&(identical(other.showdowns, _this.showdowns) || other.showdowns == _this.showdowns)&&(identical(other.showdownsWon, _this.showdownsWon) || other.showdownsWon == _this.showdownsWon)&&(identical(other.place, _this.place) || other.place == _this.place));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LeaderboardEntry;
  return Object.hash(runtimeType,_this.name,_this.stack,_this.net,_this.handsWon,_this.biggestPot,_this.handsPlayed,_this.vpipHands,_this.showdowns,_this.showdownsWon,_this.place);
}

@override
String toString() {
  final _this = this as LeaderboardEntry;
  return 'LeaderboardEntry(name: ${_this.name}, stack: ${_this.stack}, net: ${_this.net}, handsWon: ${_this.handsWon}, biggestPot: ${_this.biggestPot}, handsPlayed: ${_this.handsPlayed}, vpipHands: ${_this.vpipHands}, showdowns: ${_this.showdowns}, showdownsWon: ${_this.showdownsWon}, place: ${_this.place})';
}


}

/// @nodoc
abstract mixin class $LeaderboardEntryCopyWith<$Res>  {
  factory $LeaderboardEntryCopyWith(LeaderboardEntry value, $Res Function(LeaderboardEntry) _then) = _$LeaderboardEntryCopyWithImpl;
@useResult
$Res call({
 String name, int stack, int net, int handsWon, int biggestPot,@JsonKey(includeIfNull: false) int? handsPlayed,@JsonKey(includeIfNull: false) int? vpipHands,@JsonKey(includeIfNull: false) int? showdowns,@JsonKey(includeIfNull: false) int? showdownsWon,@JsonKey(includeIfNull: false) int? place
});




}
/// @nodoc
class _$LeaderboardEntryCopyWithImpl<$Res>
    implements $LeaderboardEntryCopyWith<$Res> {
  _$LeaderboardEntryCopyWithImpl(this._self, this._then);

  final LeaderboardEntry _self;
  final $Res Function(LeaderboardEntry) _then;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? stack = null,Object? net = null,Object? handsWon = null,Object? biggestPot = null,Object? handsPlayed = freezed,Object? vpipHands = freezed,Object? showdowns = freezed,Object? showdownsWon = freezed,Object? place = freezed,}) {
  return _then(LeaderboardEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,handsWon: null == handsWon ? _self.handsWon : handsWon // ignore: cast_nullable_to_non_nullable
as int,biggestPot: null == biggestPot ? _self.biggestPot : biggestPot // ignore: cast_nullable_to_non_nullable
as int,handsPlayed: freezed == handsPlayed ? _self.handsPlayed : handsPlayed // ignore: cast_nullable_to_non_nullable
as int?,vpipHands: freezed == vpipHands ? _self.vpipHands : vpipHands // ignore: cast_nullable_to_non_nullable
as int?,showdowns: freezed == showdowns ? _self.showdowns : showdowns // ignore: cast_nullable_to_non_nullable
as int?,showdownsWon: freezed == showdownsWon ? _self.showdownsWon : showdownsWon // ignore: cast_nullable_to_non_nullable
as int?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaderboardEntry].
extension LeaderboardEntryPatterns on LeaderboardEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaderboardEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaderboardEntry value)  $default,){
final _that = this;
switch (_that) {
case _LeaderboardEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaderboardEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int stack,  int net,  int handsWon,  int biggestPot, @JsonKey(includeIfNull: false)  int? handsPlayed, @JsonKey(includeIfNull: false)  int? vpipHands, @JsonKey(includeIfNull: false)  int? showdowns, @JsonKey(includeIfNull: false)  int? showdownsWon, @JsonKey(includeIfNull: false)  int? place)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that.name,_that.stack,_that.net,_that.handsWon,_that.biggestPot,_that.handsPlayed,_that.vpipHands,_that.showdowns,_that.showdownsWon,_that.place);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int stack,  int net,  int handsWon,  int biggestPot, @JsonKey(includeIfNull: false)  int? handsPlayed, @JsonKey(includeIfNull: false)  int? vpipHands, @JsonKey(includeIfNull: false)  int? showdowns, @JsonKey(includeIfNull: false)  int? showdownsWon, @JsonKey(includeIfNull: false)  int? place)  $default,) {final _that = this;
switch (_that) {
case _LeaderboardEntry():
return $default(_that.name,_that.stack,_that.net,_that.handsWon,_that.biggestPot,_that.handsPlayed,_that.vpipHands,_that.showdowns,_that.showdownsWon,_that.place);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int stack,  int net,  int handsWon,  int biggestPot, @JsonKey(includeIfNull: false)  int? handsPlayed, @JsonKey(includeIfNull: false)  int? vpipHands, @JsonKey(includeIfNull: false)  int? showdowns, @JsonKey(includeIfNull: false)  int? showdownsWon, @JsonKey(includeIfNull: false)  int? place)?  $default,) {final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that.name,_that.stack,_that.net,_that.handsWon,_that.biggestPot,_that.handsPlayed,_that.vpipHands,_that.showdowns,_that.showdownsWon,_that.place);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeaderboardEntry implements LeaderboardEntry {
  const _LeaderboardEntry({required this.name, required this.stack, required this.net, required this.handsWon, required this.biggestPot, @JsonKey(includeIfNull: false) this.handsPlayed, @JsonKey(includeIfNull: false) this.vpipHands, @JsonKey(includeIfNull: false) this.showdowns, @JsonKey(includeIfNull: false) this.showdownsWon, @JsonKey(includeIfNull: false) this.place});
  factory _LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);

@override final  String name;
@override final  int stack;
@override final  int net;
@override final  int handsWon;
@override final  int biggestPot;
@override@JsonKey(includeIfNull: false) final  int? handsPlayed;
@override@JsonKey(includeIfNull: false) final  int? vpipHands;
@override@JsonKey(includeIfNull: false) final  int? showdowns;
@override@JsonKey(includeIfNull: false) final  int? showdownsWon;
@override@JsonKey(includeIfNull: false) final  int? place;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaderboardEntryCopyWith<_LeaderboardEntry> get copyWith => __$LeaderboardEntryCopyWithImpl<_LeaderboardEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeaderboardEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaderboardEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.stack, stack) || other.stack == stack)&&(identical(other.net, net) || other.net == net)&&(identical(other.handsWon, handsWon) || other.handsWon == handsWon)&&(identical(other.biggestPot, biggestPot) || other.biggestPot == biggestPot)&&(identical(other.handsPlayed, handsPlayed) || other.handsPlayed == handsPlayed)&&(identical(other.vpipHands, vpipHands) || other.vpipHands == vpipHands)&&(identical(other.showdowns, showdowns) || other.showdowns == showdowns)&&(identical(other.showdownsWon, showdownsWon) || other.showdownsWon == showdownsWon)&&(identical(other.place, place) || other.place == place));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,stack,net,handsWon,biggestPot,handsPlayed,vpipHands,showdowns,showdownsWon,place);
}

@override
String toString() {
    return 'LeaderboardEntry(name: $name, stack: $stack, net: $net, handsWon: $handsWon, biggestPot: $biggestPot, handsPlayed: $handsPlayed, vpipHands: $vpipHands, showdowns: $showdowns, showdownsWon: $showdownsWon, place: $place)';
}


}

/// @nodoc
abstract mixin class _$LeaderboardEntryCopyWith<$Res> implements $LeaderboardEntryCopyWith<$Res> {
  factory _$LeaderboardEntryCopyWith(_LeaderboardEntry value, $Res Function(_LeaderboardEntry) _then) = __$LeaderboardEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, int stack, int net, int handsWon, int biggestPot,@JsonKey(includeIfNull: false) int? handsPlayed,@JsonKey(includeIfNull: false) int? vpipHands,@JsonKey(includeIfNull: false) int? showdowns,@JsonKey(includeIfNull: false) int? showdownsWon,@JsonKey(includeIfNull: false) int? place
});




}
/// @nodoc
class __$LeaderboardEntryCopyWithImpl<$Res>
    implements _$LeaderboardEntryCopyWith<$Res> {
  __$LeaderboardEntryCopyWithImpl(this._self, this._then);

  final _LeaderboardEntry _self;
  final $Res Function(_LeaderboardEntry) _then;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? stack = null,Object? net = null,Object? handsWon = null,Object? biggestPot = null,Object? handsPlayed = freezed,Object? vpipHands = freezed,Object? showdowns = freezed,Object? showdownsWon = freezed,Object? place = freezed,}) {
  return _then(_LeaderboardEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,handsWon: null == handsWon ? _self.handsWon : handsWon // ignore: cast_nullable_to_non_nullable
as int,biggestPot: null == biggestPot ? _self.biggestPot : biggestPot // ignore: cast_nullable_to_non_nullable
as int,handsPlayed: freezed == handsPlayed ? _self.handsPlayed : handsPlayed // ignore: cast_nullable_to_non_nullable
as int?,vpipHands: freezed == vpipHands ? _self.vpipHands : vpipHands // ignore: cast_nullable_to_non_nullable
as int?,showdowns: freezed == showdowns ? _self.showdowns : showdowns // ignore: cast_nullable_to_non_nullable
as int?,showdownsWon: freezed == showdownsWon ? _self.showdownsWon : showdownsWon // ignore: cast_nullable_to_non_nullable
as int?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$EventsPayload {

 int get handNumber; List<GameEvent> get events;
/// Create a copy of EventsPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventsPayloadCopyWith<EventsPayload> get copyWith => _$EventsPayloadCopyWithImpl<EventsPayload>(this as EventsPayload, _$identity);

  /// Serializes this EventsPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventsPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventsPayload&&(identical(other.handNumber, _this.handNumber) || other.handNumber == _this.handNumber)&&const DeepCollectionEquality().equals(other.events, _this.events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventsPayload;
  return Object.hash(runtimeType,_this.handNumber,const DeepCollectionEquality().hash(_this.events));
}

@override
String toString() {
  final _this = this as EventsPayload;
  return 'EventsPayload(handNumber: ${_this.handNumber}, events: ${_this.events})';
}


}

/// @nodoc
abstract mixin class $EventsPayloadCopyWith<$Res>  {
  factory $EventsPayloadCopyWith(EventsPayload value, $Res Function(EventsPayload) _then) = _$EventsPayloadCopyWithImpl;
@useResult
$Res call({
 int handNumber, List<GameEvent> events
});




}
/// @nodoc
class _$EventsPayloadCopyWithImpl<$Res>
    implements $EventsPayloadCopyWith<$Res> {
  _$EventsPayloadCopyWithImpl(this._self, this._then);

  final EventsPayload _self;
  final $Res Function(EventsPayload) _then;

/// Create a copy of EventsPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? handNumber = null,Object? events = null,}) {
  return _then(EventsPayload(
handNumber: null == handNumber ? _self.handNumber : handNumber // ignore: cast_nullable_to_non_nullable
as int,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [EventsPayload].
extension EventsPayloadPatterns on EventsPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventsPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventsPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventsPayload value)  $default,){
final _that = this;
switch (_that) {
case _EventsPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventsPayload value)?  $default,){
final _that = this;
switch (_that) {
case _EventsPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int handNumber,  List<GameEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventsPayload() when $default != null:
return $default(_that.handNumber,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int handNumber,  List<GameEvent> events)  $default,) {final _that = this;
switch (_that) {
case _EventsPayload():
return $default(_that.handNumber,_that.events);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int handNumber,  List<GameEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _EventsPayload() when $default != null:
return $default(_that.handNumber,_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventsPayload implements EventsPayload {
  const _EventsPayload({required this.handNumber, required  List<GameEvent> events}): _events = events;
  factory _EventsPayload.fromJson(Map<String, dynamic> json) => _$EventsPayloadFromJson(json);

@override final  int handNumber;
 final  List<GameEvent> _events;
@override List<GameEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of EventsPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventsPayloadCopyWith<_EventsPayload> get copyWith => __$EventsPayloadCopyWithImpl<_EventsPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventsPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventsPayload&&(identical(other.handNumber, handNumber) || other.handNumber == handNumber)&&const DeepCollectionEquality().equals(other.events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,handNumber,const DeepCollectionEquality().hash(_events));
}

@override
String toString() {
    return 'EventsPayload(handNumber: $handNumber, events: $events)';
}


}

/// @nodoc
abstract mixin class _$EventsPayloadCopyWith<$Res> implements $EventsPayloadCopyWith<$Res> {
  factory _$EventsPayloadCopyWith(_EventsPayload value, $Res Function(_EventsPayload) _then) = __$EventsPayloadCopyWithImpl;
@override @useResult
$Res call({
 int handNumber, List<GameEvent> events
});




}
/// @nodoc
class __$EventsPayloadCopyWithImpl<$Res>
    implements _$EventsPayloadCopyWith<$Res> {
  __$EventsPayloadCopyWithImpl(this._self, this._then);

  final _EventsPayload _self;
  final $Res Function(_EventsPayload) _then;

/// Create a copy of EventsPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? handNumber = null,Object? events = null,}) {
  return _then(_EventsPayload(
handNumber: null == handNumber ? _self.handNumber : handNumber // ignore: cast_nullable_to_non_nullable
as int,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,
  ));
}


}


/// @nodoc
mixin _$GameEvent {

 int get seq; int get ts; String get kind;@JsonKey(includeIfNull: false) int? get seat;@JsonKey(includeIfNull: false) String? get name;@JsonKey(includeIfNull: false) int? get amount;@JsonKey(includeIfNull: false) int? get delta;@JsonKey(includeIfNull: false) bool? get allIn;@JsonKey(includeIfNull: false) String? get action;@JsonKey(includeIfNull: false) String? get blind;@JsonKey(includeIfNull: false) String? get resolvedAs;@JsonKey(includeIfNull: false) String? get street;@JsonKey(includeIfNull: false) List<String>? get cards;@JsonKey(includeIfNull: false) List<PotView>? get pots;@JsonKey(includeIfNull: false) List<Reveal>? get reveals;@JsonKey(includeIfNull: false) int? get potIndex;@JsonKey(includeIfNull: false) int? get board;@JsonKey(includeIfNull: false) String? get description;@JsonKey(includeIfNull: false) HandResults? get results;@JsonKey(includeIfNull: false) String? get reason;@JsonKey(includeIfNull: false) List<String>? get fields;@JsonKey(includeIfNull: false) int? get buttonSeat;@JsonKey(includeIfNull: false) int? get sbSeat;@JsonKey(includeIfNull: false) int? get bbSeat;@JsonKey(includeIfNull: false) Blinds? get blinds;@JsonKey(includeIfNull: false) int? get ante;@JsonKey(includeIfNull: false) Map<String, int>? get stacks;
/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEventCopyWith<GameEvent> get copyWith => _$GameEventCopyWithImpl<GameEvent>(this as GameEvent, _$identity);

  /// Serializes this GameEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GameEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEvent&&(identical(other.seq, _this.seq) || other.seq == _this.seq)&&(identical(other.ts, _this.ts) || other.ts == _this.ts)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.delta, _this.delta) || other.delta == _this.delta)&&(identical(other.allIn, _this.allIn) || other.allIn == _this.allIn)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.blind, _this.blind) || other.blind == _this.blind)&&(identical(other.resolvedAs, _this.resolvedAs) || other.resolvedAs == _this.resolvedAs)&&(identical(other.street, _this.street) || other.street == _this.street)&&const DeepCollectionEquality().equals(other.cards, _this.cards)&&const DeepCollectionEquality().equals(other.pots, _this.pots)&&const DeepCollectionEquality().equals(other.reveals, _this.reveals)&&(identical(other.potIndex, _this.potIndex) || other.potIndex == _this.potIndex)&&(identical(other.board, _this.board) || other.board == _this.board)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.results, _this.results) || other.results == _this.results)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&const DeepCollectionEquality().equals(other.fields, _this.fields)&&(identical(other.buttonSeat, _this.buttonSeat) || other.buttonSeat == _this.buttonSeat)&&(identical(other.sbSeat, _this.sbSeat) || other.sbSeat == _this.sbSeat)&&(identical(other.bbSeat, _this.bbSeat) || other.bbSeat == _this.bbSeat)&&(identical(other.blinds, _this.blinds) || other.blinds == _this.blinds)&&(identical(other.ante, _this.ante) || other.ante == _this.ante)&&const DeepCollectionEquality().equals(other.stacks, _this.stacks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GameEvent;
  return Object.hashAll([runtimeType,_this.seq,_this.ts,_this.kind,_this.seat,_this.name,_this.amount,_this.delta,_this.allIn,_this.action,_this.blind,_this.resolvedAs,_this.street,const DeepCollectionEquality().hash(_this.cards),const DeepCollectionEquality().hash(_this.pots),const DeepCollectionEquality().hash(_this.reveals),_this.potIndex,_this.board,_this.description,_this.results,_this.reason,const DeepCollectionEquality().hash(_this.fields),_this.buttonSeat,_this.sbSeat,_this.bbSeat,_this.blinds,_this.ante,const DeepCollectionEquality().hash(_this.stacks)]);
}

@override
String toString() {
  final _this = this as GameEvent;
  return 'GameEvent(seq: ${_this.seq}, ts: ${_this.ts}, kind: ${_this.kind}, seat: ${_this.seat}, name: ${_this.name}, amount: ${_this.amount}, delta: ${_this.delta}, allIn: ${_this.allIn}, action: ${_this.action}, blind: ${_this.blind}, resolvedAs: ${_this.resolvedAs}, street: ${_this.street}, cards: ${_this.cards}, pots: ${_this.pots}, reveals: ${_this.reveals}, potIndex: ${_this.potIndex}, board: ${_this.board}, description: ${_this.description}, results: ${_this.results}, reason: ${_this.reason}, fields: ${_this.fields}, buttonSeat: ${_this.buttonSeat}, sbSeat: ${_this.sbSeat}, bbSeat: ${_this.bbSeat}, blinds: ${_this.blinds}, ante: ${_this.ante}, stacks: ${_this.stacks})';
}


}

/// @nodoc
abstract mixin class $GameEventCopyWith<$Res>  {
  factory $GameEventCopyWith(GameEvent value, $Res Function(GameEvent) _then) = _$GameEventCopyWithImpl;
@useResult
$Res call({
 int seq, int ts, String kind,@JsonKey(includeIfNull: false) int? seat,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false) int? amount,@JsonKey(includeIfNull: false) int? delta,@JsonKey(includeIfNull: false) bool? allIn,@JsonKey(includeIfNull: false) String? action,@JsonKey(includeIfNull: false) String? blind,@JsonKey(includeIfNull: false) String? resolvedAs,@JsonKey(includeIfNull: false) String? street,@JsonKey(includeIfNull: false) List<String>? cards,@JsonKey(includeIfNull: false) List<PotView>? pots,@JsonKey(includeIfNull: false) List<Reveal>? reveals,@JsonKey(includeIfNull: false) int? potIndex,@JsonKey(includeIfNull: false) int? board,@JsonKey(includeIfNull: false) String? description,@JsonKey(includeIfNull: false) HandResults? results,@JsonKey(includeIfNull: false) String? reason,@JsonKey(includeIfNull: false) List<String>? fields,@JsonKey(includeIfNull: false) int? buttonSeat,@JsonKey(includeIfNull: false) int? sbSeat,@JsonKey(includeIfNull: false) int? bbSeat,@JsonKey(includeIfNull: false) Blinds? blinds,@JsonKey(includeIfNull: false) int? ante,@JsonKey(includeIfNull: false) Map<String, int>? stacks
});


$HandResultsCopyWith<$Res>? get results;$BlindsCopyWith<$Res>? get blinds;

}
/// @nodoc
class _$GameEventCopyWithImpl<$Res>
    implements $GameEventCopyWith<$Res> {
  _$GameEventCopyWithImpl(this._self, this._then);

  final GameEvent _self;
  final $Res Function(GameEvent) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seq = null,Object? ts = null,Object? kind = null,Object? seat = freezed,Object? name = freezed,Object? amount = freezed,Object? delta = freezed,Object? allIn = freezed,Object? action = freezed,Object? blind = freezed,Object? resolvedAs = freezed,Object? street = freezed,Object? cards = freezed,Object? pots = freezed,Object? reveals = freezed,Object? potIndex = freezed,Object? board = freezed,Object? description = freezed,Object? results = freezed,Object? reason = freezed,Object? fields = freezed,Object? buttonSeat = freezed,Object? sbSeat = freezed,Object? bbSeat = freezed,Object? blinds = freezed,Object? ante = freezed,Object? stacks = freezed,}) {
  return _then(GameEvent(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,seat: freezed == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,delta: freezed == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as int?,allIn: freezed == allIn ? _self.allIn : allIn // ignore: cast_nullable_to_non_nullable
as bool?,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,blind: freezed == blind ? _self.blind : blind // ignore: cast_nullable_to_non_nullable
as String?,resolvedAs: freezed == resolvedAs ? _self.resolvedAs : resolvedAs // ignore: cast_nullable_to_non_nullable
as String?,street: freezed == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String?,cards: freezed == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<String>?,pots: freezed == pots ? _self.pots : pots // ignore: cast_nullable_to_non_nullable
as List<PotView>?,reveals: freezed == reveals ? _self.reveals : reveals // ignore: cast_nullable_to_non_nullable
as List<Reveal>?,potIndex: freezed == potIndex ? _self.potIndex : potIndex // ignore: cast_nullable_to_non_nullable
as int?,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,results: freezed == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as HandResults?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,fields: freezed == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<String>?,buttonSeat: freezed == buttonSeat ? _self.buttonSeat : buttonSeat // ignore: cast_nullable_to_non_nullable
as int?,sbSeat: freezed == sbSeat ? _self.sbSeat : sbSeat // ignore: cast_nullable_to_non_nullable
as int?,bbSeat: freezed == bbSeat ? _self.bbSeat : bbSeat // ignore: cast_nullable_to_non_nullable
as int?,blinds: freezed == blinds ? _self.blinds : blinds // ignore: cast_nullable_to_non_nullable
as Blinds?,ante: freezed == ante ? _self.ante : ante // ignore: cast_nullable_to_non_nullable
as int?,stacks: freezed == stacks ? _self.stacks : stacks // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,
  ));
}
/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HandResultsCopyWith<$Res>? get results {
    if (_self.results == null) {
    return null;
  }

  return $HandResultsCopyWith<$Res>(_self.results!, (value) {
    return _then(_self.copyWith(results: value));
  });
}/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BlindsCopyWith<$Res>? get blinds {
    if (_self.blinds == null) {
    return null;
  }

  return $BlindsCopyWith<$Res>(_self.blinds!, (value) {
    return _then(_self.copyWith(blinds: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameEvent].
extension GameEventPatterns on GameEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameEvent value)  $default,){
final _that = this;
switch (_that) {
case _GameEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameEvent value)?  $default,){
final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seq,  int ts,  String kind, @JsonKey(includeIfNull: false)  int? seat, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)  int? amount, @JsonKey(includeIfNull: false)  int? delta, @JsonKey(includeIfNull: false)  bool? allIn, @JsonKey(includeIfNull: false)  String? action, @JsonKey(includeIfNull: false)  String? blind, @JsonKey(includeIfNull: false)  String? resolvedAs, @JsonKey(includeIfNull: false)  String? street, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  List<PotView>? pots, @JsonKey(includeIfNull: false)  List<Reveal>? reveals, @JsonKey(includeIfNull: false)  int? potIndex, @JsonKey(includeIfNull: false)  int? board, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  HandResults? results, @JsonKey(includeIfNull: false)  String? reason, @JsonKey(includeIfNull: false)  List<String>? fields, @JsonKey(includeIfNull: false)  int? buttonSeat, @JsonKey(includeIfNull: false)  int? sbSeat, @JsonKey(includeIfNull: false)  int? bbSeat, @JsonKey(includeIfNull: false)  Blinds? blinds, @JsonKey(includeIfNull: false)  int? ante, @JsonKey(includeIfNull: false)  Map<String, int>? stacks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
return $default(_that.seq,_that.ts,_that.kind,_that.seat,_that.name,_that.amount,_that.delta,_that.allIn,_that.action,_that.blind,_that.resolvedAs,_that.street,_that.cards,_that.pots,_that.reveals,_that.potIndex,_that.board,_that.description,_that.results,_that.reason,_that.fields,_that.buttonSeat,_that.sbSeat,_that.bbSeat,_that.blinds,_that.ante,_that.stacks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seq,  int ts,  String kind, @JsonKey(includeIfNull: false)  int? seat, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)  int? amount, @JsonKey(includeIfNull: false)  int? delta, @JsonKey(includeIfNull: false)  bool? allIn, @JsonKey(includeIfNull: false)  String? action, @JsonKey(includeIfNull: false)  String? blind, @JsonKey(includeIfNull: false)  String? resolvedAs, @JsonKey(includeIfNull: false)  String? street, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  List<PotView>? pots, @JsonKey(includeIfNull: false)  List<Reveal>? reveals, @JsonKey(includeIfNull: false)  int? potIndex, @JsonKey(includeIfNull: false)  int? board, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  HandResults? results, @JsonKey(includeIfNull: false)  String? reason, @JsonKey(includeIfNull: false)  List<String>? fields, @JsonKey(includeIfNull: false)  int? buttonSeat, @JsonKey(includeIfNull: false)  int? sbSeat, @JsonKey(includeIfNull: false)  int? bbSeat, @JsonKey(includeIfNull: false)  Blinds? blinds, @JsonKey(includeIfNull: false)  int? ante, @JsonKey(includeIfNull: false)  Map<String, int>? stacks)  $default,) {final _that = this;
switch (_that) {
case _GameEvent():
return $default(_that.seq,_that.ts,_that.kind,_that.seat,_that.name,_that.amount,_that.delta,_that.allIn,_that.action,_that.blind,_that.resolvedAs,_that.street,_that.cards,_that.pots,_that.reveals,_that.potIndex,_that.board,_that.description,_that.results,_that.reason,_that.fields,_that.buttonSeat,_that.sbSeat,_that.bbSeat,_that.blinds,_that.ante,_that.stacks);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seq,  int ts,  String kind, @JsonKey(includeIfNull: false)  int? seat, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)  int? amount, @JsonKey(includeIfNull: false)  int? delta, @JsonKey(includeIfNull: false)  bool? allIn, @JsonKey(includeIfNull: false)  String? action, @JsonKey(includeIfNull: false)  String? blind, @JsonKey(includeIfNull: false)  String? resolvedAs, @JsonKey(includeIfNull: false)  String? street, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  List<PotView>? pots, @JsonKey(includeIfNull: false)  List<Reveal>? reveals, @JsonKey(includeIfNull: false)  int? potIndex, @JsonKey(includeIfNull: false)  int? board, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  HandResults? results, @JsonKey(includeIfNull: false)  String? reason, @JsonKey(includeIfNull: false)  List<String>? fields, @JsonKey(includeIfNull: false)  int? buttonSeat, @JsonKey(includeIfNull: false)  int? sbSeat, @JsonKey(includeIfNull: false)  int? bbSeat, @JsonKey(includeIfNull: false)  Blinds? blinds, @JsonKey(includeIfNull: false)  int? ante, @JsonKey(includeIfNull: false)  Map<String, int>? stacks)?  $default,) {final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
return $default(_that.seq,_that.ts,_that.kind,_that.seat,_that.name,_that.amount,_that.delta,_that.allIn,_that.action,_that.blind,_that.resolvedAs,_that.street,_that.cards,_that.pots,_that.reveals,_that.potIndex,_that.board,_that.description,_that.results,_that.reason,_that.fields,_that.buttonSeat,_that.sbSeat,_that.bbSeat,_that.blinds,_that.ante,_that.stacks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameEvent implements GameEvent {
  const _GameEvent({required this.seq, required this.ts, required this.kind, @JsonKey(includeIfNull: false) this.seat, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false) this.amount, @JsonKey(includeIfNull: false) this.delta, @JsonKey(includeIfNull: false) this.allIn, @JsonKey(includeIfNull: false) this.action, @JsonKey(includeIfNull: false) this.blind, @JsonKey(includeIfNull: false) this.resolvedAs, @JsonKey(includeIfNull: false) this.street, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  List<PotView>? pots, @JsonKey(includeIfNull: false)  List<Reveal>? reveals, @JsonKey(includeIfNull: false) this.potIndex, @JsonKey(includeIfNull: false) this.board, @JsonKey(includeIfNull: false) this.description, @JsonKey(includeIfNull: false) this.results, @JsonKey(includeIfNull: false) this.reason, @JsonKey(includeIfNull: false)  List<String>? fields, @JsonKey(includeIfNull: false) this.buttonSeat, @JsonKey(includeIfNull: false) this.sbSeat, @JsonKey(includeIfNull: false) this.bbSeat, @JsonKey(includeIfNull: false) this.blinds, @JsonKey(includeIfNull: false) this.ante, @JsonKey(includeIfNull: false)  Map<String, int>? stacks}): _cards = cards,_pots = pots,_reveals = reveals,_fields = fields,_stacks = stacks;
  factory _GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);

@override final  int seq;
@override final  int ts;
@override final  String kind;
@override@JsonKey(includeIfNull: false) final  int? seat;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false) final  int? amount;
@override@JsonKey(includeIfNull: false) final  int? delta;
@override@JsonKey(includeIfNull: false) final  bool? allIn;
@override@JsonKey(includeIfNull: false) final  String? action;
@override@JsonKey(includeIfNull: false) final  String? blind;
@override@JsonKey(includeIfNull: false) final  String? resolvedAs;
@override@JsonKey(includeIfNull: false) final  String? street;
 final  List<String>? _cards;
@override@JsonKey(includeIfNull: false) List<String>? get cards {
  final value = _cards;
  if (value == null) return null;
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<PotView>? _pots;
@override@JsonKey(includeIfNull: false) List<PotView>? get pots {
  final value = _pots;
  if (value == null) return null;
  if (_pots is EqualUnmodifiableListView) return _pots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Reveal>? _reveals;
@override@JsonKey(includeIfNull: false) List<Reveal>? get reveals {
  final value = _reveals;
  if (value == null) return null;
  if (_reveals is EqualUnmodifiableListView) return _reveals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  int? potIndex;
@override@JsonKey(includeIfNull: false) final  int? board;
@override@JsonKey(includeIfNull: false) final  String? description;
@override@JsonKey(includeIfNull: false) final  HandResults? results;
@override@JsonKey(includeIfNull: false) final  String? reason;
 final  List<String>? _fields;
@override@JsonKey(includeIfNull: false) List<String>? get fields {
  final value = _fields;
  if (value == null) return null;
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  int? buttonSeat;
@override@JsonKey(includeIfNull: false) final  int? sbSeat;
@override@JsonKey(includeIfNull: false) final  int? bbSeat;
@override@JsonKey(includeIfNull: false) final  Blinds? blinds;
@override@JsonKey(includeIfNull: false) final  int? ante;
 final  Map<String, int>? _stacks;
@override@JsonKey(includeIfNull: false) Map<String, int>? get stacks {
  final value = _stacks;
  if (value == null) return null;
  if (_stacks is EqualUnmodifiableMapView) return _stacks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameEventCopyWith<_GameEvent> get copyWith => __$GameEventCopyWithImpl<_GameEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameEvent&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.ts, ts) || other.ts == ts)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.delta, delta) || other.delta == delta)&&(identical(other.allIn, allIn) || other.allIn == allIn)&&(identical(other.action, action) || other.action == action)&&(identical(other.blind, blind) || other.blind == blind)&&(identical(other.resolvedAs, resolvedAs) || other.resolvedAs == resolvedAs)&&(identical(other.street, street) || other.street == street)&&const DeepCollectionEquality().equals(other.cards, _cards)&&const DeepCollectionEquality().equals(other.pots, _pots)&&const DeepCollectionEquality().equals(other.reveals, _reveals)&&(identical(other.potIndex, potIndex) || other.potIndex == potIndex)&&(identical(other.board, board) || other.board == board)&&(identical(other.description, description) || other.description == description)&&(identical(other.results, results) || other.results == results)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.fields, _fields)&&(identical(other.buttonSeat, buttonSeat) || other.buttonSeat == buttonSeat)&&(identical(other.sbSeat, sbSeat) || other.sbSeat == sbSeat)&&(identical(other.bbSeat, bbSeat) || other.bbSeat == bbSeat)&&(identical(other.blinds, blinds) || other.blinds == blinds)&&(identical(other.ante, ante) || other.ante == ante)&&const DeepCollectionEquality().equals(other.stacks, _stacks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,seq,ts,kind,seat,name,amount,delta,allIn,action,blind,resolvedAs,street,const DeepCollectionEquality().hash(_cards),const DeepCollectionEquality().hash(_pots),const DeepCollectionEquality().hash(_reveals),potIndex,board,description,results,reason,const DeepCollectionEquality().hash(_fields),buttonSeat,sbSeat,bbSeat,blinds,ante,const DeepCollectionEquality().hash(_stacks)]);
}

@override
String toString() {
    return 'GameEvent(seq: $seq, ts: $ts, kind: $kind, seat: $seat, name: $name, amount: $amount, delta: $delta, allIn: $allIn, action: $action, blind: $blind, resolvedAs: $resolvedAs, street: $street, cards: $cards, pots: $pots, reveals: $reveals, potIndex: $potIndex, board: $board, description: $description, results: $results, reason: $reason, fields: $fields, buttonSeat: $buttonSeat, sbSeat: $sbSeat, bbSeat: $bbSeat, blinds: $blinds, ante: $ante, stacks: $stacks)';
}


}

/// @nodoc
abstract mixin class _$GameEventCopyWith<$Res> implements $GameEventCopyWith<$Res> {
  factory _$GameEventCopyWith(_GameEvent value, $Res Function(_GameEvent) _then) = __$GameEventCopyWithImpl;
@override @useResult
$Res call({
 int seq, int ts, String kind,@JsonKey(includeIfNull: false) int? seat,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false) int? amount,@JsonKey(includeIfNull: false) int? delta,@JsonKey(includeIfNull: false) bool? allIn,@JsonKey(includeIfNull: false) String? action,@JsonKey(includeIfNull: false) String? blind,@JsonKey(includeIfNull: false) String? resolvedAs,@JsonKey(includeIfNull: false) String? street,@JsonKey(includeIfNull: false) List<String>? cards,@JsonKey(includeIfNull: false) List<PotView>? pots,@JsonKey(includeIfNull: false) List<Reveal>? reveals,@JsonKey(includeIfNull: false) int? potIndex,@JsonKey(includeIfNull: false) int? board,@JsonKey(includeIfNull: false) String? description,@JsonKey(includeIfNull: false) HandResults? results,@JsonKey(includeIfNull: false) String? reason,@JsonKey(includeIfNull: false) List<String>? fields,@JsonKey(includeIfNull: false) int? buttonSeat,@JsonKey(includeIfNull: false) int? sbSeat,@JsonKey(includeIfNull: false) int? bbSeat,@JsonKey(includeIfNull: false) Blinds? blinds,@JsonKey(includeIfNull: false) int? ante,@JsonKey(includeIfNull: false) Map<String, int>? stacks
});


@override $HandResultsCopyWith<$Res>? get results;@override $BlindsCopyWith<$Res>? get blinds;

}
/// @nodoc
class __$GameEventCopyWithImpl<$Res>
    implements _$GameEventCopyWith<$Res> {
  __$GameEventCopyWithImpl(this._self, this._then);

  final _GameEvent _self;
  final $Res Function(_GameEvent) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seq = null,Object? ts = null,Object? kind = null,Object? seat = freezed,Object? name = freezed,Object? amount = freezed,Object? delta = freezed,Object? allIn = freezed,Object? action = freezed,Object? blind = freezed,Object? resolvedAs = freezed,Object? street = freezed,Object? cards = freezed,Object? pots = freezed,Object? reveals = freezed,Object? potIndex = freezed,Object? board = freezed,Object? description = freezed,Object? results = freezed,Object? reason = freezed,Object? fields = freezed,Object? buttonSeat = freezed,Object? sbSeat = freezed,Object? bbSeat = freezed,Object? blinds = freezed,Object? ante = freezed,Object? stacks = freezed,}) {
  return _then(_GameEvent(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,seat: freezed == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,delta: freezed == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as int?,allIn: freezed == allIn ? _self.allIn : allIn // ignore: cast_nullable_to_non_nullable
as bool?,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,blind: freezed == blind ? _self.blind : blind // ignore: cast_nullable_to_non_nullable
as String?,resolvedAs: freezed == resolvedAs ? _self.resolvedAs : resolvedAs // ignore: cast_nullable_to_non_nullable
as String?,street: freezed == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String?,cards: freezed == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<String>?,pots: freezed == pots ? _self._pots : pots // ignore: cast_nullable_to_non_nullable
as List<PotView>?,reveals: freezed == reveals ? _self._reveals : reveals // ignore: cast_nullable_to_non_nullable
as List<Reveal>?,potIndex: freezed == potIndex ? _self.potIndex : potIndex // ignore: cast_nullable_to_non_nullable
as int?,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,results: freezed == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as HandResults?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,fields: freezed == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<String>?,buttonSeat: freezed == buttonSeat ? _self.buttonSeat : buttonSeat // ignore: cast_nullable_to_non_nullable
as int?,sbSeat: freezed == sbSeat ? _self.sbSeat : sbSeat // ignore: cast_nullable_to_non_nullable
as int?,bbSeat: freezed == bbSeat ? _self.bbSeat : bbSeat // ignore: cast_nullable_to_non_nullable
as int?,blinds: freezed == blinds ? _self.blinds : blinds // ignore: cast_nullable_to_non_nullable
as Blinds?,ante: freezed == ante ? _self.ante : ante // ignore: cast_nullable_to_non_nullable
as int?,stacks: freezed == stacks ? _self._stacks : stacks // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,
  ));
}

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HandResultsCopyWith<$Res>? get results {
    if (_self.results == null) {
    return null;
  }

  return $HandResultsCopyWith<$Res>(_self.results!, (value) {
    return _then(_self.copyWith(results: value));
  });
}/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BlindsCopyWith<$Res>? get blinds {
    if (_self.blinds == null) {
    return null;
  }

  return $BlindsCopyWith<$Res>(_self.blinds!, (value) {
    return _then(_self.copyWith(blinds: value));
  });
}
}


/// @nodoc
mixin _$Blinds {

 int get small; int get big;
/// Create a copy of Blinds
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlindsCopyWith<Blinds> get copyWith => _$BlindsCopyWithImpl<Blinds>(this as Blinds, _$identity);

  /// Serializes this Blinds to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Blinds;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Blinds&&(identical(other.small, _this.small) || other.small == _this.small)&&(identical(other.big, _this.big) || other.big == _this.big));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Blinds;
  return Object.hash(runtimeType,_this.small,_this.big);
}

@override
String toString() {
  final _this = this as Blinds;
  return 'Blinds(small: ${_this.small}, big: ${_this.big})';
}


}

/// @nodoc
abstract mixin class $BlindsCopyWith<$Res>  {
  factory $BlindsCopyWith(Blinds value, $Res Function(Blinds) _then) = _$BlindsCopyWithImpl;
@useResult
$Res call({
 int small, int big
});




}
/// @nodoc
class _$BlindsCopyWithImpl<$Res>
    implements $BlindsCopyWith<$Res> {
  _$BlindsCopyWithImpl(this._self, this._then);

  final Blinds _self;
  final $Res Function(Blinds) _then;

/// Create a copy of Blinds
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? small = null,Object? big = null,}) {
  return _then(Blinds(
small: null == small ? _self.small : small // ignore: cast_nullable_to_non_nullable
as int,big: null == big ? _self.big : big // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Blinds].
extension BlindsPatterns on Blinds {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Blinds value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Blinds() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Blinds value)  $default,){
final _that = this;
switch (_that) {
case _Blinds():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Blinds value)?  $default,){
final _that = this;
switch (_that) {
case _Blinds() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int small,  int big)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Blinds() when $default != null:
return $default(_that.small,_that.big);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int small,  int big)  $default,) {final _that = this;
switch (_that) {
case _Blinds():
return $default(_that.small,_that.big);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int small,  int big)?  $default,) {final _that = this;
switch (_that) {
case _Blinds() when $default != null:
return $default(_that.small,_that.big);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Blinds implements Blinds {
  const _Blinds({required this.small, required this.big});
  factory _Blinds.fromJson(Map<String, dynamic> json) => _$BlindsFromJson(json);

@override final  int small;
@override final  int big;

/// Create a copy of Blinds
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlindsCopyWith<_Blinds> get copyWith => __$BlindsCopyWithImpl<_Blinds>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlindsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Blinds&&(identical(other.small, small) || other.small == small)&&(identical(other.big, big) || other.big == big));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,small,big);
}

@override
String toString() {
    return 'Blinds(small: $small, big: $big)';
}


}

/// @nodoc
abstract mixin class _$BlindsCopyWith<$Res> implements $BlindsCopyWith<$Res> {
  factory _$BlindsCopyWith(_Blinds value, $Res Function(_Blinds) _then) = __$BlindsCopyWithImpl;
@override @useResult
$Res call({
 int small, int big
});




}
/// @nodoc
class __$BlindsCopyWithImpl<$Res>
    implements _$BlindsCopyWith<$Res> {
  __$BlindsCopyWithImpl(this._self, this._then);

  final _Blinds _self;
  final $Res Function(_Blinds) _then;

/// Create a copy of Blinds
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? small = null,Object? big = null,}) {
  return _then(_Blinds(
small: null == small ? _self.small : small // ignore: cast_nullable_to_non_nullable
as int,big: null == big ? _self.big : big // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Reveal {

 int get seat; List<String> get cards; String get description;@JsonKey(includeIfNull: false) List<String>? get best;
/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevealCopyWith<Reveal> get copyWith => _$RevealCopyWithImpl<Reveal>(this as Reveal, _$identity);

  /// Serializes this Reveal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reveal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reveal&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&const DeepCollectionEquality().equals(other.cards, _this.cards)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.best, _this.best));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reveal;
  return Object.hash(runtimeType,_this.seat,const DeepCollectionEquality().hash(_this.cards),_this.description,const DeepCollectionEquality().hash(_this.best));
}

@override
String toString() {
  final _this = this as Reveal;
  return 'Reveal(seat: ${_this.seat}, cards: ${_this.cards}, description: ${_this.description}, best: ${_this.best})';
}


}

/// @nodoc
abstract mixin class $RevealCopyWith<$Res>  {
  factory $RevealCopyWith(Reveal value, $Res Function(Reveal) _then) = _$RevealCopyWithImpl;
@useResult
$Res call({
 int seat, List<String> cards, String description,@JsonKey(includeIfNull: false) List<String>? best
});




}
/// @nodoc
class _$RevealCopyWithImpl<$Res>
    implements $RevealCopyWith<$Res> {
  _$RevealCopyWithImpl(this._self, this._then);

  final Reveal _self;
  final $Res Function(Reveal) _then;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seat = null,Object? cards = null,Object? description = null,Object? best = freezed,}) {
  return _then(Reveal(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Reveal].
extension RevealPatterns on Reveal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reveal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reveal value)  $default,){
final _that = this;
switch (_that) {
case _Reveal():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reveal value)?  $default,){
final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seat,  List<String> cards,  String description, @JsonKey(includeIfNull: false)  List<String>? best)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that.seat,_that.cards,_that.description,_that.best);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seat,  List<String> cards,  String description, @JsonKey(includeIfNull: false)  List<String>? best)  $default,) {final _that = this;
switch (_that) {
case _Reveal():
return $default(_that.seat,_that.cards,_that.description,_that.best);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seat,  List<String> cards,  String description, @JsonKey(includeIfNull: false)  List<String>? best)?  $default,) {final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that.seat,_that.cards,_that.description,_that.best);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reveal implements Reveal {
  const _Reveal({required this.seat, required  List<String> cards, required this.description, @JsonKey(includeIfNull: false)  List<String>? best}): _cards = cards,_best = best;
  factory _Reveal.fromJson(Map<String, dynamic> json) => _$RevealFromJson(json);

@override final  int seat;
 final  List<String> _cards;
@override List<String> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override final  String description;
 final  List<String>? _best;
@override@JsonKey(includeIfNull: false) List<String>? get best {
  final value = _best;
  if (value == null) return null;
  if (_best is EqualUnmodifiableListView) return _best;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealCopyWith<_Reveal> get copyWith => __$RevealCopyWithImpl<_Reveal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevealToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reveal&&(identical(other.seat, seat) || other.seat == seat)&&const DeepCollectionEquality().equals(other.cards, _cards)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.best, _best));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seat,const DeepCollectionEquality().hash(_cards),description,const DeepCollectionEquality().hash(_best));
}

@override
String toString() {
    return 'Reveal(seat: $seat, cards: $cards, description: $description, best: $best)';
}


}

/// @nodoc
abstract mixin class _$RevealCopyWith<$Res> implements $RevealCopyWith<$Res> {
  factory _$RevealCopyWith(_Reveal value, $Res Function(_Reveal) _then) = __$RevealCopyWithImpl;
@override @useResult
$Res call({
 int seat, List<String> cards, String description,@JsonKey(includeIfNull: false) List<String>? best
});




}
/// @nodoc
class __$RevealCopyWithImpl<$Res>
    implements _$RevealCopyWith<$Res> {
  __$RevealCopyWithImpl(this._self, this._then);

  final _Reveal _self;
  final $Res Function(_Reveal) _then;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seat = null,Object? cards = null,Object? description = null,Object? best = freezed,}) {
  return _then(_Reveal(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,best: freezed == best ? _self._best : best // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$HandResults {

 List<PotResult> get pots; Map<String, SeatResult> get seats;
/// Create a copy of HandResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandResultsCopyWith<HandResults> get copyWith => _$HandResultsCopyWithImpl<HandResults>(this as HandResults, _$identity);

  /// Serializes this HandResults to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HandResults;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HandResults&&const DeepCollectionEquality().equals(other.pots, _this.pots)&&const DeepCollectionEquality().equals(other.seats, _this.seats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HandResults;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.pots),const DeepCollectionEquality().hash(_this.seats));
}

@override
String toString() {
  final _this = this as HandResults;
  return 'HandResults(pots: ${_this.pots}, seats: ${_this.seats})';
}


}

/// @nodoc
abstract mixin class $HandResultsCopyWith<$Res>  {
  factory $HandResultsCopyWith(HandResults value, $Res Function(HandResults) _then) = _$HandResultsCopyWithImpl;
@useResult
$Res call({
 List<PotResult> pots, Map<String, SeatResult> seats
});




}
/// @nodoc
class _$HandResultsCopyWithImpl<$Res>
    implements $HandResultsCopyWith<$Res> {
  _$HandResultsCopyWithImpl(this._self, this._then);

  final HandResults _self;
  final $Res Function(HandResults) _then;

/// Create a copy of HandResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pots = null,Object? seats = null,}) {
  return _then(HandResults(
pots: null == pots ? _self.pots : pots // ignore: cast_nullable_to_non_nullable
as List<PotResult>,seats: null == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as Map<String, SeatResult>,
  ));
}

}


/// Adds pattern-matching-related methods to [HandResults].
extension HandResultsPatterns on HandResults {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HandResults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HandResults() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HandResults value)  $default,){
final _that = this;
switch (_that) {
case _HandResults():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HandResults value)?  $default,){
final _that = this;
switch (_that) {
case _HandResults() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PotResult> pots,  Map<String, SeatResult> seats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HandResults() when $default != null:
return $default(_that.pots,_that.seats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PotResult> pots,  Map<String, SeatResult> seats)  $default,) {final _that = this;
switch (_that) {
case _HandResults():
return $default(_that.pots,_that.seats);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PotResult> pots,  Map<String, SeatResult> seats)?  $default,) {final _that = this;
switch (_that) {
case _HandResults() when $default != null:
return $default(_that.pots,_that.seats);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HandResults implements HandResults {
  const _HandResults({required  List<PotResult> pots, required  Map<String, SeatResult> seats}): _pots = pots,_seats = seats;
  factory _HandResults.fromJson(Map<String, dynamic> json) => _$HandResultsFromJson(json);

 final  List<PotResult> _pots;
@override List<PotResult> get pots {
  if (_pots is EqualUnmodifiableListView) return _pots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pots);
}

 final  Map<String, SeatResult> _seats;
@override Map<String, SeatResult> get seats {
  if (_seats is EqualUnmodifiableMapView) return _seats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_seats);
}


/// Create a copy of HandResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandResultsCopyWith<_HandResults> get copyWith => __$HandResultsCopyWithImpl<_HandResults>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandResultsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HandResults&&const DeepCollectionEquality().equals(other.pots, _pots)&&const DeepCollectionEquality().equals(other.seats, _seats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_pots),const DeepCollectionEquality().hash(_seats));
}

@override
String toString() {
    return 'HandResults(pots: $pots, seats: $seats)';
}


}

/// @nodoc
abstract mixin class _$HandResultsCopyWith<$Res> implements $HandResultsCopyWith<$Res> {
  factory _$HandResultsCopyWith(_HandResults value, $Res Function(_HandResults) _then) = __$HandResultsCopyWithImpl;
@override @useResult
$Res call({
 List<PotResult> pots, Map<String, SeatResult> seats
});




}
/// @nodoc
class __$HandResultsCopyWithImpl<$Res>
    implements _$HandResultsCopyWith<$Res> {
  __$HandResultsCopyWithImpl(this._self, this._then);

  final _HandResults _self;
  final $Res Function(_HandResults) _then;

/// Create a copy of HandResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pots = null,Object? seats = null,}) {
  return _then(_HandResults(
pots: null == pots ? _self._pots : pots // ignore: cast_nullable_to_non_nullable
as List<PotResult>,seats: null == seats ? _self._seats : seats // ignore: cast_nullable_to_non_nullable
as Map<String, SeatResult>,
  ));
}


}


/// @nodoc
mixin _$PotResult {

 int get index; int get amount; List<PotWinner> get winners; String get description;
/// Create a copy of PotResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PotResultCopyWith<PotResult> get copyWith => _$PotResultCopyWithImpl<PotResult>(this as PotResult, _$identity);

  /// Serializes this PotResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PotResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PotResult&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&const DeepCollectionEquality().equals(other.winners, _this.winners)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PotResult;
  return Object.hash(runtimeType,_this.index,_this.amount,const DeepCollectionEquality().hash(_this.winners),_this.description);
}

@override
String toString() {
  final _this = this as PotResult;
  return 'PotResult(index: ${_this.index}, amount: ${_this.amount}, winners: ${_this.winners}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $PotResultCopyWith<$Res>  {
  factory $PotResultCopyWith(PotResult value, $Res Function(PotResult) _then) = _$PotResultCopyWithImpl;
@useResult
$Res call({
 int index, int amount, List<PotWinner> winners, String description
});




}
/// @nodoc
class _$PotResultCopyWithImpl<$Res>
    implements $PotResultCopyWith<$Res> {
  _$PotResultCopyWithImpl(this._self, this._then);

  final PotResult _self;
  final $Res Function(PotResult) _then;

/// Create a copy of PotResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? amount = null,Object? winners = null,Object? description = null,}) {
  return _then(PotResult(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,winners: null == winners ? _self.winners : winners // ignore: cast_nullable_to_non_nullable
as List<PotWinner>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PotResult].
extension PotResultPatterns on PotResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PotResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PotResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PotResult value)  $default,){
final _that = this;
switch (_that) {
case _PotResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PotResult value)?  $default,){
final _that = this;
switch (_that) {
case _PotResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  int amount,  List<PotWinner> winners,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PotResult() when $default != null:
return $default(_that.index,_that.amount,_that.winners,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  int amount,  List<PotWinner> winners,  String description)  $default,) {final _that = this;
switch (_that) {
case _PotResult():
return $default(_that.index,_that.amount,_that.winners,_that.description);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  int amount,  List<PotWinner> winners,  String description)?  $default,) {final _that = this;
switch (_that) {
case _PotResult() when $default != null:
return $default(_that.index,_that.amount,_that.winners,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PotResult implements PotResult {
  const _PotResult({required this.index, required this.amount, required  List<PotWinner> winners, required this.description}): _winners = winners;
  factory _PotResult.fromJson(Map<String, dynamic> json) => _$PotResultFromJson(json);

@override final  int index;
@override final  int amount;
 final  List<PotWinner> _winners;
@override List<PotWinner> get winners {
  if (_winners is EqualUnmodifiableListView) return _winners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winners);
}

@override final  String description;

/// Create a copy of PotResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PotResultCopyWith<_PotResult> get copyWith => __$PotResultCopyWithImpl<_PotResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PotResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PotResult&&(identical(other.index, index) || other.index == index)&&(identical(other.amount, amount) || other.amount == amount)&&const DeepCollectionEquality().equals(other.winners, _winners)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,amount,const DeepCollectionEquality().hash(_winners),description);
}

@override
String toString() {
    return 'PotResult(index: $index, amount: $amount, winners: $winners, description: $description)';
}


}

/// @nodoc
abstract mixin class _$PotResultCopyWith<$Res> implements $PotResultCopyWith<$Res> {
  factory _$PotResultCopyWith(_PotResult value, $Res Function(_PotResult) _then) = __$PotResultCopyWithImpl;
@override @useResult
$Res call({
 int index, int amount, List<PotWinner> winners, String description
});




}
/// @nodoc
class __$PotResultCopyWithImpl<$Res>
    implements _$PotResultCopyWith<$Res> {
  __$PotResultCopyWithImpl(this._self, this._then);

  final _PotResult _self;
  final $Res Function(_PotResult) _then;

/// Create a copy of PotResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? amount = null,Object? winners = null,Object? description = null,}) {
  return _then(_PotResult(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,winners: null == winners ? _self._winners : winners // ignore: cast_nullable_to_non_nullable
as List<PotWinner>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PotWinner {

 int get seat; int get amount;
/// Create a copy of PotWinner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PotWinnerCopyWith<PotWinner> get copyWith => _$PotWinnerCopyWithImpl<PotWinner>(this as PotWinner, _$identity);

  /// Serializes this PotWinner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PotWinner;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PotWinner&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&(identical(other.amount, _this.amount) || other.amount == _this.amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PotWinner;
  return Object.hash(runtimeType,_this.seat,_this.amount);
}

@override
String toString() {
  final _this = this as PotWinner;
  return 'PotWinner(seat: ${_this.seat}, amount: ${_this.amount})';
}


}

/// @nodoc
abstract mixin class $PotWinnerCopyWith<$Res>  {
  factory $PotWinnerCopyWith(PotWinner value, $Res Function(PotWinner) _then) = _$PotWinnerCopyWithImpl;
@useResult
$Res call({
 int seat, int amount
});




}
/// @nodoc
class _$PotWinnerCopyWithImpl<$Res>
    implements $PotWinnerCopyWith<$Res> {
  _$PotWinnerCopyWithImpl(this._self, this._then);

  final PotWinner _self;
  final $Res Function(PotWinner) _then;

/// Create a copy of PotWinner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seat = null,Object? amount = null,}) {
  return _then(PotWinner(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PotWinner].
extension PotWinnerPatterns on PotWinner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PotWinner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PotWinner() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PotWinner value)  $default,){
final _that = this;
switch (_that) {
case _PotWinner():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PotWinner value)?  $default,){
final _that = this;
switch (_that) {
case _PotWinner() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seat,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PotWinner() when $default != null:
return $default(_that.seat,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seat,  int amount)  $default,) {final _that = this;
switch (_that) {
case _PotWinner():
return $default(_that.seat,_that.amount);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seat,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _PotWinner() when $default != null:
return $default(_that.seat,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PotWinner implements PotWinner {
  const _PotWinner({required this.seat, required this.amount});
  factory _PotWinner.fromJson(Map<String, dynamic> json) => _$PotWinnerFromJson(json);

@override final  int seat;
@override final  int amount;

/// Create a copy of PotWinner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PotWinnerCopyWith<_PotWinner> get copyWith => __$PotWinnerCopyWithImpl<_PotWinner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PotWinnerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PotWinner&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seat,amount);
}

@override
String toString() {
    return 'PotWinner(seat: $seat, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$PotWinnerCopyWith<$Res> implements $PotWinnerCopyWith<$Res> {
  factory _$PotWinnerCopyWith(_PotWinner value, $Res Function(_PotWinner) _then) = __$PotWinnerCopyWithImpl;
@override @useResult
$Res call({
 int seat, int amount
});




}
/// @nodoc
class __$PotWinnerCopyWithImpl<$Res>
    implements _$PotWinnerCopyWith<$Res> {
  __$PotWinnerCopyWithImpl(this._self, this._then);

  final _PotWinner _self;
  final $Res Function(_PotWinner) _then;

/// Create a copy of PotWinner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seat = null,Object? amount = null,}) {
  return _then(_PotWinner(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SeatResult {

 int get net; int get won; bool get folded; bool get revealed;@JsonKey(includeIfNull: false) List<String>? get cards;@JsonKey(includeIfNull: false) String? get description;@JsonKey(includeIfNull: false) List<String>? get best;
/// Create a copy of SeatResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatResultCopyWith<SeatResult> get copyWith => _$SeatResultCopyWithImpl<SeatResult>(this as SeatResult, _$identity);

  /// Serializes this SeatResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeatResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeatResult&&(identical(other.net, _this.net) || other.net == _this.net)&&(identical(other.won, _this.won) || other.won == _this.won)&&(identical(other.folded, _this.folded) || other.folded == _this.folded)&&(identical(other.revealed, _this.revealed) || other.revealed == _this.revealed)&&const DeepCollectionEquality().equals(other.cards, _this.cards)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.best, _this.best));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeatResult;
  return Object.hash(runtimeType,_this.net,_this.won,_this.folded,_this.revealed,const DeepCollectionEquality().hash(_this.cards),_this.description,const DeepCollectionEquality().hash(_this.best));
}

@override
String toString() {
  final _this = this as SeatResult;
  return 'SeatResult(net: ${_this.net}, won: ${_this.won}, folded: ${_this.folded}, revealed: ${_this.revealed}, cards: ${_this.cards}, description: ${_this.description}, best: ${_this.best})';
}


}

/// @nodoc
abstract mixin class $SeatResultCopyWith<$Res>  {
  factory $SeatResultCopyWith(SeatResult value, $Res Function(SeatResult) _then) = _$SeatResultCopyWithImpl;
@useResult
$Res call({
 int net, int won, bool folded, bool revealed,@JsonKey(includeIfNull: false) List<String>? cards,@JsonKey(includeIfNull: false) String? description,@JsonKey(includeIfNull: false) List<String>? best
});




}
/// @nodoc
class _$SeatResultCopyWithImpl<$Res>
    implements $SeatResultCopyWith<$Res> {
  _$SeatResultCopyWithImpl(this._self, this._then);

  final SeatResult _self;
  final $Res Function(SeatResult) _then;

/// Create a copy of SeatResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? net = null,Object? won = null,Object? folded = null,Object? revealed = null,Object? cards = freezed,Object? description = freezed,Object? best = freezed,}) {
  return _then(SeatResult(
net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,folded: null == folded ? _self.folded : folded // ignore: cast_nullable_to_non_nullable
as bool,revealed: null == revealed ? _self.revealed : revealed // ignore: cast_nullable_to_non_nullable
as bool,cards: freezed == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<String>?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeatResult].
extension SeatResultPatterns on SeatResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeatResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeatResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeatResult value)  $default,){
final _that = this;
switch (_that) {
case _SeatResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeatResult value)?  $default,){
final _that = this;
switch (_that) {
case _SeatResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int net,  int won,  bool folded,  bool revealed, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  List<String>? best)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeatResult() when $default != null:
return $default(_that.net,_that.won,_that.folded,_that.revealed,_that.cards,_that.description,_that.best);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int net,  int won,  bool folded,  bool revealed, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  List<String>? best)  $default,) {final _that = this;
switch (_that) {
case _SeatResult():
return $default(_that.net,_that.won,_that.folded,_that.revealed,_that.cards,_that.description,_that.best);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int net,  int won,  bool folded,  bool revealed, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  List<String>? best)?  $default,) {final _that = this;
switch (_that) {
case _SeatResult() when $default != null:
return $default(_that.net,_that.won,_that.folded,_that.revealed,_that.cards,_that.description,_that.best);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeatResult implements SeatResult {
  const _SeatResult({required this.net, required this.won, required this.folded, required this.revealed, @JsonKey(includeIfNull: false)  List<String>? cards, @JsonKey(includeIfNull: false) this.description, @JsonKey(includeIfNull: false)  List<String>? best}): _cards = cards,_best = best;
  factory _SeatResult.fromJson(Map<String, dynamic> json) => _$SeatResultFromJson(json);

@override final  int net;
@override final  int won;
@override final  bool folded;
@override final  bool revealed;
 final  List<String>? _cards;
@override@JsonKey(includeIfNull: false) List<String>? get cards {
  final value = _cards;
  if (value == null) return null;
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  String? description;
 final  List<String>? _best;
@override@JsonKey(includeIfNull: false) List<String>? get best {
  final value = _best;
  if (value == null) return null;
  if (_best is EqualUnmodifiableListView) return _best;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SeatResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatResultCopyWith<_SeatResult> get copyWith => __$SeatResultCopyWithImpl<_SeatResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeatResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeatResult&&(identical(other.net, net) || other.net == net)&&(identical(other.won, won) || other.won == won)&&(identical(other.folded, folded) || other.folded == folded)&&(identical(other.revealed, revealed) || other.revealed == revealed)&&const DeepCollectionEquality().equals(other.cards, _cards)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.best, _best));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,net,won,folded,revealed,const DeepCollectionEquality().hash(_cards),description,const DeepCollectionEquality().hash(_best));
}

@override
String toString() {
    return 'SeatResult(net: $net, won: $won, folded: $folded, revealed: $revealed, cards: $cards, description: $description, best: $best)';
}


}

/// @nodoc
abstract mixin class _$SeatResultCopyWith<$Res> implements $SeatResultCopyWith<$Res> {
  factory _$SeatResultCopyWith(_SeatResult value, $Res Function(_SeatResult) _then) = __$SeatResultCopyWithImpl;
@override @useResult
$Res call({
 int net, int won, bool folded, bool revealed,@JsonKey(includeIfNull: false) List<String>? cards,@JsonKey(includeIfNull: false) String? description,@JsonKey(includeIfNull: false) List<String>? best
});




}
/// @nodoc
class __$SeatResultCopyWithImpl<$Res>
    implements _$SeatResultCopyWith<$Res> {
  __$SeatResultCopyWithImpl(this._self, this._then);

  final _SeatResult _self;
  final $Res Function(_SeatResult) _then;

/// Create a copy of SeatResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? net = null,Object? won = null,Object? folded = null,Object? revealed = null,Object? cards = freezed,Object? description = freezed,Object? best = freezed,}) {
  return _then(_SeatResult(
net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,folded: null == folded ? _self.folded : folded // ignore: cast_nullable_to_non_nullable
as bool,revealed: null == revealed ? _self.revealed : revealed // ignore: cast_nullable_to_non_nullable
as bool,cards: freezed == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<String>?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,best: freezed == best ? _self._best : best // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$ChatMessage {

 int get id; String get authorKind; String get authorName; String get text; int get ts;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.authorKind, _this.authorKind) || other.authorKind == _this.authorKind)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.ts, _this.ts) || other.ts == _this.ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatMessage;
  return Object.hash(runtimeType,_this.id,_this.authorKind,_this.authorName,_this.text,_this.ts);
}

@override
String toString() {
  final _this = this as ChatMessage;
  return 'ChatMessage(id: ${_this.id}, authorKind: ${_this.authorKind}, authorName: ${_this.authorName}, text: ${_this.text}, ts: ${_this.ts})';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 int id, String authorKind, String authorName, String text, int ts
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorKind = null,Object? authorName = null,Object? text = null,Object? ts = null,}) {
  return _then(ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorKind: null == authorKind ? _self.authorKind : authorKind // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String authorKind,  String authorName,  String text,  int ts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.authorKind,_that.authorName,_that.text,_that.ts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String authorKind,  String authorName,  String text,  int ts)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.authorKind,_that.authorName,_that.text,_that.ts);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String authorKind,  String authorName,  String text,  int ts)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.authorKind,_that.authorName,_that.text,_that.ts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.authorKind, required this.authorName, required this.text, required this.ts});
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  int id;
@override final  String authorKind;
@override final  String authorName;
@override final  String text;
@override final  int ts;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorKind, authorKind) || other.authorKind == authorKind)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.text, text) || other.text == text)&&(identical(other.ts, ts) || other.ts == ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,authorKind,authorName,text,ts);
}

@override
String toString() {
    return 'ChatMessage(id: $id, authorKind: $authorKind, authorName: $authorName, text: $text, ts: $ts)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 int id, String authorKind, String authorName, String text, int ts
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorKind = null,Object? authorName = null,Object? text = null,Object? ts = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorKind: null == authorKind ? _self.authorKind : authorKind // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChatHistory {

 List<ChatMessage> get messages;
/// Create a copy of ChatHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatHistoryCopyWith<ChatHistory> get copyWith => _$ChatHistoryCopyWithImpl<ChatHistory>(this as ChatHistory, _$identity);

  /// Serializes this ChatHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatHistory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatHistory&&const DeepCollectionEquality().equals(other.messages, _this.messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatHistory;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages));
}

@override
String toString() {
  final _this = this as ChatHistory;
  return 'ChatHistory(messages: ${_this.messages})';
}


}

/// @nodoc
abstract mixin class $ChatHistoryCopyWith<$Res>  {
  factory $ChatHistoryCopyWith(ChatHistory value, $Res Function(ChatHistory) _then) = _$ChatHistoryCopyWithImpl;
@useResult
$Res call({
 List<ChatMessage> messages
});




}
/// @nodoc
class _$ChatHistoryCopyWithImpl<$Res>
    implements $ChatHistoryCopyWith<$Res> {
  _$ChatHistoryCopyWithImpl(this._self, this._then);

  final ChatHistory _self;
  final $Res Function(ChatHistory) _then;

/// Create a copy of ChatHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,}) {
  return _then(ChatHistory(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatHistory].
extension ChatHistoryPatterns on ChatHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatHistory() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatHistory value)  $default,){
final _that = this;
switch (_that) {
case _ChatHistory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatHistory value)?  $default,){
final _that = this;
switch (_that) {
case _ChatHistory() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChatMessage> messages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatHistory() when $default != null:
return $default(_that.messages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChatMessage> messages)  $default,) {final _that = this;
switch (_that) {
case _ChatHistory():
return $default(_that.messages);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChatMessage> messages)?  $default,) {final _that = this;
switch (_that) {
case _ChatHistory() when $default != null:
return $default(_that.messages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatHistory implements ChatHistory {
  const _ChatHistory({required  List<ChatMessage> messages}): _messages = messages;
  factory _ChatHistory.fromJson(Map<String, dynamic> json) => _$ChatHistoryFromJson(json);

 final  List<ChatMessage> _messages;
@override List<ChatMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}


/// Create a copy of ChatHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatHistoryCopyWith<_ChatHistory> get copyWith => __$ChatHistoryCopyWithImpl<_ChatHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatHistory&&const DeepCollectionEquality().equals(other.messages, _messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages));
}

@override
String toString() {
    return 'ChatHistory(messages: $messages)';
}


}

/// @nodoc
abstract mixin class _$ChatHistoryCopyWith<$Res> implements $ChatHistoryCopyWith<$Res> {
  factory _$ChatHistoryCopyWith(_ChatHistory value, $Res Function(_ChatHistory) _then) = __$ChatHistoryCopyWithImpl;
@override @useResult
$Res call({
 List<ChatMessage> messages
});




}
/// @nodoc
class __$ChatHistoryCopyWithImpl<$Res>
    implements _$ChatHistoryCopyWith<$Res> {
  __$ChatHistoryCopyWithImpl(this._self, this._then);

  final _ChatHistory _self;
  final $Res Function(_ChatHistory) _then;

/// Create a copy of ChatHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,}) {
  return _then(_ChatHistory(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,
  ));
}


}


/// @nodoc
mixin _$ChatRemoved {

 int get id;
/// Create a copy of ChatRemoved
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRemovedCopyWith<ChatRemoved> get copyWith => _$ChatRemovedCopyWithImpl<ChatRemoved>(this as ChatRemoved, _$identity);

  /// Serializes this ChatRemoved to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatRemoved;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRemoved&&(identical(other.id, _this.id) || other.id == _this.id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatRemoved;
  return Object.hash(runtimeType,_this.id);
}

@override
String toString() {
  final _this = this as ChatRemoved;
  return 'ChatRemoved(id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $ChatRemovedCopyWith<$Res>  {
  factory $ChatRemovedCopyWith(ChatRemoved value, $Res Function(ChatRemoved) _then) = _$ChatRemovedCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class _$ChatRemovedCopyWithImpl<$Res>
    implements $ChatRemovedCopyWith<$Res> {
  _$ChatRemovedCopyWithImpl(this._self, this._then);

  final ChatRemoved _self;
  final $Res Function(ChatRemoved) _then;

/// Create a copy of ChatRemoved
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(ChatRemoved(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatRemoved].
extension ChatRemovedPatterns on ChatRemoved {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatRemoved value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatRemoved() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatRemoved value)  $default,){
final _that = this;
switch (_that) {
case _ChatRemoved():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatRemoved value)?  $default,){
final _that = this;
switch (_that) {
case _ChatRemoved() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatRemoved() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id)  $default,) {final _that = this;
switch (_that) {
case _ChatRemoved():
return $default(_that.id);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id)?  $default,) {final _that = this;
switch (_that) {
case _ChatRemoved() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatRemoved implements ChatRemoved {
  const _ChatRemoved({required this.id});
  factory _ChatRemoved.fromJson(Map<String, dynamic> json) => _$ChatRemovedFromJson(json);

@override final  int id;

/// Create a copy of ChatRemoved
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatRemovedCopyWith<_ChatRemoved> get copyWith => __$ChatRemovedCopyWithImpl<_ChatRemoved>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatRemovedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatRemoved&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id);
}

@override
String toString() {
    return 'ChatRemoved(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ChatRemovedCopyWith<$Res> implements $ChatRemovedCopyWith<$Res> {
  factory _$ChatRemovedCopyWith(_ChatRemoved value, $Res Function(_ChatRemoved) _then) = __$ChatRemovedCopyWithImpl;
@override @useResult
$Res call({
 int id
});




}
/// @nodoc
class __$ChatRemovedCopyWithImpl<$Res>
    implements _$ChatRemovedCopyWith<$Res> {
  __$ChatRemovedCopyWithImpl(this._self, this._then);

  final _ChatRemoved _self;
  final $Res Function(_ChatRemoved) _then;

/// Create a copy of ChatRemoved
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ChatRemoved(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Ack {

 String get id;
/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AckCopyWith<Ack> get copyWith => _$AckCopyWithImpl<Ack>(this as Ack, _$identity);

  /// Serializes this Ack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Ack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ack&&(identical(other.id, _this.id) || other.id == _this.id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ack;
  return Object.hash(runtimeType,_this.id);
}

@override
String toString() {
  final _this = this as Ack;
  return 'Ack(id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $AckCopyWith<$Res>  {
  factory $AckCopyWith(Ack value, $Res Function(Ack) _then) = _$AckCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$AckCopyWithImpl<$Res>
    implements $AckCopyWith<$Res> {
  _$AckCopyWithImpl(this._self, this._then);

  final Ack _self;
  final $Res Function(Ack) _then;

/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(Ack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Ack].
extension AckPatterns on Ack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ack() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ack value)  $default,){
final _that = this;
switch (_that) {
case _Ack():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ack value)?  $default,){
final _that = this;
switch (_that) {
case _Ack() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ack() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id)  $default,) {final _that = this;
switch (_that) {
case _Ack():
return $default(_that.id);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id)?  $default,) {final _that = this;
switch (_that) {
case _Ack() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ack implements Ack {
  const _Ack({required this.id});
  factory _Ack.fromJson(Map<String, dynamic> json) => _$AckFromJson(json);

@override final  String id;

/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AckCopyWith<_Ack> get copyWith => __$AckCopyWithImpl<_Ack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AckToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ack&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id);
}

@override
String toString() {
    return 'Ack(id: $id)';
}


}

/// @nodoc
abstract mixin class _$AckCopyWith<$Res> implements $AckCopyWith<$Res> {
  factory _$AckCopyWith(_Ack value, $Res Function(_Ack) _then) = __$AckCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class __$AckCopyWithImpl<$Res>
    implements _$AckCopyWith<$Res> {
  __$AckCopyWithImpl(this._self, this._then);

  final _Ack _self;
  final $Res Function(_Ack) _then;

/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_Ack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ErrorPayload {

@JsonKey(includeIfNull: false) String? get id; String get code; String get message;
/// Create a copy of ErrorPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorPayloadCopyWith<ErrorPayload> get copyWith => _$ErrorPayloadCopyWithImpl<ErrorPayload>(this as ErrorPayload, _$identity);

  /// Serializes this ErrorPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ErrorPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorPayload&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.message, _this.message) || other.message == _this.message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ErrorPayload;
  return Object.hash(runtimeType,_this.id,_this.code,_this.message);
}

@override
String toString() {
  final _this = this as ErrorPayload;
  return 'ErrorPayload(id: ${_this.id}, code: ${_this.code}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $ErrorPayloadCopyWith<$Res>  {
  factory $ErrorPayloadCopyWith(ErrorPayload value, $Res Function(ErrorPayload) _then) = _$ErrorPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? id, String code, String message
});




}
/// @nodoc
class _$ErrorPayloadCopyWithImpl<$Res>
    implements $ErrorPayloadCopyWith<$Res> {
  _$ErrorPayloadCopyWithImpl(this._self, this._then);

  final ErrorPayload _self;
  final $Res Function(ErrorPayload) _then;

/// Create a copy of ErrorPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? code = null,Object? message = null,}) {
  return _then(ErrorPayload(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ErrorPayload].
extension ErrorPayloadPatterns on ErrorPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorPayload value)  $default,){
final _that = this;
switch (_that) {
case _ErrorPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorPayload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? id,  String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorPayload() when $default != null:
return $default(_that.id,_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? id,  String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _ErrorPayload():
return $default(_that.id,_that.code,_that.message);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? id,  String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _ErrorPayload() when $default != null:
return $default(_that.id,_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorPayload implements ErrorPayload {
  const _ErrorPayload({@JsonKey(includeIfNull: false) this.id, required this.code, required this.message});
  factory _ErrorPayload.fromJson(Map<String, dynamic> json) => _$ErrorPayloadFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? id;
@override final  String code;
@override final  String message;

/// Create a copy of ErrorPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorPayloadCopyWith<_ErrorPayload> get copyWith => __$ErrorPayloadCopyWithImpl<_ErrorPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,code,message);
}

@override
String toString() {
    return 'ErrorPayload(id: $id, code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorPayloadCopyWith<$Res> implements $ErrorPayloadCopyWith<$Res> {
  factory _$ErrorPayloadCopyWith(_ErrorPayload value, $Res Function(_ErrorPayload) _then) = __$ErrorPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? id, String code, String message
});




}
/// @nodoc
class __$ErrorPayloadCopyWithImpl<$Res>
    implements _$ErrorPayloadCopyWith<$Res> {
  __$ErrorPayloadCopyWithImpl(this._self, this._then);

  final _ErrorPayload _self;
  final $Res Function(_ErrorPayload) _then;

/// Create a copy of ErrorPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? code = null,Object? message = null,}) {
  return _then(_ErrorPayload(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Kicked {

 String get reason;
/// Create a copy of Kicked
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickedCopyWith<Kicked> get copyWith => _$KickedCopyWithImpl<Kicked>(this as Kicked, _$identity);

  /// Serializes this Kicked to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Kicked;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Kicked&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Kicked;
  return Object.hash(runtimeType,_this.reason);
}

@override
String toString() {
  final _this = this as Kicked;
  return 'Kicked(reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $KickedCopyWith<$Res>  {
  factory $KickedCopyWith(Kicked value, $Res Function(Kicked) _then) = _$KickedCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$KickedCopyWithImpl<$Res>
    implements $KickedCopyWith<$Res> {
  _$KickedCopyWithImpl(this._self, this._then);

  final Kicked _self;
  final $Res Function(Kicked) _then;

/// Create a copy of Kicked
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,}) {
  return _then(Kicked(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Kicked].
extension KickedPatterns on Kicked {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Kicked value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Kicked() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Kicked value)  $default,){
final _that = this;
switch (_that) {
case _Kicked():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Kicked value)?  $default,){
final _that = this;
switch (_that) {
case _Kicked() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Kicked() when $default != null:
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reason)  $default,) {final _that = this;
switch (_that) {
case _Kicked():
return $default(_that.reason);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reason)?  $default,) {final _that = this;
switch (_that) {
case _Kicked() when $default != null:
return $default(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Kicked implements Kicked {
  const _Kicked({required this.reason});
  factory _Kicked.fromJson(Map<String, dynamic> json) => _$KickedFromJson(json);

@override final  String reason;

/// Create a copy of Kicked
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickedCopyWith<_Kicked> get copyWith => __$KickedCopyWithImpl<_Kicked>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KickedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Kicked&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'Kicked(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$KickedCopyWith<$Res> implements $KickedCopyWith<$Res> {
  factory _$KickedCopyWith(_Kicked value, $Res Function(_Kicked) _then) = __$KickedCopyWithImpl;
@override @useResult
$Res call({
 String reason
});




}
/// @nodoc
class __$KickedCopyWithImpl<$Res>
    implements _$KickedCopyWith<$Res> {
  __$KickedCopyWithImpl(this._self, this._then);

  final _Kicked _self;
  final $Res Function(_Kicked) _then;

/// Create a copy of Kicked
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_Kicked(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TableEnded {

 List<LeaderboardEntry> get finalLeaderboard;
/// Create a copy of TableEnded
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableEndedCopyWith<TableEnded> get copyWith => _$TableEndedCopyWithImpl<TableEnded>(this as TableEnded, _$identity);

  /// Serializes this TableEnded to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TableEnded;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableEnded&&const DeepCollectionEquality().equals(other.finalLeaderboard, _this.finalLeaderboard));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TableEnded;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.finalLeaderboard));
}

@override
String toString() {
  final _this = this as TableEnded;
  return 'TableEnded(finalLeaderboard: ${_this.finalLeaderboard})';
}


}

/// @nodoc
abstract mixin class $TableEndedCopyWith<$Res>  {
  factory $TableEndedCopyWith(TableEnded value, $Res Function(TableEnded) _then) = _$TableEndedCopyWithImpl;
@useResult
$Res call({
 List<LeaderboardEntry> finalLeaderboard
});




}
/// @nodoc
class _$TableEndedCopyWithImpl<$Res>
    implements $TableEndedCopyWith<$Res> {
  _$TableEndedCopyWithImpl(this._self, this._then);

  final TableEnded _self;
  final $Res Function(TableEnded) _then;

/// Create a copy of TableEnded
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? finalLeaderboard = null,}) {
  return _then(TableEnded(
finalLeaderboard: null == finalLeaderboard ? _self.finalLeaderboard : finalLeaderboard // ignore: cast_nullable_to_non_nullable
as List<LeaderboardEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [TableEnded].
extension TableEndedPatterns on TableEnded {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableEnded value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableEnded() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableEnded value)  $default,){
final _that = this;
switch (_that) {
case _TableEnded():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableEnded value)?  $default,){
final _that = this;
switch (_that) {
case _TableEnded() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LeaderboardEntry> finalLeaderboard)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableEnded() when $default != null:
return $default(_that.finalLeaderboard);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LeaderboardEntry> finalLeaderboard)  $default,) {final _that = this;
switch (_that) {
case _TableEnded():
return $default(_that.finalLeaderboard);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LeaderboardEntry> finalLeaderboard)?  $default,) {final _that = this;
switch (_that) {
case _TableEnded() when $default != null:
return $default(_that.finalLeaderboard);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TableEnded implements TableEnded {
  const _TableEnded({required  List<LeaderboardEntry> finalLeaderboard}): _finalLeaderboard = finalLeaderboard;
  factory _TableEnded.fromJson(Map<String, dynamic> json) => _$TableEndedFromJson(json);

 final  List<LeaderboardEntry> _finalLeaderboard;
@override List<LeaderboardEntry> get finalLeaderboard {
  if (_finalLeaderboard is EqualUnmodifiableListView) return _finalLeaderboard;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_finalLeaderboard);
}


/// Create a copy of TableEnded
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableEndedCopyWith<_TableEnded> get copyWith => __$TableEndedCopyWithImpl<_TableEnded>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableEndedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableEnded&&const DeepCollectionEquality().equals(other.finalLeaderboard, _finalLeaderboard));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_finalLeaderboard));
}

@override
String toString() {
    return 'TableEnded(finalLeaderboard: $finalLeaderboard)';
}


}

/// @nodoc
abstract mixin class _$TableEndedCopyWith<$Res> implements $TableEndedCopyWith<$Res> {
  factory _$TableEndedCopyWith(_TableEnded value, $Res Function(_TableEnded) _then) = __$TableEndedCopyWithImpl;
@override @useResult
$Res call({
 List<LeaderboardEntry> finalLeaderboard
});




}
/// @nodoc
class __$TableEndedCopyWithImpl<$Res>
    implements _$TableEndedCopyWith<$Res> {
  __$TableEndedCopyWithImpl(this._self, this._then);

  final _TableEnded _self;
  final $Res Function(_TableEnded) _then;

/// Create a copy of TableEnded
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? finalLeaderboard = null,}) {
  return _then(_TableEnded(
finalLeaderboard: null == finalLeaderboard ? _self._finalLeaderboard : finalLeaderboard // ignore: cast_nullable_to_non_nullable
as List<LeaderboardEntry>,
  ));
}


}


/// @nodoc
mixin _$Pong {

 int get serverTs;
/// Create a copy of Pong
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PongCopyWith<Pong> get copyWith => _$PongCopyWithImpl<Pong>(this as Pong, _$identity);

  /// Serializes this Pong to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Pong;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pong&&(identical(other.serverTs, _this.serverTs) || other.serverTs == _this.serverTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Pong;
  return Object.hash(runtimeType,_this.serverTs);
}

@override
String toString() {
  final _this = this as Pong;
  return 'Pong(serverTs: ${_this.serverTs})';
}


}

/// @nodoc
abstract mixin class $PongCopyWith<$Res>  {
  factory $PongCopyWith(Pong value, $Res Function(Pong) _then) = _$PongCopyWithImpl;
@useResult
$Res call({
 int serverTs
});




}
/// @nodoc
class _$PongCopyWithImpl<$Res>
    implements $PongCopyWith<$Res> {
  _$PongCopyWithImpl(this._self, this._then);

  final Pong _self;
  final $Res Function(Pong) _then;

/// Create a copy of Pong
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverTs = null,}) {
  return _then(Pong(
serverTs: null == serverTs ? _self.serverTs : serverTs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Pong].
extension PongPatterns on Pong {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pong value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pong() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pong value)  $default,){
final _that = this;
switch (_that) {
case _Pong():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pong value)?  $default,){
final _that = this;
switch (_that) {
case _Pong() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int serverTs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pong() when $default != null:
return $default(_that.serverTs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int serverTs)  $default,) {final _that = this;
switch (_that) {
case _Pong():
return $default(_that.serverTs);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int serverTs)?  $default,) {final _that = this;
switch (_that) {
case _Pong() when $default != null:
return $default(_that.serverTs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pong implements Pong {
  const _Pong({required this.serverTs});
  factory _Pong.fromJson(Map<String, dynamic> json) => _$PongFromJson(json);

@override final  int serverTs;

/// Create a copy of Pong
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PongCopyWith<_Pong> get copyWith => __$PongCopyWithImpl<_Pong>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PongToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pong&&(identical(other.serverTs, serverTs) || other.serverTs == serverTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,serverTs);
}

@override
String toString() {
    return 'Pong(serverTs: $serverTs)';
}


}

/// @nodoc
abstract mixin class _$PongCopyWith<$Res> implements $PongCopyWith<$Res> {
  factory _$PongCopyWith(_Pong value, $Res Function(_Pong) _then) = __$PongCopyWithImpl;
@override @useResult
$Res call({
 int serverTs
});




}
/// @nodoc
class __$PongCopyWithImpl<$Res>
    implements _$PongCopyWith<$Res> {
  __$PongCopyWithImpl(this._self, this._then);

  final _Pong _self;
  final $Res Function(_Pong) _then;

/// Create a copy of Pong
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverTs = null,}) {
  return _then(_Pong(
serverTs: null == serverTs ? _self.serverTs : serverTs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
