import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

enum UserRole {
  guru('guru', 'Penanggung jawab'),
  siswa('siswa', 'Siswa');

  const UserRole(this.wire, this.label);

  /// Value stored in Firestore and in the custom claim.
  final String wire;
  final String label;

  static UserRole? fromWire(Object? value) {
    for (final role in values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

/// `schools/{schoolId}/users/{uid}` (docs/02 §3.2).
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    required UserRole role,

    /// Empty until the user completes their profile.
    @Default('') String name,
    @Default('') String email,

    /// Students: their class label, e.g. `XII-A1`. Null until chosen.
    String? classId,

    /// Extracurricular labels, e.g. `Masis-KIR`. Teachers: the ones they
    /// supervise.
    @Default(<String>[]) List<String> extracurriculars,
    String? photoUrl,

    /// False once a teacher removed the student from the school.
    @Default(true) bool active,

    /// The version of the terms of use the user accepted; 0 when none.
    /// Written by the `acceptTerms` callable only.
    @Default(0) int termsVersion,
  }) = _AppUser;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
    uid: uid,
    role: UserRole.fromWire(data['role']) ?? UserRole.siswa,
    name: data['name'] as String? ?? '',
    email: data['email'] as String? ?? '',
    classId: data['classId'] as String?,
    extracurriculars: List<String>.from(
      data['extracurriculars'] as List? ?? const [],
    ),
    photoUrl: data['photoUrl'] as String?,
    active: data['status'] != 'removed',
    termsVersion: (data['termsVersion'] as num?)?.toInt() ?? 0,
  );

  /// Name and, for a student, class are required before using the app.
  bool get profileComplete =>
      name.trim().length >= 2 && (role != UserRole.siswa || classId != null);
}
