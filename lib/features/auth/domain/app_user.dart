import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

enum UserRole {
  admin('admin', 'Admin sekolah'),
  guru('guru', 'Guru'),
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
    required String name,
    required String username,
    String? nis,

    /// Students: their single class.
    String? classId,

    /// Teachers: assigned classes.
    @Default(<String>[]) List<String> classIds,
    @Default(true) bool active,
    @Default(false) bool mustChangePassword,
  }) = _AppUser;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
    uid: uid,
    role: UserRole.fromWire(data['role']) ?? UserRole.siswa,
    name: data['name'] as String? ?? '',
    username: data['username'] as String? ?? '',
    nis: data['nis'] as String?,
    classId: data['classId'] as String?,
    classIds: List<String>.from(data['classIds'] as List? ?? const []),
    active: data['status'] != 'disabled',
    mustChangePassword: data['mustChangePassword'] == true,
  );
}
