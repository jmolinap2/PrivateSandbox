import 'package:drift/drift.dart';

import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/vault_repository.dart';
import 'app_database.dart';
import 'vault_file_mapper.dart';

class VaultRepositoryImpl implements VaultRepository {
  final AppDatabase _db;

  VaultRepositoryImpl(this._db);

  @override
  Stream<List<VaultFile>> watchFiles() {
    final query = _db.select(_db.vaultFiles)
      ..where((t) => t.status.equals(ImportStatus.completed.name) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]);
    return query.watch().map((rows) => rows.map(mapVaultFileRow).toList());
  }

  @override
  Stream<List<VaultFile>> watchTrashedFiles() {
    final query = _db.select(_db.vaultFiles)
      ..where((t) => t.status.equals(ImportStatus.completed.name) & t.deletedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]);
    return query.watch().map((rows) => rows.map(mapVaultFileRow).toList());
  }

  @override
  Stream<List<VaultFile>> watchFilesInFolder(String? folderId) {
    final query = _db.select(_db.vaultFiles)
      ..where(
        (t) =>
            t.status.equals(ImportStatus.completed.name) &
            t.deletedAt.isNull() &
            (folderId == null ? t.folderId.isNull() : t.folderId.equals(folderId)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]);
    return query.watch().map((rows) => rows.map(mapVaultFileRow).toList());
  }

  @override
  Future<VaultFile?> getById(String id) async {
    final row = await (_db.select(_db.vaultFiles)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapVaultFileRow(row);
  }

  @override
  Future<bool> hasStoredFiles() async {
    final row = await (_db.select(_db.vaultFiles)..limit(1)).getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<VaultFile>> getInterruptedImports() async {
    final rows = await (_db.select(_db.vaultFiles)
          ..where((t) => t.status.isNotValue(ImportStatus.completed.name)))
        .get();
    return rows.map(mapVaultFileRow).toList();
  }

  @override
  Future<void> insertFile(VaultFile file) {
    return _db.into(_db.vaultFiles).insert(_toCompanion(file));
  }

  @override
  Future<void> markImportVerified({
    required String id,
    required String sha256Hash,
  }) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(
        status: Value(ImportStatus.verified.name),
        sha256Hash: Value(sha256Hash),
      ),
    );
  }

  @override
  Future<void> completeImport({
    required String id,
    required String sha256Hash,
    required bool originalDeleted,
  }) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(
        status: Value(ImportStatus.completed.name),
        sha256Hash: Value(sha256Hash),
        originalDeleted: Value(originalDeleted),
      ),
    );
  }

  @override
  Future<void> deleteFile(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.vaultFileTags)..where((t) => t.fileId.equals(id))).go();
      await (_db.delete(_db.vaultCollectionFiles)..where((t) => t.fileId.equals(id))).go();
      await (_db.delete(_db.vaultFiles)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> moveToTrash(String id) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> restoreFromTrash(String id) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      const VaultFilesCompanion(deletedAt: Value(null)),
    );
  }

  @override
  Future<void> moveFileToFolder(String id, String? folderId) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(folderId: Value(folderId)),
    );
  }

  @override
  Future<void> setFavorite(String id, bool isFavorite) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(isFavorite: Value(isFavorite)),
    );
  }

  @override
  Future<void> recordOpened(String id, {int? playbackPositionMs}) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(
        lastOpenedAt: Value(DateTime.now()),
        playbackPositionMs: playbackPositionMs == null ? const Value.absent() : Value(playbackPositionMs),
      ),
    );
  }

  @override
  Future<void> setThumbnail(String id, {required String fileName, required String noncePrefixBase64}) {
    return (_db.update(_db.vaultFiles)..where((t) => t.id.equals(id))).write(
      VaultFilesCompanion(
        thumbnailFileName: Value(fileName),
        thumbnailNoncePrefixBase64: Value(noncePrefixBase64),
      ),
    );
  }

  VaultFilesCompanion _toCompanion(VaultFile file) {
    return VaultFilesCompanion.insert(
      id: file.id,
      originalName: file.originalName,
      extension: file.extension,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes,
      originalPath: Value(file.originalPath),
      originalContentUri: Value(file.originalContentUri),
      originalRelativePath: Value(file.originalRelativePath),
      originalTreeUri: Value(file.originalTreeUri),
      originalTreeRelativePath: Value(file.originalTreeRelativePath),
      importedAt: file.importedAt,
      fileModifiedAt: Value(file.fileModifiedAt),
      originalCreatedAt: Value(file.originalCreatedAt),
      originalAccessedAt: Value(file.originalAccessedAt),
      originalMetadataJson: Value(file.originalMetadataJson),
      category: file.category.name,
      status: file.status.name,
      encryptedFileName: file.encryptedFileName,
      fileSaltBase64: file.fileSaltBase64,
      noncePrefixBase64: file.noncePrefixBase64,
      sha256Hash: Value(file.sha256Hash),
      originalDeleted: Value(file.originalDeleted),
      isFavorite: Value(file.isFavorite),
      lastOpenedAt: Value(file.lastOpenedAt),
      playbackPositionMs: Value(file.playbackPositionMs),
      thumbnailFileName: Value(file.thumbnailFileName),
      thumbnailNoncePrefixBase64: Value(file.thumbnailNoncePrefixBase64),
      deletedAt: Value(file.deletedAt),
      folderId: Value(file.folderId),
    );
  }
}
