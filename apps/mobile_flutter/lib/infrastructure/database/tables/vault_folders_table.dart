import 'package:drift/drift.dart';

/// Purely organizational — folders are metadata only, not a physical
/// directory layout. Ciphertext blobs all still live flat in the vault's
/// blobs directory regardless of which virtual folder a file is filed
/// under.
@DataClassName('VaultFolderRow')
class VaultFolders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Null means a top-level folder.
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
