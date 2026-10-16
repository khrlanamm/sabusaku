// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Session {

 String get uid; UserRole get role; String get schoolId; AppUser get profile;/// The account can sign in with email and password. Google-only
/// accounts must add a password first.
 bool get hasPassword;/// The account is linked to Google (offers "Pakai foto Google").
 bool get hasGoogle;/// The photo of the linked Google account, if any.
 String? get googlePhotoUrl;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Session;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.schoolId, _this.schoolId) || other.schoolId == _this.schoolId)&&(identical(other.profile, _this.profile) || other.profile == _this.profile)&&(identical(other.hasPassword, _this.hasPassword) || other.hasPassword == _this.hasPassword)&&(identical(other.hasGoogle, _this.hasGoogle) || other.hasGoogle == _this.hasGoogle)&&(identical(other.googlePhotoUrl, _this.googlePhotoUrl) || other.googlePhotoUrl == _this.googlePhotoUrl));
}


@override
int get hashCode {
  final _this = this as Session;
  return Object.hash(runtimeType,_this.uid,_this.role,_this.schoolId,_this.profile,_this.hasPassword,_this.hasGoogle,_this.googlePhotoUrl);
}

@override
String toString() {
  final _this = this as Session;
  return 'Session(uid: ${_this.uid}, role: ${_this.role}, schoolId: ${_this.schoolId}, profile: ${_this.profile}, hasPassword: ${_this.hasPassword}, hasGoogle: ${_this.hasGoogle}, googlePhotoUrl: ${_this.googlePhotoUrl})';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 String uid, UserRole role, String schoolId, AppUser profile, bool hasPassword, bool hasGoogle, String? googlePhotoUrl
});


$AppUserCopyWith<$Res> get profile;

}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? role = null,Object? schoolId = null,Object? profile = null,Object? hasPassword = null,Object? hasGoogle = null,Object? googlePhotoUrl = freezed,}) {
  return _then(Session(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,schoolId: null == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AppUser,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,hasGoogle: null == hasGoogle ? _self.hasGoogle : hasGoogle // ignore: cast_nullable_to_non_nullable
as bool,googlePhotoUrl: freezed == googlePhotoUrl ? _self.googlePhotoUrl : googlePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUserCopyWith<$Res> get profile {
  
  return $AppUserCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  UserRole role,  String schoolId,  AppUser profile,  bool hasPassword,  bool hasGoogle,  String? googlePhotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.uid,_that.role,_that.schoolId,_that.profile,_that.hasPassword,_that.hasGoogle,_that.googlePhotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  UserRole role,  String schoolId,  AppUser profile,  bool hasPassword,  bool hasGoogle,  String? googlePhotoUrl)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.uid,_that.role,_that.schoolId,_that.profile,_that.hasPassword,_that.hasGoogle,_that.googlePhotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  UserRole role,  String schoolId,  AppUser profile,  bool hasPassword,  bool hasGoogle,  String? googlePhotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.uid,_that.role,_that.schoolId,_that.profile,_that.hasPassword,_that.hasGoogle,_that.googlePhotoUrl);case _:
  return null;

}
}

}

/// @nodoc


class _Session extends Session {
  const _Session({required this.uid, required this.role, required this.schoolId, required this.profile, this.hasPassword = true, this.hasGoogle = false, this.googlePhotoUrl}): super._();
  

@override final  String uid;
@override final  UserRole role;
@override final  String schoolId;
@override final  AppUser profile;
/// The account can sign in with email and password. Google-only
/// accounts must add a password first.
@override@JsonKey() final  bool hasPassword;
/// The account is linked to Google (offers "Pakai foto Google").
@override@JsonKey() final  bool hasGoogle;
/// The photo of the linked Google account, if any.
@override final  String? googlePhotoUrl;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.role, role) || other.role == role)&&(identical(other.schoolId, schoolId) || other.schoolId == schoolId)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword)&&(identical(other.hasGoogle, hasGoogle) || other.hasGoogle == hasGoogle)&&(identical(other.googlePhotoUrl, googlePhotoUrl) || other.googlePhotoUrl == googlePhotoUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,role,schoolId,profile,hasPassword,hasGoogle,googlePhotoUrl);
}

@override
String toString() {
    return 'Session(uid: $uid, role: $role, schoolId: $schoolId, profile: $profile, hasPassword: $hasPassword, hasGoogle: $hasGoogle, googlePhotoUrl: $googlePhotoUrl)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 String uid, UserRole role, String schoolId, AppUser profile, bool hasPassword, bool hasGoogle, String? googlePhotoUrl
});


@override $AppUserCopyWith<$Res> get profile;

}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? role = null,Object? schoolId = null,Object? profile = null,Object? hasPassword = null,Object? hasGoogle = null,Object? googlePhotoUrl = freezed,}) {
  return _then(_Session(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,schoolId: null == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AppUser,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,hasGoogle: null == hasGoogle ? _self.hasGoogle : hasGoogle // ignore: cast_nullable_to_non_nullable
as bool,googlePhotoUrl: freezed == googlePhotoUrl ? _self.googlePhotoUrl : googlePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUserCopyWith<$Res> get profile {
  
  return $AppUserCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
