import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../domain/book_history.dart';
import '../domain/book_suggestion.dart';
import '../domain/catalog_book.dart';

part 'book_admin_repository.g.dart';

/// `saveBook` refused a new book because an active one with the same ISBN
/// or title and author exists.
class BookExistsException implements Exception {
  const BookExistsException(this.bookId, this.message);

  final String bookId;
  final String message;

  @override
  String toString() => 'BookExistsException($bookId)';
}

/// What a teacher (penanggung jawab) of any school reads and changes in the
/// shared book catalog. Every catalog write goes through a callable so the
/// server records it in the book's history; only the school's own
/// recommendations are written directly.
class BookAdminRepository {
  BookAdminRepository(
    this._firestore,
    this._functions,
    this._storage,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final Session _session;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection('books');
  CollectionReference<Map<String, dynamic>> get _suggestions =>
      _firestore.collection('bookSuggestions');
  DocumentReference<Map<String, dynamic>> get _school =>
      _firestore.doc('schools/${_session.schoolId}');

  // ---------- Reads ----------

  /// One book, deleted ones included. Null when the ID does not exist.
  Stream<CatalogBook?> watchBook(String bookId) => _books
      .doc(bookId)
      .snapshots()
      .map(
        (doc) => doc.exists ? CatalogBook.fromMap(doc.id, doc.data()!) : null,
      );

  /// The book's history, newest first.
  Stream<List<BookHistoryEntry>> watchHistory(String bookId) => _books
      .doc(bookId)
      .collection('history')
      .orderBy('at', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            BookHistoryEntry.fromMap(doc.id, doc.data()),
        ],
      );

  /// Every pending suggestion, newest activity first. Sorted on the device:
  /// an equality filter alone needs no composite index.
  Stream<List<BookSuggestion>> watchPendingSuggestions() => _suggestions
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => _sortedSuggestions(snapshot.docs));

  /// Pending suggestions for one book.
  Stream<List<BookSuggestion>> watchBookSuggestions(String bookId) =>
      _suggestions
          .where('bookId', isEqualTo: bookId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => _sortedSuggestions(snapshot.docs));

  Stream<BookSuggestion?> watchSuggestion(String id) => _suggestions
      .doc(id)
      .snapshots()
      .map(
        (doc) =>
            doc.exists ? BookSuggestion.fromMap(doc.id, doc.data()!) : null,
      );

  /// Soft-deleted books, most recently deleted first.
  Stream<List<CatalogBook>> watchDeletedBooks() => _books
      .where('status', isEqualTo: 'deleted')
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final doc in snapshot.docs)
                CatalogBook.fromMap(doc.id, doc.data()),
            ]..sort(
              (a, b) => (b.deletedAt ?? DateTime(2000)).compareTo(
                a.deletedAt ?? DateTime(2000),
              ),
            ),
      );

  /// This school's recommended book IDs (`schools/{s}.recommendedBooks`).
  Stream<List<String>> watchRecommended() => _school.snapshots().map(
    (doc) =>
        List<String>.from(doc.data()?['recommendedBooks'] as List? ?? const []),
  );

  /// How many students of this school have read or are reading the book.
  Stream<int> watchSchoolReaders(String bookId) => _school
      .collection('bookStats')
      .doc(bookId)
      .snapshots()
      .map((doc) => doc.data()?['readers'] as int? ?? 0);

  static List<BookSuggestion> _sortedSuggestions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) =>
      [for (final doc in docs) BookSuggestion.fromMap(doc.id, doc.data())]
        ..sort(
          (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
            a.updatedAt ?? a.createdAt ?? DateTime(2000),
          ),
        );

  // ---------- Writes ----------

  /// Creates ([bookId] null) or updates a book. Returns its ID.
  ///
  /// Throws [BookExistsException] when a new book matches an existing one.
  Future<String> saveBook({
    String? bookId,
    required Map<String, dynamic> fields,
  }) async {
    final data = await _call('saveBook', {'bookId': ?bookId, 'fields': fields});
    return data['bookId'] as String;
  }

  /// Moves the book to "Buku terhapus". Any teacher can restore it.
  Future<void> deleteBook(
    String bookId, {
    String? reason,
    String? duplicateOf,
  }) => _call('deleteBook', {
    'bookId': bookId,
    if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    'duplicateOf': ?duplicateOf,
  });

  Future<void> restoreBook(String bookId) =>
      _call('restoreBook', {'bookId': bookId});

  /// Uploads a new cover and lets the server attach it. Returns its URL.
  Future<String> uploadCover(
    String bookId,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'books/$bookId/cover-$stamp.jpg';
    await _guard(
      () => _storage
          .ref(path)
          .putData(bytes, SettableMetadata(contentType: contentType)),
    );
    final data = await _call('setBookCover', {'bookId': bookId, 'path': path});
    return data['coverUrl'] as String;
  }

  /// Applies selected [fields] of an `edit` suggestion (all when null).
  Future<void> applySuggestion(String id, {List<String>? fields}) => _call(
    'reviewSuggestion',
    {'id': id, 'action': 'apply', 'fields': ?fields},
  );

  Future<void> rejectSuggestion(String id) =>
      _call('reviewSuggestion', {'id': id, 'action': 'reject'});

  /// Adds a `new` suggestion to the catalog with the teacher's corrections.
  /// Returns the new book's ID.
  Future<String> createFromSuggestion(
    String id,
    Map<String, dynamic> book,
  ) async {
    final data = await _call('reviewSuggestion', {
      'id': id,
      'action': 'create',
      'book': book,
    });
    return data['bookId'] as String;
  }

  /// Marks a `new` suggestion as the existing book [bookId].
  Future<void> linkSuggestion(String id, String bookId) =>
      _call('reviewSuggestion', {'id': id, 'action': 'link', 'bookId': bookId});

  /// Adds or removes the book from this school's recommendations.
  Future<void> setRecommended(String bookId, {required bool recommended}) =>
      _guard(
        () => _school.update({
          'recommendedBooks': recommended
              ? FieldValue.arrayUnion([bookId])
              : FieldValue.arrayRemove([bookId]),
        }),
      );

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      return Map<String, dynamic>.from(result.data as Map? ?? const {});
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      if (error.code == 'already-exists' &&
          details is Map &&
          details['bookId'] is String) {
        throw BookExistsException(
          details['bookId'] as String,
          error.message ?? 'Buku ini sudah ada di katalog.',
        );
      }
      throw mapError(error);
    } catch (error) {
      throw mapError(error);
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapError(error);
    }
  }
}

