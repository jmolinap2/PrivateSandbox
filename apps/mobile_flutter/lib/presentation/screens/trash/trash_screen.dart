import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vault_thumbnail.dart';

/// Fase 3's "papelera privada": files land here on everyday "Eliminar"
/// instead of being wiped immediately, and can be recovered or permanently
/// deleted from here.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  Future<void> _confirmEmptyTrash(BuildContext context, WidgetRef ref, List<VaultFile> files) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar papelera'),
        content: Text(
          '${files.length} archivo(s) se eliminarán definitivamente. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final useCase = ref.read(deleteFileUseCaseProvider);
    for (final file in files) {
      await useCase.call(file);
    }
  }

  Future<void> _confirmPermanentDelete(BuildContext context, WidgetRef ref, VaultFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: Text('"${file.originalName}" se eliminará para siempre. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(deleteFileUseCaseProvider).call(file);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultTrashedFilesStreamProvider);
    final dateFormat = DateFormat('d MMM, HH:mm', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papelera'),
        actions: [
          filesAsync.maybeWhen(
            data: (files) => files.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Vaciar papelera',
                    onPressed: () => _confirmEmptyTrash(context, ref, files),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: filesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (files) {
          if (files.isEmpty) {
            return const EmptyState(
              icon: Icons.delete_outline,
              title: 'La papelera está vacía',
              subtitle: 'Los archivos eliminados de la biblioteca aparecen aquí antes de borrarse para siempre.',
            );
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final deletedAt = file.deletedAt;
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: VaultThumbnail(file: file, iconSize: 24),
                  ),
                ),
                title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(deletedAt == null ? '' : 'Eliminado el ${dateFormat.format(deletedAt)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore_from_trash_outlined),
                      tooltip: 'Recuperar',
                      onPressed: () => ref.read(recoverFromTrashUseCaseProvider).call(file),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined),
                      tooltip: 'Eliminar definitivamente',
                      onPressed: () => _confirmPermanentDelete(context, ref, file),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
