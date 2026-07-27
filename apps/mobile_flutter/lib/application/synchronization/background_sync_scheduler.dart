import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/synchronization/sync_protocol.dart';
import '../../domain/synchronization/sync_selection.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/vault_repository_impl.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/synchronization/sync_configuration_store.dart';
import 'configured_synchronization_service.dart';

const _backgroundSyncTask = 'private_sandbox_background_sync_v1';
const _backgroundSyncUniqueName = 'private_sandbox_periodic_sync';

@pragma('vm:entry-point')
void privateSandboxBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _backgroundSyncTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    const secureStorage = FlutterSecureStorage();
    final configurationStore = SyncConfigurationStore(secureStorage);
    final configuration = await configurationStore.load();
    if (configuration == null ||
        !configuration.backgroundSyncEnabled ||
        configuration.policy.mode == VaultSyncMode.localOnly) {
      return true;
    }

    final database = AppDatabase();
    try {
      final repository = VaultRepositoryImpl(database);
      final service = ConfiguredSynchronizationService(
        database: database,
        vaultRepository: repository,
        keyManager: KeyManager(secureStorage: secureStorage),
        secureStorage: secureStorage,
        configurationStore: configurationStore,
      );
      await service.runWithConfiguration(configuration);
      return true;
    } on SyncTransportException {
      return false;
    } on SyncCancelledException {
      return false;
    } on SyncAuthorizationException {
      return true;
    } on SyncIntegrityException {
      return true;
    } finally {
      await database.close();
    }
  });
}

abstract final class BackgroundSyncScheduler {
  static Future<void> initialize() {
    return Workmanager().initialize(privateSandboxBackgroundDispatcher);
  }

  static Future<void> configure({required bool enabled}) async {
    if (!enabled) {
      await Workmanager().cancelByUniqueName(_backgroundSyncUniqueName);
      return;
    }
    await Workmanager().registerPeriodicTask(
      _backgroundSyncUniqueName,
      _backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
      tag: _backgroundSyncTask,
    );
  }

  static Future<void> enqueueSoon() {
    return Workmanager().registerOneOffTask(
      '${_backgroundSyncUniqueName}_soon',
      _backgroundSyncTask,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
      tag: _backgroundSyncTask,
    );
  }
}
