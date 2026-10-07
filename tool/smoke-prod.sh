#!/usr/bin/env bash
# Read-only smoke test of the PRODUCTION backend with the demo school.
#
#   tool/smoke-prod.sh [device-id]        default device: emulator-5554
#
# Signs in as a demo student, teacher and admin and walks the main screens.
# Needs the demo school (functions/tools/seed-demo.ts) and its credentials in
# secret/demo-credentials.csv.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-emulator-5554}"
CREDENTIALS="secret/demo-credentials.csv"
[ -f "$CREDENTIALS" ] || { echo "Tidak ada $CREDENTIALS. Jalankan seed-demo dulu." >&2; exit 1; }

# All demo accounts share one password (column 4).
PASSWORD="$(awk -F, 'NR==2 {print $4}' "$CREDENTIALS")"
command -v adb >/dev/null 2>&1 || export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

flutter test integration_test/prod_smoke_test.dart -d "$DEVICE" \
  --dart-define=DEMO_PASSWORD="$PASSWORD" --reporter expanded
