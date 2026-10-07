// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveProgramSummary {

 String get programId; String get title; String get author; int get totalPages; int get currentPage; int get percent; String get startDate; String get targetDate; bool get extended; bool get overdue;
/// Create a copy of ActiveProgramSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveProgramSummaryCopyWith<ActiveProgramSummary> get copyWith => _$ActiveProgramSummaryCopyWithImpl<ActiveProgramSummary>(this as ActiveProgramSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActiveProgramSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveProgramSummary&&(identical(other.programId, _this.programId) || other.programId == _this.programId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.totalPages, _this.totalPages) || other.totalPages == _this.totalPages)&&(identical(other.currentPage, _this.currentPage) || other.currentPage == _this.currentPage)&&(identical(other.percent, _this.percent) || other.percent == _this.percent)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.targetDate, _this.targetDate) || other.targetDate == _this.targetDate)&&(identical(other.extended, _this.extended) || other.extended == _this.extended)&&(identical(other.overdue, _this.overdue) || other.overdue == _this.overdue));
}


@override
int get hashCode {
  final _this = this as ActiveProgramSummary;
  return Object.hash(runtimeType,_this.programId,_this.title,_this.author,_this.totalPages,_this.currentPage,_this.percent,_this.startDate,_this.targetDate,_this.extended,_this.overdue);
}

@override
String toString() {
  final _this = this as ActiveProgramSummary;
  return 'ActiveProgramSummary(programId: ${_this.programId}, title: ${_this.title}, author: ${_this.author}, totalPages: ${_this.totalPages}, currentPage: ${_this.currentPage}, percent: ${_this.percent}, startDate: ${_this.startDate}, targetDate: ${_this.targetDate}, extended: ${_this.extended}, overdue: ${_this.overdue})';
}


}

