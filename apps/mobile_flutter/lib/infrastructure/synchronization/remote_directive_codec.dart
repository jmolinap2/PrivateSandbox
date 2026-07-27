import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../shared/utils/random_bytes.dart';
import 'device_identity_store.dart';

/// Signs remote directives independently from the manifest revision.
///
/// This lets member devices publish normal file changes without gaining the
/// ability to forge an owner's lock/logout/wipe command or another device's
/// acknowledgement.
abstract final class RemoteDirectiveCodec {
  static final Ed25519 _signing = Ed25519();

  static Future<RemoteDeviceDirective> create({
    String? directiveId,
    required RemoteDirectiveType type,
    required String targetDeviceId,
    required DeviceCredentials issuer,
    required DateTime issuedAt,
    DateTime? expiresAt,
  }) async {
    final unsigned = RemoteDeviceDirective(
      directiveId:
          directiveId ?? base64UrlEncode(randomBytes(18)).replaceAll('=', ''),
      type: type,
      targetDeviceId: targetDeviceId,
      issuedByDeviceId: issuer.identity.deviceId,
      issuedAt: issuedAt.toUtc(),
      expiresAt: expiresAt?.toUtc(),
    );
    final signature = await _signing.sign(
      utf8.encode(canonicalJson(unsigned.issuerSignedJson())),
      keyPair: issuer.signingKeyPair,
    );
    return RemoteDeviceDirective(
      directiveId: unsigned.directiveId,
      type: unsigned.type,
      targetDeviceId: unsigned.targetDeviceId,
      issuedByDeviceId: unsigned.issuedByDeviceId,
      issuedAt: unsigned.issuedAt,
      expiresAt: unsigned.expiresAt,
      issuerSignatureBase64: base64Encode(signature.bytes),
    );
  }

  static Future<String> signAcknowledgement({
    required RemoteDeviceDirective directive,
    required DeviceCredentials target,
  }) async {
    if (directive.targetDeviceId != target.identity.deviceId) {
      throw const SyncAuthorizationException(
        'Only the target device can sign a directive acknowledgement',
      );
    }
    final signature = await _signing.sign(
      utf8.encode(canonicalJson(directive.acknowledgementSignedJson())),
      keyPair: target.signingKeyPair,
    );
    return base64Encode(signature.bytes);
  }

  static Future<void> verify({
    required RemoteDeviceDirective directive,
    required Map<String, DeviceRegistration> devices,
  }) async {
    final issuer = devices[directive.issuedByDeviceId];
    if (issuer == null || issuer.role != DeviceRole.owner) {
      throw const SyncAuthorizationException(
        'Remote directive was not issued by a registered owner',
      );
    }
    if (!devices.containsKey(directive.targetDeviceId)) {
      throw const SyncAuthorizationException(
        'Remote directive targets an unknown device',
      );
    }
    final issuerKey = SimplePublicKey(
      base64Decode(issuer.identity.signingPublicKeyBase64),
      type: KeyPairType.ed25519,
    );
    final issuerValid = await _signing.verify(
      utf8.encode(canonicalJson(directive.issuerSignedJson())),
      signature: Signature(
        base64Decode(directive.issuerSignatureBase64),
        publicKey: issuerKey,
      ),
    );
    if (!issuerValid) {
      throw const SyncIntegrityException('Invalid remote directive signature');
    }
    for (final acknowledgement
        in directive.acknowledgementSignaturesBase64.entries) {
      if (acknowledgement.key != directive.targetDeviceId) {
        throw const SyncAuthorizationException(
          'A directive was acknowledged by a non-target device',
        );
      }
      final target = devices[acknowledgement.key]!;
      final targetKey = SimplePublicKey(
        base64Decode(target.identity.signingPublicKeyBase64),
        type: KeyPairType.ed25519,
      );
      final acknowledgementValid = await _signing.verify(
        utf8.encode(canonicalJson(directive.acknowledgementSignedJson())),
        signature: Signature(
          base64Decode(acknowledgement.value),
          publicKey: targetKey,
        ),
      );
      if (!acknowledgementValid) {
        throw const SyncIntegrityException(
          'Invalid remote directive acknowledgement signature',
        );
      }
    }
  }

  static Future<void> verifyAll({
    required Iterable<RemoteDeviceDirective> directives,
    required Map<String, DeviceRegistration> devices,
  }) async {
    for (final directive in directives) {
      await verify(directive: directive, devices: devices);
    }
  }
}
