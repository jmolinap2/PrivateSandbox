import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/providers.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vault_file_tile.dart';
import '../import/import_sheet.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  Future<void> _pickAndImport(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final pickedFile = result.files.single;

    if (!context.mounted) return;
    final deleteOriginal = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar original'),
        content: const Text(
          '¿Quieres eliminar el archivo original después de importarlo a la bóveda? '
          'Esto no siempre es posible según de dónde provenga el archivo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Conservar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (deleteOriginal == null || !context.mounted) return;

    await runImportFlow(context, ref, pickedFile: pickedFile, deleteOriginal: deleteOriginal);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bóveda privada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(authControllerProvider.notifier).lock(),
          ),
        ],
      ),
      body: filesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar la bóveda: $error')),
        data: (files) {
          if (files.isEmpty) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Tu bóveda está vacía',
              subtitle: 'Importa fotos, videos, audio, PDF o cualquier archivo para guardarlo cifrado.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return VaultFileTile(
                file: file,
                onTap: () => context.push(AppRoutes.viewerFor(file.id)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndImport(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Importar'),
      ),
    );
  }
}
