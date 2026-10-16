// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Report implements DiagnosticableTreeMixin {

 String get id; ReportKind get kind; ReportReason get reason; ReportTarget get target; String? get note; bool get resolved; String get reporterName; UserRole? get reporterRole;/// Whose content or account is reported; null for books and
/// suggestions.
 String? get subjectId;/// A copy of the content at report time (comment `text`, `authorName`;
/// journal `studentName`, `date`, `keyInformation`; book `title`,
/// `authors`, `coverUrl`; suggestion `title`, `coverUrl`; user `name`,
/// `role`). Emptied when the reported person's data is erased.
 Map<String, Object?> get snapshot; bool get targetDeleted; DateTime? get createdAt; DateTime? get resolvedAt; String? get resolvedByName; String? get resolution;
/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportCopyWith<Report> get copyWith => _$ReportCopyWithImpl<Report>(this as Report, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as Report;
  properties
    ..add(DiagnosticsProperty('type', 'Report'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('kind', _this.kind))..add(DiagnosticsProperty('reason', _this.reason))..add(DiagnosticsProperty('target', _this.target))..add(DiagnosticsProperty('note', _this.note))..add(DiagnosticsProperty('resolved', _this.resolved))..add(DiagnosticsProperty('reporterName', _this.reporterName))..add(DiagnosticsProperty('reporterRole', _this.reporterRole))..add(DiagnosticsProperty('subjectId', _this.subjectId))..add(DiagnosticsProperty('snapshot', _this.snapshot))..add(DiagnosticsProperty('targetDeleted', _this.targetDeleted))..add(DiagnosticsProperty('createdAt', _this.createdAt))..add(DiagnosticsProperty('resolvedAt', _this.resolvedAt))..add(DiagnosticsProperty('resolvedByName', _this.resolvedByName))..add(DiagnosticsProperty('resolution', _this.resolution));
}

@override
bool operator ==(Object other) {
  final _this = this as Report;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Report&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.resolved, _this.resolved) || other.resolved == _this.resolved)&&(identical(other.reporterName, _this.reporterName) || other.reporterName == _this.reporterName)&&(identical(other.reporterRole, _this.reporterRole) || other.reporterRole == _this.reporterRole)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&const DeepCollectionEquality().equals(other.snapshot, _this.snapshot)&&(identical(other.targetDeleted, _this.targetDeleted) || other.targetDeleted == _this.targetDeleted)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt)&&(identical(other.resolvedByName, _this.resolvedByName) || other.resolvedByName == _this.resolvedByName)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution));
}


@override
int get hashCode {
  final _this = this as Report;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.reason,_this.target,_this.note,_this.resolved,_this.reporterName,_this.reporterRole,_this.subjectId,const DeepCollectionEquality().hash(_this.snapshot),_this.targetDeleted,_this.createdAt,_this.resolvedAt,_this.resolvedByName,_this.resolution);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as Report;
  return 'Report(id: ${_this.id}, kind: ${_this.kind}, reason: ${_this.reason}, target: ${_this.target}, note: ${_this.note}, resolved: ${_this.resolved}, reporterName: ${_this.reporterName}, reporterRole: ${_this.reporterRole}, subjectId: ${_this.subjectId}, snapshot: ${_this.snapshot}, targetDeleted: ${_this.targetDeleted}, createdAt: ${_this.createdAt}, resolvedAt: ${_this.resolvedAt}, resolvedByName: ${_this.resolvedByName}, resolution: ${_this.resolution})';
}


}

