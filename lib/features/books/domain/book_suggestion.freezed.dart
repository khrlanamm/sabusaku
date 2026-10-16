// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookSuggestion {

 String get id; SuggestionKind get kind; String? get bookId;/// Proposed values, keyed like `books` fields (`title`, `authors`,
/// `pageCount`, `isbn13`…). For `edit` only the fields that differ.
 Map<String, Object?> get proposed; int get count; List<SuggestionSource> get from; SuggestionStatus get status; DateTime? get createdAt; DateTime? get updatedAt; BookActor? get reviewedBy; DateTime? get reviewedAt; String? get resultBookId;
/// Create a copy of BookSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookSuggestionCopyWith<BookSuggestion> get copyWith => _$BookSuggestionCopyWithImpl<BookSuggestion>(this as BookSuggestion, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BookSuggestion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookSuggestion&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&const DeepCollectionEquality().equals(other.proposed, _this.proposed)&&(identical(other.count, _this.count) || other.count == _this.count)&&const DeepCollectionEquality().equals(other.from, _this.from)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.reviewedBy, _this.reviewedBy) || other.reviewedBy == _this.reviewedBy)&&(identical(other.reviewedAt, _this.reviewedAt) || other.reviewedAt == _this.reviewedAt)&&(identical(other.resultBookId, _this.resultBookId) || other.resultBookId == _this.resultBookId));
}


@override
int get hashCode {
  final _this = this as BookSuggestion;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.bookId,const DeepCollectionEquality().hash(_this.proposed),_this.count,const DeepCollectionEquality().hash(_this.from),_this.status,_this.createdAt,_this.updatedAt,_this.reviewedBy,_this.reviewedAt,_this.resultBookId);
}

@override
String toString() {
  final _this = this as BookSuggestion;
  return 'BookSuggestion(id: ${_this.id}, kind: ${_this.kind}, bookId: ${_this.bookId}, proposed: ${_this.proposed}, count: ${_this.count}, from: ${_this.from}, status: ${_this.status}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, reviewedBy: ${_this.reviewedBy}, reviewedAt: ${_this.reviewedAt}, resultBookId: ${_this.resultBookId})';
}


}

