// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Journal {

 String get programId; String get date; String get studentId; int get pageStart; int get pageEnd; DurationRange get durationRange; String get keyInformation; String? get reflection; String? get question; bool get hasUnreadTeacherComment;/// Written on this device and not yet acknowledged by the server.
 bool get pendingSync;
/// Create a copy of Journal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalCopyWith<Journal> get copyWith => _$JournalCopyWithImpl<Journal>(this as Journal, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Journal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Journal&&(identical(other.programId, _this.programId) || other.programId == _this.programId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.studentId, _this.studentId) || other.studentId == _this.studentId)&&(identical(other.pageStart, _this.pageStart) || other.pageStart == _this.pageStart)&&(identical(other.pageEnd, _this.pageEnd) || other.pageEnd == _this.pageEnd)&&(identical(other.durationRange, _this.durationRange) || other.durationRange == _this.durationRange)&&(identical(other.keyInformation, _this.keyInformation) || other.keyInformation == _this.keyInformation)&&(identical(other.reflection, _this.reflection) || other.reflection == _this.reflection)&&(identical(other.question, _this.question) || other.question == _this.question)&&(identical(other.hasUnreadTeacherComment, _this.hasUnreadTeacherComment) || other.hasUnreadTeacherComment == _this.hasUnreadTeacherComment)&&(identical(other.pendingSync, _this.pendingSync) || other.pendingSync == _this.pendingSync));
}


@override
int get hashCode {
  final _this = this as Journal;
  return Object.hash(runtimeType,_this.programId,_this.date,_this.studentId,_this.pageStart,_this.pageEnd,_this.durationRange,_this.keyInformation,_this.reflection,_this.question,_this.hasUnreadTeacherComment,_this.pendingSync);
}

@override
String toString() {
  final _this = this as Journal;
  return 'Journal(programId: ${_this.programId}, date: ${_this.date}, studentId: ${_this.studentId}, pageStart: ${_this.pageStart}, pageEnd: ${_this.pageEnd}, durationRange: ${_this.durationRange}, keyInformation: ${_this.keyInformation}, reflection: ${_this.reflection}, question: ${_this.question}, hasUnreadTeacherComment: ${_this.hasUnreadTeacherComment}, pendingSync: ${_this.pendingSync})';
}


}

/// @nodoc
abstract mixin class $JournalCopyWith<$Res>  {
  factory $JournalCopyWith(Journal value, $Res Function(Journal) _then) = _$JournalCopyWithImpl;
@useResult
$Res call({
 String programId, String date, String studentId, int pageStart, int pageEnd, DurationRange durationRange, String keyInformation, String? reflection, String? question, bool hasUnreadTeacherComment, bool pendingSync
});




}
/// @nodoc
class _$JournalCopyWithImpl<$Res>
    implements $JournalCopyWith<$Res> {
  _$JournalCopyWithImpl(this._self, this._then);

  final Journal _self;
  final $Res Function(Journal) _then;

/// Create a copy of Journal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programId = null,Object? date = null,Object? studentId = null,Object? pageStart = null,Object? pageEnd = null,Object? durationRange = null,Object? keyInformation = null,Object? reflection = freezed,Object? question = freezed,Object? hasUnreadTeacherComment = null,Object? pendingSync = null,}) {
  return _then(Journal(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,pageStart: null == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int,pageEnd: null == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int,durationRange: null == durationRange ? _self.durationRange : durationRange // ignore: cast_nullable_to_non_nullable
as DurationRange,keyInformation: null == keyInformation ? _self.keyInformation : keyInformation // ignore: cast_nullable_to_non_nullable
as String,reflection: freezed == reflection ? _self.reflection : reflection // ignore: cast_nullable_to_non_nullable
as String?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,hasUnreadTeacherComment: null == hasUnreadTeacherComment ? _self.hasUnreadTeacherComment : hasUnreadTeacherComment // ignore: cast_nullable_to_non_nullable
as bool,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Journal].
extension JournalPatterns on Journal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Journal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Journal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Journal value)  $default,){
final _that = this;
switch (_that) {
case _Journal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Journal value)?  $default,){
final _that = this;
switch (_that) {
case _Journal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String programId,  String date,  String studentId,  int pageStart,  int pageEnd,  DurationRange durationRange,  String keyInformation,  String? reflection,  String? question,  bool hasUnreadTeacherComment,  bool pendingSync)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Journal() when $default != null:
return $default(_that.programId,_that.date,_that.studentId,_that.pageStart,_that.pageEnd,_that.durationRange,_that.keyInformation,_that.reflection,_that.question,_that.hasUnreadTeacherComment,_that.pendingSync);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String programId,  String date,  String studentId,  int pageStart,  int pageEnd,  DurationRange durationRange,  String keyInformation,  String? reflection,  String? question,  bool hasUnreadTeacherComment,  bool pendingSync)  $default,) {final _that = this;
switch (_that) {
case _Journal():
return $default(_that.programId,_that.date,_that.studentId,_that.pageStart,_that.pageEnd,_that.durationRange,_that.keyInformation,_that.reflection,_that.question,_that.hasUnreadTeacherComment,_that.pendingSync);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String programId,  String date,  String studentId,  int pageStart,  int pageEnd,  DurationRange durationRange,  String keyInformation,  String? reflection,  String? question,  bool hasUnreadTeacherComment,  bool pendingSync)?  $default,) {final _that = this;
switch (_that) {
case _Journal() when $default != null:
return $default(_that.programId,_that.date,_that.studentId,_that.pageStart,_that.pageEnd,_that.durationRange,_that.keyInformation,_that.reflection,_that.question,_that.hasUnreadTeacherComment,_that.pendingSync);case _:
  return null;

}
}

}

