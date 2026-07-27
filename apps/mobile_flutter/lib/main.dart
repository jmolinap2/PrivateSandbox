import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'application/synchronization/background_sync_scheduler.dart';
import 'domain/synchronization/sync_selection.dart';
import 'infrastructure/backup/vault_restore_recovery.dart';
import 'infrastructure/encryption/key_manager.dart';
import 'infrastructure/storage/vault_paths.dart';
import 'infrastructure/synchronization/sync_configuration_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final supportDirectory = await getApplicationSupportDirectory();
  final keyManager = KeyManager();
  await VaultRestoreRecovery.recoverAll(
    supportDirectory: supportDirectory,
    readStoredKeyFingerprint: keyManager.readStoredMasterKeyFingerprint,
  );
  // Any file left in the playback/share temp dirs from a previous run (e.g.
  // the process was killed while a viewer was open, or right after a share)
  // is stale and unencrypted; drop it before anything else runs.
  await VaultPaths.clearTempPlaybackDir();
  await VaultPaths.clearTempShareDir();
  await BackgroundSyncScheduler.initialize();
  unawaited(_restoreBackgroundSchedule());
  runApp(const ProviderScope(child: VaultApp()));
}

Future<void> _restoreBackgroundSchedule() async {
  try {
    final configuration = await const SyncConfigurationStore(
      FlutterSecureStorage(),
    ).load();
    await BackgroundSyncScheduler.configure(
      enabled:
          configuration != null &&
          configuration.backgroundSyncEnabled &&
          configuration.policy.mode == VaultSyncMode.synchronized,
    );
  } catch (_) {
    // Secure-storage/plugin failures must never prevent the lock gate from
    // appearing. The settings screen surfaces configuration errors later.
  }
}
