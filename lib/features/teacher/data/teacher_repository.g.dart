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

String _$teacherRepositoryHash() => r'fd7d359a82c2b020b63be842b833ba3d793457cd';

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

/// One student's summary. Readable only while the student is in one of the
/// teacher's classes.

@ProviderFor(studentStats)
final studentStatsProvider = StudentStatsFamily._();

/// One student's summary. Readable only while the student is in one of the
/// teacher's classes.

final class StudentStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StudentStats?>,
          StudentStats?,
          Stream<StudentStats?>
        >
    with $FutureModifier<StudentStats?>, $StreamProvider<StudentStats?> {
  /// One student's summary. Readable only while the student is in one of the
  /// teacher's classes.
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

/// One student's summary. Readable only while the student is in one of the
/// teacher's classes.

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

  /// One student's summary. Readable only while the student is in one of the
  /// teacher's classes.

  StudentStatsProvider call(String studentId) =>
      StudentStatsProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentStatsProvider';
}

/// A student's books. The class filter is what lets the rules allow the
/// query (docs/03 §3).

@ProviderFor(studentPrograms)
final studentProgramsProvider = StudentProgramsFamily._();

/// A student's books. The class filter is what lets the rules allow the
/// query (docs/03 §3).

final class StudentProgramsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Program>>,
          List<Program>,
          Stream<List<Program>>
        >
    with $FutureModifier<List<Program>>, $StreamProvider<List<Program>> {
  /// A student's books. The class filter is what lets the rules allow the
  /// query (docs/03 §3).
  StudentProgramsProvider._({
    required StudentProgramsFamily super.from,
    required (String, String) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Program>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Program>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return studentPrograms(ref, argument.$1, argument.$2);
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

String _$studentProgramsHash() => r'14be253aec73236b1fe9b93356ad5194c8407417';

/// A student's books. The class filter is what lets the rules allow the
/// query (docs/03 §3).

final class StudentProgramsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Program>>, (String, String)> {
  StudentProgramsFamily._()
    : super(
        retry: null,
        name: r'studentProgramsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A student's books. The class filter is what lets the rules allow the
  /// query (docs/03 §3).

  StudentProgramsProvider call(String studentId, String classId) =>
      StudentProgramsProvider._(argument: (studentId, classId), from: this);

  @override
  String toString() => r'studentProgramsProvider';
}

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered by a status.

@ProviderFor(StudentListFilter)
final studentListFilterProvider = StudentListFilterProvider._();

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered by a status.
final class StudentListFilterProvider
    extends $NotifierProvider<StudentListFilter, StudentFilter> {
  /// Filter of the student list. Shared so the dashboard can open the list
  /// already filtered by a status.
  StudentListFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentListFilterProvider',
        isAutoDispose: true,
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

String _$studentListFilterHash() => r'817cf805ff2f54de9efed7eb2a86ef7467cf8ed0';

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered by a status.

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
