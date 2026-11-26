enum ImportStage { encrypting, verifying, savingMetadata, done, failed, cancelled }

class ImportProgress {
  final ImportStage stage;
  final String fileName;

  /// Only on [ImportStage.done]: the vault row just completed, so a batch
  /// runner can later mark its original as deleted.
  final String? vaultFileId;
  final String? sha256Hash;

  /// Only on [ImportStage.done] when gallery deletion was deferred: the
  /// asset whose original still has to be deleted by the caller, in one
  /// batch (a single system consent prompt instead of one per file).
  final String? deferredGalleryAssetId;

  const ImportProgress(
    this.stage,
    this.fileName, {
    this.vaultFileId,
    this.sha256Hash,
    this.deferredGalleryAssetId,
  });
}