/// @nodoc


class _Journal extends Journal {
  const _Journal({required this.programId, required this.date, required this.studentId, required this.pageStart, required this.pageEnd, required this.durationRange, required this.keyInformation, this.reflection, this.question, this.hasUnreadTeacherComment = false, this.pendingSync = false}): super._();
  

@override final  String programId;
@override final  String date;
@override final  String studentId;
@override final  int pageStart;
@override final  int pageEnd;
@override final  DurationRange durationRange;
@override final  String keyInformation;
@override final  String? reflection;
@override final  String? question;
@override@JsonKey() final  bool hasUnreadTeacherComment;
/// Written on this device and not yet acknowledged by the server.
@override@JsonKey() final  bool pendingSync;

/// Create a copy of Journal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalCopyWith<_Journal> get copyWith => __$JournalCopyWithImpl<_Journal>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Journal&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.date, date) || other.date == date)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd)&&(identical(other.durationRange, durationRange) || other.durationRange == durationRange)&&(identical(other.keyInformation, keyInformation) || other.keyInformation == keyInformation)&&(identical(other.reflection, reflection) || other.reflection == reflection)&&(identical(other.question, question) || other.question == question)&&(identical(other.hasUnreadTeacherComment, hasUnreadTeacherComment) || other.hasUnreadTeacherComment == hasUnreadTeacherComment)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync));
}


@override
int get hashCode {
    return Object.hash(runtimeType,programId,date,studentId,pageStart,pageEnd,durationRange,keyInformation,reflection,question,hasUnreadTeacherComment,pendingSync);
}

@override
String toString() {
    return 'Journal(programId: $programId, date: $date, studentId: $studentId, pageStart: $pageStart, pageEnd: $pageEnd, durationRange: $durationRange, keyInformation: $keyInformation, reflection: $reflection, question: $question, hasUnreadTeacherComment: $hasUnreadTeacherComment, pendingSync: $pendingSync)';
}


}

