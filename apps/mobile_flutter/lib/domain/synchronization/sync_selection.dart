enum VaultSyncMode { localOnly, synchronized }

enum RemoteDownloadMode {
  /// Download only the encrypted manifest. Blobs are fetched explicitly.
  onDemand,

  /// Download every selected live head during synchronization.
  eager,
}

/// Persistable policy for selective upload/download.
class SelectiveSyncPolicy {
  final VaultSyncMode mode;
  final RemoteDownloadMode downloadMode;
  final Set<String> includedLogicalIds;
  final Set<String> excludedLogicalIds;
  final int? maximumBlobBytes;
  final int? bandwidthLimitBytesPerSecond;

  const SelectiveSyncPolicy({
    this.mode = VaultSyncMode.synchronized,
    this.downloadMode = RemoteDownloadMode.onDemand,
    this.includedLogicalIds = const <String>{},
    this.excludedLogicalIds = const <String>{},
    this.maximumBlobBytes,
    this.bandwidthLimitBytesPerSecond,
  }) : assert(maximumBlobBytes == null || maximumBlobBytes >= 0),
       assert(
         bandwidthLimitBytesPerSecond == null ||
             bandwidthLimitBytesPerSecond > 0,
       );

  bool allowsMetadata(String logicalId) {
    if (mode == VaultSyncMode.localOnly) return false;
    if (excludedLogicalIds.contains(logicalId)) return false;
    return includedLogicalIds.isEmpty || includedLogicalIds.contains(logicalId);
  }

  bool allowsBlob(String logicalId, int size) {
    return allowsMetadata(logicalId) &&
        (maximumBlobBytes == null || size <= maximumBlobBytes!);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.name,
    'downloadMode': downloadMode.name,
    'includedLogicalIds': includedLogicalIds.toList()..sort(),
    'excludedLogicalIds': excludedLogicalIds.toList()..sort(),
    if (maximumBlobBytes != null) 'maximumBlobBytes': maximumBlobBytes,
    if (bandwidthLimitBytesPerSecond != null)
      'bandwidthLimitBytesPerSecond': bandwidthLimitBytesPerSecond,
  };

  factory SelectiveSyncPolicy.fromJson(Map<String, Object?> json) {
    return SelectiveSyncPolicy(
      mode: VaultSyncMode.values.byName(json['mode']! as String),
      downloadMode: RemoteDownloadMode.values.byName(
        json['downloadMode']! as String,
      ),
      includedLogicalIds: Set<String>.from(
        (json['includedLogicalIds']! as List).cast<String>(),
      ),
      excludedLogicalIds: Set<String>.from(
        (json['excludedLogicalIds']! as List).cast<String>(),
      ),
      maximumBlobBytes: (json['maximumBlobBytes'] as num?)?.toInt(),
      bandwidthLimitBytesPerSecond:
          (json['bandwidthLimitBytesPerSecond'] as num?)?.toInt(),
    );
  }
}
