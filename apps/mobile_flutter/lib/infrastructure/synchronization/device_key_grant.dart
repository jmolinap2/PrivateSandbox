import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_checkpoint.dart';
import '../../domain/synchronization/sync_protocol.dart';
import 'device_identity_store.dart';

class DeviceKeyGrant {
  final int protocolVersion;
  final String grantId;
  final String vaultId;
  final DeviceIdentity sender;
  final String recipientDeviceId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String ephemeralExchangePublicKeyBase64;
  final String nonceBase64;
  final String cipherTextBase64;
  final String macBase64;
  final String signatureBase64;

  const DeviceKeyGrant({
    required this.protocolVersion,
    required this.grantId,
    required this.vaultId,
    required this.sender,
    required this.recipientDeviceId,
    required this.createdAt,
    required this.expiresAt,
    required this.ephemeralExchangePublicKeyBase64,
    required this.nonceBase64,
    required this.cipherTextBase64,
    required this.macBase64,
    required this.signatureBase64,
  });

  Map<String, Object?> unsignedJson() => <String, Object?>{
    'protocolVersion': protocolVersion,
    'grantId': grantId,
    'vaultId': vaultId,
    'sender': sender.toJson(),
    'recipientDeviceId': recipientDeviceId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'ephemeralExchangePublicKey': ephemeralExchangePublicKeyBase64,
    'nonce': nonceBase64,
    'cipherText': cipherTextBase64,
    'mac': macBase64,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    ...unsignedJson(),
    'signature': signatureBase64,
  };

  factory DeviceKeyGrant.fromJson(Map<String, Object?> json) {
    final protocolVersion = (json['protocolVersion']! as num).toInt();
    SyncProtocol.requireSupported(protocolVersion);
    return DeviceKeyGrant(
      protocolVersion: protocolVersion,
      grantId: json['grantId']! as String,
      vaultId: json['vaultId']! as String,
      sender: DeviceIdentity.fromJson(
        Map<String, Object?>.from(json['sender']! as Map),
      ),
      recipientDeviceId: json['recipientDeviceId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      expiresAt: DateTime.parse(json['expiresAt']! as String).toUtc(),
      ephemeralExchangePublicKeyBase64:
          json['ephemeralExchangePublicKey']! as String,
      nonceBase64: json['nonce']! as String,
      cipherTextBase64: json['cipherText']! as String,
      macBase64: json['mac']! as String,
      signatureBase64: json['signature']! as String,
    );
  }
}

class RecoveredDeviceGrant {
  final String vaultId;
  final DeviceIdentity sender;
  final Uint8List masterKeyBytes;
  final SyncTrustCheckpoint trustCheckpoint;

