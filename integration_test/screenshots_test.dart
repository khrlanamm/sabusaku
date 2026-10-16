// Screenshots of the real app for the user guide (docs/manual) and the Play
// Store listing (store/), taken against PRODUCTION with real accounts.
//
// Run through tool/screenshots.sh, never directly: it mints a one-hour
// custom token for the account (no password, no Google account on the
// device) and saves the images through test_driver/screenshots.dart.
//
// SHOT_PHASE picks what runs:
//   siswa-start  signed-out screens, then the student starts a catalog book
//                and writes today's journal (skipped if a book is active)
//   guru         the teacher comments on that journal once, then the
//                teacher screens
//   siswa        the student screens, including the comment
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sabusaku/app/app.dart';
import 'package:sabusaku/app/router/app_router.dart';
import 'package:sabusaku/app/router/routes.dart';
import 'package:sabusaku/app/theme/theme_preference.dart';
import 'package:sabusaku/bootstrap.dart';
import 'package:sabusaku/core/storage/prefs.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart' show dismissNotificationPrompt, tapVisible, waitFor;

const _phase = String.fromEnvironment('SHOT_PHASE');
const _token = String.fromEnvironment('SHOT_TOKEN');
const _studentEmail = String.fromEnvironment('SHOT_STUDENT');

/// The catalog book the student reads in the screenshots.
const _bookQuery = 'laskar pelangi';
const _bookId = 'bk_b2f7ffdfc9bd6dda';

/// What the student writes about pages 1–48 of Laskar Pelangi.
const _journalKey =
    'Hari pertama di SD Muhammadiyah Gantong, sekolah hanya boleh dibuka '
    'kalau ada sepuluh murid. Sampai siang baru ada sembilan, lalu Harun '
    'datang sebagai murid kesepuluh. Bu Muslimah dan Pak Harfan lega.';
const _journalReflection =
    'Aku jadi sadar betapa berharganya bisa sekolah, walaupun gedungnya '
    'hampir roboh.';
const _journalQuestion =
    'Kenapa Pak Harfan tetap mempertahankan sekolah yang muridnya sedikit?';
