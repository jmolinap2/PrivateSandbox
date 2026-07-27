import 'dart:convert';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_protocol.dart';
import 'device_key_grant.dart';

/// Public request produced by a device that wants to join an existing vault.
///
/// It intentionally contains only [DeviceIdentity] public keys. The signing
/// and exchange private keys remain in the device's secure storage.
class DevicePairingRequest {
  static const String kind = 'private-sandbox-device-pairing-request';
  static const int packageVersion = 1;

  final int protocolVersion;
  final DateTime requestedAt;
  final DeviceIdentity identity;

  const DevicePairingRequest({
    this.protocolVersion = SyncProtocol.currentVersion,
    required this.requestedAt,
    required this.identity,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    'packageVersion': packageVersion,
    'protocolVersion': protocolVersion,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
    'identity': identity.toJson(),
  };

  factory DevicePairingRequest.fromJson(Map<String, Object?> json) {
    if (json['kind'] != kind || json['packageVersion'] != packageVersion) {
      throw const FormatException(
        'El archivo no es una solicitud de dispositivo compatible.',
      );
    }
    final protocolVersion = (json['protocolVersion']! as num).toInt();
    SyncProtocol.requireSupported(protocolVersion);
    final identity = DeviceIdentity.fromJson(
      Map<String, Object?>.from(json['identity']! as Map),
    );
    _validateIdentity(identity);
    return DevicePairingRequest(
      protocolVersion: protocolVersion,
      requestedAt: DateTime.parse(json['requestedAt']! as String).toUtc(),
      identity: identity,
    );
  }

  static void _validateIdentity(DeviceIdentity identity) {
    if (identity.displayName.trim().isEmpty ||
        identity.displayName.length > 128) {
      throw const FormatException('El nombre del dispositivo no es válido.');
    }
    final signingKey = base64Decode(identity.signingPublicKeyBase64);
    final exchangeKey = base64Decode(identity.exchangePublicKeyBase64);
    if (signingKey.length != 32 || exchangeKey.length != 32) {
      throw const FormatException(
        'La solicitud contiene claves públicas no válidas.',
      );
    }
    final recomputed = DeviceIdentity.fromPublicKeys(
      displayName: identity.displayName,
      signingPublicKey: signingKey,
      exchangePublicKey: exchangeKey,
      createdAt: identity.createdAt,
    );
    if (recomputed.deviceId != identity.deviceId) {
      throw const SyncIntegrityException(
        'La huella de la solicitud de dispositivo no coincide.',
      );
    }
  }
}

/// JSON envelope used for the short-lived `.psdg` device key grant.
abstract final class DeviceEnrollmentPackageCodec {
  static const String _grantKind = 'private-sandbox-device-key-grant';
  static const int _packageVersion = 1;

  static List<int> encodePairingRequest(DevicePairingRequest request) {
    return utf8.encode(canonicalJson(request.toJson()));
  }

  static DevicePairingRequest decodePairingRequest(List<int> bytes) {
    try {
      final json = Map<String, Object?>.from(
        jsonDecode(utf8.decode(bytes, allowMalformed: false)) as Map,
      );
      return DevicePairingRequest.fromJson(json);
    } on SyncException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'La solicitud de dispositivo está dañada o no es válida.',
        error,
      );
    }
  }

  static List<int> encodeGrant(DeviceKeyGrant grant) {
    return utf8.encode(
      canonicalJson(<String, Object?>{
        'kind': _grantKind,
        'packageVersion': _packageVersion,
        'grant': grant.toJson(),
      }),
    );
  }

  static DeviceKeyGrant decodeGrant(List<int> bytes) {
    try {
      final json = Map<String, Object?>.from(
        jsonDecode(utf8.decode(bytes, allowMalformed: false)) as Map,
      );
      if (json['kind'] != _grantKind ||
          json['packageVersion'] != _packageVersion) {
        throw const FormatException(
          'El archivo no es una concesión de dispositivo compatible.',
        );
      }
      return DeviceKeyGrant.fromJson(
        Map<String, Object?>.from(json['grant']! as Map),
      );
    } on SyncException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'La concesión de dispositivo está dañada o no es válida.',
        error,
      );
    }
  }
}
