import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';

/// Lets the user pick a destination folder (via the Storage Access
/// Framework, so no storage permission is required) and decrypts the file
/// there, satisfying the plan's "exportación y restauración de archivos".
Future<void> exportVaultFile(BuildContext context, WidgetRef ref, VaultFile file) async {
  final destinationPath = await FilePicker.getDirectoryPath();
  if (destinationPath == null || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 24),
          Expanded(child: Text('Exportando…')),
        ],
      ),
    ),
  );

  String message;
  try {
    await ref.read(exportUseCaseProvider).call(file: file, destinationDir: Directory(destinationPath));
    message = 'Archivo exportado correctamente.';
  } catch (_) {
    message = 'No se pudo exportar el archivo.';
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
