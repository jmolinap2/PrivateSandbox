import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../infrastructure/backup/backup_key_wrapper.dart';
import '../../infrastructure/backup/vault_backup_codec.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Bundles the whole vault into one portable PSVB2 file. SQLite (including
/// all metadata), blob names, hashes, and blob bytes are encrypted and
/// authenticated. The vault master key is independently wrapped under the
/// backup password so the backup remains portable across device Keystores.
class ExportVaultBackupUseCase {
  final AppDatabase _db;
  final KeyManager _keyManager;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  ExportVaultBackupUseCase(
    this._db,
    this._keyManager,
    this._activityRepository,
  );

  Future<File> call({
    required String password,
    required Directory destinationDir,
  }) async {
    final appDir = await VaultPaths.vaultBlobsDir();
    final liveDbFile = File(p.join(appDir.parent.path, 'vault.sqlite'));
    if (!await liveDbFile.exists()) {
      throw StateError('No se encontró la base de datos de la bóveda.');
    }

    final masterKeyBytes = await _keyManager.exportMasterKeyBytes();
    final wrapped = await BackupKeyWrapper.wrap(
      password: password,
      masterKeyBytes: masterKeyBytes,
    );

    final fileName =
        'PrivateSandbox-backup-${DateTime.now().toIso8601String().replaceAll(':', '-')}.psvb';
    final destination = File(p.join(destinationDir.path, fileName));
    final snapshotFile = File(
      p.join(
        appDir.parent.path,
        '.vault_backup_snapshot_${pid}_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      ),
    );

    try {
      // VACUUM INTO uses SQLite's own snapshot machinery, so WAL frames and
      // concurrent readers cannot produce a torn raw-file copy. Blob names
      // are then read from that same immutable snapshot; orphans and sync
      // partials are intentionally excluded.
      await _db.customStatement('VACUUM INTO ?', [snapshotFile.path]);
      final snapshotDatabase = AppDatabase.withExecutor(
        NativeDatabase(snapshotFile),
      );
      late final List<File> blobFiles;
      try {
        blobFiles = await _referencedBlobFiles(snapshotDatabase, appDir);
        await snapshotDatabase.customStatement(
          'PRAGMA wal_checkpoint(TRUNCATE);',
        );
      } finally {
        await snapshotDatabase.close();
      }
      await _deleteSnapshotSidecars(snapshotFile);

      await VaultBackupCodec.write(
        destination: destination,
        createdAt: DateTime.now(),
        databaseSchemaVersion: _db.schemaVersion,
        keyEnvelope: wrapped,
        masterKeyBytes: masterKeyBytes,
        dbFile: snapshotFile,
        blobFiles: blobFiles,
      );
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.exported,
          fileName: 'Copia de seguridad completa',
          timestamp: DateTime.now(),
          success: true,
          detail: fileName,
        ),
      );
    } catch (_) {
      if (await destination.exists()) {
        await destination.delete();
      }
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.exported,
          fileName: 'Copia de seguridad completa',
          timestamp: DateTime.now(),
          success: false,
        ),
      );
      rethrow;
    } finally {
      await _deleteSnapshotSidecars(snapshotFile);
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
    }
    return destination;
  }

  Future<List<File>> _referencedBlobFiles(
    AppDatabase snapshotDatabase,
    Directory blobsDir,
  ) async {
    final rows = await snapshotDatabase.customSelect('''
      SELECT status, encrypted_file_name, thumbnail_file_name
      FROM vault_files
    ''').get();
    final names = <String>{};
    for (final row in rows) {
      final status = row.data['status'];
      if (status == 'importing') {
        throw StateError(
          'Hay una importación en curso; espera a que termine para crear la copia.',
        );
      }
      if (status != 'verified' && status != 'completed') {
        throw StateError(
          'La bóveda contiene un estado de importación inválido.',
        );
      }

      final encryptedName = row.data['encrypted_file_name'];
      if (encryptedName is! String ||
          encryptedName.isEmpty ||
          p.basename(encryptedName) != encryptedName ||
          !names.add(encryptedName)) {
        throw StateError(
          'La base de datos contiene una referencia de blob inválida o duplicada.',
        );
      }
      final thumbnailName = row.data['thumbnail_file_name'];
      if (thumbnailName != null &&
          (thumbnailName is! String ||
              thumbnailName.isEmpty ||
              p.basename(thumbnailName) != thumbnailName ||
              !names.add(thumbnailName))) {
        throw StateError(
          'La base de datos contiene una referencia de miniatura inválida o duplicada.',
        );
      }
    }

    final files = <File>[];
    for (final name in names) {
      final file = File(p.join(blobsDir.path, name));
      if (!await file.exists()) {
        throw StateError('Falta el blob requerido por SQLite: $name');
      }
      files.add(file);
    }
    return files;
  }

  Future<void> _deleteSnapshotSidecars(File snapshotFile) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final file = File('${snapshotFile.path}$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
