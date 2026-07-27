import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart' as vp;

import '../abstractions/video_engine.dart';

/// [VideoEngine] backed by the official `video_player` plugin, which uses
/// Media3/ExoPlayer on Android — one of the engines the plan explicitly
/// allows ("Posibles motores: libVLC, Android Media3, ExoPlayer, mpv").
class Media3VideoEngine extends ChangeNotifier implements VideoEngine {
  vp.VideoPlayerController? _controller;

  @override
  VideoEngineValue get value {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const VideoEngineValue.uninitialized();
    }
    final v = controller.value;
    return VideoEngineValue(
      isInitialized: true,
      isPlaying: v.isPlaying,
      isCompleted: v.isCompleted,
      position: v.position,
      duration: v.duration,
      aspectRatio: v.aspectRatio == 0 ? 16 / 9 : v.aspectRatio,
    );
  }

  @override
  Future<void> initialize(File file) async {
    final controller = vp.VideoPlayerController.file(file);
    _controller = controller;
    controller.addListener(notifyListeners);
    await controller.initialize();
    notifyListeners();
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> seekTo(Duration position) async => _controller?.seekTo(position);

  @override
  Future<void> setPlaybackSpeed(double speed) async => _controller?.setPlaybackSpeed(speed);

  @override
  Future<void> setVolume(double volume) async => _controller?.setVolume(volume);

  @override
  Widget buildSurface() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return const SizedBox.shrink();
    return vp.VideoPlayer(controller);
  }

  @override
  void dispose() {
    _controller?.removeListener(notifyListeners);
    _controller?.dispose();
    super.dispose();
  }
}
