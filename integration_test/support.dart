import 'dart:convert';
import 'dart:io';

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
const e2eClass = 'XII-A1';
const e2eTeacherEmail = 'guru@e2e.test';
const e2eTeacherName = 'Sari Wulandari';
const e2eStudentEmail = 'siswa@e2e.test';
const e2eStudentName = 'Raka Pratama';
const e2eNewStudentEmail = 'baru@e2e.test';
const e2eGoogleEmail = 'google@e2e.test';
const e2eGoogleName = 'Gita Lestari';
const e2eRegisterEmail = 'daftar@e2e.test';
const e2eRegisterName = 'Dewi Anggraini';
const e2eOutsiderEmail = 'luar@e2e.test';

/// The Auth emulator accepts an unsigned JSON ID token for Google.
const e2eGoogleIdToken =
    '{"sub":"google-e2e","email":"google@e2e.test","email_verified":true}';

/// Sign-in secrets of the run. tool/e2e.sh generates them and passes the
/// initial one to the seed script as well, so none is written in the repo.
const e2eInitialPassword = String.fromEnvironment('E2E_INITIAL');
const e2eNewPassword = String.fromEnvironment('E2E_NEW');
const e2eBook = 'Laskar Pelangi';
const e2eNewBook = 'Ronggeng Dukuh Paruk';
const e2eCommentText = 'Ringkasanmu jelas, lanjutkan membaca ya.';
const e2eJournalText =
    'Ikal mulai menyadari bahwa pendidikan adalah jalan mengubah hidupnya.';

/// Where the device reaches the emulators (see lib/bootstrap.dart).
const _emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

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
  // What the screen showed instead, to make the failure readable.
  final texts = find
      .byType(RichText)
      .evaluate()
      .map((element) => (element.widget as RichText).text.toPlainText())
      .where((text) => text.trim().length > 1)
      .toSet()
      .join(' | ');
  fail('Timed out waiting for $finder. On screen: $texts');
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
  // A lazy list builds only what is on screen: scroll until it exists.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
}

Future<void> signIn(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await waitFor(tester, find.byKey(const Key('login-submit')));
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tapVisible(tester, find.byKey(const Key('login-submit')));
}

/// Signs in the Google-only account directly: the Google account picker is
/// a system screen the test cannot drive.
Future<void> signInWithFakeGoogle() =>
    FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: e2eGoogleIdToken),
    );

Future<void> signOut(WidgetTester tester) async {
  await FirebaseAuth.instance.signOut();
  await waitFor(tester, find.byKey(const Key('login-submit')));
}

/// Fills both fields of a new password and its confirmation.
Future<void> enterNewPassword(WidgetTester tester, String password) async {
  await tester.enterText(find.byKey(const Key('password-new')), password);
  await tester.enterText(find.byKey(const Key('password-confirm')), password);
}

/// Picks [label] in the class dropdown.
Future<void> pickClass(WidgetTester tester, String label) async {
  await tapVisible(tester, find.byKey(const Key('field-class')));
  await waitFor(tester, find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Opens the verification link the Auth emulator "sent" to [email], as the
/// student would from their inbox.
Future<void> verifyEmailOnEmulator(String email) async {
  final client = HttpClient();
  try {
    final codes = await _getJson(
      client,
      Uri.parse(
        'http://$_emulatorHost:9099/emulator/v1/projects/sabusaku/oobCodes',
      ),
    );
    final link =
        (codes['oobCodes'] as List).cast<Map<String, dynamic>>().lastWhere(
              (code) =>
                  code['email'] == email &&
                  code['requestType'] == 'VERIFY_EMAIL',
            )['oobLink']
            as String;
    // The link points at localhost; the device reaches the host elsewhere.
    final uri = Uri.parse(link).replace(host: _emulatorHost);
    final request = await client.getUrl(uri);
    final response = await request.close();
    await response.drain<void>();
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _getJson(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
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
