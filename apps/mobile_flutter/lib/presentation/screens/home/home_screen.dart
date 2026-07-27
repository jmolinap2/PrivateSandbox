import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/library/library_filter.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/file_category.dart';
import '../../../domain/entities/vault_file.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/selected_tab_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vault_thumbnail.dart';
import '../import/import_flow.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openLibrary(WidgetRef ref, {FileCategory? category, bool favoritesOnly = false}) {
    final notifier = ref.read(libraryFilterProvider.notifier);
    notifier.reset();
    if (category != null) notifier.setCategory(category);
    if (favoritesOnly) notifier.setFavoritesOnly(true);
    ref.read(selectedTabIndexProvider.notifier).set(1);
  }

  String _totalSizeLabel(List<VaultFile> files) {
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final mb = totalBytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filesAsync = ref.watch(vaultFilesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('PrivateSandbox'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(authControllerProvider.notifier).lock(),
          ),
        ],
      ),
      body: filesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (files) {
          final byCategory = <FileCategory, List<VaultFile>>{
            for (final category in FileCategory.values) category: files.where((f) => f.category == category).toList(),
          };
          final recent = files.take(6).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 40, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bóveda desbloqueada', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '${files.length} archivo${files.length == 1 ? '' : 's'} · ${_totalSizeLabel(files)}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _CategoryCard(
                    label: 'Videos',
                    icon: Icons.movie_outlined,
                    color: Colors.purpleAccent,
                    files: byCategory[FileCategory.video]!,
                    onTap: () => _openLibrary(ref, category: FileCategory.video),
                  ),
                  _CategoryCard(
                    label: 'Música',
                    icon: Icons.audiotrack_outlined,
                    color: Colors.pinkAccent,
                    files: byCategory[FileCategory.audio]!,
                    onTap: () => _openLibrary(ref, category: FileCategory.audio),
                  ),
                  _CategoryCard(
                    label: 'Fotos',
                    icon: Icons.image_outlined,
                    color: Colors.lightBlueAccent,
                    files: byCategory[FileCategory.image]!,
                    onTap: () => _openLibrary(ref, category: FileCategory.image),
                  ),
                  _CategoryCard(
                    label: 'Documentos',
                    icon: Icons.description_outlined,
                    color: Colors.greenAccent,
                    files: [...byCategory[FileCategory.pdf]!, ...byCategory[FileCategory.generic]!],
                    onTap: () => _openLibrary(ref, category: FileCategory.pdf),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => pickAndImportFiles(context, ref),
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Importar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openLibrary(ref, favoritesOnly: true),
                      icon: const Icon(Icons.star_border),
                      label: const Text('Favoritos'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recientes', style: theme.textTheme.titleMedium),
                  TextButton(
                    onPressed: () => _openLibrary(ref),
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Tu bóveda está vacía',
                  subtitle: 'Importa fotos, videos, audio, PDF o cualquier archivo para guardarlo cifrado.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: recent.length,
                  itemBuilder: (context, index) {
                    final file = recent[index];
                    return _RecentTile(file: file);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<VaultFile> files;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.files,
    required this.onTap,
  });

  String get _sizeLabel {
    final mb = files.fold<int>(0, (sum, f) => sum + f.sizeBytes) / (1024 * 1024);
    return mb < 1024 ? '${mb.toStringAsFixed(1)} MB' : '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(label, style: theme.textTheme.titleSmall),
              Text(
                '${files.length} archivos · $_sizeLabel',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final VaultFile file;

  const _RecentTile({required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push(AppRoutes.viewerFor(file.id)),
        child: VaultThumbnail(file: file, iconSize: 28),
      ),
    );
  }
}
