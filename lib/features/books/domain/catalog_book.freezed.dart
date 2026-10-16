// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookActor {

 String? get uid; String get name; String? get schoolId; String? get schoolName;/// `import`, `guru` or `siswa`.
 String get kind;
/// Create a copy of BookActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookActorCopyWith<BookActor> get copyWith => _$BookActorCopyWithImpl<BookActor>(this as BookActor, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BookActor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookActor&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.schoolId, _this.schoolId) || other.schoolId == _this.schoolId)&&(identical(other.schoolName, _this.schoolName) || other.schoolName == _this.schoolName)&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}


@override
int get hashCode {
  final _this = this as BookActor;
  return Object.hash(runtimeType,_this.uid,_this.name,_this.schoolId,_this.schoolName,_this.kind);
}

@override
String toString() {
  final _this = this as BookActor;
  return 'BookActor(uid: ${_this.uid}, name: ${_this.name}, schoolId: ${_this.schoolId}, schoolName: ${_this.schoolName}, kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $BookActorCopyWith<$Res>  {
  factory $BookActorCopyWith(BookActor value, $Res Function(BookActor) _then) = _$BookActorCopyWithImpl;
@useResult
$Res call({
 String? uid, String name, String? schoolId, String? schoolName, String kind
});




}
/// @nodoc
class _$BookActorCopyWithImpl<$Res>
    implements $BookActorCopyWith<$Res> {
  _$BookActorCopyWithImpl(this._self, this._then);

  final BookActor _self;
  final $Res Function(BookActor) _then;

/// Create a copy of BookActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = freezed,Object? name = null,Object? schoolId = freezed,Object? schoolName = freezed,Object? kind = null,}) {
  return _then(BookActor(
uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,schoolId: freezed == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String?,schoolName: freezed == schoolName ? _self.schoolName : schoolName // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookActor].
extension BookActorPatterns on BookActor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookActor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookActor value)  $default,){
final _that = this;
switch (_that) {
case _BookActor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookActor value)?  $default,){
final _that = this;
switch (_that) {
case _BookActor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? uid,  String name,  String? schoolId,  String? schoolName,  String kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookActor() when $default != null:
return $default(_that.uid,_that.name,_that.schoolId,_that.schoolName,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? uid,  String name,  String? schoolId,  String? schoolName,  String kind)  $default,) {final _that = this;
switch (_that) {
case _BookActor():
return $default(_that.uid,_that.name,_that.schoolId,_that.schoolName,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? uid,  String name,  String? schoolId,  String? schoolName,  String kind)?  $default,) {final _that = this;
switch (_that) {
case _BookActor() when $default != null:
return $default(_that.uid,_that.name,_that.schoolId,_that.schoolName,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _BookActor implements BookActor {
  const _BookActor({this.uid, this.name = '', this.schoolId, this.schoolName, this.kind = 'guru'});
  

@override final  String? uid;
@override@JsonKey() final  String name;
@override final  String? schoolId;
@override final  String? schoolName;
/// `import`, `guru` or `siswa`.
@override@JsonKey() final  String kind;

/// Create a copy of BookActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookActorCopyWith<_BookActor> get copyWith => __$BookActorCopyWithImpl<_BookActor>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookActor&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.schoolId, schoolId) || other.schoolId == schoolId)&&(identical(other.schoolName, schoolName) || other.schoolName == schoolName)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,name,schoolId,schoolName,kind);
}

@override
String toString() {
    return 'BookActor(uid: $uid, name: $name, schoolId: $schoolId, schoolName: $schoolName, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$BookActorCopyWith<$Res> implements $BookActorCopyWith<$Res> {
  factory _$BookActorCopyWith(_BookActor value, $Res Function(_BookActor) _then) = __$BookActorCopyWithImpl;
@override @useResult
$Res call({
 String? uid, String name, String? schoolId, String? schoolName, String kind
});




}
/// @nodoc
class __$BookActorCopyWithImpl<$Res>
    implements _$BookActorCopyWith<$Res> {
  __$BookActorCopyWithImpl(this._self, this._then);

  final _BookActor _self;
  final $Res Function(_BookActor) _then;

/// Create a copy of BookActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = freezed,Object? name = null,Object? schoolId = freezed,Object? schoolName = freezed,Object? kind = null,}) {
  return _then(_BookActor(
uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,schoolId: freezed == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String?,schoolName: freezed == schoolName ? _self.schoolName : schoolName // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CatalogBook {

 String get id; String get title; String? get subtitle; List<String> get authors; String? get publisher; int? get publishedYear; String? get isbn13; String? get isbn10; int get pageCount; List<String> get categories; String? get description; String? get coverUrl;/// `active` or `deleted` (soft delete; any teacher can restore).
 bool get active; DateTime? get deletedAt; BookActor? get deletedBy; String? get deleteReason; String? get duplicateOf; int get readerCount; BookActor? get createdBy; DateTime? get updatedAt; BookActor? get updatedBy; int get version;
/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogBookCopyWith<CatalogBook> get copyWith => _$CatalogBookCopyWithImpl<CatalogBook>(this as CatalogBook, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatalogBook;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogBook&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&const DeepCollectionEquality().equals(other.authors, _this.authors)&&(identical(other.publisher, _this.publisher) || other.publisher == _this.publisher)&&(identical(other.publishedYear, _this.publishedYear) || other.publishedYear == _this.publishedYear)&&(identical(other.isbn13, _this.isbn13) || other.isbn13 == _this.isbn13)&&(identical(other.isbn10, _this.isbn10) || other.isbn10 == _this.isbn10)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.active, _this.active) || other.active == _this.active)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.deletedBy, _this.deletedBy) || other.deletedBy == _this.deletedBy)&&(identical(other.deleteReason, _this.deleteReason) || other.deleteReason == _this.deleteReason)&&(identical(other.duplicateOf, _this.duplicateOf) || other.duplicateOf == _this.duplicateOf)&&(identical(other.readerCount, _this.readerCount) || other.readerCount == _this.readerCount)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.version, _this.version) || other.version == _this.version));
}


@override
int get hashCode {
  final _this = this as CatalogBook;
  return Object.hashAll([runtimeType,_this.id,_this.title,_this.subtitle,const DeepCollectionEquality().hash(_this.authors),_this.publisher,_this.publishedYear,_this.isbn13,_this.isbn10,_this.pageCount,const DeepCollectionEquality().hash(_this.categories),_this.description,_this.coverUrl,_this.active,_this.deletedAt,_this.deletedBy,_this.deleteReason,_this.duplicateOf,_this.readerCount,_this.createdBy,_this.updatedAt,_this.updatedBy,_this.version]);
}

@override
String toString() {
  final _this = this as CatalogBook;
  return 'CatalogBook(id: ${_this.id}, title: ${_this.title}, subtitle: ${_this.subtitle}, authors: ${_this.authors}, publisher: ${_this.publisher}, publishedYear: ${_this.publishedYear}, isbn13: ${_this.isbn13}, isbn10: ${_this.isbn10}, pageCount: ${_this.pageCount}, categories: ${_this.categories}, description: ${_this.description}, coverUrl: ${_this.coverUrl}, active: ${_this.active}, deletedAt: ${_this.deletedAt}, deletedBy: ${_this.deletedBy}, deleteReason: ${_this.deleteReason}, duplicateOf: ${_this.duplicateOf}, readerCount: ${_this.readerCount}, createdBy: ${_this.createdBy}, updatedAt: ${_this.updatedAt}, updatedBy: ${_this.updatedBy}, version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $CatalogBookCopyWith<$Res>  {
  factory $CatalogBookCopyWith(CatalogBook value, $Res Function(CatalogBook) _then) = _$CatalogBookCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? subtitle, List<String> authors, String? publisher, int? publishedYear, String? isbn13, String? isbn10, int pageCount, List<String> categories, String? description, String? coverUrl, bool active, DateTime? deletedAt, BookActor? deletedBy, String? deleteReason, String? duplicateOf, int readerCount, BookActor? createdBy, DateTime? updatedAt, BookActor? updatedBy, int version
});


$BookActorCopyWith<$Res>? get deletedBy;$BookActorCopyWith<$Res>? get createdBy;$BookActorCopyWith<$Res>? get updatedBy;

}
/// @nodoc
class _$CatalogBookCopyWithImpl<$Res>
    implements $CatalogBookCopyWith<$Res> {
  _$CatalogBookCopyWithImpl(this._self, this._then);

  final CatalogBook _self;
  final $Res Function(CatalogBook) _then;

/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? subtitle = freezed,Object? authors = null,Object? publisher = freezed,Object? publishedYear = freezed,Object? isbn13 = freezed,Object? isbn10 = freezed,Object? pageCount = null,Object? categories = null,Object? description = freezed,Object? coverUrl = freezed,Object? active = null,Object? deletedAt = freezed,Object? deletedBy = freezed,Object? deleteReason = freezed,Object? duplicateOf = freezed,Object? readerCount = null,Object? createdBy = freezed,Object? updatedAt = freezed,Object? updatedBy = freezed,Object? version = null,}) {
  return _then(CatalogBook(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as List<String>,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,publishedYear: freezed == publishedYear ? _self.publishedYear : publishedYear // ignore: cast_nullable_to_non_nullable
as int?,isbn13: freezed == isbn13 ? _self.isbn13 : isbn13 // ignore: cast_nullable_to_non_nullable
as String?,isbn10: freezed == isbn10 ? _self.isbn10 : isbn10 // ignore: cast_nullable_to_non_nullable
as String?,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedBy: freezed == deletedBy ? _self.deletedBy : deletedBy // ignore: cast_nullable_to_non_nullable
as BookActor?,deleteReason: freezed == deleteReason ? _self.deleteReason : deleteReason // ignore: cast_nullable_to_non_nullable
as String?,duplicateOf: freezed == duplicateOf ? _self.duplicateOf : duplicateOf // ignore: cast_nullable_to_non_nullable
as String?,readerCount: null == readerCount ? _self.readerCount : readerCount // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as BookActor?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as BookActor?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get deletedBy {
    if (_self.deletedBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.deletedBy!, (value) {
    return _then(_self.copyWith(deletedBy: value));
  });
}/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get createdBy {
    if (_self.createdBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.createdBy!, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get updatedBy {
    if (_self.updatedBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.updatedBy!, (value) {
    return _then(_self.copyWith(updatedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatalogBook].
extension CatalogBookPatterns on CatalogBook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogBook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogBook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogBook value)  $default,){
final _that = this;
switch (_that) {
case _CatalogBook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogBook value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogBook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? subtitle,  List<String> authors,  String? publisher,  int? publishedYear,  String? isbn13,  String? isbn10,  int pageCount,  List<String> categories,  String? description,  String? coverUrl,  bool active,  DateTime? deletedAt,  BookActor? deletedBy,  String? deleteReason,  String? duplicateOf,  int readerCount,  BookActor? createdBy,  DateTime? updatedAt,  BookActor? updatedBy,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogBook() when $default != null:
return $default(_that.id,_that.title,_that.subtitle,_that.authors,_that.publisher,_that.publishedYear,_that.isbn13,_that.isbn10,_that.pageCount,_that.categories,_that.description,_that.coverUrl,_that.active,_that.deletedAt,_that.deletedBy,_that.deleteReason,_that.duplicateOf,_that.readerCount,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? subtitle,  List<String> authors,  String? publisher,  int? publishedYear,  String? isbn13,  String? isbn10,  int pageCount,  List<String> categories,  String? description,  String? coverUrl,  bool active,  DateTime? deletedAt,  BookActor? deletedBy,  String? deleteReason,  String? duplicateOf,  int readerCount,  BookActor? createdBy,  DateTime? updatedAt,  BookActor? updatedBy,  int version)  $default,) {final _that = this;
switch (_that) {
case _CatalogBook():
return $default(_that.id,_that.title,_that.subtitle,_that.authors,_that.publisher,_that.publishedYear,_that.isbn13,_that.isbn10,_that.pageCount,_that.categories,_that.description,_that.coverUrl,_that.active,_that.deletedAt,_that.deletedBy,_that.deleteReason,_that.duplicateOf,_that.readerCount,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? subtitle,  List<String> authors,  String? publisher,  int? publishedYear,  String? isbn13,  String? isbn10,  int pageCount,  List<String> categories,  String? description,  String? coverUrl,  bool active,  DateTime? deletedAt,  BookActor? deletedBy,  String? deleteReason,  String? duplicateOf,  int readerCount,  BookActor? createdBy,  DateTime? updatedAt,  BookActor? updatedBy,  int version)?  $default,) {final _that = this;
switch (_that) {
case _CatalogBook() when $default != null:
return $default(_that.id,_that.title,_that.subtitle,_that.authors,_that.publisher,_that.publishedYear,_that.isbn13,_that.isbn10,_that.pageCount,_that.categories,_that.description,_that.coverUrl,_that.active,_that.deletedAt,_that.deletedBy,_that.deleteReason,_that.duplicateOf,_that.readerCount,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogBook extends CatalogBook {
  const _CatalogBook({required this.id, required this.title, this.subtitle,  List<String> authors = const <String>[], this.publisher, this.publishedYear, this.isbn13, this.isbn10, this.pageCount = 0,  List<String> categories = const <String>[], this.description, this.coverUrl, this.active = true, this.deletedAt, this.deletedBy, this.deleteReason, this.duplicateOf, this.readerCount = 0, this.createdBy, this.updatedAt, this.updatedBy, this.version = 1}): _authors = authors,_categories = categories,super._();
  

@override final  String id;
@override final  String title;
@override final  String? subtitle;
 final  List<String> _authors;
@override@JsonKey() List<String> get authors {
  if (_authors is EqualUnmodifiableListView) return _authors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authors);
}

@override final  String? publisher;
@override final  int? publishedYear;
@override final  String? isbn13;
@override final  String? isbn10;
@override@JsonKey() final  int pageCount;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override final  String? description;
@override final  String? coverUrl;
/// `active` or `deleted` (soft delete; any teacher can restore).
@override@JsonKey() final  bool active;
@override final  DateTime? deletedAt;
@override final  BookActor? deletedBy;
@override final  String? deleteReason;
@override final  String? duplicateOf;
@override@JsonKey() final  int readerCount;
@override final  BookActor? createdBy;
@override final  DateTime? updatedAt;
@override final  BookActor? updatedBy;
@override@JsonKey() final  int version;

/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogBookCopyWith<_CatalogBook> get copyWith => __$CatalogBookCopyWithImpl<_CatalogBook>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogBook&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other.authors, _authors)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.publishedYear, publishedYear) || other.publishedYear == publishedYear)&&(identical(other.isbn13, isbn13) || other.isbn13 == isbn13)&&(identical(other.isbn10, isbn10) || other.isbn10 == isbn10)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&const DeepCollectionEquality().equals(other.categories, _categories)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.active, active) || other.active == active)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.deletedBy, deletedBy) || other.deletedBy == deletedBy)&&(identical(other.deleteReason, deleteReason) || other.deleteReason == deleteReason)&&(identical(other.duplicateOf, duplicateOf) || other.duplicateOf == duplicateOf)&&(identical(other.readerCount, readerCount) || other.readerCount == readerCount)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,title,subtitle,const DeepCollectionEquality().hash(_authors),publisher,publishedYear,isbn13,isbn10,pageCount,const DeepCollectionEquality().hash(_categories),description,coverUrl,active,deletedAt,deletedBy,deleteReason,duplicateOf,readerCount,createdBy,updatedAt,updatedBy,version]);
}

@override
String toString() {
    return 'CatalogBook(id: $id, title: $title, subtitle: $subtitle, authors: $authors, publisher: $publisher, publishedYear: $publishedYear, isbn13: $isbn13, isbn10: $isbn10, pageCount: $pageCount, categories: $categories, description: $description, coverUrl: $coverUrl, active: $active, deletedAt: $deletedAt, deletedBy: $deletedBy, deleteReason: $deleteReason, duplicateOf: $duplicateOf, readerCount: $readerCount, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class _$CatalogBookCopyWith<$Res> implements $CatalogBookCopyWith<$Res> {
  factory _$CatalogBookCopyWith(_CatalogBook value, $Res Function(_CatalogBook) _then) = __$CatalogBookCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? subtitle, List<String> authors, String? publisher, int? publishedYear, String? isbn13, String? isbn10, int pageCount, List<String> categories, String? description, String? coverUrl, bool active, DateTime? deletedAt, BookActor? deletedBy, String? deleteReason, String? duplicateOf, int readerCount, BookActor? createdBy, DateTime? updatedAt, BookActor? updatedBy, int version
});


