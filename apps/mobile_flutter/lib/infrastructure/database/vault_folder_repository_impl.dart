import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/vault_folder.dart';
import '../../domain/repositories/vault_folder_repository.dart';
import 'app_database.dart';

class VaultFolderRepositoryImpl implements VaultFolderRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  VaultFolderRepositoryImpl(this._db);

  @override
  Stream<List<VaultFolder>> watchFolders(String? parentId) {
    final query = _db.select(_db.vaultFolders)
      ..where((t) => parentId == null ? t.parentId.isNull() : t.parentId.equals(parentId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<VaultFolder?> getById(String id) async {
    final row = await (_db.select(_db.vaultFolders)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<String> createFolder({required String name, required String? parentId}) async {
    final id = _uuid.v4();
    await _db.into(_db.vaultFolders).insert(
          VaultFoldersCompanion.insert(
            id: id,
            name: name,
            parentId: Value(parentId),
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  @override
  Future<void> renameFolder(String id, String newName) {
    return (_db.update(_db.vaultFolders)..where((t) => t.id.equals(id))).write(
      VaultFoldersCompanion(name: Value(newName)),
    );
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _db.transaction(() => _deleteFolderRecursive(id));
  }

  Future<void> _deleteFolderRecursive(String id) async {
    final childIds = await (_db.select(_db.vaultFolders)..where((t) => t.parentId.equals(id))).get();
    for (final child in childIds) {
      await _deleteFolderRecursive(child.id);
    }
    await (_db.update(_db.vaultFiles)..where((t) => t.folderId.equals(id))).write(
      const VaultFilesCompanion(folderId: Value(null)),
    );
    await (_db.delete(_db.vaultFolders)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<VaultFolder>> getAllFolders() async {
    final rows = await _db.select(_db.vaultFolders).get();
    return rows.map(_toEntity).toList();
  }

  VaultFolder _toEntity(VaultFolderRow row) {
    return VaultFolder(id: row.id, name: row.name, parentId: row.parentId, createdAt: row.createdAt);
  }
}
