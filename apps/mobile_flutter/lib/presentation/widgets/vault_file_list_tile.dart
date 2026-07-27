import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/vault_file.dart';
import '../screens/folders/folder_picker_sheet.dart';
import '../screens/viewer/file_details_screen.dart';
import '../screens/viewer/restore_action.dart';
import 'collection_assignment_sheet.dart';
import 'tag_assignment_sheet.dart';
import 'vault_thumbnail.dart';

class VaultFileListTile extends ConsumerWidget {
  final VaultFile file;
  final VoidCallback onTap;

  const VaultFileListTile({super.key, required this.file, required this.onTap});

  String get _sizeLabel {
    final kb = file.sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar de la bóveda'),
        content: Text('"${file.originalName}" se moverá a la papelera. Podrás recuperarlo desde ahí.'),
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
      await ref.read(moveToTrashUseCaseProvider).call(file);
    }
  }

  Future<void> _moveToFolder(BuildContext context, WidgetRef ref) async {
    final folders = await ref.read(vaultFolderRepositoryProvider).getAllFolders();
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<FolderChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FolderPickerSheet(folders: folders, currentFolderId: file.folderId),
    );
    if (chosen == null) return;
    await ref.read(vaultRepositoryProvider).moveFileToFolder(file.id, chosen.folderId);
  }

  void _showTags(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagAssignmentSheet(file: file),
    );
  }

  void _showCollections(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CollectionAssignmentSheet(file: file),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: VaultThumbnail(file: file, iconSize: 24),
        ),
      ),
      title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${file.extension.toUpperCase()} · $_sizeLabel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              file.isFavorite ? Icons.star : Icons.star_border,
              color: file.isFavorite ? theme.colorScheme.primary : null,
            ),
            onPressed: () => ref.read(vaultRepositoryProvider).setFavorite(file.id, !file.isFavorite),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'restore':
                  restoreVaultFile(context, ref, file);
                case 'move':
                  _moveToFolder(context, ref);
                case 'tags':
                  _showTags(context);
                case 'collections':
                  _showCollections(context);
                case 'details':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FileDetailsScreen(file: file)),
                  );
                case 'delete':
                  _confirmDelete(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'restore', child: Text('Restaurar')),
              PopupMenuItem(value: 'move', child: Text('Mover a carpeta')),
              PopupMenuItem(value: 'tags', child: Text('Etiquetas')),
              PopupMenuItem(value: 'collections', child: Text('Colecciones')),
              PopupMenuItem(value: 'details', child: Text('Detalles')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}
