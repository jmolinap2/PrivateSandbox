import 'dart:io';

/// Abstracts the concrete audio playback library behind one interface —
/// same rationale as [VideoEngine]: the presentation layer never imports
/// `just_audio` (or any future replacement) directly.
abstract interface class AudioEngine {
  Stream<Duration> get positionStream;
  Stream<bool> get playingStream;

  /// Fires once each time the current track plays through to its end — used
  /// to auto-advance a playback queue.
  Stream<void> get completedStream;

  Duration? get duration;
  Duration get position;

  Future<void> load(File file);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  void dispose();
}
