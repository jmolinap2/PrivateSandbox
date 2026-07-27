import 'dart:typed_data';

import '../../domain/synchronization/sync_checkpoint.dart';
import '../../infrastructure/synchronization/device_key_grant.dart';

typedef MasterKeyImporter = Future<void> Function(Uint8List masterKeyBytes);
typedef PostGrantSynchronization = Future<void> Function();

/// Installs a verified device grant in the only safe order.
///
/// Persisting the authenticated checkpoint before the master key is
/// intentional: after the key is imported, any first remote read must already
/// be pinned to the manifest generation and device registry carried by the
/// owner's signed grant. This prevents a malicious provider from presenting an
/// older owner set during the enrollment window.
class DeviceGrantRecoveryCoordinator {
  final SyncTrustCheckpointStore checkpointStore;
  final MasterKeyImporter importMasterKey;
  final PostGrantSynchronization synchronize;

  const DeviceGrantRecoveryCoordinator({
    required this.checkpointStore,
    required this.importMasterKey,
    required this.synchronize,
  });

  Future<void> install(RecoveredDeviceGrant recovered) async {
    await checkpointStore.save(recovered.trustCheckpoint);
    await importMasterKey(recovered.masterKeyBytes);
    await synchronize();
  }
}
