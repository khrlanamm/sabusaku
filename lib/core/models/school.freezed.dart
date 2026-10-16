// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'school.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SchoolSettings {

/// 0 = Sunday … 6 = Saturday. Neutral days never break a streak.
 List<int> get neutralWeekdays;/// `yyyy-MM-dd`, sorted.
 List<String> get holidays; int get activeMaxDays; int get attentionMaxDays;
/// Create a copy of SchoolSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchoolSettingsCopyWith<SchoolSettings> get copyWith => _$SchoolSettingsCopyWithImpl<SchoolSettings>(this as SchoolSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SchoolSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchoolSettings&&const DeepCollectionEquality().equals(other.neutralWeekdays, _this.neutralWeekdays)&&const DeepCollectionEquality().equals(other.holidays, _this.holidays)&&(identical(other.activeMaxDays, _this.activeMaxDays) || other.activeMaxDays == _this.activeMaxDays)&&(identical(other.attentionMaxDays, _this.attentionMaxDays) || other.attentionMaxDays == _this.attentionMaxDays));
}


@override
int get hashCode {
  final _this = this as SchoolSettings;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.neutralWeekdays),const DeepCollectionEquality().hash(_this.holidays),_this.activeMaxDays,_this.attentionMaxDays);
}

@override
String toString() {
  final _this = this as SchoolSettings;
  return 'SchoolSettings(neutralWeekdays: ${_this.neutralWeekdays}, holidays: ${_this.holidays}, activeMaxDays: ${_this.activeMaxDays}, attentionMaxDays: ${_this.attentionMaxDays})';
}


}

/// @nodoc
abstract mixin class $SchoolSettingsCopyWith<$Res>  {
  factory $SchoolSettingsCopyWith(SchoolSettings value, $Res Function(SchoolSettings) _then) = _$SchoolSettingsCopyWithImpl;
@useResult
$Res call({
 List<int> neutralWeekdays, List<String> holidays, int activeMaxDays, int attentionMaxDays
});




}
/// @nodoc
class _$SchoolSettingsCopyWithImpl<$Res>
    implements $SchoolSettingsCopyWith<$Res> {
  _$SchoolSettingsCopyWithImpl(this._self, this._then);

  final SchoolSettings _self;
  final $Res Function(SchoolSettings) _then;

/// Create a copy of SchoolSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? neutralWeekdays = null,Object? holidays = null,Object? activeMaxDays = null,Object? attentionMaxDays = null,}) {
  return _then(SchoolSettings(
neutralWeekdays: null == neutralWeekdays ? _self.neutralWeekdays : neutralWeekdays // ignore: cast_nullable_to_non_nullable
as List<int>,holidays: null == holidays ? _self.holidays : holidays // ignore: cast_nullable_to_non_nullable
as List<String>,activeMaxDays: null == activeMaxDays ? _self.activeMaxDays : activeMaxDays // ignore: cast_nullable_to_non_nullable
as int,attentionMaxDays: null == attentionMaxDays ? _self.attentionMaxDays : attentionMaxDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SchoolSettings].
extension SchoolSettingsPatterns on SchoolSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchoolSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchoolSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchoolSettings value)  $default,){
final _that = this;
switch (_that) {
case _SchoolSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchoolSettings value)?  $default,){
final _that = this;
switch (_that) {
case _SchoolSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> neutralWeekdays,  List<String> holidays,  int activeMaxDays,  int attentionMaxDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchoolSettings() when $default != null:
return $default(_that.neutralWeekdays,_that.holidays,_that.activeMaxDays,_that.attentionMaxDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> neutralWeekdays,  List<String> holidays,  int activeMaxDays,  int attentionMaxDays)  $default,) {final _that = this;
switch (_that) {
case _SchoolSettings():
return $default(_that.neutralWeekdays,_that.holidays,_that.activeMaxDays,_that.attentionMaxDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> neutralWeekdays,  List<String> holidays,  int activeMaxDays,  int attentionMaxDays)?  $default,) {final _that = this;
switch (_that) {
case _SchoolSettings() when $default != null:
return $default(_that.neutralWeekdays,_that.holidays,_that.activeMaxDays,_that.attentionMaxDays);case _:
  return null;

}
}

}

/// @nodoc


class _SchoolSettings extends SchoolSettings {
  const _SchoolSettings({ List<int> neutralWeekdays = const <int>[0],  List<String> holidays = const <String>[], this.activeMaxDays = 3, this.attentionMaxDays = 7}): _neutralWeekdays = neutralWeekdays,_holidays = holidays,super._();
  

/// 0 = Sunday … 6 = Saturday. Neutral days never break a streak.
 final  List<int> _neutralWeekdays;
/// 0 = Sunday … 6 = Saturday. Neutral days never break a streak.
@override@JsonKey() List<int> get neutralWeekdays {
  if (_neutralWeekdays is EqualUnmodifiableListView) return _neutralWeekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_neutralWeekdays);
}

/// `yyyy-MM-dd`, sorted.
 final  List<String> _holidays;
/// `yyyy-MM-dd`, sorted.
@override@JsonKey() List<String> get holidays {
  if (_holidays is EqualUnmodifiableListView) return _holidays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_holidays);
}

