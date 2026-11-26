import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/library/library_filter.dart';
import '../../../application/library/library_view_mode.dart';
import '../../../domain/entities/file_category.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vault_file_list_tile.dart';
import '../../widgets/vault_file_tile.dart';
import '../folders/folders_screen.dart';
import '../import/import_flow.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryLabel(FileCategory? category) => switch (category) {
        null => 'Todos',
        FileCategory.video => 'Videos',
        FileCategory.audio => 'Música',
        FileCategory.image => 'Fotos',
        FileCategory.pdf => 'PDF',
        FileCategory.generic => 'Documentos',
      };

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(libraryFilterProvider);
    final files = ref.watch(filteredLibraryProvider);
    final notifier = ref.read(libraryFilterProvider.notifier);
    final viewMode = ref.watch(libraryViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: Icon(viewMode == LibraryViewMode.list ? Icons.grid_view_outlined : Icons.view_list_outlined),
            tooltip: viewMode == LibraryViewMode.list ? 'Ver como cuadrícula' : 'Ver como lista',
            onPressed: () => ref.read(libraryViewModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Carpetas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FoldersScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar en la biblioteca…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setQuery,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final category in [null, ...FileCategory.values])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(_categoryLabel(category)),
                      selected: filter.category == category,
                      onSelected: (_) => notifier.setCategory(category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Favoritos'),
                    avatar: const Icon(Icons.star, size: 18),
                    selected: filter.favoritesOnly,
                    onSelected: notifier.setFavoritesOnly,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('Recientes'),
                    selected: filter.sort == LibrarySort.recent,
                    onSelected: (_) => notifier.setSort(LibrarySort.recent),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('Nombre'),
                    selected: filter.sort == LibrarySort.name,
                    onSelected: (_) => notifier.setSort(LibrarySort.name),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: files.isEmpty
                ? const EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'Sin resultados',
                    subtitle: 'Nada coincide con los filtros actuales.',
                  )
                : Builder(
                    builder: (context) {
                      final queueIds = [for (final f in files) f.id];
                      if (viewMode == LibraryViewMode.grid) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return VaultFileTile(
                              file: file,
                              onTap: () => context.push(AppRoutes.viewerFor(file.id), extra: queueIds),
                            );
                          },
                        );
                      }
                      return ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          return VaultFileListTile(
                            file: file,
                            onTap: () => context.push(AppRoutes.viewerFor(file.id), extra: queueIds),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pickAndImportFiles(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Importar'),
      ),
    );
  }
}
