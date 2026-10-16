// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookHistoryEntry {

 String get id; BookHistoryType get type; Map<String, FieldChange> get changes; BookActor get by; DateTime? get at; String? get suggestionId; String? get note;
/// Create a copy of BookHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookHistoryEntryCopyWith<BookHistoryEntry> get copyWith => _$BookHistoryEntryCopyWithImpl<BookHistoryEntry>(this as BookHistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BookHistoryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookHistoryEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.changes, _this.changes)&&(identical(other.by, _this.by) || other.by == _this.by)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.suggestionId, _this.suggestionId) || other.suggestionId == _this.suggestionId)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as BookHistoryEntry;
  return Object.hash(runtimeType,_this.id,_this.type,const DeepCollectionEquality().hash(_this.changes),_this.by,_this.at,_this.suggestionId,_this.note);
}

@override
String toString() {
  final _this = this as BookHistoryEntry;
  return 'BookHistoryEntry(id: ${_this.id}, type: ${_this.type}, changes: ${_this.changes}, by: ${_this.by}, at: ${_this.at}, suggestionId: ${_this.suggestionId}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $BookHistoryEntryCopyWith<$Res>  {
  factory $BookHistoryEntryCopyWith(BookHistoryEntry value, $Res Function(BookHistoryEntry) _then) = _$BookHistoryEntryCopyWithImpl;
@useResult
$Res call({
 String id, BookHistoryType type, Map<String, FieldChange> changes, BookActor by, DateTime? at, String? suggestionId, String? note
});


$BookActorCopyWith<$Res> get by;

}
/// @nodoc
class _$BookHistoryEntryCopyWithImpl<$Res>
    implements $BookHistoryEntryCopyWith<$Res> {
  _$BookHistoryEntryCopyWithImpl(this._self, this._then);

  final BookHistoryEntry _self;
  final $Res Function(BookHistoryEntry) _then;

/// Create a copy of BookHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? changes = null,Object? by = null,Object? at = freezed,Object? suggestionId = freezed,Object? note = freezed,}) {
  return _then(BookHistoryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BookHistoryType,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as Map<String, FieldChange>,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as BookActor,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,suggestionId: freezed == suggestionId ? _self.suggestionId : suggestionId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BookHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res> get by {
  
  return $BookActorCopyWith<$Res>(_self.by, (value) {
    return _then(_self.copyWith(by: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookHistoryEntry].
extension BookHistoryEntryPatterns on BookHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _BookHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BookHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  BookHistoryType type,  Map<String, FieldChange> changes,  BookActor by,  DateTime? at,  String? suggestionId,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookHistoryEntry() when $default != null:
return $default(_that.id,_that.type,_that.changes,_that.by,_that.at,_that.suggestionId,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  BookHistoryType type,  Map<String, FieldChange> changes,  BookActor by,  DateTime? at,  String? suggestionId,  String? note)  $default,) {final _that = this;
switch (_that) {
case _BookHistoryEntry():
return $default(_that.id,_that.type,_that.changes,_that.by,_that.at,_that.suggestionId,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  BookHistoryType type,  Map<String, FieldChange> changes,  BookActor by,  DateTime? at,  String? suggestionId,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _BookHistoryEntry() when $default != null:
return $default(_that.id,_that.type,_that.changes,_that.by,_that.at,_that.suggestionId,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _BookHistoryEntry implements BookHistoryEntry {
  const _BookHistoryEntry({required this.id, required this.type,  Map<String, FieldChange> changes = const <String, FieldChange>{}, required this.by, this.at, this.suggestionId, this.note}): _changes = changes;
  

@override final  String id;
@override final  BookHistoryType type;
 final  Map<String, FieldChange> _changes;
@override@JsonKey() Map<String, FieldChange> get changes {
  if (_changes is EqualUnmodifiableMapView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_changes);
}

@override final  BookActor by;
@override final  DateTime? at;
@override final  String? suggestionId;
@override final  String? note;

/// Create a copy of BookHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookHistoryEntryCopyWith<_BookHistoryEntry> get copyWith => __$BookHistoryEntryCopyWithImpl<_BookHistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookHistoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.changes, _changes)&&(identical(other.by, by) || other.by == by)&&(identical(other.at, at) || other.at == at)&&(identical(other.suggestionId, suggestionId) || other.suggestionId == suggestionId)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(_changes),by,at,suggestionId,note);
}

@override
String toString() {
    return 'BookHistoryEntry(id: $id, type: $type, changes: $changes, by: $by, at: $at, suggestionId: $suggestionId, note: $note)';
}


}

/// @nodoc
abstract mixin class _$BookHistoryEntryCopyWith<$Res> implements $BookHistoryEntryCopyWith<$Res> {
  factory _$BookHistoryEntryCopyWith(_BookHistoryEntry value, $Res Function(_BookHistoryEntry) _then) = __$BookHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, BookHistoryType type, Map<String, FieldChange> changes, BookActor by, DateTime? at, String? suggestionId, String? note
});


@override $BookActorCopyWith<$Res> get by;

}
/// @nodoc
class __$BookHistoryEntryCopyWithImpl<$Res>
    implements _$BookHistoryEntryCopyWith<$Res> {
  __$BookHistoryEntryCopyWithImpl(this._self, this._then);

  final _BookHistoryEntry _self;
  final $Res Function(_BookHistoryEntry) _then;

/// Create a copy of BookHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? changes = null,Object? by = null,Object? at = freezed,Object? suggestionId = freezed,Object? note = freezed,}) {
  return _then(_BookHistoryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BookHistoryType,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as Map<String, FieldChange>,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as BookActor,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,suggestionId: freezed == suggestionId ? _self.suggestionId : suggestionId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BookHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res> get by {
  
  return $BookActorCopyWith<$Res>(_self.by, (value) {
    return _then(_self.copyWith(by: value));
  });
}
}

// dart format on
