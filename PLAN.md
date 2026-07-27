# Plan de desarrollo — Sandbox privado multimedia

## Visión general

El producto está centrado en un **sandbox privado y cifrado para archivos**, no en VLC.

El reproductor multimedia es un componente interno y reemplazable. El valor principal de la aplicación es permitir que el usuario pueda:

- Importar archivos privados.
- Ocultarlos de galerías, reproductores y exploradores externos.
- Consultarlos únicamente dentro de la aplicación.
- Reproducir fotos, videos, audio y documentos.
- Exportarlos posteriormente.
- Conservar el archivo original y la mayor cantidad posible de metadatos.
- Trabajar sin root.
- Mantener los archivos cifrados mientras estén dentro de la bóveda.

El desarrollo se divide en cinco fases. Las fases 1, 2 y 3 deben ser completamente funcionales y publicables por sí solas.

---

# Fase 1 — Bóveda privada funcional

## Objetivo

Entregar una aplicación útil y publicable como bóveda cifrada para Android.

## Funcionalidades

- Aplicación desarrollada en Flutter.
- Acceso mediante PIN.
- Autenticación biométrica.
- Importación de:
  - Imágenes.
  - Videos.
  - Audio.
  - PDF.
  - Archivos genéricos.
- Cifrado por streaming para evitar cargar archivos completos en memoria.
- Almacenamiento en el espacio privado de la aplicación.
- Eliminación opcional del archivo original después de verificar la importación.
- Galería privada básica.
- Reproductor básico de video.
- Reproductor básico de audio.
- Visor de imágenes.
- Visor de PDF.
- Exportación y restauración de archivos.
- Conservación de los bytes originales del archivo.
- Registro de:
  - Nombre original.
  - Extensión.
  - Tipo MIME.
  - Tamaño.
  - Ruta original.
  - Fecha de importación.
  - Fechas disponibles del archivo.
- Verificación de integridad durante la importación.
- Manejo de errores básicos.
- Recuperación ante cierres inesperados durante una importación.

## Consideraciones técnicas

- Los archivos deben cifrarse sin modificar el contenido original.
- El archivo cifrado debe almacenarse únicamente dentro del espacio privado de la aplicación.
- Las claves no deben almacenarse directamente en SQLite.
- Las claves deben protegerse mediante Android Keystore.
- La importación debe considerarse completada solo cuando:
  1. El archivo haya sido copiado.
  2. El archivo haya sido cifrado.
  3. El hash haya sido verificado.
  4. La información haya sido registrada en la base de datos.

## Producto independiente

Una bóveda privada y cifrada para archivos.

## Criterio de finalización

El usuario puede:

1. Importar un archivo.
2. Ocultarlo de las aplicaciones externas.
3. Abrirlo dentro de la bóveda.
4. Exportarlo nuevamente.
5. Recuperar el contenido sin pérdida.

---

# Fase 2 — Centro multimedia privado

## Objetivo

Convertir la bóveda en una aplicación multimedia completa.

## Funcionalidades

- Interfaz moderna desarrollada completamente en Flutter.
- Experiencia de navegación inspirada en reproductores multimedia consolidados.
- Biblioteca separada por:
  - Videos.
  - Música.
  - Imágenes.
  - Documentos.
- Reproductor avanzado de video.
- Reproductor avanzado de audio.
- Reanudación desde la última posición.
- Velocidad de reproducción.
- Gestos para:
  - Volumen.
  - Brillo.
  - Avance.
  - Retroceso.
- Listas de reproducción.
- Álbumes.
- Favoritos.
- Historial de reproducción.
- Miniaturas privadas.
- Caché privada.
- Búsqueda.
- Filtros.
- Ordenamiento.
- Importación múltiple.
- Importación en segundo plano.
- Indicadores de progreso.
- Cancelación de importaciones.
- Organización por tipo de archivo.

## Consideraciones técnicas

- El motor multimedia debe estar abstraído detrás de una interfaz.
- La aplicación no debe depender directamente de un único motor.
- Posibles motores:
  - libVLC.
  - Android Media3.
  - ExoPlayer.
  - mpv.
