import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/student_status.dart';
import '../../auth/domain/app_user.dart';

part 'admin_models.freezed.dart';

/// One account to create through the `createUsers` callable.
@freezed
abstract class NewUser with _$NewUser {
  const NewUser._();

  const factory NewUser({
    required UserRole role,
    required String name,
    required String username,

    /// Students: their class.
    String? classId,

    /// Teachers: assigned classes.
    @Default(<String>[]) List<String> classIds,
  }) = _NewUser;

  Map<String, dynamic> toMap() => {
    'role': role.wire,
    'name': name,
    'username': username,
    if (role == UserRole.siswa) 'classId': classId,
    if (role == UserRole.guru) 'classIds': classIds,
  };
}

/// Per-row outcome of `createUsers`.
@freezed
abstract class CreateUserResult with _$CreateUserResult {
  const factory CreateUserResult({
    required String username,
    required bool ok,
    String? uid,
    String? password,
    String? reason,
  }) = _CreateUserResult;

  factory CreateUserResult.fromMap(Map<String, dynamic> data) =>
      CreateUserResult(
        username: data['username'] as String? ?? '',
        ok: data['ok'] == true,
        uid: data['uid'] as String?,
        password: data['password'] as String?,
        reason: data['reason'] as String?,
      );
}

/// Numbers on the admin home. Admins see statistics, never journal text.
@freezed
abstract class AdminCounts with _$AdminCounts {
  const factory AdminCounts({
    required int students,
    required int teachers,
    required int classes,
    required Map<StudentStatus, int> byStatus,
  }) = _AdminCounts;
}
