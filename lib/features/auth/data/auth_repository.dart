import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/google_sign_in.dart';
import '../../../core/policy/terms.dart';
import '../../../core/storage/prefs.dart';
import '../../../core/utils/labels.dart';
import '../domain/app_user.dart';
import '../domain/session.dart';

part 'auth_repository.g.dart';

typedef _Claims = ({UserRole role, String schoolId, bool superadmin});

/// Outcome of asking the server to attach the account to its school.
enum _ClaimResult { claimed, notRegistered, notVerified }

const _passwordProvider = 'password';
const _googleProvider = 'google.com';

/// Google serves profile photos at 96 px by default; ask for 400 px.
String? upsizeGooglePhoto(String? url) =>
    url?.replaceFirst(RegExp(r'=s96-c$'), '=s400-c');

class AuthRepository {
  AuthRepository(
    this._auth,
    this._firestore,
    this._functions,
    this._storage,
    this._prefs,
  ) {
    // Firebase sends verification and password-reset emails in Indonesian.
    _auth.setLanguageCode('id');
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final SharedPreferences _prefs;

  Future<void>? _googleReady;

  /// One `claimAccount` call at a time: the session stream and the Google
  /// sign-in both ask for it right after signing in.
  Future<_ClaimResult>? _claimInFlight;

  static String _claimsKey(String uid) => 'auth.claims.$uid';

  DocumentReference<Map<String, dynamic>> _userDoc(
    String schoolId,
    String uid,
  ) => _firestore.doc('schools/$schoolId/users/$uid');

  Reference _avatarRef(String schoolId, String uid) =>
      _storage.ref('schools/$schoolId/avatars/$uid.jpg');

  /// The Firebase account, for prefilling forms (Google display name).
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------

  /// Emits the session as sign-in state, claims or the profile change.
  ///
  /// An account without school claims is attached to its school through the
  /// `claimAccount` callable; an email that belongs to no school becomes
  /// [AuthNotRegistered].
  Stream<AuthState> watchAuthState() {
    late final StreamController<AuthState> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;
    var generation = 0;
    // A claim that succeeded must yield claims after the token refresh; this
    // stops a retry loop when it does not.
    String? claimedFor;

    Future<void> failAndSignOut(Object error) async {
      controller.addError(mapError(error));
      await signOut();
    }

    Future<void> claim(User user, int current) async {
      final _ClaimResult result;
      try {
        result = await _claim();
      } catch (error) {
        if (current == generation) await failAndSignOut(error);
        return;
      }
      if (current != generation) return;
      switch (result) {
        case _ClaimResult.notRegistered:
          controller.add(AuthNotRegistered(user.email ?? ''));
        case _ClaimResult.notVerified:
          controller.add(AuthNeedsVerification(user.email ?? ''));
        case _ClaimResult.claimed:
          if (claimedFor == user.uid) {
            await failAndSignOut(const AppException(AppErrorCode.unknown));
            return;
          }
          claimedFor = user.uid;
          // The new token carries the claims and re-enters through
          // userChanges.
          await refreshClaims();
      }
    }

    Future<void> onUser(User? user) async {
      final current = ++generation;
      await profileSub?.cancel();
      profileSub = null;
      if (user == null) {
        claimedFor = null;
        controller.add(const AuthSignedOut());
        return;
      }

      final providers = {for (final info in user.providerData) info.providerId};
      final hasGoogle = providers.contains(_googleProvider);
      if (!user.emailVerified && !hasGoogle) {
        controller.add(AuthNeedsVerification(user.email ?? ''));
        return;
      }

      final claims = await _claimsOf(user);
      if (current != generation) return;
      if (claims == null) {
        await claim(user, current);
        return;
      }
      claimedFor = null;

      final googleInfo = user.providerData
          .where((info) => info.providerId == _googleProvider)
          .firstOrNull;

      profileSub = _userDoc(claims.schoolId, user.uid).snapshots().listen(
        (snapshot) {
          final data = snapshot.data();
          if (data == null) {
            // A cache miss while offline is not proof the profile is gone.
            if (!snapshot.metadata.isFromCache) claim(user, current);
            return;
          }
          final profile = AppUser.fromMap(snapshot.id, data);
          if (!profile.active) {
            // Removed from the school: the server cleared the claims and the
            // membership, so this email no longer belongs to a school.
            controller.add(AuthNotRegistered(user.email ?? ''));
            return;
          }
          controller.add(
            AuthSignedIn(
              Session(
                uid: user.uid,
                role: claims.role,
                schoolId: claims.schoolId,
                profile: profile,
                hasPassword: providers.contains(_passwordProvider),
                hasGoogle: hasGoogle,
                googlePhotoUrl: upsizeGooglePhoto(googleInfo?.photoURL),
                superadmin: claims.superadmin,
              ),
            ),
          );
        },
        // Reading one's own profile only fails when the account lost access.
        onError: (Object _) => claim(user, current),
      );
    }

    controller = StreamController<AuthState>(
      // userChanges also fires when a password is linked or the user reloads
      // after verifying their email.
      onListen: () => authSub = _auth.userChanges().listen(onUser),
      onCancel: () async {
        await authSub?.cancel();
        await profileSub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<_ClaimResult> _claim() =>
      _claimInFlight ??= _callClaim().whenComplete(() => _claimInFlight = null);

  Future<_ClaimResult> _callClaim() async {
    try {
      await _functions.httpsCallable('claimAccount').call<Object?>();
      return _ClaimResult.claimed;
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final reason = details is Map ? details['reason'] : null;
      if (reason == 'not-registered' || error.code == 'not-found') {
        return _ClaimResult.notRegistered;
      }
      if (reason == 'email-not-verified') return _ClaimResult.notVerified;
      rethrow;
    }
  }

  /// Claims from the ID token. Falls back to the copy cached at the last
  /// successful read so the app still opens offline with an expired token.
  Future<_Claims?> _claimsOf(User user) async {
    try {
      final token = await user.getIdTokenResult();
      final claims = _parseClaims(token.claims);
      if (claims != null) {
        await _prefs.setString(
          _claimsKey(user.uid),
          jsonEncode({
            'role': claims.role.wire,
            'schoolId': claims.schoolId,
            'superadmin': claims.superadmin,
          }),
        );
      } else {
        await _prefs.remove(_claimsKey(user.uid));
      }
      return claims;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'network-request-failed') return null;
      final cached = _prefs.getString(_claimsKey(user.uid));
      if (cached == null) return null;
      return _parseClaims(jsonDecode(cached) as Map<String, dynamic>);
    }
  }

  static _Claims? _parseClaims(Map<String, dynamic>? claims) {
    final role = UserRole.fromWire(claims?['role']);
    final schoolId = claims?['schoolId'];
    if (role == null || schoolId is! String || schoolId.isEmpty) return null;
    return (
      role: role,
      schoolId: schoolId,
      superadmin: claims?['superadmin'] == true,
    );
  }

  /// Forces a token refresh so changed claims take effect.
  Future<void> refreshClaims() async {
    try {
      await _auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException {
      // Offline or signed out: the next successful refresh picks them up.
    }
  }

  // ---------------------------------------------------------------------
  // Sign-in
  // ---------------------------------------------------------------------

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final address = normalizeEmail(email);
    // Same message as a wrong password: never reveal which part is wrong.
    if (!isValidEmail(address)) {
      throw const AppException(AppErrorCode.invalidCredentials);
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: address,
        password: password,
      );
    } catch (error) {
      throw mapError(error);
    }
  }

  Future<void> _initGoogle() => _googleReady ??= GoogleSignIn.instance
      .initialize(serverClientId: googleServerClientId);

  /// Google ID token from Credential Manager, or null when the user closed
  /// the account picker.
  Future<String?> _googleIdToken() async {
    await _initGoogle();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      debugPrint('Google sign-in failed: ${error.code} ${error.description}');
      throw const AppException(
        AppErrorCode.unknown,
        message: 'Masuk dengan Google gagal. Coba lagi.',
      );
    }
  }

  /// Returns false when the user cancelled.
  ///
  /// Always asks the server to claim the account afterwards, even when the
  /// token already has a school: the claim also fills an empty profile photo
  /// with the Google one (an existing photo is never replaced).
  Future<bool> signInWithGoogle() async {
    final idToken = await _googleIdToken();
    if (idToken == null) return false;
    final User user;
    try {
      final credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      user = credential.user!;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'account-exists-with-different-credential') {
        throw AppException(
          AppErrorCode.alreadyExists,
          message:
              'Email ini sudah terdaftar dengan password. Masuk dengan '
              'email dan password.',
          cause: error,
        );
      }
      throw mapError(error);
    }

    final hadClaims = await _claimsOf(user) != null;
    final _ClaimResult result;
    try {
      result = await _claim();
    } catch (_) {
      // Without claims the session stream reports the failure; with claims
      // only the photo fill was missed.
      return true;
    }
    // Missing claims: the session stream refreshes the token after its own
    // (shared) claim and shows "not registered" or "verify" itself. With
    // claims, a failed claim means the membership is gone; refreshing lets
    // the stream see the cleared claims.
    if (hadClaims && result != _ClaimResult.claimed) await refreshClaims();
    return true;
  }

