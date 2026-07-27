import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';
import '../../../infrastructure/storage/vault_paths.dart';
import '../../widgets/empty_state.dart';

/// Fase 3's "gestión de almacenamiento": space used, duplicate detection
/// (by content hash — the same integrity hash already computed at import),
/// and clearing the transient decrypted-playback cache.
class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  String _sizeLabel(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  Future<void> _clearCache(BuildContext context) async {
    await VaultPaths.clearTempPlaybackDir();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caché de reproducción vaciada.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(vaultFilesStreamProvider).value ?? const <VaultFile>[];
    final trashed = ref.watch(vaultTrashedFilesStreamProvider).value ?? const <VaultFile>[];
    final duplicateGroups = ref.watch(duplicateFileGroupsProvider);

    final activeBytes = files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final trashedBytes = trashed.fold<int>(0, (sum, f) => sum + f.sizeBytes);

    return Scaffold(
      appBar: AppBar(title: const Text('Almacenamiento')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Bóveda'),
            subtitle: Text('${files.length} archivo(s)'),
            trailing: Text(_sizeLabel(activeBytes)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Papelera'),
            subtitle: Text('${trashed.length} archivo(s)'),
            trailing: Text(_sizeLabel(trashedBytes)),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Limpiar caché de reproducción'),
            subtitle: const Text('Borra archivos temporales descifrados que hayan quedado.'),
            onTap: () => _clearCache(context),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Archivos duplicados', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (duplicateGroups.isEmpty)
            const EmptyState(
              icon: Icons.content_copy_outlined,
              title: 'Sin duplicados',
              subtitle: 'No se encontraron archivos con el mismo contenido.',
            )
          else
            for (final group in duplicateGroups) _DuplicateGroupTile(files: group),
        ],
      ),
    );
  }
}

class _DuplicateGroupTile extends ConsumerWidget {
  const _DuplicateGroupTile({required this.files});

  final List<VaultFile> files;

  Future<void> _keepOnly(BuildContext context, WidgetRef ref, VaultFile keep) async {
    final others = files.where((f) => f.id != keep.id).toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar duplicados'),
        content: Text('Se moverán ${others.length} archivo(s) a la papelera, conservando solo "${keep.originalName}".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final useCase = ref.read(moveToTrashUseCaseProvider);
    for (final file in others) {
      await useCase.call(file);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final file in files)
              ListTile(
                dense: true,
                title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: TextButton(
                  onPressed: () => _keepOnly(context, ref, file),
                  child: const Text('Conservar este'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