@riverpod
BookAdminRepository bookAdminRepository(Ref ref) => BookAdminRepository(
  ref.watch(firestoreProvider),
  ref.watch(functionsProvider),
  ref.watch(storageProvider),
  ref.watch(currentSessionProvider),
);

@riverpod
Stream<CatalogBook?> adminBook(Ref ref, String bookId) =>
    ref.watch(bookAdminRepositoryProvider).watchBook(bookId);

@riverpod
Stream<List<BookHistoryEntry>> bookHistory(Ref ref, String bookId) =>
    ref.watch(bookAdminRepositoryProvider).watchHistory(bookId);

@riverpod
Stream<List<BookSuggestion>> pendingSuggestions(Ref ref) =>
    ref.watch(bookAdminRepositoryProvider).watchPendingSuggestions();

@riverpod
Stream<List<BookSuggestion>> bookSuggestions(Ref ref, String bookId) =>
    ref.watch(bookAdminRepositoryProvider).watchBookSuggestions(bookId);

@riverpod
Stream<BookSuggestion?> suggestion(Ref ref, String id) =>
    ref.watch(bookAdminRepositoryProvider).watchSuggestion(id);

@riverpod
Stream<List<CatalogBook>> deletedBooks(Ref ref) =>
    ref.watch(bookAdminRepositoryProvider).watchDeletedBooks();

@riverpod
Stream<List<String>> schoolRecommendedBooks(Ref ref) =>
    ref.watch(bookAdminRepositoryProvider).watchRecommended();

@riverpod
Stream<int> schoolBookReaders(Ref ref, String bookId) =>
    ref.watch(bookAdminRepositoryProvider).watchSchoolReaders(bookId);
