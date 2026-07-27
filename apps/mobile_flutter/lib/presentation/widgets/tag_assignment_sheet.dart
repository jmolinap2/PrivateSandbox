import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/vault_file.dart';

/// Multi-select sheet for assigning/unassigning tags on [file] — toggling a
/// tag applies immediately (no separate "save" step), same as favoriting.
class TagAssignmentSheet extends ConsumerWidget {
  const TagAssignmentSheet({required this.file, super.key});

  final VaultFile file;

  Future<void> _createAndAssign(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva etiqueta'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Crear')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final tag = await ref.read(vaultTagRepositoryProvider).getOrCreateTag(name);
    await ref.read(vaultTagRepositoryProvider).addTagToFile(file.id, tag.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTagsAsync = ref.watch(vaultTagsStreamProvider);
    final assignedTagsAsync = ref.watch(vaultTagsForFileStreamProvider(file.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return allTagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (allTags) {
            final assignedIds = assignedTagsAsync.value?.map((t) => t.id).toSet() ?? const <String>{};
            return ListView(
              controller: scrollController,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Nueva etiqueta'),
                  onTap: () => _createAndAssign(context, ref),
                ),
                for (final tag in allTags)
                  CheckboxListTile(
                    title: Text(tag.name),
                    value: assignedIds.contains(tag.id),
                    onChanged: (checked) {
                      final tagRepo = ref.read(vaultTagRepositoryProvider);
                      if (checked == true) {
                        tagRepo.addTagToFile(file.id, tag.id);
                      } else {
                        tagRepo.removeTagFromFile(file.id, tag.id);
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
