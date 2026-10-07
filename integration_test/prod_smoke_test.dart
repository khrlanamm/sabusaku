// Read-only smoke test against PRODUCTION, using the demo school created by
// functions/tools/seed-demo.ts. It signs in as each role and walks the main
// screens; it never writes journals, comments or settings.
//
//   tool/smoke-prod.sh [device-id]
//
// The script passes the demo password from secret/demo-credentials.csv.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sabusaku/bootstrap.dart';

import 'support.dart';

const _password = String.fromEnvironment('DEMO_PASSWORD');
const _school = String.fromEnvironment('DEMO_SCHOOL', defaultValue: 'demo');

/// Keeps a screen up long enough to be looked at or captured from outside.
Future<void> _hold(WidgetTester tester, [int seconds = 3]) =>
    tester.pump(Duration(seconds: seconds));

Future<void> _signIn(WidgetTester tester, String username) =>
    signIn(tester, school: _school, username: username, password: _password);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(useEmulators, isFalse, reason: 'This test targets production');
    expect(_password, isNotEmpty, reason: 'Pass --dart-define=DEMO_PASSWORD');
  });

  testWidgets('siswa: beranda, buku, riwayat, jurnal, profil', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, '2001');
    await waitFor(tester, find.text('Buku bulan ini'));
    await dismissNotificationPrompt(tester);
    await waitFor(tester, find.text('Laskar Pelangi'));
    await _hold(tester);

    await tester.tap(navTab('Buku'));
    await waitFor(tester, find.byKey(const Key('book-stop')));
    await _hold(tester);

    await tester.tap(navTab('Jurnal'));
    await waitFor(tester, find.textContaining('Hal. '));
    await _hold(tester);

    // The second entry: the newest one carries the unread comment, and
    // opening it would mark it read.
    await tester.tap(find.textContaining('Hal. ').at(1));
    await waitFor(tester, find.text('Informasi penting'));
    await _hold(tester);
    await tester.tap(find.byType(BackButton));

    await waitFor(tester, navTab('Profil'));
    await tester.tap(navTab('Profil'));
    await waitFor(tester, find.text('Riwayat buku'));
    await _hold(tester);
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('guru: dashboard, siswa, detail siswa, jurnal', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, 'guru1');
    await waitFor(tester, find.text('Status siswa'));
    await _hold(tester);

    await tester.tap(navTab('Siswa'));
    // Lists build lazily; the alphabetically first student is on screen.
    await waitFor(tester, find.text('Anisa Rahmawati'));
    await _hold(tester);

    await tester.tap(find.text('Anisa Rahmawati'));
    await waitFor(tester, find.byKey(const Key('student-active-book')));
    // Her finished book from last month, from the per-class programs query.
    await waitFor(tester, find.text('Pulang'));
    await _hold(tester);

    await tester.tap(find.byKey(const Key('student-active-book')));
    await waitFor(tester, find.textContaining('Hal. '));
    await tester.tap(find.textContaining('Hal. ').first);
    await waitFor(tester, find.byKey(const Key('comment-input')));
    await _hold(tester);
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('admin: beranda, kelas, pengguna, pengaturan', (tester) async {
    await startApp(tester, allowProduction: true);
    await _signIn(tester, 'admin');
    await waitFor(tester, find.text('Aktivitas membaca siswa'));
    await _hold(tester);

    await tester.tap(navTab('Kelas'));
    await waitFor(tester, find.text('XI IPA 1'));
    await _hold(tester);

    await tester.tap(navTab('Pengguna'));
    await waitFor(tester, find.text('Anisa Rahmawati'));
    await _hold(tester);

    await tester.tap(navTab('Pengaturan'));
    await waitFor(tester, find.text('Hari netral'));
    await _hold(tester);
    await FirebaseAuth.instance.signOut();
  });
}
