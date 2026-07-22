import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../../../domain/entities/vault_file.dart';
import 'decrypted_playback_view.dart';
import 'export_action.dart';

class ImageViewerScreen extends ConsumerWidget {
  final VaultFile file;

  const ImageViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
        builder: (context, decrypted) => PhotoView(imageProvider: FileImage(decrypted)),
      ),
    );
  }
}