  const RecoveredDeviceGrant({
    required this.vaultId,
    required this.sender,
    required this.masterKeyBytes,
    required this.trustCheckpoint,
  });
}

/// Creates a short-lived, signed X25519 key grant for device enrollment.
abstract final class DeviceKeyGrantCodec {
  static final X25519 _exchange = X25519();
  static final Ed25519 _signing = Ed25519();
  static final AesGcm _cipher = AesGcm.with256bits();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static Future<DeviceKeyGrant> create({
    required String vaultId,
    required Uint8List masterKeyBytes,
    required DeviceCredentials sender,
    required DeviceIdentity recipient,
    required SyncTrustCheckpoint trustCheckpoint,
    required DateTime createdAt,
    Duration lifetime = const Duration(minutes: 10),
  }) async {
    if (masterKeyBytes.length != 32) {
      throw ArgumentError.value(
        masterKeyBytes.length,
        'masterKeyBytes',
        'Expected a 256-bit vault master key',
      );
    }
    if (trustCheckpoint.vaultId != vaultId ||
        trustCheckpoint.manifestDigest.isEmpty ||
        trustCheckpoint.envelopeDigest.isEmpty) {
      throw const SyncIntegrityException(
        'Key grant requires a valid trust checkpoint for this vault',
      );
    }
    final senderRegistration =
        trustCheckpoint.trustedDevices[sender.identity.deviceId];
    if (senderRegistration == null ||
        !senderRegistration.isAuthorized ||
        senderRegistration.role != DeviceRole.owner ||
        senderRegistration.identity.signingPublicKeyBase64 !=
            sender.identity.signingPublicKeyBase64) {
      throw const SyncAuthorizationException(
        'Only an owner trusted by the checkpoint can create a key grant',
      );
    }
    final recipientRegistration =
        trustCheckpoint.trustedDevices[recipient.deviceId];
    if (recipientRegistration == null ||
        !recipientRegistration.isAuthorized ||
        recipientRegistration.identity.signingPublicKeyBase64 !=
            recipient.signingPublicKeyBase64 ||
        recipientRegistration.identity.exchangePublicKeyBase64 !=
            recipient.exchangePublicKeyBase64) {
      throw const SyncAuthorizationException(
        'Recipient must be authorized in the granted trust checkpoint',
      );
    }
    final ephemeral = await _exchange.newKeyPair();
    final ephemeralData = await ephemeral.extract();
    final recipientPublicKey = SimplePublicKey(
      base64Decode(recipient.exchangePublicKeyBase64),
      type: KeyPairType.x25519,
    );
    final shared = await _exchange.sharedSecretKey(
      keyPair: ephemeralData,
      remotePublicKey: recipientPublicKey,
    );
    final wrappingKey = await _deriveWrappingKey(
      shared: shared,
      vaultId: vaultId,
      senderDeviceId: sender.identity.deviceId,
      recipientDeviceId: recipient.deviceId,
    );
    final normalizedCreatedAt = createdAt.toUtc();
    final expiresAt = normalizedCreatedAt.add(lifetime);
    final aadMap = <String, Object?>{
      'protocolVersion': SyncProtocol.currentVersion,
      'vaultId': vaultId,
      'senderDeviceId': sender.identity.deviceId,
      'recipientDeviceId': recipient.deviceId,
      'createdAt': normalizedCreatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'ephemeralExchangePublicKey': base64Encode(ephemeralData.publicKey.bytes),
    };
    final payload = utf8.encode(
      canonicalJson(<String, Object?>{
        'vaultId': vaultId,
        'masterKey': base64Encode(masterKeyBytes),
        'trustCheckpoint': trustCheckpoint.toJson(),
      }),
    );
    final box = await _cipher.encrypt(
      payload,
      secretKey: wrappingKey,
      aad: utf8.encode(canonicalJson(aadMap)),
    );
    final contentWithoutId = <String, Object?>{
      ...aadMap,
      'sender': sender.identity.toJson(),
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    final grantId = crypto.sha256
        .convert(utf8.encode(canonicalJson(contentWithoutId)))
        .toString();
    final unsigned = <String, Object?>{
      'protocolVersion': SyncProtocol.currentVersion,
      'grantId': grantId,
      'vaultId': vaultId,
      'sender': sender.identity.toJson(),
      'recipientDeviceId': recipient.deviceId,
      'createdAt': normalizedCreatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'ephemeralExchangePublicKey': base64Encode(ephemeralData.publicKey.bytes),
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    final signature = await _signing.sign(
      utf8.encode(canonicalJson(unsigned)),
      keyPair: sender.signingKeyPair,
    );
    ephemeralData.destroy();
    return DeviceKeyGrant(
      protocolVersion: SyncProtocol.currentVersion,
      grantId: grantId,
      vaultId: vaultId,
      sender: sender.identity,
      recipientDeviceId: recipient.deviceId,
      createdAt: normalizedCreatedAt,
      expiresAt: expiresAt,
      ephemeralExchangePublicKeyBase64:
          unsigned['ephemeralExchangePublicKey']! as String,
      nonceBase64: unsigned['nonce']! as String,
      cipherTextBase64: unsigned['cipherText']! as String,
      macBase64: unsigned['mac']! as String,
      signatureBase64: base64Encode(signature.bytes),
    );
  }

  static Future<RecoveredDeviceGrant> open({
    required DeviceKeyGrant grant,
    required DeviceCredentials recipient,
    required DateTime now,
    String? expectedSenderDeviceId,
  }) async {
    SyncProtocol.requireSupported(grant.protocolVersion);
    if (grant.recipientDeviceId != recipient.identity.deviceId) {
      throw const SyncAuthorizationException(
        'The key grant targets a different device',
      );
    }
    if (!now.toUtc().isBefore(grant.expiresAt)) {
      throw const SyncAuthorizationException('The key grant has expired');
    }
    if (expectedSenderDeviceId != null &&
        expectedSenderDeviceId != grant.sender.deviceId) {
      throw const SyncAuthorizationException('Unexpected key grant sender');
    }
    final recomputedSender = DeviceIdentity.fromPublicKeys(
      displayName: grant.sender.displayName,
      signingPublicKey: base64Decode(grant.sender.signingPublicKeyBase64),
      exchangePublicKey: base64Decode(grant.sender.exchangePublicKeyBase64),
      createdAt: grant.sender.createdAt,
    );
    if (recomputedSender.deviceId != grant.sender.deviceId) {
      throw const SyncIntegrityException(
        'Key grant sender fingerprint is invalid',
      );
    }
    final senderSigningKey = SimplePublicKey(
      base64Decode(grant.sender.signingPublicKeyBase64),
      type: KeyPairType.ed25519,
    );
    final signatureIsValid = await _signing.verify(
      utf8.encode(canonicalJson(grant.unsignedJson())),
      signature: Signature(
        base64Decode(grant.signatureBase64),
        publicKey: senderSigningKey,
      ),
    );
    if (!signatureIsValid) {
      throw const SyncIntegrityException('Invalid key grant signature');
    }
    final ephemeralPublicKey = SimplePublicKey(
      base64Decode(grant.ephemeralExchangePublicKeyBase64),
      type: KeyPairType.x25519,
    );
    final shared = await _exchange.sharedSecretKey(
      keyPair: recipient.exchangeKeyPair,
      remotePublicKey: ephemeralPublicKey,
    );
    final wrappingKey = await _deriveWrappingKey(
      shared: shared,
      vaultId: grant.vaultId,
      senderDeviceId: grant.sender.deviceId,
      recipientDeviceId: recipient.identity.deviceId,
    );
    final aadMap = <String, Object?>{
      'protocolVersion': grant.protocolVersion,
      'vaultId': grant.vaultId,
      'senderDeviceId': grant.sender.deviceId,
      'recipientDeviceId': grant.recipientDeviceId,
      'createdAt': grant.createdAt.toUtc().toIso8601String(),
      'expiresAt': grant.expiresAt.toUtc().toIso8601String(),
      'ephemeralExchangePublicKey': grant.ephemeralExchangePublicKeyBase64,
    };
    try {
      final clear = await _cipher.decrypt(
        SecretBox(
          base64Decode(grant.cipherTextBase64),
          nonce: base64Decode(grant.nonceBase64),
          mac: Mac(base64Decode(grant.macBase64)),
        ),
        secretKey: wrappingKey,
        aad: utf8.encode(canonicalJson(aadMap)),
      );
      final payload = Map<String, Object?>.from(
        jsonDecode(utf8.decode(clear)) as Map,
      );
      if (payload['vaultId'] != grant.vaultId) {
        throw const SyncIntegrityException('Key grant vault mismatch');
      }
      final masterKey = Uint8List.fromList(
        base64Decode(payload['masterKey']! as String),
      );
      if (masterKey.length != 32) {
        throw const SyncIntegrityException(
          'Invalid master key length in grant',
        );
      }
      final trustCheckpoint = SyncTrustCheckpoint.fromJson(
        Map<String, Object?>.from(payload['trustCheckpoint']! as Map),
      );
      if (trustCheckpoint.vaultId != grant.vaultId) {
        throw const SyncIntegrityException(
          'Key grant trust checkpoint belongs to a different vault',
        );
      }
      final trustedSender =
          trustCheckpoint.trustedDevices[grant.sender.deviceId];
      if (trustedSender == null ||
          !trustedSender.isAuthorized ||
          trustedSender.role != DeviceRole.owner ||
          trustedSender.identity.signingPublicKeyBase64 !=
              grant.sender.signingPublicKeyBase64) {
        throw const SyncAuthorizationException(
          'Key grant sender is not an owner in its trust checkpoint',
        );
      }
      final trustedRecipient =
          trustCheckpoint.trustedDevices[recipient.identity.deviceId];
      if (trustedRecipient == null ||
          !trustedRecipient.isAuthorized ||
          trustedRecipient.identity.signingPublicKeyBase64 !=
              recipient.identity.signingPublicKeyBase64 ||
          trustedRecipient.identity.exchangePublicKeyBase64 !=
              recipient.identity.exchangePublicKeyBase64) {
        throw const SyncAuthorizationException(
          'Recipient is not authorized by the key grant checkpoint',
        );
      }
      return RecoveredDeviceGrant(
        vaultId: grant.vaultId,
        sender: grant.sender,
        masterKeyBytes: masterKey,
        trustCheckpoint: trustCheckpoint,
      );
    } on SyncException {
      rethrow;
    } catch (error) {
      throw SyncIntegrityException('Unable to authenticate key grant', error);
    }
  }

  static Future<SecretKey> _deriveWrappingKey({
    required SecretKey shared,
    required String vaultId,
    required String senderDeviceId,
    required String recipientDeviceId,
  }) {
    return _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('private-sandbox-device-grant-salt-v1'),
      info: utf8.encode(
        'private-sandbox-device-grant-v1|$vaultId|'
        '$senderDeviceId|$recipientDeviceId',
      ),
    );
  }
}
