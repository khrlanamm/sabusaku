import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/firebase/firebase_providers.dart';
import 'core/storage/prefs.dart';
import 'firebase_options.dart';

/// `--dart-define=USE_EMULATORS=true` points the app at the local Firebase
/// Emulator Suite instead of the production project.
const useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// The Android emulator reaches the host machine at 10.0.2.2.
const _emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

const _appCheck = bool.fromEnvironment('APP_CHECK');

bool _firebaseReady = false;

/// Safe to call more than once (integration tests start the app repeatedly).
Future<void> initFirebase() async {
  if (_firebaseReady) return;
  _firebaseReady = true;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
    FirebaseFunctions.instanceFor(region: firebaseRegion)
        .useFunctionsEmulator(_emulatorHost, 5001);
    await FirebaseStorage.instance.useStorageEmulator(_emulatorHost, 9199);
  }

  // App Check proves requests come from this app (docs/03 §4). It is off
  // unless built with `--dart-define=APP_CHECK=true`: until the app is
  // distributed through Google Play and Play Integrity is linked, every token
  // request fails slowly and delays the first sign-in by about 20 seconds.
  if (_appCheck && !useEmulators) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }

  // Crash reports only from release builds against production. Debug and
  // test runs keep Flutter's own error handling, which tests rely on.
  final reportCrashes = !kDebugMode && !useEmulators;
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(reportCrashes);
  if (reportCrashes) {
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  await initializeDateFormatting('id_ID');
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SabuSakuApp(),
    ),
  );
}
