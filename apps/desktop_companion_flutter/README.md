# Private Sandbox Desktop Companion

Aplicación Flutter de escritorio —con soporte prioritario para Windows— que
accede a una bóveda Private Sandbox sin convertir WebDAV en una parte confiable
del sistema. El servidor recibe únicamente el manifiesto E2EE y blobs ya
cifrados.

## Alcance

- configura un endpoint WebDAV **HTTPS** con autenticación básica, bearer o sin
  autenticación;
- persiste endpoint, credenciales, identidad y enrollment mediante
  `flutter_secure_storage` (Windows Credential Manager en Windows);
- crea o carga una identidad local Ed25519/X25519;
- exporta la parte pública como un `DeviceIdentity` JSON;
- importa y autentica un `DeviceKeyGrant` cifrado para este dispositivo;
- fija fuera de banda la huella del propietario que firma el grant;
- deriva el identificador opaco de bóveda y rechaza grants cuya clave no
  corresponda con ese identificador;
- autentica el manifiesto remoto cifrado, aplica un checkpoint antirrollback y
  muestra objetos, conflictos, versiones y dispositivos;
- descarga blobs cifrados bajo demanda, por chunks reanudables, validando cada
  SHA-256 y el hash final.

La aplicación **no descifra archivos de contenido**, no exporta claves privadas
y no escribe la clave maestra en archivos.

## Core compartido

`pubspec.yaml` declara una dependencia local real:

```yaml
mobile_flutter:
  path: ../mobile_flutter
```

El companion reutiliza las implementaciones de protocolo bajo
`mobile_flutter/lib/{domain,infrastructure}/synchronization`: canonicalización,
Ed25519, X25519, HKDF, AES-256-GCM, manifiestos, WebDAV, ETag CAS y blobs
reanudables. No mantiene un protocolo paralelo.

## Flujo de emparejamiento

1. Configura y prueba el WebDAV HTTPS.
2. Crea la identidad del equipo.
3. Exporta `private-sandbox-device.pspair.json` y entrégalo al dispositivo
   propietario.
4. En el propietario, autoriza esa identidad y genera un grant.
5. Compara por un canal independiente los 64 caracteres de la huella del
   propietario.
6. Importa el grant e ingresa esa huella. Un grant expirado, alterado, destinado
   a otro equipo, firmado por otra identidad o cuyo checkpoint marque este
   equipo como revocado es rechazado.
7. Actualiza el catálogo.

La primera lectura se ancla al checkpoint de confianza firmado incluido en el
grant. Las lecturas posteriores rechazan generaciones antiguas, firmas de
dispositivos no confiables y dos contenidos distintos en una generación ya
observada.

## Requisitos WebDAV

El proveedor debe implementar `HEAD`, `GET`, `PUT`, `DELETE`, `MKCOL` y
`PROPFIND Depth: 1`, devolver ETag para el manifiesto y respetar `If-Match` /
`If-None-Match`. Las redirecciones HTTP no se siguen y HTTP sin TLS solo existe
en los tests del core.

La prueba de conexión crea, si hace falta, la colección `vaults/`.

## Almacenamiento local

- La configuración y el enrollment se guardan como entradas del almacén seguro
  del sistema.
- El enrollment agrupa clave maestra y checkpoint en **una sola escritura**.
- Los blobs cifrados se guardan bajo el directorio de soporte privado de la
  aplicación:
  `PrivateSandbox/EncryptedRemoteCache/<vault-id>/`.
- Una descarga parcial usa el sufijo `.sync.part`; al reanudar se verifican los
  chunks ya escritos antes de continuar.
- Nunca se sobrescribe un blob local no relacionado ni un archivo de solicitud
  de emparejamiento existente.

## Desarrollo

Requiere Flutter 3.44 o posterior, Dart 3.12 y Visual Studio con
“Desktop development with C++” **más C++ ATL** para compilar Windows. ATL es un
requisito nativo de `flutter_secure_storage_windows`.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

El ejecutable y sus DLL se generan en:

```text
build/windows/x64/runner/Release/
```

Debe distribuirse la carpeta completa; el `.exe` no es autónomo.

### Estado de validación en este workspace

- `flutter analyze`: sin issues.
- `flutter test`: 8 pruebas superadas.
- `flutter doctor -v`: Flutter 3.44.4, Dart 3.12.2 y Visual Studio Build Tools
  2022 17.14.35 detectados.
- `flutter build windows --release`: validación de enlace pendiente porque el
  Build Tools instalado no incluye ATL. El compilador termina con
  `C1083: atlstr.h: No such file or directory` al compilar
  `flutter_secure_storage_windows`.

Para cerrar la validación nativa, abre Visual Studio Installer, modifica
“Build Tools 2022”, instala el componente individual **C++ ATL for latest
v143 build tools**, y repite `flutter build windows --release`. No se sustituye
el almacén seguro por archivos en texto plano para sortear esta dependencia.

## Pruebas incluidas

Las pruebas unitarias cubren:

- serialización y verificación de huella de `DeviceIdentity`;
- round-trip de configuración WebDAV guardada en un secret store;
- rechazo explícito de endpoints sin HTTPS;
- serialización atómica del enrollment y checkpoint;
- detección de equivocation en una generación remota observada.

No hay pruebas contra un proveedor WebDAV público: para integración se debe usar
un servidor de prueba con TLS y ETag reales.
