import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../application/providers.dart';
import '../../../application/vault/restore_use_case.dart';
import '../../../domain/entities/vault_file.dart';
import '../../../infrastructure/storage/vault_paths.dart';

/// Tries to put [file] back exactly where it came from first; only asks the
/// user to pick a folder when that's genuinely not possible (e.g. the file
/// was imported from the file explorer, its original was deleted, and the
/// app never held folder-level access to recreate it there) — satisfies the
/// plan's "exportación y restauración de archivos" without pretending a
/// silent folder-drop is the same thing as restoring.
Future<void> restoreVaultFile(BuildContext context, WidgetRef ref, VaultFile file) async {
  final result = await ref.read(restoreUseCaseProvider).call(file);

  if (result == RestoreResult.restoredToOriginal) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurado en su ubicación original.')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ubicación original no disponible'),
      content: const Text(
        'No se pudo restaurar el archivo en su ubicación original: la carpeta o el archivo original ya no '
        'existen, o se importó desde el explorador de archivos y Android no permite recrearlo sin acceso '
        'a esa carpeta. ¿Quieres elegir una carpeta para guardarlo?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Elegir carpeta')),
      ],
    ),
  );
  if (proceed != true || !context.mounted) return;

  await _exportToChosenFolder(context, ref, file);
}

Future<void> _exportToChosenFolder(BuildContext context, WidgetRef ref, VaultFile file) async {
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
          Expanded(child: Text('Restaurando…')),
        ],
      ),
    ),
  );

  String message;
  try {
    await ref.read(exportUseCaseProvider).call(file: file, destinationDir: Directory(destinationPath));
    await _removeFromVault(ref, file);
    message = 'Archivo restaurado correctamente.';
  } catch (_) {
    message = 'No se pudo restaurar el archivo.';
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Same vault cleanup [RestoreUseCase] does after restoring to the original
/// location — kept separate here since [ExportUseCase] already logs its own
/// "exported" activity event, and going through `DeleteFileUseCase` would
/// add a second, misleading "eliminado" entry for what the user did as one
/// "restaurar" action.
Future<void> _removeFromVault(WidgetRef ref, VaultFile file) async {
  final blobsDir = await VaultPaths.vaultBlobsDir();

  final blob = File(p.join(blobsDir.path, file.encryptedFileName));
  if (await blob.exists()) {
    await blob.delete();
  }

  final thumbnailFileName = file.thumbnailFileName;
  if (thumbnailFileName != null) {
    final thumbBlob = File(p.join(blobsDir.path, thumbnailFileName));
    if (await thumbBlob.exists()) {
      await thumbBlob.delete();
    }
  }

  await ref.read(vaultRepositoryProvider).deleteFile(file.id);
}