@override@JsonKey() final  int activeMaxDays;
@override@JsonKey() final  int attentionMaxDays;

/// Create a copy of SchoolSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchoolSettingsCopyWith<_SchoolSettings> get copyWith => __$SchoolSettingsCopyWithImpl<_SchoolSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchoolSettings&&const DeepCollectionEquality().equals(other.neutralWeekdays, _neutralWeekdays)&&const DeepCollectionEquality().equals(other.holidays, _holidays)&&(identical(other.activeMaxDays, activeMaxDays) || other.activeMaxDays == activeMaxDays)&&(identical(other.attentionMaxDays, attentionMaxDays) || other.attentionMaxDays == attentionMaxDays));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_neutralWeekdays),const DeepCollectionEquality().hash(_holidays),activeMaxDays,attentionMaxDays);
}

@override
String toString() {
    return 'SchoolSettings(neutralWeekdays: $neutralWeekdays, holidays: $holidays, activeMaxDays: $activeMaxDays, attentionMaxDays: $attentionMaxDays)';
}


}

/// @nodoc
abstract mixin class _$SchoolSettingsCopyWith<$Res> implements $SchoolSettingsCopyWith<$Res> {
  factory _$SchoolSettingsCopyWith(_SchoolSettings value, $Res Function(_SchoolSettings) _then) = __$SchoolSettingsCopyWithImpl;
@override @useResult
$Res call({
 List<int> neutralWeekdays, List<String> holidays, int activeMaxDays, int attentionMaxDays
});




}
/// @nodoc
class __$SchoolSettingsCopyWithImpl<$Res>
    implements _$SchoolSettingsCopyWith<$Res> {
  __$SchoolSettingsCopyWithImpl(this._self, this._then);

  final _SchoolSettings _self;
  final $Res Function(_SchoolSettings) _then;

/// Create a copy of SchoolSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? neutralWeekdays = null,Object? holidays = null,Object? activeMaxDays = null,Object? attentionMaxDays = null,}) {
  return _then(_SchoolSettings(
neutralWeekdays: null == neutralWeekdays ? _self._neutralWeekdays : neutralWeekdays // ignore: cast_nullable_to_non_nullable
as List<int>,holidays: null == holidays ? _self._holidays : holidays // ignore: cast_nullable_to_non_nullable
as List<String>,activeMaxDays: null == activeMaxDays ? _self.activeMaxDays : activeMaxDays // ignore: cast_nullable_to_non_nullable
as int,attentionMaxDays: null == attentionMaxDays ? _self.attentionMaxDays : attentionMaxDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$School {

 String get id; String get name; bool get active; SchoolSettings get settings;/// Class labels (`XII-A1`), sorted by grade. Teachers add more.
 List<String> get classes;/// Extracurricular labels (`Masis-KIR`). Teachers add more.
 List<String> get extracurriculars;
/// Create a copy of School
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchoolCopyWith<School> get copyWith => _$SchoolCopyWithImpl<School>(this as School, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as School;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is School&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.active, _this.active) || other.active == _this.active)&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&const DeepCollectionEquality().equals(other.classes, _this.classes)&&const DeepCollectionEquality().equals(other.extracurriculars, _this.extracurriculars));
}


@override
int get hashCode {
  final _this = this as School;
  return Object.hash(runtimeType,_this.id,_this.name,_this.active,_this.settings,const DeepCollectionEquality().hash(_this.classes),const DeepCollectionEquality().hash(_this.extracurriculars));
}

@override
String toString() {
  final _this = this as School;
  return 'School(id: ${_this.id}, name: ${_this.name}, active: ${_this.active}, settings: ${_this.settings}, classes: ${_this.classes}, extracurriculars: ${_this.extracurriculars})';
}


}

