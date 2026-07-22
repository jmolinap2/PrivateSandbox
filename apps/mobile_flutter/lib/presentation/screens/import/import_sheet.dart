import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/import/import_progress.dart';
import '../../../application/providers.dart';
import '../../../shared/errors/vault_exceptions.dart';

/// Runs [ImportUseCase] for a single picked file and shows its progress in
/// a bottom sheet. Returns true if the import finished successfully.
Future<bool> runImportFlow(
  BuildContext context,
  WidgetRef ref, {
  required PlatformFile pickedFile,
  required bool deleteOriginal,
}) async {
  final completer = ValueNotifier<ImportProgress?>(null);
  Object? failure;

  final future = ref.read(importUseCaseProvider).call(
        pickedFile: pickedFile,
        deleteOriginal: deleteOriginal,
      ).forEach((progress) {
    completer.value = progress;
  }).catchError((Object e) {
    failure = e;
  });

  if (!context.mounted) return false;
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (context) {
      return ValueListenableBuilder<ImportProgress?>(
        valueListenable: completer,
        builder: (context, progress, _) {
          final stage = progress?.stage;
          final label = switch (stage) {
            null => 'Preparando…',
            ImportStage.encrypting => 'Cifrando archivo…',
            ImportStage.verifying => 'Verificando integridad…',
            ImportStage.savingMetadata => 'Guardando…',
            ImportStage.done => 'Completado',
            ImportStage.failed => 'Error al importar',
          };
          final isDone = stage == ImportStage.done || stage == ImportStage.failed;
          if (isDone) {
            Future.microtask(() {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stage != ImportStage.done && stage != ImportStage.failed)
                    const CircularProgressIndicator()
                  else
                    Icon(
                      stage == ImportStage.done ? Icons.check_circle : Icons.error,
                      color: stage == ImportStage.done ? Colors.green : Theme.of(context).colorScheme.error,
                      size: 40,
                    ),
                  const SizedBox(height: 16),
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (progress != null) ...[
                    const SizedBox(height: 4),
                    Text(progress.fileName, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );

  await future;
  if (failure != null) {
    final message = failure is VaultException ? failure.toString() : 'No se pudo importar el archivo.';
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  }
  return true;
}
