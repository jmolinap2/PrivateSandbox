import 'package:drift/drift.dart';

/// Durable bridge between local vault rows and immutable remote versions.
///
/// Rows intentionally survive deletion of the corresponding [localFileId].
/// That retained state is what lets the synchronization adapter publish a
/// tombstone after a permanent local deletion instead of silently bringing
/// the remote copy back.
@DataClassName('VaultSyncStateRow')
class VaultSyncStates extends Table {
  TextColumn get localFileId => text()();
  TextColumn get logicalId => text()();
  TextColumn get latestVersionId => text().nullable()();
  TextColumn get knownVersionIdsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get vectorJson => text().withDefault(const Constant('{}'))();
  TextColumn get lastPublishedRevisionId => text().nullable()();
  DateTimeColumn get lastPublishedAt => dateTime().nullable()();
  BoolColumn get isConflict => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localFileId};
}
