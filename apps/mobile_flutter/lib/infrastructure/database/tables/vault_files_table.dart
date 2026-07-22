import 'package:drift/drift.dart';

@DataClassName('VaultFileRow')
class VaultFiles extends Table {
  TextColumn get id => text()();
  TextColumn get originalName => text()();
  TextColumn get extension => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get originalPath => text().nullable()();
  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get fileModifiedAt => dateTime().nullable()();
  TextColumn get category => text()();
  TextColumn get status => text()();
  TextColumn get encryptedFileName => text()();
  TextColumn get fileSaltBase64 => text()();
  TextColumn get noncePrefixBase64 => text()();
  TextColumn get sha256Hash => text().withDefault(const Constant(''))();
  BoolColumn get originalDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
