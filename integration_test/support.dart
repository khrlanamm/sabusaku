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
const e2eInitialPassword = 'awal1234';
const e2eNewPassword = 'baru12345';

/// Starts the real app against the Firebase Emulator Suite, signed out.
Future<void> startApp(WidgetTester tester) async {
  assert(
    useEmulators,
    'Run with --dart-define=USE_EMULATORS=true so tests never touch production',
  );
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

/// Scrolls [finder] into view first: the on-screen keyboard can cover it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
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
