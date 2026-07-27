import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';
import '../../../media_engine/abstractions/video_engine.dart';
import 'decrypted_playback_view.dart';
import 'restore_action.dart';
import 'share_action.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final VaultFile file;

  /// Ordered playback queue this file belongs to (e.g. the videos of a
  /// collection/album/library view). Empty means "just this one file".
  final List<VaultFile> queue;

  const VideoPlayerScreen({super.key, required this.file, this.queue = const []});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late List<VaultFile> _queue;
  late int _index;

  @override
  void initState() {
    super.initState();
    _queue = widget.queue.isEmpty ? [widget.file] : widget.queue;
    final found = _queue.indexWhere((f) => f.id == widget.file.id);
    _index = found < 0 ? 0 : found;
  }

  VaultFile get _current => _queue[_index];
  bool get _hasPrevious => _index > 0;
  bool get _hasNext => _index < _queue.length - 1;

  void _goTo(int index) {
    if (index < 0 || index >= _queue.length) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final file = _current;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(file.originalName),
        actions: [
          ShareActionButton(file: file),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => restoreVaultFile(context, ref, file),
          ),
        ],
      ),
      // Re-keyed per file so switching tracks re-runs decryption and rebuilds
      // the player body for the new file from scratch.
      body: DecryptedPlaybackView(
        key: ValueKey(file.id),
        file: file,
        builder: (context, decrypted) => _VideoBody(
          vaultFile: file,
          decryptedFile: decrypted,
          hasPrevious: _hasPrevious,
          hasNext: _hasNext,
          onPrevious: _hasPrevious ? () => _goTo(_index - 1) : null,
          onNext: _hasNext ? () => _goTo(_index + 1) : null,
        ),
      ),
    );
  }
}

