import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../domain/entities/vault_file.dart';
import 'decrypted_playback_view.dart';
import 'restore_action.dart';
import 'share_action.dart';

class ImageViewerScreen extends ConsumerStatefulWidget {
  final VaultFile file;

  /// Ordered image queue this file belongs to (e.g. the photos of a
  /// collection/album/library view). Empty means "just this one file".
  final List<VaultFile> queue;

  const ImageViewerScreen({super.key, required this.file, this.queue = const []});

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  late List<VaultFile> _queue;
  late int _index;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _queue = widget.queue.isEmpty ? [widget.file] : widget.queue;
    final found = _queue.indexWhere((f) => f.id == widget.file.id);
    _index = found < 0 ? 0 : found;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  VaultFile get _current => _queue[_index];

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
          if (_queue.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_index + 1} de ${_queue.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ShareActionButton(file: file),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => restoreVaultFile(context, ref, file),
          ),
        ],
      ),
      body: _queue.length > 1
          ? PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: _queue.length,
              onPageChanged: (index) => setState(() => _index = index),
              builder: (context, index) {
                final queuedFile = _queue[index];
                return PhotoViewGalleryPageOptions.customChild(
                  child: DecryptedPlaybackView(
                    key: ValueKey(queuedFile.id),
                    file: queuedFile,
                    builder: (context, decrypted) => Image.file(decrypted, fit: BoxFit.contain),
                  ),
                );
              },
            )
          : DecryptedPlaybackView(
              file: file,
              builder: (context, decrypted) => PhotoView(imageProvider: FileImage(decrypted)),
            ),
    );
  }
}