/// @nodoc
abstract mixin class $ActiveProgramSummaryCopyWith<$Res>  {
  factory $ActiveProgramSummaryCopyWith(ActiveProgramSummary value, $Res Function(ActiveProgramSummary) _then) = _$ActiveProgramSummaryCopyWithImpl;
@useResult
$Res call({
 String programId, String title, String author, int totalPages, int currentPage, int percent, String startDate, String targetDate, bool extended, bool overdue
});




}
/// @nodoc
class _$ActiveProgramSummaryCopyWithImpl<$Res>
    implements $ActiveProgramSummaryCopyWith<$Res> {
  _$ActiveProgramSummaryCopyWithImpl(this._self, this._then);

  final ActiveProgramSummary _self;
  final $Res Function(ActiveProgramSummary) _then;

/// Create a copy of ActiveProgramSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programId = null,Object? title = null,Object? author = null,Object? totalPages = null,Object? currentPage = null,Object? percent = null,Object? startDate = null,Object? targetDate = null,Object? extended = null,Object? overdue = null,}) {
  return _then(ActiveProgramSummary(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,targetDate: null == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String,extended: null == extended ? _self.extended : extended // ignore: cast_nullable_to_non_nullable
as bool,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ActiveProgramSummary].
extension ActiveProgramSummaryPatterns on ActiveProgramSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveProgramSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveProgramSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveProgramSummary value)  $default,){
final _that = this;
switch (_that) {
case _ActiveProgramSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveProgramSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveProgramSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String programId,  String title,  String author,  int totalPages,  int currentPage,  int percent,  String startDate,  String targetDate,  bool extended,  bool overdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveProgramSummary() when $default != null:
return $default(_that.programId,_that.title,_that.author,_that.totalPages,_that.currentPage,_that.percent,_that.startDate,_that.targetDate,_that.extended,_that.overdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String programId,  String title,  String author,  int totalPages,  int currentPage,  int percent,  String startDate,  String targetDate,  bool extended,  bool overdue)  $default,) {final _that = this;
switch (_that) {
case _ActiveProgramSummary():
return $default(_that.programId,_that.title,_that.author,_that.totalPages,_that.currentPage,_that.percent,_that.startDate,_that.targetDate,_that.extended,_that.overdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String programId,  String title,  String author,  int totalPages,  int currentPage,  int percent,  String startDate,  String targetDate,  bool extended,  bool overdue)?  $default,) {final _that = this;
switch (_that) {
case _ActiveProgramSummary() when $default != null:
return $default(_that.programId,_that.title,_that.author,_that.totalPages,_that.currentPage,_that.percent,_that.startDate,_that.targetDate,_that.extended,_that.overdue);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveProgramSummary implements ActiveProgramSummary {
  const _ActiveProgramSummary({required this.programId, required this.title, required this.author, required this.totalPages, required this.currentPage, required this.percent, required this.startDate, required this.targetDate, this.extended = false, this.overdue = false});
  

@override final  String programId;
@override final  String title;
@override final  String author;
@override final  int totalPages;
@override final  int currentPage;
@override final  int percent;
@override final  String startDate;
@override final  String targetDate;
@override@JsonKey() final  bool extended;
@override@JsonKey() final  bool overdue;

/// Create a copy of ActiveProgramSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveProgramSummaryCopyWith<_ActiveProgramSummary> get copyWith => __$ActiveProgramSummaryCopyWithImpl<_ActiveProgramSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveProgramSummary&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.extended, extended) || other.extended == extended)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,programId,title,author,totalPages,currentPage,percent,startDate,targetDate,extended,overdue);
}

@override
String toString() {
    return 'ActiveProgramSummary(programId: $programId, title: $title, author: $author, totalPages: $totalPages, currentPage: $currentPage, percent: $percent, startDate: $startDate, targetDate: $targetDate, extended: $extended, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class _$ActiveProgramSummaryCopyWith<$Res> implements $ActiveProgramSummaryCopyWith<$Res> {
  factory _$ActiveProgramSummaryCopyWith(_ActiveProgramSummary value, $Res Function(_ActiveProgramSummary) _then) = __$ActiveProgramSummaryCopyWithImpl;
@override @useResult
$Res call({
 String programId, String title, String author, int totalPages, int currentPage, int percent, String startDate, String targetDate, bool extended, bool overdue
});




}
/// @nodoc
class __$ActiveProgramSummaryCopyWithImpl<$Res>
    implements _$ActiveProgramSummaryCopyWith<$Res> {
  __$ActiveProgramSummaryCopyWithImpl(this._self, this._then);

  final _ActiveProgramSummary _self;
  final $Res Function(_ActiveProgramSummary) _then;

/// Create a copy of ActiveProgramSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programId = null,Object? title = null,Object? author = null,Object? totalPages = null,Object? currentPage = null,Object? percent = null,Object? startDate = null,Object? targetDate = null,Object? extended = null,Object? overdue = null,}) {
  return _then(_ActiveProgramSummary(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,targetDate: null == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String,extended: null == extended ? _self.extended : extended // ignore: cast_nullable_to_non_nullable
as bool,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$StudentStats {

 String get studentId; String get name; String? get nis; String? get classId; String? get className; StudentStatus get status; int get daysSinceLastJournal; ActiveProgramSummary? get activeProgram; int get streakCurrent; int get streakBest; String? get lastJournalDate; int get journalCountMonth; int get journalCountTotal; int get booksCompleted;/// The five most recent journal dates, newest first.
 List<String> get recentDates;
/// Create a copy of StudentStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentStatsCopyWith<StudentStats> get copyWith => _$StudentStatsCopyWithImpl<StudentStats>(this as StudentStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StudentStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentStats&&(identical(other.studentId, _this.studentId) || other.studentId == _this.studentId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.nis, _this.nis) || other.nis == _this.nis)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&(identical(other.className, _this.className) || other.className == _this.className)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.daysSinceLastJournal, _this.daysSinceLastJournal) || other.daysSinceLastJournal == _this.daysSinceLastJournal)&&(identical(other.activeProgram, _this.activeProgram) || other.activeProgram == _this.activeProgram)&&(identical(other.streakCurrent, _this.streakCurrent) || other.streakCurrent == _this.streakCurrent)&&(identical(other.streakBest, _this.streakBest) || other.streakBest == _this.streakBest)&&(identical(other.lastJournalDate, _this.lastJournalDate) || other.lastJournalDate == _this.lastJournalDate)&&(identical(other.journalCountMonth, _this.journalCountMonth) || other.journalCountMonth == _this.journalCountMonth)&&(identical(other.journalCountTotal, _this.journalCountTotal) || other.journalCountTotal == _this.journalCountTotal)&&(identical(other.booksCompleted, _this.booksCompleted) || other.booksCompleted == _this.booksCompleted)&&const DeepCollectionEquality().equals(other.recentDates, _this.recentDates));
}


@override
int get hashCode {
  final _this = this as StudentStats;
  return Object.hash(runtimeType,_this.studentId,_this.name,_this.nis,_this.classId,_this.className,_this.status,_this.daysSinceLastJournal,_this.activeProgram,_this.streakCurrent,_this.streakBest,_this.lastJournalDate,_this.journalCountMonth,_this.journalCountTotal,_this.booksCompleted,const DeepCollectionEquality().hash(_this.recentDates));
}

@override
String toString() {
  final _this = this as StudentStats;
  return 'StudentStats(studentId: ${_this.studentId}, name: ${_this.name}, nis: ${_this.nis}, classId: ${_this.classId}, className: ${_this.className}, status: ${_this.status}, daysSinceLastJournal: ${_this.daysSinceLastJournal}, activeProgram: ${_this.activeProgram}, streakCurrent: ${_this.streakCurrent}, streakBest: ${_this.streakBest}, lastJournalDate: ${_this.lastJournalDate}, journalCountMonth: ${_this.journalCountMonth}, journalCountTotal: ${_this.journalCountTotal}, booksCompleted: ${_this.booksCompleted}, recentDates: ${_this.recentDates})';
}


}

/// @nodoc
abstract mixin class $StudentStatsCopyWith<$Res>  {
  factory $StudentStatsCopyWith(StudentStats value, $Res Function(StudentStats) _then) = _$StudentStatsCopyWithImpl;
@useResult
$Res call({
 String studentId, String name, String? nis, String? classId, String? className, StudentStatus status, int daysSinceLastJournal, ActiveProgramSummary? activeProgram, int streakCurrent, int streakBest, String? lastJournalDate, int journalCountMonth, int journalCountTotal, int booksCompleted, List<String> recentDates
});


$ActiveProgramSummaryCopyWith<$Res>? get activeProgram;

}
/// @nodoc
class _$StudentStatsCopyWithImpl<$Res>
    implements $StudentStatsCopyWith<$Res> {
  _$StudentStatsCopyWithImpl(this._self, this._then);

  final StudentStats _self;
  final $Res Function(StudentStats) _then;

/// Create a copy of StudentStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? studentId = null,Object? name = null,Object? nis = freezed,Object? classId = freezed,Object? className = freezed,Object? status = null,Object? daysSinceLastJournal = null,Object? activeProgram = freezed,Object? streakCurrent = null,Object? streakBest = null,Object? lastJournalDate = freezed,Object? journalCountMonth = null,Object? journalCountTotal = null,Object? booksCompleted = null,Object? recentDates = null,}) {
  return _then(StudentStats(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nis: freezed == nis ? _self.nis : nis // ignore: cast_nullable_to_non_nullable
as String?,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,className: freezed == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StudentStatus,daysSinceLastJournal: null == daysSinceLastJournal ? _self.daysSinceLastJournal : daysSinceLastJournal // ignore: cast_nullable_to_non_nullable
as int,activeProgram: freezed == activeProgram ? _self.activeProgram : activeProgram // ignore: cast_nullable_to_non_nullable
as ActiveProgramSummary?,streakCurrent: null == streakCurrent ? _self.streakCurrent : streakCurrent // ignore: cast_nullable_to_non_nullable
as int,streakBest: null == streakBest ? _self.streakBest : streakBest // ignore: cast_nullable_to_non_nullable
as int,lastJournalDate: freezed == lastJournalDate ? _self.lastJournalDate : lastJournalDate // ignore: cast_nullable_to_non_nullable
as String?,journalCountMonth: null == journalCountMonth ? _self.journalCountMonth : journalCountMonth // ignore: cast_nullable_to_non_nullable
as int,journalCountTotal: null == journalCountTotal ? _self.journalCountTotal : journalCountTotal // ignore: cast_nullable_to_non_nullable
as int,booksCompleted: null == booksCompleted ? _self.booksCompleted : booksCompleted // ignore: cast_nullable_to_non_nullable
as int,recentDates: null == recentDates ? _self.recentDates : recentDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of StudentStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActiveProgramSummaryCopyWith<$Res>? get activeProgram {
    if (_self.activeProgram == null) {
    return null;
  }

  return $ActiveProgramSummaryCopyWith<$Res>(_self.activeProgram!, (value) {
    return _then(_self.copyWith(activeProgram: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudentStats].
extension StudentStatsPatterns on StudentStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentStats value)  $default,){
final _that = this;
switch (_that) {
case _StudentStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentStats value)?  $default,){
final _that = this;
switch (_that) {
case _StudentStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String studentId,  String name,  String? nis,  String? classId,  String? className,  StudentStatus status,  int daysSinceLastJournal,  ActiveProgramSummary? activeProgram,  int streakCurrent,  int streakBest,  String? lastJournalDate,  int journalCountMonth,  int journalCountTotal,  int booksCompleted,  List<String> recentDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentStats() when $default != null:
return $default(_that.studentId,_that.name,_that.nis,_that.classId,_that.className,_that.status,_that.daysSinceLastJournal,_that.activeProgram,_that.streakCurrent,_that.streakBest,_that.lastJournalDate,_that.journalCountMonth,_that.journalCountTotal,_that.booksCompleted,_that.recentDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String studentId,  String name,  String? nis,  String? classId,  String? className,  StudentStatus status,  int daysSinceLastJournal,  ActiveProgramSummary? activeProgram,  int streakCurrent,  int streakBest,  String? lastJournalDate,  int journalCountMonth,  int journalCountTotal,  int booksCompleted,  List<String> recentDates)  $default,) {final _that = this;
switch (_that) {
case _StudentStats():
return $default(_that.studentId,_that.name,_that.nis,_that.classId,_that.className,_that.status,_that.daysSinceLastJournal,_that.activeProgram,_that.streakCurrent,_that.streakBest,_that.lastJournalDate,_that.journalCountMonth,_that.journalCountTotal,_that.booksCompleted,_that.recentDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String studentId,  String name,  String? nis,  String? classId,  String? className,  StudentStatus status,  int daysSinceLastJournal,  ActiveProgramSummary? activeProgram,  int streakCurrent,  int streakBest,  String? lastJournalDate,  int journalCountMonth,  int journalCountTotal,  int booksCompleted,  List<String> recentDates)?  $default,) {final _that = this;
switch (_that) {
case _StudentStats() when $default != null:
return $default(_that.studentId,_that.name,_that.nis,_that.classId,_that.className,_that.status,_that.daysSinceLastJournal,_that.activeProgram,_that.streakCurrent,_that.streakBest,_that.lastJournalDate,_that.journalCountMonth,_that.journalCountTotal,_that.booksCompleted,_that.recentDates);case _:
  return null;

}
}

}

/// @nodoc


class _StudentStats implements StudentStats {
  const _StudentStats({required this.studentId, required this.name, this.nis, this.classId, this.className, this.status = StudentStatus.belumMulai, this.daysSinceLastJournal = 0, this.activeProgram, this.streakCurrent = 0, this.streakBest = 0, this.lastJournalDate, this.journalCountMonth = 0, this.journalCountTotal = 0, this.booksCompleted = 0,  List<String> recentDates = const <String>[]}): _recentDates = recentDates;
  

@override final  String studentId;
@override final  String name;
@override final  String? nis;
@override final  String? classId;
@override final  String? className;
@override@JsonKey() final  StudentStatus status;
@override@JsonKey() final  int daysSinceLastJournal;
@override final  ActiveProgramSummary? activeProgram;
@override@JsonKey() final  int streakCurrent;
@override@JsonKey() final  int streakBest;
@override final  String? lastJournalDate;
@override@JsonKey() final  int journalCountMonth;
@override@JsonKey() final  int journalCountTotal;
@override@JsonKey() final  int booksCompleted;
/// The five most recent journal dates, newest first.
 final  List<String> _recentDates;
/// The five most recent journal dates, newest first.
@override@JsonKey() List<String> get recentDates {
  if (_recentDates is EqualUnmodifiableListView) return _recentDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentDates);
}


/// Create a copy of StudentStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentStatsCopyWith<_StudentStats> get copyWith => __$StudentStatsCopyWithImpl<_StudentStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentStats&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nis, nis) || other.nis == nis)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.className, className) || other.className == className)&&(identical(other.status, status) || other.status == status)&&(identical(other.daysSinceLastJournal, daysSinceLastJournal) || other.daysSinceLastJournal == daysSinceLastJournal)&&(identical(other.activeProgram, activeProgram) || other.activeProgram == activeProgram)&&(identical(other.streakCurrent, streakCurrent) || other.streakCurrent == streakCurrent)&&(identical(other.streakBest, streakBest) || other.streakBest == streakBest)&&(identical(other.lastJournalDate, lastJournalDate) || other.lastJournalDate == lastJournalDate)&&(identical(other.journalCountMonth, journalCountMonth) || other.journalCountMonth == journalCountMonth)&&(identical(other.journalCountTotal, journalCountTotal) || other.journalCountTotal == journalCountTotal)&&(identical(other.booksCompleted, booksCompleted) || other.booksCompleted == booksCompleted)&&const DeepCollectionEquality().equals(other.recentDates, _recentDates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,studentId,name,nis,classId,className,status,daysSinceLastJournal,activeProgram,streakCurrent,streakBest,lastJournalDate,journalCountMonth,journalCountTotal,booksCompleted,const DeepCollectionEquality().hash(_recentDates));
}

@override
String toString() {
    return 'StudentStats(studentId: $studentId, name: $name, nis: $nis, classId: $classId, className: $className, status: $status, daysSinceLastJournal: $daysSinceLastJournal, activeProgram: $activeProgram, streakCurrent: $streakCurrent, streakBest: $streakBest, lastJournalDate: $lastJournalDate, journalCountMonth: $journalCountMonth, journalCountTotal: $journalCountTotal, booksCompleted: $booksCompleted, recentDates: $recentDates)';
}


}

/// @nodoc
abstract mixin class _$StudentStatsCopyWith<$Res> implements $StudentStatsCopyWith<$Res> {
  factory _$StudentStatsCopyWith(_StudentStats value, $Res Function(_StudentStats) _then) = __$StudentStatsCopyWithImpl;
@override @useResult
$Res call({
 String studentId, String name, String? nis, String? classId, String? className, StudentStatus status, int daysSinceLastJournal, ActiveProgramSummary? activeProgram, int streakCurrent, int streakBest, String? lastJournalDate, int journalCountMonth, int journalCountTotal, int booksCompleted, List<String> recentDates
});


@override $ActiveProgramSummaryCopyWith<$Res>? get activeProgram;

}
/// @nodoc
class __$StudentStatsCopyWithImpl<$Res>
    implements _$StudentStatsCopyWith<$Res> {
  __$StudentStatsCopyWithImpl(this._self, this._then);

  final _StudentStats _self;
  final $Res Function(_StudentStats) _then;

/// Create a copy of StudentStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? studentId = null,Object? name = null,Object? nis = freezed,Object? classId = freezed,Object? className = freezed,Object? status = null,Object? daysSinceLastJournal = null,Object? activeProgram = freezed,Object? streakCurrent = null,Object? streakBest = null,Object? lastJournalDate = freezed,Object? journalCountMonth = null,Object? journalCountTotal = null,Object? booksCompleted = null,Object? recentDates = null,}) {
  return _then(_StudentStats(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nis: freezed == nis ? _self.nis : nis // ignore: cast_nullable_to_non_nullable
as String?,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String?,className: freezed == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StudentStatus,daysSinceLastJournal: null == daysSinceLastJournal ? _self.daysSinceLastJournal : daysSinceLastJournal // ignore: cast_nullable_to_non_nullable
as int,activeProgram: freezed == activeProgram ? _self.activeProgram : activeProgram // ignore: cast_nullable_to_non_nullable
as ActiveProgramSummary?,streakCurrent: null == streakCurrent ? _self.streakCurrent : streakCurrent // ignore: cast_nullable_to_non_nullable
as int,streakBest: null == streakBest ? _self.streakBest : streakBest // ignore: cast_nullable_to_non_nullable
as int,lastJournalDate: freezed == lastJournalDate ? _self.lastJournalDate : lastJournalDate // ignore: cast_nullable_to_non_nullable
as String?,journalCountMonth: null == journalCountMonth ? _self.journalCountMonth : journalCountMonth // ignore: cast_nullable_to_non_nullable
as int,journalCountTotal: null == journalCountTotal ? _self.journalCountTotal : journalCountTotal // ignore: cast_nullable_to_non_nullable
as int,booksCompleted: null == booksCompleted ? _self.booksCompleted : booksCompleted // ignore: cast_nullable_to_non_nullable
as int,recentDates: null == recentDates ? _self._recentDates : recentDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of StudentStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActiveProgramSummaryCopyWith<$Res>? get activeProgram {
    if (_self.activeProgram == null) {
    return null;
  }

  return $ActiveProgramSummaryCopyWith<$Res>(_self.activeProgram!, (value) {
    return _then(_self.copyWith(activeProgram: value));
  });
}
}

// dart format on
