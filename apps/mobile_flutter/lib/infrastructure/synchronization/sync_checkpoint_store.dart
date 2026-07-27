// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import '../../domain/synchronization/sync_checkpoint.dart';
import '../../domain/synchronization/sync_protocol.dart';
import 'device_identity_store.dart';

class SecureSyncTrustCheckpointStore implements SyncTrustCheckpointStore {
  static const String _keyPrefix = 'sync_trust_checkpoint_v1_';
  final SyncSecretStore _secretStore;

  const SecureSyncTrustCheckpointStore({required SyncSecretStore secretStore})
    : _secretStore = secretStore;

  @override
  Future<SyncTrustCheckpoint?> load(String vaultId) async {
    final serialized = await _secretStore.read('$_keyPrefix$vaultId');
    if (serialized == null) return null;
    try {
      return SyncTrustCheckpoint.fromJson(
        Map<String, Object?>.from(jsonDecode(serialized) as Map),
      );
    } catch (error) {
      throw SyncIntegrityException(
        'Stored synchronization trust checkpoint is corrupted',
        error,
      );
    }
  }

  @override
  Future<void> save(SyncTrustCheckpoint checkpoint) {
    return _secretStore.write(
      '$_keyPrefix${checkpoint.vaultId}',
      canonicalJson(checkpoint.toJson()),
    );
  }

  @override
  Future<void> clear(String vaultId) {
    return _secretStore.delete('$_keyPrefix$vaultId');
  }
}

class MemorySyncTrustCheckpointStore implements SyncTrustCheckpointStore {
  final Map<String, SyncTrustCheckpoint> _checkpoints =
      <String, SyncTrustCheckpoint>{};

  @override
  Future<SyncTrustCheckpoint?> load(String vaultId) async {
    return _checkpoints[vaultId];
  }

  @override
  Future<void> save(SyncTrustCheckpoint checkpoint) async {
    _checkpoints[checkpoint.vaultId] = checkpoint;
  }

  @override
  Future<void> clear(String vaultId) async {
    _checkpoints.remove(vaultId);
  }
}
