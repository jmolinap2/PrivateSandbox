import '../entities/activity_event.dart';

abstract interface class ActivityRepository {
  /// Emits logged events, most recent first.
  Stream<List<ActivityEvent>> watchEvents();

  Future<void> logEvent(ActivityEvent event);
}
