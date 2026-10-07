// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Book {

 String get title; String get author; int get totalPages; String? get isbn;
/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookCopyWith<Book> get copyWith => _$BookCopyWithImpl<Book>(this as Book, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Book;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Book&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.totalPages, _this.totalPages) || other.totalPages == _this.totalPages)&&(identical(other.isbn, _this.isbn) || other.isbn == _this.isbn));
}


@override
int get hashCode {
  final _this = this as Book;
  return Object.hash(runtimeType,_this.title,_this.author,_this.totalPages,_this.isbn);
}

@override
String toString() {
  final _this = this as Book;
  return 'Book(title: ${_this.title}, author: ${_this.author}, totalPages: ${_this.totalPages}, isbn: ${_this.isbn})';
}


}

/// @nodoc
abstract mixin class $BookCopyWith<$Res>  {
  factory $BookCopyWith(Book value, $Res Function(Book) _then) = _$BookCopyWithImpl;
@useResult
$Res call({
 String title, String author, int totalPages, String? isbn
});




}
/// @nodoc
class _$BookCopyWithImpl<$Res>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._self, this._then);

  final Book _self;
  final $Res Function(Book) _then;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? author = null,Object? totalPages = null,Object? isbn = freezed,}) {
  return _then(Book(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,isbn: freezed == isbn ? _self.isbn : isbn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Book].
extension BookPatterns on Book {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Book value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Book() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Book value)  $default,){
final _that = this;
switch (_that) {
case _Book():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Book value)?  $default,){
final _that = this;
switch (_that) {
case _Book() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String author,  int totalPages,  String? isbn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Book() when $default != null:
return $default(_that.title,_that.author,_that.totalPages,_that.isbn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String author,  int totalPages,  String? isbn)  $default,) {final _that = this;
switch (_that) {
case _Book():
return $default(_that.title,_that.author,_that.totalPages,_that.isbn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String author,  int totalPages,  String? isbn)?  $default,) {final _that = this;
switch (_that) {
case _Book() when $default != null:
return $default(_that.title,_that.author,_that.totalPages,_that.isbn);case _:
  return null;

}
}

}

/// @nodoc


class _Book implements Book {
  const _Book({required this.title, required this.author, required this.totalPages, this.isbn});
  

@override final  String title;
@override final  String author;
@override final  int totalPages;
@override final  String? isbn;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookCopyWith<_Book> get copyWith => __$BookCopyWithImpl<_Book>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Book&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.isbn, isbn) || other.isbn == isbn));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,author,totalPages,isbn);
}

@override
String toString() {
    return 'Book(title: $title, author: $author, totalPages: $totalPages, isbn: $isbn)';
}


}

/// @nodoc
abstract mixin class _$BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$BookCopyWith(_Book value, $Res Function(_Book) _then) = __$BookCopyWithImpl;
@override @useResult
$Res call({
 String title, String author, int totalPages, String? isbn
});




}
/// @nodoc
class __$BookCopyWithImpl<$Res>
    implements _$BookCopyWith<$Res> {
  __$BookCopyWithImpl(this._self, this._then);

  final _Book _self;
  final $Res Function(_Book) _then;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? author = null,Object? totalPages = null,Object? isbn = freezed,}) {
  return _then(_Book(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,isbn: freezed == isbn ? _self.isbn : isbn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Program {

 String get id; String get studentId; String? get classId; Book get book; String get startDate; String get targetDate; bool get extended; ProgramStatus get status; String? get finalReflection; int get currentPage; int get journalCount; String? get lastJournalDate; int get streakCurrent; int get streakBest;
/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramCopyWith<Program> get copyWith => _$ProgramCopyWithImpl<Program>(this as Program, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Program;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Program&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.studentId, _this.studentId) || other.studentId == _this.studentId)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&(identical(other.book, _this.book) || other.book == _this.book)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.targetDate, _this.targetDate) || other.targetDate == _this.targetDate)&&(identical(other.extended, _this.extended) || other.extended == _this.extended)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.finalReflection, _this.finalReflection) || other.finalReflection == _this.finalReflection)&&(identical(other.currentPage, _this.currentPage) || other.currentPage == _this.currentPage)&&(identical(other.journalCount, _this.journalCount) || other.journalCount == _this.journalCount)&&(identical(other.lastJournalDate, _this.lastJournalDate) || other.lastJournalDate == _this.lastJournalDate)&&(identical(other.streakCurrent, _this.streakCurrent) || other.streakCurrent == _this.streakCurrent)&&(identical(other.streakBest, _this.streakBest) || other.streakBest == _this.streakBest));
}


