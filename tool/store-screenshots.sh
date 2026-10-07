#!/usr/bin/env bash
# Captures the raw app screens for the Play Store graphics, from PRODUCTION
# with the demo school.
#
#   tool/store-screenshots.sh <phone|tablet> [device-id]
#
# Runs integration_test/store_tour_test.dart and saves one PNG per `SHOT:`
# marker to store/raw/<phone|tablet>/. `tablet` temporarily gives the device a
# 10-inch tablet display (1600x2560 at 320 dpi) and restores it afterwards.
# The status bar is put in Android's demo mode so it shows a clean clock.
set -euo pipefail
cd "$(dirname "$0")/.."

FORM="${1:?phone or tablet}"
DEVICE="${2:-emulator-5554}"
OUT="store/raw/$FORM"
CREDENTIALS="secret/demo-credentials.csv"
[ -f "$CREDENTIALS" ] || { echo "Tidak ada $CREDENTIALS. Jalankan seed-demo dulu." >&2; exit 1; }
shared="$(awk -F, 'NR==2 {print $4}' "$CREDENTIALS")"

command -v adb >/dev/null 2>&1 || export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
adb="adb -s $DEVICE"

restore() {
  $adb shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null 2>&1 || true
  $adb shell wm size reset >/dev/null 2>&1 || true
  $adb shell wm density reset >/dev/null 2>&1 || true
}
trap restore EXIT

if [ "$FORM" = tablet ]; then
  $adb shell wm size 1600x2560
  $adb shell wm density 320
fi

# Clean status bar: 09:41, full signal and battery, no notification icons.
$adb shell settings put global sysui_demo_allowed 1
demo() { $adb shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }
demo -e command enter
demo -e command clock -e hhmm 0941
demo -e command notifications -e visible false
demo -e command battery -e level 100 -e plugged false
demo -e command network -e wifi show -e level 4
demo -e command network -e mobile show -e datatype none -e level 4

rm -rf "$OUT" && mkdir -p "$OUT"

# The test framework captures print() and reports it through `flutter test`,
# so the markers are read from its output rather than from the device log.
flutter test integration_test/store_tour_test.dart -d "$DEVICE" \
  --dart-define=DEMO_PASSWORD="$shared" --reporter expanded 2>&1 |
  while IFS= read -r line; do
    case "$line" in
      *SHOT:*)
        name="${line##*SHOT:}"
        name="${name%%[[:space:]]*}"
        sleep 0.3
        $adb exec-out screencap -p > "$OUT/$name.png"
        echo "captured $name"
        ;;
      *"All tests passed"* | *"Some tests failed"* | *"[E]"*) echo "$line" ;;
    esac
  done

ls -1 "$OUT"
