import 'package:freezed_annotation/freezed_annotation.dart';

import '../../features/auth/domain/app_user.dart';

part 'member.freezed.dart';

/// `members/{email}` (docs/02): who belongs to which school. The document ID
/// is the lower-case email, so one email belongs to at most one school.
/// Written by Cloud Functions; a teacher may edit a student or teacher entry
/// until that person signs in for the first time.
@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required String email,
    required String schoolId,
    required UserRole role,
    @Default('') String name,

    /// Class label, e.g. `XII-A1`.
    String? classId,
    @Default(<String>[]) List<String> extracurriculars,

    /// Teachers: the class they are the homeroom teacher of.
    String? homeroomClass,

    /// Set once the account signed in and claimed this entry.
    String? uid,
  }) = _Member;

  factory Member.fromMap(String email, Map<String, dynamic> data) => Member(
    email: data['email'] as String? ?? email,
    schoolId: data['schoolId'] as String? ?? '',
    role: UserRole.fromWire(data['role']) ?? UserRole.siswa,
    name: data['name'] as String? ?? '',
    classId: data['classId'] as String?,
    extracurriculars: List<String>.from(
      data['extracurriculars'] as List? ?? const [],
    ),
    homeroomClass: data['homeroomClass'] as String?,
    uid: data['uid'] as String?,
  );

  /// Added by a teacher, but the person has not signed in yet.
  bool get pending => uid == null;
}

/// One student to add through the `addStudents` callable. Only the email is
/// required; the student completes the rest at first sign-in.
@freezed
abstract class NewStudent with _$NewStudent {
  const NewStudent._();

  const factory NewStudent({
    required String email,
    @Default('') String name,
    String? classId,
    @Default(<String>[]) List<String> extracurriculars,
  }) = _NewStudent;

  Map<String, dynamic> toMap() => {
    'email': email,
    if (name.isNotEmpty) 'name': name,
    if (classId != null) 'classId': classId,
    if (extracurriculars.isNotEmpty) 'extracurriculars': extracurriculars,
  };
}

/// Per-row outcome of `addStudents`.
@freezed
abstract class AddStudentResult with _$AddStudentResult {
  const factory AddStudentResult({
    required String email,
    required bool ok,
    String? reason,
  }) = _AddStudentResult;

  factory AddStudentResult.fromMap(Map<String, dynamic> data) =>
      AddStudentResult(
        email: data['email'] as String? ?? '',
        ok: data['ok'] == true,
        reason: data['reason'] as String?,
      );
}
