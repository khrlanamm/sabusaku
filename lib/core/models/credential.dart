import 'package:freezed_annotation/freezed_annotation.dart';

import '../../features/auth/domain/app_user.dart';

part 'credential.freezed.dart';

/// An initial or temporary password to hand to a user. Shown once and never
/// stored.
@freezed
abstract class Credential with _$Credential {
  const factory Credential({
    required String name,
    required String username,
    required String password,
    required UserRole role,
    @Default('') String className,
  }) = _Credential;
}
