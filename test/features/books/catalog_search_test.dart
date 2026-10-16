import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/features/books/data/catalog_repository.dart';
import 'package:sabusaku/features/books/domain/catalog_book.dart';

import 'sample_catalog.dart';

List<String> ids(List<CatalogEntry> entries) => [
  for (final entry in entries) entry.id,
];

void main() {
  test('every query word must start a word of the title or authors', () {
    expect(ids(searchCatalog(sampleEntries, 'andrea')), [
      'bk_laskar',
      'bk_pemimpi',
    ]);
    expect(ids(searchCatalog(sampleEntries, 'pram bumi')), ['bk_bumi']);
    expect(searchCatalog(sampleEntries, 'umi'), isEmpty);
  });

  test('ignores case, accents and punctuation', () {
    expect(ids(searchCatalog(sampleEntries, 'SITI nurbaya:')), ['bk_siti']);
    expect(ids(searchCatalog(sampleEntries, 'Cantík, itu')), ['bk_cantik']);
  });

  test(
    'ranks recommended, then title prefix, then school, then all readers',
    () {
      // "andrea": both titles match through the author only.
      final byReaders = searchCatalog(sampleEntries, 'andrea');
      expect(ids(byReaders), ['bk_laskar', 'bk_pemimpi']);

      final bySchool = searchCatalog(
        sampleEntries,
        'andrea',
        schoolReaders: {'bk_pemimpi': 3},
      );
      expect(ids(bySchool), ['bk_pemimpi', 'bk_laskar']);

      final recommendedFirst = searchCatalog(
        sampleEntries,
        'andrea',
        recommended: ['bk_pemimpi'],
      );
      expect(ids(recommendedFirst), ['bk_pemimpi', 'bk_laskar']);

      // "sang" is the start of a title, "sang pemimpi" beats an author match.
      final prefix = searchCatalog([
        ...sampleEntries,
        // Matches "sang" through its author only, with many more readers.
        sampleEntries.last.copyWith(
          id: 'bk_other',
          title: 'Zaman Baru',
          authors: 'Sang Penulis',
          readerCount: 99,
        ),
      ], 'sang');
      expect(ids(prefix).first, 'bk_pemimpi');
    },
  );

  test('filters by category and caps the results', () {
    expect(ids(searchCatalog(sampleEntries, '', category: 'Sastra Klasik')), [
      'bk_bumi',
      'bk_siti',
    ]);
    expect(searchCatalog(sampleEntries, '', limit: 3), hasLength(3));
  });
}