/// @nodoc
abstract mixin class $ReportCopyWith<$Res>  {
  factory $ReportCopyWith(Report value, $Res Function(Report) _then) = _$ReportCopyWithImpl;
@useResult
$Res call({
 String id, ReportKind kind, ReportReason reason, ReportTarget target, String? note, bool resolved, String reporterName, UserRole? reporterRole, String? subjectId, Map<String, Object?> snapshot, bool targetDeleted, DateTime? createdAt, DateTime? resolvedAt, String? resolvedByName, String? resolution
});




}
/// @nodoc
class _$ReportCopyWithImpl<$Res>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._self, this._then);

  final Report _self;
  final $Res Function(Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? reason = null,Object? target = null,Object? note = freezed,Object? resolved = null,Object? reporterName = null,Object? reporterRole = freezed,Object? subjectId = freezed,Object? snapshot = null,Object? targetDeleted = null,Object? createdAt = freezed,Object? resolvedAt = freezed,Object? resolvedByName = freezed,Object? resolution = freezed,}) {
  return _then(Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReportKind,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ReportTarget,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,resolved: null == resolved ? _self.resolved : resolved // ignore: cast_nullable_to_non_nullable
as bool,reporterName: null == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String,reporterRole: freezed == reporterRole ? _self.reporterRole : reporterRole // ignore: cast_nullable_to_non_nullable
as UserRole?,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,targetDeleted: null == targetDeleted ? _self.targetDeleted : targetDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedByName: freezed == resolvedByName ? _self.resolvedByName : resolvedByName // ignore: cast_nullable_to_non_nullable
as String?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Report].
extension ReportPatterns on Report {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Report value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Report() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Report value)  $default,){
final _that = this;
switch (_that) {
case _Report():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Report value)?  $default,){
final _that = this;
switch (_that) {
case _Report() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ReportKind kind,  ReportReason reason,  ReportTarget target,  String? note,  bool resolved,  String reporterName,  UserRole? reporterRole,  String? subjectId,  Map<String, Object?> snapshot,  bool targetDeleted,  DateTime? createdAt,  DateTime? resolvedAt,  String? resolvedByName,  String? resolution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.kind,_that.reason,_that.target,_that.note,_that.resolved,_that.reporterName,_that.reporterRole,_that.subjectId,_that.snapshot,_that.targetDeleted,_that.createdAt,_that.resolvedAt,_that.resolvedByName,_that.resolution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ReportKind kind,  ReportReason reason,  ReportTarget target,  String? note,  bool resolved,  String reporterName,  UserRole? reporterRole,  String? subjectId,  Map<String, Object?> snapshot,  bool targetDeleted,  DateTime? createdAt,  DateTime? resolvedAt,  String? resolvedByName,  String? resolution)  $default,) {final _that = this;
switch (_that) {
case _Report():
return $default(_that.id,_that.kind,_that.reason,_that.target,_that.note,_that.resolved,_that.reporterName,_that.reporterRole,_that.subjectId,_that.snapshot,_that.targetDeleted,_that.createdAt,_that.resolvedAt,_that.resolvedByName,_that.resolution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ReportKind kind,  ReportReason reason,  ReportTarget target,  String? note,  bool resolved,  String reporterName,  UserRole? reporterRole,  String? subjectId,  Map<String, Object?> snapshot,  bool targetDeleted,  DateTime? createdAt,  DateTime? resolvedAt,  String? resolvedByName,  String? resolution)?  $default,) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.kind,_that.reason,_that.target,_that.note,_that.resolved,_that.reporterName,_that.reporterRole,_that.subjectId,_that.snapshot,_that.targetDeleted,_that.createdAt,_that.resolvedAt,_that.resolvedByName,_that.resolution);case _:
  return null;

}
}

}

/// @nodoc


class _Report extends Report with DiagnosticableTreeMixin {
  const _Report({required this.id, required this.kind, required this.reason, required this.target, this.note, this.resolved = false, this.reporterName = '', this.reporterRole, this.subjectId,  Map<String, Object?> snapshot = const <String, Object?>{}, this.targetDeleted = false, this.createdAt, this.resolvedAt, this.resolvedByName, this.resolution}): _snapshot = snapshot,super._();
  

@override final  String id;
@override final  ReportKind kind;
@override final  ReportReason reason;
@override final  ReportTarget target;
@override final  String? note;
@override@JsonKey() final  bool resolved;
@override@JsonKey() final  String reporterName;
@override final  UserRole? reporterRole;
/// Whose content or account is reported; null for books and
/// suggestions.
@override final  String? subjectId;
/// A copy of the content at report time (comment `text`, `authorName`;
/// journal `studentName`, `date`, `keyInformation`; book `title`,
/// `authors`, `coverUrl`; suggestion `title`, `coverUrl`; user `name`,
/// `role`). Emptied when the reported person's data is erased.
 final  Map<String, Object?> _snapshot;
/// A copy of the content at report time (comment `text`, `authorName`;
/// journal `studentName`, `date`, `keyInformation`; book `title`,
/// `authors`, `coverUrl`; suggestion `title`, `coverUrl`; user `name`,
/// `role`). Emptied when the reported person's data is erased.
@override@JsonKey() Map<String, Object?> get snapshot {
  if (_snapshot is EqualUnmodifiableMapView) return _snapshot;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_snapshot);
}

