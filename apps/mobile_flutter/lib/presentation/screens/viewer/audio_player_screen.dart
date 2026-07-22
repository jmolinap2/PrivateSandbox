import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/entities/vault_file.dart';
import 'decrypted_playback_view.dart';
import 'export_action.dart';

class AudioPlayerScreen extends ConsumerWidget {
  final VaultFile file;

  const AudioPlayerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.originalName),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => exportVaultFile(context, ref, file),
          ),
        ],
      ),
      body: DecryptedPlaybackView(
        file: file,
        builder: (context, decrypted) => _AudioBody(file: decrypted, title: file.originalName),
      ),
    );
  }
}

class _AudioBody extends StatefulWidget {
  final File file;
  final String title;

  const _AudioBody({required this.file, required this.title});

  @override
  State<_AudioBody> createState() => _AudioBodyState();
}

class _AudioBodyState extends State<_AudioBody> {
  final _player = AudioPlayer();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _player.setFilePath(widget.file.path).then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _player.play();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
          Text(widget.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;
              return Column(
                children: [
                  Slider(
                    min: 0,
                    max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                    onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
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
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                iconSize: 64,
                icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                onPressed: () => playing ? _player.pause() : _player.play(),
              );
            },
          ),
        ],
      ),
    );
  }
}
