/// How long the app can sit in the background before it re-locks itself on
/// return. "Inmediato" (the default) locks on every backgrounding, no matter
/// how brief — appropriate for a privacy vault where even a quick app-switch
/// shouldn't leave content exposed.
enum AutoLockTimeout { immediate, seconds30, minute1, minutes5, never }

extension AutoLockTimeoutX on AutoLockTimeout {
  /// Null means "never lock automatically"; [Duration.zero] means lock on
  /// any backgrounding, however brief.
  Duration? get threshold => switch (this) {
        AutoLockTimeout.immediate => Duration.zero,
        AutoLockTimeout.seconds30 => const Duration(seconds: 30),
        AutoLockTimeout.minute1 => const Duration(minutes: 1),
        AutoLockTimeout.minutes5 => const Duration(minutes: 5),
        AutoLockTimeout.never => null,
      };

  String get label => switch (this) {
        AutoLockTimeout.immediate => 'Inmediato',
        AutoLockTimeout.seconds30 => '30 segundos',
        AutoLockTimeout.minute1 => '1 minuto',
        AutoLockTimeout.minutes5 => '5 minutos',
        AutoLockTimeout.never => 'Nunca',
      };
}
