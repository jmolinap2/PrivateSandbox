import 'dart:convert';

import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';

/// Serializes the public-only device pairing request exchanged out of band.
///
/// Private Ed25519/X25519 material never leaves secure storage. The fingerprint
/// is recomputed while decoding so a malformed or altered identity is rejected.
abstract final class PairingRequestCodec {
  static String encode(DeviceIdentity identity) {
    return canonicalJson(identity.toJson());
  }

  static DeviceIdentity decode(String serialized) {
    try {
      final json = Map<String, Object?>.from(jsonDecode(serialized) as Map);
      final identity = DeviceIdentity.fromJson(json);
      final signingKey = base64Decode(identity.signingPublicKeyBase64);
      final exchangeKey = base64Decode(identity.exchangePublicKeyBase64);
      final recomputed = DeviceIdentity.fromPublicKeys(
        displayName: identity.displayName,
        signingPublicKey: signingKey,
        exchangePublicKey: exchangeKey,
        createdAt: identity.createdAt,
      );
      if (recomputed.deviceId != identity.deviceId) {
        throw const SyncIntegrityException(
          'La huella de la solicitud de emparejamiento no coincide.',
        );
      }
      return identity;
    } on SyncException {
      rethrow;
    } catch (error) {
      throw SyncProtocolException(
        'La solicitud de emparejamiento no es un DeviceIdentity válido.',
        error,
      );
    }
  }
}
