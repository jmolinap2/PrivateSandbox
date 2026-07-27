# Ciclo de trabajo en este repo

Cada vez que se modifica la app (`apps/mobile_flutter`), seguir este ciclo técnico en orden. No saltarse pasos ni combinarlos para ahorrar tiempo.

1. **Implementar el cambio.**
2. **`flutter analyze`** (desde `apps/mobile_flutter`) — debe quedar limpio. Leer la salida, no asumir que "sin crash" equivale a "sin warnings".
3. **`flutter test`** (desde `apps/mobile_flutter`) — debe pasar.
4. **`tool/deploy.sh [ip:puerto]`** — compila el APK debug, lo instala por adb inalámbrico y empuja una copia renombrada a la carpeta de APKs del celular. Antes de sobrescribir esa copia, si ya existe una en el destino, el script la mueve a una subcarpeta `respaldo/` con timestamp — nunca la borra sin más. El `ip:puerto` de depuración inalámbrica cambia seguido (a veces la IP también); si `adb devices` no muestra el teléfono, pedir el valor actual en vez de reusar el anterior a ciegas.

## Por qué este orden

El propio `tool/deploy.sh` ya documenta esto en su cabecera: `flutter analyze` se corre aparte a propósito, porque su salida "needs to actually be read, not just piped through". El mismo criterio aplica al resto del ciclo: cada paso existe para que un problema se detecte en la etapa más barata posible.

Sobre `git commit`: no hay una regla propia de este repo sobre cuándo commitear — se sigue el criterio general (solo cuando el usuario lo pide explícitamente), sin condiciones adicionales inventadas.
