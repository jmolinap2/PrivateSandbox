import 'package:flutter/material.dart';

import '../../domain/entities/vault_file.dart';
import 'vault_thumbnail.dart';

class VaultFileTile extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onTap;

  const VaultFileTile({super.key, required this.file, required this.onTap});

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
                child: Stack(
                  children: [
                    Positioned.fill(child: VaultThumbnail(file: file)),
                    if (file.isFavorite)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                      ),
                  ],
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
