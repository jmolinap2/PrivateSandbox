import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'device_identity.dart';
import 'sync_protocol.dart';

enum VectorRelation { before, after, equal, concurrent }

/// A compact version vector used to distinguish causality from concurrency.
class VersionVector {
  final Map<String, int> counters;

  VersionVector(Map<String, int> counters)
    : counters = Map.unmodifiable(
        Map<String, int>.fromEntries(
          (counters.entries.toList()
                ..sort((left, right) => left.key.compareTo(right.key)))
              .map((entry) {
                if (entry.value < 0) {
                  throw ArgumentError.value(
                    entry.value,
                    entry.key,
                    'Negative counter',
                  );
                }
                return entry;
              }),
        ),
      );

  const VersionVector.empty() : counters = const <String, int>{};

  int operator [](String deviceId) => counters[deviceId] ?? 0;

  VersionVector increment(String deviceId) {
    return VersionVector(<String, int>{
      ...counters,
      deviceId: this[deviceId] + 1,
    });
  }

  VersionVector merge(VersionVector other) {
    final result = <String, int>{...counters};
    for (final entry in other.counters.entries) {
      final current = result[entry.key] ?? 0;
      if (entry.value > current) result[entry.key] = entry.value;
    }
    return VersionVector(result);
  }

  VectorRelation compare(VersionVector other) {
    var lower = false;
    var higher = false;
    final deviceIds = <String>{...counters.keys, ...other.counters.keys};
    for (final deviceId in deviceIds) {
      final left = this[deviceId];
      final right = other[deviceId];
      if (left < right) lower = true;
      if (left > right) higher = true;
    }
    if (lower && higher) return VectorRelation.concurrent;
    if (lower) return VectorRelation.before;
    if (higher) return VectorRelation.after;
    return VectorRelation.equal;
  }

  int get total => counters.values.fold<int>(0, (sum, value) => sum + value);

  Map<String, Object?> toJson() => <String, Object?>{...counters};

