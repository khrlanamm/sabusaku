import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../time/date_id.dart';
import '../time/wib_clock.dart';

part 'program.freezed.dart';

enum ProgramStatus {
  active('active', 'Sedang dibaca'),
  completed('completed', 'Selesai'),
  stopped('stopped', 'Dihentikan');

  const ProgramStatus(this.wire, this.label);

  final String wire;
  final String label;

  static ProgramStatus fromWire(Object? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => ProgramStatus.stopped,
  );
}

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String title,
    required String author,
    required int totalPages,
    String? isbn,

    /// The catalog book it was picked from (`books/{bookId}`), if any.
    String? bookId,

    /// Copied from the catalog when picked, so lists show the cover without
    /// reading the catalog.
    String? coverUrl,
  }) = _Book;

  factory Book.fromMap(Map<String, dynamic>? data) => Book(
    title: data?['title'] as String? ?? '',
    author: data?['author'] as String? ?? '',
    totalPages: data?['totalPages'] as int? ?? 0,
    isbn: data?['isbn'] as String?,
    bookId: data?['bookId'] as String?,
    coverUrl: data?['coverUrl'] as String?,
  );
}

/// `schools/{schoolId}/programs/{programId}`: one book read by one student
/// (docs/02 §3.5). Progress and streak fields are written by the server.
@freezed
abstract class Program with _$Program {
  const Program._();

  const factory Program({
    required String id,
    required String studentId,
    String? classId,
    required Book book,
    required String startDate,
    required String targetDate,
    @Default(false) bool extended,
    @Default(ProgramStatus.active) ProgramStatus status,
    String? finalReflection,

    /// When the student marked the book finished.
    DateTime? completedAt,
    @Default(0) int currentPage,
    @Default(0) int journalCount,
    String? lastJournalDate,
    @Default(0) int streakCurrent,
    @Default(0) int streakBest,
  }) = _Program;

  factory Program.fromMap(String id, Map<String, dynamic> data) => Program(
    id: id,
    studentId: data['studentId'] as String? ?? '',
    classId: data['classId'] as String?,
    book: Book.fromMap(data['book'] as Map<String, dynamic>?),
    startDate: data['startDate'] as String? ?? '',
    targetDate: data['targetDate'] as String? ?? '',
    extended: data['extended'] == true,
    status: ProgramStatus.fromWire(data['status']),
    finalReflection: data['finalReflection'] as String?,
    completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    currentPage: data['currentPage'] as int? ?? 0,
    journalCount: data['journalCount'] as int? ?? 0,
    lastJournalDate: data['lastJournalDate'] as String?,
    streakCurrent: data['streakCurrent'] as int? ?? 0,
    streakBest: data['streakBest'] as int? ?? 0,
  );

  bool get isActive => status == ProgramStatus.active;

  /// 0–100, rounded down like the server does.
  int get percent => book.totalPages <= 0
      ? 0
      : (currentPage * 100 ~/ book.totalPages).clamp(0, 100);

  /// "Tandai selesai" is only offered at 100% (PRD BR-10).
  bool get isFullyRead => currentPage >= book.totalPages;

  /// Past its target and still being read (PRD BR-9).
  bool isOverdue(String today) =>
      isActive && DateId.daysBetween(targetDate, today) > 0;

  /// The WIB date it was marked finished, if it was.
  String? get completedDate =>
      completedAt == null ? null : WibClock.dateIdOf(completedAt!);
}
