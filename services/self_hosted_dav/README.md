# PrivateSandbox self-hosted DAV

Servidor de referencia para la Fase 4. Sólo almacena manifiestos y bloques
cifrados; no conoce la clave maestra ni recibe contenido en claro.

## Ejecución

```powershell
$env:PS_DAV_USERNAME = "vault"
$env:PS_DAV_PASSWORD = "una-contraseña-larga-y-aleatoria"
dart run bin/server.dart --root=D:\PrivateSandbox --port=8443 --cert=chain.pem --key=key.pem --public-shares
```

Configura la app con `https://servidor:8443/dav/`. Si habilitas enlaces
temporales, usa `https://servidor:8443/public/` como base pública. La clave
del enlace permanece en el fragmento `#psk=...`, que no llega al servidor.

TLS es obligatorio. `--allow-http` funciona únicamente al enlazar una
dirección loopback y existe para pruebas automatizadas.

## Operación

- Ejecuta el proceso con un usuario del sistema dedicado.
- Protege `PS_DAV_PASSWORD` mediante el gestor de secretos del servicio.
- Respalda el directorio configurado en `--root`; todo su contenido ya está
  cifrado por el cliente.
- Un proxy inverso puede terminar TLS, pero el proceso debe seguir escuchando
  sólo en loopback en ese caso.
- Los PUT usan swap y recuperación de interrupciones; ETag/If-Match evita que
  dos dispositivos sobrescriban el manifiesto silenciosamente.
- Los enlaces expirados responden `410 Gone` y su ciphertext se elimina de
  forma oportunista. El paquete también valida su expiración autenticada.
