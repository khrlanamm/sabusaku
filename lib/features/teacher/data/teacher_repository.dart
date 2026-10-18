import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/reading_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/member.dart';
import '../../../core/models/program.dart';
import '../../../core/models/school.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/student_status.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/session.dart';

part 'teacher_repository.g.dart';

/// What a teacher (penanggung jawab) reads and writes: every student of the
/// school, the students and teachers added but not signed in yet, the
/// school's class and extracurricular labels and settings, and comments on
/// journals.
///
/// Adding, removing and erasing students and teachers go through callables;
/// edits the rules allow (names, labels, settings) are written directly.
class TeacherRepository {
  TeacherRepository(
    this._firestore,
    this._functions,
    this._reading,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final ReadingRepository _reading;
  final Session _session;

  DocumentReference<Map<String, dynamic>> get _school =>
      _firestore.doc('schools/${_session.schoolId}');
  CollectionReference<Map<String, dynamic>> get _users =>
      _school.collection('users');
  CollectionReference<Map<String, dynamic>> get _members =>
      _firestore.collection('members');

  // ---------- Students ----------

  /// Every signed-in student of the school, sorted by name.
  Stream<List<StudentStats>> watchStudents() => _reading.stats
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            StudentStats.fromMap(doc.id, doc.data()),
        ],
      );

  /// Students added by a teacher who have not signed in yet.
  Stream<List<Member>> watchPendingStudents() => _watchPending(UserRole.siswa);

  /// Teachers added by another teacher who have not signed in yet.
  Stream<List<Member>> watchPendingTeachers() => _watchPending(UserRole.guru);

  Stream<List<Member>> _watchPending(UserRole role) => _members
      .where('schoolId', isEqualTo: _session.schoolId)
      .where('role', isEqualTo: role.wire)
      .snapshots()
      .map(
        (snapshot) =>
            [
                for (final doc in snapshot.docs)
                  Member.fromMap(doc.id, doc.data()),
              ].where((member) => member.pending).toList()
              ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b))),
      );

  static String _sortKey(Member member) =>
      (member.name.isEmpty ? member.email : member.name).toLowerCase();

  Stream<Member?> watchMember(String email) => _members
      .doc(email)
      .snapshots()
      .map((doc) => doc.exists ? Member.fromMap(doc.id, doc.data()!) : null);

  /// The school's penanggung jawab, sorted by name.
  Stream<List<AppUser>> watchTeachers() => _users
      .where('role', isEqualTo: UserRole.guru.wire)
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final doc in snapshot.docs)
                AppUser.fromMap(doc.id, doc.data()),
            ].where((user) => user.active).toList()..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
      );

  /// At most 100 students per call; larger imports are split by the caller.
  Future<List<AddStudentResult>> addStudents(List<NewStudent> students) async {
    final data = await _call('addStudents', {
      'students': [for (final student in students) student.toMap()],
    });
    return [
      for (final row in data['results'] as List)
        AddStudentResult.fromMap(Map<String, dynamic>.from(row as Map)),
    ];
  }

  /// Takes the student out of the school. Their account stays; their
  /// journals come back if they are added again.
  Future<void> removeStudent(String email) =>
      _call('removeStudent', {'email': email});

  /// Permanently deletes the student's data in this school. Their account
  /// stays. Returns the number of books removed.
  Future<int> eraseStudent(String email) async =>
      (await _call('eraseStudent', {'email': email}))['programs'] as int? ?? 0;

  /// Edits a signed-in student's profile.
  Future<void> updateStudent(
    String uid, {
    required String name,
    required String? classId,
    required List<String> extracurriculars,
  }) => _guard(
    () => _users.doc(uid).update({
      'name': name,
      'classId': classId,
      'extracurriculars': extracurriculars,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  /// Edits a student who has not signed in yet.
  Future<void> updatePendingStudent(
    String email, {
    required String name,
    required String? classId,
    required List<String> extracurriculars,
  }) => _guard(
    () => _members.doc(email).update({
      'name': name,
      'classId': classId,
      'extracurriculars': extracurriculars,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  // ---------- Teachers ----------

  /// Puts another teacher on the school roster. Returns whether they joined
  /// right away (they already had a verified account with that email).
  Future<bool> addTeacher({
    required String email,
    required String name,
    String? homeroomClass,
    List<String> extracurriculars = const [],
  }) async {
    final data = await _call('addTeacher', {
      'email': email,
      'name': name,
      'homeroomClass': ?homeroomClass,
      if (extracurriculars.isNotEmpty) 'extracurriculars': extracurriculars,
    });
    return data['joined'] == true;
  }

  /// Takes another teacher out of the school, or withdraws the invitation of
  /// one who has not signed in yet. Their account stays.
  Future<void> removeTeacher(String email) =>
      _call('removeTeacher', {'email': email});

  /// Edits a teacher who has not signed in yet. Afterwards their roles are
  /// theirs to change.
  Future<void> updatePendingTeacher(
    String email, {
    required String name,
    required String? homeroomClass,
    required List<String> extracurriculars,
  }) => _guard(
    () => _members.doc(email).update({
      'name': name,
      'homeroomClass': homeroomClass,
      'extracurriculars': extracurriculars,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  // ---------- School labels and settings ----------

  Future<void> addClassLabel(String label) => _guard(
    () => _school.update({
      'classes': FieldValue.arrayUnion([label]),
    }),
  );

  /// Students keep the label they have; it only leaves the choices.
  Future<void> removeClassLabel(String label) => _guard(
    () => _school.update({
      'classes': FieldValue.arrayRemove([label]),
    }),
  );

  Future<void> addExtracurricular(String label) => _guard(
    () => _school.update({
      'extracurriculars': FieldValue.arrayUnion([label]),
    }),
  );

  Future<void> removeExtracurricular(String label) => _guard(
    () => _school.update({
      'extracurriculars': FieldValue.arrayRemove([label]),
    }),
  );

  Future<void> updateSettings(SchoolSettings settings) =>
      _guard(() => _school.update({'settings': settings.toMap()}));

  // ---------- Comments ----------

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

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) =>
      _guard(() async {
        final result = await _functions.httpsCallable(name).call<Object?>(data);
        return Map<String, dynamic>.from(result.data as Map? ?? const {});
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
  ref.watch(firestoreProvider),
  ref.watch(functionsProvider),
  ref.watch(readingRepositoryProvider),
  ref.watch(currentSessionProvider),
);

@riverpod
Stream<List<StudentStats>> teacherStudents(Ref ref) =>
    ref.watch(teacherRepositoryProvider).watchStudents();

@riverpod
Stream<List<Member>> pendingStudents(Ref ref) =>
    ref.watch(teacherRepositoryProvider).watchPendingStudents();

@riverpod
Stream<List<Member>> pendingTeachers(Ref ref) =>
    ref.watch(teacherRepositoryProvider).watchPendingTeachers();

@riverpod
Stream<Member?> member(Ref ref, String email) =>
    ref.watch(teacherRepositoryProvider).watchMember(email);

@riverpod
Stream<List<AppUser>> schoolTeachers(Ref ref) =>
    ref.watch(teacherRepositoryProvider).watchTeachers();

/// One student's summary. Gone once the student is removed from the school.
@riverpod
Stream<StudentStats?> studentStats(Ref ref, String studentId) =>
    ref.watch(readingRepositoryProvider).watchStats(studentId);

/// A student's books, newest first.
@riverpod
Stream<List<Program>> studentPrograms(Ref ref, String studentId) =>
    ref.watch(readingRepositoryProvider).watchPrograms(studentId);

typedef StudentFilter = ({
  String? classId,
  String? extracurricular,
  StudentStatus? status,
});

/// Filter of the student list. Shared so the dashboard can open the list
/// already filtered.
@riverpod
class StudentListFilter extends _$StudentListFilter {
  @override
  StudentFilter build() => (classId: null, extracurricular: null, status: null);

  void setClass(String? classId) => state = (
    classId: classId,
    extracurricular: state.extracurricular,
    status: state.status,
  );

  void setExtracurricular(String? extracurricular) => state = (
    classId: state.classId,
    extracurricular: extracurricular,
    status: state.status,
  );

  void setStatus(StudentStatus? status) => state = (
    classId: state.classId,
    extracurricular: state.extracurricular,
    status: status,
  );

  void reset() => state = (classId: null, extracurricular: null, status: null);
}

/// Whether [filter] keeps a student with these labels.
bool matchesLabels(
  StudentFilter filter, {
  required String? classId,
  required List<String> extracurriculars,
}) =>
    (filter.classId == null || classId == filter.classId) &&
    (filter.extracurricular == null ||
        extracurriculars.contains(filter.extracurricular));
