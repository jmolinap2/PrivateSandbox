import 'dart:convert';

import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_checkpoint.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';

/// Locally pinned trust and anti-rollback checkpoint for one remote vault.
class TrustedRemoteState {
  static const int formatVersion = 1;

  final String vaultId;
  final String ownerDeviceId;
  final int minimumGeneration;
  final String? manifestDigest;
  final String? envelopeDigest;
  final Map<String, DeviceRegistration> trustedDevices;

  TrustedRemoteState({
    required this.vaultId,
    required this.ownerDeviceId,
    required this.minimumGeneration,
    required this.manifestDigest,
    required this.envelopeDigest,
    required Map<String, DeviceRegistration> trustedDevices,
  }) : trustedDevices = Map.unmodifiable(trustedDevices) {
    if (vaultId.isEmpty || ownerDeviceId.isEmpty || minimumGeneration < 0) {
      throw ArgumentError('Estado remoto de confianza inválido.');
    }
    final owner = this.trustedDevices[ownerDeviceId];
    if (owner == null || owner.role != DeviceRole.owner) {
      throw const SyncAuthorizationException(
        'El estado de confianza no contiene al propietario fijado.',
      );
    }
    _validateRegistry(this.trustedDevices);
  }

  factory TrustedRemoteState.fromCheckpoint({
    required SyncTrustCheckpoint checkpoint,
    required String ownerDeviceId,
  }) {
    if (checkpoint.generation < 0 ||
        !_isSha256(checkpoint.manifestDigest) ||
        !_isSha256(checkpoint.envelopeDigest)) {
      throw const SyncIntegrityException(
        'El grant no contiene un checkpoint remoto completo.',
      );
    }
    final owner = checkpoint.trustedDevices[ownerDeviceId];
    if (owner == null ||
        !owner.isAuthorized ||
        owner.role != DeviceRole.owner ||
        owner.identity.deviceId != ownerDeviceId) {
      throw const SyncAuthorizationException(
        'El emisor no es un propietario autorizado en el checkpoint.',
      );
    }
    return TrustedRemoteState(
      vaultId: checkpoint.vaultId,
      ownerDeviceId: ownerDeviceId,
      minimumGeneration: checkpoint.generation,
      manifestDigest: checkpoint.manifestDigest,
      envelopeDigest: checkpoint.envelopeDigest,
      trustedDevices: checkpoint.trustedDevices,
    );
  }

  factory TrustedRemoteState.bootstrap({
    required String vaultId,
    required DeviceIdentity owner,
  }) {
    final ownerRegistration = DeviceRegistration(
      identity: owner,
      role: DeviceRole.owner,
      state: DeviceAuthorizationState.authorized,
      authorizedByDeviceId: owner.deviceId,
      authorizedAt: owner.createdAt,
    );
    return TrustedRemoteState(
      vaultId: vaultId,
      ownerDeviceId: owner.deviceId,
      minimumGeneration: 0,
      manifestDigest: null,
      envelopeDigest: null,
      trustedDevices: <String, DeviceRegistration>{
        owner.deviceId: ownerRegistration,
      },
    );
  }

  TrustedRemoteState advance({
    required SyncManifest manifest,
    required String newEnvelopeDigest,
  }) {
    if (manifest.vaultId != vaultId) {
      throw const SyncIntegrityException(
        'El manifiesto remoto pertenece a otra bóveda.',
      );
    }
    if (manifest.generation < minimumGeneration) {
      throw const SyncIntegrityException(
        'Se detectó una reversión del manifiesto remoto.',
      );
    }
    if (manifest.generation == minimumGeneration && manifestDigest != null) {
      if (manifest.digest != manifestDigest ||
          (envelopeDigest != null && newEnvelopeDigest != envelopeDigest)) {
        throw const SyncIntegrityException(
          'Dos manifiestos distintos usan la misma generación.',
        );
      }
    }
    final owner = manifest.devices[ownerDeviceId];
    if (owner == null || owner.role != DeviceRole.owner) {
      throw const SyncAuthorizationException(
        'El propietario fijado ya no figura como propietario remoto.',
      );
    }
    return TrustedRemoteState(
      vaultId: vaultId,
      ownerDeviceId: ownerDeviceId,
      minimumGeneration: manifest.generation,
      manifestDigest: manifest.digest,
      envelopeDigest: newEnvelopeDigest,
      trustedDevices: manifest.devices,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'formatVersion': formatVersion,
    'vaultId': vaultId,
    'ownerDeviceId': ownerDeviceId,
    'minimumGeneration': minimumGeneration,
    if (manifestDigest != null) 'manifestDigest': manifestDigest,
    if (envelopeDigest != null) 'envelopeDigest': envelopeDigest,
    'trustedDevices': <String, Object?>{
      for (final entry
          in (trustedDevices.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key))))
        entry.key: entry.value.toJson(),
    },
  };

  factory TrustedRemoteState.fromJson(Map<String, Object?> json) {
    if (json['formatVersion'] != formatVersion) {
      throw const SyncProtocolException(
        'Versión de estado remoto local no compatible.',
      );
    }
    return TrustedRemoteState(
      vaultId: json['vaultId']! as String,
      ownerDeviceId: json['ownerDeviceId']! as String,
      minimumGeneration: (json['minimumGeneration']! as num).toInt(),
      manifestDigest: json['manifestDigest'] as String?,
      envelopeDigest: json['envelopeDigest'] as String?,
      trustedDevices: (json['trustedDevices']! as Map).map(
        (key, value) => MapEntry(
          key as String,
          DeviceRegistration.fromJson(Map<String, Object?>.from(value as Map)),
        ),
      ),
    );
  }

  static bool _isSha256(String value) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
  }

  static void _validateRegistry(Map<String, DeviceRegistration> registrations) {
    for (final entry in registrations.entries) {
      final identity = entry.value.identity;
      try {
        final recomputed = DeviceIdentity.fromPublicKeys(
          displayName: identity.displayName,
          signingPublicKey: base64Decode(identity.signingPublicKeyBase64),
          exchangePublicKey: base64Decode(identity.exchangePublicKeyBase64),
          createdAt: identity.createdAt,
        );
        if (entry.key != identity.deviceId ||
            recomputed.deviceId != identity.deviceId) {
          throw const SyncIntegrityException(
            'El registro contiene una identidad de dispositivo inconsistente.',
          );
        }
      } on SyncException {
        rethrow;
      } catch (error) {
        throw SyncIntegrityException(
          'El registro contiene claves públicas inválidas.',
          error,
        );
      }
    }
  }
}
