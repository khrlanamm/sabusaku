import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
  }

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(
    !kDebugMode && !useEmulators,
  );
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
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
