enum ActivityEventType { imported, exported, deleted, accessDenied }

/// A local, on-device audit trail entry — the plan's "Actividad reciente" /
/// registro de importaciones, exportaciones y eliminaciones. Never leaves
/// the device and isn't itself considered sensitive vault content.
class ActivityEvent {
  final String id;
  final ActivityEventType type;
  final String fileName;
  final DateTime timestamp;
  final bool success;
  final String? detail;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.fileName,
    required this.timestamp,
    required this.success,
    this.detail,
  });
}