  factory VersionVector.fromJson(Map<String, Object?> json) {
    return VersionVector(
      json.map((key, value) => MapEntry(key, (value! as num).toInt())),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VersionVector &&
      canonicalJson(other.toJson()) == canonicalJson(toJson());

  @override
  int get hashCode => canonicalJson(toJson()).hashCode;
}

class SyncBlobChunk {
  final int index;
  final String path;
  final int size;
  final String sha256;

  const SyncBlobChunk({
    required this.index,
    required this.path,
    required this.size,
    required this.sha256,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'index': index,
    'path': path,
    'size': size,
    'sha256': sha256,
  };

  factory SyncBlobChunk.fromJson(Map<String, Object?> json) {
    return SyncBlobChunk(
      index: (json['index']! as num).toInt(),
      path: normalizeRemotePath(json['path']! as String),
      size: (json['size']! as num).toInt(),
      sha256: json['sha256']! as String,
    );
  }
}

/// Content-addressed description of a remotely stored encrypted blob.
class SyncBlobDescriptor {
  final String objectId;
  final int size;
  final String sha256;
  final int chunkSize;
  final List<SyncBlobChunk> chunks;

  SyncBlobDescriptor({
    required this.objectId,
    required this.size,
    required this.sha256,
    required this.chunkSize,
    required List<SyncBlobChunk> chunks,
  }) : chunks = List.unmodifiable(chunks) {
    if (size < 0 || chunkSize <= 0) {
      throw ArgumentError('Invalid blob size/chunk size');
    }
    var expectedIndex = 0;
    var accumulatedSize = 0;
    for (final chunk in this.chunks) {
      if (chunk.index != expectedIndex++) {
        throw ArgumentError('Blob chunks must have contiguous indexes');
      }
      accumulatedSize += chunk.size;
    }
    if (accumulatedSize != size) {
      throw ArgumentError(
        'Chunk sizes ($accumulatedSize) do not match blob size ($size)',
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'objectId': objectId,
    'size': size,
    'sha256': sha256,
    'chunkSize': chunkSize,
    'chunks': chunks.map((chunk) => chunk.toJson()).toList(growable: false),
  };

  factory SyncBlobDescriptor.fromJson(Map<String, Object?> json) {
    return SyncBlobDescriptor(
      objectId: json['objectId']! as String,
      size: (json['size']! as num).toInt(),
      sha256: json['sha256']! as String,
      chunkSize: (json['chunkSize']! as num).toInt(),
      chunks: (json['chunks']! as List)
          .map(
            (value) =>
                SyncBlobChunk.fromJson(Map<String, Object?>.from(value as Map)),
          )
          .toList(growable: false),
    );
  }
}

/// One immutable version of a logical vault object.
///
/// [privateMetadata] is safe to contain names, MIME types, encryption salts
/// and folder/tag identifiers because the whole manifest is encrypted before
/// it leaves the device.
class SyncObjectVersion {
  final String versionId;
  final String authorDeviceId;
  final DateTime createdAt;
  final VersionVector vector;
  final Set<String> parentVersionIds;
  final bool isTombstone;
  final SyncBlobDescriptor? blob;
  final Map<String, Object?> privateMetadata;

  SyncObjectVersion._({
    required this.versionId,
    required this.authorDeviceId,
    required this.createdAt,
    required this.vector,
    required this.parentVersionIds,
    required this.isTombstone,
    required this.blob,
    required this.privateMetadata,
  });

  factory SyncObjectVersion.create({
    required String authorDeviceId,
    required DateTime createdAt,
    required VersionVector vector,
    required Set<String> parentVersionIds,
    required bool isTombstone,
    required SyncBlobDescriptor? blob,
    Map<String, Object?> privateMetadata = const <String, Object?>{},
  }) {
    if (isTombstone == (blob != null)) {
      throw ArgumentError(
        'A live version requires a blob; a tombstone must not have one',
      );
    }
    final normalizedParents = parentVersionIds.toList()..sort();
    final unsigned = <String, Object?>{
      'authorDeviceId': authorDeviceId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'vector': vector.toJson(),
      'parents': normalizedParents,
      'tombstone': isTombstone,
      if (blob != null) 'blob': blob.toJson(),
      'metadata': privateMetadata,
    };
    final versionId = crypto.sha256
        .convert(utf8.encode(canonicalJson(unsigned)))
        .toString();
    return SyncObjectVersion._(
      versionId: versionId,
      authorDeviceId: authorDeviceId,
      createdAt: createdAt.toUtc(),
      vector: vector,
      parentVersionIds: Set.unmodifiable(normalizedParents),
      isTombstone: isTombstone,
      blob: blob,
      privateMetadata: Map.unmodifiable(privateMetadata),
    );
  }

  factory SyncObjectVersion.fromJson(Map<String, Object?> json) {
    final version = SyncObjectVersion.create(
      authorDeviceId: json['authorDeviceId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      vector: VersionVector.fromJson(
        Map<String, Object?>.from(json['vector']! as Map),
      ),
      parentVersionIds: Set<String>.from(
        (json['parents']! as List).cast<String>(),
      ),
      isTombstone: json['tombstone']! as bool,
      blob: json['blob'] == null
          ? null
          : SyncBlobDescriptor.fromJson(
              Map<String, Object?>.from(json['blob']! as Map),
            ),
      privateMetadata: Map<String, Object?>.from(json['metadata']! as Map),
    );
    if (version.versionId != json['versionId']) {
      throw const SyncIntegrityException('Sync version identifier mismatch');
    }
    return version;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'versionId': versionId,
    'authorDeviceId': authorDeviceId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'vector': vector.toJson(),
    'parents': parentVersionIds.toList()..sort(),
    'tombstone': isTombstone,
    if (blob != null) 'blob': blob!.toJson(),
    'metadata': privateMetadata,
  };
}

class SyncObjectRecord {
  final String logicalId;
  final Map<String, SyncObjectVersion> versions;

  SyncObjectRecord({
    required this.logicalId,
    required Iterable<SyncObjectVersion> versions,
  }) : versions = Map.unmodifiable(<String, SyncObjectVersion>{
         for (final version in versions) version.versionId: version,
       });

  List<SyncObjectVersion> get heads {
    final all = versions.values.toList(growable: false);
    return all
        .where((candidate) {
          return !all.any((other) {
            if (identical(candidate, other) ||
                candidate.versionId == other.versionId) {
              return false;
            }
            return other.vector.compare(candidate.vector) ==
                VectorRelation.after;
          });
        })
        .toList(growable: false);
  }

  SyncObjectRecord add(SyncObjectVersion version) {
    return SyncObjectRecord(
      logicalId: logicalId,
      versions: <SyncObjectVersion>[...versions.values, version],
    );
  }

  SyncObjectRecord merge(SyncObjectRecord other) {
    if (logicalId != other.logicalId) {
      throw ArgumentError('Cannot merge different logical objects');
    }
    return SyncObjectRecord(
      logicalId: logicalId,
      versions: <SyncObjectVersion>[
        ...versions.values,
        ...other.versions.values,
      ],
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'logicalId': logicalId,
    'versions':
        (versions.values.toList()..sort(
              (left, right) => left.versionId.compareTo(right.versionId),
            ))
            .map((version) => version.toJson())
            .toList(growable: false),
  };

  factory SyncObjectRecord.fromJson(Map<String, Object?> json) {
    return SyncObjectRecord(
      logicalId: json['logicalId']! as String,
      versions: (json['versions']! as List).map(
        (value) =>
            SyncObjectVersion.fromJson(Map<String, Object?>.from(value as Map)),
      ),
    );
  }
}

/// The only mutable logical state published remotely. The serialized bytes are
/// always encrypted and signed by [authorDeviceId].
class SyncManifest {
  final int protocolVersion;
  final String vaultId;
  final int generation;
  final String? previousManifestDigest;
  final String authorDeviceId;
  final DateTime generatedAt;
  final Map<String, DeviceRegistration> devices;
  final Map<String, SyncObjectRecord> records;
  final Map<String, RemoteDeviceDirective> directives;

  SyncManifest({
    this.protocolVersion = SyncProtocol.currentVersion,
    required this.vaultId,
    required this.generation,
    required this.previousManifestDigest,
    required this.authorDeviceId,
    required this.generatedAt,
    required Map<String, DeviceRegistration> devices,
    required Map<String, SyncObjectRecord> records,
    Map<String, RemoteDeviceDirective> directives =
        const <String, RemoteDeviceDirective>{},
  }) : devices = Map.unmodifiable(devices),
       records = Map.unmodifiable(records),
       directives = Map.unmodifiable(directives) {
    SyncProtocol.requireSupported(protocolVersion);
    if (generation < 0) throw ArgumentError.value(generation, 'generation');
  }

  factory SyncManifest.initial({
    required String vaultId,
    required DeviceIdentity owner,
    required DateTime now,
  }) {
    final registration = DeviceRegistration(
      identity: owner,
      role: DeviceRole.owner,
      state: DeviceAuthorizationState.authorized,
      authorizedByDeviceId: owner.deviceId,
      authorizedAt: now.toUtc(),
    );
    return SyncManifest(
      vaultId: vaultId,
      generation: 0,
      previousManifestDigest: null,
      authorDeviceId: owner.deviceId,
      generatedAt: now.toUtc(),
      devices: <String, DeviceRegistration>{owner.deviceId: registration},
      records: const <String, SyncObjectRecord>{},
    );
  }

  DeviceRegistration requireAuthorizedDevice(String deviceId) {
    final registration = devices[deviceId];
    if (registration == null || !registration.isAuthorized) {
      throw SyncAuthorizationException('Device $deviceId is not authorized');
    }
    return registration;
  }

  String get digest =>
      crypto.sha256.convert(utf8.encode(canonicalJson(toJson()))).toString();

  SyncManifest nextGeneration({
    required String authorDeviceId,
    required DateTime generatedAt,
    Map<String, DeviceRegistration>? devices,
    Map<String, SyncObjectRecord>? records,
    Map<String, RemoteDeviceDirective>? directives,
  }) {
    requireAuthorizedDevice(authorDeviceId);
    return SyncManifest(
      protocolVersion: protocolVersion,
      vaultId: vaultId,
      generation: generation + 1,
      previousManifestDigest: digest,
      authorDeviceId: authorDeviceId,
      generatedAt: generatedAt.toUtc(),
      devices: devices ?? this.devices,
      records: records ?? this.records,
      directives: directives ?? this.directives,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'protocolVersion': protocolVersion,
    'vaultId': vaultId,
    'generation': generation,
    if (previousManifestDigest != null)
      'previousManifestDigest': previousManifestDigest,
    'authorDeviceId': authorDeviceId,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'devices': <String, Object?>{
      for (final entry
          in (devices.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key))))
        entry.key: entry.value.toJson(),
    },
    'records': <String, Object?>{
      for (final entry
          in (records.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key))))
        entry.key: entry.value.toJson(),
    },
    'directives': <String, Object?>{
      for (final entry
          in (directives.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key))))
        entry.key: entry.value.toJson(),
    },
  };

  factory SyncManifest.fromJson(Map<String, Object?> json) {
    final version = (json['protocolVersion']! as num).toInt();
    SyncProtocol.requireSupported(version);
    return SyncManifest(
      protocolVersion: version,
      vaultId: json['vaultId']! as String,
      generation: (json['generation']! as num).toInt(),
      previousManifestDigest: json['previousManifestDigest'] as String?,
      authorDeviceId: json['authorDeviceId']! as String,
      generatedAt: DateTime.parse(json['generatedAt']! as String).toUtc(),
      devices: (json['devices']! as Map).map(
        (key, value) => MapEntry(
          key as String,
          DeviceRegistration.fromJson(Map<String, Object?>.from(value as Map)),
        ),
      ),
      records: (json['records']! as Map).map(
        (key, value) => MapEntry(
          key as String,
          SyncObjectRecord.fromJson(Map<String, Object?>.from(value as Map)),
        ),
      ),
      directives: (json['directives']! as Map).map(
        (key, value) => MapEntry(
          key as String,
          RemoteDeviceDirective.fromJson(
            Map<String, Object?>.from(value as Map),
          ),
        ),
      ),
    );
  }
}

/// Privileged, pure transformations for the encrypted device registry.
abstract final class SyncManifestAdmin {
  static SyncManifest authorizeDevice({
    required SyncManifest manifest,
    required String actorDeviceId,
    required DeviceIdentity newDevice,
    DeviceRole role = DeviceRole.member,
    required DateTime now,
  }) {
    final actor = manifest.requireAuthorizedDevice(actorDeviceId);
    if (actor.role != DeviceRole.owner) {
      throw const SyncAuthorizationException(
        'Only an owner can authorize devices',
      );
    }
    if (manifest.devices.containsKey(newDevice.deviceId)) {
      throw SyncAuthorizationException(
        'Device ${newDevice.deviceId} is already registered',
      );
    }
    final devices = <String, DeviceRegistration>{
      ...manifest.devices,
      newDevice.deviceId: DeviceRegistration(
        identity: newDevice,
        role: role,
        state: DeviceAuthorizationState.authorized,
        authorizedByDeviceId: actorDeviceId,
        authorizedAt: now.toUtc(),
      ),
    };
    return manifest.nextGeneration(
      authorDeviceId: actorDeviceId,
      generatedAt: now,
      devices: devices,
    );
  }

