// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(studentRepository)
final studentRepositoryProvider = StudentRepositoryProvider._();

final class StudentRepositoryProvider
    extends
        $FunctionalProvider<
          StudentRepository,
          StudentRepository,
          StudentRepository
        >
    with $Provider<StudentRepository> {
  StudentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentRepositoryHash();

  @$internal
  @override
  $ProviderElement<StudentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StudentRepository create(Ref ref) {
    return studentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentRepository>(value),
    );
  }
}

String _$studentRepositoryHash() => r'd1e5075811087d0e8e9084c1087e8ecc5e7a363f';

/// The student's own summary (server-written).

@ProviderFor(myStats)
final myStatsProvider = MyStatsProvider._();

/// The student's own summary (server-written).

final class MyStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StudentStats?>,
          StudentStats?,
          Stream<StudentStats?>
        >
    with $FutureModifier<StudentStats?>, $StreamProvider<StudentStats?> {
  /// The student's own summary (server-written).
  MyStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myStatsHash();

  @$internal
  @override
  $StreamProviderElement<StudentStats?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StudentStats?> create(Ref ref) {
    return myStats(ref);
  }
}

String _$myStatsHash() => r'6cd260295cab9ce80bba3e130d02dab5887c5bda';

/// The book being read, or null. Follows the lock document, so it is correct
/// offline and the instant a book is started or finished.

@ProviderFor(activeProgram)
final activeProgramProvider = ActiveProgramProvider._();

/// The book being read, or null. Follows the lock document, so it is correct
/// offline and the instant a book is started or finished.

final class ActiveProgramProvider
    extends
        $FunctionalProvider<AsyncValue<Program?>, Program?, Stream<Program?>>
    with $FutureModifier<Program?>, $StreamProvider<Program?> {
  /// The book being read, or null. Follows the lock document, so it is correct
  /// offline and the instant a book is started or finished.
  ActiveProgramProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeProgramProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeProgramHash();

  @$internal
  @override
  $StreamProviderElement<Program?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Program?> create(Ref ref) {
    return activeProgram(ref);
  }
}

String _$activeProgramHash() => r'8b8f7882bf0f5c0262d9af2c19f48bfe977dd2ef';

/// All of the student's books, newest first.

@ProviderFor(myPrograms)
final myProgramsProvider = MyProgramsProvider._();

/// All of the student's books, newest first.

final class MyProgramsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Program>>,
          List<Program>,
          Stream<List<Program>>
        >
    with $FutureModifier<List<Program>>, $StreamProvider<List<Program>> {
  /// All of the student's books, newest first.
  MyProgramsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProgramsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProgramsHash();

  @$internal
  @override
  $StreamProviderElement<List<Program>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Program>> create(Ref ref) {
    return myPrograms(ref);
  }
}

String _$myProgramsHash() => r'853a75e5dd19d5473e06f8bb683d84183fa0a3d2';

@ProviderFor(unreadJournals)
final unreadJournalsProvider = UnreadJournalsFamily._();

final class UnreadJournalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Journal>>,
          List<Journal>,
          Stream<List<Journal>>
        >
    with $FutureModifier<List<Journal>>, $StreamProvider<List<Journal>> {
  UnreadJournalsProvider._({
    required UnreadJournalsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'unreadJournalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unreadJournalsHash();

  @override
  String toString() {
    return r'unreadJournalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Journal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Journal>> create(Ref ref) {
    final argument = this.argument as String;
    return unreadJournals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadJournalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadJournalsHash() => r'427355b84debb4f371693f97ee100a8c3a3a215a';

final class UnreadJournalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Journal>>, String> {
  UnreadJournalsFamily._()
    : super(
        retry: null,
        name: r'unreadJournalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UnreadJournalsProvider call(String programId) =>
      UnreadJournalsProvider._(argument: programId, from: this);

  @override
  String toString() => r'unreadJournalsProvider';
}
