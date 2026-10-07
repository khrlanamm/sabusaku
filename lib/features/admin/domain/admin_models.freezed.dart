// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewUser {

 UserRole get role; String get name; String get username;/// Students: their class.
 String? get classId;/// Teachers: assigned classes.
 List<String> get classIds;
/// Create a copy of NewUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewUserCopyWith<NewUser> get copyWith => _$NewUserCopyWithImpl<NewUser>(this as NewUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NewUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewUser&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&const DeepCollectionEquality().equals(other.classIds, _this.classIds));
}


@override
int get hashCode {
  final _this = this as NewUser;
  return Object.hash(runtimeType,_this.role,_this.name,_this.username,_this.classId,const DeepCollectionEquality().hash(_this.classIds));
}

@override
String toString() {
  final _this = this as NewUser;
  return 'NewUser(role: ${_this.role}, name: ${_this.name}, username: ${_this.username}, classId: ${_this.classId}, classIds: ${_this.classIds})';
}


}

/// @nodoc
abstract mixin class $NewUserCopyWith<$Res>  {
  factory $NewUserCopyWith(NewUser value, $Res Function(NewUser) _then) = _$NewUserCopyWithImpl;
@useResult
$Res call({
 UserRole role, String name, String username, String? classId, List<String> classIds
});




}
/// @nodoc
class _$NewUserCopyWithImpl<$Res>
    implements $NewUserCopyWith<$Res> {
  _$NewUserCopyWithImpl(this._self, this._then);

  final NewUser _self;
  final $Res Function(NewUser) _then;

/// Create a copy of NewUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? name = null,Object? username = null,Object? classId = freezed,Object? classIds = null,}) {
  return _then(NewUser(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,classIds: null == classIds ? _self.classIds : classIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [NewUser].
extension NewUserPatterns on NewUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewUser value)  $default,){
final _that = this;
switch (_that) {
case _NewUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewUser value)?  $default,){
final _that = this;
switch (_that) {
case _NewUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserRole role,  String name,  String username,  String? classId,  List<String> classIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewUser() when $default != null:
return $default(_that.role,_that.name,_that.username,_that.classId,_that.classIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserRole role,  String name,  String username,  String? classId,  List<String> classIds)  $default,) {final _that = this;
switch (_that) {
case _NewUser():
return $default(_that.role,_that.name,_that.username,_that.classId,_that.classIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserRole role,  String name,  String username,  String? classId,  List<String> classIds)?  $default,) {final _that = this;
switch (_that) {
case _NewUser() when $default != null:
return $default(_that.role,_that.name,_that.username,_that.classId,_that.classIds);case _:
  return null;

}
}

}

/// @nodoc


class _NewUser extends NewUser {
  const _NewUser({required this.role, required this.name, required this.username, this.classId,  List<String> classIds = const <String>[]}): _classIds = classIds,super._();
  

@override final  UserRole role;
@override final  String name;
@override final  String username;
/// Students: their class.
@override final  String? classId;
/// Teachers: assigned classes.
 final  List<String> _classIds;
/// Teachers: assigned classes.
@override@JsonKey() List<String> get classIds {
  if (_classIds is EqualUnmodifiableListView) return _classIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classIds);
}


/// Create a copy of NewUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewUserCopyWith<_NewUser> get copyWith => __$NewUserCopyWithImpl<_NewUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewUser&&(identical(other.role, role) || other.role == role)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.classId, classId) || other.classId == classId)&&const DeepCollectionEquality().equals(other.classIds, _classIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,role,name,username,classId,const DeepCollectionEquality().hash(_classIds));
}

@override
String toString() {
    return 'NewUser(role: $role, name: $name, username: $username, classId: $classId, classIds: $classIds)';
}


}

