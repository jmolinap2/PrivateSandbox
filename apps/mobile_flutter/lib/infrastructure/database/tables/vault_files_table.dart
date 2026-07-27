import 'package:drift/drift.dart';

@DataClassName('VaultFileRow')
class VaultFiles extends Table {
  TextColumn get id => text()();
  TextColumn get originalName => text()();
  TextColumn get extension => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get originalPath => text().nullable()();
  TextColumn get originalContentUri => text().nullable()();
  TextColumn get originalRelativePath => text().nullable()();

  /// Persisted SAF folder-tree grant covering this file's original folder
  /// (explorer-sourced imports whose original was deleted, only). Lets
  /// restore recreate the file in that folder even though
  /// [originalContentUri]'s document is gone.
  TextColumn get originalTreeUri => text().nullable()();

  /// The file's folder path relative to [originalTreeUri]'s root. Only
  /// meaningful together with [originalTreeUri].
  TextColumn get originalTreeRelativePath => text().nullable()();
  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get fileModifiedAt => dateTime().nullable()();
  TextColumn get category => text()();
  TextColumn get status => text()();
  TextColumn get encryptedFileName => text()();
  TextColumn get fileSaltBase64 => text()();
  TextColumn get noncePrefixBase64 => text()();
  TextColumn get sha256Hash => text().withDefault(const Constant(''))();
  BoolColumn get originalDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  IntColumn get playbackPositionMs => integer().nullable()();
  TextColumn get thumbnailFileName => text().nullable()();
  TextColumn get thumbnailNoncePrefixBase64 => text().nullable()();

  /// When set, the file is in the private trash — hidden from the library
  /// but not yet permanently deleted. Null means "active".
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Virtual folder this file is filed under. Null means "unfiled" (shown
  /// at the folder root). Purely organizational — never changes where the
  /// ciphertext blob physically lives on disk.
  TextColumn get folderId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
