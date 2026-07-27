import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/vault_file.dart';

/// Multi-select sheet for adding/removing [file] from collections —
/// mirrors [TagAssignmentSheet]'s toggle-applies-immediately behavior.
class CollectionAssignmentSheet extends ConsumerWidget {
  const CollectionAssignmentSheet({required this.file, super.key});

  final VaultFile file;

  Future<void> _createAndAssign(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva colección'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Crear')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final collectionId = await ref.read(vaultCollectionRepositoryProvider).createCollection(name);
    await ref.read(vaultCollectionRepositoryProvider).addFileToCollection(file.id, collectionId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCollectionsAsync = ref.watch(vaultCollectionsStreamProvider);
    final assignedCollectionsAsync = ref.watch(vaultCollectionsForFileStreamProvider(file.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return allCollectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (allCollections) {
            final assignedIds = assignedCollectionsAsync.value?.map((c) => c.id).toSet() ?? const <String>{};
            return ListView(
              controller: scrollController,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Nueva colección'),
                  onTap: () => _createAndAssign(context, ref),
                ),
                for (final collection in allCollections)
                  CheckboxListTile(
                    title: Text(collection.name),
                    value: assignedIds.contains(collection.id),
                    onChanged: (checked) {
                      final collectionRepo = ref.read(vaultCollectionRepositoryProvider);
                      if (checked == true) {
                        collectionRepo.addFileToCollection(file.id, collection.id);
                      } else {
                        collectionRepo.removeFileFromCollection(file.id, collection.id);
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
