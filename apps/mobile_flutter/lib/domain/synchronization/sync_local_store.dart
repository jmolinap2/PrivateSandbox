import 'dart:io';

import 'sync_manifest.dart';

/// One unpublished local change exposed to [SynchronizationEngine].
///
/// The adapter assigns a stable [localRevisionId] and keeps returning the
/// candidate until [acknowledgePublished] succeeds. This makes app termination
/// between upload and local acknowledgement safe and idempotent.
class LocalSyncCandidate {
  final String logicalId;
  final String localRevisionId;
  final String authorDeviceId;
  final DateTime createdAt;
  final VersionVector vector;
  final Set<String> parentVersionIds;
  final bool isTombstone;
  final File? encryptedBlob;
  final Map<String, Object?> privateMetadata;

  const LocalSyncCandidate({
    required this.logicalId,
    required this.localRevisionId,
    required this.authorDeviceId,
    required this.createdAt,
    required this.vector,
    this.parentVersionIds = const <String>{},
    required this.isTombstone,
    required this.encryptedBlob,
    this.privateMetadata = const <String, Object?>{},
  }) : assert(
         (isTombstone && encryptedBlob == null) ||
             (!isTombstone && encryptedBlob != null),
       );
}

/// Integration boundary between the provider-neutral core and local DB/files.
abstract interface class LocalSyncStore {
  Future<List<LocalSyncCandidate>> listPendingCandidates();

  Future<bool> hasVersion(String logicalId, String versionId);

  /// Returns a unique path on the same filesystem as the final vault blobs.
  /// The transfer manager writes a `.sync.part` sibling and atomically renames
  /// it to this file only after all encrypted bytes pass SHA-256 validation.
  Future<File> createStagingTarget(String logicalId, SyncObjectVersion version);

  /// Commits a verified encrypted blob and its private metadata locally.
  ///
  /// [isConflict] tells adapters to create a distinct visible conflict copy;
  /// they must never overwrite an existing local object silently.
  Future<void> commitRemoteVersion({
    required String logicalId,
    required SyncObjectVersion version,
    required File encryptedBlob,
    required bool isConflict,
  });

  /// Records a remote deletion marker. The core deliberately does not delete
  /// bytes; a host policy/UI may later turn a dominating tombstone into trash.
  Future<void> recordRemoteTombstone({
    required String logicalId,
    required SyncObjectVersion tombstone,
    required bool isConflict,
  });

  Future<void> acknowledgePublished({
    required String logicalId,
    required String localRevisionId,
    required SyncObjectVersion version,
  });
}
