import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'sync_protocol.dart';

enum DeviceAuthorizationState { authorized, revoked }

enum DeviceRole { owner, member }

/// Public, non-secret identity of a synchronization device.
///
/// Ed25519 authenticates manifest changes. X25519 is used only to deliver an
/// encrypted master-key grant to a newly authorized device.
class DeviceIdentity {
  final String deviceId;
  final String displayName;
  final String signingPublicKeyBase64;
  final String exchangePublicKeyBase64;
  final DateTime createdAt;

  const DeviceIdentity({
    required this.deviceId,
    required this.displayName,
    required this.signingPublicKeyBase64,
    required this.exchangePublicKeyBase64,
    required this.createdAt,
  });

  factory DeviceIdentity.fromPublicKeys({
    required String displayName,
    required List<int> signingPublicKey,
    required List<int> exchangePublicKey,
    required DateTime createdAt,
  }) {
    final fingerprint = crypto.sha256.convert(<int>[
      ...utf8.encode('private-sandbox-device-id-v1'),
      ...signingPublicKey,
      ...exchangePublicKey,
    ]).toString();
    return DeviceIdentity(
      deviceId: fingerprint,
      displayName: displayName,
      signingPublicKeyBase64: base64Encode(signingPublicKey),
      exchangePublicKeyBase64: base64Encode(exchangePublicKey),
      createdAt: createdAt.toUtc(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'deviceId': deviceId,
    'displayName': displayName,
    'signingPublicKey': signingPublicKeyBase64,
    'exchangePublicKey': exchangePublicKeyBase64,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory DeviceIdentity.fromJson(Map<String, Object?> json) {
    return DeviceIdentity(
      deviceId: json['deviceId']! as String,
      displayName: json['displayName']! as String,
      signingPublicKeyBase64: json['signingPublicKey']! as String,
      exchangePublicKeyBase64: json['exchangePublicKey']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
    );
  }
}

class DeviceRegistration {
  final DeviceIdentity identity;
  final DeviceRole role;
  final DeviceAuthorizationState state;
  final String authorizedByDeviceId;
  final DateTime authorizedAt;
  final DateTime? revokedAt;
  final String? revokedByDeviceId;

  const DeviceRegistration({
    required this.identity,
    required this.role,
    required this.state,
    required this.authorizedByDeviceId,
    required this.authorizedAt,
    this.revokedAt,
    this.revokedByDeviceId,
  });

  bool get isAuthorized => state == DeviceAuthorizationState.authorized;

  DeviceRegistration revoke({
    required String byDeviceId,
    required DateTime at,
  }) {
    return DeviceRegistration(
      identity: identity,
      role: role,
      state: DeviceAuthorizationState.revoked,
      authorizedByDeviceId: authorizedByDeviceId,
      authorizedAt: authorizedAt,
      revokedAt: at.toUtc(),
      revokedByDeviceId: byDeviceId,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'identity': identity.toJson(),
    'role': role.name,
    'state': state.name,
    'authorizedBy': authorizedByDeviceId,
    'authorizedAt': authorizedAt.toUtc().toIso8601String(),
    if (revokedAt != null) 'revokedAt': revokedAt!.toUtc().toIso8601String(),
    if (revokedByDeviceId != null) 'revokedBy': revokedByDeviceId,
  };

  factory DeviceRegistration.fromJson(Map<String, Object?> json) {
    return DeviceRegistration(
      identity: DeviceIdentity.fromJson(
        Map<String, Object?>.from(json['identity']! as Map),
      ),
      role: DeviceRole.values.byName(json['role']! as String),
      state: DeviceAuthorizationState.values.byName(json['state']! as String),
      authorizedByDeviceId: json['authorizedBy']! as String,
      authorizedAt: DateTime.parse(json['authorizedAt']! as String).toUtc(),
      revokedAt: json['revokedAt'] == null
          ? null
          : DateTime.parse(json['revokedAt']! as String).toUtc(),
      revokedByDeviceId: json['revokedBy'] as String?,
    );
  }
}

enum RemoteDirectiveType { lock, logout, wipeLocalData }

/// An authenticated request delivered through the encrypted manifest.
///
/// The synchronization core never executes destructive directives. It exposes
/// them to the host app, which must apply its own confirmation/policy and then
/// acknowledge the directive in a subsequent manifest revision.
class RemoteDeviceDirective {
  final String directiveId;
  final RemoteDirectiveType type;
  final String targetDeviceId;
  final String issuedByDeviceId;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String issuerSignatureBase64;
  final Map<String, String> acknowledgementSignaturesBase64;

  const RemoteDeviceDirective({
    required this.directiveId,
    required this.type,
    required this.targetDeviceId,
    required this.issuedByDeviceId,
    required this.issuedAt,
    this.expiresAt,
    this.issuerSignatureBase64 = '',
    this.acknowledgementSignaturesBase64 = const <String, String>{},
  });

  Set<String> get acknowledgedByDeviceIds =>
      acknowledgementSignaturesBase64.keys.toSet();

  bool isPendingFor(String deviceId, DateTime now) {
    return targetDeviceId == deviceId &&
        !acknowledgedByDeviceIds.contains(deviceId) &&
        (expiresAt == null || now.toUtc().isBefore(expiresAt!));
  }

  Map<String, Object?> issuerSignedJson() => <String, Object?>{
    'id': directiveId,
    'type': type.name,
    'targetDeviceId': targetDeviceId,
    'issuedBy': issuedByDeviceId,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
  };

  Map<String, Object?> acknowledgementSignedJson() => <String, Object?>{
    'context': 'private-sandbox-directive-ack-v1',
    'directive': issuerSignedJson(),
    'issuerSignature': issuerSignatureBase64,
  };

  RemoteDeviceDirective acknowledge(
    String deviceId, {
    required String signatureBase64,
  }) {
    if (deviceId != targetDeviceId) {
      throw const SyncAuthorizationException(
        'Only the target device can acknowledge a remote directive',
      );
    }
    return RemoteDeviceDirective(
      directiveId: directiveId,
      type: type,
      targetDeviceId: targetDeviceId,
      issuedByDeviceId: issuedByDeviceId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      issuerSignatureBase64: issuerSignatureBase64,
      acknowledgementSignaturesBase64: <String, String>{
        ...acknowledgementSignaturesBase64,
        deviceId: signatureBase64,
      },
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    ...issuerSignedJson(),
    'issuerSignature': issuerSignatureBase64,
    'acknowledgements': <String, Object?>{
      for (final entry in acknowledgementSignaturesBase64.entries)
        entry.key: entry.value,
    },
  };

  factory RemoteDeviceDirective.fromJson(Map<String, Object?> json) {
    return RemoteDeviceDirective(
      directiveId: json['id']! as String,
      type: RemoteDirectiveType.values.byName(json['type']! as String),
      targetDeviceId: json['targetDeviceId']! as String,
      issuedByDeviceId: json['issuedBy']! as String,
      issuedAt: DateTime.parse(json['issuedAt']! as String).toUtc(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt']! as String).toUtc(),
      issuerSignatureBase64: json['issuerSignature']! as String,
      acknowledgementSignaturesBase64: Map<String, String>.from(
        (json['acknowledgements']! as Map).map(
          (key, value) => MapEntry(key as String, value as String),
        ),
      ),
    );
  }
}
