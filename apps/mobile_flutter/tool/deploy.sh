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

PHONE_DIR="$(dirname "$PHONE_DEST")"
PHONE_BACKUP_DIR="$PHONE_DIR/respaldo"
# Git Bash reescribe rutas tipo /sdcard/... como rutas de Windows antes de
# pasarlas a adb.exe; MSYS_NO_PATHCONV=1 evita esa conversion. La carpeta
# ademas lleva un apostrofo en el nombre ("APK'S"), asi que cada orden de
# shell va como una sola cadena con la ruta entre comillas dobles y se
# ejecuta con sh -c del lado del telefono -- pasarla como argumentos
# separados hace que el apostrofo abra una comilla que nunca cierra.
export MSYS_NO_PATHCONV=1
if "$ADB" -s "$DEVICE" shell "test -f \"$PHONE_DEST\""; then
  BACKUP_NAME="$(basename "$PHONE_DEST" .apk)-$(date +%Y%m%d-%H%M%S).apk"
  echo "==> Respaldando la APK anterior del teléfono: $BACKUP_NAME"
  "$ADB" -s "$DEVICE" shell "mkdir -p \"$PHONE_BACKUP_DIR\""
  "$ADB" -s "$DEVICE" shell "mv \"$PHONE_DEST\" \"$PHONE_BACKUP_DIR/$BACKUP_NAME\""
fi

echo "==> adb push -> $PHONE_DEST"
"$ADB" -s "$DEVICE" shell "mkdir -p \"$PHONE_DIR\""
"$ADB" -s "$DEVICE" push "$APK" "$PHONE_DEST"

echo "==> done"
