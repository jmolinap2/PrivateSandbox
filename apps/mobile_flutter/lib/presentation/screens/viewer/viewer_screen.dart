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
///
/// [queueIds] is the ordered list of file ids the user was looking at when
/// they tapped this one (e.g. a collection/album/filtered library). For
/// video/audio it becomes the playback queue, so the player can advance to
/// the next track; other categories ignore it.
class ViewerScreen extends ConsumerStatefulWidget {
  final String fileId;
  final List<String>? queueIds;

  const ViewerScreen({super.key, required this.fileId, this.queueIds});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  @override
  void initState() {
    super.initState();
    // Recorded once per screen open, not on every rebuild the vault files
    // stream triggers (e.g. another file's favorite being toggled).
    ref.read(vaultRepositoryProvider).recordOpened(widget.fileId);
  }

  /// Builds the same-category playback queue for [file], preserving the order
  /// the ids were given in. Falls back to just [file] when there's no queue.
  List<VaultFile> _buildQueue(VaultFile file, List<VaultFile> allFiles) {
    final ids = widget.queueIds;
    if (ids == null || ids.isEmpty) return [file];
    final byId = {for (final f in allFiles) f.id: f};
    final queue = <VaultFile>[
      for (final id in ids)
        if (byId[id] case final f? when f.category == file.category) f,
    ];
    return queue.isEmpty ? [file] : queue;
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(vaultFilesStreamProvider);

    return filesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (files) {
        VaultFile? file;
        for (final f in files) {
          if (f.id == widget.fileId) {
            file = f;
            break;
          }
        }
        if (file == null) {
          return const Scaffold(body: Center(child: Text('Archivo no encontrado.')));
        }
        return switch (file.category) {
          FileCategory.image => ImageViewerScreen(file: file),
          FileCategory.video => VideoPlayerScreen(file: file, queue: _buildQueue(file, files)),
          FileCategory.audio => AudioPlayerScreen(file: file, queue: _buildQueue(file, files)),
          FileCategory.pdf => PdfViewerScreen(file: file),
          FileCategory.generic => GenericFileScreen(file: file),
        };
      },
    );
  }
}
