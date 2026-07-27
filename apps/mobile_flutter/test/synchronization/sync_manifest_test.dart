import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_conflict_resolver.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';

void main() {
  group('VersionVector', () {
    test('distinguishes causality, equality and concurrency', () {
      final first = VersionVector(<String, int>{'a': 1});
      final descendant = VersionVector(<String, int>{'a': 2});
      final concurrent = VersionVector(<String, int>{'a': 1, 'b': 1});

      expect(first.compare(descendant), VectorRelation.before);
      expect(descendant.compare(first), VectorRelation.after);
      expect(
        first.compare(VersionVector(<String, int>{'a': 1})),
        VectorRelation.equal,
      );
      expect(descendant.compare(concurrent), VectorRelation.concurrent);
      expect(descendant.merge(concurrent).counters, <String, int>{
        'a': 2,
        'b': 1,
      });
    });
  });

  group('SyncConflictResolver', () {
    test('preserves concurrent heads and chooses the same primary', () {
      final left = _version(
        author: 'device-a',
        vector: VersionVector(<String, int>{'device-a': 2}),
        hash: 'left',
      );
      final right = _version(
        author: 'device-b',
        vector: VersionVector(<String, int>{'device-a': 1, 'device-b': 1}),
        hash: 'right',
      );
      final forward = SyncObjectRecord(
        logicalId: 'file',
        versions: <SyncObjectVersion>[left, right],
      );
      final reverse = SyncObjectRecord(
        logicalId: 'file',
        versions: <SyncObjectVersion>[right, left],
      );

      expect(forward.heads, hasLength(2));
      final resolution = SyncConflictResolver.resolve(forward);
      expect(resolution.hasConflict, isTrue);
      expect(resolution.conflicts, hasLength(1));
      expect(
        SyncConflictResolver.resolve(reverse).primary.versionId,
        resolution.primary.versionId,
      );
    });

    test('removes only causally obsolete versions from heads', () {
      final old = _version(
        author: 'device-a',
        vector: VersionVector(<String, int>{'device-a': 1}),
        hash: 'old',
      );
      final current = _version(
        author: 'device-a',
        vector: VersionVector(<String, int>{'device-a': 2}),
        hash: 'current',
        parents: <String>{old.versionId},
      );
      final record = SyncObjectRecord(
        logicalId: 'file',
        versions: <SyncObjectVersion>[old, current],
      );

      expect(record.versions, hasLength(2));
      expect(record.heads.single.versionId, current.versionId);
    });
  });

  test('manifest JSON round-trip keeps its authenticated digest', () {
    final owner = DeviceIdentity.fromPublicKeys(
      displayName: 'Phone',
      signingPublicKey: List<int>.generate(32, (index) => index),
      exchangePublicKey: List<int>.generate(32, (index) => index + 32),
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final manifest = SyncManifest.initial(
      vaultId: 'vault',
      owner: owner,
      now: DateTime.utc(2026, 1, 2),
    );

    final decoded = SyncManifest.fromJson(manifest.toJson());

    expect(decoded.digest, manifest.digest);
    expect(decoded.devices.values.single.identity.deviceId, owner.deviceId);
  });

  test('only a directive target can acknowledge it', () {
    final owner = DeviceIdentity.fromPublicKeys(
      displayName: 'Owner',
      signingPublicKey: List<int>.filled(32, 1),
      exchangePublicKey: List<int>.filled(32, 2),
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final initial = SyncManifest.initial(
      vaultId: 'vault',
      owner: owner,
      now: DateTime.utc(2026, 1, 1),
    );
    final issued = SyncManifestAdmin.issueDirective(
      manifest: initial,
      actorDeviceId: owner.deviceId,
      directive: RemoteDeviceDirective(
        directiveId: 'lock-1',
        type: RemoteDirectiveType.lock,
        targetDeviceId: owner.deviceId,
        issuedByDeviceId: owner.deviceId,
        issuedAt: DateTime.utc(2026, 1, 2),
      ),
      now: DateTime.utc(2026, 1, 2),
    );

    final acknowledged = SyncManifestAdmin.acknowledgeDirective(
      manifest: issued,
      actorDeviceId: owner.deviceId,
      directiveId: 'lock-1',
      acknowledgementSignatureBase64: 'test-signature',
      now: DateTime.utc(2026, 1, 3),
    );

    expect(
      acknowledged.directives['lock-1']!.acknowledgedByDeviceIds,
      contains(owner.deviceId),
    );
    expect(acknowledged.generation, issued.generation + 1);
  });
}

SyncObjectVersion _version({
  required String author,
  required VersionVector vector,
  required String hash,
  Set<String> parents = const <String>{},
}) {
  return SyncObjectVersion.create(
    authorDeviceId: author,
    createdAt: DateTime.utc(2026, 1, 1, 0, vector.total),
    vector: vector,
    parentVersionIds: parents,
    isTombstone: false,
    blob: SyncBlobDescriptor(
      objectId: hash,
      size: 1,
      sha256: hash,
      chunkSize: 1,
      chunks: <SyncBlobChunk>[
        SyncBlobChunk(index: 0, path: 'objects/$hash', size: 1, sha256: hash),
      ],
    ),
  );
}
