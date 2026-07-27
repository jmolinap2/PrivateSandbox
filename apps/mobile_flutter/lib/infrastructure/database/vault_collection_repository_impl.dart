import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_collection.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/vault_collection_repository.dart';
import 'app_database.dart';
import 'vault_file_mapper.dart';

class VaultCollectionRepositoryImpl implements VaultCollectionRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  VaultCollectionRepositoryImpl(this._db);

  @override
  Stream<List<VaultCollection>> watchCollections() {
    final query = _db.select(_db.vaultCollections)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<String> createCollection(String name) async {
    final id = _uuid.v4();
    await _db.into(_db.vaultCollections).insert(
          VaultCollectionsCompanion.insert(id: id, name: name.trim(), createdAt: DateTime.now()),
        );
    return id;
  }

  @override
  Future<void> renameCollection(String id, String newName) {
    return (_db.update(_db.vaultCollections)..where((t) => t.id.equals(id))).write(
      VaultCollectionsCompanion(name: Value(newName.trim())),
    );
  }

  @override
  Future<void> deleteCollection(String id) async {
    await (_db.delete(_db.vaultCollectionFiles)..where((t) => t.collectionId.equals(id))).go();
    await (_db.delete(_db.vaultCollections)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> addFileToCollection(String fileId, String collectionId) {
    return _db.into(_db.vaultCollectionFiles).insertOnConflictUpdate(
          VaultCollectionFilesCompanion.insert(collectionId: collectionId, fileId: fileId),
        );
  }

  @override
  Future<void> removeFileFromCollection(String fileId, String collectionId) {
    return (_db.delete(_db.vaultCollectionFiles)
          ..where((t) => t.fileId.equals(fileId) & t.collectionId.equals(collectionId)))
        .go();
  }

  @override
  Stream<List<VaultCollection>> watchCollectionsForFile(String fileId) {
    final query = _db.select(_db.vaultCollections).join([
      innerJoin(_db.vaultCollectionFiles, _db.vaultCollectionFiles.collectionId.equalsExp(_db.vaultCollections.id)),
    ])
      ..where(_db.vaultCollectionFiles.fileId.equals(fileId))
      ..orderBy([OrderingTerm.desc(_db.vaultCollections.createdAt)]);
    return query.watch().map((rows) => rows.map((row) => _toEntity(row.readTable(_db.vaultCollections))).toList());
  }

  @override
  Stream<List<VaultFile>> watchFilesInCollection(String collectionId) {
    final query = _db.select(_db.vaultFiles).join([
      innerJoin(_db.vaultCollectionFiles, _db.vaultCollectionFiles.fileId.equalsExp(_db.vaultFiles.id)),
    ])
      ..where(
        _db.vaultCollectionFiles.collectionId.equals(collectionId) &
            _db.vaultFiles.status.equals(ImportStatus.completed.name) &
            _db.vaultFiles.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm.desc(_db.vaultFiles.importedAt)]);
    return query.watch().map((rows) => rows.map((row) => mapVaultFileRow(row.readTable(_db.vaultFiles))).toList());
  }

  VaultCollection _toEntity(VaultCollectionRow row) =>
      VaultCollection(id: row.id, name: row.name, createdAt: row.createdAt);
}
