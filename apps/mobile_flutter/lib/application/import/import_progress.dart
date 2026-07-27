enum ImportStage { encrypting, verifying, savingMetadata, done, failed, cancelled }

class ImportProgress {
  final ImportStage stage;
  final String fileName;

  const ImportProgress(this.stage, this.fileName);
}
