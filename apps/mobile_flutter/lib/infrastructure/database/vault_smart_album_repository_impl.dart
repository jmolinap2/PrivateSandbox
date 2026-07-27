import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/file_category.dart';
import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/entities/vault_smart_album.dart';
import '../../domain/repositories/vault_smart_album_repository.dart';
import 'app_database.dart';
import 'vault_file_mapper.dart';

class VaultSmartAlbumRepositoryImpl implements VaultSmartAlbumRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  VaultSmartAlbumRepositoryImpl(this._db);

  @override
  Stream<List<VaultSmartAlbum>> watchSmartAlbums() {
    final query = _db.select(_db.vaultSmartAlbums)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<void> createSmartAlbum({
    required String name,
    required FileCategory? categoryFilter,
    required bool favoritesOnly,
    required String? tagId,
  }) {
    return _db.into(_db.vaultSmartAlbums).insert(
          VaultSmartAlbumsCompanion.insert(
            id: _uuid.v4(),
            name: name.trim(),
            categoryFilter: Value(categoryFilter?.name),
            favoritesOnly: Value(favoritesOnly),
            tagId: Value(tagId),
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteSmartAlbum(String id) {
    return (_db.delete(_db.vaultSmartAlbums)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<VaultFile>> watchFilesFor(VaultSmartAlbum album) {
    final tagId = album.tagId;
    if (tagId == null) {
      final query = _db.select(_db.vaultFiles)
        ..where((t) {
          var predicate = t.status.equals(ImportStatus.completed.name) & t.deletedAt.isNull();
          final category = album.categoryFilter;
          if (category != null) predicate = predicate & t.category.equals(category.name);
          if (album.favoritesOnly) predicate = predicate & t.isFavorite.equals(true);
          return predicate;
        })
        ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]);
      return query.watch().map((rows) => rows.map(mapVaultFileRow).toList());
    }

    final query = _db.select(_db.vaultFiles).join([
      innerJoin(_db.vaultFileTags, _db.vaultFileTags.fileId.equalsExp(_db.vaultFiles.id)),
    ])
      ..where(() {
        var predicate = _db.vaultFileTags.tagId.equals(tagId) &
            _db.vaultFiles.status.equals(ImportStatus.completed.name) &
            _db.vaultFiles.deletedAt.isNull();
        final category = album.categoryFilter;
        if (category != null) predicate = predicate & _db.vaultFiles.category.equals(category.name);
        if (album.favoritesOnly) predicate = predicate & _db.vaultFiles.isFavorite.equals(true);
        return predicate;
      }())
      ..orderBy([OrderingTerm.desc(_db.vaultFiles.importedAt)]);
    return query.watch().map((rows) => rows.map((row) => mapVaultFileRow(row.readTable(_db.vaultFiles))).toList());
  }

  VaultSmartAlbum _toEntity(VaultSmartAlbumRow row) {
    return VaultSmartAlbum(
      id: row.id,
      name: row.name,
      categoryFilter: row.categoryFilter == null ? null : FileCategory.values.byName(row.categoryFilter!),
      favoritesOnly: row.favoritesOnly,
      tagId: row.tagId,
      createdAt: row.createdAt,
    );
  }
}
