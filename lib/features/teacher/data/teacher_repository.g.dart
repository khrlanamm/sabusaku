// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teacherRepository)
final teacherRepositoryProvider = TeacherRepositoryProvider._();

final class TeacherRepositoryProvider
    extends
        $FunctionalProvider<
          TeacherRepository,
          TeacherRepository,
          TeacherRepository
        >
    with $Provider<TeacherRepository> {
  TeacherRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teacherRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teacherRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeacherRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeacherRepository create(Ref ref) {
    return teacherRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeacherRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeacherRepository>(value),
    );
  }
}

String _$teacherRepositoryHash() => r'714ae3c6138771186d64d82630ee559552c08105';

@ProviderFor(teacherStudents)
final teacherStudentsProvider = TeacherStudentsProvider._();

final class TeacherStudentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudentStats>>,
          List<StudentStats>,
          Stream<List<StudentStats>>
        >
    with
        $FutureModifier<List<StudentStats>>,
        $StreamProvider<List<StudentStats>> {
  TeacherStudentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teacherStudentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teacherStudentsHash();

  @$internal
  @override
  $StreamProviderElement<List<StudentStats>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StudentStats>> create(Ref ref) {
    return teacherStudents(ref);
  }
}

String _$teacherStudentsHash() => r'94ff3c91d0ab0ea73f6e4bca5cc57f170ad66dac';

@ProviderFor(pendingStudents)
final pendingStudentsProvider = PendingStudentsProvider._();

final class PendingStudentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Member>>,
          List<Member>,
          Stream<List<Member>>
        >
    with $FutureModifier<List<Member>>, $StreamProvider<List<Member>> {
  PendingStudentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingStudentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingStudentsHash();

  @$internal
  @override
  $StreamProviderElement<List<Member>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Member>> create(Ref ref) {
    return pendingStudents(ref);
  }
}

String _$pendingStudentsHash() => r'fcf6eaa4ca666393edfa1841e8d2d8d7df00f54e';

@ProviderFor(pendingTeachers)
final pendingTeachersProvider = PendingTeachersProvider._();

final class PendingTeachersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Member>>,
          List<Member>,
          Stream<List<Member>>
        >
    with $FutureModifier<List<Member>>, $StreamProvider<List<Member>> {
  PendingTeachersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingTeachersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingTeachersHash();

  @$internal
  @override
  $StreamProviderElement<List<Member>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Member>> create(Ref ref) {
    return pendingTeachers(ref);
  }
}

String _$pendingTeachersHash() => r'd3217d186075ed17b68a0b8b3b5d26406401bd26';

@ProviderFor(member)
final memberProvider = MemberFamily._();

