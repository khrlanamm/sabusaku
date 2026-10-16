import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../features/auth/domain/app_user.dart';

part 'report.freezed.dart';

/// What a report is about.
enum ReportKind {
  comment('comment', 'komentar', 'Komentar'),
  journal('journal', 'jurnal', 'Jurnal'),
  book('book', 'buku', 'Buku'),
  suggestion('suggestion', 'saran', 'Saran buku'),
  user('user', 'pengguna', 'Pengguna');

  const ReportKind(this.wire, this.noun, this.label);

  final String wire;

  /// After "Laporkan": "Laporkan komentar".
  final String noun;
  final String label;

  static ReportKind fromWire(Object? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => ReportKind.comment,
  );
}

enum ReportReason {
  inappropriate('inappropriate', 'Konten tidak pantas'),
  harassment('harassment', 'Pelecehan atau perundungan'),
  personalData('personal_data', 'Membuka data pribadi orang lain'),
  copyright('copyright', 'Melanggar hak cipta'),
  wrongData('wrong_data', 'Data buku salah'),
  other('other', 'Lainnya');

  const ReportReason(this.wire, this.label);

  final String wire;
  final String label;

  static ReportReason fromWire(Object? value) => values.firstWhere(
    (reason) => reason.wire == value,
    orElse: () => ReportReason.other,
  );

  /// The reasons offered for [kind]: wrong book data only fits books and
  /// suggestions.
  static List<ReportReason> forKind(ReportKind kind) => [
    for (final reason in values)
      if (reason != wrongData ||
          kind == ReportKind.book ||
          kind == ReportKind.suggestion)
        reason,
  ];
}

/// What is reported, with the IDs the `reportContent` callable needs.
@immutable
class ReportTarget {
  const ReportTarget._(
    this.kind, {
    this.programId,
    this.date,
    this.commentId,
    this.bookId,
    this.suggestionId,
    this.userId,
    this.aboutTeacher = false,
  });

  /// A teacher's comment on a journal.
  const ReportTarget.comment({
    required String programId,
    required String date,
    required String commentId,
  }) : this._(
         ReportKind.comment,
         programId: programId,
         date: date,
         commentId: commentId,
       );

  /// A student's journal (penanggung jawab only).
  const ReportTarget.journal({required String programId, required String date})
    : this._(ReportKind.journal, programId: programId, date: date);

  /// A book of the shared catalog.
  const ReportTarget.book(String bookId)
    : this._(ReportKind.book, bookId: bookId);

  /// A student's book suggestion (penanggung jawab only).
  const ReportTarget.suggestion(String suggestionId)
    : this._(ReportKind.suggestion, suggestionId: suggestionId);

  /// Another user of the same school: their name, photo or behaviour.
  /// [teacher] when the user is a penanggung jawab.
  const ReportTarget.user(String userId, {bool teacher = false})
    : this._(ReportKind.user, userId: userId, aboutTeacher: teacher);

  factory ReportTarget.fromMap(ReportKind kind, Object? data) {
    final map = data is Map ? data : const {};
    String? text(String key) => map[key] is String ? map[key] as String : null;
    return ReportTarget._(
      kind,
      programId: text('programId'),
      date: text('date'),
      commentId: text('commentId'),
      bookId: text('bookId'),
      suggestionId: text('suggestionId'),
      userId: text('userId'),
    );
  }

  final ReportKind kind;
  final String? programId;
  final String? date;
  final String? commentId;
  final String? bookId;
  final String? suggestionId;
  final String? userId;

  /// The reported person is a penanggung jawab: their comment, or their
  /// account. The server keeps such a report from every school's list so
  /// they never see who reported them; only the developer reads it. Not sent
  /// to the callable.
  final bool aboutTeacher;

  /// Read by the developer only, never by a school's penanggung jawab.
  bool get developerOnly => kind == ReportKind.comment || aboutTeacher;

  /// The callable's arguments, without the reason and the note.
  Map<String, Object> toMap() => {
    'kind': kind.wire,
    'programId': ?programId,
    'date': ?date,
    'commentId': ?commentId,
    'bookId': ?bookId,
    'suggestionId': ?suggestionId,
    'userId': ?userId,
  };

  @override
  bool operator ==(Object other) =>
      other is ReportTarget &&
      other.kind == kind &&
      other.programId == programId &&
      other.date == date &&
      other.commentId == commentId &&
      other.bookId == bookId &&
      other.suggestionId == suggestionId &&
      other.userId == userId &&
      other.aboutTeacher == aboutTeacher;

  @override
  int get hashCode => Object.hash(
    kind,
    programId,
    date,
    commentId,
    bookId,
    suggestionId,
    userId,
    aboutTeacher,
  );

  @override
  String toString() => 'ReportTarget(${toMap()})';
}

/// `reports/{id}`: written by Cloud Functions only, read by the penanggung
/// jawab of the schools in `schools`.
@freezed
abstract class Report with _$Report {
  const Report._();

  const factory Report({
    required String id,
    required ReportKind kind,
    required ReportReason reason,
    required ReportTarget target,
    String? note,
    @Default(false) bool resolved,
    @Default('') String reporterName,
    UserRole? reporterRole,

    /// Whose content or account is reported; null for books and
    /// suggestions.
    String? subjectId,

    /// A copy of the content at report time (comment `text`, `authorName`;
    /// journal `studentName`, `date`, `keyInformation`; book `title`,
    /// `authors`, `coverUrl`; suggestion `title`, `coverUrl`; user `name`,
    /// `role`). Emptied when the reported person's data is erased.
    @Default(<String, Object?>{}) Map<String, Object?> snapshot,
    @Default(false) bool targetDeleted,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedByName,
    String? resolution,
  }) = _Report;

  factory Report.fromMap(String id, Map<String, dynamic> data) {
    final kind = ReportKind.fromWire(data['kind']);
    final snapshot = data['snapshot'];
    final resolvedBy = data['resolvedBy'];
    return Report(
      id: id,
      kind: kind,
      reason: ReportReason.fromWire(data['reason']),
      target: ReportTarget.fromMap(kind, data['target']),
      note: _nonEmpty(data['note']),
      resolved: data['status'] == 'resolved',
      reporterName: data['reporterName'] as String? ?? '',
      reporterRole: UserRole.fromWire(data['reporterRole']),
      subjectId: data['subjectId'] as String?,
      snapshot: snapshot is Map
          ? Map<String, Object?>.from(snapshot)
          : const <String, Object?>{},
      targetDeleted: data['targetDeleted'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedByName: resolvedBy is Map ? _nonEmpty(resolvedBy['name']) : null,
      resolution: _nonEmpty(data['resolution']),
    );
  }

  /// A text field of [snapshot], or null when missing or blank.
  String? snapshotText(String key) => _nonEmpty(snapshot[key]);
}

String? _nonEmpty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
