import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/file_category.dart';
import '../../../domain/entities/vault_file.dart';
import 'audio_player_screen.dart';
import 'generic_file_screen.dart';
import 'image_viewer_screen.dart';
import 'pdf_viewer_screen.dart';
import 'video_player_screen.dart';

/// Resolves [fileId] from the vault and dispatches to the viewer matching
/// its [FileCategory].
class ViewerScreen extends ConsumerWidget {
  final String fileId;

  const ViewerScreen({super.key, required this.fileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesStreamProvider);

    return filesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (files) {
        VaultFile? file;
        for (final f in files) {
          if (f.id == fileId) {
            file = f;
            break;
          }
        }
        if (file == null) {
          return const Scaffold(body: Center(child: Text('Archivo no encontrado.')));
        }
        return switch (file.category) {
          FileCategory.image => ImageViewerScreen(file: file),
          FileCategory.video => VideoPlayerScreen(file: file),
          FileCategory.audio => AudioPlayerScreen(file: file),
          FileCategory.pdf => PdfViewerScreen(file: file),
          FileCategory.generic => GenericFileScreen(file: file),
        };
      },
    );
  }
}