@override
int get hashCode {
  final _this = this as Program;
  return Object.hash(runtimeType,_this.id,_this.studentId,_this.classId,_this.book,_this.startDate,_this.targetDate,_this.extended,_this.status,_this.finalReflection,_this.currentPage,_this.journalCount,_this.lastJournalDate,_this.streakCurrent,_this.streakBest);
}

@override
String toString() {
  final _this = this as Program;
  return 'Program(id: ${_this.id}, studentId: ${_this.studentId}, classId: ${_this.classId}, book: ${_this.book}, startDate: ${_this.startDate}, targetDate: ${_this.targetDate}, extended: ${_this.extended}, status: ${_this.status}, finalReflection: ${_this.finalReflection}, currentPage: ${_this.currentPage}, journalCount: ${_this.journalCount}, lastJournalDate: ${_this.lastJournalDate}, streakCurrent: ${_this.streakCurrent}, streakBest: ${_this.streakBest})';
}


}

/// @nodoc
abstract mixin class $ProgramCopyWith<$Res>  {
  factory $ProgramCopyWith(Program value, $Res Function(Program) _then) = _$ProgramCopyWithImpl;
@useResult
$Res call({
 String id, String studentId, String? classId, Book book, String startDate, String targetDate, bool extended, ProgramStatus status, String? finalReflection, int currentPage, int journalCount, String? lastJournalDate, int streakCurrent, int streakBest
});


$BookCopyWith<$Res> get book;

}
/// @nodoc
class _$ProgramCopyWithImpl<$Res>
    implements $ProgramCopyWith<$Res> {
  _$ProgramCopyWithImpl(this._self, this._then);

  final Program _self;
  final $Res Function(Program) _then;

/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? classId = freezed,Object? book = null,Object? startDate = null,Object? targetDate = null,Object? extended = null,Object? status = null,Object? finalReflection = freezed,Object? currentPage = null,Object? journalCount = null,Object? lastJournalDate = freezed,Object? streakCurrent = null,Object? streakBest = null,}) {
  return _then(Program(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as Book,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,targetDate: null == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String,extended: null == extended ? _self.extended : extended // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProgramStatus,finalReflection: freezed == finalReflection ? _self.finalReflection : finalReflection // ignore: cast_nullable_to_non_nullable
as String?,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,journalCount: null == journalCount ? _self.journalCount : journalCount // ignore: cast_nullable_to_non_nullable
as int,lastJournalDate: freezed == lastJournalDate ? _self.lastJournalDate : lastJournalDate // ignore: cast_nullable_to_non_nullable
as String?,streakCurrent: null == streakCurrent ? _self.streakCurrent : streakCurrent // ignore: cast_nullable_to_non_nullable
as int,streakBest: null == streakBest ? _self.streakBest : streakBest // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookCopyWith<$Res> get book {
  
  return $BookCopyWith<$Res>(_self.book, (value) {
    return _then(_self.copyWith(book: value));
  });
}
}


/// Adds pattern-matching-related methods to [Program].
extension ProgramPatterns on Program {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Program value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Program() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Program value)  $default,){
final _that = this;
switch (_that) {
case _Program():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Program value)?  $default,){
final _that = this;
switch (_that) {
case _Program() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String studentId,  String? classId,  Book book,  String startDate,  String targetDate,  bool extended,  ProgramStatus status,  String? finalReflection,  int currentPage,  int journalCount,  String? lastJournalDate,  int streakCurrent,  int streakBest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Program() when $default != null:
return $default(_that.id,_that.studentId,_that.classId,_that.book,_that.startDate,_that.targetDate,_that.extended,_that.status,_that.finalReflection,_that.currentPage,_that.journalCount,_that.lastJournalDate,_that.streakCurrent,_that.streakBest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String studentId,  String? classId,  Book book,  String startDate,  String targetDate,  bool extended,  ProgramStatus status,  String? finalReflection,  int currentPage,  int journalCount,  String? lastJournalDate,  int streakCurrent,  int streakBest)  $default,) {final _that = this;
switch (_that) {
case _Program():
return $default(_that.id,_that.studentId,_that.classId,_that.book,_that.startDate,_that.targetDate,_that.extended,_that.status,_that.finalReflection,_that.currentPage,_that.journalCount,_that.lastJournalDate,_that.streakCurrent,_that.streakBest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String studentId,  String? classId,  Book book,  String startDate,  String targetDate,  bool extended,  ProgramStatus status,  String? finalReflection,  int currentPage,  int journalCount,  String? lastJournalDate,  int streakCurrent,  int streakBest)?  $default,) {final _that = this;
switch (_that) {
case _Program() when $default != null:
return $default(_that.id,_that.studentId,_that.classId,_that.book,_that.startDate,_that.targetDate,_that.extended,_that.status,_that.finalReflection,_that.currentPage,_that.journalCount,_that.lastJournalDate,_that.streakCurrent,_that.streakBest);case _:
  return null;

}
}

}

/// @nodoc


class _Program extends Program {
  const _Program({required this.id, required this.studentId, this.classId, required this.book, required this.startDate, required this.targetDate, this.extended = false, this.status = ProgramStatus.active, this.finalReflection, this.currentPage = 0, this.journalCount = 0, this.lastJournalDate, this.streakCurrent = 0, this.streakBest = 0}): super._();
  

@override final  String id;
@override final  String studentId;
@override final  String? classId;
@override final  Book book;
@override final  String startDate;
@override final  String targetDate;
@override@JsonKey() final  bool extended;
@override@JsonKey() final  ProgramStatus status;
@override final  String? finalReflection;
@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int journalCount;
@override final  String? lastJournalDate;
@override@JsonKey() final  int streakCurrent;
@override@JsonKey() final  int streakBest;

/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramCopyWith<_Program> get copyWith => __$ProgramCopyWithImpl<_Program>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Program&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.book, book) || other.book == book)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.extended, extended) || other.extended == extended)&&(identical(other.status, status) || other.status == status)&&(identical(other.finalReflection, finalReflection) || other.finalReflection == finalReflection)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.journalCount, journalCount) || other.journalCount == journalCount)&&(identical(other.lastJournalDate, lastJournalDate) || other.lastJournalDate == lastJournalDate)&&(identical(other.streakCurrent, streakCurrent) || other.streakCurrent == streakCurrent)&&(identical(other.streakBest, streakBest) || other.streakBest == streakBest));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,studentId,classId,book,startDate,targetDate,extended,status,finalReflection,currentPage,journalCount,lastJournalDate,streakCurrent,streakBest);
}

