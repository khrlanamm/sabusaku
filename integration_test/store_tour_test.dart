// Walks the screens used for the Play Store screenshots, against PRODUCTION
// with the demo school. Read-only: the journal form is filled in but never
// saved.
//
//   tool/store-screenshots.sh <phone|tablet>
//
// Before holding each screen the test prints `SHOT:<name>`; the script
// reads that marker from the test output and captures the screen under
// that name.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sabusaku/bootstrap.dart';

import 'support.dart';

const _password = String.fromEnvironment('DEMO_PASSWORD');

Future<void> _shot(WidgetTester tester, String name) async {
  // The on-screen keyboard must not be in the picture.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 900));
  // ignore: avoid_print
  print('SHOT:$name');
  await tester.pump(const Duration(milliseconds: 2800));
}

Future<void> _signIn(WidgetTester tester, String username) =>
    signIn(tester, school: 'demo', username: username, password: _password);

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(useEmulators, isFalse, reason: 'This tour targets production');
    expect(_password, isNotEmpty, reason: 'Pass --dart-define=DEMO_PASSWORD');
  });

  testWidgets('siswa: beranda, riwayat, buku, profil', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, '2001');
    await waitFor(tester, find.text('Buku bulan ini'));
    await dismissNotificationPrompt(tester);
    await waitFor(tester, find.text('Laskar Pelangi'));
    await waitFor(tester, find.byKey(const Key('home-new-comments')));
    await _shot(tester, 'siswa-beranda');

    await tester.tap(navTab('Jurnal'));
    await waitFor(tester, find.textContaining('Hal. '));
    await _shot(tester, 'siswa-riwayat');

    await tester.tap(navTab('Buku'));
    await waitFor(tester, find.byKey(const Key('book-stop')));
    await _shot(tester, 'siswa-buku');

    await tester.tap(navTab('Profil'));
    await waitFor(tester, find.text('Riwayat buku'));
    await waitFor(tester, find.text('Negeri 5 Menara'));
    await _shot(tester, 'siswa-profil');
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('siswa: isi jurnal', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, '2003');
    await waitFor(tester, find.byKey(const Key('home-write-journal')));
    await dismissNotificationPrompt(tester);
    await tester.tap(find.byKey(const Key('home-write-journal')));
    await waitFor(tester, find.byKey(const Key('journal-save')));

    final start = int.parse(
      tester
          .widget<TextFormField>(find.byKey(const Key('journal-page-start')))
          .controller!
          .text,
    );
    await tester.enterText(
      find.byKey(const Key('journal-page-end')),
      '${start + 17}',
    );
    await tester.tap(find.byKey(const Key('journal-duration-30to60')));
    await tester.enterText(
      find.byKey(const Key('journal-key-information')),
      'Minke mulai bersekolah di HBS dan menyadari betapa berbedanya '
      'perlakuan terhadap pribumi dan orang Eropa.',
    );
    await tester.enterText(
      find.byKey(const Key('journal-reflection')),
      'Keberanian Minke untuk terus menulis sangat menginspirasi.',
    );
    await _shot(tester, 'siswa-isi-jurnal');
    // Leave without saving.
    await _back(tester);
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('siswa: jurnal dengan komentar guru', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, '2002');
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await dismissNotificationPrompt(tester);
    await tester.tap(find.text('Lihat'));
    await waitFor(tester, find.text('Komentar guru'));
    await waitFor(tester, find.text('Sari Wulandari'));
    await _shot(tester, 'siswa-komentar');
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('guru: dashboard, siswa, detail, jurnal', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, 'guru1');
    await waitFor(tester, find.text('Status siswa'));
    await waitFor(tester, find.text('Perlu perhatian'));
    await _shot(tester, 'guru-dashboard');

    await tester.tap(navTab('Siswa'));
    await waitFor(tester, find.text('Anisa Rahmawati'));
    await waitFor(tester, find.widgetWithText(ChoiceChip, 'XI IPA 1'));
    await _shot(tester, 'guru-siswa');

    await tester.tap(find.text('Anisa Rahmawati'));
    await waitFor(tester, find.byKey(const Key('student-active-book')));
    await waitFor(tester, find.text('Pulang'));
    await _shot(tester, 'guru-detail-siswa');
    await _back(tester);

    await waitFor(tester, find.text('Dewi Lestari Putri'));
    await tester.tap(find.text('Dewi Lestari Putri'));
    await waitFor(tester, find.byKey(const Key('student-active-book')));
    await tester.tap(find.byKey(const Key('student-active-book')));
    await waitFor(tester, find.textContaining('Hal. '));
    await tester.tap(find.textContaining('Hal. ').first);
    await waitFor(tester, find.byKey(const Key('comment-input')));
    await waitFor(tester, find.text('Sari Wulandari'));
    await _shot(tester, 'guru-jurnal');
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('admin: beranda, pengguna, pengaturan', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, 'admin');
    await waitFor(tester, find.text('Aktivitas membaca siswa'));
    await _shot(tester, 'admin-beranda');

    await tester.tap(navTab('Pengguna'));
    await waitFor(tester, find.text('Anisa Rahmawati'));
    await waitFor(tester, find.widgetWithText(ChoiceChip, 'XI IPA 1'));
    await _shot(tester, 'admin-pengguna');

    await tester.tap(navTab('Kelas'));
    await waitFor(tester, find.text('XI IPA 1'));
    await _shot(tester, 'admin-kelas');
    await FirebaseAuth.instance.signOut();
  });
}