- Las miniaturas no deben almacenarse en ubicaciones públicas.
- Los archivos cifrados no deben descifrarse completamente en disco para reproducirse.
- Cuando sea posible, deben reproducirse mediante streams temporales o archivos temporales controlados.

## Producto independiente

Un reproductor multimedia privado con bóveda integrada.

## Criterio de finalización

El usuario puede reemplazar:

- Una galería privada.
- Un reproductor de video.
- Un reproductor de música.
- Un visor básico de documentos.

Todo desde una sola aplicación.

---

# Fase 3 — Gestor seguro de archivos

## Objetivo

Convertir la aplicación en un espacio privado completo para administrar archivos.

## Funcionalidades

- Carpetas virtuales.
- Subcarpetas virtuales.
- Etiquetas.
- Colecciones.
- Álbumes inteligentes.
- Papelera privada.
- Restauración de archivos eliminados.
- Eliminación definitiva.
- Exportación a:
  - Ruta original.
  - Carpeta seleccionada.
  - Compartición controlada.
- Conservación de metadatos internos.
- Conservación de EXIF cuando el formato lo permita.
- Registro de metadatos que Android no permita restaurar.
- Verificación de integridad mediante hash.
- Recuperación ante importaciones interrumpidas.
- Recuperación ante exportaciones interrumpidas.
- Copias de seguridad cifradas locales.
- Importación de una bóveda completa.
- Exportación de una bóveda completa.
- Bloqueo automático.
- Protección contra capturas de pantalla.
- Ocultamiento del contenido en aplicaciones recientes.
- Registro local de actividad de seguridad.
- Auditoría local de:
  - Importaciones.
  - Exportaciones.
  - Eliminaciones.
  - Intentos fallidos de acceso.
- Múltiples métodos de desbloqueo.
- Configuración de tiempo de bloqueo automático.
- Gestión de almacenamiento.
- Detección de archivos duplicados.
- Indicadores de uso de espacio.
- Limpieza segura de caché.
- Migraciones compatibles entre versiones.

## Consideraciones técnicas

- La estructura de carpetas puede ser virtual y persistirse en SQLite.
- Los archivos físicos no necesitan replicar exactamente la estructura visual.
- Cada archivo debe tener:
  - Identificador único.
  - Hash.
  - Ruta física privada.
  - Ruta lógica.
  - Estado.
  - Metadatos.
  - Información de cifrado.
- Las operaciones críticas deben implementarse mediante transacciones.
- Los procesos largos deben ejecutarse como tareas controladas.
- Debe existir un sistema de estados para evitar archivos huérfanos.

## Producto independiente

Un gestor privado y cifrado de archivos con capacidades multimedia.

## Criterio de finalización

El usuario puede administrar toda su información privada sin depender de:

- Galería externa.
- Reproductor externo.
- Explorador de archivos externo.
- Aplicación externa para documentos comunes.

---

# Fase 4 — Sincronización y múltiples dispositivos

## Objetivo

Ampliar el producto a varios dispositivos sin comprometer el cifrado.

## Funcionalidades

- Sincronización cifrada de extremo a extremo.
- Copias de seguridad remotas.
- Compatibilidad con:
  - Servidor propio.
  - WebDAV.
  - Proveedores de almacenamiento compatibles.
- Aplicación complementaria para escritorio.
- Transferencia directa entre dispositivos.
- Historial de versiones.
- Resolución de conflictos.
- Recuperación mediante clave maestra.
- Compartición temporal mediante paquetes cifrados.
- Enlaces temporales protegidos.
- Importación remota.
- Exportación remota.
- Sincronización selectiva.
- Descarga bajo demanda.
- Carga en segundo plano.
- Reanudación de transferencias.
- Control de ancho de banda.
- Registro de dispositivos autorizados.
- Revocación de dispositivos.
- Cierre remoto de sesión.
- Borrado remoto de datos locales, cuando sea posible.
- Modo solo local.
- Modo sincronizado.