@override
String toString() {
    return 'Program(id: $id, studentId: $studentId, classId: $classId, book: $book, startDate: $startDate, targetDate: $targetDate, extended: $extended, status: $status, finalReflection: $finalReflection, currentPage: $currentPage, journalCount: $journalCount, lastJournalDate: $lastJournalDate, streakCurrent: $streakCurrent, streakBest: $streakBest)';
}


}

/// @nodoc
abstract mixin class _$ProgramCopyWith<$Res> implements $ProgramCopyWith<$Res> {
  factory _$ProgramCopyWith(_Program value, $Res Function(_Program) _then) = __$ProgramCopyWithImpl;
@override @useResult
$Res call({
 String id, String studentId, String? classId, Book book, String startDate, String targetDate, bool extended, ProgramStatus status, String? finalReflection, int currentPage, int journalCount, String? lastJournalDate, int streakCurrent, int streakBest
});


@override $BookCopyWith<$Res> get book;

}
/// @nodoc
class __$ProgramCopyWithImpl<$Res>
    implements _$ProgramCopyWith<$Res> {
  __$ProgramCopyWithImpl(this._self, this._then);

  final _Program _self;
  final $Res Function(_Program) _then;

/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? classId = freezed,Object? book = null,Object? startDate = null,Object? targetDate = null,Object? extended = null,Object? status = null,Object? finalReflection = freezed,Object? currentPage = null,Object? journalCount = null,Object? lastJournalDate = freezed,Object? streakCurrent = null,Object? streakBest = null,}) {
  return _then(_Program(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,book: null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as Book,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,targetDate: null == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String,extended: null == extended ? _self.extended : extended // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProgramStatus,finalReflection: freezed == finalReflection ? _self.finalReflection : finalReflection // ignore: cast_nullable_to_non_nullable
as String?,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,journalCount: null == journalCount ? _self.journalCount : journalCount // ignore: cast_nullable_to_non_nullable
as int,lastJournalDate: freezed == lastJournalDate ? _self.lastJournalDate : lastJournalDate // ignore: cast_nullable_to_non_nullable
as String?,streakCurrent: null == streakCurrent ? _self.streakCurrent : streakCurrent // ignore: cast_nullable_to_non_nullable
as int,streakBest: null == streakBest ? _self.streakBest : streakBest // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookCopyWith<$Res> get book {
  
  return $BookCopyWith<$Res>(_self.book, (value) {
    return _then(_self.copyWith(book: value));
  });
}
}

// dart format on
