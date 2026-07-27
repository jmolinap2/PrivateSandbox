import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/application/synchronization/device_grant_recovery_coordinator.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_checkpoint.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_enrollment_package.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_key_grant.dart';

void main() {
  group('device enrollment package', () {
    test('pairing request round-trips its public DeviceIdentity', () {
      final identity = _identity('Nuevo teléfono', 3);
      final request = DevicePairingRequest(
        requestedAt: DateTime.utc(2026, 7, 26, 12),
        identity: identity,
      );

      final decoded = DeviceEnrollmentPackageCodec.decodePairingRequest(
        DeviceEnrollmentPackageCodec.encodePairingRequest(request),
      );

      expect(decoded.protocolVersion, SyncProtocol.currentVersion);
      expect(decoded.requestedAt, request.requestedAt);
      expect(decoded.identity.toJson(), identity.toJson());
    });

    test('pairing request rejects a modified identity fingerprint', () {
      final request = DevicePairingRequest(
        requestedAt: DateTime.utc(2026, 7, 26),
        identity: _identity('Tablet', 7),
      );
      final json =
          jsonDecode(
                utf8.decode(
                  DeviceEnrollmentPackageCodec.encodePairingRequest(request),
                ),
              )
              as Map<String, dynamic>;
      (json['identity'] as Map<String, dynamic>)['deviceId'] = 'altered';

      expect(
        () => DeviceEnrollmentPackageCodec.decodePairingRequest(
          utf8.encode(jsonEncode(json)),
        ),
        throwsA(isA<SyncIntegrityException>()),
      );
    });

    test('grant envelope round-trips the signed grant fields', () {
      final sender = _identity('Propietario', 11);
      final grant = DeviceKeyGrant(
        protocolVersion: SyncProtocol.currentVersion,
        grantId: 'grant-id',
        vaultId: 'vault-id',
        sender: sender,
        recipientDeviceId: _identity('Receptor', 19).deviceId,
        createdAt: DateTime.utc(2026, 7, 26, 10),
        expiresAt: DateTime.utc(2026, 7, 26, 10, 10),
        ephemeralExchangePublicKeyBase64: base64Encode(
          List<int>.filled(32, 41),
        ),
        nonceBase64: base64Encode(List<int>.filled(12, 43)),
        cipherTextBase64: base64Encode(List<int>.filled(32, 47)),
        macBase64: base64Encode(List<int>.filled(16, 53)),
        signatureBase64: base64Encode(List<int>.filled(64, 59)),
      );

      final decoded = DeviceEnrollmentPackageCodec.decodeGrant(
        DeviceEnrollmentPackageCodec.encodeGrant(grant),
      );

      expect(decoded.toJson(), grant.toJson());
    });
  });

  test(
    'grant recovery persists checkpoint before key and first sync',
    () async {
      final events = <String>[];
      final identity = _identity('Propietario', 23);
      final registration = DeviceRegistration(
        identity: identity,
        role: DeviceRole.owner,
        state: DeviceAuthorizationState.authorized,
        authorizedByDeviceId: identity.deviceId,
        authorizedAt: DateTime.utc(2026, 7, 26),
      );
      final checkpoint = SyncTrustCheckpoint(
        vaultId: 'vault',
        generation: 4,
        manifestDigest: 'manifest-digest',
        envelopeDigest: 'envelope-digest',
        trustedDevices: <String, DeviceRegistration>{
          identity.deviceId: registration,
        },
      );
      final store = _RecordingCheckpointStore(events);
      final coordinator = DeviceGrantRecoveryCoordinator(
        checkpointStore: store,
        importMasterKey: (bytes) async {
          expect(events, <String>['checkpoint']);
          expect(bytes, hasLength(32));
          events.add('master-key');
        },
        synchronize: () async {
          expect(events, <String>['checkpoint', 'master-key']);
          events.add('sync');
        },
      );

      await coordinator.install(
        RecoveredDeviceGrant(
          vaultId: checkpoint.vaultId,
          sender: identity,
          masterKeyBytes: Uint8List(32),
          trustCheckpoint: checkpoint,
        ),
      );

      expect(events, <String>['checkpoint', 'master-key', 'sync']);
      expect(await store.load('vault'), same(checkpoint));
    },
  );
}

class _RecordingCheckpointStore implements SyncTrustCheckpointStore {
  final List<String> events;
  SyncTrustCheckpoint? checkpoint;

  _RecordingCheckpointStore(this.events);

  @override
  Future<void> clear(String vaultId) async {
    checkpoint = null;
  }

  @override
  Future<SyncTrustCheckpoint?> load(String vaultId) async => checkpoint;

  @override
  Future<void> save(SyncTrustCheckpoint value) async {
    events.add('checkpoint');
    checkpoint = value;
  }
}

DeviceIdentity _identity(String name, int seed) {
  return DeviceIdentity.fromPublicKeys(
    displayName: name,
    signingPublicKey: List<int>.generate(32, (index) => seed + index),
    exchangePublicKey: List<int>.generate(32, (index) => seed * 2 + index),
    createdAt: DateTime.utc(2026, 7, seed.clamp(1, 28)),
  );
}