## Consideraciones técnicas

- El servidor nunca debe recibir archivos descifrados.
- La clave maestra no debe enviarse al servidor.
- Cada dispositivo debe poseer su propia identidad criptográfica.
- La sincronización debe operar sobre bloques o archivos cifrados.
- Los conflictos deben resolverse sin sobreescribir contenido silenciosamente.
- Esta fase depende de la estabilidad de las fases 1, 2 y 3.

## Resultado

El usuario puede acceder a su bóveda desde varios dispositivos manteniendo cifrado de extremo a extremo.

---

# Fase 5 — Plataforma privada avanzada

## Objetivo

Diferenciar el producto más allá de una bóveda convencional.

**Sin inteligencia artificial.** Toda la funcionalidad de esta fase debe ser
determinista y explicable: reglas definidas por el usuario, metadatos,
hashes y extracción directa de texto. No se incorporan modelos de
aprendizaje automático de ningún tipo, ni locales ni remotos.

## Funcionalidades

- Indexación de documentos mediante extracción directa de texto (PDF con capa de texto, TXT, y formatos similares).
- Búsqueda por contenido sobre el texto extraído y los metadatos registrados.
- Clasificación automática de archivos por reglas deterministas: tipo MIME, extensión, tamaño, fechas y carpeta de origen.
- Detección de duplicados exactos por hash.
- Agrupación automática por criterios explícitos: fecha, carpeta de origen, tipo o etiqueta.
- Reglas de organización definidas por el usuario.
- Etiquetado automático derivado de esas mismas reglas.
- Archivos sensibles con protección adicional.
- Múltiples bóvedas.
- Claves independientes por bóveda.
- Perfil señuelo.
- Contenido alternativo.
- Código de emergencia.
- Bloqueo reforzado.
- Notas privadas.
- Gestión de documentos de identidad.
- Gestión de tarjetas.
- Gestión de archivos comprimidos.
- Integración controlada con aplicaciones externas.
- Sistema modular para agregar:
  - Nuevos visores.
  - Nuevos reproductores.
  - Procesadores de archivos.
  - Indexadores.
  - Motores de reglas.
- Automatizaciones locales.
- Procesamiento sin conexión.

## Consideraciones técnicas

- Ninguna funcionalidad puede depender de modelos de aprendizaje automático, ni ejecutados en el dispositivo ni en un servicio externo.
- Toda clasificación, agrupación o etiquetado debe ser reproducible: las mismas entradas y reglas producen siempre el mismo resultado, y el usuario puede consultar por qué se aplicó cada regla.
- La extracción de texto se limita a formatos que ya lo contienen; no se infiere texto de imágenes.
- Los índices generados también deben permanecer cifrados.
- La función de perfil señuelo debe diseñarse con cuidado para no comprometer la bóveda principal.

## Resultado

La aplicación se convierte en una plataforma privada para administrar, consultar, reproducir y organizar información sensible.

---

# Arquitectura general propuesta

```text
PrivateSandbox
│
├── apps/
│   ├── mobile_flutter/
│   └── desktop_flutter/
│
├── packages/
│   ├── presentation/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── animations/
│   │   ├── theme/
│   │   └── navigation/
│   │
│   ├── application/
│   │   ├── vault/
│   │   ├── import/
│   │   ├── export/
│   │   ├── playback/
│   │   ├── search/
│   │   ├── backup/
│   │   └── synchronization/
│   │
│   ├── domain/
│   │   ├── vault/
│   │   ├── media/
│   │   ├── files/
│   │   ├── metadata/
│   │   ├── collections/
│   │   ├── security/
│   │   └── synchronization/
│   │
│   ├── infrastructure/
│   │   ├── database/
│   │   ├── encryption/
│   │   ├── storage/
│   │   ├── metadata/
│   │   ├── thumbnails/
│   │   ├── backup/
│   │   └── synchronization/
│   │
│   ├── media_engine/
│   │   ├── abstractions/
│   │   ├── libvlc/
│   │   └── media3/
│   │
│   └── shared/
│       ├── errors/
│       ├── logging/
│       ├── permissions/
│       ├── result/
│       └── utilities/
│
└── native/
    ├── android/
    │   ├── keystore/
    │   ├── biometric/
    │   ├── media_store/
    │   ├── background_tasks/
    │   └── platform_api/
    │
    └── desktop/
```

