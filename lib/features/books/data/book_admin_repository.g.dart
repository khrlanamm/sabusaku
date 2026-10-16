// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_admin_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookAdminRepository)
final bookAdminRepositoryProvider = BookAdminRepositoryProvider._();

final class BookAdminRepositoryProvider
    extends
        $FunctionalProvider<
          BookAdminRepository,
          BookAdminRepository,
          BookAdminRepository
        >
    with $Provider<BookAdminRepository> {
  BookAdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookAdminRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookAdminRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookAdminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookAdminRepository create(Ref ref) {
    return bookAdminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookAdminRepository>(value),
    );
  }
}

String _$bookAdminRepositoryHash() =>
    r'f9b30f5c99f9410dc83f582eaa77422c374e66a2';

@ProviderFor(adminBook)
final adminBookProvider = AdminBookFamily._();

final class AdminBookProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogBook?>,
          CatalogBook?,
          Stream<CatalogBook?>
        >
    with $FutureModifier<CatalogBook?>, $StreamProvider<CatalogBook?> {
  AdminBookProvider._({
    required AdminBookFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminBookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminBookHash();

  @override
  String toString() {
    return r'adminBookProvider'
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
    return adminBook(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminBookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminBookHash() => r'4daf0a8aa04b0bfa1c75332d9c4ae59b21979d4b';

final class AdminBookFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CatalogBook?>, String> {
  AdminBookFamily._()
    : super(
        retry: null,
        name: r'adminBookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminBookProvider call(String bookId) =>
      AdminBookProvider._(argument: bookId, from: this);

  @override
  String toString() => r'adminBookProvider';
}

@ProviderFor(bookHistory)
final bookHistoryProvider = BookHistoryFamily._();

final class BookHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BookHistoryEntry>>,
          List<BookHistoryEntry>,
          Stream<List<BookHistoryEntry>>
        >
    with
        $FutureModifier<List<BookHistoryEntry>>,
        $StreamProvider<List<BookHistoryEntry>> {
  BookHistoryProvider._({
    required BookHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookHistoryHash();

  @override
  String toString() {
    return r'bookHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<BookHistoryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BookHistoryEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return bookHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookHistoryHash() => r'b103deeb8e94d455cb03f6f585ecacdb616968ee';

final class BookHistoryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<BookHistoryEntry>>, String> {
  BookHistoryFamily._()
    : super(
        retry: null,
        name: r'bookHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookHistoryProvider call(String bookId) =>
      BookHistoryProvider._(argument: bookId, from: this);

  @override
  String toString() => r'bookHistoryProvider';
}

@ProviderFor(pendingSuggestions)
final pendingSuggestionsProvider = PendingSuggestionsProvider._();

final class PendingSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BookSuggestion>>,
          List<BookSuggestion>,
          Stream<List<BookSuggestion>>
        >
    with
        $FutureModifier<List<BookSuggestion>>,
        $StreamProvider<List<BookSuggestion>> {
  PendingSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSuggestionsHash();

  @$internal
  @override
  $StreamProviderElement<List<BookSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BookSuggestion>> create(Ref ref) {
    return pendingSuggestions(ref);
  }
}

String _$pendingSuggestionsHash() =>
    r'0a16927f36724fe20caec1f920e844ed5fe5584e';

@ProviderFor(bookSuggestions)
final bookSuggestionsProvider = BookSuggestionsFamily._();

final class BookSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BookSuggestion>>,
          List<BookSuggestion>,
          Stream<List<BookSuggestion>>
        >
    with
        $FutureModifier<List<BookSuggestion>>,
        $StreamProvider<List<BookSuggestion>> {
  BookSuggestionsProvider._({
    required BookSuggestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookSuggestionsHash();

  @override
  String toString() {
    return r'bookSuggestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<BookSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BookSuggestion>> create(Ref ref) {
    final argument = this.argument as String;
    return bookSuggestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookSuggestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookSuggestionsHash() => r'48905bf4573e9131e5ea245450aeb461bf18b0ff';

final class BookSuggestionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<BookSuggestion>>, String> {
  BookSuggestionsFamily._()
    : super(
        retry: null,
        name: r'bookSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookSuggestionsProvider call(String bookId) =>
      BookSuggestionsProvider._(argument: bookId, from: this);

  @override
  String toString() => r'bookSuggestionsProvider';
}

@ProviderFor(suggestion)
final suggestionProvider = SuggestionFamily._();

final class SuggestionProvider
    extends
        $FunctionalProvider<
          AsyncValue<BookSuggestion?>,
          BookSuggestion?,
          Stream<BookSuggestion?>
        >
    with $FutureModifier<BookSuggestion?>, $StreamProvider<BookSuggestion?> {
  SuggestionProvider._({
    required SuggestionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'suggestionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$suggestionHash();

  @override
  String toString() {
    return r'suggestionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<BookSuggestion?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BookSuggestion?> create(Ref ref) {
    final argument = this.argument as String;
    return suggestion(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$suggestionHash() => r'2c4d0e1066b17de1f79cb837f031d9756839f2b5';

final class SuggestionFamily extends $Family
    with $FunctionalFamilyOverride<Stream<BookSuggestion?>, String> {
  SuggestionFamily._()
    : super(
        retry: null,
        name: r'suggestionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SuggestionProvider call(String id) =>
      SuggestionProvider._(argument: id, from: this);

  @override
  String toString() => r'suggestionProvider';
}

@ProviderFor(deletedBooks)
final deletedBooksProvider = DeletedBooksProvider._();

final class DeletedBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogBook>>,
          List<CatalogBook>,
          Stream<List<CatalogBook>>
        >
    with
        $FutureModifier<List<CatalogBook>>,
        $StreamProvider<List<CatalogBook>> {
  DeletedBooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletedBooksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedBooksHash();

  @$internal
  @override
  $StreamProviderElement<List<CatalogBook>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CatalogBook>> create(Ref ref) {
    return deletedBooks(ref);
  }
}

String _$deletedBooksHash() => r'efd4a63a1ccb1019f6c6e7d798297a3b32a9bfee';

@ProviderFor(schoolRecommendedBooks)
final schoolRecommendedBooksProvider = SchoolRecommendedBooksProvider._();

final class SchoolRecommendedBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  SchoolRecommendedBooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schoolRecommendedBooksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schoolRecommendedBooksHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return schoolRecommendedBooks(ref);
  }
}

String _$schoolRecommendedBooksHash() =>
    r'7212a44b1d5f4da62f53300822b07a0c2a4a87b5';

@ProviderFor(schoolBookReaders)
final schoolBookReadersProvider = SchoolBookReadersFamily._();

final class SchoolBookReadersProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  SchoolBookReadersProvider._({
    required SchoolBookReadersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'schoolBookReadersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$schoolBookReadersHash();

  @override
  String toString() {
    return r'schoolBookReadersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return schoolBookReaders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SchoolBookReadersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$schoolBookReadersHash() => r'9984ead23ee8f2c66e8acec3e01bb48e41426f58';

final class SchoolBookReadersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  SchoolBookReadersFamily._()
    : super(
        retry: null,
        name: r'schoolBookReadersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SchoolBookReadersProvider call(String bookId) =>
      SchoolBookReadersProvider._(argument: bookId, from: this);

  @override
  String toString() => r'schoolBookReadersProvider';
}
