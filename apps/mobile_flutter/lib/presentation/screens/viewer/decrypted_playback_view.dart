import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';

/// Decrypts [file] into a private temporary file for the lifetime of this
/// widget, exposing it to [builder], and deletes it again on dispose so
/// plaintext never lingers on disk longer than the viewer is open.
class DecryptedPlaybackView extends ConsumerStatefulWidget {
  final VaultFile file;
  final Widget Function(BuildContext context, File decryptedFile) builder;

  const DecryptedPlaybackView({
    super.key,
    required this.file,
    required this.builder,
  });

  @override
  ConsumerState<DecryptedPlaybackView> createState() =>
      _DecryptedPlaybackViewState();
}

class _DecryptedPlaybackViewState extends ConsumerState<DecryptedPlaybackView> {
  File? _decryptedFile;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final playback = ref.read(playbackUseCaseProvider);
    try {
      final file = await playback.decryptToTemp(widget.file);
      if (mounted) {
        setState(() => _decryptedFile = file);
      } else {
        await playback.cleanupTemp(file);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    final decrypted = _decryptedFile;
    if (decrypted != null) {
      ref.read(playbackUseCaseProvider).cleanupTemp(decrypted);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(child: Text('No se pudo abrir el archivo.'));
    }
    final decrypted = _decryptedFile;
    if (decrypted == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, decrypted);
  }
}
