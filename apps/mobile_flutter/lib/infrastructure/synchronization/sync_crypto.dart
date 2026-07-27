import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_manifest.dart';
import '../../domain/synchronization/sync_protocol.dart';
import 'device_identity_store.dart';
import 'remote_directive_codec.dart';

class SyncVaultKeys {
  final String vaultId;
  final SecretKey manifestKey;

  const SyncVaultKeys({required this.vaultId, required this.manifestKey});
}

class EncryptedSyncEnvelope {
  final int protocolVersion;
  final String objectKind;
  final String vaultId;
  final int generation;
  final String authorDeviceId;
  final DateTime createdAt;
  final String nonceBase64;
  final String cipherTextBase64;
  final String macBase64;
  final String signatureBase64;

  const EncryptedSyncEnvelope({
    required this.protocolVersion,
    required this.objectKind,
    required this.vaultId,
    required this.generation,
    required this.authorDeviceId,
    required this.createdAt,
    required this.nonceBase64,
    required this.cipherTextBase64,
    required this.macBase64,
    required this.signatureBase64,
  });

  Map<String, Object?> headerJson() => <String, Object?>{
    'protocolVersion': protocolVersion,
    'objectKind': objectKind,
    'vaultId': vaultId,
    'generation': generation,
    'authorDeviceId': authorDeviceId,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> unsignedJson() => <String, Object?>{
    ...headerJson(),
    'nonce': nonceBase64,
    'cipherText': cipherTextBase64,
    'mac': macBase64,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    ...unsignedJson(),
    'signature': signatureBase64,
  };

  factory EncryptedSyncEnvelope.fromJson(Map<String, Object?> json) {
    final version = (json['protocolVersion']! as num).toInt();
    SyncProtocol.requireSupported(version);
    return EncryptedSyncEnvelope(
      protocolVersion: version,
      objectKind: json['objectKind']! as String,
      vaultId: json['vaultId']! as String,
      generation: (json['generation']! as num).toInt(),
      authorDeviceId: json['authorDeviceId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      nonceBase64: json['nonce']! as String,
      cipherTextBase64: json['cipherText']! as String,
      macBase64: json['mac']! as String,
      signatureBase64: json['signature']! as String,
    );
  }
}

/// E2EE codec for the private manifest.
///
/// The server sees only a vault-scoped opaque identifier, generation, author
/// fingerprint and ciphertext. Names, paths, salts, device labels, selection
/// state and history all remain inside AES-256-GCM.
class SyncCrypto {
  static const String manifestObjectKind = 'vault-manifest';
  final AesGcm _cipher = AesGcm.with256bits();
  final Ed25519 _signing = Ed25519();
  final Hkdf _manifestKdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final Hkdf _vaultIdKdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final Sha256 _sha256 = Sha256();

  Future<SyncVaultKeys> deriveVaultKeys(SecretKey masterKey) async {
    final manifestKey = await _manifestKdf.deriveKey(
      secretKey: masterKey,
      nonce: utf8.encode('private-sandbox-sync-salt-v1'),
      info: utf8.encode('private-sandbox-sync-manifest-key-v1'),
    );
    final vaultIdMaterial = await _vaultIdKdf.deriveKey(
      secretKey: masterKey,
      nonce: utf8.encode('private-sandbox-sync-salt-v1'),
      info: utf8.encode('private-sandbox-sync-vault-id-v1'),
    );
    final digest = await _sha256.hash(await vaultIdMaterial.extractBytes());
    return SyncVaultKeys(
      vaultId: digest.bytes
          .take(20)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
      manifestKey: manifestKey,
    );
  }

  Future<EncryptedSyncEnvelope> encryptManifest({
    required SyncManifest manifest,
    required SyncVaultKeys keys,
    required DeviceCredentials signer,
  }) async {
    if (manifest.vaultId != keys.vaultId) {
      throw const SyncIntegrityException('Manifest uses a different vault ID');
    }
    if (manifest.authorDeviceId != signer.identity.deviceId) {
      throw const SyncAuthorizationException(
        'Manifest author does not match signing device',
      );
    }
    final registration = manifest.requireAuthorizedDevice(
      signer.identity.deviceId,
    );
    if (registration.identity.signingPublicKeyBase64 !=
        signer.identity.signingPublicKeyBase64) {
      throw const SyncAuthorizationException(
        'Signing key does not match device registry',
      );
    }
    _validateDeviceIdentities(manifest.devices);
    await RemoteDirectiveCodec.verifyAll(
      directives: manifest.directives.values,
      devices: manifest.devices,
    );
    final header = <String, Object?>{
      'protocolVersion': manifest.protocolVersion,
      'objectKind': manifestObjectKind,
      'vaultId': manifest.vaultId,
      'generation': manifest.generation,
      'authorDeviceId': manifest.authorDeviceId,
      'createdAt': manifest.generatedAt.toUtc().toIso8601String(),
    };
    final box = await _cipher.encrypt(
      utf8.encode(canonicalJson(manifest.toJson())),
      secretKey: keys.manifestKey,
      aad: utf8.encode(canonicalJson(header)),
    );
    final unsigned = <String, Object?>{
      ...header,
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    final signature = await _signing.sign(
      utf8.encode(canonicalJson(unsigned)),
      keyPair: signer.signingKeyPair,
    );
    return EncryptedSyncEnvelope(
      protocolVersion: manifest.protocolVersion,
      objectKind: manifestObjectKind,
      vaultId: manifest.vaultId,
      generation: manifest.generation,
      authorDeviceId: manifest.authorDeviceId,
      createdAt: manifest.generatedAt,
      nonceBase64: unsigned['nonce']! as String,
      cipherTextBase64: unsigned['cipherText']! as String,
      macBase64: unsigned['mac']! as String,
      signatureBase64: base64Encode(signature.bytes),
    );
  }

  Future<SyncManifest> decryptManifest({
    required EncryptedSyncEnvelope envelope,
    required SyncVaultKeys keys,
    Map<String, DeviceRegistration>? trustedDevices,
  }) async {
    SyncProtocol.requireSupported(envelope.protocolVersion);
    if (envelope.objectKind != manifestObjectKind ||
        envelope.vaultId != keys.vaultId) {
      throw const SyncIntegrityException('Unexpected encrypted sync object');
    }
    try {
      final clear = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope.cipherTextBase64),
          nonce: base64Decode(envelope.nonceBase64),
          mac: Mac(base64Decode(envelope.macBase64)),
        ),
        secretKey: keys.manifestKey,
        aad: utf8.encode(canonicalJson(envelope.headerJson())),
      );
      final manifest = SyncManifest.fromJson(
        Map<String, Object?>.from(jsonDecode(utf8.decode(clear)) as Map),
      );
      if (manifest.vaultId != envelope.vaultId ||
          manifest.protocolVersion != envelope.protocolVersion ||
          manifest.generation != envelope.generation ||
          manifest.authorDeviceId != envelope.authorDeviceId ||
          manifest.generatedAt != envelope.createdAt) {
        throw const SyncIntegrityException(
          'Encrypted envelope and manifest fields disagree',
        );
      }
      final author = manifest.requireAuthorizedDevice(envelope.authorDeviceId);
      final previouslyTrusted = trustedDevices?[envelope.authorDeviceId];
      if (trustedDevices != null &&
          (previouslyTrusted == null ||
              !previouslyTrusted.isAuthorized ||
              previouslyTrusted.identity.signingPublicKeyBase64 !=
                  author.identity.signingPublicKeyBase64)) {
        throw const SyncAuthorizationException(
          'Manifest author is not trusted by the previous registry',
        );
      }
      _validateDeviceIdentities(manifest.devices);
      if (trustedDevices != null) {
        _validateDeviceRegistryTransition(
          previous: trustedDevices,
          current: manifest.devices,
          authorDeviceId: envelope.authorDeviceId,
        );
      }
      final publicKey = SimplePublicKey(
        base64Decode(author.identity.signingPublicKeyBase64),
        type: KeyPairType.ed25519,
      );
      final signatureIsValid = await _signing.verify(
        utf8.encode(canonicalJson(envelope.unsignedJson())),
        signature: Signature(
          base64Decode(envelope.signatureBase64),
          publicKey: publicKey,
        ),
      );
      if (!signatureIsValid) {
        throw const SyncIntegrityException('Invalid manifest signature');
      }
      await RemoteDirectiveCodec.verifyAll(
        directives: manifest.directives.values,
        devices: manifest.devices,
      );
      return manifest;
    } on SyncException {
      rethrow;
    } catch (error) {
      throw SyncIntegrityException(
        'Unable to authenticate encrypted manifest',
        error,
      );
    }
  }