const _comment =
    'Ringkasanmu runtut, Alan. Coba perhatikan juga cara Bu Muslimah '
    'memandang murid-muridnya di bab berikutnya.';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;

  Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name, {int wait = 2000}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester, wait);
    if (!surfaceConverted && Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
      await settle(tester, 500);
    }
    await binding.takeScreenshot(name);
  }

  late ProviderContainer container;

  Future<void> go(WidgetTester tester, String location, Finder ready) async {
    container.read(appRouterProvider).go(location);
    await waitFor(tester, ready, timeout: const Duration(seconds: 40));
  }

  Future<void> startApp(WidgetTester tester) async {
    await initFirebase();
    await FirebaseAuth.instance.signOut();
    await initializeDateFormatting('id_ID');
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SabuSakuApp(),
      ),
    );
  }

  Future<void> signIn(WidgetTester tester) async {
    expect(_token, isNotEmpty, reason: 'Run through tool/screenshots.sh');
    await FirebaseAuth.instance.signInWithCustomToken(_token);
    await waitFor(tester, find.byType(NavigationBar));
  }

  String schoolId() => container.read(currentSessionProvider).schoolId;

  Future<String?> activeProgramId(String studentId) async {
    final lock = await FirebaseFirestore.instance
        .doc('schools/${schoolId()}/activePrograms/$studentId')
        .get();
    return lock.data()?['programId'] as String?;
  }

  /// The teacher cannot read the student's lock; the programs are visible.
  Future<String?> activeProgramOf(String studentId) async {
    final programs = await FirebaseFirestore.instance
        .collection('schools/${schoolId()}/programs')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    return programs.docs.isEmpty ? null : programs.docs.first.id;
  }

  Future<String?> latestJournalDate(String programId) async {
    final journals = await FirebaseFirestore.instance
        .collection('schools/${schoolId()}/programs/$programId/journals')
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    return journals.docs.isEmpty ? null : journals.docs.first.id;
  }

  testWidgets('screenshots: $_phase', (tester) async {
    await startApp(tester);

    switch (_phase) {
      case 'siswa-start':
        await waitFor(tester, find.byKey(const Key('login-submit')));
        await shot(tester, 'mulai-login');
        await go(tester, Routes.register, find.byType(TextFormField));
        await shot(tester, 'mulai-daftar');

        await signIn(tester);
        await dismissNotificationPrompt(tester);
        final uid = container.read(currentSessionProvider).uid;
        if (await activeProgramId(uid) == null) {
          await go(
            tester,
            Routes.studentBook,
            find.byKey(const Key('book-search')),
          );
          await shot(tester, 'siswa-mulai-buku');
          await tester.enterText(
            find.byKey(const Key('book-search')),
            'laskar',
          );
          await waitFor(tester, find.byKey(const Key('book-search-result-0')));
          await shot(tester, 'siswa-cari-buku', wait: 4000);
          await tapVisible(tester, find.byKey(const Key('book-manual')));
          await shot(tester, 'siswa-isi-data-sendiri');
          await tapVisible(
            tester,
            find.byKey(const Key('book-back-to-search')),
          );
          await tester.enterText(
            find.byKey(const Key('book-search')),
            _bookQuery,
          );
          await waitFor(tester, find.byKey(const Key('book-search-result-0')));
          await tapVisible(
            tester,
            find.byKey(const Key('book-search-result-0')),
          );
          await waitFor(tester, find.byKey(const Key('book-clear-pick')));
          await shot(tester, 'siswa-buku-dipilih', wait: 4000);
          await tapVisible(tester, find.byKey(const Key('book-start')));
          await waitFor(
            tester,
            find.byKey(const Key('book-stop')),
            timeout: const Duration(seconds: 60),
          );
        }

        await go(
          tester,
          Routes.studentWriteJournal,
          find.byKey(const Key('journal-save')),
        );
        final programId = (await activeProgramId(uid))!;
        if (await latestJournalDate(programId) == null) {
          await tester.enterText(
            find.byKey(const Key('journal-page-end')),
            '48',
          );
          await tapVisible(
            tester,
            find.byKey(const Key('journal-duration-30to60')),
          );
          await tester.enterText(
            find.byKey(const Key('journal-key-information')),
            _journalKey,
          );
          await tester.enterText(
            find.byKey(const Key('journal-reflection')),
            _journalReflection,
          );
          await tester.enterText(
            find.byKey(const Key('journal-question')),
            _journalQuestion,
          );
          await tester.pump();
          await shot(tester, 'siswa-isi-jurnal');
          await tapVisible(tester, find.byKey(const Key('journal-save')));
          // Saved: the form reloads as an edit of today's journal.
          await waitFor(
            tester,
            find.textContaining('mengubah jurnal'),
            timeout: const Duration(seconds: 60),
          );
        }

      case 'guru':
        await signIn(tester);
        final students = await FirebaseFirestore.instance
            .collection('schools/${schoolId()}/users')
            .where('email', isEqualTo: _studentEmail)
            .get();
        final studentId = students.docs.single.id;
        final programId = (await activeProgramOf(studentId))!;
        final date = (await latestJournalDate(programId))!;
        final comments = await FirebaseFirestore.instance
            .collection(
              'schools/${schoolId()}/programs/$programId/journals/$date/comments',
            )
            .get();

        await go(
          tester,
          Routes.teacherJournal(studentId, programId, date),
          find.byKey(const Key('comment-input')),
        );
        if (comments.docs.isEmpty) {
          await tester.enterText(
            find.byKey(const Key('comment-input')),
            _comment,
          );
          await tapVisible(tester, find.byKey(const Key('comment-send')));
          await waitFor(tester, find.text(_comment));
        }
        await shot(tester, 'guru-jurnal-komentar');

        await go(tester, Routes.teacherDashboard, find.text('Status siswa'));
        await shot(tester, 'guru-dashboard', wait: 4000);
        await go(
          tester,
          Routes.teacherStudents,
          find.byKey(const Key('students-add')),
        );
        await shot(tester, 'guru-siswa', wait: 3000);
        await go(
          tester,
          Routes.teacherAddStudents,
          find.byKey(const Key('add-email-0')),
        );
        await shot(tester, 'guru-tambah-siswa');
        await go(tester, Routes.teacherImportStudents, find.byType(Scaffold));
        await shot(tester, 'guru-impor-csv');
        await go(
          tester,
          Routes.teacherStudent(studentId),
          find.byKey(const Key('student-active-book')),
        );
        await shot(tester, 'guru-detail-siswa', wait: 4000);
        await go(
          tester,
          Routes.teacherProgram(studentId, programId),
          find.textContaining('Hal. '),
        );
        await shot(tester, 'guru-jurnal-siswa');
        await go(tester, Routes.teacherSchool, find.textContaining('Kelas ('));
        await shot(tester, 'guru-sekolah', wait: 3000);
        await go(tester, Routes.teacherSettings, find.byType(Scaffold));
        await shot(tester, 'guru-pengaturan-sekolah', wait: 3000);
        await go(
          tester,
          Routes.teacherBooks,
          find.textContaining('Semua buku'),
        );
        await shot(tester, 'guru-katalog', wait: 5000);
        await go(
          tester,
          Routes.teacherBook(_bookId),
          find.textContaining('Pembaca'),
        );
        await shot(tester, 'guru-detail-buku', wait: 4000);
        await go(
          tester,
          Routes.teacherAddBook,
          find.byKey(const Key('editor-title')),
        );
        await shot(tester, 'guru-tambah-buku');
        await go(tester, Routes.teacherSuggestions, find.byType(Scaffold));
        await shot(tester, 'guru-saran', wait: 3000);
        await go(tester, Routes.teacherDeletedBooks, find.byType(Scaffold));
        await shot(tester, 'guru-buku-terhapus', wait: 3000);
        await go(tester, Routes.teacherProfile, find.byType(Scaffold));
        await shot(tester, 'guru-profil', wait: 3000);
        await container
            .read(themePreferenceControllerProvider.notifier)
            .set(ThemePreference.gelap);
        await go(tester, Routes.teacherDashboard, find.text('Status siswa'));
        await shot(tester, 'guru-dashboard-gelap', wait: 3000);
        await go(
          tester,
          Routes.teacherBooks,
          find.textContaining('Semua buku'),
        );
        await shot(tester, 'guru-katalog-gelap', wait: 4000);

      case 'siswa':
        await signIn(tester);
        await dismissNotificationPrompt(tester);
        final uid = container.read(currentSessionProvider).uid;
        final programId = (await activeProgramId(uid))!;
        final date = (await latestJournalDate(programId))!;

        await go(tester, Routes.studentHome, find.text('Buku bulan ini'));
        await shot(tester, 'siswa-beranda', wait: 4000);
        await go(
          tester,
          Routes.studentBook,
          find.byKey(const Key('book-stop')),
        );
        await shot(tester, 'siswa-buku-saya', wait: 4000);
        await go(tester, Routes.studentJournals, find.textContaining('Hal. '));
        await shot(tester, 'siswa-riwayat-jurnal');
        await go(
          tester,
          Routes.studentJournal(programId, date),
          find.text(_comment),
        );
        await shot(tester, 'siswa-jurnal-komentar');
        await go(
          tester,
          Routes.studentWriteJournal,
          find.byKey(const Key('journal-save')),
        );
        await shot(tester, 'siswa-ubah-jurnal');
        await go(
          tester,
          Routes.studentExplore,
          find.textContaining('Semua buku'),
        );
        await shot(tester, 'siswa-jelajahi', wait: 5000);
        await tapVisible(
          tester,
          find.byKey(const Key('explore-category-Sastra Klasik')),
        );
        await shot(tester, 'siswa-jelajahi-klasik', wait: 5000);
        await go(
          tester,
          Routes.studentCatalogBook(_bookId),
          find.byType(Scaffold),
        );
        await shot(tester, 'siswa-detail-buku', wait: 4000);
        await go(tester, Routes.studentProfile, find.byType(Scaffold));
        await shot(tester, 'siswa-profil', wait: 4000);
        await go(
          tester,
          Routes.changePassword,
          find.byKey(const Key('password-new')),
        );
        // A partial password, so the checklist shows met and unmet rules.
        await tester.enterText(
          find.byKey(const Key('password-new')),
          String.fromCharCodes(const [83, 97, 98, 117, 49]),
        );
        await tester.pump();
        await shot(tester, 'siswa-ubah-password');
        await container
            .read(themePreferenceControllerProvider.notifier)
            .set(ThemePreference.gelap);
        await go(tester, Routes.studentHome, find.text('Buku bulan ini'));
        await shot(tester, 'siswa-beranda-gelap', wait: 3000);
        await go(
          tester,
          Routes.studentExplore,
          find.textContaining('Semua buku'),
        );
        await shot(tester, 'siswa-jelajahi-gelap', wait: 5000);

      default:
        fail('Unknown SHOT_PHASE "$_phase"');
    }
  });
}
