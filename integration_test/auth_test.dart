// End-to-end sign-in flow against the Firebase Emulator Suite.
//
//   (cd functions && npm run emulators)            # terminal 1
//   (cd functions && npx tsx tools/seed-e2e.ts --emulator)
//   flutter test integration_test/auth_test.dart -d <android-device> \
//       --dart-define=USE_EMULATORS=true

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin: wrong password, first login, forced password change', (
    tester,
  ) async {
    await startApp(tester);

    // Wrong password: uniform message, still on the login screen.
    await signIn(tester, username: 'admin', password: 'salah-password');
    await waitFor(
      tester,
      find.text('Kode sekolah, username, atau password salah.'),
    );

    // Unknown school code gives the very same message.
    await signIn(
      tester,
      school: 'tidakada',
      username: 'admin',
      password: e2eInitialPassword,
    );
    await waitFor(
      tester,
      find.text('Kode sekolah, username, atau password salah.'),
    );

    // Initial password: forced to choose a new one before anything else.
    await signIn(tester, username: 'admin', password: e2eInitialPassword);
    await setNewPassword(tester);

    // Lands in the admin shell with its four tabs.
    await waitFor(tester, find.text('Pengaturan'));
    expect(find.text('Kelas'), findsWidgets);
    expect(find.text('Pengguna'), findsWidgets);

    // The old password no longer works; the new one skips the forced change.
    await signOut(tester);
    await signIn(tester, username: 'admin', password: e2eInitialPassword);
    await waitFor(
      tester,
      find.text('Kode sekolah, username, atau password salah.'),
    );
    await signIn(tester, username: 'admin', password: e2eNewPassword);
    await waitFor(tester, find.text('Pengaturan'));
    expect(find.text('Buat password baru'), findsNothing);
  });
}
