// End-to-end flows against the Firebase Emulator Suite. The tests run in
// order and build on each other, like a school being set up for real.
//
//   (cd functions && npm run emulators)                      # terminal 1
//   (cd functions && npx tsx tools/seed-e2e.ts --emulator)   # reset + seed
//   flutter test integration_test/app_test.dart -d <android-device> \
//       --dart-define=USE_EMULATORS=true

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

const _wrongCredentials = 'Kode sekolah, username, atau password salah.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin: wrong password, first login, forced password change', (
    tester,
  ) async {
    await startApp(tester);

    // Wrong password: uniform message, still on the login screen.
    await signIn(tester, username: 'admin', password: 'salah-password');
    await waitFor(tester, find.text(_wrongCredentials));

    // An unknown school code gives the very same message.
    await signIn(
      tester,
      school: 'tidakada',
      username: 'admin',
      password: e2eInitialPassword,
    );
    await waitFor(tester, find.text(_wrongCredentials));

    // Initial password: forced to choose a new one before anything else.
    await signIn(tester, username: 'admin', password: e2eInitialPassword);
    await setNewPassword(tester);

    // Lands in the admin shell.
    await waitFor(tester, navTab('Pengaturan'));
    expect(navTab('Kelas'), findsOneWidget);
    expect(navTab('Pengguna'), findsOneWidget);

    // The old password no longer works; the new one skips the forced change.
    await signOut(tester);
    await signIn(tester, username: 'admin', password: e2eInitialPassword);
    await waitFor(tester, find.text(_wrongCredentials));
    await signIn(tester, username: 'admin', password: e2eNewPassword);
    await waitFor(tester, navTab('Pengaturan'));
    expect(find.text('Buat password baru'), findsNothing);
  });

  testWidgets('admin: creates a class, a teacher and a student', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, username: 'admin', password: e2eNewPassword);
    await waitFor(tester, navTab('Kelas'));

    // Class
    await tester.tap(navTab('Kelas'));
    await waitFor(tester, find.byKey(const Key('class-add')));
    await tester.tap(find.byKey(const Key('class-add')));
    await waitFor(tester, find.byKey(const Key('class-name')));
    await tester.enterText(find.byKey(const Key('class-name')), e2eClass);
    await tapVisible(tester, find.byKey(const Key('class-save')));
    await waitFor(tester, find.text(e2eClass));

    // Teacher, assigned to the class at creation
    await tester.tap(navTab('Pengguna'));
    await openAddUser(tester);
    await tester.tap(find.text('Guru'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('add-user-name')), 'Bu Sari');
    await tester.enterText(
      find.byKey(const Key('add-user-username')),
      e2eTeacher,
    );
    await tapVisible(tester, find.widgetWithText(FilterChip, e2eClass));
    await tapVisible(tester, find.byKey(const Key('add-user-submit')));
    teacherPassword = await readCredentialAndClose(tester);
    expect(teacherPassword, hasLength(10));

    // Student
    await openAddUser(tester);
    await tester.enterText(
      find.byKey(const Key('add-user-name')),
      'Raka Pratama',
    );
    await tester.enterText(
      find.byKey(const Key('add-user-username')),
      e2eStudent,
    );
    await tapVisible(tester, find.byKey(const Key('add-user-class')));
    await waitFor(tester, find.text(e2eClass));
    await tester.tap(find.text(e2eClass).last);
    await tester.pump(const Duration(milliseconds: 500));
    await tapVisible(tester, find.byKey(const Key('add-user-submit')));
    studentPassword = await readCredentialAndClose(tester);

    // Both show up in the lists.
    await waitFor(tester, find.text('Raka Pratama'));
    expect(find.textContaining(e2eClass), findsWidgets);
    await tester.tap(find.text('Guru'));
    await waitFor(tester, find.text('Bu Sari'));

    // A username that is already taken is refused with a clear reason.
    await openAddUser(tester);
    await tester.enterText(find.byKey(const Key('add-user-name')), 'Kembaran');
    await tester.enterText(
      find.byKey(const Key('add-user-username')),
      e2eStudent,
    );
    await tapVisible(tester, find.byKey(const Key('add-user-class')));
    await waitFor(tester, find.text(e2eClass));
    await tester.tap(find.text(e2eClass).last);
    await tester.pump(const Duration(milliseconds: 500));
    await tapVisible(tester, find.byKey(const Key('add-user-submit')));
    await waitFor(tester, find.text('Username sudah dipakai.'));
  });
}
