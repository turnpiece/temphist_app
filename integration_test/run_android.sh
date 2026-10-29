#!/usr/bin/env bash
# Runs the integration tests on an Android device/emulator.
#
# `flutter test` reinstalls the app, wiping runtime permissions, and the OS
# location dialog is native so the tests cannot tap it. This grants location
# in the background as soon as the app is installed.
#
# Usage: integration_test/run_android.sh [--deny-location] [device-id] [extra flutter test args]
#
#   (default)         grant location, run integration_test/app_test.dart
#   --deny-location   refuse location up front, run permission_denied_test.dart
set -euo pipefail

TARGET=integration_test/app_test.dart
DENY=0
if [ "${1:-}" = "--deny-location" ]; then
  DENY=1
  TARGET=integration_test/permission_denied_test.dart
  shift
fi

PKG=com.turnpiece.temphist
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
DEVICE="${1:-emulator-5554}"
[ $# -gt 0 ] && shift

cd "$(dirname "$0")/.."

# Keep re-granting for the whole run: `flutter test` uninstalls and reinstalls
# the app, so a grant made before that point is lost. Granting is idempotent
# and fails harmlessly while the package is not installed.
(
  while true; do
    for perm in android.permission.ACCESS_FINE_LOCATION android.permission.ACCESS_COARSE_LOCATION; do
      if [ "$DENY" = 1 ]; then
        # user-fixed + not granted: the app's permission request is refused
        # immediately instead of showing the OS dialog.
        "$ADB" -s "$DEVICE" shell pm revoke "$PKG" "$perm" >/dev/null 2>&1 || true
        "$ADB" -s "$DEVICE" shell pm set-permission-flags "$PKG" "$perm" user-fixed >/dev/null 2>&1 || true
      else
        "$ADB" -s "$DEVICE" shell pm grant "$PKG" "$perm" >/dev/null 2>&1 || true
      fi
    done
    sleep 2
  done
) &
GRANTER=$!
trap 'kill $GRANTER 2>/dev/null || true' EXIT

flutter test "$TARGET" -d "$DEVICE" "$@"
