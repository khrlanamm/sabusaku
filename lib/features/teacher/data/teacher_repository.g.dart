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
/// already filtered.

@ProviderFor(StudentListFilter)
final studentListFilterProvider = StudentListFilterProvider._();

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered.
final class StudentListFilterProvider
    extends $NotifierProvider<StudentListFilter, StudentFilter> {
  /// Filter of the student list. Shared so the dashboard can open the list
  /// already filtered.
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

String _$studentListFilterHash() => r'8cbcb93fbb0c0d97a0e1b8110356e4556d807e5e';

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered.

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
