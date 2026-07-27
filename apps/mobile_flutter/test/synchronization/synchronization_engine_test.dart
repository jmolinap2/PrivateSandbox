import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/application/synchronization/synchronization_engine.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_local_store.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';
import 'package:mobile_flutter/domain/synchronization/sync_selection.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_identity_store.dart';
import 'package:mobile_flutter/infrastructure/synchronization/encrypted_manifest_repository.dart';
import 'package:mobile_flutter/infrastructure/synchronization/in_memory_sync_transport.dart';
import 'package:mobile_flutter/infrastructure/synchronization/resumable_blob_transfer.dart';
import 'package:mobile_flutter/infrastructure/synchronization/sync_checkpoint_store.dart';
import 'package:mobile_flutter/infrastructure/synchronization/sync_crypto.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('private-sandbox-engine-');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('two devices sync E2EE and preserve concurrent edits', () async {
    final crypto = SyncCrypto();
    final keys = await crypto.deriveVaultKeys(
      SecretKey(List<int>.generate(32, (index) => index + 1)),
    );
    final transport = InMemorySyncTransport();
    final firstDevice = await DeviceIdentityManager(
      secretStore: MemorySyncSecretStore(),
      clock: () => DateTime.utc(2026, 1, 1),
    ).loadOrCreate(displayName: 'Phone');
    final secondDevice = await DeviceIdentityManager(
      secretStore: MemorySyncSecretStore(),
      clock: () => DateTime.utc(2026, 1, 2),
    ).loadOrCreate(displayName: 'Desktop');
    final firstStore = _FakeLocalSyncStore(Directory('${temp.path}/phone'));
    final secondStore = _FakeLocalSyncStore(Directory('${temp.path}/desktop'));
    final firstRepository = EncryptedManifestRepository(
      transport: transport,
      crypto: crypto,
      keys: keys,
    );
    final firstEngine = _engine(
      repository: firstRepository,
      transport: transport,
      keys: keys,
      device: firstDevice,
      store: firstStore,
      now: DateTime.utc(2026, 2, 1),
    );

    final originalBytes = _bytes(2300, seed: 3);
    final original = File('${temp.path}/original.enc');
    await original.writeAsBytes(originalBytes);
    firstStore.add(
      LocalSyncCandidate(
        logicalId: 'logical-file',
        localRevisionId: 'phone-original',
        authorDeviceId: firstDevice.identity.deviceId,
        createdAt: DateTime.utc(2026, 2, 1),
        vector: VersionVector(<String, int>{firstDevice.identity.deviceId: 1}),
        isTombstone: false,
        encryptedBlob: original,
        privateMetadata: const <String, Object?>{'name': 'private.jpg'},
      ),
    );

    final firstResult = await firstEngine.synchronize(
      policy: const SelectiveSyncPolicy(downloadMode: RemoteDownloadMode.eager),
    );
    expect(firstResult.uploadedVersions, 1);
    final beforeEnrollment = (await firstRepository.load())!;
    final originalVersion = beforeEnrollment
        .manifest
        .records['logical-file']!
        .versions
        .values
        .single;

    await firstEngine.authorizeDevice(secondDevice.identity);

    final secondRepository = EncryptedManifestRepository(
      transport: transport,
      crypto: crypto,
      keys: keys,
    );
    final secondEngine = _engine(
      repository: secondRepository,
      transport: transport,
      keys: keys,
      device: secondDevice,
      store: secondStore,
      now: DateTime.utc(2026, 2, 3),
    );
    final secondInitial = await secondEngine.synchronize(
      policy: const SelectiveSyncPolicy(downloadMode: RemoteDownloadMode.eager),
    );
    expect(secondInitial.downloadedVersions, 1);
    expect(
      await secondStore.bytesFor('logical-file', originalVersion.versionId),
      originalBytes,
    );
    final directive = await firstEngine.issueDirective(
      type: RemoteDirectiveType.lock,
      targetDeviceId: secondDevice.identity.deviceId,
    );
    final delivery = await secondEngine.synchronize(
      policy: const SelectiveSyncPolicy(),
    );
    expect(
      delivery.pendingDirectives.map((item) => item.directiveId),
      contains(directive.directiveId),
    );
    expect(
      await secondEngine.acknowledgeDirective(directive.directiveId),
      isTrue,
    );
    final acknowledgedManifest = await firstEngine.loadManifest();
    expect(
      acknowledgedManifest
          .directives[directive.directiveId]!
          .acknowledgedByDeviceIds,
      contains(secondDevice.identity.deviceId),
    );

    final phoneEdit = File('${temp.path}/phone-edit.enc');
    final desktopEdit = File('${temp.path}/desktop-edit.enc');
    await phoneEdit.writeAsBytes(_bytes(1700, seed: 11));
    await desktopEdit.writeAsBytes(_bytes(1900, seed: 19));
    firstStore.add(
      LocalSyncCandidate(
        logicalId: 'logical-file',
        localRevisionId: 'phone-edit',
        authorDeviceId: firstDevice.identity.deviceId,
        createdAt: DateTime.utc(2026, 3, 1, 10),
        vector: VersionVector(<String, int>{firstDevice.identity.deviceId: 2}),
        parentVersionIds: <String>{originalVersion.versionId},
        isTombstone: false,
        encryptedBlob: phoneEdit,
        privateMetadata: const <String, Object?>{'name': 'phone-edit.jpg'},
      ),
    );
    secondStore.add(
      LocalSyncCandidate(
        logicalId: 'logical-file',
        localRevisionId: 'desktop-edit',
        authorDeviceId: secondDevice.identity.deviceId,
        createdAt: DateTime.utc(2026, 3, 1, 11),
        vector: VersionVector(<String, int>{
          firstDevice.identity.deviceId: 1,
          secondDevice.identity.deviceId: 1,
        }),
        parentVersionIds: <String>{originalVersion.versionId},
        isTombstone: false,
        encryptedBlob: desktopEdit,
        privateMetadata: const <String, Object?>{'name': 'desktop-edit.jpg'},
      ),
    );

    await firstEngine.synchronize(
      policy: const SelectiveSyncPolicy(downloadMode: RemoteDownloadMode.eager),
    );
    await secondEngine.synchronize(
      policy: const SelectiveSyncPolicy(downloadMode: RemoteDownloadMode.eager),
    );
    final phoneFinal = await firstEngine.synchronize(
      policy: const SelectiveSyncPolicy(downloadMode: RemoteDownloadMode.eager),
    );
    final finalManifest = (await firstRepository.load())!;
    final record = finalManifest.manifest.records['logical-file']!;

    expect(record.versions, hasLength(3));
    expect(record.heads, hasLength(2));
    expect(firstStore.versionCount('logical-file'), 3);
    expect(secondStore.versionCount('logical-file'), 3);
    expect(
      phoneFinal.preservedConflicts + secondStore.conflictCommits,
      greaterThan(0),
    );
  });
}

