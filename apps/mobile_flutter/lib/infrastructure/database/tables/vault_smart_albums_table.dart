import 'package:drift/drift.dart';

/// A saved filter, not a static list — its contents are recomputed live
/// from the criteria every time it's opened, unlike a [VaultCollections]
/// entry which is a fixed, manually-curated set of files.
@DataClassName('VaultSmartAlbumRow')
class VaultSmartAlbums extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// [FileCategory.name], or null for "any category".
  TextColumn get categoryFilter => text().nullable()();
  BoolColumn get favoritesOnly => boolean().withDefault(const Constant(false))();

  /// Must carry this tag, or null for "any tag".
  TextColumn get tagId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
