import 'dart:typed_data';

import 'package:desktop_companion_flutter/src/models/stored_enrollment.dart';
import 'package:desktop_companion_flutter/src/models/trusted_remote_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_checkpoint.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';

void main() {
  final owner = DeviceIdentity.fromPublicKeys(
    displayName: 'Teléfono propietario',
    signingPublicKey: List<int>.filled(32, 7),
    exchangePublicKey: List<int>.filled(32, 9),
    createdAt: DateTime.utc(2026, 7, 20),
  );

  test('trusted checkpoint and enrollment round-trip', () {
    final initial = SyncManifest.initial(
      vaultId: 'vault-opaque-id',
      owner: owner,
      now: DateTime.utc(2026, 7, 26),
    );
    final trust = TrustedRemoteState.bootstrap(
      vaultId: initial.vaultId,
      owner: owner,
    ).advance(manifest: initial, newEnvelopeDigest: 'a' * 64);
    final enrollment = StoredEnrollment(
      masterKeyBytes: Uint8List.fromList(
        List<int>.generate(32, (index) => index),
      ),
      trust: trust,
    );

    final decoded = StoredEnrollment.fromJson(enrollment.toJson());

    expect(decoded.masterKeyBytes, orderedEquals(enrollment.masterKeyBytes));
    expect(decoded.trust.ownerDeviceId, owner.deviceId);
    expect(decoded.trust.minimumGeneration, initial.generation);
    expect(decoded.trust.manifestDigest, initial.digest);
  });

  test('imports the authenticated checkpoint carried by a grant', () {
    final manifest = SyncManifest.initial(
      vaultId: 'vault-opaque-id',
      owner: owner,
      now: DateTime.utc(2026, 7, 26),
    );
    final checkpoint = SyncTrustCheckpoint(
      vaultId: manifest.vaultId,
      generation: manifest.generation,
      manifestDigest: manifest.digest,
      envelopeDigest: 'c' * 64,
      trustedDevices: manifest.devices,
    );

    final trust = TrustedRemoteState.fromCheckpoint(
      checkpoint: checkpoint,
      ownerDeviceId: owner.deviceId,
    );

    expect(trust.minimumGeneration, checkpoint.generation);
    expect(trust.manifestDigest, checkpoint.manifestDigest);
    expect(trust.envelopeDigest, checkpoint.envelopeDigest);
    expect(trust.trustedDevices.keys, contains(owner.deviceId));
  });

  test('rejects equivocation at an already observed generation', () {
    final first = SyncManifest.initial(
      vaultId: 'vault-opaque-id',
      owner: owner,
      now: DateTime.utc(2026, 7, 26),
    );
    final trust = TrustedRemoteState.bootstrap(
      vaultId: first.vaultId,
      owner: owner,
    ).advance(manifest: first, newEnvelopeDigest: 'a' * 64);
    final altered = SyncManifest.initial(
      vaultId: first.vaultId,
      owner: owner,
      now: DateTime.utc(2026, 7, 27),
    );

    expect(
      () => trust.advance(manifest: altered, newEnvelopeDigest: 'b' * 64),
      throwsA(isA<SyncIntegrityException>()),
    );
  });
}
