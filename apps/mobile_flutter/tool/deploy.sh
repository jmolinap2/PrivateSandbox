#!/usr/bin/env bash
# Builds a debug APK, installs it on the phone over wireless adb, and pushes
# a renamed copy to the phone's shared APK folder — the three steps that
# otherwise take several separate tool calls every checkpoint.
#
# Usage: tool/deploy.sh [ip:port]
# ip:port defaults to the last known wireless-debugging address. Pass a new
# one when it changes (Ajustes > Opciones de desarrollador > Depuración
# inalámbrica > "Dirección IP y puerto" shows the current value).
#
# Run `flutter analyze` separately before this — it's not included here on
# purpose, its output needs to actually be read, not just piped through.
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE="${1:-192.168.1.98:37007}"
ADB="/c/Android/Sdk/platform-tools/adb.exe"
FLUTTER="$USERPROFILE/flutter/bin/flutter"
APK="build/app/outputs/flutter-apk/app-debug.apk"
PHONE_DEST="/sdcard/APK'S - DESARROLLOS/PrivateSandbox-1.0.0+1-debug.apk"

echo "==> flutter build apk --debug"
"$FLUTTER" build apk --debug

echo "==> adb connect $DEVICE"
"$ADB" connect "$DEVICE"

echo "==> adb install -r"
"$ADB" -s "$DEVICE" install -r "$APK"

echo "==> adb push -> $PHONE_DEST"
"$ADB" -s "$DEVICE" push "$APK" "$PHONE_DEST"

echo "==> done"
