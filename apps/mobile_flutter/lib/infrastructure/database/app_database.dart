import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/activity_events_table.dart';
import 'tables/vault_collections_table.dart';
import 'tables/vault_files_table.dart';
import 'tables/vault_folders_table.dart';
import 'tables/vault_smart_albums_table.dart';
import 'tables/vault_tags_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  VaultFiles,
  ActivityEvents,
  VaultFolders,
  VaultTags,
  VaultFileTags,
  VaultCollections,
  VaultCollectionFiles,
  VaultSmartAlbums,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(vaultFiles, vaultFiles.isFavorite);
            await m.addColumn(vaultFiles, vaultFiles.lastOpenedAt);
            await m.addColumn(vaultFiles, vaultFiles.playbackPositionMs);
            await m.addColumn(vaultFiles, vaultFiles.thumbnailFileName);
            await m.addColumn(vaultFiles, vaultFiles.thumbnailNoncePrefixBase64);
            await m.createTable(activityEvents);
          }
          if (from < 3) {
            await m.addColumn(vaultFiles, vaultFiles.originalContentUri);
          }
          if (from < 4) {
            await m.addColumn(vaultFiles, vaultFiles.originalRelativePath);
          }
          if (from < 5) {
            await m.addColumn(vaultFiles, vaultFiles.deletedAt);
          }
          if (from < 6) {
            await m.createTable(vaultFolders);
            await m.addColumn(vaultFiles, vaultFiles.folderId);
          }
          if (from < 7) {
            await m.createTable(vaultTags);
            await m.createTable(vaultFileTags);
            await m.createTable(vaultCollections);
            await m.createTable(vaultCollectionFiles);
            await m.createTable(vaultSmartAlbums);
          }
          if (from < 8) {
            await m.addColumn(vaultFiles, vaultFiles.originalTreeUri);
            await m.addColumn(vaultFiles, vaultFiles.originalTreeRelativePath);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'vault.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
