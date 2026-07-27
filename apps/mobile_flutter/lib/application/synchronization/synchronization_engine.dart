// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_checkpoint.dart';
import '../../domain/synchronization/sync_conflict_resolver.dart';
import '../../domain/synchronization/sync_local_store.dart';
import '../../domain/synchronization/sync_manifest.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../domain/synchronization/sync_selection.dart';
import '../../infrastructure/synchronization/device_identity_store.dart';
import '../../infrastructure/synchronization/device_key_grant.dart';
import '../../infrastructure/synchronization/encrypted_manifest_repository.dart';
import '../../infrastructure/synchronization/remote_directive_codec.dart';
import '../../infrastructure/synchronization/resumable_blob_transfer.dart';
import '../../infrastructure/synchronization/sync_crypto.dart';

class SynchronizationEngineConfig {
  final int maximumCasAttempts;
  final bool verifyExistingRemoteChunks;

  const SynchronizationEngineConfig({
    this.maximumCasAttempts = 4,
    this.verifyExistingRemoteChunks = true,
  }) : assert(maximumCasAttempts > 0);
}

class SynchronizationResult {
  final bool skippedBecauseLocalOnly;
  final int? previousGeneration;
  final int? currentGeneration;
  final int uploadedVersions;
  final int downloadedVersions;
  final int recordedTombstones;
  final int preservedConflicts;
  final int skippedBySelection;
  final List<RemoteDeviceDirective> pendingDirectives;

  const SynchronizationResult({
    required this.skippedBecauseLocalOnly,
    required this.previousGeneration,
    required this.currentGeneration,
    required this.uploadedVersions,
    required this.downloadedVersions,
    required this.recordedTombstones,
    required this.preservedConflicts,
    required this.skippedBySelection,
    required this.pendingDirectives,
  });

  const SynchronizationResult.localOnly()
    : skippedBecauseLocalOnly = true,
      previousGeneration = null,
      currentGeneration = null,
      uploadedVersions = 0,
      downloadedVersions = 0,
      recordedTombstones = 0,
      preservedConflicts = 0,
      skippedBySelection = 0,
      pendingDirectives = const <RemoteDeviceDirective>[];
}

class _PreparedCandidate {
  final LocalSyncCandidate candidate;
  final SyncObjectVersion version;

  const _PreparedCandidate(this.candidate, this.version);
}

/// Coordinates authenticated manifest CAS and resumable encrypted blob
/// transfers. It is deliberately independent from Drift/Riverpod/UI.
class SynchronizationEngine {
  final EncryptedManifestRepository _manifests;
  final ResumableBlobTransfer _transfers;
  final LocalSyncStore _localStore;
  final SyncTrustCheckpointStore _trustStore;
  final SyncVaultKeys _vaultKeys;
  final DeviceCredentials _device;
  final DateTime Function() _clock;
  final SynchronizationEngineConfig config;

  SynchronizationEngine({
    required EncryptedManifestRepository manifests,
    required ResumableBlobTransfer transfers,
    required LocalSyncStore localStore,
    required SyncTrustCheckpointStore trustStore,
    required SyncVaultKeys vaultKeys,
    required DeviceCredentials device,
    DateTime Function()? clock,
    this.config = const SynchronizationEngineConfig(),
  }) : _manifests = manifests,
       _transfers = transfers,
       _localStore = localStore,
       _trustStore = trustStore,
       _vaultKeys = vaultKeys,
       _device = device,
       _clock = clock ?? DateTime.now;

