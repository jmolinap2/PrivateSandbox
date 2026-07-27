import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_checkpoint.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_identity_store.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_key_grant.dart';
import 'package:mobile_flutter/infrastructure/synchronization/encrypted_manifest_repository.dart';
import 'package:mobile_flutter/infrastructure/synchronization/in_memory_sync_transport.dart';
import 'package:mobile_flutter/infrastructure/synchronization/sync_crypto.dart';

void main() {
  test('device identity is stable and corruption is not regenerated', () async {
    final secrets = MemorySyncSecretStore();
    final manager = DeviceIdentityManager(
      secretStore: secrets,
      clock: () => DateTime.utc(2026, 1, 1),
    );

    final first = await manager.loadOrCreate(displayName: 'Pixel');
    final second = await manager.loadOrCreate(displayName: 'Ignored');

    expect(second.identity.deviceId, first.identity.deviceId);
    await secrets.write(DeviceIdentityManager.storageKey, '{broken');
    expect(manager.load, throwsA(isA<SyncIntegrityException>()));
  });

  test('manifest is encrypted, signed and rejects tampering', () async {
    final credentials = await DeviceIdentityManager(
      secretStore: MemorySyncSecretStore(),
      clock: () => DateTime.utc(2026, 1, 1),
    ).loadOrCreate(displayName: 'Owner');
    final crypto = SyncCrypto();
    final keys = await crypto.deriveVaultKeys(
      SecretKey(List<int>.generate(32, (index) => index)),
    );
    final manifest = SyncManifest.initial(
      vaultId: keys.vaultId,
      owner: credentials.identity,
      now: DateTime.utc(2026, 1, 2),
    );
    final envelope = await crypto.encryptManifest(
      manifest: manifest,
      keys: keys,
      signer: credentials,
    );

    expect(envelope.cipherTextBase64, isNot(contains('Owner')));
    final decoded = await crypto.decryptManifest(
      envelope: envelope,
      keys: keys,
    );
    expect(decoded.digest, manifest.digest);

    final json = envelope.toJson();
    final cipher = base64Decode(json['cipherText']! as String);
    cipher[0] ^= 0xff;
    json['cipherText'] = base64Encode(cipher);
    final tampered = crypto.decodeEnvelope(utf8.encode(jsonEncode(json)));
    expect(
      () => crypto.decryptManifest(envelope: tampered, keys: keys),
      throwsA(isA<SyncIntegrityException>()),
    );
  });

  test(
    'key grant recovers master key only for recipient before expiry',
    () async {
      final sender = await DeviceIdentityManager(
        secretStore: MemorySyncSecretStore(),
      ).loadOrCreate(displayName: 'Sender');
      final recipient = await DeviceIdentityManager(
        secretStore: MemorySyncSecretStore(),
      ).loadOrCreate(displayName: 'Recipient');
      final stranger = await DeviceIdentityManager(
        secretStore: MemorySyncSecretStore(),
      ).loadOrCreate(displayName: 'Stranger');
      final masterKey = Uint8List.fromList(
        List<int>.generate(32, (index) => 255 - index),
      );
      final createdAt = DateTime.utc(2026, 2, 1);
      final initial = SyncManifest.initial(
        vaultId: 'vault-id',
        owner: sender.identity,
        now: createdAt,
      );
      final authorized = SyncManifestAdmin.authorizeDevice(
        manifest: initial,
        actorDeviceId: sender.identity.deviceId,
        newDevice: recipient.identity,
        now: createdAt,
      );
      final checkpoint = _checkpoint(authorized);

      final grant = await DeviceKeyGrantCodec.create(
        vaultId: 'vault-id',
        masterKeyBytes: masterKey,
        sender: sender,
        recipient: recipient.identity,
        trustCheckpoint: checkpoint,
        createdAt: createdAt,
      );
      final recovered = await DeviceKeyGrantCodec.open(
        grant: grant,
        recipient: recipient,
        now: createdAt.add(const Duration(minutes: 1)),
        expectedSenderDeviceId: sender.identity.deviceId,
      );

      expect(recovered.masterKeyBytes, masterKey);
      expect(recovered.trustCheckpoint.manifestDigest, authorized.digest);
      expect(
        () => DeviceKeyGrantCodec.open(
          grant: grant,
          recipient: stranger,
          now: createdAt.add(const Duration(minutes: 1)),
        ),
        throwsA(isA<SyncAuthorizationException>()),
      );
      expect(
        () => DeviceKeyGrantCodec.open(
          grant: grant,
          recipient: recipient,
          now: createdAt.add(const Duration(minutes: 11)),
        ),
        throwsA(isA<SyncAuthorizationException>()),
      );
    },
  );

  test('manifest repository uses ETag compare-and-swap', () async {
    final credentials = await DeviceIdentityManager(
      secretStore: MemorySyncSecretStore(),
    ).loadOrCreate(displayName: 'Owner');
    final crypto = SyncCrypto();
    final keys = await crypto.deriveVaultKeys(
      SecretKey(List<int>.filled(32, 7)),
    );
    final transport = InMemorySyncTransport();
    final repository = EncryptedManifestRepository(
      transport: transport,
      crypto: crypto,
      keys: keys,
    );
    final initial = SyncManifest.initial(
      vaultId: keys.vaultId,
      owner: credentials.identity,
      now: DateTime.utc(2026, 1, 1),
    );
    final stored = await repository.publish(
      manifest: initial,
      signer: credentials,
      expectedEtag: null,
    );
    final next = initial.nextGeneration(
      authorDeviceId: credentials.identity.deviceId,
      generatedAt: DateTime.utc(2026, 1, 2),
    );

    await repository.publish(
      manifest: next,
      signer: credentials,
      expectedEtag: stored.etag,
    );
    expect(
      () => repository.publish(
        manifest: next,
        signer: credentials,
        expectedEtag: stored.etag,
      ),
      throwsA(isA<SyncPreconditionFailed>()),
    );
  });

  test(
    'grant trust anchor rejects a revoked device using an old key',
    () async {
      final owner = await DeviceIdentityManager(
        secretStore: MemorySyncSecretStore(),
      ).loadOrCreate(displayName: 'Owner');
      final revoked = await DeviceIdentityManager(
        secretStore: MemorySyncSecretStore(),
      ).loadOrCreate(displayName: 'Revoked phone');
      final recipient = await DeviceIdentityManager(
        secretStore: MemorySyncSecretStore(),
      ).loadOrCreate(displayName: 'New desktop');
      final masterBytes = Uint8List.fromList(List<int>.filled(32, 91));
      final crypto = SyncCrypto();
      final keys = await crypto.deriveVaultKeys(SecretKey(masterBytes));
      final initial = SyncManifest.initial(
        vaultId: keys.vaultId,
        owner: owner.identity,
        now: DateTime.utc(2026, 4, 1),
      );
      final withOldDevice = SyncManifestAdmin.authorizeDevice(
        manifest: initial,
        actorDeviceId: owner.identity.deviceId,
        newDevice: revoked.identity,
        now: DateTime.utc(2026, 4, 2),
      );
      final beforeRevocation = SyncManifestAdmin.authorizeDevice(
        manifest: withOldDevice,
        actorDeviceId: owner.identity.deviceId,
        newDevice: recipient.identity,
        now: DateTime.utc(2026, 4, 3),
      );
      final trusted = SyncManifestAdmin.revokeDevice(
        manifest: beforeRevocation,
        actorDeviceId: owner.identity.deviceId,
        targetDeviceId: revoked.identity.deviceId,
        now: DateTime.utc(2026, 4, 4),
      );
      final grant = await DeviceKeyGrantCodec.create(
        vaultId: keys.vaultId,
        masterKeyBytes: masterBytes,
        sender: owner,
        recipient: recipient.identity,
        trustCheckpoint: _checkpoint(trusted),
        createdAt: DateTime.utc(2026, 4, 5),
      );
      final recovered = await DeviceKeyGrantCodec.open(
        grant: grant,
        recipient: recipient,
        now: DateTime.utc(2026, 4, 5, 0, 1),
      );

      final fakeRegistry = <String, DeviceRegistration>{
        ...trusted.devices,
        revoked.identity.deviceId:
            beforeRevocation.devices[revoked.identity.deviceId]!,
      };
      final fake = SyncManifest(
        vaultId: keys.vaultId,
        generation: trusted.generation + 1,
        previousManifestDigest: trusted.digest,
        authorDeviceId: revoked.identity.deviceId,
        generatedAt: DateTime.utc(2026, 4, 6),
        devices: fakeRegistry,
        records: trusted.records,
      );
      final forgedEnvelope = await crypto.encryptManifest(
        manifest: fake,
        keys: keys,
        signer: revoked,
      );

      expect(
        () => crypto.decryptManifest(
          envelope: forgedEnvelope,
          keys: keys,
          trustedDevices: recovered.trustCheckpoint.trustedDevices,
        ),
        throwsA(isA<SyncAuthorizationException>()),
      );
    },
  );
}

SyncTrustCheckpoint _checkpoint(SyncManifest manifest) {
  return SyncTrustCheckpoint(
    vaultId: manifest.vaultId,
    generation: manifest.generation,
    manifestDigest: manifest.digest,
    envelopeDigest: 'test-envelope-${manifest.generation}',
    trustedDevices: manifest.devices,
  );
}
