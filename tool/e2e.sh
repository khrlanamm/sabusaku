#!/usr/bin/env bash
# Runs the Flutter integration tests against the Firebase Emulator Suite.
#
#   tool/e2e.sh [device-id]        default device: emulator-5554
#
# Starts the Auth, Firestore and Functions emulators, resets and seeds them,
# runs integration_test/app_test.dart on the Android device, then stops them.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-emulator-5554}"

# The Firestore emulator needs a JVM. macOS ships a `java` stub that only
# prints an install hint, so test that it runs; Homebrew's JDK is not on PATH.
java -version >/dev/null 2>&1 || export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
command -v adb >/dev/null 2>&1 || export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

(cd functions && npm run build >/dev/null)

firebase emulators:exec --project sabusaku --only auth,firestore,functions \
  "(cd functions && npx tsx tools/seed-e2e.ts --emulator) && flutter test integration_test/app_test.dart -d $DEVICE --dart-define=USE_EMULATORS=true --reporter expanded"
