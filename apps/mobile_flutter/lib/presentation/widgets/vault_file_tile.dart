import 'package:flutter/material.dart';

import '../../domain/entities/file_category.dart';
import '../../domain/entities/vault_file.dart';

class VaultFileTile extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onTap;

  const VaultFileTile({super.key, required this.file, required this.onTap});

  IconData get _icon => switch (file.category) {
        FileCategory.image => Icons.image_outlined,
        FileCategory.video => Icons.movie_outlined,
        FileCategory.audio => Icons.audiotrack_outlined,
        FileCategory.pdf => Icons.picture_as_pdf_outlined,
        FileCategory.generic => Icons.insert_drive_file_outlined,
      };

  String get _sizeLabel {
    final kb = file.sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(_icon, size: 40, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                file.originalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                _sizeLabel,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
