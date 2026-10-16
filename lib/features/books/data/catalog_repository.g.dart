// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The whole search index: the four shard documents merged, sorted by title.
/// The documents stay in Firestore's offline cache, so search works without
/// a signal once the catalog has loaded.

@ProviderFor(catalogIndex)
final catalogIndexProvider = CatalogIndexProvider._();

/// The whole search index: the four shard documents merged, sorted by title.
/// The documents stay in Firestore's offline cache, so search works without
/// a signal once the catalog has loaded.

final class CatalogIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogEntry>>,
          List<CatalogEntry>,
          Stream<List<CatalogEntry>>
        >
    with
        $FutureModifier<List<CatalogEntry>>,
        $StreamProvider<List<CatalogEntry>> {
  /// The whole search index: the four shard documents merged, sorted by title.
  /// The documents stay in Firestore's offline cache, so search works without
  /// a signal once the catalog has loaded.
  CatalogIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogIndexHash();

  @$internal
  @override
  $StreamProviderElement<List<CatalogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CatalogEntry>> create(Ref ref) {
    return catalogIndex(ref);
  }
}

String _$catalogIndexHash() => r'b33ac412d53efd92f8a1f6ef299f873a8b8737d1';

/// One catalog book (`books/{bookId}`), or null when it does not exist.

@ProviderFor(catalogBook)
final catalogBookProvider = CatalogBookFamily._();

/// One catalog book (`books/{bookId}`), or null when it does not exist.

final class CatalogBookProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogBook?>,
          CatalogBook?,
          Stream<CatalogBook?>
        >
    with $FutureModifier<CatalogBook?>, $StreamProvider<CatalogBook?> {
  /// One catalog book (`books/{bookId}`), or null when it does not exist.
  CatalogBookProvider._({
    required CatalogBookFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'catalogBookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$catalogBookHash();

  @override
  String toString() {
    return r'catalogBookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CatalogBook?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CatalogBook?> create(Ref ref) {
    final argument = this.argument as String;
    return catalogBook(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogBookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$catalogBookHash() => r'51d8112f40a9bd223fc87777881c3f620855c3ec';

/// One catalog book (`books/{bookId}`), or null when it does not exist.

final class CatalogBookFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CatalogBook?>, String> {
  CatalogBookFamily._()
    : super(
        retry: null,
        name: r'catalogBookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One catalog book (`books/{bookId}`), or null when it does not exist.

  CatalogBookProvider call(String bookId) =>
      CatalogBookProvider._(argument: bookId, from: this);

  @override
  String toString() => r'catalogBookProvider';
}

/// Readers of each catalog book in the signed-in user's school
/// (`schools/{s}/bookStats`, written by the server).

@ProviderFor(schoolBookStats)
final schoolBookStatsProvider = SchoolBookStatsProvider._();

/// Readers of each catalog book in the signed-in user's school
/// (`schools/{s}/bookStats`, written by the server).

final class SchoolBookStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ({int active, int readers})>>,
          Map<String, ({int active, int readers})>,
          Stream<Map<String, ({int active, int readers})>>
        >
    with
        $FutureModifier<Map<String, ({int active, int readers})>>,
        $StreamProvider<Map<String, ({int active, int readers})>> {
  /// Readers of each catalog book in the signed-in user's school
  /// (`schools/{s}/bookStats`, written by the server).
  SchoolBookStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schoolBookStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schoolBookStatsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, ({int active, int readers})>>
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, ({int active, int readers})>> create(Ref ref) {
    return schoolBookStats(ref);
  }
}

String _$schoolBookStatsHash() => r'8444fe629f02898cbd647d19319d02ba09855d85';

/// Books the school's teachers recommend (`schools/{s}.recommendedBooks`).

@ProviderFor(recommendedBookIds)
final recommendedBookIdsProvider = RecommendedBookIdsProvider._();

/// Books the school's teachers recommend (`schools/{s}.recommendedBooks`).

final class RecommendedBookIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Books the school's teachers recommend (`schools/{s}.recommendedBooks`).
  RecommendedBookIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendedBookIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendedBookIdsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return recommendedBookIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recommendedBookIdsHash() =>
    r'a84ea4fdbc09a27eff5b4f9e350149d1d243f978';

/// A catalog book chosen outside the start form ("Baca buku ini" on the
/// book's page). The form takes it once and clears it.

@ProviderFor(PendingBookPick)
final pendingBookPickProvider = PendingBookPickProvider._();

/// A catalog book chosen outside the start form ("Baca buku ini" on the
/// book's page). The form takes it once and clears it.
final class PendingBookPickProvider
    extends $NotifierProvider<PendingBookPick, CatalogEntry?> {
  /// A catalog book chosen outside the start form ("Baca buku ini" on the
  /// book's page). The form takes it once and clears it.
  PendingBookPickProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingBookPickProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingBookPickHash();

  @$internal
  @override
  PendingBookPick create() => PendingBookPick();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogEntry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogEntry?>(value),
    );
  }
}

String _$pendingBookPickHash() => r'068f512cd7a105d53aa0b659ef781d421e0bc924';

/// A catalog book chosen outside the start form ("Baca buku ini" on the
/// book's page). The form takes it once and clears it.

abstract class _$PendingBookPick extends $Notifier<CatalogEntry?> {
  CatalogEntry? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CatalogEntry?, CatalogEntry?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CatalogEntry?, CatalogEntry?>,
              CatalogEntry?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
