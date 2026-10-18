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
import 'package:sabusaku/core/widgets/report_sheet.dart';
import 'package:sabusaku/features/teacher/presentation/reports_screen.dart';

import 'support.dart';

const _wrongCredentials = 'Email atau password salah.';
const _wrongInput = 'bukan-yang-benar';
const _bookReportNote = 'Jumlah halamannya tidak sesuai bukunya.';
const _resolution = 'Jumlah halaman sudah diperbaiki.';

/// Opens [menuKey]'s popup menu and picks [itemKey].
Future<void> _pickMenu(
  WidgetTester tester,
  String menuKey,
  String itemKey,
) async {
  await tapVisible(tester, find.byKey(Key(menuKey)));
  await waitFor(tester, find.byKey(Key(itemKey)));
  // The menu grows in; tap once it stands still.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.byKey(Key(itemKey)));
  await waitFor(tester, find.byKey(const Key('report-sheet')));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Picks [reason] in the open report sheet, adds [note] and sends it.
Future<void> _sendReport(
  WidgetTester tester,
  String reason, {
  String? note,
}) async {
  await tapVisible(tester, find.byKey(Key('report-reason-$reason')));
  if (note != null) {
    await tester.enterText(find.byKey(const Key('report-note')), note);
  }
  await tapVisible(tester, find.byKey(const Key('report-submit')));
  await waitForGone(tester, find.byKey(const Key('report-sheet')));
}

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

    // The first sign-in asks for the terms of use, even before the name.
    await waitFor(tester, find.byKey(const Key('terms-screen')));
    expect(find.byKey(const Key('complete-submit')), findsNothing);
    await tapVisible(tester, termsAccept);

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

    // A book that is not in the catalog: entered by hand, sent as a suggestion.
    await tester.tap(find.byKey(const Key('home-start-book')));
    await waitFor(tester, find.byKey(const Key('book-manual')));
    await tapVisible(tester, find.byKey(const Key('book-manual')));
    await tester.enterText(find.byKey(const Key('book-title')), e2eNewBook);
    await tester.enterText(
      find.byKey(const Key('book-author')),
      'Ahmad Tohari',
    );
    await tester.enterText(find.byKey(const Key('book-pages')), '300');
    await waitFor(tester, find.byKey(const Key('book-new-note')));
    await tapVisible(tester, find.byKey(const Key('book-start')));
    await waitFor(tester, find.byKey(const Key('book-stop')));
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
    // Found in the catalog; the page count differs from this copy.
    await waitFor(tester, find.byKey(const Key('book-search')));
    await tester.enterText(find.byKey(const Key('book-search')), 'laskar');
    await waitFor(tester, find.byKey(const Key('book-search-result-0')));
    await tapVisible(tester, find.byKey(const Key('book-search-result-0')));
    await waitFor(tester, find.byKey(const Key('book-clear-pick')));
    expect(find.text('Andrea Hirata'), findsWidgets);
    await tester.enterText(find.byKey(const Key('book-pages')), '100');
    await waitFor(tester, find.byKey(const Key('book-edited-note')));
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

    // Every card on Beranda opens its page. Once the server has counted the
    // journal, the student is on this month's leaderboard.
    await tester.tap(navTab('Beranda'));
    await waitFor(tester, find.byKey(const Key('home-stat-rank')));
    await tapVisible(tester, find.byKey(const Key('home-stat-rank')));
    await waitFor(tester, find.byKey(const Key('rank-mine')));
    expect(find.textContaining('$e2eStudentName (kamu)'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.byKey(const Key('home-book-history')));
    await tapVisible(tester, find.byKey(const Key('home-book-history')));
    await waitFor(tester, find.byKey(const Key('book-history-search')));
    expect(find.text(e2eBook), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.byKey(const Key('home-stat-journals')));
    await tapVisible(tester, find.byKey(const Key('home-stat-journals')));
    await waitFor(tester, find.byKey(const Key('journals-view')));
    expect(find.textContaining('Hal. 1–40'), findsOneWidget);
  });

  testWidgets('guru comments, adds a student and removes another', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, email: e2eTeacherEmail, password: e2eInitialPassword);
    await waitFor(tester, find.text('Status siswa'));
    // She supervises Masis-KIR, so she is asked about the morning digest.
    await dismissNotificationPrompt(tester);
    expect(navTab('Sekolah'), findsOneWidget);

    // Her students' leaderboard ("Binaan saya": Raka is in Masis-KIR).
    await tapVisible(tester, find.byKey(const Key('dashboard-ranking')));
    await waitFor(tester, find.textContaining(e2eStudentName));
    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.text('Status siswa'));

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

  testWidgets('guru applies an edit and adds a suggested book to the catalog', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, email: e2eTeacherEmail, password: e2eInitialPassword);
    await waitFor(tester, navTab('Buku'));
    await dismissNotificationPrompt(tester);
    await tester.tap(navTab('Buku'));
    await waitFor(tester, find.byKey(const Key('books-suggestions')));
    await tester.tap(find.byKey(const Key('books-suggestions')));

    // The page count a student entered for Laskar Pelangi.
    await waitFor(tester, find.text(e2eBook));
    await tester.tap(find.text(e2eBook).first);
    await waitFor(tester, find.byKey(const Key('suggestion-apply')));
    await tapVisible(tester, find.byKey(const Key('suggestion-apply')));
    await waitFor(tester, find.text('Saran diterapkan ke katalog.'));
    await tester.tap(find.byType(BackButton));

    // A book no catalog had: added with a category.
    await waitFor(tester, find.text(e2eNewBook));
    await tester.tap(find.text(e2eNewBook).first);
    await waitFor(tester, find.byKey(const Key('suggestion-create')));
    await tapVisible(tester, find.byKey(const Key('suggestion-create')));
    // The save button sits at the end of a lazy list; tapVisible scrolls.
    await waitFor(tester, find.byKey(const Key('editor-title')));
    await tapVisible(tester, find.byKey(const Key('editor-category-Novel')));
    await tapVisible(tester, find.byKey(const Key('editor-save')));
    await waitFor(tester, find.byKey(const Key('book-edit-button')));

    // Its history records the creation; the catalog search now finds it.
    await waitFor(tester, find.textContaining('Ditambahkan'));
    await tester.tap(find.byType(BackButton).first);
    await tester.pump(const Duration(milliseconds: 500));
    while (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton).first);
      await tester.pump(const Duration(milliseconds: 500));
    }
    await waitFor(tester, find.byKey(const Key('books-search')));
    await tester.enterText(find.byKey(const Key('books-search')), 'ronggeng');
    await waitFor(tester, find.text(e2eNewBook));
  });

  testWidgets(
    'guru sets her homeroom class, scopes the dashboard, adds a guru',
    (tester) async {
      await startApp(tester);
      await signIn(
        tester,
        email: e2eTeacherEmail,
        password: e2eInitialPassword,
      );
      await waitFor(tester, find.text('Status siswa'));
      await dismissNotificationPrompt(tester);
      // She supervises Masis-KIR: the dashboard opens on her own students.
      expect(find.byKey(const Key('scope-mine')), findsOneWidget);

      // Profil: she becomes the homeroom teacher of XII-A1.
      await tester.tap(navTab('Profil'));
      await waitFor(tester, find.byKey(const Key('profile-homeroom')));
      await tester.tap(find.byKey(const Key('profile-homeroom')));
      await waitFor(tester, find.byKey(const Key('roles-save')));
      await pickClass(tester, e2eClass);
      await tapVisible(tester, find.byKey(const Key('roles-save')));
      await waitForGone(tester, find.byKey(const Key('roles-save')));
      await waitFor(
        tester,
        find.descendant(
          of: find.byKey(const Key('profile-homeroom')),
          matching: find.text(e2eClass),
        ),
      );

      // Sekolah: she adds another teacher, who waits under "Belum masuk".
      await tester.tap(navTab('Sekolah'));
      await waitFor(tester, find.byKey(const Key('school-add-class')));
      // Further down a lazy list; tapVisible scrolls to it.
      await tapVisible(tester, find.byKey(const Key('school-add-teacher')));
      await waitFor(tester, find.byKey(const Key('add-teacher-email')));
      await tester.enterText(
        find.byKey(const Key('add-teacher-email')),
        'Guru.Baru@E2E.test',
      );
      await tester.enterText(
        find.byKey(const Key('add-teacher-name')),
        'Bambang Sutejo, S.Pd.',
      );
      await tapVisible(tester, find.byKey(const Key('add-teacher-submit')));
      await waitFor(tester, find.byKey(const Key('school-add-teacher')));
      await tapVisible(
        tester,
        find.byKey(const Key('school-pending-teachers')),
      );
      await waitFor(tester, find.text('Bambang Sutejo, S.Pd.'));

      // Dashboard: narrowed to XII-A1, the active-book card keeps the scope.
      await tester.tap(navTab('Dashboard'));
      await waitFor(tester, find.byKey(const Key('scope-class')));
      await tester.tap(find.byKey(const Key('scope-class')));
      await waitFor(tester, find.text(e2eClass).last);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(e2eClass).last);
      await waitFor(tester, find.text('Kelas $e2eClass'));
      await tester.tap(find.byKey(const Key('dashboard-card-books')));
      await waitFor(tester, find.byKey(const Key('active-books-summary')));
      expect(find.text('Kelas $e2eClass'), findsOneWidget);
      await waitFor(tester, find.text(e2eStudentName));
      expect(find.text(e2eBook), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await waitFor(tester, find.text('Status siswa'));
    },
  );

  testWidgets('siswa sees the homeroom teacher on the profile', (tester) async {
    await startApp(tester);
    await signIn(tester, email: e2eStudentEmail, password: e2eInitialPassword);
    await waitFor(tester, navTab('Profil'));
    await dismissNotificationPrompt(tester);
    await tester.tap(navTab('Profil'));
    await waitFor(tester, find.textContaining('Wali kelas: $e2eTeacherName'));
    expect(
      find.textContaining('Masis-KIR (pembina: $e2eTeacherName)'),
      findsOneWidget,
    );
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
    // The card of the commented journal ("Jurnal Kamis, 15 Oktober 2026"),
    // not the "Jurnal bulan ini" statistic below it.
    await tester.tap(find.textContaining(RegExp(r'^Jurnal \S+, ')).first);
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

  testWidgets('siswa reports the teacher comment', (tester) async {
    await startApp(tester);
    await signIn(tester, email: e2eStudentEmail, password: e2eInitialPassword);
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await dismissNotificationPrompt(tester);

    await tester.tap(navTab('Jurnal'));
    await waitFor(tester, find.textContaining('Hal. 1–40'));
    await tester.tap(find.textContaining('Hal. 1–40'));
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(CommentTile),
        matching: find.text(e2eCommentText),
      ),
    );

    await _pickMenu(tester, 'comment-menu', 'comment-report');
    expect(find.text('Laporkan komentar'), findsOneWidget);
    await _sendReport(tester, 'inappropriate');
    // About a teacher: only the developer reads it.
    await waitFor(tester, find.text(reportSentToDeveloperMessage));
  });

  testWidgets('siswa reports a catalog book', (tester) async {
    await startApp(tester);
    await signIn(tester, email: e2eRegisterEmail, password: e2eNewPassword);
    await waitFor(tester, find.byKey(const Key('home-start-book')));
    await dismissNotificationPrompt(tester);

    await tester.tap(find.byKey(const Key('home-start-book')));
    await waitFor(tester, find.byKey(const Key('book-explore')));
    await tapVisible(tester, find.byKey(const Key('book-explore')));
    await waitFor(tester, find.byKey(const Key('explore-book-0')));
    await tester.tap(find.byKey(const Key('explore-book-0')));
    // The menu shows once the book has loaded.
    await waitFor(tester, find.byKey(const Key('book-menu')));

    await _pickMenu(tester, 'book-menu', 'book-report');
    expect(find.text('Laporkan buku'), findsOneWidget);
    await _sendReport(tester, 'wrong_data', note: _bookReportNote);
    await waitFor(tester, find.text(reportSentMessage));
  });

  testWidgets('guru reports a journal and resolves the book report', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, email: e2eTeacherEmail, password: e2eInitialPassword);
    await waitFor(tester, find.text('Status siswa'));
    await dismissNotificationPrompt(tester);

    // The student's journal, from the student list.
    await tester.tap(navTab('Siswa'));
    await waitFor(tester, find.text(e2eStudentName));
    await tester.tap(find.text(e2eStudentName));
    await waitFor(tester, find.byKey(const Key('student-active-book')));
    await tester.tap(find.byKey(const Key('student-active-book')));
    await waitFor(tester, find.textContaining('Hal. 1–40'));
    await tester.tap(find.textContaining('Hal. 1–40'));
    await waitFor(tester, find.text(e2eJournalText));
    await _pickMenu(tester, 'journal-menu', 'journal-report');
    await _sendReport(tester, 'other');
    await waitFor(tester, find.text(reportSentMessage));
    while (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton).first);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Sekolah → Laporan: the journal and the book report, not the report
    // about the teacher's comment.
    await tester.tap(navTab('Sekolah'));
    await waitFor(tester, find.text('2 laporan perlu ditinjau'));
    await tapVisible(tester, find.byKey(const Key('school-reports')));
    await waitFor(tester, find.byKey(const Key('report-card-1')));
    expect(find.byKey(const Key('report-card-2')), findsNothing);
    expect(find.text(e2eCommentText), findsNothing);
    expect(find.text('Data buku salah'), findsOneWidget);
    expect(find.textContaining(_bookReportNote), findsOneWidget);
    expect(find.textContaining(e2eRegisterName), findsOneWidget);
    expect(find.textContaining(e2eJournalText), findsOneWidget);

    final bookCard = find.ancestor(
      of: find.text('Data buku salah'),
      matching: find.byType(ReportCard),
    );
    await tapVisible(
      tester,
      find.descendant(of: bookCard, matching: find.text('Tandai selesai')),
    );
    await waitFor(tester, find.byKey(const Key('report-resolution')));
    await tester.enterText(
      find.byKey(const Key('report-resolution')),
      _resolution,
    );
    await tester.tap(find.byKey(const Key('report-resolve-confirm')));
    await waitFor(tester, find.text('Laporan ditandai selesai.'));
    await waitForGone(tester, find.byKey(const Key('report-card-1')));
    expect(find.text('Data buku salah'), findsNothing);

    await tester.tap(find.byKey(const Key('reports-resolved')));
    await waitFor(tester, find.text(_resolution));
    expect(find.text('Data buku salah'), findsOneWidget);
    expect(find.textContaining('Selesai oleh $e2eTeacherName'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.text('1 laporan perlu ditinjau'));
  });
}