---

# Capas

```text
Presentation
     │
Application
     │
Domain
     │
Infrastructure
     │
Native / Media Engine
```

## Presentation

Responsable de:

- Pantallas.
- Navegación.
- Widgets.
- Animaciones.
- Temas.
- Interacción del usuario.

## Application

Responsable de:

- Casos de uso.
- Coordinación de procesos.
- Importaciones.
- Exportaciones.
- Reproducción.
- Copias de seguridad.
- Sincronización.
- Validaciones de flujo.

## Domain

Responsable de:

- Reglas del negocio.
- Entidades.
- Agregados.
- Interfaces.
- Estados.
- Restricciones.
- Invariantes.

## Infrastructure

Responsable de:

- SQLite.
- Sistema de archivos.
- Cifrado.
- Lectura de metadatos.
- Miniaturas.
- Android Keystore.
- Servicios del sistema operativo.

## Native / Media Engine

Responsable de:

- Integraciones específicas de Android.
- Reproducción multimedia.
- Biometría.
- Scoped Storage.
- MediaStore.
- Servicios en segundo plano.
- Operaciones que Flutter no resuelva directamente.

---

# Tecnologías recomendadas

## Aplicación

- Flutter.
- Dart.
- Riverpod.
- GoRouter.

## Base de datos

- SQLite.
- Drift.

## Seguridad

- Android Keystore.
- BiometricPrompt.
- AES-256-GCM.
- HKDF para derivación de claves.
- SHA-256 o BLAKE3 para integridad.

## Multimedia

- libVLC o Android Media3.
- Abstracción propia para evitar acoplamiento.

## Procesamiento

- Isolates de Dart.
- WorkManager para tareas persistentes.
- Platform Channels o FFI para integraciones nativas.

## Metadatos

- EXIF.
- MediaMetadataRetriever.
- Bibliotecas específicas según el formato.
- Persistencia de metadatos complementarios en SQLite.

---

# Principios técnicos

1. El sandbox es el núcleo del producto.
2. El reproductor debe ser reemplazable.
3. Los archivos nunca deben almacenarse descifrados de forma permanente.
4. Las claves no deben guardarse directamente en la base de datos.
5. Toda importación debe verificarse antes de eliminar el original.
6. Toda operación crítica debe ser recuperable.
7. Las miniaturas deben permanecer dentro del entorno privado.
8. La base de datos debe diseñarse con migraciones desde la primera versión.
9. Los procesos pesados deben ejecutarse fuera del hilo principal.
10. La interfaz debe depender de casos de uso, no de implementaciones concretas.
11. Los motores externos deben encapsularse detrás de interfaces.
12. La aplicación debe funcionar sin root.
13. Debe respetarse Scoped Storage.
14. Las fases 1, 2 y 3 deben ser publicables por separado.
15. Las nuevas fases no deben obligar al usuario a volver a importar su bóveda.
16. La aplicación no incorpora inteligencia artificial ni modelos de aprendizaje automático en ninguna fase. Toda automatización es determinista y basada en reglas.

---

# Orden recomendado

```text
Fase 1
Bóveda privada funcional
        ↓
Fase 2
Centro multimedia privado
        ↓
Fase 3
Gestor seguro de archivos
        ↓
Fase 4
Sincronización y múltiples dispositivos
        ↓
Fase 5
Plataforma privada avanzada
```

---

# Resumen de productos funcionales

## Producto 1

Bóveda privada cifrada.

## Producto 2

Reproductor multimedia privado con bóveda.

## Producto 3

Gestor seguro de archivos con reproducción multimedia.

## Producto 4

Bóveda sincronizada entre dispositivos.

## Producto 5

Plataforma privada avanzada para archivos y contenido multimedia.