@override@JsonKey() final  bool targetDeleted;
@override final  DateTime? createdAt;
@override final  DateTime? resolvedAt;
@override final  String? resolvedByName;
@override final  String? resolution;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportCopyWith<_Report> get copyWith => __$ReportCopyWithImpl<_Report>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'Report'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('kind', kind))..add(DiagnosticsProperty('reason', reason))..add(DiagnosticsProperty('target', target))..add(DiagnosticsProperty('note', note))..add(DiagnosticsProperty('resolved', resolved))..add(DiagnosticsProperty('reporterName', reporterName))..add(DiagnosticsProperty('reporterRole', reporterRole))..add(DiagnosticsProperty('subjectId', subjectId))..add(DiagnosticsProperty('snapshot', snapshot))..add(DiagnosticsProperty('targetDeleted', targetDeleted))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('resolvedAt', resolvedAt))..add(DiagnosticsProperty('resolvedByName', resolvedByName))..add(DiagnosticsProperty('resolution', resolution));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Report&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.target, target) || other.target == target)&&(identical(other.note, note) || other.note == note)&&(identical(other.resolved, resolved) || other.resolved == resolved)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.reporterRole, reporterRole) || other.reporterRole == reporterRole)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&const DeepCollectionEquality().equals(other.snapshot, _snapshot)&&(identical(other.targetDeleted, targetDeleted) || other.targetDeleted == targetDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolvedByName, resolvedByName) || other.resolvedByName == resolvedByName)&&(identical(other.resolution, resolution) || other.resolution == resolution));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,reason,target,note,resolved,reporterName,reporterRole,subjectId,const DeepCollectionEquality().hash(_snapshot),targetDeleted,createdAt,resolvedAt,resolvedByName,resolution);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'Report(id: $id, kind: $kind, reason: $reason, target: $target, note: $note, resolved: $resolved, reporterName: $reporterName, reporterRole: $reporterRole, subjectId: $subjectId, snapshot: $snapshot, targetDeleted: $targetDeleted, createdAt: $createdAt, resolvedAt: $resolvedAt, resolvedByName: $resolvedByName, resolution: $resolution)';
}


}

/// @nodoc
abstract mixin class _$ReportCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$ReportCopyWith(_Report value, $Res Function(_Report) _then) = __$ReportCopyWithImpl;
@override @useResult
$Res call({
 String id, ReportKind kind, ReportReason reason, ReportTarget target, String? note, bool resolved, String reporterName, UserRole? reporterRole, String? subjectId, Map<String, Object?> snapshot, bool targetDeleted, DateTime? createdAt, DateTime? resolvedAt, String? resolvedByName, String? resolution
});




}
/// @nodoc
class __$ReportCopyWithImpl<$Res>
    implements _$ReportCopyWith<$Res> {
  __$ReportCopyWithImpl(this._self, this._then);

  final _Report _self;
  final $Res Function(_Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? reason = null,Object? target = null,Object? note = freezed,Object? resolved = null,Object? reporterName = null,Object? reporterRole = freezed,Object? subjectId = freezed,Object? snapshot = null,Object? targetDeleted = null,Object? createdAt = freezed,Object? resolvedAt = freezed,Object? resolvedByName = freezed,Object? resolution = freezed,}) {
  return _then(_Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReportKind,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ReportTarget,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,resolved: null == resolved ? _self.resolved : resolved // ignore: cast_nullable_to_non_nullable
as bool,reporterName: null == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String,reporterRole: freezed == reporterRole ? _self.reporterRole : reporterRole // ignore: cast_nullable_to_non_nullable
as UserRole?,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,snapshot: null == snapshot ? _self._snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,targetDeleted: null == targetDeleted ? _self.targetDeleted : targetDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedByName: freezed == resolvedByName ? _self.resolvedByName : resolvedByName // ignore: cast_nullable_to_non_nullable
as String?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
