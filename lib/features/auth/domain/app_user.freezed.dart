// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppUser {

 String get uid; UserRole get role;/// Empty until the user completes their profile.
 String get name; String get email;/// Students: their class label, e.g. `XII-A1`. Null until chosen.
 String? get classId;/// Extracurricular labels, e.g. `Masis-KIR`. Teachers: the ones they
/// supervise.
 List<String> get extracurriculars;/// Teachers: the class they are the homeroom teacher (wali kelas) of.
 String? get homeroomClass; String? get photoUrl;/// False once a teacher removed the student from the school.
 bool get active;/// The version of the terms of use the user accepted; 0 when none.
/// Written by the `acceptTerms` callable only.
 int get termsVersion;/// The superadmin's profile in a school they opened. Left out of the
/// school's teacher list. Written by Cloud Functions only.
 bool get superadmin;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&const DeepCollectionEquality().equals(other.extracurriculars, _this.extracurriculars)&&(identical(other.homeroomClass, _this.homeroomClass) || other.homeroomClass == _this.homeroomClass)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.active, _this.active) || other.active == _this.active)&&(identical(other.termsVersion, _this.termsVersion) || other.termsVersion == _this.termsVersion)&&(identical(other.superadmin, _this.superadmin) || other.superadmin == _this.superadmin));
}


@override
int get hashCode {
  final _this = this as AppUser;
  return Object.hash(runtimeType,_this.uid,_this.role,_this.name,_this.email,_this.classId,const DeepCollectionEquality().hash(_this.extracurriculars),_this.homeroomClass,_this.photoUrl,_this.active,_this.termsVersion,_this.superadmin);
}

@override
String toString() {
  final _this = this as AppUser;
  return 'AppUser(uid: ${_this.uid}, role: ${_this.role}, name: ${_this.name}, email: ${_this.email}, classId: ${_this.classId}, extracurriculars: ${_this.extracurriculars}, homeroomClass: ${_this.homeroomClass}, photoUrl: ${_this.photoUrl}, active: ${_this.active}, termsVersion: ${_this.termsVersion}, superadmin: ${_this.superadmin})';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String uid, UserRole role, String name, String email, String? classId, List<String> extracurriculars, String? homeroomClass, String? photoUrl, bool active, int termsVersion, bool superadmin
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? role = null,Object? name = null,Object? email = null,Object? classId = freezed,Object? extracurriculars = null,Object? homeroomClass = freezed,Object? photoUrl = freezed,Object? active = null,Object? termsVersion = null,Object? superadmin = null,}) {
  return _then(AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,extracurriculars: null == extracurriculars ? _self.extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,homeroomClass: freezed == homeroomClass ? _self.homeroomClass : homeroomClass // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as int,superadmin: null == superadmin ? _self.superadmin : superadmin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  UserRole role,  String name,  String email,  String? classId,  List<String> extracurriculars,  String? homeroomClass,  String? photoUrl,  bool active,  int termsVersion,  bool superadmin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.role,_that.name,_that.email,_that.classId,_that.extracurriculars,_that.homeroomClass,_that.photoUrl,_that.active,_that.termsVersion,_that.superadmin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  UserRole role,  String name,  String email,  String? classId,  List<String> extracurriculars,  String? homeroomClass,  String? photoUrl,  bool active,  int termsVersion,  bool superadmin)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.uid,_that.role,_that.name,_that.email,_that.classId,_that.extracurriculars,_that.homeroomClass,_that.photoUrl,_that.active,_that.termsVersion,_that.superadmin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  UserRole role,  String name,  String email,  String? classId,  List<String> extracurriculars,  String? homeroomClass,  String? photoUrl,  bool active,  int termsVersion,  bool superadmin)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.role,_that.name,_that.email,_that.classId,_that.extracurriculars,_that.homeroomClass,_that.photoUrl,_that.active,_that.termsVersion,_that.superadmin);case _:
  return null;

}
}

}

/// @nodoc


class _AppUser extends AppUser {
  const _AppUser({required this.uid, required this.role, this.name = '', this.email = '', this.classId,  List<String> extracurriculars = const <String>[], this.homeroomClass, this.photoUrl, this.active = true, this.termsVersion = 0, this.superadmin = false}): _extracurriculars = extracurriculars,super._();
  

@override final  String uid;
@override final  UserRole role;
/// Empty until the user completes their profile.
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
/// Students: their class label, e.g. `XII-A1`. Null until chosen.
@override final  String? classId;
/// Extracurricular labels, e.g. `Masis-KIR`. Teachers: the ones they
/// supervise.
 final  List<String> _extracurriculars;
/// Extracurricular labels, e.g. `Masis-KIR`. Teachers: the ones they
/// supervise.
@override@JsonKey() List<String> get extracurriculars {
  if (_extracurriculars is EqualUnmodifiableListView) return _extracurriculars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extracurriculars);
}

/// Teachers: the class they are the homeroom teacher (wali kelas) of.
@override final  String? homeroomClass;
@override final  String? photoUrl;
/// False once a teacher removed the student from the school.
@override@JsonKey() final  bool active;
/// The version of the terms of use the user accepted; 0 when none.
/// Written by the `acceptTerms` callable only.
@override@JsonKey() final  int termsVersion;
/// The superadmin's profile in a school they opened. Left out of the
/// school's teacher list. Written by Cloud Functions only.
@override@JsonKey() final  bool superadmin;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.role, role) || other.role == role)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.classId, classId) || other.classId == classId)&&const DeepCollectionEquality().equals(other.extracurriculars, _extracurriculars)&&(identical(other.homeroomClass, homeroomClass) || other.homeroomClass == homeroomClass)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.active, active) || other.active == active)&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.superadmin, superadmin) || other.superadmin == superadmin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,role,name,email,classId,const DeepCollectionEquality().hash(_extracurriculars),homeroomClass,photoUrl,active,termsVersion,superadmin);
}

@override
String toString() {
    return 'AppUser(uid: $uid, role: $role, name: $name, email: $email, classId: $classId, extracurriculars: $extracurriculars, homeroomClass: $homeroomClass, photoUrl: $photoUrl, active: $active, termsVersion: $termsVersion, superadmin: $superadmin)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, UserRole role, String name, String email, String? classId, List<String> extracurriculars, String? homeroomClass, String? photoUrl, bool active, int termsVersion, bool superadmin
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? role = null,Object? name = null,Object? email = null,Object? classId = freezed,Object? extracurriculars = null,Object? homeroomClass = freezed,Object? photoUrl = freezed,Object? active = null,Object? termsVersion = null,Object? superadmin = null,}) {
  return _then(_AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,extracurriculars: null == extracurriculars ? _self._extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,homeroomClass: freezed == homeroomClass ? _self.homeroomClass : homeroomClass // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as int,superadmin: null == superadmin ? _self.superadmin : superadmin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