/// @nodoc
abstract mixin class _$JournalCopyWith<$Res> implements $JournalCopyWith<$Res> {
  factory _$JournalCopyWith(_Journal value, $Res Function(_Journal) _then) = __$JournalCopyWithImpl;
@override @useResult
$Res call({
 String programId, String date, String studentId, int pageStart, int pageEnd, DurationRange durationRange, String keyInformation, String? reflection, String? question, bool hasUnreadTeacherComment, bool pendingSync
});




}
/// @nodoc
class __$JournalCopyWithImpl<$Res>
    implements _$JournalCopyWith<$Res> {
  __$JournalCopyWithImpl(this._self, this._then);

  final _Journal _self;
  final $Res Function(_Journal) _then;

/// Create a copy of Journal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programId = null,Object? date = null,Object? studentId = null,Object? pageStart = null,Object? pageEnd = null,Object? durationRange = null,Object? keyInformation = null,Object? reflection = freezed,Object? question = freezed,Object? hasUnreadTeacherComment = null,Object? pendingSync = null,}) {
  return _then(_Journal(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,pageStart: null == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int,pageEnd: null == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int,durationRange: null == durationRange ? _self.durationRange : durationRange // ignore: cast_nullable_to_non_nullable
as DurationRange,keyInformation: null == keyInformation ? _self.keyInformation : keyInformation // ignore: cast_nullable_to_non_nullable
as String,reflection: freezed == reflection ? _self.reflection : reflection // ignore: cast_nullable_to_non_nullable
as String?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,hasUnreadTeacherComment: null == hasUnreadTeacherComment ? _self.hasUnreadTeacherComment : hasUnreadTeacherComment // ignore: cast_nullable_to_non_nullable
as bool,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$JournalComment {

 String get id; String get teacherId; String get teacherName; String get text; DateTime? get createdAt; bool get edited;
/// Create a copy of JournalComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalCommentCopyWith<JournalComment> get copyWith => _$JournalCommentCopyWithImpl<JournalComment>(this as JournalComment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JournalComment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalComment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teacherId, _this.teacherId) || other.teacherId == _this.teacherId)&&(identical(other.teacherName, _this.teacherName) || other.teacherName == _this.teacherName)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.edited, _this.edited) || other.edited == _this.edited));
}


@override
int get hashCode {
  final _this = this as JournalComment;
  return Object.hash(runtimeType,_this.id,_this.teacherId,_this.teacherName,_this.text,_this.createdAt,_this.edited);
}

@override
String toString() {
  final _this = this as JournalComment;
  return 'JournalComment(id: ${_this.id}, teacherId: ${_this.teacherId}, teacherName: ${_this.teacherName}, text: ${_this.text}, createdAt: ${_this.createdAt}, edited: ${_this.edited})';
}


}

/// @nodoc
abstract mixin class $JournalCommentCopyWith<$Res>  {
  factory $JournalCommentCopyWith(JournalComment value, $Res Function(JournalComment) _then) = _$JournalCommentCopyWithImpl;
@useResult
$Res call({
 String id, String teacherId, String teacherName, String text, DateTime? createdAt, bool edited
});




}
/// @nodoc
class _$JournalCommentCopyWithImpl<$Res>
    implements $JournalCommentCopyWith<$Res> {
  _$JournalCommentCopyWithImpl(this._self, this._then);

  final JournalComment _self;
  final $Res Function(JournalComment) _then;

/// Create a copy of JournalComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teacherId = null,Object? teacherName = null,Object? text = null,Object? createdAt = freezed,Object? edited = null,}) {
  return _then(JournalComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalComment].
extension JournalCommentPatterns on JournalComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalComment value)  $default,){
final _that = this;
switch (_that) {
case _JournalComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalComment value)?  $default,){
final _that = this;
switch (_that) {
case _JournalComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String teacherId,  String teacherName,  String text,  DateTime? createdAt,  bool edited)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalComment() when $default != null:
return $default(_that.id,_that.teacherId,_that.teacherName,_that.text,_that.createdAt,_that.edited);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String teacherId,  String teacherName,  String text,  DateTime? createdAt,  bool edited)  $default,) {final _that = this;
switch (_that) {
case _JournalComment():
return $default(_that.id,_that.teacherId,_that.teacherName,_that.text,_that.createdAt,_that.edited);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String teacherId,  String teacherName,  String text,  DateTime? createdAt,  bool edited)?  $default,) {final _that = this;
switch (_that) {
case _JournalComment() when $default != null:
return $default(_that.id,_that.teacherId,_that.teacherName,_that.text,_that.createdAt,_that.edited);case _:
  return null;

}
}

}

/// @nodoc


class _JournalComment implements JournalComment {
  const _JournalComment({required this.id, required this.teacherId, required this.teacherName, required this.text, this.createdAt, this.edited = false});
  

@override final  String id;
@override final  String teacherId;
@override final  String teacherName;
@override final  String text;
@override final  DateTime? createdAt;
@override@JsonKey() final  bool edited;

/// Create a copy of JournalComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalCommentCopyWith<_JournalComment> get copyWith => __$JournalCommentCopyWithImpl<_JournalComment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalComment&&(identical(other.id, id) || other.id == id)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.edited, edited) || other.edited == edited));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,teacherId,teacherName,text,createdAt,edited);
}

@override
String toString() {
    return 'JournalComment(id: $id, teacherId: $teacherId, teacherName: $teacherName, text: $text, createdAt: $createdAt, edited: $edited)';
}


}

/// @nodoc
abstract mixin class _$JournalCommentCopyWith<$Res> implements $JournalCommentCopyWith<$Res> {
  factory _$JournalCommentCopyWith(_JournalComment value, $Res Function(_JournalComment) _then) = __$JournalCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String teacherId, String teacherName, String text, DateTime? createdAt, bool edited
});




}
/// @nodoc
class __$JournalCommentCopyWithImpl<$Res>
    implements _$JournalCommentCopyWith<$Res> {
  __$JournalCommentCopyWithImpl(this._self, this._then);

  final _JournalComment _self;
  final $Res Function(_JournalComment) _then;

/// Create a copy of JournalComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teacherId = null,Object? teacherName = null,Object? text = null,Object? createdAt = freezed,Object? edited = null,}) {
  return _then(_JournalComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
