import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/file_category.dart';
import '../../widgets/empty_state.dart';
import 'collection_files_screen.dart';
import 'smart_album_files_screen.dart';
import 'tag_files_screen.dart';

/// Fase 3's "etiquetas / colecciones / álbumes inteligentes": three
/// different ways to group files that already exist elsewhere in the vault
/// — none of them move or duplicate the underlying ciphertext.
class OrganizationScreen extends StatelessWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Organización'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Etiquetas'), Tab(text: 'Colecciones'), Tab(text: 'Álbumes')],
          ),
        ),
        body: const TabBarView(
          children: [_TagsTab(), _CollectionsTab(), _SmartAlbumsTab()],
        ),
      ),
    );
  }
}

Future<String?> _promptName(BuildContext context, String title, {String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Nombre')),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Guardar')),
      ],
    ),
  );
}

class _TagsTab extends ConsumerWidget {
  const _TagsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(vaultTagsStreamProvider);
    return Scaffold(
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (tags) {
          if (tags.isEmpty) {
            return const EmptyState(
              icon: Icons.label_outline,
              title: 'Sin etiquetas',
              subtitle: 'Crea una etiqueta y asígnala a un archivo desde su menú.',
            );
          }
          return ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(tag.name),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TagFilesScreen(tag: tag)),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'rename':
                        final name = await _promptName(context, 'Renombrar etiqueta', initial: tag.name);
                        if (name != null && name.isNotEmpty) {
                          await ref.read(vaultTagRepositoryProvider).renameTag(tag.id, name);
                        }
                      case 'delete':
                        await ref.read(vaultTagRepositoryProvider).deleteTag(tag.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva etiqueta',
        onPressed: () async {
          final name = await _promptName(context, 'Nueva etiqueta');
          if (name != null && name.isNotEmpty) {
            await ref.read(vaultTagRepositoryProvider).getOrCreateTag(name);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CollectionsTab extends ConsumerWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(vaultCollectionsStreamProvider);
    return Scaffold(
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (collections) {
          if (collections.isEmpty) {
            return const EmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: 'Sin colecciones',
              subtitle: 'Crea una colección y agrégale archivos desde su menú.',
            );
          }
          return ListView.builder(
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return ListTile(
                leading: const Icon(Icons.collections_bookmark_outlined),
                title: Text(collection.name),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CollectionFilesScreen(collection: collection)),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'rename':
                        final name = await _promptName(context, 'Renombrar colección', initial: collection.name);
                        if (name != null && name.isNotEmpty) {
                          await ref.read(vaultCollectionRepositoryProvider).renameCollection(collection.id, name);
                        }
                      case 'delete':
                        await ref.read(vaultCollectionRepositoryProvider).deleteCollection(collection.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva colección',
        onPressed: () async {
          final name = await _promptName(context, 'Nueva colección');
          if (name != null && name.isNotEmpty) {
            await ref.read(vaultCollectionRepositoryProvider).createCollection(name);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SmartAlbumsTab extends ConsumerWidget {
  const _SmartAlbumsTab();

  String _categoryLabel(FileCategory? category) => switch (category) {
        null => 'Cualquier categoría',
        FileCategory.video => 'Videos',
        FileCategory.audio => 'Música',
        FileCategory.image => 'Fotos',
        FileCategory.pdf => 'PDF',
        FileCategory.generic => 'Documentos',
      };

  Future<void> _createSmartAlbum(BuildContext context, WidgetRef ref) async {
    final tags = await ref.read(vaultTagRepositoryProvider).watchTags().first;
    if (!context.mounted) return;

    final nameController = TextEditingController();
    FileCategory? category;
    bool favoritesOnly = false;
    String? tagId;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo álbum inteligente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(hintText: 'Nombre')),
              const SizedBox(height: 16),
              DropdownButton<FileCategory?>(
                value: category,
                isExpanded: true,
                items: [
                  for (final option in [null, ...FileCategory.values])
                    DropdownMenuItem(value: option, child: Text(_categoryLabel(option))),
                ],
                onChanged: (value) => setState(() => category = value),
              ),
              if (tags.isNotEmpty)
                DropdownButton<String?>(
                  value: tagId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Cualquier etiqueta')),
                    for (final tag in tags) DropdownMenuItem(value: tag.id, child: Text(tag.name)),
                  ],
                  onChanged: (value) => setState(() => tagId = value),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo favoritos'),
                value: favoritesOnly,
                onChanged: (value) => setState(() => favoritesOnly = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Crear')),
          ],
        ),
      ),
    );

    if (created != true || nameController.text.trim().isEmpty) return;
    await ref.read(vaultSmartAlbumRepositoryProvider).createSmartAlbum(
          name: nameController.text.trim(),
          categoryFilter: category,
          favoritesOnly: favoritesOnly,
          tagId: tagId,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(vaultSmartAlbumsStreamProvider);
    return Scaffold(
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (albums) {
          if (albums.isEmpty) {
            return const EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'Sin álbumes inteligentes',
              subtitle: 'Crea uno con un criterio (categoría, favoritos, etiqueta) y se actualizará solo.',
            );
          }
          return ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text(album.name),
                subtitle: Text(_categoryLabel(album.categoryFilter) + (album.favoritesOnly ? ' · Favoritos' : '')),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SmartAlbumFilesScreen(album: album)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(vaultSmartAlbumRepositoryProvider).deleteSmartAlbum(album.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo álbum inteligente',
        onPressed: () => _createSmartAlbum(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