  Future<SynchronizationResult> synchronize({
    required SelectiveSyncPolicy policy,
    Set<String> requestedDownloadLogicalIds = const <String>{},
    bool Function()? isCancelled,
    SyncProgressCallback? onProgress,
  }) async {
    if (policy.mode == VaultSyncMode.localOnly) {
      return const SynchronizationResult.localOnly();
    }
    _throwIfCancelled(isCancelled);

    var stored = await _loadOrInitialize(isCancelled: isCancelled);
    final startingGeneration = stored.manifest.generation;
    final candidates = await _localStore.listPendingCandidates();
    final prepared = <_PreparedCandidate>[];
    var skippedBySelection = 0;

    for (final candidate in candidates) {
      _throwIfCancelled(isCancelled);
      if (candidate.authorDeviceId != _device.identity.deviceId) {
        throw const SyncAuthorizationException(
          'A local candidate claims a different author device',
        );
      }
      if (!policy.allowsMetadata(candidate.logicalId)) {
        skippedBySelection++;
        continue;
      }
      final vector = candidate.vector[_device.identity.deviceId] == 0
          ? candidate.vector.increment(_device.identity.deviceId)
          : candidate.vector;
      SyncBlobDescriptor? descriptor;
      if (!candidate.isTombstone) {
        final file = candidate.encryptedBlob!;
        final size = await file.length();
        if (!policy.allowsBlob(candidate.logicalId, size)) {
          skippedBySelection++;
          continue;
        }
        descriptor = await _transfers.upload(
          vaultId: _vaultKeys.vaultId,
          encryptedFile: file,
          verifyExistingChunks: config.verifyExistingRemoteChunks,
          bandwidthLimitBytesPerSecond: policy.bandwidthLimitBytesPerSecond,
          isCancelled: isCancelled,
          onProgress: onProgress,
        );
      }
      prepared.add(
        _PreparedCandidate(
          candidate,
          SyncObjectVersion.create(
            authorDeviceId: candidate.authorDeviceId,
            createdAt: candidate.createdAt,
            vector: vector,
            parentVersionIds: candidate.parentVersionIds,
            isTombstone: candidate.isTombstone,
            blob: descriptor,
            privateMetadata: candidate.privateMetadata,
          ),
        ),
      );
    }

    var uploadedVersions = 0;
    for (var attempt = 0; attempt < config.maximumCasAttempts; attempt++) {
      _throwIfCancelled(isCancelled);
      stored.manifest.requireAuthorizedDevice(_device.identity.deviceId);
      final records = <String, SyncObjectRecord>{...stored.manifest.records};
      var changed = false;
      var additionsThisAttempt = 0;
      for (final item in prepared) {
        final current = records[item.candidate.logicalId];
        if (current?.versions.containsKey(item.version.versionId) ?? false) {
          continue;
        }
        records[item.candidate.logicalId] = current == null
            ? SyncObjectRecord(
                logicalId: item.candidate.logicalId,
                versions: <SyncObjectVersion>[item.version],
              )
            : current.add(item.version);
        changed = true;
        additionsThisAttempt++;
      }
      if (!changed) break;
      final next = stored.manifest.nextGeneration(
        authorDeviceId: _device.identity.deviceId,
        generatedAt: _clock().toUtc(),
        records: records,
      );
      try {
        stored = await _manifests.publish(
          manifest: next,
          signer: _device,
          expectedEtag: stored.etag,
        );
        uploadedVersions = additionsThisAttempt;
        await _saveCheckpoint(stored);
        break;
      } on SyncPreconditionFailed {
        if (attempt + 1 == config.maximumCasAttempts) rethrow;
        stored = await _reloadAfterRace(stored);
      }
    }

    for (final item in prepared) {
      if (stored.manifest.records[item.candidate.logicalId]?.versions
              .containsKey(item.version.versionId) ??
          false) {
        await _localStore.acknowledgePublished(
          logicalId: item.candidate.logicalId,
          localRevisionId: item.candidate.localRevisionId,
          version: item.version,
        );
      }
    }

    var downloadedVersions = 0;
    var recordedTombstones = 0;
    var preservedConflicts = 0;
    for (final record in stored.manifest.records.values) {
      _throwIfCancelled(isCancelled);
      if (!policy.allowsMetadata(record.logicalId)) continue;
      final shouldDownload =
          policy.downloadMode == RemoteDownloadMode.eager ||
          requestedDownloadLogicalIds.contains(record.logicalId);
      if (!shouldDownload) continue;
      final resolution = SyncConflictResolver.resolve(record);
      final orderedHeads = record.heads.toList()
        ..sort((left, right) => left.versionId.compareTo(right.versionId));
      for (final version in orderedHeads) {
        if (await _localStore.hasVersion(record.logicalId, version.versionId)) {
          continue;
        }
        final isConflict =
            resolution.hasConflict &&
            version.versionId != resolution.primary.versionId;
        if (isConflict) preservedConflicts++;
        if (version.isTombstone) {
          await _localStore.recordRemoteTombstone(
            logicalId: record.logicalId,
            tombstone: version,
            isConflict: isConflict,
          );
          recordedTombstones++;
          continue;
        }
        final descriptor = version.blob!;
        if (!policy.allowsBlob(record.logicalId, descriptor.size)) {
          skippedBySelection++;
          continue;
        }
        final target = await _localStore.createStagingTarget(
          record.logicalId,
          version,
        );
        final downloaded = await _transfers.download(
          descriptor: descriptor,
          target: target,
          bandwidthLimitBytesPerSecond: policy.bandwidthLimitBytesPerSecond,
          isCancelled: isCancelled,
          onProgress: onProgress,
        );
        await _localStore.commitRemoteVersion(
          logicalId: record.logicalId,
          version: version,
          encryptedBlob: downloaded,
          isConflict: isConflict,
        );
        downloadedVersions++;
      }
    }

    final pendingDirectives = stored.manifest.directives.values
        .where(
          (directive) => directive.isPendingFor(
            _device.identity.deviceId,
            _clock().toUtc(),
          ),
        )
        .toList(growable: false);
    return SynchronizationResult(
      skippedBecauseLocalOnly: false,
      previousGeneration: startingGeneration,
      currentGeneration: stored.manifest.generation,
      uploadedVersions: uploadedVersions,
      downloadedVersions: downloadedVersions,
      recordedTombstones: recordedTombstones,
      preservedConflicts: preservedConflicts,
      skippedBySelection: skippedBySelection,
      pendingDirectives: pendingDirectives,
    );
  }