final class MemberProvider
    extends $FunctionalProvider<AsyncValue<Member?>, Member?, Stream<Member?>>
    with $FutureModifier<Member?>, $StreamProvider<Member?> {
  MemberProvider._({
    required MemberFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'memberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberHash();

  @override
  String toString() {
    return r'memberProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Member?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Member?> create(Ref ref) {
    final argument = this.argument as String;
    return member(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberHash() => r'212402888ac83950d68f593647faa57911c2a348';

final class MemberFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Member?>, String> {
  MemberFamily._()
    : super(
        retry: null,
        name: r'memberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberProvider call(String email) =>
      MemberProvider._(argument: email, from: this);

  @override
  String toString() => r'memberProvider';
}

@ProviderFor(schoolTeachers)
final schoolTeachersProvider = SchoolTeachersProvider._();

final class SchoolTeachersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          Stream<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $StreamProvider<List<AppUser>> {
  SchoolTeachersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schoolTeachersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schoolTeachersHash();

  @$internal
  @override
  $StreamProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppUser>> create(Ref ref) {
    return schoolTeachers(ref);
  }
}

String _$schoolTeachersHash() => r'c545ae39747274ec9a700b196fdd01386f4e2232';

/// One student's summary. Gone once the student is removed from the school.

@ProviderFor(studentStats)
final studentStatsProvider = StudentStatsFamily._();

/// One student's summary. Gone once the student is removed from the school.

final class StudentStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StudentStats?>,
          StudentStats?,
          Stream<StudentStats?>
        >
    with $FutureModifier<StudentStats?>, $StreamProvider<StudentStats?> {
  /// One student's summary. Gone once the student is removed from the school.
  StudentStatsProvider._({
    required StudentStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentStatsHash();

  @override
  String toString() {
    return r'studentStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<StudentStats?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StudentStats?> create(Ref ref) {
    final argument = this.argument as String;
    return studentStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentStatsHash() => r'9499b99f44aea660a24fc84549c3c7740278bf5c';

/// One student's summary. Gone once the student is removed from the school.

final class StudentStatsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<StudentStats?>, String> {
  StudentStatsFamily._()
    : super(
        retry: null,
        name: r'studentStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One student's summary. Gone once the student is removed from the school.

  StudentStatsProvider call(String studentId) =>
      StudentStatsProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentStatsProvider';
}

/// A student's books, newest first.

@ProviderFor(studentPrograms)
final studentProgramsProvider = StudentProgramsFamily._();

/// A student's books, newest first.

final class StudentProgramsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Program>>,
          List<Program>,
          Stream<List<Program>>
        >
    with $FutureModifier<List<Program>>, $StreamProvider<List<Program>> {
  /// A student's books, newest first.
  StudentProgramsProvider._({
    required StudentProgramsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentProgramsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentProgramsHash();

  @override
  String toString() {
    return r'studentProgramsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Program>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Program>> create(Ref ref) {
    final argument = this.argument as String;
    return studentPrograms(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProgramsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentProgramsHash() => r'eb2c91aa178fbd9a3ad85bf6ad692661cf7de54d';

/// A student's books, newest first.

final class StudentProgramsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Program>>, String> {
  StudentProgramsFamily._()
    : super(
        retry: null,
        name: r'studentProgramsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A student's books, newest first.

  StudentProgramsProvider call(String studentId) =>
      StudentProgramsProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentProgramsProvider';
}

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered, and kept while the list is not built yet (a tab opens
/// only when first visited). Cleared for each account and school.

@ProviderFor(StudentListFilter)
final studentListFilterProvider = StudentListFilterProvider._();

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered, and kept while the list is not built yet (a tab opens
/// only when first visited). Cleared for each account and school.
final class StudentListFilterProvider
    extends $NotifierProvider<StudentListFilter, StudentFilter> {
  /// Filter of the student list. Shared so the dashboard can open the list
  /// already filtered, and kept while the list is not built yet (a tab opens
  /// only when first visited). Cleared for each account and school.
  StudentListFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentListFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentListFilterHash();

  @$internal
  @override
  StudentListFilter create() => StudentListFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentFilter>(value),
    );
  }
}

String _$studentListFilterHash() => r'ca3f1f713d0ae20b7ef854a657ae9e3ec3756205';

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered, and kept while the list is not built yet (a tab opens
/// only when first visited). Cleared for each account and school.

abstract class _$StudentListFilter extends $Notifier<StudentFilter> {
  StudentFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StudentFilter, StudentFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StudentFilter, StudentFilter>,
              StudentFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The scope of the dashboard and of the pages its cards open. Starts on the
/// teacher's own students when they have a group, and again for each account
/// and school.

@ProviderFor(DashboardScope)
final dashboardScopeProvider = DashboardScopeProvider._();

/// The scope of the dashboard and of the pages its cards open. Starts on the
/// teacher's own students when they have a group, and again for each account
/// and school.
final class DashboardScopeProvider
    extends $NotifierProvider<DashboardScope, StudentScope> {
  /// The scope of the dashboard and of the pages its cards open. Starts on the
  /// teacher's own students when they have a group, and again for each account
  /// and school.
  DashboardScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardScopeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardScopeHash();

  @$internal
  @override
  DashboardScope create() => DashboardScope();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentScope>(value),
    );
  }
}

String _$dashboardScopeHash() => r'bcf4fde2010a0b20bbe4abc084d1f3b5841c5dbb';

/// The scope of the dashboard and of the pages its cards open. Starts on the
/// teacher's own students when they have a group, and again for each account
/// and school.

abstract class _$DashboardScope extends $Notifier<StudentScope> {
  StudentScope build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StudentScope, StudentScope>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StudentScope, StudentScope>,
              StudentScope,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The labels a view can be narrowed to: the school's lists plus any class a
/// student still carries after it left the list.

@ProviderFor(scopeOptions)
final scopeOptionsProvider = ScopeOptionsProvider._();

/// The labels a view can be narrowed to: the school's lists plus any class a
/// student still carries after it left the list.

final class ScopeOptionsProvider
    extends $FunctionalProvider<ScopeOptions, ScopeOptions, ScopeOptions>
    with $Provider<ScopeOptions> {
  /// The labels a view can be narrowed to: the school's lists plus any class a
  /// student still carries after it left the list.
  ScopeOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scopeOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scopeOptionsHash();

  @$internal
  @override
  $ProviderElement<ScopeOptions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScopeOptions create(Ref ref) {
    return scopeOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScopeOptions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScopeOptions>(value),
    );
  }
}

String _$scopeOptionsHash() => r'13969e7484c54644bb5cada1003702222cf7dfa7';

/// [DashboardScope] as it applies now; see [StudentScope.resolve].

@ProviderFor(effectiveDashboardScope)
final effectiveDashboardScopeProvider = EffectiveDashboardScopeProvider._();

/// [DashboardScope] as it applies now; see [StudentScope.resolve].

final class EffectiveDashboardScopeProvider
    extends $FunctionalProvider<StudentScope, StudentScope, StudentScope>
    with $Provider<StudentScope> {
  /// [DashboardScope] as it applies now; see [StudentScope.resolve].
  EffectiveDashboardScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveDashboardScopeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveDashboardScopeHash();

  @$internal
  @override
  $ProviderElement<StudentScope> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StudentScope create(Ref ref) {
    return effectiveDashboardScope(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentScope>(value),
    );
  }
}

String _$effectiveDashboardScopeHash() =>
    r'1f460d60c4d02694e07375d6230232bd366289d3';
