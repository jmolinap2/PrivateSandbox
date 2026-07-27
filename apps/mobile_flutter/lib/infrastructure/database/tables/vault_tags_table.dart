import 'package:drift/drift.dart';

@DataClassName('VaultTagRow')
class VaultTags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many join between files and tags.
@DataClassName('VaultFileTagRow')
class VaultFileTags extends Table {
  TextColumn get fileId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {fileId, tagId};
}
