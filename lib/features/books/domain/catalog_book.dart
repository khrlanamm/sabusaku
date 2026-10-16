import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_book.freezed.dart';

/// Who did something to the catalog. Imported books have kind `import`.
@freezed
abstract class BookActor with _$BookActor {
  const factory BookActor({
    String? uid,
    @Default('') String name,
    String? schoolId,
    String? schoolName,

    /// `import`, `guru` or `siswa`.
    @Default('guru') String kind,
  }) = _BookActor;

  factory BookActor.fromMap(Object? data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : const {};
    return BookActor(
      uid: map['uid'] as String?,
      name: map['name'] as String? ?? '',
      schoolId: map['schoolId'] as String?,
      schoolName: map['schoolName'] as String?,
      kind: map['kind'] as String? ?? 'guru',
    );
  }
}

/// `books/{bookId}`: one book of the shared catalog (all schools).
@freezed
abstract class CatalogBook with _$CatalogBook {
  const CatalogBook._();

  const factory CatalogBook({
    required String id,
    required String title,
    String? subtitle,
    @Default(<String>[]) List<String> authors,
    String? publisher,
    int? publishedYear,
    String? isbn13,
    String? isbn10,
    @Default(0) int pageCount,
    @Default(<String>[]) List<String> categories,
    String? description,
    String? coverUrl,

    /// `active` or `deleted` (soft delete; any teacher can restore).
    @Default(true) bool active,
    DateTime? deletedAt,
    BookActor? deletedBy,
    String? deleteReason,
    String? duplicateOf,
    @Default(0) int readerCount,
    BookActor? createdBy,
    DateTime? updatedAt,
    BookActor? updatedBy,
    @Default(1) int version,
  }) = _CatalogBook;

  factory CatalogBook.fromMap(String id, Map<String, dynamic> data) =>
      CatalogBook(
        id: id,
        title: data['title'] as String? ?? '',
        subtitle: data['subtitle'] as String?,
        authors: List<String>.from(data['authors'] as List? ?? const []),
        publisher: data['publisher'] as String?,
        publishedYear: data['publishedYear'] as int?,
        isbn13: data['isbn13'] as String?,
        isbn10: data['isbn10'] as String?,
        pageCount: data['pageCount'] as int? ?? 0,
        categories: List<String>.from(data['categories'] as List? ?? const []),
        description: data['description'] as String?,
        coverUrl: data['coverUrl'] as String?,
        active: data['status'] != 'deleted',
        deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
        deletedBy: data['deletedBy'] == null
            ? null
            : BookActor.fromMap(data['deletedBy']),
        deleteReason: data['deleteReason'] as String?,
        duplicateOf: data['duplicateOf'] as String?,
        readerCount: data['readerCount'] as int? ?? 0,
        createdBy: data['createdBy'] == null
            ? null
            : BookActor.fromMap(data['createdBy']),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        updatedBy: data['updatedBy'] == null
            ? null
            : BookActor.fromMap(data['updatedBy']),
        version: data['version'] as int? ?? 1,
      );

  String get authorLine => authors.join(', ');

  /// The fields a teacher edits, as sent to `saveBook`.
  Map<String, dynamic> toFields() => {
    'title': title,
    'subtitle': subtitle,
    'authors': authors,
    'publisher': publisher,
    'publishedYear': publishedYear,
    'isbn13': isbn13,
    'isbn10': isbn10,
    'pageCount': pageCount,
    'categories': categories,
    'description': description,
  };
}

/// One entry of the search index (`catalog/shard-{n}.entries.{bookId}`).
/// Compact keys keep the four index documents small.
@freezed
abstract class CatalogEntry with _$CatalogEntry {
  const CatalogEntry._();

  const factory CatalogEntry({
    required String id,
    required String title,
    @Default('') String authors,
    @Default(0) int pageCount,
    int? year,
    String? coverUrl,
    @Default(<String>[]) List<String> categories,
    @Default(0) int readerCount,
  }) = _CatalogEntry;

  /// `{t: title, a: "Author, Author", p: pages, y: year, c: coverUrl,
  /// g: categories, r: readerCount}`.
  factory CatalogEntry.fromMap(String id, Map<String, dynamic> data) =>
      CatalogEntry(
        id: id,
        title: data['t'] as String? ?? '',
        authors: data['a'] as String? ?? '',
        pageCount: data['p'] as int? ?? 0,
        year: data['y'] as int?,
        coverUrl: data['c'] as String?,
        categories: List<String>.from(data['g'] as List? ?? const []),
        readerCount: data['r'] as int? ?? 0,
      );

  String get searchText => '$title $authors';
}