  static SyncManifest revokeDevice({
    required SyncManifest manifest,
    required String actorDeviceId,
    required String targetDeviceId,
    required DateTime now,
  }) {
    final actor = manifest.requireAuthorizedDevice(actorDeviceId);
    if (actor.role != DeviceRole.owner) {
      throw const SyncAuthorizationException(
        'Only an owner can revoke devices',
      );
    }
    if (actorDeviceId == targetDeviceId) {
      throw const SyncAuthorizationException(
        'A device cannot sign its own revocation',
      );
    }
    final target = manifest.requireAuthorizedDevice(targetDeviceId);
    if (target.role == DeviceRole.owner) {
      final otherOwners = manifest.devices.values.where(
        (registration) =>
            registration.identity.deviceId != targetDeviceId &&
            registration.isAuthorized &&
            registration.role == DeviceRole.owner,
      );
      if (otherOwners.isEmpty) {
        throw const SyncAuthorizationException(
          'The last owner cannot be revoked',
        );
      }
    }
    return manifest.nextGeneration(
      authorDeviceId: actorDeviceId,
      generatedAt: now,
      devices: <String, DeviceRegistration>{
        ...manifest.devices,
        targetDeviceId: target.revoke(byDeviceId: actorDeviceId, at: now),
      },
    );
  }