@override $BookActorCopyWith<$Res>? get deletedBy;@override $BookActorCopyWith<$Res>? get createdBy;@override $BookActorCopyWith<$Res>? get updatedBy;

}
/// @nodoc
class __$CatalogBookCopyWithImpl<$Res>
    implements _$CatalogBookCopyWith<$Res> {
  __$CatalogBookCopyWithImpl(this._self, this._then);

  final _CatalogBook _self;
  final $Res Function(_CatalogBook) _then;

/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? subtitle = freezed,Object? authors = null,Object? publisher = freezed,Object? publishedYear = freezed,Object? isbn13 = freezed,Object? isbn10 = freezed,Object? pageCount = null,Object? categories = null,Object? description = freezed,Object? coverUrl = freezed,Object? active = null,Object? deletedAt = freezed,Object? deletedBy = freezed,Object? deleteReason = freezed,Object? duplicateOf = freezed,Object? readerCount = null,Object? createdBy = freezed,Object? updatedAt = freezed,Object? updatedBy = freezed,Object? version = null,}) {
  return _then(_CatalogBook(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,authors: null == authors ? _self._authors : authors // ignore: cast_nullable_to_non_nullable
as List<String>,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,publishedYear: freezed == publishedYear ? _self.publishedYear : publishedYear // ignore: cast_nullable_to_non_nullable
as int?,isbn13: freezed == isbn13 ? _self.isbn13 : isbn13 // ignore: cast_nullable_to_non_nullable
as String?,isbn10: freezed == isbn10 ? _self.isbn10 : isbn10 // ignore: cast_nullable_to_non_nullable
as String?,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedBy: freezed == deletedBy ? _self.deletedBy : deletedBy // ignore: cast_nullable_to_non_nullable
as BookActor?,deleteReason: freezed == deleteReason ? _self.deleteReason : deleteReason // ignore: cast_nullable_to_non_nullable
as String?,duplicateOf: freezed == duplicateOf ? _self.duplicateOf : duplicateOf // ignore: cast_nullable_to_non_nullable
as String?,readerCount: null == readerCount ? _self.readerCount : readerCount // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as BookActor?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as BookActor?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get deletedBy {
    if (_self.deletedBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.deletedBy!, (value) {
    return _then(_self.copyWith(deletedBy: value));
  });
}/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get createdBy {
    if (_self.createdBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.createdBy!, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}/// Create a copy of CatalogBook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookActorCopyWith<$Res>? get updatedBy {
    if (_self.updatedBy == null) {
    return null;
  }

  return $BookActorCopyWith<$Res>(_self.updatedBy!, (value) {
    return _then(_self.copyWith(updatedBy: value));
  });
}
}

/// @nodoc
mixin _$CatalogEntry {

 String get id; String get title; String get authors; int get pageCount; int? get year; String? get coverUrl; List<String> get categories; int get readerCount;
/// Create a copy of CatalogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogEntryCopyWith<CatalogEntry> get copyWith => _$CatalogEntryCopyWithImpl<CatalogEntry>(this as CatalogEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatalogEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.authors, _this.authors) || other.authors == _this.authors)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&(identical(other.readerCount, _this.readerCount) || other.readerCount == _this.readerCount));
}


@override
int get hashCode {
  final _this = this as CatalogEntry;
  return Object.hash(runtimeType,_this.id,_this.title,_this.authors,_this.pageCount,_this.year,_this.coverUrl,const DeepCollectionEquality().hash(_this.categories),_this.readerCount);
}

@override
String toString() {
  final _this = this as CatalogEntry;
  return 'CatalogEntry(id: ${_this.id}, title: ${_this.title}, authors: ${_this.authors}, pageCount: ${_this.pageCount}, year: ${_this.year}, coverUrl: ${_this.coverUrl}, categories: ${_this.categories}, readerCount: ${_this.readerCount})';
}


}

