import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/app/router/routes.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';

AuthSignedIn signedIn(UserRole role, {bool mustChangePassword = false}) =>
    AuthSignedIn(
      Session(
        uid: 'u1',
        role: role,
        schoolId: 'sman1',
        profile: AppUser(
          uid: 'u1',
          role: role,
          name: 'Nama',
          username: 'nama',
          mustChangePassword: mustChangePassword,
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

    test('signed out is sent to login from anywhere', () {
      expect(redirectFor(const AuthSignedOut(), Routes.login), isNull);
      expect(redirectFor(const AuthSignedOut(), Routes.splash), Routes.login);
      expect(
        redirectFor(const AuthSignedOut(), Routes.adminUsers),
        Routes.login,
      );
      expect(
        redirectFor(const AuthSignedOut(), Routes.changePassword),
        Routes.login,
      );
    });

    test('an initial password must be changed before anything else', () {
      final auth = signedIn(UserRole.siswa, mustChangePassword: true);
      expect(redirectFor(auth, Routes.studentHome), Routes.forceChangePassword);
      expect(redirectFor(auth, Routes.login), Routes.forceChangePassword);
      expect(redirectFor(auth, Routes.forceChangePassword), isNull);
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
        redirectFor(signedIn(UserRole.admin), Routes.forceChangePassword),
        Routes.adminHome,
      );
    });

    test('cross-role access returns to the own home', () {
      expect(
        redirectFor(signedIn(UserRole.siswa), Routes.adminUsers),
        Routes.studentHome,
      );
      expect(
        redirectFor(signedIn(UserRole.guru), Routes.studentHome),
        Routes.teacherDashboard,
      );
      expect(
        redirectFor(signedIn(UserRole.admin), Routes.teacherStudent('siswa1')),
        Routes.adminHome,
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
        redirectFor(signedIn(UserRole.guru), Routes.teacherStudents),
        isNull,
      );
      expect(
        redirectFor(signedIn(UserRole.admin), Routes.changePassword),
        isNull,
      );
    });
  });
}
