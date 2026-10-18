import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_book.dart';

part 'book_history.freezed.dart';

enum BookHistoryType {
  created('created', 'Ditambahkan'),
  updated('updated', 'Diubah'),
  deleted('deleted', 'Dihapus'),
  restored('restored', 'Diaktifkan kembali'),
  coverChanged('cover_changed', 'Cover diganti'),
  suggestionApplied('suggestion_applied', 'Saran diterapkan'),
  suggestionRejected('suggestion_rejected', 'Saran ditolak'),
  merged('merged', 'Duplikat digabung');

  const BookHistoryType(this.wire, this.label);

  final String wire;
  final String label;

  static BookHistoryType fromWire(Object? value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => BookHistoryType.updated,
  );
}

/// A field change: `{from, to}` (either may be null).
typedef FieldChange = ({Object? from, Object? to});

/// `books/{bookId}/history/{id}`, written by Cloud Functions.
@freezed
abstract class BookHistoryEntry with _$BookHistoryEntry {
  const factory BookHistoryEntry({
    required String id,
    required BookHistoryType type,
    @Default(<String, FieldChange>{}) Map<String, FieldChange> changes,
    required BookActor by,
    DateTime? at,
    String? suggestionId,
    String? note,
  }) = _BookHistoryEntry;

  factory BookHistoryEntry.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['changes'];
    return BookHistoryEntry(
      id: id,
      type: BookHistoryType.fromWire(data['type']),
      changes: {
        if (raw is Map)
          for (final MapEntry(:key, :value) in raw.entries)
            if (value is Map)
              key as String: (from: value['from'], to: value['to']),
      },
      by: BookActor.fromMap(data['by']),
      at: (data['at'] as Timestamp?)?.toDate(),
      suggestionId: data['suggestionId'] as String?,
      note: data['note'] as String?,
    );
  }
}