/// @nodoc
abstract mixin class $CatalogEntryCopyWith<$Res>  {
  factory $CatalogEntryCopyWith(CatalogEntry value, $Res Function(CatalogEntry) _then) = _$CatalogEntryCopyWithImpl;
@useResult
$Res call({
 String id, String title, String authors, int pageCount, int? year, String? coverUrl, List<String> categories, int readerCount
});




}
/// @nodoc
class _$CatalogEntryCopyWithImpl<$Res>
    implements $CatalogEntryCopyWith<$Res> {
  _$CatalogEntryCopyWithImpl(this._self, this._then);

  final CatalogEntry _self;
  final $Res Function(CatalogEntry) _then;

/// Create a copy of CatalogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? authors = null,Object? pageCount = null,Object? year = freezed,Object? coverUrl = freezed,Object? categories = null,Object? readerCount = null,}) {
  return _then(CatalogEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,readerCount: null == readerCount ? _self.readerCount : readerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogEntry].
extension CatalogEntryPatterns on CatalogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogEntry value)  $default,){
final _that = this;
switch (_that) {
case _CatalogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String authors,  int pageCount,  int? year,  String? coverUrl,  List<String> categories,  int readerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogEntry() when $default != null:
return $default(_that.id,_that.title,_that.authors,_that.pageCount,_that.year,_that.coverUrl,_that.categories,_that.readerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String authors,  int pageCount,  int? year,  String? coverUrl,  List<String> categories,  int readerCount)  $default,) {final _that = this;
switch (_that) {
case _CatalogEntry():
return $default(_that.id,_that.title,_that.authors,_that.pageCount,_that.year,_that.coverUrl,_that.categories,_that.readerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String authors,  int pageCount,  int? year,  String? coverUrl,  List<String> categories,  int readerCount)?  $default,) {final _that = this;
switch (_that) {
case _CatalogEntry() when $default != null:
return $default(_that.id,_that.title,_that.authors,_that.pageCount,_that.year,_that.coverUrl,_that.categories,_that.readerCount);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogEntry extends CatalogEntry {
  const _CatalogEntry({required this.id, required this.title, this.authors = '', this.pageCount = 0, this.year, this.coverUrl,  List<String> categories = const <String>[], this.readerCount = 0}): _categories = categories,super._();
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  String authors;
@override@JsonKey() final  int pageCount;
@override final  int? year;
@override final  String? coverUrl;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey() final  int readerCount;

/// Create a copy of CatalogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogEntryCopyWith<_CatalogEntry> get copyWith => __$CatalogEntryCopyWithImpl<_CatalogEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.authors, authors) || other.authors == authors)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.year, year) || other.year == year)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&const DeepCollectionEquality().equals(other.categories, _categories)&&(identical(other.readerCount, readerCount) || other.readerCount == readerCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,authors,pageCount,year,coverUrl,const DeepCollectionEquality().hash(_categories),readerCount);
}

@override
String toString() {
    return 'CatalogEntry(id: $id, title: $title, authors: $authors, pageCount: $pageCount, year: $year, coverUrl: $coverUrl, categories: $categories, readerCount: $readerCount)';
}


}

/// @nodoc
abstract mixin class _$CatalogEntryCopyWith<$Res> implements $CatalogEntryCopyWith<$Res> {
  factory _$CatalogEntryCopyWith(_CatalogEntry value, $Res Function(_CatalogEntry) _then) = __$CatalogEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String authors, int pageCount, int? year, String? coverUrl, List<String> categories, int readerCount
});




}
/// @nodoc
class __$CatalogEntryCopyWithImpl<$Res>
    implements _$CatalogEntryCopyWith<$Res> {
  __$CatalogEntryCopyWithImpl(this._self, this._then);

  final _CatalogEntry _self;
  final $Res Function(_CatalogEntry) _then;

/// Create a copy of CatalogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? authors = null,Object? pageCount = null,Object? year = freezed,Object? coverUrl = freezed,Object? categories = null,Object? readerCount = null,}) {
  return _then(_CatalogEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,readerCount: null == readerCount ? _self.readerCount : readerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
