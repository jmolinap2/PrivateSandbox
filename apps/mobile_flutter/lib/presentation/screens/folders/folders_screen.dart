import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_folder.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vault_file_list_tile.dart';

/// Fase 3's "carpetas virtuales / subcarpetas": purely organizational —
/// filing a file under a folder never moves its ciphertext blob, it just
/// sets a `folderId` tag used to filter the library view.
class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  final List<VaultFolder> _path = [];

  String? get _currentFolderId => _path.isEmpty ? null : _path.last.id;

  Future<String?> _promptName(String title, {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder() async {
    final name = await _promptName('Nueva carpeta');
    if (name == null || name.isEmpty) return;
    await ref.read(vaultFolderRepositoryProvider).createFolder(name: name, parentId: _currentFolderId);
  }

  Future<void> _renameFolder(VaultFolder folder) async {
    final name = await _promptName('Renombrar carpeta', initial: folder.name);
    if (name == null || name.isEmpty) return;
    await ref.read(vaultFolderRepositoryProvider).renameFolder(folder.id, name);
  }

  Future<void> _deleteFolder(VaultFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carpeta'),
        content: Text(
          '"${folder.name}" y sus subcarpetas se eliminarán. Los archivos no se borran: quedarán sin carpeta.',
        ),
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
      await ref.read(vaultFolderRepositoryProvider).deleteFolder(folder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(vaultFoldersStreamProvider(_currentFolderId));
    final filesAsync = ref.watch(vaultFilesInFolderStreamProvider(_currentFolderId));
    final canPop = _path.isNotEmpty;

    return PopScope(
      canPop: !canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canPop) setState(() => _path.removeLast());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_path.isEmpty ? 'Carpetas' : _path.last.name),
          leading: canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _path.removeLast()),
                )
              : null,
        ),
        body: foldersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (folders) {
            return filesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (files) {
                if (folders.isEmpty && files.isEmpty) {
                  return const EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'Carpeta vacía',
                    subtitle: 'Crea una subcarpeta o mueve archivos aquí desde la Biblioteca.',
                  );
                }
                return ListView(
                  children: [
                    for (final folder in folders)
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(folder.name),
                        onTap: () => setState(() => _path.add(folder)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _renameFolder(folder);
                              case 'delete':
                                _deleteFolder(folder);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    if (folders.isNotEmpty && files.isNotEmpty) const Divider(),
                    for (final file in files)
                      VaultFileListTile(
                        file: file,
                        onTap: () => context.push(
                          AppRoutes.viewerFor(file.id),
                          extra: [for (final f in files) f.id],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createFolder,
          tooltip: 'Nueva carpeta',
          child: const Icon(Icons.create_new_folder_outlined),
        ),
      ),
    );
  }
}
