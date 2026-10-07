// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JournalDraft {

 String get date; int get pageStart; int get pageEnd; DurationRange get durationRange; String get keyInformation; String get reflection; String get question;
/// Create a copy of JournalDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalDraftCopyWith<JournalDraft> get copyWith => _$JournalDraftCopyWithImpl<JournalDraft>(this as JournalDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JournalDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalDraft&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.pageStart, _this.pageStart) || other.pageStart == _this.pageStart)&&(identical(other.pageEnd, _this.pageEnd) || other.pageEnd == _this.pageEnd)&&(identical(other.durationRange, _this.durationRange) || other.durationRange == _this.durationRange)&&(identical(other.keyInformation, _this.keyInformation) || other.keyInformation == _this.keyInformation)&&(identical(other.reflection, _this.reflection) || other.reflection == _this.reflection)&&(identical(other.question, _this.question) || other.question == _this.question));
}


@override
int get hashCode {
  final _this = this as JournalDraft;
  return Object.hash(runtimeType,_this.date,_this.pageStart,_this.pageEnd,_this.durationRange,_this.keyInformation,_this.reflection,_this.question);
}

@override
String toString() {
  final _this = this as JournalDraft;
  return 'JournalDraft(date: ${_this.date}, pageStart: ${_this.pageStart}, pageEnd: ${_this.pageEnd}, durationRange: ${_this.durationRange}, keyInformation: ${_this.keyInformation}, reflection: ${_this.reflection}, question: ${_this.question})';
}


}

/// @nodoc
abstract mixin class $JournalDraftCopyWith<$Res>  {
  factory $JournalDraftCopyWith(JournalDraft value, $Res Function(JournalDraft) _then) = _$JournalDraftCopyWithImpl;
@useResult
$Res call({
 String date, int pageStart, int pageEnd, DurationRange durationRange, String keyInformation, String reflection, String question
});




}
/// @nodoc
class _$JournalDraftCopyWithImpl<$Res>
    implements $JournalDraftCopyWith<$Res> {
  _$JournalDraftCopyWithImpl(this._self, this._then);

  final JournalDraft _self;
  final $Res Function(JournalDraft) _then;

/// Create a copy of JournalDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? pageStart = null,Object? pageEnd = null,Object? durationRange = null,Object? keyInformation = null,Object? reflection = null,Object? question = null,}) {
  return _then(JournalDraft(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,pageStart: null == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int,pageEnd: null == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int,durationRange: null == durationRange ? _self.durationRange : durationRange // ignore: cast_nullable_to_non_nullable
as DurationRange,keyInformation: null == keyInformation ? _self.keyInformation : keyInformation // ignore: cast_nullable_to_non_nullable
as String,reflection: null == reflection ? _self.reflection : reflection // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalDraft].
extension JournalDraftPatterns on JournalDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalDraft value)  $default,){
final _that = this;
switch (_that) {
case _JournalDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalDraft value)?  $default,){
final _that = this;
switch (_that) {
case _JournalDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int pageStart,  int pageEnd,  DurationRange durationRange,  String keyInformation,  String reflection,  String question)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalDraft() when $default != null:
return $default(_that.date,_that.pageStart,_that.pageEnd,_that.durationRange,_that.keyInformation,_that.reflection,_that.question);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int pageStart,  int pageEnd,  DurationRange durationRange,  String keyInformation,  String reflection,  String question)  $default,) {final _that = this;
switch (_that) {
case _JournalDraft():
return $default(_that.date,_that.pageStart,_that.pageEnd,_that.durationRange,_that.keyInformation,_that.reflection,_that.question);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int pageStart,  int pageEnd,  DurationRange durationRange,  String keyInformation,  String reflection,  String question)?  $default,) {final _that = this;
switch (_that) {
case _JournalDraft() when $default != null:
return $default(_that.date,_that.pageStart,_that.pageEnd,_that.durationRange,_that.keyInformation,_that.reflection,_that.question);case _:
  return null;

}
}

}

/// @nodoc


class _JournalDraft extends JournalDraft {
  const _JournalDraft({required this.date, required this.pageStart, required this.pageEnd, required this.durationRange, required this.keyInformation, this.reflection = '', this.question = ''}): super._();
  

@override final  String date;
@override final  int pageStart;
@override final  int pageEnd;
@override final  DurationRange durationRange;
@override final  String keyInformation;
@override@JsonKey() final  String reflection;
@override@JsonKey() final  String question;

/// Create a copy of JournalDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalDraftCopyWith<_JournalDraft> get copyWith => __$JournalDraftCopyWithImpl<_JournalDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalDraft&&(identical(other.date, date) || other.date == date)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd)&&(identical(other.durationRange, durationRange) || other.durationRange == durationRange)&&(identical(other.keyInformation, keyInformation) || other.keyInformation == keyInformation)&&(identical(other.reflection, reflection) || other.reflection == reflection)&&(identical(other.question, question) || other.question == question));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date,pageStart,pageEnd,durationRange,keyInformation,reflection,question);
}

@override
String toString() {
    return 'JournalDraft(date: $date, pageStart: $pageStart, pageEnd: $pageEnd, durationRange: $durationRange, keyInformation: $keyInformation, reflection: $reflection, question: $question)';
}


}

/// @nodoc
abstract mixin class _$JournalDraftCopyWith<$Res> implements $JournalDraftCopyWith<$Res> {
  factory _$JournalDraftCopyWith(_JournalDraft value, $Res Function(_JournalDraft) _then) = __$JournalDraftCopyWithImpl;
@override @useResult
$Res call({
 String date, int pageStart, int pageEnd, DurationRange durationRange, String keyInformation, String reflection, String question
});




}
/// @nodoc
class __$JournalDraftCopyWithImpl<$Res>
    implements _$JournalDraftCopyWith<$Res> {
  __$JournalDraftCopyWithImpl(this._self, this._then);

  final _JournalDraft _self;
  final $Res Function(_JournalDraft) _then;

/// Create a copy of JournalDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? pageStart = null,Object? pageEnd = null,Object? durationRange = null,Object? keyInformation = null,Object? reflection = null,Object? question = null,}) {
  return _then(_JournalDraft(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,pageStart: null == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int,pageEnd: null == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int,durationRange: null == durationRange ? _self.durationRange : durationRange // ignore: cast_nullable_to_non_nullable
as DurationRange,keyInformation: null == keyInformation ? _self.keyInformation : keyInformation // ignore: cast_nullable_to_non_nullable
as String,reflection: null == reflection ? _self.reflection : reflection // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
