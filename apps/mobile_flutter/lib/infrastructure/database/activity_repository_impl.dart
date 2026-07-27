import 'package:drift/drift.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import 'app_database.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final AppDatabase _db;

  ActivityRepositoryImpl(this._db);

  @override
  Stream<List<ActivityEvent>> watchEvents() {
    final query = _db.select(_db.activityEvents)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(200);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<void> logEvent(ActivityEvent event) {
    return _db.into(_db.activityEvents).insert(
          ActivityEventsCompanion.insert(
            id: event.id,
            type: event.type.name,
            fileName: event.fileName,
            timestamp: event.timestamp,
            success: Value(event.success),
            detail: Value(event.detail),
          ),
        );
  }

  ActivityEvent _toEntity(ActivityEventRow row) {
    return ActivityEvent(
      id: row.id,
      type: ActivityEventType.values.byName(row.type),
      fileName: row.fileName,
      timestamp: row.timestamp,
      success: row.success,
      detail: row.detail,
    );
  }
}
