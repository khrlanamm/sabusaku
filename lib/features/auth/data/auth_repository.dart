import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/storage/prefs.dart';
import '../domain/app_user.dart';
import '../domain/credentials.dart';
import '../domain/session.dart';

part 'auth_repository.g.dart';

typedef _Claims = ({UserRole role, String schoolId, List<String> classIds});

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._prefs);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const _schoolCodeKey = 'auth.schoolCode';
  static String _claimsKey(String uid) => 'auth.claims.$uid';

  /// The school code of the last successful sign-in on this device.
  String? get rememberedSchoolCode => _prefs.getString(_schoolCodeKey);

  DocumentReference<Map<String, dynamic>> _userDoc(
    String schoolId,
    String uid,
  ) => _firestore.doc('schools/$schoolId/users/$uid');

  /// Emits the session as sign-in state, claims or the profile change.
  Stream<AuthState> watchAuthState() {
    late final StreamController<AuthState> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;
    var generation = 0;

    Future<void> onUser(User? user) async {
      final current = ++generation;
      await profileSub?.cancel();
      profileSub = null;
      if (user == null) {
        controller.add(const AuthSignedOut());
        return;
      }

      final claims = await _claimsOf(user);
      if (current != generation) return;
      if (claims == null) {
        await _auth.signOut();
        return;
      }

      profileSub = _userDoc(claims.schoolId, user.uid).snapshots().listen(
        (snapshot) {
          final data = snapshot.data();
          if (data == null) {
            // A cache miss while offline is not proof the profile is gone.
            if (!snapshot.metadata.isFromCache) _auth.signOut();
            return;
          }
          final profile = AppUser.fromMap(snapshot.id, data);
          if (!profile.active) {
            _auth.signOut();
            return;
          }
          controller.add(
            AuthSignedIn(
              Session(
                uid: user.uid,
                role: claims.role,
                schoolId: claims.schoolId,
                classIds: claims.classIds,
                profile: profile,
              ),
            ),
          );
        },
        // Reading one's own profile only fails when the account lost access.
        onError: (Object _) => _auth.signOut(),
      );
    }

    controller = StreamController<AuthState>(
      onListen: () => authSub = _auth.idTokenChanges().listen(onUser),
      onCancel: () async {
        await authSub?.cancel();
        await profileSub?.cancel();
      },
    );
    return controller.stream;
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
            'classIds': claims.classIds,
          }),
        );
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
      classIds: List<String>.from(claims?['classIds'] as List? ?? const []),
    );
  }

  Future<void> signIn({
    required String schoolCode,
    required String username,
    required String password,
  }) async {
    final school = normalizeIdentity(schoolCode);
    final user = normalizeIdentity(username);
    // Same message as a wrong password: never reveal which part is wrong.
    if (!isValidSchoolCode(school) || !isValidUsername(user)) {
      throw const AppException(AppErrorCode.invalidCredentials);
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: pseudoEmail(school, user),
        password: password,
      );
    } catch (error) {
      throw mapError(error);
    }
    await _prefs.setString(_schoolCodeKey, school);
  }

  /// Changes the password and clears the "must change" flag.
  ///
  /// [currentPassword] is required outside the first-login flow, where the
  /// user has just authenticated.
  Future<void> changePassword({
    required Session session,
    String? currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AppException(AppErrorCode.sessionExpired);
    try {
      if (currentPassword != null) {
        try {
          await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(
              email: user.email!,
              password: currentPassword,
            ),
          );
        } on FirebaseAuthException catch (error) {
          if (error.code == 'invalid-credential' ||
              error.code == 'wrong-password') {
            throw const AppException(AppErrorCode.wrongPassword);
          }
          rethrow;
        }
      }
      await user.updatePassword(newPassword);
      if (session.mustChangePassword) {
        await _userDoc(
          session.schoolId,
          session.uid,
        ).update({'mustChangePassword': false});
      }
    } catch (error) {
      throw mapError(error);
    }
  }

  /// Forces a token refresh so changed claims take effect.
  Future<void> refreshClaims() async {
    try {
      await _auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException {
      // Offline or signed out: the next successful refresh picks them up.
    }
  }

  Future<void> signOut() => _auth.signOut();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  ref.watch(firebaseAuthProvider),
  ref.watch(firestoreProvider),
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
