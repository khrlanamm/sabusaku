// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(readingRepository)
final readingRepositoryProvider = ReadingRepositoryProvider._();

final class ReadingRepositoryProvider
    extends
        $FunctionalProvider<
          ReadingRepository,
          ReadingRepository,
          ReadingRepository
        >
    with $Provider<ReadingRepository> {
  ReadingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReadingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReadingRepository create(Ref ref) {
    return readingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingRepository>(value),
    );
  }
}

String _$readingRepositoryHash() => r'bdac93f17086ebfb7d3bc83eb71b63da509fd910';

@ProviderFor(program)
final programProvider = ProgramFamily._();

final class ProgramProvider
    extends
        $FunctionalProvider<AsyncValue<Program?>, Program?, Stream<Program?>>
    with $FutureModifier<Program?>, $StreamProvider<Program?> {
  ProgramProvider._({
    required ProgramFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programHash();

  @override
  String toString() {
    return r'programProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Program?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Program?> create(Ref ref) {
    final argument = this.argument as String;
    return program(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programHash() => r'4e208643b197cb93b22c96d65393966a23aa0f22';

final class ProgramFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Program?>, String> {
  ProgramFamily._()
    : super(
        retry: null,
        name: r'programProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProgramProvider call(String programId) =>
      ProgramProvider._(argument: programId, from: this);

  @override
  String toString() => r'programProvider';
}

@ProviderFor(journal)
final journalProvider = JournalFamily._();

final class JournalProvider
    extends
        $FunctionalProvider<AsyncValue<Journal?>, Journal?, Stream<Journal?>>
    with $FutureModifier<Journal?>, $StreamProvider<Journal?> {
  JournalProvider._({
    required JournalFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'journalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journalHash();

  @override
  String toString() {
    return r'journalProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Journal?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Journal?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return journal(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journalHash() => r'ead16e4b839675085b185713487c061cda14945b';

final class JournalFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Journal?>, (String, String)> {
  JournalFamily._()
    : super(
        retry: null,
        name: r'journalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JournalProvider call(String programId, String date) =>
      JournalProvider._(argument: (programId, date), from: this);

  @override
  String toString() => r'journalProvider';
}

@ProviderFor(journals)
final journalsProvider = JournalsFamily._();

final class JournalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Journal>>,
          List<Journal>,
          Stream<List<Journal>>
        >
    with $FutureModifier<List<Journal>>, $StreamProvider<List<Journal>> {
  JournalsProvider._({
    required JournalsFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'journalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journalsHash();

  @override
  String toString() {
    return r'journalsProvider'
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
    final argument = this.argument as (String, int);
    return journals(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journalsHash() => r'9798263d939fb4ff1f096b4d22c409e485cd45a3';

final class JournalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Journal>>, (String, int)> {
  JournalsFamily._()
    : super(
        retry: null,
        name: r'journalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JournalsProvider call(String programId, int limit) =>
      JournalsProvider._(argument: (programId, limit), from: this);

  @override
  String toString() => r'journalsProvider';
}

@ProviderFor(journalComments)
final journalCommentsProvider = JournalCommentsFamily._();

final class JournalCommentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JournalComment>>,
          List<JournalComment>,
          Stream<List<JournalComment>>
        >
    with
        $FutureModifier<List<JournalComment>>,
        $StreamProvider<List<JournalComment>> {
  JournalCommentsProvider._({
    required JournalCommentsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'journalCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journalCommentsHash();

  @override
  String toString() {
    return r'journalCommentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<JournalComment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<JournalComment>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return journalComments(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journalCommentsHash() => r'614573f6050c259040cd30a41269e736cba696e2';

final class JournalCommentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<JournalComment>>,
          (String, String)
        > {
  JournalCommentsFamily._()
    : super(
        retry: null,
        name: r'journalCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JournalCommentsProvider call(String programId, String date) =>
      JournalCommentsProvider._(argument: (programId, date), from: this);

  @override
  String toString() => r'journalCommentsProvider';
}