  /// Fetches one historical version without changing the global eager/on-demand
  /// preference.
  Future<bool> downloadVersion({
    required String logicalId,
    required String versionId,
    int? bandwidthLimitBytesPerSecond,
    bool Function()? isCancelled,
    SyncProgressCallback? onProgress,
  }) async {
    final stored = await _loadOrInitialize(isCancelled: isCancelled);
    final record = stored.manifest.records[logicalId];
    final version = record?.versions[versionId];
    if (version == null) return false;
    if (await _localStore.hasVersion(logicalId, versionId)) return true;
    final resolution = SyncConflictResolver.resolve(record!);
    final isConflict =
        record.heads.any((head) => head.versionId == version.versionId) &&
        resolution.hasConflict &&
        resolution.primary.versionId != version.versionId;
    if (version.isTombstone) {
      await _localStore.recordRemoteTombstone(
        logicalId: logicalId,
        tombstone: version,
        isConflict: isConflict,
      );
      return true;
    }
    final target = await _localStore.createStagingTarget(logicalId, version);
    final downloaded = await _transfers.download(
      descriptor: version.blob!,
      target: target,
      bandwidthLimitBytesPerSecond: bandwidthLimitBytesPerSecond,
      isCancelled: isCancelled,
      onProgress: onProgress,
    );
    await _localStore.commitRemoteVersion(
      logicalId: logicalId,
      version: version,
      encryptedBlob: downloaded,
      isConflict: isConflict,
    );
    return true;
  }

  /// Returns the authenticated, decrypted in-process catalog used by
  /// on-demand and version-history UI. Callers must not serialize it to logs
  /// or shared storage.
  Future<SyncManifest> loadManifest({bool Function()? isCancelled}) async {
    return (await _loadOrInitialize(isCancelled: isCancelled)).manifest;
  }

  Future<SyncManifest> authorizeDevice(
    DeviceIdentity newDevice, {
    DeviceRole role = DeviceRole.member,
    bool Function()? isCancelled,
  }) async {
    final stored = await _mutateManifest(
      (manifest) async => SyncManifestAdmin.authorizeDevice(
        manifest: manifest,
        actorDeviceId: _device.identity.deviceId,
        newDevice: newDevice,
        role: role,
        now: _clock().toUtc(),
      ),
      isCancelled: isCancelled,
    );
    return stored.manifest;
  }

