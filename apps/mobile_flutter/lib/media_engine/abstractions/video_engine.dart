import 'dart:io';

import 'package:flutter/widgets.dart';

/// Immutable playback state snapshot exposed by any [VideoEngine].
class VideoEngineValue {
  final bool isInitialized;
  final bool isPlaying;
  final bool isCompleted;
  final Duration position;
  final Duration duration;
  final double aspectRatio;

  const VideoEngineValue({
    required this.isInitialized,
    required this.isPlaying,
    required this.isCompleted,
    required this.position,
    required this.duration,
    required this.aspectRatio,
  });

  const VideoEngineValue.uninitialized()
      : isInitialized = false,
        isPlaying = false,
        isCompleted = false,
        position = Duration.zero,
        duration = Duration.zero,
        aspectRatio = 16 / 9;
}

/// Abstracts the concrete video playback library behind one interface, per
/// the plan's "el motor multimedia debe estar abstraído detrás de una
/// interfaz" / "la app no debe depender directamente de un único motor".
///
/// The presentation layer only ever talks to this interface — it never
/// imports `video_player`, `flutter_vlc_player`, or any other concrete
/// engine package directly. Swapping engines (e.g. adding a libVLC-backed
/// implementation later) means adding a new class under `media_engine/` and
/// changing the factory in `application/providers.dart`; no UI code changes.
abstract interface class VideoEngine implements Listenable {
  VideoEngineValue get value;

  Future<void> initialize(File file);
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> setVolume(double volume);

  /// The actual render surface. Opaque to callers — only the concrete
  /// engine knows what widget backs it.
  Widget buildSurface();

  void dispose();
}
