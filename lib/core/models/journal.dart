import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal.freezed.dart';

/// Reading duration brackets (PRD BR-6).
enum DurationRange {
  lt15('lt15', '< 15 menit'),
  m15to30('15to30', '15–30 menit'),
  m30to60('30to60', '30–60 menit'),
  gt60('gt60', '> 60 menit');

  const DurationRange(this.wire, this.label);

  final String wire;
  final String label;

  static DurationRange fromWire(Object? value) => values.firstWhere(
    (range) => range.wire == value,
    orElse: () => DurationRange.m15to30,
  );
}

/// `.../programs/{programId}/journals/{yyyy-MM-dd}` (docs/02 §3.6). The
/// document ID is the date, which is what makes "one journal per day" a
/// database guarantee.
@freezed
abstract class Journal with _$Journal {
  const Journal._();

  const factory Journal({
    required String programId,
    required String date,
    required String studentId,
    required int pageStart,
    required int pageEnd,
    required DurationRange durationRange,
    required String keyInformation,
    String? reflection,
    String? question,
    @Default(false) bool hasUnreadTeacherComment,

    /// Written on this device and not yet acknowledged by the server.
    @Default(false) bool pendingSync,
  }) = _Journal;

  factory Journal.fromSnapshot(
    String programId,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Journal(
      programId: programId,
      date: snapshot.id,
      studentId: data['studentId'] as String? ?? '',
      pageStart: data['pageStart'] as int? ?? 1,
      pageEnd: data['pageEnd'] as int? ?? 1,
      durationRange: DurationRange.fromWire(data['durationRange']),
      keyInformation: data['keyInformation'] as String? ?? '',
      reflection: _nonEmpty(data['reflection']),
      question: _nonEmpty(data['question']),
      hasUnreadTeacherComment: data['hasUnreadTeacherComment'] == true,
      pendingSync: snapshot.metadata.hasPendingWrites,
    );
  }

  int get pagesRead => pageEnd - pageStart + 1;
}

String? _nonEmpty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// A teacher's comment on a journal (docs/02 §3.7).
@freezed
abstract class JournalComment with _$JournalComment {
  const factory JournalComment({
    required String id,
    required String teacherId,
    required String teacherName,
    required String text,
    DateTime? createdAt,
    @Default(false) bool edited,
  }) = _JournalComment;

  factory JournalComment.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    final created = (data['createdAt'] as Timestamp?)?.toDate();
    final updated = (data['updatedAt'] as Timestamp?)?.toDate();
    return JournalComment(
      id: snapshot.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? 'Guru',
      text: data['text'] as String? ?? '',
      createdAt: created,
      edited:
          created != null &&
          updated != null &&
          updated.difference(created).inSeconds.abs() > 1,
    );
  }
}