  /// Creates a short-lived master-key grant anchored to the latest
  /// authenticated registry. Call [authorizeDevice] first; the recipient must
  /// persist `RecoveredDeviceGrant.trustCheckpoint` before its first fetch.
  Future<DeviceKeyGrant> createDeviceKeyGrant({
    required DeviceIdentity recipient,
    required Uint8List masterKeyBytes,
    Duration lifetime = const Duration(minutes: 10),
    bool Function()? isCancelled,
  }) async {
    final stored = await _loadOrInitialize(isCancelled: isCancelled);
    final registration = stored.manifest.requireAuthorizedDevice(
      recipient.deviceId,
    );
    if (registration.identity.signingPublicKeyBase64 !=
            recipient.signingPublicKeyBase64 ||
        registration.identity.exchangePublicKeyBase64 !=
            recipient.exchangePublicKeyBase64) {
      throw const SyncAuthorizationException(
        'Grant recipient does not match the authorized device identity',
      );
    }
    return DeviceKeyGrantCodec.create(
      vaultId: _vaultKeys.vaultId,
      masterKeyBytes: masterKeyBytes,
      sender: _device,
      recipient: recipient,
      trustCheckpoint: _checkpointFor(stored),
      createdAt: _clock().toUtc(),
      lifetime: lifetime,
    );
  }

  Future<SyncManifest> revokeDevice(
    String targetDeviceId, {
    bool Function()? isCancelled,
  }) async {
    final stored = await _mutateManifest(
      (manifest) async => SyncManifestAdmin.revokeDevice(
        manifest: manifest,
        actorDeviceId: _device.identity.deviceId,
        targetDeviceId: targetDeviceId,
        now: _clock().toUtc(),
      ),
      isCancelled: isCancelled,
    );
    return stored.manifest;
  }

  Future<RemoteDeviceDirective> issueDirective({
    String? directiveId,
    required RemoteDirectiveType type,
    required String targetDeviceId,
    DateTime? expiresAt,
    bool Function()? isCancelled,
  }) async {
    final directive = await RemoteDirectiveCodec.create(
      directiveId: directiveId,
      type: type,
      targetDeviceId: targetDeviceId,
      issuer: _device,
      issuedAt: _clock().toUtc(),
      expiresAt: expiresAt,
    );
    await _mutateManifest(
      (manifest) async => SyncManifestAdmin.issueDirective(
        manifest: manifest,
        actorDeviceId: _device.identity.deviceId,
        directive: directive,
        now: _clock().toUtc(),
      ),
      isCancelled: isCancelled,
    );
    return directive;
  }

  /// Acknowledges a delivered lock/logout/wipe request through an
  /// authenticated manifest CAS. This does not execute the request; callers
  /// invoke it only after their local policy has handled the directive.
  Future<bool> acknowledgeDirective(
    String directiveId, {
    bool Function()? isCancelled,
  }) async {
    var stored = await _loadOrInitialize(isCancelled: isCancelled);
    for (var attempt = 0; attempt < config.maximumCasAttempts; attempt++) {
      _throwIfCancelled(isCancelled);
      final directive = stored.manifest.directives[directiveId];
      if (directive == null) return false;
      if (directive.targetDeviceId != _device.identity.deviceId) {
        throw const SyncAuthorizationException(
          'Only the target device can acknowledge a remote directive',
        );
      }
      if (directive.acknowledgedByDeviceIds.contains(
        _device.identity.deviceId,
      )) {
        return true;
      }
      final acknowledgementSignature =
          await RemoteDirectiveCodec.signAcknowledgement(
            directive: directive,
            target: _device,
          );
      final acknowledged = SyncManifestAdmin.acknowledgeDirective(
        manifest: stored.manifest,
        actorDeviceId: _device.identity.deviceId,
        directiveId: directiveId,
        acknowledgementSignatureBase64: acknowledgementSignature,
        now: _clock().toUtc(),
      );
      try {
        stored = await _manifests.publish(
          manifest: acknowledged,
          signer: _device,
          expectedEtag: stored.etag,
        );
        await _saveCheckpoint(stored);
        return true;
      } on SyncPreconditionFailed {
        if (attempt + 1 == config.maximumCasAttempts) rethrow;
        stored = await _reloadAfterRace(stored);
      }
    }
    return false;
  }

