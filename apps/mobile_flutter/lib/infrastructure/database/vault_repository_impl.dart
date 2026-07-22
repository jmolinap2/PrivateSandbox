import 'package:drift/drift.dart';

import '../../domain/entities/file_category.dart';
import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/vault_repository.dart';
import 'app_database.dart';

class VaultRepositoryImpl implements VaultRepository {
  final AppDatabase _db;

  VaultRepositoryImpl(this._db);

  @override
  Stream<List<VaultFile>> watchFiles() {
    final query = _db.select(_db.vaultFiles)
      ..where((t) => t.status.equals(ImportStatus.completed.name))
      ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<VaultFile?> getById(String id) async {
    final row = await (_db.select(_db.vaultFiles)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<VaultFile>> getInterruptedImports() async {
    final rows = await (_db.select(_db.vaultFiles)..where((t) => t.status.equals(ImportStatus.importing.name))).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> insertFile(VaultFile file) {
    return _db.into(_db.vaultFiles).insert(_toCompanion(file));
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
    return (_db.delete(_db.vaultFiles)..where((t) => t.id.equals(id))).go();
  }

  VaultFile _toEntity(VaultFileRow row) {
    return VaultFile(
      id: row.id,
      originalName: row.originalName,
      extension: row.extension,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      originalPath: row.originalPath,
      importedAt: row.importedAt,
      fileModifiedAt: row.fileModifiedAt,
      category: FileCategory.values.byName(row.category),
      status: ImportStatus.values.byName(row.status),
      encryptedFileName: row.encryptedFileName,
      fileSaltBase64: row.fileSaltBase64,
      noncePrefixBase64: row.noncePrefixBase64,
      sha256Hash: row.sha256Hash,
      originalDeleted: row.originalDeleted,
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
      importedAt: file.importedAt,
      fileModifiedAt: Value(file.fileModifiedAt),
      category: file.category.name,
      status: file.status.name,
      encryptedFileName: file.encryptedFileName,
      fileSaltBase64: file.fileSaltBase64,
      noncePrefixBase64: file.noncePrefixBase64,
      sha256Hash: Value(file.sha256Hash),
      originalDeleted: Value(file.originalDeleted),
    );
  }
}
