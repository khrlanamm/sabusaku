import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';

part 'session.freezed.dart';

/// The signed-in user. Role, school and classes come from the custom claims
/// (the source of truth for authorisation); [profile] is the Firestore
/// document.
@freezed
abstract class Session with _$Session {
  const Session._();

  const factory Session({
    required String uid,
    required UserRole role,
    required String schoolId,

    /// Teachers only: classes from the `classIds` claim.
    @Default(<String>[]) List<String> classIds,
    required AppUser profile,
  }) = _Session;

  bool get mustChangePassword => profile.mustChangePassword;
}

sealed class AuthState {
  const AuthState();
}

/// The stored session is still being resolved.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final Session session;
}
