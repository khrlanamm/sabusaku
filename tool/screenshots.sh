#!/usr/bin/env bash
# Takes the user guide and Play Store screenshots on a device, against
# PRODUCTION, signed in as real accounts (integration_test/screenshots_test.dart).
#
#   SHOT_STUDENT=<siswa email> SHOT_TEACHER=<guru email> \
#     tool/screenshots.sh <siswa-start|guru|siswa> [device-id] [out-dir]
#
# Run the phases in that order the first time: siswa-start makes the student
# start a catalog book and write today's journal, guru comments on it.
# Each run mints a one-hour custom token with the Admin SDK (secret/), so no
# password or Google account is needed on the device. The token only lives in
# this shell and the debug build on the device; never write it down.
set -euo pipefail
cd "$(dirname "$0")/.."

PHASE="${1:?phase: siswa-start, guru or siswa}"
DEVICE="${2:-emulator-5554}"
OUT="${3:-build/screenshots/phone}"
: "${SHOT_STUDENT:?set SHOT_STUDENT to the student account email}"
: "${SHOT_TEACHER:?set SHOT_TEACHER to the teacher account email}"

case "$PHASE" in
  guru) EMAIL="$SHOT_TEACHER" ;;
  *) EMAIL="$SHOT_STUDENT" ;;
esac

TOKEN="$(cd functions && npx tsx tools/custom-token.ts --email "$EMAIL")"

SHOT_DIR="$OUT" flutter drive \
  --driver=test_driver/screenshots.dart \
  --target=integration_test/screenshots_test.dart \
  -d "$DEVICE" \
  --dart-define=SHOT_PHASE="$PHASE" \
  --dart-define=SHOT_TOKEN="$TOKEN" \
  --dart-define=SHOT_STUDENT="$SHOT_STUDENT"
