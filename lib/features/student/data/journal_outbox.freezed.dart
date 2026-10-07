// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_outbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboxEntry {

 String get programId; String get bookTitle; String get date; OutboxKind get kind; OutboxStatus get status; String? get reason;/// What was being saved; null for a delete.
 JournalDraft? get draft;
/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxEntryCopyWith<OutboxEntry> get copyWith => _$OutboxEntryCopyWithImpl<OutboxEntry>(this as OutboxEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutboxEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxEntry&&(identical(other.programId, _this.programId) || other.programId == _this.programId)&&(identical(other.bookTitle, _this.bookTitle) || other.bookTitle == _this.bookTitle)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.draft, _this.draft) || other.draft == _this.draft));
}


@override
int get hashCode {
  final _this = this as OutboxEntry;
  return Object.hash(runtimeType,_this.programId,_this.bookTitle,_this.date,_this.kind,_this.status,_this.reason,_this.draft);
}

@override
String toString() {
  final _this = this as OutboxEntry;
  return 'OutboxEntry(programId: ${_this.programId}, bookTitle: ${_this.bookTitle}, date: ${_this.date}, kind: ${_this.kind}, status: ${_this.status}, reason: ${_this.reason}, draft: ${_this.draft})';
}


}

/// @nodoc
abstract mixin class $OutboxEntryCopyWith<$Res>  {
  factory $OutboxEntryCopyWith(OutboxEntry value, $Res Function(OutboxEntry) _then) = _$OutboxEntryCopyWithImpl;
@useResult
$Res call({
 String programId, String bookTitle, String date, OutboxKind kind, OutboxStatus status, String? reason, JournalDraft? draft
});


$JournalDraftCopyWith<$Res>? get draft;

}
/// @nodoc
class _$OutboxEntryCopyWithImpl<$Res>
    implements $OutboxEntryCopyWith<$Res> {
  _$OutboxEntryCopyWithImpl(this._self, this._then);

  final OutboxEntry _self;
  final $Res Function(OutboxEntry) _then;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programId = null,Object? bookTitle = null,Object? date = null,Object? kind = null,Object? status = null,Object? reason = freezed,Object? draft = freezed,}) {
  return _then(OutboxEntry(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,bookTitle: null == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OutboxKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboxStatus,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as JournalDraft?,
  ));
}
/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalDraftCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $JournalDraftCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [OutboxEntry].
extension OutboxEntryPatterns on OutboxEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxEntry value)  $default,){
final _that = this;
switch (_that) {
case _OutboxEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String programId,  String bookTitle,  String date,  OutboxKind kind,  OutboxStatus status,  String? reason,  JournalDraft? draft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
return $default(_that.programId,_that.bookTitle,_that.date,_that.kind,_that.status,_that.reason,_that.draft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String programId,  String bookTitle,  String date,  OutboxKind kind,  OutboxStatus status,  String? reason,  JournalDraft? draft)  $default,) {final _that = this;
switch (_that) {
case _OutboxEntry():
return $default(_that.programId,_that.bookTitle,_that.date,_that.kind,_that.status,_that.reason,_that.draft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String programId,  String bookTitle,  String date,  OutboxKind kind,  OutboxStatus status,  String? reason,  JournalDraft? draft)?  $default,) {final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
return $default(_that.programId,_that.bookTitle,_that.date,_that.kind,_that.status,_that.reason,_that.draft);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxEntry extends OutboxEntry {
  const _OutboxEntry({required this.programId, required this.bookTitle, required this.date, required this.kind, this.status = OutboxStatus.pending, this.reason, this.draft}): super._();
  

@override final  String programId;
@override final  String bookTitle;
@override final  String date;
@override final  OutboxKind kind;
@override@JsonKey() final  OutboxStatus status;
@override final  String? reason;
/// What was being saved; null for a delete.
@override final  JournalDraft? draft;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxEntryCopyWith<_OutboxEntry> get copyWith => __$OutboxEntryCopyWithImpl<_OutboxEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxEntry&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.date, date) || other.date == date)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode {
    return Object.hash(runtimeType,programId,bookTitle,date,kind,status,reason,draft);
}

@override
String toString() {
    return 'OutboxEntry(programId: $programId, bookTitle: $bookTitle, date: $date, kind: $kind, status: $status, reason: $reason, draft: $draft)';
}


}

/// @nodoc
abstract mixin class _$OutboxEntryCopyWith<$Res> implements $OutboxEntryCopyWith<$Res> {
  factory _$OutboxEntryCopyWith(_OutboxEntry value, $Res Function(_OutboxEntry) _then) = __$OutboxEntryCopyWithImpl;
@override @useResult
$Res call({
 String programId, String bookTitle, String date, OutboxKind kind, OutboxStatus status, String? reason, JournalDraft? draft
});


@override $JournalDraftCopyWith<$Res>? get draft;

}
/// @nodoc
class __$OutboxEntryCopyWithImpl<$Res>
    implements _$OutboxEntryCopyWith<$Res> {
  __$OutboxEntryCopyWithImpl(this._self, this._then);

  final _OutboxEntry _self;
  final $Res Function(_OutboxEntry) _then;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programId = null,Object? bookTitle = null,Object? date = null,Object? kind = null,Object? status = null,Object? reason = freezed,Object? draft = freezed,}) {
  return _then(_OutboxEntry(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,bookTitle: null == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OutboxKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboxStatus,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as JournalDraft?,
  ));
}

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalDraftCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $JournalDraftCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

// dart format on
