import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/reading_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/student_status.dart';
import '../../../core/utils/streams.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';

part 'teacher_repository.g.dart';

/// What a teacher reads and writes: student summaries of the assigned
/// classes, and comments on their journals.
class TeacherRepository {
  TeacherRepository(this._functions, this._reading, this._session);

  final FirebaseFunctions _functions;
  final ReadingRepository _reading;
  final Session _session;

  /// One class per query, as an equality filter, so the rules can prove the
  /// teacher is assigned to it (docs/02 §3.8). Avoids `whereIn`.
  Stream<List<StudentStats>> watchClassStats(String classId) => _reading.stats
      .where('classId', isEqualTo: classId)
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            StudentStats.fromMap(doc.id, doc.data()),
        ],
      );

  /// All students of the assigned classes, merged and sorted by name.
  Stream<List<StudentStats>> watchStudents() =>
      combineLatest([
        for (final classId in _session.classIds) watchClassStats(classId),
      ]).map(
        (lists) => lists.expand((list) => list).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
      );

  Future<void> addComment(String programId, String date, String text) => _guard(
    () => _reading.comments(programId, date).add({
      'teacherId': _session.uid,
      // Must equal the profile name; the rules check it.
      'teacherName': _session.profile.name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<void> updateComment(
    String programId,
    String date,
    String commentId,
    String text,
  ) => _guard(
    () => _reading.comments(programId, date).doc(commentId).update({
      'text': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<void> deleteComment(String programId, String date, String commentId) =>
      _guard(() => _reading.comments(programId, date).doc(commentId).delete());

  /// Temporary password for a student of an assigned class. Shown once.
  Future<String> resetStudentPassword(String studentId) => _guard(() async {
    final result = await _functions
        .httpsCallable('resetPassword')
        .call<Object?>({'uid': studentId});
    return (result.data as Map)['password'] as String;
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapError(error);
    }
  }
}

@riverpod
TeacherRepository teacherRepository(Ref ref) => TeacherRepository(
  ref.watch(functionsProvider),
  ref.watch(readingRepositoryProvider),
  ref.watch(currentSessionProvider),
);

@riverpod
Stream<List<StudentStats>> teacherStudents(Ref ref) =>
    ref.watch(teacherRepositoryProvider).watchStudents();

/// One student's summary. Readable only while the student is in one of the
/// teacher's classes.
@riverpod
Stream<StudentStats?> studentStats(Ref ref, String studentId) =>
    ref.watch(readingRepositoryProvider).watchStats(studentId);

/// A student's books. The class filter is what lets the rules allow the
/// query (docs/03 §3).
@riverpod
Stream<List<Program>> studentPrograms(
  Ref ref,
  String studentId,
  String classId,
) => ref
    .watch(readingRepositoryProvider)
    .watchPrograms(studentId, classId: classId);

typedef StudentFilter = ({String? classId, StudentStatus? status});

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered by a status.
@riverpod
class StudentListFilter extends _$StudentListFilter {
  @override
  StudentFilter build() => (classId: null, status: null);

  void setClass(String? classId) =>
      state = (classId: classId, status: state.status);

  void setStatus(StudentStatus? status) =>
      state = (classId: state.classId, status: status);
}
