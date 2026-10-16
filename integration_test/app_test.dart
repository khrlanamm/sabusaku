// End-to-end flows against the Firebase Emulator Suite. The tests run in
// order and build on each other, like a school starting to use the app.
//
//   tool/e2e.sh [device-id]
//
// The script starts the emulators, seeds them (functions/tools/seed-e2e.ts)
// and passes this run's sign-in secrets to both the seed and this test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:sabusaku/core/widgets/journal_view.dart';

import 'support.dart';

const _wrongCredentials = 'Email atau password salah.';
const _wrongInput = 'bukan-yang-benar';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(e2eInitialPassword, isNotEmpty, reason: 'Run through tool/e2e.sh');
    expect(e2eNewPassword, isNotEmpty, reason: 'Run through tool/e2e.sh');
  });

  testWidgets('wrong password, and an email no school registered', (
    tester,
  ) async {
    await startApp(tester);

    await signIn(tester, email: e2eStudentEmail, password: _wrongInput);
    await waitFor(tester, find.text(_wrongCredentials));

    // A valid account on no roster: told to contact the school, then out.
    await signIn(tester, email: e2eOutsiderEmail, password: e2eInitialPassword);
    await waitFor(tester, find.byKey(const Key('dialog-not-registered')));
    expect(
      find.text('Harap Menghubungi Administrator Sekolah'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('link-school-signup')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-not-registered-close')));
    await waitForGone(tester, find.byKey(const Key('dialog-not-registered')));
    await waitFor(tester, find.byKey(const Key('login-submit')));
  });

  testWidgets('siswa without name and class completes the profile first', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(
      tester,
      email: e2eNewStudentEmail,
      password: e2eInitialPassword,
    );

    await waitFor(tester, find.byKey(const Key('complete-submit')));
    // The account has a password: only name and class are asked.
    expect(find.byKey(const Key('password-new')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('complete-name')),
      'Bagas Saputra',
    );
    await pickClass(tester, 'XII-A2');
    await tapVisible(tester, find.byKey(const Key('complete-submit')));

    await waitFor(tester, find.byKey(const Key('home-start-book')));
    await dismissNotificationPrompt(tester);
    expect(navTab('Beranda'), findsOneWidget);
  });

  testWidgets('Google-only siswa adds a password, then signs in with it', (
    tester,
  ) async {
    await startApp(tester);
    await signInWithFakeGoogle();

    // Name and class came from the roster; only the password is missing.
    await waitFor(tester, find.byKey(const Key('complete-submit')));
    await waitFor(tester, find.byKey(const Key('password-new')));
    await enterNewPassword(tester, e2eNewPassword);
    await tapVisible(tester, find.byKey(const Key('complete-submit')));
    await waitFor(tester, find.byKey(const Key('home-start-book')));
    await dismissNotificationPrompt(tester);

    await signOut(tester);
    await signIn(tester, email: e2eGoogleEmail, password: e2eNewPassword);
    await waitFor(tester, find.byKey(const Key('home-start-book')));
  });

  testWidgets('siswa signs up with email and verifies it', (tester) async {
    await startApp(tester);
    await waitFor(tester, find.byKey(const Key('login-register')));
    await tester.tap(find.byKey(const Key('login-register')));
    await waitFor(tester, find.byKey(const Key('register-submit')));
    await tester.enterText(
      find.byKey(const Key('register-email')),
      e2eRegisterEmail,
    );
    await enterNewPassword(tester, e2eNewPassword);
    await tapVisible(tester, find.byKey(const Key('register-submit')));

    // Not verified yet: the app waits for the link.
    await waitFor(tester, find.byKey(const Key('verify-check')));
    await verifyEmailOnEmulator(e2eRegisterEmail);
    await tapVisible(tester, find.byKey(const Key('verify-check')));

    // Joined with the name and class the teacher entered.
    await waitFor(tester, find.byKey(const Key('home-start-book')));
    await dismissNotificationPrompt(tester);
    expect(find.textContaining('Dewi'), findsWidgets);
  });

  testWidgets('siswa starts a book and writes a journal', (tester) async {
    await startApp(tester);
    await signIn(tester, email: e2eStudentEmail, password: e2eInitialPassword);

    // No book yet: the home offers to start one.
    await waitFor(tester, find.byKey(const Key('home-start-book')));
    await dismissNotificationPrompt(tester);
    await tester.tap(find.byKey(const Key('home-start-book')));
    await waitFor(tester, find.byKey(const Key('book-title')));
    await tester.enterText(find.byKey(const Key('book-title')), e2eBook);
    await tester.enterText(
      find.byKey(const Key('book-author')),
      'Andrea Hirata',
    );
    await tester.enterText(find.byKey(const Key('book-pages')), '100');
    await tapVisible(tester, find.byKey(const Key('book-start')));
    await waitFor(tester, find.byKey(const Key('book-stop')));
    expect(find.text('Halaman 0 dari 100'), findsOneWidget);

    // Write today's journal from the home screen.
    await tester.tap(navTab('Beranda'));
    await waitFor(tester, find.byKey(const Key('home-write-journal')));
    await waitForGone(tester, find.byType(SnackBar));
    await tester.tap(find.byKey(const Key('home-write-journal')));
    await waitFor(tester, find.byKey(const Key('journal-save')));
    await tester.enterText(find.byKey(const Key('journal-page-end')), '40');
    await tapVisible(tester, find.byKey(const Key('journal-duration-15to30')));
    await tester.enterText(
      find.byKey(const Key('journal-key-information')),
      e2eJournalText,
    );
    await tapVisible(tester, find.byKey(const Key('journal-save')));

    // Saved locally at once; the server-computed numbers follow.
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await waitFor(tester, find.textContaining('Halaman 40 dari 100'));
    await waitFor(tester, find.text('1 hari'));

    await tester.tap(navTab('Jurnal'));
    await waitFor(tester, find.textContaining('Hal. 1–40'));
  });

  testWidgets('guru comments, adds a student and removes another', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, email: e2eTeacherEmail, password: e2eInitialPassword);
    await waitFor(tester, find.text('Status siswa'));
    expect(navTab('Sekolah'), findsOneWidget);

    // Student list → detail → active book → journal → comment.
    await tester.tap(navTab('Siswa'));
    await waitFor(tester, find.text(e2eStudentName));
    await tester.tap(find.text(e2eStudentName));
    await waitFor(tester, find.byKey(const Key('student-active-book')));
    expect(find.textContaining('Halaman 40 dari 100'), findsOneWidget);
    await tester.tap(find.byKey(const Key('student-active-book')));
    await waitFor(tester, find.textContaining('Hal. 1–40'));
    await tester.tap(find.textContaining('Hal. 1–40'));
    await waitFor(tester, find.text(e2eJournalText));
    await tester.enterText(
      find.byKey(const Key('comment-input')),
      e2eCommentText,
    );
    await tapVisible(tester, find.byKey(const Key('comment-send')));
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(CommentTile),
        matching: find.text(e2eCommentText),
      ),
    );
    await tester.tap(find.byType(BackButton));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(BackButton));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.byKey(const Key('students-add')));

    // Add a student by email only; they wait under "Belum masuk".
    await tapVisible(tester, find.byKey(const Key('students-add')));
    await waitFor(tester, find.byKey(const Key('students-add-manual')));
    await tester.tap(find.byKey(const Key('students-add-manual')));
    await waitFor(tester, find.byKey(const Key('add-email-0')));
    await tester.enterText(
      find.byKey(const Key('add-email-0')),
      'Murid.Baru@E2E.test',
    );
    await tapVisible(tester, find.byKey(const Key('add-submit')));
    await waitFor(tester, find.byKey(const Key('add-result-added')));
    await tapVisible(tester, find.byKey(const Key('add-done')));
    await waitFor(tester, find.byKey(const Key('students-pending')));

    // Remove the Google student from the school.
    await waitFor(tester, find.text(e2eGoogleName));
    await tester.tap(find.text(e2eGoogleName));
    await waitFor(tester, find.byKey(const Key('student-remove')));
    await tapVisible(tester, find.byKey(const Key('student-remove')));
    await waitFor(tester, find.text('Keluarkan'));
    await tester.tap(find.text('Keluarkan'));
    await waitFor(tester, find.byKey(const Key('students-add')));
    await waitForGone(tester, find.text(e2eGoogleName));
  });

  testWidgets('removed siswa is told to contact the school', (tester) async {
    await startApp(tester);
    await signIn(tester, email: e2eGoogleEmail, password: e2eNewPassword);
    await waitFor(tester, find.byKey(const Key('dialog-not-registered')));
    await tester.tap(find.byKey(const Key('dialog-not-registered-close')));
    await waitFor(tester, find.byKey(const Key('login-submit')));
  });

  testWidgets('siswa sees the new teacher comment and reads it', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, email: e2eStudentEmail, password: e2eInitialPassword);
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await dismissNotificationPrompt(tester);

    await waitFor(tester, find.byKey(const Key('home-new-comments')));
    await tester.tap(find.textContaining('Jurnal ').last);
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(CommentTile),
        matching: find.text(e2eCommentText),
      ),
    );
    expect(find.text(e2eTeacherName), findsOneWidget);

    // Opening the journal marks the comment as read.
    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await waitForGone(tester, find.byKey(const Key('home-new-comments')));
  });
}
