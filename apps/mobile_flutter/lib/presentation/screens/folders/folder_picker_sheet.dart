import 'package:flutter/material.dart';

import '../../../domain/entities/vault_folder.dart';

class FolderChoice {
  const FolderChoice(this.folderId);
  final String? folderId;
}

/// Flat, indented tree of every folder, for picking a destination when
/// moving a file — used both from the folder browser and from the flat
/// Biblioteca list, so it works without knowing "where you currently are".
class FolderPickerSheet extends StatelessWidget {
  const FolderPickerSheet({required this.folders, required this.currentFolderId, super.key});

  final List<VaultFolder> folders;
  final String? currentFolderId;

  int _depthOf(VaultFolder folder, Map<String, VaultFolder> byId) {
    var depth = 0;
    var current = folder;
    while (current.parentId != null) {
      final parent = byId[current.parentId];
      if (parent == null) break;
      depth++;
      current = parent;
    }
    return depth;
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final folder in folders) folder.id: folder};
    final sorted = [...folders]..sort((a, b) {
        final depthCompare = _depthOf(a, byId).compareTo(_depthOf(b, byId));
        return depthCompare != 0 ? depthCompare : a.name.compareTo(b.name);
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Sin carpeta'),
              selected: currentFolderId == null,
              onTap: () => Navigator.of(context).pop(const FolderChoice(null)),
            ),
            for (final folder in sorted)
              Padding(
                padding: EdgeInsets.only(left: 16.0 * _depthOf(folder, byId)),
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  selected: currentFolderId == folder.id,
                  onTap: () => Navigator.of(context).pop(FolderChoice(folder.id)),
                ),
              ),
          ],
        );
      },
    );
  }
}