  Uint8List encodeEnvelope(EncryptedSyncEnvelope envelope) {
    return Uint8List.fromList(utf8.encode(canonicalJson(envelope.toJson())));
  }

  EncryptedSyncEnvelope decodeEnvelope(List<int> bytes) {
    if (bytes.length > SyncProtocol.maximumManifestBytes) {
      throw const SyncProtocolException('Remote manifest exceeds size limit');
    }
    try {
      return EncryptedSyncEnvelope.fromJson(
        Map<String, Object?>.from(jsonDecode(utf8.decode(bytes)) as Map),
      );
    } on SyncException {
      rethrow;
    } catch (error) {
      throw SyncProtocolException('Malformed encrypted manifest', error);
    }
  }

  static void _validateDeviceIdentities(
    Map<String, DeviceRegistration> devices,
  ) {
    if (devices.isEmpty ||
        !devices.values.any(
          (registration) =>
              registration.isAuthorized &&
              registration.role == DeviceRole.owner,
        )) {
      throw const SyncAuthorizationException(
        'A sync vault must retain at least one authorized owner',
      );
    }
    for (final entry in devices.entries) {
      final identity = entry.value.identity;
      final recomputed = DeviceIdentity.fromPublicKeys(
        displayName: identity.displayName,
        signingPublicKey: base64Decode(identity.signingPublicKeyBase64),
        exchangePublicKey: base64Decode(identity.exchangePublicKeyBase64),
        createdAt: identity.createdAt,
      );
      if (entry.key != identity.deviceId ||
          identity.deviceId != recomputed.deviceId) {
        throw const SyncIntegrityException(
          'Device registry contains an invalid identity fingerprint',
        );
      }
    }
  }