class _VideoBody extends ConsumerStatefulWidget {
  final VaultFile vaultFile;
  final File decryptedFile;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _VideoBody({
    required this.vaultFile,
    required this.decryptedFile,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  ConsumerState<_VideoBody> createState() => _VideoBodyState();
}

class _VideoBodyState extends ConsumerState<_VideoBody> {
  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  late final VideoEngine _engine;
  bool _ready = false;
  double _speed = 1.0;
  double _volume = 1.0;
  double _brightness = 0.5;

  bool _isSeeking = false;
  double _seekDeltaSeconds = 0;

  bool _isAdjustingVolume = false;
  bool _isAdjustingBrightness = false;
  // A single vertical drag is either brightness (left half) or volume (right
  // half); decided at drag start so it can't flip mid-gesture.
  bool _verticalDragIsBrightness = false;

  // Guards against auto-advancing more than once for the same completion.
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    _engine = ref.read(videoEngineFactoryProvider)();
    ref.read(systemChannelProvider).getScreenBrightness().then((value) {
      if (mounted) setState(() => _brightness = value);
    });
    _engine.addListener(_onEngineTick);
    _engine.initialize(widget.decryptedFile).then((_) async {
      if (!mounted) return;
      final resumeMs = widget.vaultFile.playbackPositionMs;
      final duration = _engine.value.duration;
      // Don't resume if the saved position is within the last 5s — that
      // usually means the video already finished.
      if (resumeMs != null && resumeMs > 0 && duration.inMilliseconds - resumeMs > 5000) {
        await _engine.seekTo(Duration(milliseconds: resumeMs));
      }
      if (!mounted) return;
      setState(() => _ready = true);
      _engine.play();
    });
  }

  void _onEngineTick() {
    // Auto-advance to the next queue item once the current one finishes.
    if (!_advanced && _engine.value.isCompleted && widget.onNext != null) {
      _advanced = true;
      widget.onNext!();
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineTick);
    ref
        .read(vaultRepositoryProvider)
        .recordOpened(widget.vaultFile.id, playbackPositionMs: _engine.value.position.inMilliseconds);
    // Hand brightness control back to the system so the vault doesn't leave
    // the whole device dimmed after the player closes.
    ref.read(systemChannelProvider).clearScreenBrightness();
    _engine.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    _engine.value.isPlaying ? _engine.pause() : _engine.play();
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _engine.setPlaybackSpeed(speed);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isSeeking = true;
      _seekDeltaSeconds = 0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _seekDeltaSeconds += details.delta.dx / 8);
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final target = _engine.value.position + Duration(milliseconds: (_seekDeltaSeconds * 1000).round());
    final duration = _engine.value.duration;
    final clamped = target < Duration.zero ? Duration.zero : (target > duration ? duration : target);
    await _engine.seekTo(clamped);
    if (!mounted) return;
    setState(() {
      _isSeeking = false;
      _seekDeltaSeconds = 0;
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    final width = MediaQuery.of(context).size.width;
    final isBrightness = details.globalPosition.dx < width / 2;
    setState(() {
      _verticalDragIsBrightness = isBrightness;
      _isAdjustingBrightness = isBrightness;
      _isAdjustingVolume = !isBrightness;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final height = MediaQuery.of(context).size.height;
    if (_verticalDragIsBrightness) {
      setState(() {
        _brightness = (_brightness - details.delta.dy / height).clamp(0.0, 1.0);
      });
      ref.read(systemChannelProvider).setScreenBrightness(_brightness);
    } else {
      setState(() {
        _volume = (_volume - details.delta.dy / height).clamp(0.0, 1.0);
      });
      _engine.setVolume(_volume);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isAdjustingVolume = false;
      _isAdjustingBrightness = false;
    });
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _engine.value.aspectRatio,
        child: GestureDetector(
          onTap: _togglePlayback,
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onVerticalDragStart: _onVerticalDragStart,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _engine.buildSurface(),
              AnimatedBuilder(
                animation: _engine,
                builder: (context, _) => _engine.value.isPlaying
                    ? const SizedBox.shrink()
                    : const Icon(Icons.play_arrow, size: 64, color: Colors.white70),
              ),
              if (_isSeeking)
                Positioned.fill(
                  child: Center(
                    child: _Badge(
                      icon: _seekDeltaSeconds >= 0 ? Icons.fast_forward : Icons.fast_rewind,
                      label: '${_seekDeltaSeconds >= 0 ? '+' : ''}${_seekDeltaSeconds.round()}s',
                    ),
                  ),
                ),
              if (_isAdjustingVolume)
                Positioned.fill(
                  child: Center(
                    child: _Badge(
                      icon: _volume == 0 ? Icons.volume_off : Icons.volume_up,
                      label: '${(_volume * 100).round()}%',
                    ),
                  ),
                ),
              if (_isAdjustingBrightness)
                Positioned.fill(
                  child: Center(
                    child: _Badge(
                      icon: Icons.brightness_6,
                      label: '${(_brightness * 100).round()}%',
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<double>(
                  initialValue: _speed,
                  onSelected: _setSpeed,
                  itemBuilder: (context) => [
                    for (final speed in _speeds) PopupMenuItem(value: speed, child: Text('${speed}x')),
                  ],
                  child: _Badge(icon: Icons.speed, label: '${_speed}x', compact: true),
                ),
              ),
              _Controls(
                engine: _engine,
                format: _format,
                hasPrevious: widget.hasPrevious,
                hasNext: widget.hasNext,
                onPrevious: widget.onPrevious,
                onNext: widget.onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.engine,
    required this.format,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final VideoEngine engine;
  final String Function(Duration) format;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final showQueueControls = hasPrevious || hasNext;
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final value = engine.value;
        final durationMs = value.duration.inMilliseconds;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showQueueControls)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: hasPrevious ? onPrevious : null,
                      disabledColor: Colors.white24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: hasNext ? onNext : null,
                      disabledColor: Colors.white24,
                    ),
                  ],
                ),
              Row(
                children: [
                  Text(format(value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: durationMs > 0 ? durationMs.toDouble() : 1,
                      value: value.position.inMilliseconds.clamp(0, durationMs > 0 ? durationMs : 1).toDouble(),
                      onChanged: (v) => engine.seekTo(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Text(format(value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _Badge({required this.icon, required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16, vertical: compact ? 6 : 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: compact ? 16 : 24),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
