import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/import/picked_file.dart';
import '../../../application/providers.dart';
import 'folder_access_resolver.dart';
import 'gallery_picker_screen.dart';
import 'import_sheet.dart';
import 'import_source_sheet.dart';

/// Full entry point for importing into the vault: choose a source (gallery
/// vs. generic file explorer), pick one or more files, confirm whether the
/// originals should be removed, then run the import batch. Shared by every
/// screen that offers an "Importar" action.
Future<void> pickAndImportFiles(BuildContext context, WidgetRef ref) async {
  final source = await showImportSourceSheet(context);
  if (source == null || !context.mounted) return;

  List<PickedFile> files;
  if (source == ImportSource.gallery) {
    final result = await Navigator.of(context).push<List<PickedFile>>(
      MaterialPageRoute(builder: (_) => const GalleryPickerScreen()),
    );
    files = result ?? const [];
  } else {
    final result = await FilePicker.pickFiles(type: FileType.any, allowMultiple: true);
    files = [
      for (final f in result?.files ?? const <PlatformFile>[])
        if (f.path != null) PickedFile(path: f.path!, name: f.name, size: f.size, contentUri: f.identifier),
    ];
  }
  if (files.isEmpty || !context.mounted) return;

  final preferences = ref.read(importPreferencesProvider);
  var confirmed = await preferences.getDeleteOriginalDefault();
  if (!context.mounted) return;
  if (confirmed == null) {
    final choice = await showDialog<_DeleteOriginalChoice>(
      context: context,
      builder: (context) => _DeleteOriginalDialog(fileCount: files.length),
    );
    if (choice == null || !context.mounted) return;
    confirmed = choice.deleteOriginal;
    if (choice.remember) await preferences.setDeleteOriginalDefault(confirmed);
  }
  if (!context.mounted) return;

  // Only explorer-sourced files whose original is about to be deleted need
  // a folder-tree grant resolved — gallery picks use MediaStore's relative
  // path instead, and kept originals can still be restored via their own
  // document URI, so neither needs it. This only reuses a grant the app
  // already holds; it never prompts (see folder_access_resolver.dart), so
  // it's safe to run silently over the whole batch here.
  if (confirmed) {
    files = [for (final file in files) await resolveFolderAccessIfNeeded(ref, file)];
  }
  if (!context.mounted) return;

  await runImportFlow(context, ref, pickedFiles: files, deleteOriginal: confirmed);
}

class _DeleteOriginalChoice {
  const _DeleteOriginalChoice({required this.deleteOriginal, required this.remember});

  final bool deleteOriginal;
  final bool remember;
}

class _DeleteOriginalDialog extends StatefulWidget {
  const _DeleteOriginalDialog({required this.fileCount});

  final int fileCount;

  @override
  State<_DeleteOriginalDialog> createState() => _DeleteOriginalDialogState();
}

class _DeleteOriginalDialogState extends State<_DeleteOriginalDialog> {
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar originales'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fileCount == 1
                ? '¿Quieres eliminar el archivo original después de importarlo a la bóveda?'
                : '¿Quieres eliminar los ${widget.fileCount} archivos originales después de importarlos a la bóveda?',
          ),
          CheckboxListTile(
            value: _remember,
            onChanged: (value) => setState(() => _remember = value ?? false),
            title: const Text('Recordar mi elección'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(_DeleteOriginalChoice(deleteOriginal: false, remember: _remember)),
          child: const Text('Conservar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(_DeleteOriginalChoice(deleteOriginal: true, remember: _remember)),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
