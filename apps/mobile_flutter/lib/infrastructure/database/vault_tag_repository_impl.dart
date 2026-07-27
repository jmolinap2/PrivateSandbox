import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/entities/vault_tag.dart';
import '../../domain/repositories/vault_tag_repository.dart';
import 'app_database.dart';
import 'vault_file_mapper.dart';

class VaultTagRepositoryImpl implements VaultTagRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  VaultTagRepositoryImpl(this._db);

  @override
  Stream<List<VaultTag>> watchTags() {
    final query = _db.select(_db.vaultTags)..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<VaultTag> getOrCreateTag(String name) async {
    final normalized = name.trim();
    final existing = await (_db.select(_db.vaultTags)
          ..where((t) => t.name.lower().equals(normalized.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) return _toEntity(existing);

    final id = _uuid.v4();
    await _db.into(_db.vaultTags).insert(VaultTagsCompanion.insert(id: id, name: normalized));
    return VaultTag(id: id, name: normalized);
  }

  @override
  Future<void> renameTag(String id, String newName) {
    return (_db.update(_db.vaultTags)..where((t) => t.id.equals(id))).write(
      VaultTagsCompanion(name: Value(newName.trim())),
    );
  }

  @override
  Future<void> deleteTag(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.vaultFileTags)..where((t) => t.tagId.equals(id))).go();
      await (_db.update(_db.vaultSmartAlbums)..where((t) => t.tagId.equals(id))).write(
        const VaultSmartAlbumsCompanion(tagId: Value(null)),
      );
      await (_db.delete(_db.vaultTags)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> addTagToFile(String fileId, String tagId) {
    return _db.into(_db.vaultFileTags).insertOnConflictUpdate(
          VaultFileTagsCompanion.insert(fileId: fileId, tagId: tagId),
        );
  }

  @override
  Future<void> removeTagFromFile(String fileId, String tagId) {
    return (_db.delete(_db.vaultFileTags)
          ..where((t) => t.fileId.equals(fileId) & t.tagId.equals(tagId)))
        .go();
  }

  @override
  Stream<List<VaultTag>> watchTagsForFile(String fileId) {
    final query = _db.select(_db.vaultTags).join([
      innerJoin(_db.vaultFileTags, _db.vaultFileTags.tagId.equalsExp(_db.vaultTags.id)),
    ])
      ..where(_db.vaultFileTags.fileId.equals(fileId))
      ..orderBy([OrderingTerm.asc(_db.vaultTags.name)]);
    return query.watch().map((rows) => rows.map((row) => _toEntity(row.readTable(_db.vaultTags))).toList());
  }

  @override
  Stream<List<VaultFile>> watchFilesWithTag(String tagId) {
    final query = _db.select(_db.vaultFiles).join([
      innerJoin(_db.vaultFileTags, _db.vaultFileTags.fileId.equalsExp(_db.vaultFiles.id)),
    ])
      ..where(
        _db.vaultFileTags.tagId.equals(tagId) &
            _db.vaultFiles.status.equals(ImportStatus.completed.name) &
            _db.vaultFiles.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm.desc(_db.vaultFiles.importedAt)]);
    return query.watch().map((rows) => rows.map((row) => mapVaultFileRow(row.readTable(_db.vaultFiles))).toList());
  }

  VaultTag _toEntity(VaultTagRow row) => VaultTag(id: row.id, name: row.name);
}
