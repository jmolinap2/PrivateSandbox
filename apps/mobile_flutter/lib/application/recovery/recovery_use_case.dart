import '../../domain/entities/import_status.dart';
import '../../domain/repositories/vault_repository.dart';
import '../import/active_import_registry.dart';
import '../vault/vault_file_lifecycle.dart';

/// Resolves imports interrupted at either side of the durable verification
/// boundary.
///
/// Draft [ImportStatus.importing] records are safe to roll back because the
/// source has not been deleted yet. [ImportStatus.verified] records are
/// instead promoted conservatively: their authenticated blob is the copy that
/// must survive even when the process died immediately after source deletion.
class RecoveryUseCase {
  final VaultRepository _vaultRepository;
  final VaultFileLifecycle _lifecycle;

  RecoveryUseCase(this._vaultRepository, {VaultFileLifecycle? lifecycle})
    : _lifecycle = lifecycle ?? VaultFileLifecycle(_vaultRepository);

  Future<int> recoverInterruptedImports() async {
    final interrupted = await _vaultRepository.getInterruptedImports();
    var recovered = 0;
    for (final file in interrupted) {
      if (ActiveImportRegistry.contains(file.id)) continue;
      try {
        switch (file.status) {
          case ImportStatus.importing:
            // Metadata first: if this commit fails, leave all bytes intact.
            await _lifecycle.deleteRecordThenArtifacts(file);
            recovered++;
            break;
          case ImportStatus.verified:
            if (!await _lifecycle.hasCompleteCiphertext(file)) {
              // Preserve the record for diagnostics/retry. Deleting it could
              // lose the only location metadata for an already-removed source.
              continue;
            }
            await _vaultRepository.completeImport(
              id: file.id,
              sha256Hash: file.sha256Hash,
              originalDeleted: false,
            );
            recovered++;
            break;
          case ImportStatus.completed:
            // getInterruptedImports must not return this state, but treating
            // it as a no-op makes recovery robust to repository changes.
            continue;
        }
      } catch (_) {
        // One damaged entry must not prevent recovery of independent files.
      }
    }
    await _lifecycle.cleanupOrphanedBlobs();
    return recovered;
  }
}
