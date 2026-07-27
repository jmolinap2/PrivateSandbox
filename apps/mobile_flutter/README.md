# Private Sandbox móvil

Aplicación Flutter para Android que mantiene archivos privados cifrados dentro
del sandbox de la aplicación. Incluye organización, reproducción, respaldo
local cifrado y un núcleo de sincronización E2EE compatible con WebDAV.

## Desarrollo

Requiere Flutter 3.44 o posterior, Dart 3.12, Android SDK y JDK 17.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

El APK de depuración se genera en:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

No se debe publicar el build `release` hasta configurar un keystore de
producción. La clave maestra de la bóveda vive en el almacenamiento seguro del
sistema y nunca debe incluirse en logs, backups automáticos de Android ni
archivos de configuración.

## Sincronización

La aplicación acepta endpoints WebDAV HTTPS. El servidor sólo recibe
manifiestos y blobs cifrados; la clave maestra no se envía. El servidor de
referencia está en `../../services/self_hosted_dav`.

El companion Windows está en `../desktop_companion_flutter`.

## Estado y pendientes

La matriz de funcionalidades, resultados de análisis/pruebas/builds y
pendientes de publicación se mantiene en
[`../../ESTADO_FASES_3_4.md`](../../ESTADO_FASES_3_4.md).