  static SyncManifest issueDirective({
    required SyncManifest manifest,
    required String actorDeviceId,
    required RemoteDeviceDirective directive,
    required DateTime now,
  }) {
    final actor = manifest.requireAuthorizedDevice(actorDeviceId);
    if (actor.role != DeviceRole.owner ||
        directive.issuedByDeviceId != actorDeviceId) {
      throw const SyncAuthorizationException(
        'Only an owner can issue remote directives',
      );
    }
    if (!manifest.devices.containsKey(directive.targetDeviceId)) {
      throw const SyncAuthorizationException('Directive target is unknown');
    }
    if (manifest.directives.containsKey(directive.directiveId)) {
      throw const SyncAuthorizationException(
        'Directive identifiers are immutable and cannot be reused',
      );
    }
    return manifest.nextGeneration(
      authorDeviceId: actorDeviceId,
      generatedAt: now,
      directives: <String, RemoteDeviceDirective>{
        ...manifest.directives,
        directive.directiveId: directive,
      },
    );
  }

  /// Persists an acknowledgement without granting the target device authority
  /// to alter the directive itself. The enclosing manifest revision is signed
  /// by the target's Ed25519 identity during publication.
  static SyncManifest acknowledgeDirective({
    required SyncManifest manifest,
    required String actorDeviceId,
    required String directiveId,
    required String acknowledgementSignatureBase64,
    required DateTime now,
  }) {
    manifest.requireAuthorizedDevice(actorDeviceId);
    final directive = manifest.directives[directiveId];
    if (directive == null) {
      throw SyncAuthorizationException(
        'Remote directive $directiveId does not exist',
      );
    }
    if (directive.targetDeviceId != actorDeviceId) {
      throw const SyncAuthorizationException(
        'Only the target device can acknowledge a remote directive',
      );
    }
    if (directive.acknowledgedByDeviceIds.contains(actorDeviceId)) {
      return manifest;
    }
    return manifest.nextGeneration(
      authorDeviceId: actorDeviceId,
      generatedAt: now,
      directives: <String, RemoteDeviceDirective>{
        ...manifest.directives,
        directiveId: directive.acknowledge(
          actorDeviceId,
          signatureBase64: acknowledgementSignatureBase64,
        ),
      },
    );
  }
}
