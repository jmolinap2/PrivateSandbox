#!/usr/bin/env bash
# Builds a debug APK, installs it on the phone over wireless adb, and pushes
# a renamed copy to the phone's shared APK folder — the three steps that
# otherwise take several separate tool calls every checkpoint.
#
# Usage: tool/deploy.sh [ip:port]
# Sin argumento detecta el telefono (device=duchamp) por `adb devices -l` y,
# si no aparece, por mDNS; el puerto inalambrico cambia, asi que no se guarda.
# Se puede forzar un ip:port como argumento.
#
# Run `flutter analyze` separately before this — it's not included here on
# purpose, its output needs to actually be read, not just piped through.
set -euo pipefail

cd "$(dirname "$0")/.."

ADB="/c/Android/Sdk/platform-tools/adb.exe"
EXPECTED_DEVICE="duchamp"

# Imprime el serial de un dispositivo conectado cuyo device sea $EXPECTED_DEVICE.
find_connected() {
  "$ADB" devices -l | tr -d '\r' |
    awk -v d="device:$EXPECTED_DEVICE" '$2 == "device" && index($0, d) { print $1; exit }'
}

detect_device() {
  local serial candidate
  serial="$(find_connected)"
  if [ -n "$serial" ]; then echo "$serial"; return 0; fi
  # No aparece: conectar candidatos mDNS y volver a buscar por identidad.
  for candidate in $("$ADB" mdns services | tr -d '\r' |
      awk '/_adb-tls-connect._tcp/ { print $NF }'); do
    "$ADB" connect "$candidate" >/dev/null 2>&1 || true
  done
  find_connected
}

if [ -n "${1:-}" ]; then
  DEVICE="$1"
  "$ADB" connect "$DEVICE" >/dev/null 2>&1 || true
else
  DEVICE="$(detect_device)"
  if [ -z "$DEVICE" ]; then
    echo "ERROR: no se encontro el telefono ($EXPECTED_DEVICE) por adb ni mDNS." >&2
    echo "Revisa la depuracion inalambrica / el emparejamiento." >&2
    exit 2
  fi
fi
echo "==> dispositivo: $DEVICE"
FLUTTER="$USERPROFILE/flutter/bin/flutter"
APK="build/app/outputs/flutter-apk/app-debug.apk"
PHONE_DEST="/sdcard/APK'S - DESARROLLOS/PrivateSandbox-1.0.0+1-debug.apk"

echo "==> flutter build apk --debug"
"$FLUTTER" build apk --debug --build-number="$(git rev-list --count HEAD)"

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
