import 'sync_manifest.dart';
import 'sync_protocol.dart';

/// Deterministic, non-destructive view of a logical object's current heads.
class SyncConflictResolution {
  final SyncObjectVersion primary;
  final List<SyncObjectVersion> conflicts;
  final bool equivalentConcurrentChanges;

  const SyncConflictResolution({
    required this.primary,
    required this.conflicts,
    required this.equivalentConcurrentChanges,
  });

  bool get hasConflict => conflicts.isNotEmpty && !equivalentConcurrentChanges;
}

abstract final class SyncConflictResolver {
  /// Resolves which head is presented as primary without deleting any head.
  ///
  /// Causally obsolete versions are already filtered by [SyncObjectRecord.heads].
  /// Concurrent heads remain in [conflicts]. The stable comparator makes every
  /// device choose the same primary even when clocks are equal.
  static SyncConflictResolution resolve(SyncObjectRecord record) {
    final heads = record.heads;
    if (heads.isEmpty) {
      throw StateError('Cannot resolve an object with no versions');
    }
    final ordered = heads.toList()..sort(_compareVersions);
    final primary = ordered.last;
    final conflicts = ordered
        .where((version) => version.versionId != primary.versionId)
        .toList(growable: false);
    final equivalent = ordered.every(
      (version) =>
          version.isTombstone == primary.isTombstone &&
          version.blob?.sha256 == primary.blob?.sha256 &&
          canonicalJson(version.privateMetadata) ==
              canonicalJson(primary.privateMetadata),
    );
    return SyncConflictResolution(
      primary: primary,
      conflicts: conflicts,
      equivalentConcurrentChanges: equivalent,
    );
  }

  static int _compareVersions(SyncObjectVersion left, SyncObjectVersion right) {
    final time = left.createdAt.compareTo(right.createdAt);
    if (time != 0) return time;
    final clock = left.vector.total.compareTo(right.vector.total);
    if (clock != 0) return clock;
    final author = left.authorDeviceId.compareTo(right.authorDeviceId);
    if (author != 0) return author;
    return left.versionId.compareTo(right.versionId);
  }
}
