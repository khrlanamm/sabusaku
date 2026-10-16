import 'package:freezed_annotation/freezed_annotation.dart';

import 'student_status.dart';

part 'student_stats.freezed.dart';

/// The active book as copied into the summary.
@freezed
abstract class ActiveProgramSummary with _$ActiveProgramSummary {
  const factory ActiveProgramSummary({
    required String programId,
    required String title,
    required String author,
    required int totalPages,
    required int currentPage,
    required int percent,
    required String startDate,
    required String targetDate,
    @Default(false) bool extended,
    @Default(false) bool overdue,
  }) = _ActiveProgramSummary;

  factory ActiveProgramSummary.fromMap(Map<String, dynamic> data) =>
      ActiveProgramSummary(
        programId: data['programId'] as String? ?? '',
        title: data['title'] as String? ?? '',
        author: data['author'] as String? ?? '',
        totalPages: data['totalPages'] as int? ?? 0,
        currentPage: data['currentPage'] as int? ?? 0,
        percent: data['percent'] as int? ?? 0,
        startDate: data['startDate'] as String? ?? '',
        targetDate: data['targetDate'] as String? ?? '',
        extended: data['extended'] == true,
        overdue: data['overdue'] == true,
      );
}

/// `schools/{schoolId}/studentStats/{studentId}` (docs/02 §3.8). Written only
/// by Cloud Functions; one document serves the student's home and one row of
/// the teacher's dashboard.
@freezed
abstract class StudentStats with _$StudentStats {
  const factory StudentStats({
    required String studentId,
    required String name,
    @Default('') String email,
    String? photoUrl,

    /// Class label, e.g. `XII-A1`.
    String? classId,
    @Default(<String>[]) List<String> extracurriculars,
    @Default(StudentStatus.belumMulai) StudentStatus status,
    @Default(0) int daysSinceLastJournal,
    ActiveProgramSummary? activeProgram,
    @Default(0) int streakCurrent,
    @Default(0) int streakBest,
    String? lastJournalDate,
    @Default(0) int journalCountMonth,
    @Default(0) int journalCountTotal,
    @Default(0) int booksCompleted,

    /// The five most recent journal dates, newest first.
    @Default(<String>[]) List<String> recentDates,
  }) = _StudentStats;

  factory StudentStats.fromMap(String id, Map<String, dynamic> data) {
    final active = data['activeProgram'];
    return StudentStats(
      studentId: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      classId: data['classId'] as String?,
      extracurriculars: List<String>.from(
        data['extracurriculars'] as List? ?? const [],
      ),
      status: StudentStatus.fromWire(data['status'] as String?),
      daysSinceLastJournal: data['daysSinceLastJournal'] as int? ?? 0,
      activeProgram: active is Map
          ? ActiveProgramSummary.fromMap(Map<String, dynamic>.from(active))
          : null,
      streakCurrent: data['streakCurrent'] as int? ?? 0,
      streakBest: data['streakBest'] as int? ?? 0,
      lastJournalDate: data['lastJournalDate'] as String?,
      journalCountMonth: data['journalCountMonth'] as int? ?? 0,
      journalCountTotal: data['journalCountTotal'] as int? ?? 0,
      booksCompleted: data['booksCompleted'] as int? ?? 0,
      recentDates: List<String>.from(data['recentDates'] as List? ?? const []),
    );
  }
}
