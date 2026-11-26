import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../application/import/import_progress.dart';
import '../../../application/import/picked_file.dart';
import '../../../application/providers.dart';

class ImportBatchResult {
  final int succeeded;
  final int failed;
  final int cancelled;

  const ImportBatchResult({required this.succeeded, required this.failed, this.cancelled = 0});
}

class _FileImportState {
  final PickedFile file;
  ImportStage? stage;
  bool failed = false;

  _FileImportState(this.file);

  bool get isCancelled => stage == ImportStage.cancelled;
  bool get isDone => stage == ImportStage.done;
  bool get isFinished => isDone || isCancelled || failed;
}

/// Mutable flag shared between the progress sheet's "Cancelar" button and the
/// import batch loop / cipher, so a tap aborts the in-flight file and skips
/// the rest.
class _CancelToken {
  bool cancelled = false;
}

/// Runs [ImportUseCase] for every file in [pickedFiles], sequentially, and
/// shows a live per-file progress list in a bottom sheet until they're all
/// done (or failed).
Future<ImportBatchResult> runImportFlow(
  BuildContext context,
  WidgetRef ref, {
  required List<PickedFile> pickedFiles,
  required bool deleteOriginal,
}) async {
  final states = pickedFiles.map((f) => _FileImportState(f)).toList();
  final tick = ValueNotifier<int>(0);
  final cancelToken = _CancelToken();

  // Gallery originals whose deletion is deferred to a single batch call.
  final deferredDeletions = <({String assetId, String vaultFileId, String sha256Hash})>[];

  Future<void> deleteDeferredOriginals() async {
    if (deferredDeletions.isEmpty) return;
    try {
      final deleted = (await PhotoManager.editor.deleteWithIds(
        [for (final d in deferredDeletions) d.assetId],
      )).toSet();
      final repository = ref.read(vaultRepositoryProvider);
      for (final d in deferredDeletions.where((d) => deleted.contains(d.assetId))) {
        await repository.completeImport(
          id: d.vaultFileId,
          sha256Hash: d.sha256Hash,
          originalDeleted: true,
        );
      }
    } catch (_) {
      // Same policy as the per-file path: a failed delete is not an import
      // failure; the originals just stay where they are.
    }
  }

  Future<void> runAll() async {
    for (final state in states) {
      // Files not yet started when the user cancels are marked cancelled
      // without ever touching the cipher.
      if (cancelToken.cancelled) {
        state.stage = ImportStage.cancelled;
        tick.value++;
        continue;
      }
      try {
        await ref
            .read(importUseCaseProvider)
            .call(
              pickedFile: state.file,
              deleteOriginal: deleteOriginal,
              deferGalleryDeletion: true,
              isCancelled: () => cancelToken.cancelled,
            )
            .forEach((progress) {
          state.stage = progress.stage;
          final assetId = progress.deferredGalleryAssetId;
          if (assetId != null && progress.vaultFileId != null && progress.sha256Hash != null) {
            deferredDeletions.add((
              assetId: assetId,
              vaultFileId: progress.vaultFileId!,
              sha256Hash: progress.sha256Hash!,
            ));
          }
          tick.value++;
        });
      } catch (_) {
        state.failed = true;
        tick.value++;
      }
    }
    await deleteDeferredOriginals();
  }

  final future = runAll();

  if (context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (context, _, _) {
            final allDone = states.every((s) => s.isFinished);
            if (allDone) {
              Future.microtask(() {
                if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }
            final canCancel = !allDone && !cancelToken.cancelled;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        states.length == 1 ? 'Importando archivo' : 'Importando ${states.length} archivos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: states.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => _ImportRow(state: states[index]),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: canCancel
                              ? () {
                                  cancelToken.cancelled = true;
                                  tick.value++;
                                }
                              : null,
                          child: Text(cancelToken.cancelled ? 'Cancelando…' : 'Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  await future;

  final failedCount = states.where((s) => s.failed).length;
  final cancelledCount = states.where((s) => s.isCancelled).length;
  final succeededCount = states.where((s) => s.isDone).length;

  if (context.mounted) {
    final String message;
    if (cancelledCount > 0) {
      message = succeededCount == 0
          ? 'Importación cancelada.'
          : 'Cancelado. $succeededCount importado(s), $cancelledCount cancelado(s).';
    } else if (failedCount == 0) {
      message = succeededCount == 1 ? 'Archivo importado.' : '$succeededCount archivos importados.';
    } else {
      message = '$succeededCount importado(s), $failedCount con error.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  return ImportBatchResult(succeeded: succeededCount, failed: failedCount, cancelled: cancelledCount);
}

class _ImportRow extends StatelessWidget {
  final _FileImportState state;

  const _ImportRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (state.stage) {
      null => 'En espera…',
      ImportStage.encrypting => 'Cifrando…',
      ImportStage.verifying => 'Verificando…',
      ImportStage.savingMetadata => 'Guardando…',
      ImportStage.done => 'Completado',
      ImportStage.failed => 'Error',
      ImportStage.cancelled => 'Cancelado',
    };

    Widget leading;
    if (state.failed) {
      leading = Icon(Icons.error, color: theme.colorScheme.error);
    } else if (state.isCancelled) {
      leading = Icon(Icons.cancel_outlined, color: theme.colorScheme.outline);
    } else if (state.isDone) {
      leading = const Icon(Icons.check_circle, color: Colors.green);
    } else {
      leading = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
