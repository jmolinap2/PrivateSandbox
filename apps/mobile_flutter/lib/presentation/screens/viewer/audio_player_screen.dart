import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';
import '../../../media_engine/abstractions/audio_engine.dart';
import 'decrypted_playback_view.dart';
import 'restore_action.dart';
import 'share_action.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final VaultFile file;

  /// Ordered playback queue this track belongs to (e.g. the audio files of a
  /// collection/album/library view). Empty means "just this one track".
  final List<VaultFile> queue;

  const AudioPlayerScreen({super.key, required this.file, this.queue = const []});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
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
      appBar: AppBar(
        title: Text(file.originalName),
        actions: [
          ShareActionButton(file: file),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => restoreVaultFile(context, ref, file),
          ),
        ],
      ),
      body: DecryptedPlaybackView(
        key: ValueKey(file.id),
        file: file,
        builder: (context, decrypted) => _AudioBody(
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

class _AudioBody extends ConsumerStatefulWidget {
  final VaultFile vaultFile;
  final File decryptedFile;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _AudioBody({
    required this.vaultFile,
    required this.decryptedFile,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  ConsumerState<_AudioBody> createState() => _AudioBodyState();
}

class _AudioBodyState extends ConsumerState<_AudioBody> {
  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  late final AudioEngine _engine;
  StreamSubscription<void>? _completedSub;
  bool _ready = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _engine = ref.read(audioEngineFactoryProvider)();
    // Auto-advance to the next queue item when the current track finishes.
    _completedSub = _engine.completedStream.listen((_) {
      widget.onNext?.call();
    });
    _engine.load(widget.decryptedFile).then((_) async {
      if (!mounted) return;
      final resumeMs = widget.vaultFile.playbackPositionMs;
      final duration = _engine.duration;
      if (resumeMs != null && resumeMs > 0 && duration != null && duration.inMilliseconds - resumeMs > 5000) {
        await _engine.seek(Duration(milliseconds: resumeMs));
      }
      if (!mounted) return;
      setState(() => _ready = true);
      _engine.play();
    });
  }

  @override
  void dispose() {
    _completedSub?.cancel();
    ref.read(vaultRepositoryProvider).recordOpened(widget.vaultFile.id, playbackPositionMs: _engine.position.inMilliseconds);
    _engine.dispose();
    super.dispose();
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _engine.setSpeed(speed);
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.audiotrack, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(widget.vaultFile.originalName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          StreamBuilder<Duration>(
            stream: _engine.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _engine.duration ?? Duration.zero;
              return Column(
                children: [
                  Slider(
                    min: 0,
                    max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                    onChanged: (value) => _engine.seek(Duration(milliseconds: value.toInt())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(position)),
                        Text(_format(duration)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.hasPrevious || widget.hasNext)
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: widget.onPrevious,
                ),
              StreamBuilder<bool>(
                stream: _engine.playingStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data ?? false;
                  return IconButton(
                    iconSize: 64,
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    onPressed: () => playing ? _engine.pause() : _engine.play(),
                  );
                },
              ),
              if (widget.hasPrevious || widget.hasNext)
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next),
                  onPressed: widget.onNext,
                ),
              PopupMenuButton<double>(
                initialValue: _speed,
                onSelected: _setSpeed,
                itemBuilder: (context) => [
                  for (final speed in _speeds) PopupMenuItem(value: speed, child: Text('${speed}x')),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed),
                      const SizedBox(width: 4),
                      Text('${_speed}x'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