  /// Creates an email/password account and sends the verification email.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final address = normalizeEmail(email);
    if (!isValidEmail(address)) {
      throw const AppException(
        AppErrorCode.invalidInput,
        message: 'Format email belum benar.',
      );
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: address,
        password: password,
      );
      await credential.user?.sendEmailVerification();
    } catch (error) {
      throw mapError(error);
    }
  }

  Future<void> resendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (error) {
      throw mapError(error);
    }
  }

  /// Re-reads the account after the user clicked the verification link.
  /// Returns true when the email is now verified.
  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final fresh = _auth.currentUser;
      if (fresh == null || !fresh.emailVerified) return false;
      // The server reads `email_verified` from the token, so refresh it.
      await fresh.getIdToken(true);
      return true;
    } catch (error) {
      throw mapError(error);
    }
  }

  /// Sends Firebase's password-reset email. Never reveals whether the
  /// address has an account.
  Future<void> sendPasswordReset(String email) async {
    final address = normalizeEmail(email);
    if (!isValidEmail(address)) {
      throw const AppException(
        AppErrorCode.invalidInput,
        message: 'Format email belum benar.',
      );
    }
    try {
      await _auth.sendPasswordResetEmail(email: address);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') return;
      throw mapError(error);
    }
  }

  // ---------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------

  /// Adds a password to an account that only signs in with Google.
  Future<void> setPassword(String newPassword) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AppException(AppErrorCode.sessionExpired);
    }
    try {
      try {
        await user.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: newPassword),
        );
      } on FirebaseAuthException catch (error) {
        // Some Auth backends (the emulator among them) refuse to link a
        // password credential whose email is the account's own. Setting the
        // password directly adds the same `password` provider.
        if (error.code != 'email-already-in-use') rethrow;
        await user.updatePassword(newPassword);
      }
      // userChanges does not always fire for a link; reload makes the new
      // provider visible to the session.
      await user.reload();
      await user.getIdToken(true);
    } catch (error) {
      throw mapError(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AppException(AppErrorCode.sessionExpired);
    }
    try {
      try {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: currentPassword),
        );
      } on FirebaseAuthException catch (error) {
        if (error.code == 'invalid-credential' ||
            error.code == 'wrong-password') {
          throw const AppException(AppErrorCode.wrongPassword);
        }
        rethrow;
      }
      await user.updatePassword(newPassword);
    } catch (error) {
      throw mapError(error);
    }
  }

  // ---------------------------------------------------------------------
  // Terms of use
  // ---------------------------------------------------------------------

  /// Records that the user accepted the current terms of use. Only the server
  /// writes `termsVersion`; the watched profile then carries it into the
  /// session, which lets the router move on.
  Future<void> acceptTerms() => _guard(
    () => _functions.httpsCallable('acceptTerms').call<Object?>({
      'version': currentTermsVersion,
    }),
  );

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  /// Writes only the given fields. Rules allow the owner to change name,
  /// class (students) and extracurriculars.
  Future<void> updateProfile(
    Session session, {
    String? name,
    String? classId,
    List<String>? extracurriculars,
  }) async {
    final changes = <String, Object?>{
      'name': ?name?.trim(),
      'classId': ?classId,
      'extracurriculars': ?extracurriculars,
    };
    if (changes.isEmpty) return;
    await _guard(
      () => _userDoc(
        session.schoolId,
        session.uid,
      ).update({...changes, 'updatedAt': FieldValue.serverTimestamp()}),
    );
  }

  /// A teacher's homeroom class and supervised extracurriculars. Both are
  /// written as given, so either can be cleared.
  Future<void> updateTeacherGroup(
    Session session, {
    required String? homeroomClass,
    required List<String> extracurriculars,
  }) => _guard(
    () => _userDoc(session.schoolId, session.uid).update({
      'homeroomClass': homeroomClass,
      'extracurriculars': extracurriculars,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  /// Uploads a new profile photo (already resized by the picker).
  Future<void> uploadPhoto(
    Session session,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) => _guard(() async {
    final ref = _avatarRef(session.schoolId, session.uid);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    await _setPhotoUrl(session, url);
  });

  /// Uses the photo of the linked Google account and drops the upload.
  Future<void> useGooglePhoto(Session session) => _guard(() async {
    final url = session.googlePhotoUrl;
    if (url == null) return;
    await _setPhotoUrl(session, url);
    await _deleteAvatar(session);
  });

  Future<void> removePhoto(Session session) => _guard(() async {
    await _setPhotoUrl(session, null);
    await _deleteAvatar(session);
  });

  Future<void> _setPhotoUrl(Session session, String? url) => _userDoc(
    session.schoolId,
    session.uid,
  ).update({'photoUrl': url, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> _deleteAvatar(Session session) async {
    try {
      await _avatarRef(session.schoolId, session.uid).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  /// Deletes the account and its data on the server, then signs out.
  Future<void> deleteAccount() async {
    await _guard(
      () => _functions.httpsCallable('deleteMyAccount').call<Object?>(),
    );
    await signOut();
  }

  Future<void> signOut() async {
    if (_googleReady != null) {
      // So the next "Masuk dengan Google" offers the account picker again.
      await GoogleSignIn.instance.signOut().catchError((Object _) {});
    }
    await _auth.signOut();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapError(error);
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  ref.watch(firebaseAuthProvider),
  ref.watch(firestoreProvider),
  ref.watch(functionsProvider),
  ref.watch(storageProvider),
  ref.watch(sharedPreferencesProvider),
);

@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();

/// The signed-in session, or null while loading or signed out.
@Riverpod(keepAlive: true)
Session? session(Ref ref) {
  final state = ref.watch(authStateProvider).value;
  return state is AuthSignedIn ? state.session : null;
}

/// For code that only runs inside a role shell, where a session always exists.
///
/// While signing out, screens are still mounted for a frame before the router
/// redirects; they keep the last session instead of throwing mid-build.
@Riverpod(keepAlive: true)
class CurrentSession extends _$CurrentSession {
  Session? _last;

  @override
  Session build() {
    final session = ref.watch(sessionProvider) ?? _last;
    if (session == null) throw const AppException(AppErrorCode.sessionExpired);
    return _last = session;
  }
}
