# Estado verificable de las fases 3 y 4

Fecha de corte: 27 de julio de 2026.

Este documento distingue entre funcionalidad implementada, validación
automatizada, compilación nativa y validación pendiente en dispositivos reales.
Una función no se considera lista para producción sólo porque el código compile.

## Resumen ejecutivo

| Área | Estado | Evidencia |
|---|---|---|
| Fase 3, núcleo funcional | Implementado | Análisis limpio, pruebas de operaciones atómicas, respaldo y recuperación |
| Fase 3, publicación | Pendiente | Falta firma release y recuperación de respaldo accesible desde el bloqueo |
| Fase 4, protocolo E2EE | Implementado | Pruebas de criptografía, manifiestos, conflictos, grants y revocación |
| Fase 4, WebDAV y servidor propio | Implementado en código | Servidor y transporte pasan pruebas; falta prueba E2E con TLS real |
| Fase 4, aplicación móvil | Compila como debug | APK generado correctamente |
| Fase 4, companion Windows | Código validado, build bloqueado | Falta C++ ATL en Visual Studio Build Tools |
| Instalación en teléfono | Completada | APK actualizado por ADB conservando los datos existentes |

Conclusión: la Fase 3 tiene su núcleo implementado, pero aún no debe publicarse
como release. La Fase 4 está avanzada y su núcleo criptográfico funciona en
pruebas, pero no está cerrada como producto multidispositivo.

## Validación ejecutada

### Aplicación móvil

```text
flutter analyze
No issues found

flutter test --reporter=expanded
58 pruebas superadas

flutter build apk --debug
Compilación correcta
```

Artefacto:

```text
apps/mobile_flutter/build/app/outputs/flutter-apk/app-debug.apk
Tamaño: 220141693 bytes
SHA-256: 77480E31925205B8A34424C9A30E8845E1D389B5A2DA2EC431D74CDD8D9AA86F
```

### Servidor autohospedado

```text
dart analyze
No issues found

dart test --reporter=expanded
5 pruebas superadas

dart compile exe bin/server.dart
Compilación correcta
```

Artefacto:

```text
services/self_hosted_dav/build/private_sandbox_dav.exe
Tamaño: 7119872 bytes
SHA-256: BD568F47CAF91C5DBCB9C71B4D157315D29E81F39CF1445A83086E25AB02CC95
```

### Companion de escritorio

```text
flutter analyze
No issues found

flutter test --reporter=expanded
8 pruebas superadas

flutter build windows --release
Bloqueado: atlstr.h no está instalado
```

La compilación Windows requiere instalar `C++ ATL for latest v143 build tools`
desde Visual Studio Installer. No se sustituyó el almacén seguro de Windows por
archivos en texto plano para evitar esta dependencia.

En total se ejecutaron 71 pruebas automatizadas sin fallos.

## Fase 3 implementada

- Carpetas y subcarpetas virtuales.
- Etiquetas, colecciones y álbumes inteligentes.
- Papelera, restauración y eliminación definitiva.
- Exportación controlada y restauración a la ubicación original cuando Android
  conserva el permiso.
- Conservación de bytes, fechas y metadatos originales disponibles.
- Hash SHA-256 e integridad durante importación y restauración.
- Estados durables `importing`, `verified` y `completed`.
- Publicación atómica de archivos y limpieza de parciales.
- Recuperación de importaciones y swaps de respaldo interrumpidos.
- Copia completa PSVB2 cifrada y autenticada, incluida la base de datos.
- Validación estricta de manifiestos, tamaños, rutas y referencias DB/blob.
- PIN con backoff persistente, biometría y bloqueo automático configurable.
- Protección contra capturas y ocultamiento en aplicaciones recientes.
- Auditoría local de eventos de seguridad y gestión de almacenamiento.
- Esquema Drift con migraciones hasta la versión 10.
- Android Auto Backup desactivado para evitar restaurar datos sin sus claves.

## Fase 4 implementada

- Identidad Ed25519/X25519 independiente por dispositivo.
- Manifiesto y metadatos cifrados con AES-256-GCM y claves derivadas por HKDF.
- Grants cifrados y firmados para autorizar nuevos dispositivos.
- Checkpoint de confianza que impide que un dispositivo revocado reutilice una
  clave maestra antigua para reingresar.
