import 'package:flutter/material.dart';

enum ImportSource { gallery, filesystem }

/// Lets the user choose between the vault's own photos/videos grid
/// ("Galería", backed by MediaStore — needed so originals can actually be
/// deleted after import) and the generic file explorer ("Explorador de
/// archivos" — any file type, including audio, PDFs and documents).
Future<ImportSource?> showImportSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImportSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Importar desde'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              subtitle: const Text('Fotos y videos del dispositivo'),
              onTap: () => Navigator.of(context).pop(ImportSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Explorador de archivos'),
              subtitle: const Text('Cualquier tipo, incluyendo audio, PDF y documentos'),
              onTap: () => Navigator.of(context).pop(ImportSource.filesystem),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