/// @nodoc
abstract mixin class $SchoolCopyWith<$Res>  {
  factory $SchoolCopyWith(School value, $Res Function(School) _then) = _$SchoolCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool active, SchoolSettings settings, List<String> classes, List<String> extracurriculars
});


$SchoolSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$SchoolCopyWithImpl<$Res>
    implements $SchoolCopyWith<$Res> {
  _$SchoolCopyWithImpl(this._self, this._then);

  final School _self;
  final $Res Function(School) _then;

/// Create a copy of School
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? active = null,Object? settings = null,Object? classes = null,Object? extracurriculars = null,}) {
  return _then(School(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as SchoolSettings,classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as List<String>,extracurriculars: null == extracurriculars ? _self.extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of School
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SchoolSettingsCopyWith<$Res> get settings {
  
  return $SchoolSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [School].
extension SchoolPatterns on School {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _School value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _School() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _School value)  $default,){
final _that = this;
switch (_that) {
case _School():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _School value)?  $default,){
final _that = this;
switch (_that) {
case _School() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool active,  SchoolSettings settings,  List<String> classes,  List<String> extracurriculars)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _School() when $default != null:
return $default(_that.id,_that.name,_that.active,_that.settings,_that.classes,_that.extracurriculars);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool active,  SchoolSettings settings,  List<String> classes,  List<String> extracurriculars)  $default,) {final _that = this;
switch (_that) {
case _School():
return $default(_that.id,_that.name,_that.active,_that.settings,_that.classes,_that.extracurriculars);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool active,  SchoolSettings settings,  List<String> classes,  List<String> extracurriculars)?  $default,) {final _that = this;
switch (_that) {
case _School() when $default != null:
return $default(_that.id,_that.name,_that.active,_that.settings,_that.classes,_that.extracurriculars);case _:
  return null;

}
}

}

/// @nodoc


class _School implements School {
  const _School({required this.id, required this.name, this.active = true, this.settings = const SchoolSettings(),  List<String> classes = const <String>[],  List<String> extracurriculars = const <String>[]}): _classes = classes,_extracurriculars = extracurriculars;
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool active;
@override@JsonKey() final  SchoolSettings settings;
/// Class labels (`XII-A1`), sorted by grade. Teachers add more.
 final  List<String> _classes;
/// Class labels (`XII-A1`), sorted by grade. Teachers add more.
@override@JsonKey() List<String> get classes {
  if (_classes is EqualUnmodifiableListView) return _classes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classes);
}

/// Extracurricular labels (`Masis-KIR`). Teachers add more.
 final  List<String> _extracurriculars;
/// Extracurricular labels (`Masis-KIR`). Teachers add more.
@override@JsonKey() List<String> get extracurriculars {
  if (_extracurriculars is EqualUnmodifiableListView) return _extracurriculars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extracurriculars);
}


/// Create a copy of School
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchoolCopyWith<_School> get copyWith => __$SchoolCopyWithImpl<_School>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _School&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.active, active) || other.active == active)&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other.classes, _classes)&&const DeepCollectionEquality().equals(other.extracurriculars, _extracurriculars));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,active,settings,const DeepCollectionEquality().hash(_classes),const DeepCollectionEquality().hash(_extracurriculars));
}

@override
String toString() {
    return 'School(id: $id, name: $name, active: $active, settings: $settings, classes: $classes, extracurriculars: $extracurriculars)';
}


}

/// @nodoc
abstract mixin class _$SchoolCopyWith<$Res> implements $SchoolCopyWith<$Res> {
  factory _$SchoolCopyWith(_School value, $Res Function(_School) _then) = __$SchoolCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool active, SchoolSettings settings, List<String> classes, List<String> extracurriculars
});


@override $SchoolSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$SchoolCopyWithImpl<$Res>
    implements _$SchoolCopyWith<$Res> {
  __$SchoolCopyWithImpl(this._self, this._then);

  final _School _self;
  final $Res Function(_School) _then;

/// Create a copy of School
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? active = null,Object? settings = null,Object? classes = null,Object? extracurriculars = null,}) {
  return _then(_School(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as SchoolSettings,classes: null == classes ? _self._classes : classes // ignore: cast_nullable_to_non_nullable
as List<String>,extracurriculars: null == extracurriculars ? _self._extracurriculars : extracurriculars // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of School
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SchoolSettingsCopyWith<$Res> get settings {
  
  return $SchoolSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
