import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_book.dart';

part 'book_suggestion.freezed.dart';

enum SuggestionKind { edit, newBook }

enum SuggestionStatus { pending, accepted, rejected }

/// Where a suggestion came from. No student name: other schools' teachers
/// see suggestions too.
typedef SuggestionSource = ({
  String schoolId,
  String schoolName,
  String programId,
});

/// `bookSuggestions/{id}`, written by Cloud Functions when a student starts
/// a book whose details differ from the catalog (`edit`) or that is not in
/// it (`new`). Identical proposals are merged and counted.
@freezed
abstract class BookSuggestion with _$BookSuggestion {
  const BookSuggestion._();

  const factory BookSuggestion({
    required String id,
    required SuggestionKind kind,
    String? bookId,

    /// Proposed values, keyed like `books` fields (`title`, `authors`,
    /// `pageCount`, `isbn13`…). For `edit` only the fields that differ.
    @Default(<String, Object?>{}) Map<String, Object?> proposed,
    @Default(1) int count,
    @Default(<SuggestionSource>[]) List<SuggestionSource> from,
    @Default(SuggestionStatus.pending) SuggestionStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
    BookActor? reviewedBy,
    DateTime? reviewedAt,
    String? resultBookId,
  }) = _BookSuggestion;

  factory BookSuggestion.fromMap(
    String id,
    Map<String, dynamic> data,
  ) => BookSuggestion(
    id: id,
    kind: data['kind'] == 'new' ? SuggestionKind.newBook : SuggestionKind.edit,
    bookId: data['bookId'] as String?,
    proposed: Map<String, Object?>.from(data['proposed'] as Map? ?? const {}),
    count: data['count'] as int? ?? 1,
    from: [
      for (final item in data['from'] as List? ?? const [])
        if (item is Map)
          (
            schoolId: item['schoolId'] as String? ?? '',
            schoolName: item['schoolName'] as String? ?? '',
            programId: item['programId'] as String? ?? '',
          ),
    ],
    status: switch (data['status']) {
      'accepted' => SuggestionStatus.accepted,
      'rejected' => SuggestionStatus.rejected,
      _ => SuggestionStatus.pending,
    },
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    reviewedBy: data['reviewedBy'] == null
        ? null
        : BookActor.fromMap(data['reviewedBy']),
    reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    resultBookId: data['resultBookId'] as String?,
  );

  bool get pending => status == SuggestionStatus.pending;
}
