import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../infrastructure/backup/backup_key_wrapper.dart';
import '../../infrastructure/backup/vault_backup_codec.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Bundles the whole vault — SQLite DB (all metadata: files, folders, tags,
/// collections, smart albums, activity log) and every encrypted blob — into
/// one portable, password-protected file. The vault's own master key is
/// wrapped under the backup password (see [BackupKeyWrapper]) and travels
/// inside the file, since the device's Keystore-backed storage wouldn't be
/// usable after a restore on a different device/install.
class ExportVaultBackupUseCase {
  final AppDatabase _db;
  final KeyManager _keyManager;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  ExportVaultBackupUseCase(this._db, this._keyManager, this._activityRepository);

  Future<File> call({required String password, required Directory destinationDir}) async {
    // Force everything out of the WAL into the main file, so the copy below
    // is a complete, consistent snapshot.
    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

    final appDir = await VaultPaths.vaultBlobsDir();
    final dbFile = File(p.join(appDir.parent.path, 'vault.sqlite'));
    if (!await dbFile.exists()) {
      throw StateError('No se encontró la base de datos de la bóveda.');
    }

    final blobFiles = await appDir.list().where((e) => e is File).cast<File>().toList();

    final masterKeyBytes = await _keyManager.exportMasterKeyBytes();
    final wrapped = await BackupKeyWrapper.wrap(password: password, masterKeyBytes: masterKeyBytes);

    final manifest = VaultBackupManifest(
      createdAt: DateTime.now().toIso8601String(),
      kdfSaltBase64: wrapped.saltBase64,
      kdfIterations: BackupKeyWrapper.iterations,
      wrappedKeyNonceBase64: wrapped.nonceBase64,
      wrappedKeyCipherTextBase64: wrapped.cipherTextBase64,
      wrappedKeyMacBase64: wrapped.macBase64,
      dbFile: VaultBackupFileEntry(name: 'vault.sqlite', size: await dbFile.length()),
      blobFiles: [
        for (final blob in blobFiles) VaultBackupFileEntry(name: p.basename(blob.path), size: await blob.length()),
      ],
    );

    final fileName = 'PrivateSandbox-backup-${DateTime.now().toIso8601String().replaceAll(':', '-')}.psvb';
    final destination = File(p.join(destinationDir.path, fileName));

    try {
      await VaultBackupCodec.write(
        destination: destination,
        manifest: manifest,
        dbFile: dbFile,
        blobFiles: blobFiles,
      );
      await _activityRepository.logEvent(ActivityEvent(
        id: _uuid.v4(),
        type: ActivityEventType.exported,
        fileName: 'Copia de seguridad completa',
        timestamp: DateTime.now(),
        success: true,
        detail: fileName,
      ));
    } catch (_) {
      if (await destination.exists()) {
        await destination.delete();
      }
      await _activityRepository.logEvent(ActivityEvent(
        id: _uuid.v4(),
        type: ActivityEventType.exported,
        fileName: 'Copia de seguridad completa',
        timestamp: DateTime.now(),
        success: false,
      ));
      rethrow;
    }
    return destination;
  }
}
