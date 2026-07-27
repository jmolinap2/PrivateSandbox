import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/vault_repository.dart';
import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_configuration.dart';
import '../../domain/synchronization/sync_selection.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/synchronization/device_identity_store.dart';
import '../../infrastructure/synchronization/drift_vault_sync_store.dart';
import '../../infrastructure/synchronization/encrypted_manifest_repository.dart';
import '../../infrastructure/synchronization/resumable_blob_transfer.dart';
import '../../infrastructure/synchronization/sync_checkpoint_store.dart';
import '../../infrastructure/synchronization/sync_configuration_store.dart';
import '../../infrastructure/synchronization/sync_crypto.dart';
import '../../infrastructure/synchronization/webdav_sync_transport.dart';
import '../../infrastructure/storage/vault_paths.dart';
import 'synchronization_engine.dart';

typedef ConfiguredSyncOperation<T> =
    Future<T> Function(
      SynchronizationEngine engine,
      DeviceCredentials device,
      SyncConfiguration configuration,
    );

/// Builds one complete synchronization run from securely stored settings.
///
/// Keeping this free of Riverpod/Flutter widgets lets the same code run in a
/// foreground screen, an Android WorkManager isolate and the desktop
/// companion.
class ConfiguredSynchronizationService {
  final AppDatabase database;
  final VaultRepository vaultRepository;
  final KeyManager keyManager;
  final FlutterSecureStorage secureStorage;
  final SyncConfigurationStore configurationStore;

  const ConfiguredSynchronizationService({
    required this.database,
    required this.vaultRepository,
    required this.keyManager,
    required this.secureStorage,
    required this.configurationStore,
  });

  Future<SynchronizationResult> run({
    Set<String> requestedDownloads = const <String>{},
    bool Function()? isCancelled,
    SyncProgressCallback? onProgress,
  }) async {
    final configuration = await configurationStore.load();
    if (configuration == null ||
        configuration.policy.mode == VaultSyncMode.localOnly) {
      return const SynchronizationResult.localOnly();
    }
    return runWithConfiguration(
      configuration,
      requestedDownloads: requestedDownloads,
      isCancelled: isCancelled,
      onProgress: onProgress,
    );
  }

  Future<SynchronizationResult> runWithConfiguration(
    SyncConfiguration configuration, {
    Set<String> requestedDownloads = const <String>{},
    bool Function()? isCancelled,
    SyncProgressCallback? onProgress,
  }) async {
    return withEngineConfiguration(
      configuration,
      (engine, _, configured) => engine.synchronize(
        policy: configured.policy,
        requestedDownloadLogicalIds: requestedDownloads,
        isCancelled: isCancelled,
        onProgress: onProgress,
      ),
    );
  }

  /// Loads the persisted synchronized-mode configuration or reports a
  /// user-actionable error. Device enrollment deliberately uses the same
  /// endpoint and credentials as normal synchronization.
  Future<SyncConfiguration> requireConfiguration() async {
    final configuration = await configurationStore.load();
    if (configuration == null ||
        configuration.policy.mode == VaultSyncMode.localOnly) {
      throw const FormatException(
        'Guarda primero una configuración de sincronización remota.',
      );
    }
    configuration.validate();
    return configuration;
  }

  /// Returns this installation's public identity without requiring a vault
  /// key. A fresh receiver needs this to create its pairing request before it
  /// has received the owner's encrypted key grant.
  Future<DeviceIdentity> loadOrCreateDeviceIdentity() async {
    final configuration = await requireConfiguration();
    final secretStore = FlutterSecureSyncSecretStore(storage: secureStorage);
    final identityManager = DeviceIdentityManager(secretStore: secretStore);
    final device = await identityManager.loadOrCreate(
      displayName: configuration.deviceDisplayName,
    );
    try {
      return device.identity;
    } finally {
      device.destroy();
    }
  }

  /// Runs an administrative operation with the same authenticated engine used
  /// by foreground/background synchronization.
  Future<T> withEngine<T>(ConfiguredSyncOperation<T> operation) async {
    final configuration = await requireConfiguration();
    return withEngineConfiguration(configuration, operation);
  }

  Future<T> withEngineConfiguration<T>(
    SyncConfiguration configuration,
    ConfiguredSyncOperation<T> operation,
  ) async {
    configuration.validate();
    if (configuration.policy.mode == VaultSyncMode.localOnly) {
      throw const FormatException(
        'La administración remota no está disponible en modo sólo local.',
      );
    }
    final masterKey = await keyManager.getExistingMasterKey();
    final secretStore = FlutterSecureSyncSecretStore(storage: secureStorage);
    final identityManager = DeviceIdentityManager(secretStore: secretStore);
    final device = await identityManager.loadOrCreate(
      displayName: configuration.deviceDisplayName,
    );
    final crypto = SyncCrypto();
    final vaultKeys = await crypto.deriveVaultKeys(masterKey);
    final credentials = switch (configuration.authenticationKind) {
      SyncAuthenticationKind.none => const WebDavCredentials.none(),
      SyncAuthenticationKind.basic => WebDavCredentials.basic(
        username: configuration.username,
        password: configuration.secret,
      ),
      SyncAuthenticationKind.bearer => WebDavCredentials.bearer(
        configuration.secret,
      ),
    };
    final transport = WebDavSyncTransport(
      baseUri: configuration.endpoint,
      credentials: credentials,
    );
    try {
      final manifests = EncryptedManifestRepository(
        transport: transport,
        crypto: crypto,
        keys: vaultKeys,
      );
      final engine = SynchronizationEngine(
        manifests: manifests,
        transfers: ResumableBlobTransfer(transport: transport),
        localStore: DriftVaultSyncStore(
          database: database,
          vaultRepository: vaultRepository,
          deviceId: device.identity.deviceId,
          blobsDirectory: VaultPaths.vaultBlobsDir,
        ),
        trustStore: SecureSyncTrustCheckpointStore(secretStore: secretStore),
        vaultKeys: vaultKeys,
        device: device,
      );
      return await operation(engine, device, configuration);
    } finally {
      transport.close(force: true);
      device.destroy();
    }
  }
}
