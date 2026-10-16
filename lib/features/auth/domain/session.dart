import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/policy/terms.dart';
import 'app_user.dart';

part 'session.freezed.dart';

/// The signed-in user. Role and school come from the custom claims (the
/// source of truth for authorisation); [profile] is the Firestore document.
@freezed
abstract class Session with _$Session {
  const Session._();

  const factory Session({
    required String uid,
    required UserRole role,
    required String schoolId,
    required AppUser profile,

    /// The account can sign in with email and password. Google-only
    /// accounts must add a password first.
    @Default(true) bool hasPassword,

    /// The account is linked to Google (offers "Pakai foto Google").
    @Default(false) bool hasGoogle,

    /// The photo of the linked Google account, if any.
    String? googlePhotoUrl,
  }) = _Session;

  /// Sent to the terms of use before anything else, even "Lengkapi akun":
  /// the name and photo asked there are visible to others.
  bool get needsTerms => profile.termsVersion < currentTermsVersion;

  /// Sent to "Lengkapi akun" once the terms are accepted.
  bool get needsCompletion => !profile.profileComplete || !hasPassword;
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

/// Signed up with email and password; the address is not verified yet.
class AuthNeedsVerification extends AuthState {
  const AuthNeedsVerification(this.email);

  final String email;
}

/// Signed in, but the email belongs to no school. The login screen shows
/// "Harap Menghubungi Administrator Sekolah" and then signs out.
class AuthNotRegistered extends AuthState {
  const AuthNotRegistered(this.email);

  final String email;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final Session session;
}
