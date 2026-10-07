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

import 'package:sabusaku/core/widgets/journal_view.dart';

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

  testWidgets('siswa: first login, starts a book, writes a journal', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, username: e2eStudent, password: studentPassword);
    await setNewPassword(tester);

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

    // The journal is in the history, and the book cannot be finished yet.
    await tester.tap(navTab('Jurnal'));
    await waitFor(tester, find.textContaining('Hal. 1–40'));
    await tester.tap(navTab('Buku'));
    await waitFor(tester, find.byKey(const Key('book-complete')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('book-complete')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('guru: sees the class, opens the journal, comments', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, username: e2eTeacher, password: teacherPassword);
    await setNewPassword(tester);

    // Dashboard built from the summary documents of the assigned class.
    await waitFor(tester, find.text('Status siswa'));
    await waitFor(tester, find.text('Buku aktif'));

    // Student list → detail → active book → journal.
    await tester.tap(navTab('Siswa'));
    await waitFor(tester, find.text('Raka Pratama'));
    expect(find.text('Aktif'), findsWidgets);
    await tester.tap(find.text('Raka Pratama'));
    await waitFor(tester, find.byKey(const Key('student-active-book')));
    expect(find.textContaining('Halaman 40 dari 100'), findsOneWidget);
    await tester.tap(find.byKey(const Key('student-active-book')));
    await waitFor(tester, find.textContaining('Hal. 1–40'));
    await tester.tap(find.textContaining('Hal. 1–40'));
    await waitFor(tester, find.text(e2eJournalText));

    // Comment on it.
    await tester.enterText(
      find.byKey(const Key('comment-input')),
      e2eCommentText,
    );
    // Hides the keyboard first: it moves the composer while it animates.
    await tapVisible(tester, find.byKey(const Key('comment-send')));
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(CommentTile),
        matching: find.text(e2eCommentText),
      ),
    );
    expect(find.text('Bu Sari'), findsOneWidget);
  });

  testWidgets('siswa: sees the new teacher comment and reads it', (
    tester,
  ) async {
    await startApp(tester);
    await signIn(tester, username: e2eStudent, password: e2eNewPassword);
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await dismissNotificationPrompt(tester);

    // The server flagged the journal when the teacher commented.
    await waitFor(tester, find.byKey(const Key('home-new-comments')));
    await tester.tap(find.textContaining('Jurnal ').last);
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(CommentTile),
        matching: find.text(e2eCommentText),
      ),
    );
    expect(find.text('Bu Sari'), findsOneWidget);

    // Opening the journal marks the comment as read.
    // `pageBack` looks for the English tooltip; the app runs in Indonesian.
    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.text('Jurnal hari ini sudah diisi'));
    await waitForGone(tester, find.byKey(const Key('home-new-comments')));
  });
}
