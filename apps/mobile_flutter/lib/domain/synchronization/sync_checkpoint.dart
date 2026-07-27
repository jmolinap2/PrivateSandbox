import 'device_identity.dart';

/// Durable anti-rollback state retained locally after an authenticated read.
class SyncTrustCheckpoint {
  final String vaultId;
  final int generation;
  final String manifestDigest;
  final String envelopeDigest;
  final Map<String, DeviceRegistration> trustedDevices;

  const SyncTrustCheckpoint({
    required this.vaultId,
    required this.generation,
    required this.manifestDigest,
    required this.envelopeDigest,
    required this.trustedDevices,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'vaultId': vaultId,
    'generation': generation,
    'manifestDigest': manifestDigest,
    'envelopeDigest': envelopeDigest,
    'trustedDevices': <String, Object?>{
      for (final entry in trustedDevices.entries)
        entry.key: entry.value.toJson(),
    },
  };

  factory SyncTrustCheckpoint.fromJson(Map<String, Object?> json) {
    return SyncTrustCheckpoint(
      vaultId: json['vaultId']! as String,
      generation: (json['generation']! as num).toInt(),
      manifestDigest: json['manifestDigest']! as String,
      envelopeDigest: json['envelopeDigest']! as String,
      trustedDevices: (json['trustedDevices']! as Map).map(
        (key, value) => MapEntry(
          key as String,
          DeviceRegistration.fromJson(Map<String, Object?>.from(value as Map)),
        ),
      ),
    );
  }
}

abstract interface class SyncTrustCheckpointStore {
  Future<SyncTrustCheckpoint?> load(String vaultId);

  Future<void> save(SyncTrustCheckpoint checkpoint);

  Future<void> clear(String vaultId);
}
