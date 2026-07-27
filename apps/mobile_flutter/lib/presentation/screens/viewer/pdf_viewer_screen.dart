import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/vault_file.dart';
import 'decrypted_playback_view.dart';
import 'restore_action.dart';
import 'share_action.dart';

class PdfViewerScreen extends ConsumerWidget {
  final VaultFile file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        file: file,
        builder: (context, decrypted) => PDFView(filePath: decrypted.path),
      ),
    );
  }
}
