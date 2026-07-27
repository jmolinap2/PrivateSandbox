import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/backup/backup_key_wrapper.dart';
import '../../infrastructure/backup/vault_backup_codec.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/storage/vault_paths.dart';

enum ImportVaultBackupResult { success, wrongPassword, invalidFile }

/// Replaces the entire vault (DB + every blob + master key) with the
/// contents of a backup produced by [ExportVaultBackupUseCase]. This is
/// destructive by nature — restoring *is* replacing — so the whole backup
/// is first extracted to a scratch directory and fully validated there;
/// nothing about the live vault is touched until that succeeds, so a bad
/// password or a corrupt/truncated backup file leaves the current vault
/// completely untouched.
///
/// The caller must treat the app as unusable after a successful call:
/// [AppDatabase] is closed as part of the swap, so every provider that
/// depends on it needs a fresh process, not just a provider invalidation.
class ImportVaultBackupUseCase {
  final AppDatabase _db;
  final KeyManager _keyManager;

  ImportVaultBackupUseCase(this._db, this._keyManager);

  Future<ImportVaultBackupResult> call({required File backupFile, required String password}) async {
    final VaultBackupManifest manifest;
    try {
      manifest = await VaultBackupCodec.readManifest(backupFile);
    } catch (_) {
      return ImportVaultBackupResult.invalidFile;
    }

    final masterKeyBytes = await BackupKeyWrapper.unwrap(password: password, manifest: manifest);
    if (masterKeyBytes == null) {
      return ImportVaultBackupResult.wrongPassword;
    }

    final tempBase = await getTemporaryDirectory();
    final stagingDir = Directory(p.join(tempBase.path, 'vault_restore_staging'));
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
    await stagingDir.create(recursive: true);

    try {
      await VaultBackupCodec.extract(source: backupFile, manifest: manifest, outputDir: stagingDir);
    } catch (_) {
      await stagingDir.delete(recursive: true);
      return ImportVaultBackupResult.invalidFile;
    }

    // Everything above is read-only with respect to the live vault. Only
    // now, with a fully-extracted and password-verified backup sitting in
    // staging, do we touch anything real.
    await _db.close();

    final appSupportDir = await getApplicationSupportDirectory();
    final liveDbFile = File(p.join(appSupportDir.path, 'vault.sqlite'));
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final sidecar = File('${liveDbFile.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }

    final blobsDir = await VaultPaths.vaultBlobsDir();
    if (await blobsDir.exists()) {
      await blobsDir.delete(recursive: true);
    }
    await blobsDir.create(recursive: true);

    final stagedDb = File(p.join(stagingDir.path, manifest.dbFile.name));
    await stagedDb.copy(liveDbFile.path);

    final stagedBlobsDir = Directory(p.join(stagingDir.path, 'blobs'));
    if (await stagedBlobsDir.exists()) {
      await for (final entity in stagedBlobsDir.list()) {
        if (entity is File) {
          await entity.copy(p.join(blobsDir.path, p.basename(entity.path)));
        }
      }
    }

    await _keyManager.importMasterKeyBytes(masterKeyBytes);
    await stagingDir.delete(recursive: true);

    return ImportVaultBackupResult.success;
  }
}
