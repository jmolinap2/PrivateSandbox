import 'package:drift/drift.dart';

@DataClassName('ActivityEventRow')
class ActivityEvents extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get fileName => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get success => boolean().withDefault(const Constant(true))();
  TextColumn get detail => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