- Revocación, bloqueo remoto y cierre remoto mediante directivas firmadas.
- WebDAV HTTPS con `ETag`, `If-Match`, `If-None-Match`, `PROPFIND` y rangos.
- Transferencias por chunks reanudables con SHA-256 por bloque y final.
- Resolución de concurrencia mediante vectores de versión y copias de conflicto.
- Historial de versiones en el manifiesto.
- Sincronización selectiva, modo local/sincronizado, límites de ancho de banda y
  descarga eager/on-demand en el núcleo.
- Trabajo periódico en segundo plano mediante WorkManager.
- Paquetes cifrados PSHARE1 y enlaces temporales con la capacidad en el
  fragmento de URL, fuera del servidor.
- Servidor autohospedado que sólo almacena ciphertext.
- Companion Flutter para Windows con catálogo, pairing y descargas cifradas.

## Pendientes críticos

### P0 — antes de publicar

1. **Recuperación desde el bloqueo.** El respaldo completo puede restaurar la
   clave maestra, DB y blobs, pero `PinUnlockScreen` sólo muestra el error cuando
   falta la clave. Debe ofrecer un flujo de recuperación PSVB2 antes de
   desbloquear.
2. **Borrado remoto real.** La directiva firmada existe y exige confirmación
   local, pero actualmente sólo se acusa recibo. Debe invalidar primero la clave
   maestra y completar la limpieza mediante un journal recuperable.
3. **Firma Android release.** `build.gradle.kts` todavía firma `release` con la
   clave de debug. Hay que configurar un keystore de producción fuera del
   repositorio y verificar APK/AAB firmado.
4. **Prueba integral con datos reales.** Ejecutar en al menos dos dispositivos:
   alta, importación, sync, conflicto, descarga, revocación, cierre, pérdida de
   red, reinicio y recuperación.
5. **WebDAV con TLS real.** Las pruebas actuales usan transporte controlado. Se
   debe validar contra el servidor autohospedado detrás de un certificado
   confiable y contra al menos un proveedor WebDAV externo.

### P1 — para cerrar completamente la Fase 4

1. Exponer en el móvil un catálogo remoto con selección explícita de versiones
   y descarga bajo demanda. El motor ya ofrece `loadManifest` y
   `downloadVersion`, pero falta esa pantalla.
2. Implementar transferencia directa peer-to-peer. El paquete cifrado sirve
   para transferencia manual, pero no existe transporte LAN/P2P.
3. Instalar ATL y obtener una compilación Windows release reproducible.
4. Validar restauración completa de una bóveda en un teléfono limpio.
5. Añadir pruebas de integración servidor–móvil–desktop y pruebas de procesos
   terminados durante upload, download, restore y revocación.

### Mantenimiento técnico

- Retirar la dependencia directa `sqlite3_flutter_libs`, marcada EOL; Drift ya
  usa `sqlite3` 3.x con native assets.
- Vigilar la migración a Built-in Kotlin de `file_picker`, `photo_manager` y
  `workmanager_android`; Flutter avisó que versiones futuras serán más
  estrictas.
- Sustituir el README inicial de Flutter por documentación operativa y agregar
  CI para análisis, pruebas y builds.
- Definir política de rotación de credenciales, certificados TLS y retención de
  versiones remotas.

## Instalación Android

Tras reactivar la depuración inalámbrica, la conexión e instalación se
completaron correctamente:

```text
adb connect 192.168.1.96:33231
connected to 192.168.1.96:33231

adb -s 192.168.1.96:33231 install -r app-debug.apk
Performing Streamed Install
Success
```

Se utilizó `-r`, por lo que no se desinstaló la aplicación ni se eliminaron los
datos existentes. Android confirmó:

```text
package: com.privatesandbox.mobile_flutter
versionName: 1.0.0
versionCode: 1
lastUpdateTime: 2026-07-27 00:48:36
```

La actividad principal inició con estado `ok` y el proceso permaneció activo
después del arranque. Para futuras actualizaciones:

```powershell
adb connect DIRECCION_IP_Y_PUERTO
adb -s DIRECCION_IP_Y_PUERTO install -r `
  apps/mobile_flutter/build/app/outputs/flutter-apk/app-debug.apk
```

Android puede cambiar el puerto de depuración inalámbrica al desactivar y volver
a activar la función.
