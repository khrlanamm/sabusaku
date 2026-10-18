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

String _$studentRepositoryHash() => r'728ee0ed72346f8f8d4b29db4be0948b1fef8cdb';

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

/// The student's journals from [from] to [to] (inclusive) over all their
/// books, or one book when [programId] is given; newest first. Only books
/// with a journal in the range are queried (`journalDates`).

@ProviderFor(myJournalsBetween)
final myJournalsBetweenProvider = MyJournalsBetweenFamily._();

/// The student's journals from [from] to [to] (inclusive) over all their
/// books, or one book when [programId] is given; newest first. Only books
/// with a journal in the range are queried (`journalDates`).

final class MyJournalsBetweenProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Journal>>,
          List<Journal>,
          Stream<List<Journal>>
        >
    with $FutureModifier<List<Journal>>, $StreamProvider<List<Journal>> {
  /// The student's journals from [from] to [to] (inclusive) over all their
  /// books, or one book when [programId] is given; newest first. Only books
  /// with a journal in the range are queried (`journalDates`).
  MyJournalsBetweenProvider._({
    required MyJournalsBetweenFamily super.from,
    required (String, String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'myJournalsBetweenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myJournalsBetweenHash();

  @override
  String toString() {
    return r'myJournalsBetweenProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Journal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Journal>> create(Ref ref) {
    final argument = this.argument as (String, String, String?);
    return myJournalsBetween(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is MyJournalsBetweenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myJournalsBetweenHash() => r'cb57b852ad70ce0a85a9812664f00cc40003fdf7';

/// The student's journals from [from] to [to] (inclusive) over all their
/// books, or one book when [programId] is given; newest first. Only books
/// with a journal in the range are queried (`journalDates`).

final class MyJournalsBetweenFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<Journal>>,
          (String, String, String?)
        > {
  MyJournalsBetweenFamily._()
    : super(
        retry: null,
        name: r'myJournalsBetweenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The student's journals from [from] to [to] (inclusive) over all their
  /// books, or one book when [programId] is given; newest first. Only books
  /// with a journal in the range are queried (`journalDates`).

  MyJournalsBetweenProvider call(String from, String to, String? programId) =>
      MyJournalsBetweenProvider._(argument: (from, to, programId), from: this);

  @override
  String toString() => r'myJournalsBetweenProvider';
}

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

/// The filter of the Jurnal tab. Kept while the student moves between tabs,
/// so cards on Beranda can set it before opening the tab; reset per account.

@ProviderFor(JournalFilterState)
final journalFilterStateProvider = JournalFilterStateProvider._();

/// The filter of the Jurnal tab. Kept while the student moves between tabs,
/// so cards on Beranda can set it before opening the tab; reset per account.
final class JournalFilterStateProvider
    extends $NotifierProvider<JournalFilterState, JournalFilter> {
  /// The filter of the Jurnal tab. Kept while the student moves between tabs,
  /// so cards on Beranda can set it before opening the tab; reset per account.
  JournalFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalFilterStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalFilterStateHash();

  @$internal
  @override
  JournalFilterState create() => JournalFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalFilter>(value),
    );
  }
}

String _$journalFilterStateHash() =>
    r'1d02849187a4055b098c7137a23a336ccf8ca88f';

/// The filter of the Jurnal tab. Kept while the student moves between tabs,
/// so cards on Beranda can set it before opening the tab; reset per account.

abstract class _$JournalFilterState extends $Notifier<JournalFilter> {
  JournalFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<JournalFilter, JournalFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JournalFilter, JournalFilter>,
              JournalFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
