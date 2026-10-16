import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/app/router/routes.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';

AuthSignedIn signedIn(
  UserRole role, {
  String name = 'Nama Lengkap',
  String? classId = 'XII-A1',
  bool hasPassword = true,
}) => AuthSignedIn(
  Session(
    uid: 'u1',
    role: role,
    schoolId: 'sman1',
    hasPassword: hasPassword,
    profile: AppUser(
      uid: 'u1',
      role: role,
      name: name,
      email: 'nama@example.com',
      classId: role == UserRole.siswa ? classId : null,
    ),
  ),
);

void main() {
  group('redirectFor', () {
    test('loading always waits on the splash', () {
      expect(redirectFor(const AuthLoading(), Routes.splash), isNull);
      expect(redirectFor(const AuthLoading(), Routes.login), Routes.splash);
      expect(
        redirectFor(const AuthLoading(), Routes.studentHome),
        Routes.splash,
      );
    });

    test('signed out may use login and sign-up only', () {
      const auth = AuthSignedOut();
      expect(redirectFor(auth, Routes.login), isNull);
      expect(redirectFor(auth, Routes.register), isNull);
      expect(redirectFor(auth, Routes.splash), Routes.login);
      expect(redirectFor(auth, Routes.teacherStudents), Routes.login);
      expect(redirectFor(auth, Routes.changePassword), Routes.login);
      expect(redirectFor(auth, Routes.completeProfile), Routes.login);
    });

    test('an email without a school stays on login for the dialog', () {
      const auth = AuthNotRegistered('x@example.com');
      expect(redirectFor(auth, Routes.login), isNull);
      expect(redirectFor(auth, Routes.splash), Routes.login);
      expect(redirectFor(auth, Routes.studentHome), Routes.login);
    });

    test('an unverified sign-up waits for verification', () {
      const auth = AuthNeedsVerification('x@example.com');
      expect(redirectFor(auth, Routes.verifyEmail), isNull);
      expect(redirectFor(auth, Routes.login), Routes.verifyEmail);
      expect(redirectFor(auth, Routes.studentHome), Routes.verifyEmail);
    });

    test('an incomplete profile is completed before anything else', () {
      for (final auth in [
        signedIn(UserRole.siswa, name: ''),
        signedIn(UserRole.siswa, classId: null),
        signedIn(UserRole.siswa, hasPassword: false),
        signedIn(UserRole.guru, hasPassword: false),
      ]) {
        expect(redirectFor(auth, Routes.completeProfile), isNull);
        expect(redirectFor(auth, Routes.login), Routes.completeProfile);
        expect(redirectFor(auth, Routes.studentHome), Routes.completeProfile);
        expect(
          redirectFor(auth, Routes.changePassword),
          Routes.completeProfile,
        );
      }
    });

    test('a teacher needs no class', () {
      expect(
        redirectFor(signedIn(UserRole.guru, classId: null), Routes.login),
        Routes.teacherDashboard,
      );
    });

    test('each role lands in its own shell', () {
      expect(
        redirectFor(signedIn(UserRole.siswa), Routes.login),
        Routes.studentHome,
      );
      expect(
        redirectFor(signedIn(UserRole.guru), Routes.splash),
        Routes.teacherDashboard,
      );
      expect(
        redirectFor(signedIn(UserRole.guru), Routes.completeProfile),
        Routes.teacherDashboard,
      );
    });

    test('cross-role access returns to the own home', () {
      expect(
        redirectFor(signedIn(UserRole.siswa), Routes.teacherSchool),
        Routes.studentHome,
      );
      expect(
        redirectFor(signedIn(UserRole.guru), Routes.studentHome),
        Routes.teacherDashboard,
      );
    });

    test('own routes and the shared password screen are allowed', () {
      expect(
        redirectFor(
          signedIn(UserRole.siswa),
          Routes.studentJournal('p1', '2026-10-07'),
        ),
        isNull,
      );
      expect(
        redirectFor(signedIn(UserRole.guru), Routes.teacherAddStudents),
        isNull,
      );
      expect(
        redirectFor(
          signedIn(UserRole.guru),
          Routes.teacherPendingMember('a.b@example.com'),
        ),
        isNull,
      );
      expect(
        redirectFor(signedIn(UserRole.siswa), Routes.changePassword),
        isNull,
      );
    });
  });
}
