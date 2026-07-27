import 'package:drift/drift.dart';

/// A named, user-curated group of files — flat (unlike carpetas, not
/// hierarchical), and a file can belong to several at once (unlike
/// carpetas, where a file has at most one).
@DataClassName('VaultCollectionRow')
class VaultCollections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VaultCollectionFileRow')
class VaultCollectionFiles extends Table {
  TextColumn get collectionId => text()();
  TextColumn get fileId => text()();

  @override
  Set<Column> get primaryKey => {collectionId, fileId};
}
