// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'school_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SchoolClass {

 String get id; String get name; int get grade; String get academicYear;/// Mirror of the teachers' `classIds`, for display only.
 List<String> get teacherIds; bool get isArchived;
/// Create a copy of SchoolClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchoolClassCopyWith<SchoolClass> get copyWith => _$SchoolClassCopyWithImpl<SchoolClass>(this as SchoolClass, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SchoolClass;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchoolClass&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.grade, _this.grade) || other.grade == _this.grade)&&(identical(other.academicYear, _this.academicYear) || other.academicYear == _this.academicYear)&&const DeepCollectionEquality().equals(other.teacherIds, _this.teacherIds)&&(identical(other.isArchived, _this.isArchived) || other.isArchived == _this.isArchived));
}


@override
int get hashCode {
  final _this = this as SchoolClass;
  return Object.hash(runtimeType,_this.id,_this.name,_this.grade,_this.academicYear,const DeepCollectionEquality().hash(_this.teacherIds),_this.isArchived);
}

@override
String toString() {
  final _this = this as SchoolClass;
  return 'SchoolClass(id: ${_this.id}, name: ${_this.name}, grade: ${_this.grade}, academicYear: ${_this.academicYear}, teacherIds: ${_this.teacherIds}, isArchived: ${_this.isArchived})';
}


}

/// @nodoc
abstract mixin class $SchoolClassCopyWith<$Res>  {
  factory $SchoolClassCopyWith(SchoolClass value, $Res Function(SchoolClass) _then) = _$SchoolClassCopyWithImpl;
@useResult
$Res call({
 String id, String name, int grade, String academicYear, List<String> teacherIds, bool isArchived
});




}
/// @nodoc
class _$SchoolClassCopyWithImpl<$Res>
    implements $SchoolClassCopyWith<$Res> {
  _$SchoolClassCopyWithImpl(this._self, this._then);

  final SchoolClass _self;
  final $Res Function(SchoolClass) _then;

/// Create a copy of SchoolClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? grade = null,Object? academicYear = null,Object? teacherIds = null,Object? isArchived = null,}) {
  return _then(SchoolClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as int,academicYear: null == academicYear ? _self.academicYear : academicYear // ignore: cast_nullable_to_non_nullable
as String,teacherIds: null == teacherIds ? _self.teacherIds : teacherIds // ignore: cast_nullable_to_non_nullable
as List<String>,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SchoolClass].
extension SchoolClassPatterns on SchoolClass {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchoolClass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchoolClass() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchoolClass value)  $default,){
final _that = this;
switch (_that) {
case _SchoolClass():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchoolClass value)?  $default,){
final _that = this;
switch (_that) {
case _SchoolClass() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int grade,  String academicYear,  List<String> teacherIds,  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchoolClass() when $default != null:
return $default(_that.id,_that.name,_that.grade,_that.academicYear,_that.teacherIds,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int grade,  String academicYear,  List<String> teacherIds,  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _SchoolClass():
return $default(_that.id,_that.name,_that.grade,_that.academicYear,_that.teacherIds,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int grade,  String academicYear,  List<String> teacherIds,  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _SchoolClass() when $default != null:
return $default(_that.id,_that.name,_that.grade,_that.academicYear,_that.teacherIds,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc


class _SchoolClass implements SchoolClass {
  const _SchoolClass({required this.id, required this.name, required this.grade, required this.academicYear,  List<String> teacherIds = const <String>[], this.isArchived = false}): _teacherIds = teacherIds;
  

@override final  String id;
@override final  String name;
@override final  int grade;
@override final  String academicYear;
/// Mirror of the teachers' `classIds`, for display only.
 final  List<String> _teacherIds;
/// Mirror of the teachers' `classIds`, for display only.
@override@JsonKey() List<String> get teacherIds {
  if (_teacherIds is EqualUnmodifiableListView) return _teacherIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teacherIds);
}

@override@JsonKey() final  bool isArchived;

/// Create a copy of SchoolClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchoolClassCopyWith<_SchoolClass> get copyWith => __$SchoolClassCopyWithImpl<_SchoolClass>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchoolClass&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.academicYear, academicYear) || other.academicYear == academicYear)&&const DeepCollectionEquality().equals(other.teacherIds, _teacherIds)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,grade,academicYear,const DeepCollectionEquality().hash(_teacherIds),isArchived);
}

@override
String toString() {
    return 'SchoolClass(id: $id, name: $name, grade: $grade, academicYear: $academicYear, teacherIds: $teacherIds, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$SchoolClassCopyWith<$Res> implements $SchoolClassCopyWith<$Res> {
  factory _$SchoolClassCopyWith(_SchoolClass value, $Res Function(_SchoolClass) _then) = __$SchoolClassCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int grade, String academicYear, List<String> teacherIds, bool isArchived
});




}
/// @nodoc
class __$SchoolClassCopyWithImpl<$Res>
    implements _$SchoolClassCopyWith<$Res> {
  __$SchoolClassCopyWithImpl(this._self, this._then);

  final _SchoolClass _self;
  final $Res Function(_SchoolClass) _then;

/// Create a copy of SchoolClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? grade = null,Object? academicYear = null,Object? teacherIds = null,Object? isArchived = null,}) {
  return _then(_SchoolClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as int,academicYear: null == academicYear ? _self.academicYear : academicYear // ignore: cast_nullable_to_non_nullable
as String,teacherIds: null == teacherIds ? _self._teacherIds : teacherIds // ignore: cast_nullable_to_non_nullable
as List<String>,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