/// @nodoc
abstract mixin class _$NewUserCopyWith<$Res> implements $NewUserCopyWith<$Res> {
  factory _$NewUserCopyWith(_NewUser value, $Res Function(_NewUser) _then) = __$NewUserCopyWithImpl;
@override @useResult
$Res call({
 UserRole role, String name, String username, String? classId, List<String> classIds
});




}
/// @nodoc
class __$NewUserCopyWithImpl<$Res>
    implements _$NewUserCopyWith<$Res> {
  __$NewUserCopyWithImpl(this._self, this._then);

  final _NewUser _self;
  final $Res Function(_NewUser) _then;

/// Create a copy of NewUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? name = null,Object? username = null,Object? classId = freezed,Object? classIds = null,}) {
  return _then(_NewUser(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,classIds: null == classIds ? _self._classIds : classIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$CreateUserResult {

 String get username; bool get ok; String? get uid; String? get password; String? get reason;
/// Create a copy of CreateUserResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateUserResultCopyWith<CreateUserResult> get copyWith => _$CreateUserResultCopyWithImpl<CreateUserResult>(this as CreateUserResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreateUserResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUserResult&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.password, _this.password) || other.password == _this.password)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as CreateUserResult;
  return Object.hash(runtimeType,_this.username,_this.ok,_this.uid,_this.password,_this.reason);
}

@override
String toString() {
  final _this = this as CreateUserResult;
  return 'CreateUserResult(username: ${_this.username}, ok: ${_this.ok}, uid: ${_this.uid}, password: ${_this.password}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $CreateUserResultCopyWith<$Res>  {
  factory $CreateUserResultCopyWith(CreateUserResult value, $Res Function(CreateUserResult) _then) = _$CreateUserResultCopyWithImpl;
@useResult
$Res call({
 String username, bool ok, String? uid, String? password, String? reason
});




}
/// @nodoc
class _$CreateUserResultCopyWithImpl<$Res>
    implements $CreateUserResultCopyWith<$Res> {
  _$CreateUserResultCopyWithImpl(this._self, this._then);

  final CreateUserResult _self;
  final $Res Function(CreateUserResult) _then;

/// Create a copy of CreateUserResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? ok = null,Object? uid = freezed,Object? password = freezed,Object? reason = freezed,}) {
  return _then(CreateUserResult(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateUserResult].
extension CreateUserResultPatterns on CreateUserResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateUserResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateUserResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateUserResult value)  $default,){
final _that = this;
switch (_that) {
case _CreateUserResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateUserResult value)?  $default,){
final _that = this;
switch (_that) {
case _CreateUserResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  bool ok,  String? uid,  String? password,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateUserResult() when $default != null:
return $default(_that.username,_that.ok,_that.uid,_that.password,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  bool ok,  String? uid,  String? password,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _CreateUserResult():
return $default(_that.username,_that.ok,_that.uid,_that.password,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  bool ok,  String? uid,  String? password,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _CreateUserResult() when $default != null:
return $default(_that.username,_that.ok,_that.uid,_that.password,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _CreateUserResult implements CreateUserResult {
  const _CreateUserResult({required this.username, required this.ok, this.uid, this.password, this.reason});
  

@override final  String username;
@override final  bool ok;
@override final  String? uid;
@override final  String? password;
@override final  String? reason;

/// Create a copy of CreateUserResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateUserResultCopyWith<_CreateUserResult> get copyWith => __$CreateUserResultCopyWithImpl<_CreateUserResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateUserResult&&(identical(other.username, username) || other.username == username)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.password, password) || other.password == password)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,username,ok,uid,password,reason);
}

@override
String toString() {
    return 'CreateUserResult(username: $username, ok: $ok, uid: $uid, password: $password, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$CreateUserResultCopyWith<$Res> implements $CreateUserResultCopyWith<$Res> {
  factory _$CreateUserResultCopyWith(_CreateUserResult value, $Res Function(_CreateUserResult) _then) = __$CreateUserResultCopyWithImpl;
@override @useResult
$Res call({
 String username, bool ok, String? uid, String? password, String? reason
});




}
/// @nodoc
class __$CreateUserResultCopyWithImpl<$Res>
    implements _$CreateUserResultCopyWith<$Res> {
  __$CreateUserResultCopyWithImpl(this._self, this._then);

  final _CreateUserResult _self;
  final $Res Function(_CreateUserResult) _then;

/// Create a copy of CreateUserResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? ok = null,Object? uid = freezed,Object? password = freezed,Object? reason = freezed,}) {
  return _then(_CreateUserResult(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,uid: freezed == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AdminCounts {

 int get students; int get teachers; int get classes; Map<StudentStatus, int> get byStatus;
/// Create a copy of AdminCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminCountsCopyWith<AdminCounts> get copyWith => _$AdminCountsCopyWithImpl<AdminCounts>(this as AdminCounts, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminCounts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminCounts&&(identical(other.students, _this.students) || other.students == _this.students)&&(identical(other.teachers, _this.teachers) || other.teachers == _this.teachers)&&(identical(other.classes, _this.classes) || other.classes == _this.classes)&&const DeepCollectionEquality().equals(other.byStatus, _this.byStatus));
}


@override
int get hashCode {
  final _this = this as AdminCounts;
  return Object.hash(runtimeType,_this.students,_this.teachers,_this.classes,const DeepCollectionEquality().hash(_this.byStatus));
}

@override
String toString() {
  final _this = this as AdminCounts;
  return 'AdminCounts(students: ${_this.students}, teachers: ${_this.teachers}, classes: ${_this.classes}, byStatus: ${_this.byStatus})';
}


}

/// @nodoc
abstract mixin class $AdminCountsCopyWith<$Res>  {
  factory $AdminCountsCopyWith(AdminCounts value, $Res Function(AdminCounts) _then) = _$AdminCountsCopyWithImpl;
@useResult
$Res call({
 int students, int teachers, int classes, Map<StudentStatus, int> byStatus
});




}
/// @nodoc
class _$AdminCountsCopyWithImpl<$Res>
    implements $AdminCountsCopyWith<$Res> {
  _$AdminCountsCopyWithImpl(this._self, this._then);

  final AdminCounts _self;
  final $Res Function(AdminCounts) _then;

/// Create a copy of AdminCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? students = null,Object? teachers = null,Object? classes = null,Object? byStatus = null,}) {
  return _then(AdminCounts(
students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,teachers: null == teachers ? _self.teachers : teachers // ignore: cast_nullable_to_non_nullable
as int,classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as int,byStatus: null == byStatus ? _self.byStatus : byStatus // ignore: cast_nullable_to_non_nullable
as Map<StudentStatus, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminCounts].
extension AdminCountsPatterns on AdminCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminCounts value)  $default,){
final _that = this;
switch (_that) {
case _AdminCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminCounts value)?  $default,){
final _that = this;
switch (_that) {
case _AdminCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int students,  int teachers,  int classes,  Map<StudentStatus, int> byStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminCounts() when $default != null:
return $default(_that.students,_that.teachers,_that.classes,_that.byStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int students,  int teachers,  int classes,  Map<StudentStatus, int> byStatus)  $default,) {final _that = this;
switch (_that) {
case _AdminCounts():
return $default(_that.students,_that.teachers,_that.classes,_that.byStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int students,  int teachers,  int classes,  Map<StudentStatus, int> byStatus)?  $default,) {final _that = this;
switch (_that) {
case _AdminCounts() when $default != null:
return $default(_that.students,_that.teachers,_that.classes,_that.byStatus);case _:
  return null;

}
}

}

/// @nodoc


class _AdminCounts implements AdminCounts {
  const _AdminCounts({required this.students, required this.teachers, required this.classes, required  Map<StudentStatus, int> byStatus}): _byStatus = byStatus;
  

@override final  int students;
@override final  int teachers;
@override final  int classes;
 final  Map<StudentStatus, int> _byStatus;
@override Map<StudentStatus, int> get byStatus {
  if (_byStatus is EqualUnmodifiableMapView) return _byStatus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byStatus);
}


/// Create a copy of AdminCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminCountsCopyWith<_AdminCounts> get copyWith => __$AdminCountsCopyWithImpl<_AdminCounts>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminCounts&&(identical(other.students, students) || other.students == students)&&(identical(other.teachers, teachers) || other.teachers == teachers)&&(identical(other.classes, classes) || other.classes == classes)&&const DeepCollectionEquality().equals(other.byStatus, _byStatus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,students,teachers,classes,const DeepCollectionEquality().hash(_byStatus));
}

@override
String toString() {
    return 'AdminCounts(students: $students, teachers: $teachers, classes: $classes, byStatus: $byStatus)';
}


}

/// @nodoc
abstract mixin class _$AdminCountsCopyWith<$Res> implements $AdminCountsCopyWith<$Res> {
  factory _$AdminCountsCopyWith(_AdminCounts value, $Res Function(_AdminCounts) _then) = __$AdminCountsCopyWithImpl;
@override @useResult
$Res call({
 int students, int teachers, int classes, Map<StudentStatus, int> byStatus
});




}
/// @nodoc
class __$AdminCountsCopyWithImpl<$Res>
    implements _$AdminCountsCopyWith<$Res> {
  __$AdminCountsCopyWithImpl(this._self, this._then);

  final _AdminCounts _self;
  final $Res Function(_AdminCounts) _then;

/// Create a copy of AdminCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? students = null,Object? teachers = null,Object? classes = null,Object? byStatus = null,}) {
  return _then(_AdminCounts(
students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,teachers: null == teachers ? _self.teachers : teachers // ignore: cast_nullable_to_non_nullable
as int,classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as int,byStatus: null == byStatus ? _self._byStatus : byStatus // ignore: cast_nullable_to_non_nullable
as Map<StudentStatus, int>,
  ));
}


}

// dart format on
