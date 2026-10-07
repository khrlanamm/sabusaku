import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sabusaku/app/app.dart';
import 'package:sabusaku/bootstrap.dart';
import 'package:sabusaku/core/storage/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must match functions/tools/seed-e2e.ts.
const e2eSchool = 'e2e';

/// Sign-in secrets of the run. tool/e2e.sh generates them and passes the
/// initial one to the seed script as well, so none is written in the repo.
const e2eInitialPassword = String.fromEnvironment('E2E_INITIAL');
const e2eNewPassword = String.fromEnvironment('E2E_NEW');
const e2eClass = 'XII IPA 1';
const e2eTeacher = 'sari';
const e2eStudent = '1001';
const e2eBook = 'Laskar Pelangi';
const e2eCommentText = 'Ringkasanmu jelas, lanjutkan membaca ya.';
const e2eJournalText =
    'Ikal mulai menyadari bahwa pendidikan adalah jalan mengubah hidupnya.';

/// Initial passwords captured when the admin creates the accounts; later
/// tests sign in with them.
String teacherPassword = '';
String studentPassword = '';

/// A destination of the bottom navigation bar.
Finder navTab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Starts the real app, signed out. Tests run against the Firebase Emulator
/// Suite; only the read-only production smoke test passes [allowProduction].
Future<void> startApp(
  WidgetTester tester, {
  bool allowProduction = false,
}) async {
  if (!useEmulators && !allowProduction) {
    fail(
      'Run with --dart-define=USE_EMULATORS=true so tests never touch '
      'production',
    );
  }
  await initFirebase();
  await FirebaseAuth.instance.signOut();
  await initializeDateFormatting('id_ID');
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SabuSakuApp(),
    ),
  );
}

/// Pumps until [finder] matches. Network-backed screens never "settle" on a
/// fixed frame count, so tests wait on what they expect to see.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

/// Pumps until [finder] no longer matches, e.g. a SnackBar covering a button.
Future<void> waitForGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for $finder to disappear');
}

/// Scrolls [finder] into view first: the on-screen keyboard can cover it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // A SnackBar floats above the bottom of the screen for a few seconds.
  await waitForGone(tester, find.byType(SnackBar));
  // A focused field keeps scrolling its caret back into view.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
}

Future<void> signIn(
  WidgetTester tester, {
  required String username,
  required String password,
  String school = e2eSchool,
}) async {
  await waitFor(tester, find.byKey(const Key('login-submit')));
  await tester.enterText(find.byKey(const Key('login-school')), school);
  await tester.enterText(find.byKey(const Key('login-username')), username);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tapVisible(tester, find.byKey(const Key('login-submit')));
}

/// Completes the forced password change shown at first sign-in.
Future<void> setNewPassword(WidgetTester tester) async {
  await waitFor(tester, find.text('Buat password baru'));
  await tester.enterText(find.byKey(const Key('password-new')), e2eNewPassword);
  await tester.enterText(
    find.byKey(const Key('password-confirm')),
    e2eNewPassword,
  );
  await tapVisible(tester, find.byKey(const Key('password-submit')));
}

Future<void> signOut(WidgetTester tester) async {
  await FirebaseAuth.instance.signOut();
  await waitFor(tester, find.byKey(const Key('login-submit')));
}

/// Admin › Pengguna › + › "Tambah satu pengguna".
Future<void> openAddUser(WidgetTester tester) async {
  await waitFor(tester, find.byKey(const Key('users-add')));
  // A floating SnackBar from the previous action can sit on top of the FAB.
  await waitForGone(tester, find.byType(SnackBar));
  await tester.tap(find.byKey(const Key('users-add')));
  await waitFor(tester, find.byKey(const Key('users-add-manual')));
  await tester.tap(find.byKey(const Key('users-add-manual')));
  await waitFor(tester, find.byKey(const Key('add-user-submit')));
}

/// Reads the password from the one-time credential dialog and dismisses it.
Future<String> readCredentialAndClose(WidgetTester tester) async {
  final field = find.descendant(
    of: find.byKey(const Key('credential-password')),
    matching: find.byType(SelectableText),
  );
  await waitFor(tester, field);
  final password = tester.widget<SelectableText>(field).data!;
  await tester.tap(find.byKey(const Key('credential-close')));
  await tester.pump(const Duration(milliseconds: 500));
  return password;
}

/// The student home explains notifications once before Android asks for the
/// permission. Declines it when it shows; does nothing when it does not
/// (permission already decided on this device).
Future<void> dismissNotificationPrompt(WidgetTester tester) async {
  final later = find.byKey(const Key('notification-later'));
  final end = DateTime.now().add(const Duration(seconds: 6));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (later.evaluate().isNotEmpty) {
      await tester.tap(later);
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
}
