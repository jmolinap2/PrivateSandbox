import 'dart:io';

import 'package:just_audio/just_audio.dart' as ja;

import '../abstractions/audio_engine.dart';

/// [AudioEngine] backed by `just_audio`, which uses Media3/ExoPlayer on
/// Android — same engine family as [Media3VideoEngine].
class Media3AudioEngine implements AudioEngine {
  final _player = ja.AudioPlayer();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<bool> get playingStream => _player.playerStateStream.map((state) => state.playing);

  @override
  Stream<void> get completedStream => _player.processingStateStream
      .where((state) => state == ja.ProcessingState.completed)
      .map((_) {});

  @override
  Duration? get duration => _player.duration;

  @override
  Duration get position => _player.position;

  @override
  Future<void> load(File file) => _player.setFilePath(file.path);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  void dispose() => _player.dispose();
}