  Future<StoredSyncManifest> _mutateManifest(
    Future<SyncManifest> Function(SyncManifest manifest) transform, {
    bool Function()? isCancelled,
  }) async {
    var stored = await _loadOrInitialize(isCancelled: isCancelled);
    for (var attempt = 0; attempt < config.maximumCasAttempts; attempt++) {
      _throwIfCancelled(isCancelled);
      final next = await transform(stored.manifest);
      if (next.digest == stored.manifest.digest) return stored;
      try {
        stored = await _manifests.publish(
          manifest: next,
          signer: _device,
          expectedEtag: stored.etag,
        );
        await _saveCheckpoint(stored);
        return stored;
      } on SyncPreconditionFailed {
        if (attempt + 1 == config.maximumCasAttempts) rethrow;
        stored = await _reloadAfterRace(stored);
      }
    }
    throw const SyncPreconditionFailed(
      'Manifest compare-and-swap retry limit was exhausted',
    );
  }

  Future<StoredSyncManifest> _loadOrInitialize({
    bool Function()? isCancelled,
  }) async {
    final checkpoint = await _trustStore.load(_vaultKeys.vaultId);
    _throwIfCancelled(isCancelled);
    var stored = await _manifests.load(
      trustedDevices: checkpoint?.trustedDevices,
      minimumGeneration: checkpoint?.generation,
    );
    if (stored != null) {
      _validateCheckpoint(checkpoint, stored);
      stored.manifest.requireAuthorizedDevice(_device.identity.deviceId);
      await _saveCheckpoint(stored);
      return stored;
    }
    if (checkpoint != null) {
      throw const SyncIntegrityException(
        'Remote manifest disappeared after this vault was synchronized',
      );
    }
    final initial = SyncManifest.initial(
      vaultId: _vaultKeys.vaultId,
      owner: _device.identity,
      now: _clock().toUtc(),
    );
    try {
      stored = await _manifests.publish(
        manifest: initial,
        signer: _device,
        expectedEtag: null,
      );
    } on SyncPreconditionFailed {
      stored = await _manifests.load();
      if (stored == null) rethrow;
      stored.manifest.requireAuthorizedDevice(_device.identity.deviceId);
    }
    await _saveCheckpoint(stored);
    return stored;
  }

  Future<StoredSyncManifest> _reloadAfterRace(
    StoredSyncManifest previous,
  ) async {
    final current = await _manifests.load(
      trustedDevices: previous.manifest.devices,
      minimumGeneration: previous.manifest.generation,
    );
    if (current == null) {
      throw const SyncIntegrityException(
        'Remote manifest disappeared during compare-and-swap',
      );
    }
    if (current.manifest.generation == previous.manifest.generation &&
        current.envelopeDigest != previous.envelopeDigest) {
      throw const SyncIntegrityException(
        'Remote provider equivocated at the same manifest generation',
      );
    }
    if (current.manifest.generation == previous.manifest.generation + 1 &&
        current.manifest.previousManifestDigest != previous.manifest.digest) {
      throw const SyncIntegrityException(
        'Remote manifest history chain is broken',
      );
    }
    current.manifest.requireAuthorizedDevice(_device.identity.deviceId);
    await _saveCheckpoint(current);
    return current;
  }

  void _validateCheckpoint(
    SyncTrustCheckpoint? checkpoint,
    StoredSyncManifest stored,
  ) {
    if (checkpoint == null) return;
    if (stored.manifest.generation == checkpoint.generation &&
        stored.envelopeDigest != checkpoint.envelopeDigest) {
      throw const SyncIntegrityException(
        'Remote provider equivocated at the checkpoint generation',
      );
    }
    if (stored.manifest.generation == checkpoint.generation + 1 &&
        stored.manifest.previousManifestDigest != checkpoint.manifestDigest) {
      throw const SyncIntegrityException(
        'Remote manifest does not descend from the trusted checkpoint',
      );
    }
  }

  Future<void> _saveCheckpoint(StoredSyncManifest stored) {
    return _trustStore.save(_checkpointFor(stored));
  }

  static SyncTrustCheckpoint _checkpointFor(StoredSyncManifest stored) {
    return SyncTrustCheckpoint(
      vaultId: stored.manifest.vaultId,
      generation: stored.manifest.generation,
      manifestDigest: stored.manifest.digest,
      envelopeDigest: stored.envelopeDigest,
      trustedDevices: stored.manifest.devices,
    );
  }

  static void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) {
      throw const SyncCancelledException();
    }
  }
}
