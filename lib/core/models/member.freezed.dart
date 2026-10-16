// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Member {

 String get email; String get schoolId; UserRole get role; String get name;/// Class label, e.g. `XII-A1`.
 String? get classId; List<String> get extracurriculars;/// Set once the account signed in and claimed this entry.
 String? get uid;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Member;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.schoolId, _this.schoolId) || other.schoolId == _this.schoolId)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&const DeepCollectionEquality().equals(other.extracurriculars, _this.extracurriculars)&&(identical(other.uid, _this.uid) || other.uid == _this.uid));
}


@override
int get hashCode {
  final _this = this as Member;
  return Object.hash(runtimeType,_this.email,_this.schoolId,_this.role,_this.name,_this.classId,const DeepCollectionEquality().hash(_this.extracurriculars),_this.uid);
}

@override
String toString() {
  final _this = this as Member;
  return 'Member(email: ${_this.email}, schoolId: ${_this.schoolId}, role: ${_this.role}, name: ${_this.name}, classId: ${_this.classId}, extracurriculars: ${_this.extracurriculars}, uid: ${_this.uid})';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String email, String schoolId, UserRole role, String name, String? classId, List<String> extracurriculars, String? uid
});




}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? schoolId = null,Object? role = null,Object? name = null,Object? classId = freezed,Object? extracurriculars = null,Object? uid = freezed,}) {
  return _then(Member(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,schoolId: null == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,extracurriculars: null == extracurriculars ? _self.extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String schoolId,  UserRole role,  String name,  String? classId,  List<String> extracurriculars,  String? uid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.email,_that.schoolId,_that.role,_that.name,_that.classId,_that.extracurriculars,_that.uid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String schoolId,  UserRole role,  String name,  String? classId,  List<String> extracurriculars,  String? uid)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.email,_that.schoolId,_that.role,_that.name,_that.classId,_that.extracurriculars,_that.uid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String schoolId,  UserRole role,  String name,  String? classId,  List<String> extracurriculars,  String? uid)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.email,_that.schoolId,_that.role,_that.name,_that.classId,_that.extracurriculars,_that.uid);case _:
  return null;

}
}

}

/// @nodoc


class _Member extends Member {
  const _Member({required this.email, required this.schoolId, required this.role, this.name = '', this.classId,  List<String> extracurriculars = const <String>[], this.uid}): _extracurriculars = extracurriculars,super._();
  

@override final  String email;
@override final  String schoolId;
@override final  UserRole role;
@override@JsonKey() final  String name;
/// Class label, e.g. `XII-A1`.
@override final  String? classId;
 final  List<String> _extracurriculars;
@override@JsonKey() List<String> get extracurriculars {
  if (_extracurriculars is EqualUnmodifiableListView) return _extracurriculars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extracurriculars);
}

/// Set once the account signed in and claimed this entry.
@override final  String? uid;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.email, email) || other.email == email)&&(identical(other.schoolId, schoolId) || other.schoolId == schoolId)&&(identical(other.role, role) || other.role == role)&&(identical(other.name, name) || other.name == name)&&(identical(other.classId, classId) || other.classId == classId)&&const DeepCollectionEquality().equals(other.extracurriculars, _extracurriculars)&&(identical(other.uid, uid) || other.uid == uid));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,schoolId,role,name,classId,const DeepCollectionEquality().hash(_extracurriculars),uid);
}

@override
String toString() {
    return 'Member(email: $email, schoolId: $schoolId, role: $role, name: $name, classId: $classId, extracurriculars: $extracurriculars, uid: $uid)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String email, String schoolId, UserRole role, String name, String? classId, List<String> extracurriculars, String? uid
});




}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? schoolId = null,Object? role = null,Object? name = null,Object? classId = freezed,Object? extracurriculars = null,Object? uid = freezed,}) {
  return _then(_Member(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,schoolId: null == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,extracurriculars: null == extracurriculars ? _self._extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$NewStudent {

 String get email; String get name; String? get classId; List<String> get extracurriculars;
/// Create a copy of NewStudent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewStudentCopyWith<NewStudent> get copyWith => _$NewStudentCopyWithImpl<NewStudent>(this as NewStudent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NewStudent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewStudent&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&const DeepCollectionEquality().equals(other.extracurriculars, _this.extracurriculars));
}


@override
int get hashCode {
  final _this = this as NewStudent;
  return Object.hash(runtimeType,_this.email,_this.name,_this.classId,const DeepCollectionEquality().hash(_this.extracurriculars));
}

@override
String toString() {
  final _this = this as NewStudent;
  return 'NewStudent(email: ${_this.email}, name: ${_this.name}, classId: ${_this.classId}, extracurriculars: ${_this.extracurriculars})';
}


}

/// @nodoc
abstract mixin class $NewStudentCopyWith<$Res>  {
  factory $NewStudentCopyWith(NewStudent value, $Res Function(NewStudent) _then) = _$NewStudentCopyWithImpl;
@useResult
$Res call({
 String email, String name, String? classId, List<String> extracurriculars
});




}
/// @nodoc
class _$NewStudentCopyWithImpl<$Res>
    implements $NewStudentCopyWith<$Res> {
  _$NewStudentCopyWithImpl(this._self, this._then);

  final NewStudent _self;
  final $Res Function(NewStudent) _then;

/// Create a copy of NewStudent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? name = null,Object? classId = freezed,Object? extracurriculars = null,}) {
  return _then(NewStudent(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,extracurriculars: null == extracurriculars ? _self.extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [NewStudent].
extension NewStudentPatterns on NewStudent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewStudent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewStudent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewStudent value)  $default,){
final _that = this;
switch (_that) {
case _NewStudent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewStudent value)?  $default,){
final _that = this;
switch (_that) {
case _NewStudent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String name,  String? classId,  List<String> extracurriculars)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewStudent() when $default != null:
return $default(_that.email,_that.name,_that.classId,_that.extracurriculars);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String name,  String? classId,  List<String> extracurriculars)  $default,) {final _that = this;
switch (_that) {
case _NewStudent():
return $default(_that.email,_that.name,_that.classId,_that.extracurriculars);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String name,  String? classId,  List<String> extracurriculars)?  $default,) {final _that = this;
switch (_that) {
case _NewStudent() when $default != null:
return $default(_that.email,_that.name,_that.classId,_that.extracurriculars);case _:
  return null;

}
}

}

/// @nodoc


class _NewStudent extends NewStudent {
  const _NewStudent({required this.email, this.name = '', this.classId,  List<String> extracurriculars = const <String>[]}): _extracurriculars = extracurriculars,super._();
  

@override final  String email;
@override@JsonKey() final  String name;
@override final  String? classId;
 final  List<String> _extracurriculars;
@override@JsonKey() List<String> get extracurriculars {
  if (_extracurriculars is EqualUnmodifiableListView) return _extracurriculars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extracurriculars);
}


/// Create a copy of NewStudent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewStudentCopyWith<_NewStudent> get copyWith => __$NewStudentCopyWithImpl<_NewStudent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewStudent&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&(identical(other.classId, classId) || other.classId == classId)&&const DeepCollectionEquality().equals(other.extracurriculars, _extracurriculars));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,name,classId,const DeepCollectionEquality().hash(_extracurriculars));
}