/// @nodoc
abstract mixin class $BookSuggestionCopyWith<$Res>  {
  factory $BookSuggestionCopyWith(BookSuggestion value, $Res Function(BookSuggestion) _then) = _$BookSuggestionCopyWithImpl;
@useResult
$Res call({
 String id, SuggestionKind kind, String? bookId, Map<String, Object?> proposed, int count, List<SuggestionSource> from, SuggestionStatus status, DateTime? createdAt, DateTime? updatedAt, BookActor? reviewedBy, DateTime? reviewedAt, String? resultBookId
});


$BookActorCopyWith<$Res>? get reviewedBy;

}
/// @nodoc
class _$BookSuggestionCopyWithImpl<$Res>
    implements $BookSuggestionCopyWith<$Res> {
  _$BookSuggestionCopyWithImpl(this._self, this._then);

  final BookSuggestion _self;
  final $Res Function(BookSuggestion) _then;

/// Create a copy of BookSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? bookId = freezed,Object? proposed = null,Object? count = null,Object? from = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? reviewedBy = freezed,Object? reviewedAt = freezed,Object? resultBookId = freezed,}) {
  return _then(BookSuggestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SuggestionKind,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String?,proposed: null == proposed ? _self.proposed : proposed // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as List<SuggestionSource>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SuggestionStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as BookActor?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resultBookId: freezed == resultBookId ? _self.resultBookId : resultBookId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BookSuggestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get reviewedBy {
    if (_self.reviewedBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.reviewedBy!, (value) {
    return _then(_self.copyWith(reviewedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookSuggestion].
extension BookSuggestionPatterns on BookSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _BookSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _BookSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SuggestionKind kind,  String? bookId,  Map<String, Object?> proposed,  int count,  List<SuggestionSource> from,  SuggestionStatus status,  DateTime? createdAt,  DateTime? updatedAt,  BookActor? reviewedBy,  DateTime? reviewedAt,  String? resultBookId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookSuggestion() when $default != null:
return $default(_that.id,_that.kind,_that.bookId,_that.proposed,_that.count,_that.from,_that.status,_that.createdAt,_that.updatedAt,_that.reviewedBy,_that.reviewedAt,_that.resultBookId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SuggestionKind kind,  String? bookId,  Map<String, Object?> proposed,  int count,  List<SuggestionSource> from,  SuggestionStatus status,  DateTime? createdAt,  DateTime? updatedAt,  BookActor? reviewedBy,  DateTime? reviewedAt,  String? resultBookId)  $default,) {final _that = this;
switch (_that) {
case _BookSuggestion():
return $default(_that.id,_that.kind,_that.bookId,_that.proposed,_that.count,_that.from,_that.status,_that.createdAt,_that.updatedAt,_that.reviewedBy,_that.reviewedAt,_that.resultBookId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SuggestionKind kind,  String? bookId,  Map<String, Object?> proposed,  int count,  List<SuggestionSource> from,  SuggestionStatus status,  DateTime? createdAt,  DateTime? updatedAt,  BookActor? reviewedBy,  DateTime? reviewedAt,  String? resultBookId)?  $default,) {final _that = this;
switch (_that) {
case _BookSuggestion() when $default != null:
return $default(_that.id,_that.kind,_that.bookId,_that.proposed,_that.count,_that.from,_that.status,_that.createdAt,_that.updatedAt,_that.reviewedBy,_that.reviewedAt,_that.resultBookId);case _:
  return null;

}
}

}

/// @nodoc


class _BookSuggestion extends BookSuggestion {
  const _BookSuggestion({required this.id, required this.kind, this.bookId,  Map<String, Object?> proposed = const <String, Object?>{}, this.count = 1,  List<SuggestionSource> from = const <SuggestionSource>[], this.status = SuggestionStatus.pending, this.createdAt, this.updatedAt, this.reviewedBy, this.reviewedAt, this.resultBookId}): _proposed = proposed,_from = from,super._();
  

@override final  String id;
@override final  SuggestionKind kind;
@override final  String? bookId;
/// Proposed values, keyed like `books` fields (`title`, `authors`,
/// `pageCount`, `isbn13`…). For `edit` only the fields that differ.
 final  Map<String, Object?> _proposed;
/// Proposed values, keyed like `books` fields (`title`, `authors`,
/// `pageCount`, `isbn13`…). For `edit` only the fields that differ.
@override@JsonKey() Map<String, Object?> get proposed {
  if (_proposed is EqualUnmodifiableMapView) return _proposed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_proposed);
}

@override@JsonKey() final  int count;
 final  List<SuggestionSource> _from;
@override@JsonKey() List<SuggestionSource> get from {
  if (_from is EqualUnmodifiableListView) return _from;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_from);
}

@override@JsonKey() final  SuggestionStatus status;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  BookActor? reviewedBy;
@override final  DateTime? reviewedAt;
@override final  String? resultBookId;

/// Create a copy of BookSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookSuggestionCopyWith<_BookSuggestion> get copyWith => __$BookSuggestionCopyWithImpl<_BookSuggestion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookSuggestion&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&const DeepCollectionEquality().equals(other.proposed, _proposed)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.from, _from)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.resultBookId, resultBookId) || other.resultBookId == resultBookId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,bookId,const DeepCollectionEquality().hash(_proposed),count,const DeepCollectionEquality().hash(_from),status,createdAt,updatedAt,reviewedBy,reviewedAt,resultBookId);
}

@override
String toString() {
    return 'BookSuggestion(id: $id, kind: $kind, bookId: $bookId, proposed: $proposed, count: $count, from: $from, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt, resultBookId: $resultBookId)';
}


}

/// @nodoc
abstract mixin class _$BookSuggestionCopyWith<$Res> implements $BookSuggestionCopyWith<$Res> {
  factory _$BookSuggestionCopyWith(_BookSuggestion value, $Res Function(_BookSuggestion) _then) = __$BookSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String id, SuggestionKind kind, String? bookId, Map<String, Object?> proposed, int count, List<SuggestionSource> from, SuggestionStatus status, DateTime? createdAt, DateTime? updatedAt, BookActor? reviewedBy, DateTime? reviewedAt, String? resultBookId
});


@override $BookActorCopyWith<$Res>? get reviewedBy;

}
/// @nodoc
class __$BookSuggestionCopyWithImpl<$Res>
    implements _$BookSuggestionCopyWith<$Res> {
  __$BookSuggestionCopyWithImpl(this._self, this._then);

  final _BookSuggestion _self;
  final $Res Function(_BookSuggestion) _then;

/// Create a copy of BookSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? bookId = freezed,Object? proposed = null,Object? count = null,Object? from = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? reviewedBy = freezed,Object? reviewedAt = freezed,Object? resultBookId = freezed,}) {
  return _then(_BookSuggestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SuggestionKind,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String?,proposed: null == proposed ? _self._proposed : proposed // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self._from : from // ignore: cast_nullable_to_non_nullable
as List<SuggestionSource>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SuggestionStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as BookActor?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resultBookId: freezed == resultBookId ? _self.resultBookId : resultBookId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BookSuggestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get reviewedBy {
    if (_self.reviewedBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.reviewedBy!, (value) {
    return _then(_self.copyWith(reviewedBy: value));
  });
}
}

// dart format on
