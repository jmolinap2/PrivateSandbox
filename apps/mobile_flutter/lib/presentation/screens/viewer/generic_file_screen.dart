import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/vault_file.dart';
import 'restore_action.dart';
import 'share_action.dart';

/// Files without a dedicated in-app viewer (Phase 1 only ships viewers for
/// images/video/audio/PDF) still get imported, hidden and exported — they
/// just show their metadata plus an export action instead of a preview.
class GenericFileScreen extends ConsumerWidget {
  final VaultFile file;

  const GenericFileScreen({super.key, required this.file});

  String get _sizeLabel {
    final kb = file.sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(file.originalName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 96, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(file.originalName, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${file.mimeType} · $_sizeLabel',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => restoreVaultFile(context, ref, file),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Exportar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => shareVaultFile(context, ref, file),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