  static void _validateDeviceRegistryTransition({
    required Map<String, DeviceRegistration> previous,
    required Map<String, DeviceRegistration> current,
    required String authorDeviceId,
  }) {
    final author = previous[authorDeviceId]!;
    final changed =
        canonicalJson(_deviceRegistryJson(previous)) !=
        canonicalJson(_deviceRegistryJson(current));
    if (changed && author.role != DeviceRole.owner) {
      throw const SyncAuthorizationException(
        'Only an existing owner can change the device registry',
      );
    }
    for (final entry in previous.entries) {
      final next = current[entry.key];
      if (next == null) {
        throw const SyncAuthorizationException(
          'Device registry entries cannot be removed',
        );
      }
      final old = entry.value;
      if (canonicalJson(old.identity.toJson()) !=
              canonicalJson(next.identity.toJson()) ||
          old.role != next.role ||
          old.authorizedByDeviceId != next.authorizedByDeviceId ||
          old.authorizedAt != next.authorizedAt) {
        throw const SyncAuthorizationException(
          'Existing device identity and authorization history are immutable',
        );
      }
      if (old.state == DeviceAuthorizationState.revoked) {
        if (canonicalJson(old.toJson()) != canonicalJson(next.toJson())) {
          throw const SyncAuthorizationException(
            'A revoked device cannot be reactivated or modified',
          );
        }
      } else if (next.state == DeviceAuthorizationState.revoked) {
        if (next.revokedByDeviceId != authorDeviceId ||
            next.revokedAt == null) {
          throw const SyncAuthorizationException(
            'Device revocation must identify the owner that signed it',
          );
        }
      } else if (canonicalJson(old.toJson()) != canonicalJson(next.toJson())) {
        throw const SyncAuthorizationException(
          'Invalid mutation of an authorized device registration',
        );
      }
    }
    for (final entry in current.entries) {
      if (previous.containsKey(entry.key)) continue;
      final registration = entry.value;
      if (!registration.isAuthorized ||
          registration.authorizedByDeviceId != authorDeviceId ||
          registration.revokedAt != null ||
          registration.revokedByDeviceId != null) {
        throw const SyncAuthorizationException(
          'New device registration is not a valid owner authorization',
        );
      }
    }
  }

  static Map<String, Object?> _deviceRegistryJson(
    Map<String, DeviceRegistration> devices,
  ) {
    return <String, Object?>{
      for (final entry in devices.entries) entry.key: entry.value.toJson(),
    };
  }
}