SynchronizationEngine _engine({
  required EncryptedManifestRepository repository,
  required InMemorySyncTransport transport,
  required SyncVaultKeys keys,
  required DeviceCredentials device,
  required _FakeLocalSyncStore store,
  required DateTime now,
}) {
  return SynchronizationEngine(
    manifests: repository,
    transfers: ResumableBlobTransfer(transport: transport, chunkSize: 256),
    localStore: store,
    trustStore: MemorySyncTrustCheckpointStore(),
    vaultKeys: keys,
    device: device,
    clock: () => now,
  );
}

class _FakeLocalSyncStore implements LocalSyncStore {
  final Directory root;
  final List<LocalSyncCandidate> _pending = <LocalSyncCandidate>[];
  final Map<String, Map<String, File?>> _versions =
      <String, Map<String, File?>>{};
  int conflictCommits = 0;

  _FakeLocalSyncStore(this.root);

  void add(LocalSyncCandidate candidate) => _pending.add(candidate);

  int versionCount(String logicalId) => _versions[logicalId]?.length ?? 0;

  Future<Uint8List> bytesFor(String logicalId, String versionId) async {
    return Uint8List.fromList(
      await _versions[logicalId]![versionId]!.readAsBytes(),
    );
  }

  @override
  Future<void> acknowledgePublished({
    required String logicalId,
    required String localRevisionId,
    required SyncObjectVersion version,
  }) async {
    final candidate = _pending.firstWhere(
      (item) =>
          item.logicalId == logicalId &&
          item.localRevisionId == localRevisionId,
    );
    _versions.putIfAbsent(
      logicalId,
      () => <String, File?>{},
    )[version.versionId] = candidate.encryptedBlob;
    _pending.remove(candidate);
  }

  @override
  Future<void> commitRemoteVersion({
    required String logicalId,
    required SyncObjectVersion version,
    required File encryptedBlob,
    required bool isConflict,
  }) async {
    _versions.putIfAbsent(
      logicalId,
      () => <String, File?>{},
    )[version.versionId] = encryptedBlob;
    if (isConflict) conflictCommits++;
  }

  @override
  Future<File> createStagingTarget(
    String logicalId,
    SyncObjectVersion version,
  ) async {
    if (!await root.exists()) await root.create(recursive: true);
    return File('${root.path}/$logicalId-${version.versionId}.enc');
  }

  @override
  Future<bool> hasVersion(String logicalId, String versionId) async {
    return _versions[logicalId]?.containsKey(versionId) ?? false;
  }

  @override
  Future<List<LocalSyncCandidate>> listPendingCandidates() async {
    return List<LocalSyncCandidate>.of(_pending);
  }

  @override
  Future<void> recordRemoteTombstone({
    required String logicalId,
    required SyncObjectVersion tombstone,
    required bool isConflict,
  }) async {
    _versions.putIfAbsent(
      logicalId,
      () => <String, File?>{},
    )[tombstone.versionId] = null;
    if (isConflict) conflictCommits++;
  }
}

Uint8List _bytes(int length, {required int seed}) {
  return Uint8List.fromList(
    List<int>.generate(length, (index) => (index * 37 + seed) & 0xff),
  );
}
