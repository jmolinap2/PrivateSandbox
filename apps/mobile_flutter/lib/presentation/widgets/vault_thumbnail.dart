import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/file_category.dart';
import '../../domain/entities/vault_file.dart';

IconData iconForCategory(FileCategory category) => switch (category) {
      FileCategory.image => Icons.image_outlined,
      FileCategory.video => Icons.movie_outlined,
      FileCategory.audio => Icons.audiotrack_outlined,
      FileCategory.pdf => Icons.picture_as_pdf_outlined,
      FileCategory.generic => Icons.insert_drive_file_outlined,
    };

/// Shows a decrypted thumbnail when [file] has one, falling back to a
/// category icon otherwise (or while it loads).
class VaultThumbnail extends ConsumerWidget {
  final VaultFile file;
  final double iconSize;

  const VaultThumbnail({super.key, required this.file, this.iconSize = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fallback = Icon(iconForCategory(file.category), size: iconSize, color: theme.colorScheme.primary);

    if (!file.hasThumbnail) return Center(child: fallback);

    final key = (
      fileSaltBase64: file.fileSaltBase64,
      thumbnailFileName: file.thumbnailFileName!,
      thumbnailNoncePrefixBase64: file.thumbnailNoncePrefixBase64!,
    );
    final bytesAsync = ref.watch(thumbnailBytesProvider(key));

    return bytesAsync.when(
      loading: () => Center(child: fallback),
      error: (_, _) => Center(child: fallback),
      data: (bytes) {
        if (bytes == null || bytes.isEmpty) return Center(child: fallback);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        );
      },
    );
  }
}
