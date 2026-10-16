import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/utils/streams.dart';
import '../../../core/utils/text_search.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/school_repository.dart';
import '../domain/book_categories.dart';
import '../domain/catalog_book.dart';

part 'catalog_repository.g.dart';

/// Thrown by [catalogIndex] when the device is offline and has never loaded
/// the catalog, so there is nothing to search yet.
const catalogNotLoaded = AppException(
  AppErrorCode.network,
  message:
      'Katalog buku belum termuat. Sambungkan internet sekali untuk '
      'memuatnya; setelah itu katalog bisa dicari tanpa sinyal.',
);

/// `catalog/shard-{n}.entries`, active books only.
List<CatalogEntry> _entriesOf(DocumentSnapshot<Map<String, dynamic>> shard) {
  final entries = shard.data()?['entries'];
  if (entries is! Map) return const [];
  return [
    for (final MapEntry(:key, :value) in entries.entries)
      if (value is Map)
        CatalogEntry.fromMap(key as String, Map<String, dynamic>.from(value)),
  ];
}

/// The whole search index: the four shard documents merged, sorted by title.
/// The documents stay in Firestore's offline cache, so search works without
/// a signal once the catalog has loaded.
@Riverpod(keepAlive: true)
Stream<List<CatalogEntry>> catalogIndex(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return combineLatest([
    for (var shard = 0; shard < catalogShards; shard++)
      firestore.doc('catalog/shard-$shard').snapshots(),
  ]).map((shards) {
    final neverLoaded = shards.every(
      (shard) => !shard.exists && shard.metadata.isFromCache,
    );
    if (neverLoaded) throw catalogNotLoaded;
    return [for (final shard in shards) ..._entriesOf(shard)]..sort(
      (a, b) =>
          normalizeSearchText(a.title).compareTo(normalizeSearchText(b.title)),
    );
  });
}

/// One catalog book (`books/{bookId}`), or null when it does not exist.
@riverpod
Stream<CatalogBook?> catalogBook(Ref ref, String bookId) => ref
    .watch(firestoreProvider)
    .doc('books/$bookId')
    .snapshots()
    .map(
      (snapshot) => snapshot.exists
          ? CatalogBook.fromMap(snapshot.id, snapshot.data()!)
          : null,
    );

/// Readers of each catalog book in the signed-in user's school
/// (`schools/{s}/bookStats`, written by the server).
@riverpod
Stream<Map<String, ({int readers, int active})>> schoolBookStats(Ref ref) {
  final schoolId = ref.watch(currentSessionProvider.select((s) => s.schoolId));
  return ref
      .watch(firestoreProvider)
      .collection('schools/$schoolId/bookStats')
      .snapshots()
      .map(
        (snapshot) => {
          for (final doc in snapshot.docs)
            doc.id: (
              readers: doc.data()['readers'] as int? ?? 0,
              active: doc.data()['active'] as int? ?? 0,
            ),
        },
      );
}

/// Books the school's teachers recommend (`schools/{s}.recommendedBooks`).
@riverpod
List<String> recommendedBookIds(Ref ref) =>
    ref.watch(schoolProvider).value?.recommendedBooks ?? const [];

/// Filters [entries] by [query] and [category] and ranks them:
///   1. recommended by the school,
///   2. the title starts with the query,
///   3. most readers in the school,
///   4. most readers overall,
///   5. title.
///
/// Matching ignores case, accents and punctuation; every word of the query
/// must start some word of the title or the authors.
List<CatalogEntry> searchCatalog(
  List<CatalogEntry> entries,
  String query, {
  String? category,
  List<String> recommended = const [],
  Map<String, int> schoolReaders = const {},
  int? limit,
}) {
  final normalQuery = normalizeSearchText(query);
  final recommendedSet = recommended.toSet();
  final scored = [
    for (final entry in entries)
      if ((category == null || entry.categories.contains(category)) &&
          matchesQuery(entry.searchText, query))
        (
          entry: entry,
          recommended: recommendedSet.contains(entry.id),
          titlePrefix:
              normalQuery.isNotEmpty &&
              normalizeSearchText(entry.title).startsWith(normalQuery),
          school: schoolReaders[entry.id] ?? 0,
          title: normalizeSearchText(entry.title),
        ),
  ];
  int flag(bool value) => value ? 0 : 1;
  scored.sort((a, b) {
    var order = flag(a.recommended).compareTo(flag(b.recommended));
    if (order != 0) return order;
    order = flag(a.titlePrefix).compareTo(flag(b.titlePrefix));
    if (order != 0) return order;
    order = b.school.compareTo(a.school);
    if (order != 0) return order;
    order = b.entry.readerCount.compareTo(a.entry.readerCount);
    if (order != 0) return order;
    return a.title.compareTo(b.title);
  });
  final ranked = [for (final item in scored) item.entry];
  return limit == null || ranked.length <= limit
      ? ranked
      : ranked.sublist(0, limit);
}

/// A catalog book chosen outside the start form ("Baca buku ini" on the
/// book's page). The form takes it once and clears it.
@Riverpod(keepAlive: true)
class PendingBookPick extends _$PendingBookPick {
  @override
  CatalogEntry? build() => null;

  void pick(CatalogEntry entry) => state = entry;

  void clear() => state = null;
}

/// The index entry of a full catalog book, for handing it to the start form.
CatalogEntry entryOfBook(CatalogBook book) => CatalogEntry(
  id: book.id,
  title: book.title,
  authors: book.authorLine,
  pageCount: book.pageCount,
  year: book.publishedYear,
  coverUrl: book.coverUrl,
  categories: book.categories,
  readerCount: book.readerCount,
);
