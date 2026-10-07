// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Credential {

 String get name; String get username; String get password; UserRole get role; String get className;
/// Create a copy of Credential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialCopyWith<Credential> get copyWith => _$CredentialCopyWithImpl<Credential>(this as Credential, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Credential;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Credential&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.password, _this.password) || other.password == _this.password)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.className, _this.className) || other.className == _this.className));
}


@override
int get hashCode {
  final _this = this as Credential;
  return Object.hash(runtimeType,_this.name,_this.username,_this.password,_this.role,_this.className);
}

@override
String toString() {
  final _this = this as Credential;
  return 'Credential(name: ${_this.name}, username: ${_this.username}, password: ${_this.password}, role: ${_this.role}, className: ${_this.className})';
}


}

/// @nodoc
abstract mixin class $CredentialCopyWith<$Res>  {
  factory $CredentialCopyWith(Credential value, $Res Function(Credential) _then) = _$CredentialCopyWithImpl;
@useResult
$Res call({
 String name, String username, String password, UserRole role, String className
});




}
/// @nodoc
class _$CredentialCopyWithImpl<$Res>
    implements $CredentialCopyWith<$Res> {
  _$CredentialCopyWithImpl(this._self, this._then);

  final Credential _self;
  final $Res Function(Credential) _then;

/// Create a copy of Credential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? username = null,Object? password = null,Object? role = null,Object? className = null,}) {
  return _then(Credential(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Credential].
extension CredentialPatterns on Credential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Credential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Credential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Credential value)  $default,){
final _that = this;
switch (_that) {
case _Credential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Credential value)?  $default,){
final _that = this;
switch (_that) {
case _Credential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String username,  String password,  UserRole role,  String className)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Credential() when $default != null:
return $default(_that.name,_that.username,_that.password,_that.role,_that.className);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String username,  String password,  UserRole role,  String className)  $default,) {final _that = this;
switch (_that) {
case _Credential():
return $default(_that.name,_that.username,_that.password,_that.role,_that.className);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String username,  String password,  UserRole role,  String className)?  $default,) {final _that = this;
switch (_that) {
case _Credential() when $default != null:
return $default(_that.name,_that.username,_that.password,_that.role,_that.className);case _:
  return null;

}
}

}

/// @nodoc


class _Credential implements Credential {
  const _Credential({required this.name, required this.username, required this.password, required this.role, this.className = ''});
  

@override final  String name;
@override final  String username;
@override final  String password;
@override final  UserRole role;
@override@JsonKey() final  String className;

/// Create a copy of Credential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialCopyWith<_Credential> get copyWith => __$CredentialCopyWithImpl<_Credential>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Credential&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.role, role) || other.role == role)&&(identical(other.className, className) || other.className == className));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,username,password,role,className);
}

@override
String toString() {
    return 'Credential(name: $name, username: $username, password: $password, role: $role, className: $className)';
}


}

/// @nodoc
abstract mixin class _$CredentialCopyWith<$Res> implements $CredentialCopyWith<$Res> {
  factory _$CredentialCopyWith(_Credential value, $Res Function(_Credential) _then) = __$CredentialCopyWithImpl;
@override @useResult
$Res call({
 String name, String username, String password, UserRole role, String className
});




}
/// @nodoc
class __$CredentialCopyWithImpl<$Res>
    implements _$CredentialCopyWith<$Res> {
  __$CredentialCopyWithImpl(this._self, this._then);

  final _Credential _self;
  final $Res Function(_Credential) _then;

/// Create a copy of Credential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? username = null,Object? password = null,Object? role = null,Object? className = null,}) {
  return _then(_Credential(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
