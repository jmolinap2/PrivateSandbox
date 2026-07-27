import '../entities/vault_file.dart';

abstract interface class VaultRepository {
  /// Emits the list of fully-imported, non-trashed files, most recent first.
  Stream<List<VaultFile>> watchFiles();

  /// Emits files currently in the trash, most recently trashed first.
  Stream<List<VaultFile>> watchTrashedFiles();

  /// Emits non-trashed files filed directly under [folderId] (null for
  /// unfiled/root files), most recent first.
  Stream<List<VaultFile>> watchFilesInFolder(String? folderId);

  Future<VaultFile?> getById(String id);

  /// Includes active, trashed and interrupted rows. Used before unlocking to
  /// decide whether creating a new master key would be destructive.
  Future<bool> hasStoredFiles();

  /// Files left in [ImportStatus.importing] by a previous run — candidates
  /// for cleanup by the recovery use case.
  Future<List<VaultFile>> getInterruptedImports();

  /// Registers a file as "importing" before any bytes are encrypted, so an
  /// interruption mid-import can be detected and cleaned up on next launch.
  Future<void> insertFile(VaultFile file);

  /// Persists the verified content hash and advances the import to its
  /// recoverable commit point. Once this succeeds, crash recovery must never
  /// discard the ciphertext.
  Future<void> markImportVerified({
    required String id,
    required String sha256Hash,
  });

  /// Marks an import as finished once the ciphertext has been written and
  /// its integrity verified.
  Future<void> completeImport({
    required String id,
    required String sha256Hash,
    required bool originalDeleted,
  });

  /// Removes the DB row. Callers are responsible for deleting the
  /// corresponding ciphertext blob from disk. Used for permanent deletion —
  /// everyday "delete" from the library should go through [moveToTrash]
  /// instead.
  Future<void> deleteFile(String id);

  /// Hides the file from the library without touching its ciphertext —
  /// the "papelera privada" the file can still be recovered from.
  Future<void> moveToTrash(String id);

  /// Brings a trashed file back into the active library.
  Future<void> restoreFromTrash(String id);

  /// Files a file under [folderId], or clears it back to "unfiled" if null.
  Future<void> moveFileToFolder(String id, String? folderId);

  Future<void> setFavorite(String id, bool isFavorite);

  /// Records that [id] was opened just now, and (for audio/video) its
  /// last playback position so playback can resume from there.
  Future<void> recordOpened(String id, {int? playbackPositionMs});

  Future<void> setThumbnail(String id, {required String fileName, required String noncePrefixBase64});
}