@override
String toString() {
    return 'NewStudent(email: $email, name: $name, classId: $classId, extracurriculars: $extracurriculars)';
}


}

/// @nodoc
abstract mixin class _$NewStudentCopyWith<$Res> implements $NewStudentCopyWith<$Res> {
  factory _$NewStudentCopyWith(_NewStudent value, $Res Function(_NewStudent) _then) = __$NewStudentCopyWithImpl;
@override @useResult
$Res call({
 String email, String name, String? classId, List<String> extracurriculars
});




}
/// @nodoc
class __$NewStudentCopyWithImpl<$Res>
    implements _$NewStudentCopyWith<$Res> {
  __$NewStudentCopyWithImpl(this._self, this._then);

  final _NewStudent _self;
  final $Res Function(_NewStudent) _then;

/// Create a copy of NewStudent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? name = null,Object? classId = freezed,Object? extracurriculars = null,}) {
  return _then(_NewStudent(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,extracurriculars: null == extracurriculars ? _self._extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$AddStudentResult {

 String get email; bool get ok; String? get reason;
/// Create a copy of AddStudentResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddStudentResultCopyWith<AddStudentResult> get copyWith => _$AddStudentResultCopyWithImpl<AddStudentResult>(this as AddStudentResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AddStudentResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddStudentResult&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as AddStudentResult;
  return Object.hash(runtimeType,_this.email,_this.ok,_this.reason);
}

@override
String toString() {
  final _this = this as AddStudentResult;
  return 'AddStudentResult(email: ${_this.email}, ok: ${_this.ok}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $AddStudentResultCopyWith<$Res>  {
  factory $AddStudentResultCopyWith(AddStudentResult value, $Res Function(AddStudentResult) _then) = _$AddStudentResultCopyWithImpl;
@useResult
$Res call({
 String email, bool ok, String? reason
});




}
/// @nodoc
class _$AddStudentResultCopyWithImpl<$Res>
    implements $AddStudentResultCopyWith<$Res> {
  _$AddStudentResultCopyWithImpl(this._self, this._then);

  final AddStudentResult _self;
  final $Res Function(AddStudentResult) _then;

/// Create a copy of AddStudentResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? ok = null,Object? reason = freezed,}) {
  return _then(AddStudentResult(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddStudentResult].
extension AddStudentResultPatterns on AddStudentResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddStudentResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddStudentResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddStudentResult value)  $default,){
final _that = this;
switch (_that) {
case _AddStudentResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddStudentResult value)?  $default,){
final _that = this;
switch (_that) {
case _AddStudentResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  bool ok,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddStudentResult() when $default != null:
return $default(_that.email,_that.ok,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  bool ok,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _AddStudentResult():
return $default(_that.email,_that.ok,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  bool ok,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _AddStudentResult() when $default != null:
return $default(_that.email,_that.ok,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _AddStudentResult implements AddStudentResult {
  const _AddStudentResult({required this.email, required this.ok, this.reason});
  

@override final  String email;
@override final  bool ok;
@override final  String? reason;

/// Create a copy of AddStudentResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddStudentResultCopyWith<_AddStudentResult> get copyWith => __$AddStudentResultCopyWithImpl<_AddStudentResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddStudentResult&&(identical(other.email, email) || other.email == email)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,ok,reason);
}

@override
String toString() {
    return 'AddStudentResult(email: $email, ok: $ok, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$AddStudentResultCopyWith<$Res> implements $AddStudentResultCopyWith<$Res> {
  factory _$AddStudentResultCopyWith(_AddStudentResult value, $Res Function(_AddStudentResult) _then) = __$AddStudentResultCopyWithImpl;
@override @useResult
$Res call({
 String email, bool ok, String? reason
});




}
/// @nodoc
class __$AddStudentResultCopyWithImpl<$Res>
    implements _$AddStudentResultCopyWith<$Res> {
  __$AddStudentResultCopyWithImpl(this._self, this._then);

  final _AddStudentResult _self;
  final $Res Function(_AddStudentResult) _then;

/// Create a copy of AddStudentResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? ok = null,Object? reason = freezed,}) {
  return _then(_AddStudentResult(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
