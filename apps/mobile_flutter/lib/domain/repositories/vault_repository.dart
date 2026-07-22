import '../entities/vault_file.dart';

abstract interface class VaultRepository {
  /// Emits the list of fully-imported files, most recent first.
  Stream<List<VaultFile>> watchFiles();

  Future<VaultFile?> getById(String id);

  /// Files left in [ImportStatus.importing] by a previous run — candidates
  /// for cleanup by the recovery use case.
  Future<List<VaultFile>> getInterruptedImports();

  /// Registers a file as "importing" before any bytes are encrypted, so an
  /// interruption mid-import can be detected and cleaned up on next launch.
  Future<void> insertFile(VaultFile file);

  /// Marks an import as finished once the ciphertext has been written and
  /// its integrity verified.
  Future<void> completeImport({
    required String id,
    required String sha256Hash,
    required bool originalDeleted,
  });

  /// Removes the DB row. Callers are responsible for deleting the
  /// corresponding ciphertext blob from disk.
  Future<void> deleteFile(String id);
}
