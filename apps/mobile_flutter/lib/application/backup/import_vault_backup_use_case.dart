import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/backup/backup_key_wrapper.dart';
import '../../infrastructure/backup/vault_backup_codec.dart';
import '../../infrastructure/backup/vault_restore_recovery.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../shared/errors/vault_exceptions.dart';

enum ImportVaultBackupResult { success, wrongPassword, invalidFile }

/// Restores a complete PSVB2 vault through four explicit safety gates:
///
/// 1. Strictly parse the bounded public header.
/// 2. Authenticate the password-wrapped master key and encrypted manifest.
/// 3. Extract every authenticated payload block to same-volume staging, run
///    SQLite integrity checks, validate DB-to-blob references, and decrypt
///    every referenced vault blob with the restored master key.
/// 4. Close the live DB and replace DB/blobs using rename-based staging while
///    retaining the old vault until the new key has been installed. Any
///    exception during the swap rolls files and key material back.
///
/// The caller must restart the process after success because [_db] is closed.
class ImportVaultBackupUseCase {
  final AppDatabase _db;
  final KeyManager _keyManager;

  ImportVaultBackupUseCase(this._db, this._keyManager);

  Future<ImportVaultBackupResult> call({
    required File backupFile,
    required String password,
  }) async {
    final VaultBackupHeader header;
    try {
      header = await VaultBackupCodec.readHeader(backupFile);
    } catch (_) {
      return ImportVaultBackupResult.invalidFile;
    }

    final masterKeyBytes = await BackupKeyWrapper.unwrap(
      password: password,
      envelope: header.keyEnvelope,
    );
    if (masterKeyBytes == null) {
      return ImportVaultBackupResult.wrongPassword;
    }

    final VaultBackupManifest privateManifest;
    try {
      privateManifest = await VaultBackupCodec.readPayloadManifest(
        source: backupFile,
        header: header,
        masterKeyBytes: masterKeyBytes,
      );
      if (privateManifest.databaseSchemaVersion > _db.schemaVersion) {
        return ImportVaultBackupResult.invalidFile;
      }
    } catch (_) {
      return ImportVaultBackupResult.invalidFile;
    }

    final supportDir = await getApplicationSupportDirectory();
    final operationId = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final stagingDir = Directory(
      p.join(supportDir.path, '.vault_restore_staging_$operationId'),
    );
    final rollbackDir = Directory(
      p.join(supportDir.path, '.vault_restore_rollback_$operationId'),
    );
    await stagingDir.create(recursive: true);

    VaultBackupManifest extractedManifest;
    try {
      extractedManifest = await VaultBackupCodec.extract(
        source: backupFile,
        header: header,
        masterKeyBytes: masterKeyBytes,
        outputDir: stagingDir,
      );
      if (extractedManifest.databaseSchemaVersion !=
          privateManifest.databaseSchemaVersion) {
        throw const FormatException(
          'El manifiesto cambió durante la restauración.',
        );
      }
      await _validateStagedVault(
        stagingDir: stagingDir,
        manifest: extractedManifest,
        masterKeyBytes: masterKeyBytes,
      );
    } catch (_) {
      await _deleteDirectoryIfExists(stagingDir);
      return ImportVaultBackupResult.invalidFile;
    }

    Uint8List? oldMasterKeyBytes;
    try {
      oldMasterKeyBytes = await _keyManager.exportMasterKeyBytes();
    } on KeyMaterialMissingException {
      // Restoring a portable backup is also the supported recovery path for
      // a lost Keystore key. The old vault remains available for rollback,
      // but its already-missing key cannot be restored.
      oldMasterKeyBytes = null;
    }
    await _db.close();

    try {
      await _swapWithRollback(
        supportDir: supportDir,
        operationId: operationId,
        stagingDir: stagingDir,
        rollbackDir: rollbackDir,
        restoredMasterKeyBytes: masterKeyBytes,
        oldMasterKeyBytes: oldMasterKeyBytes,
      );
    } catch (_) {
      try {
        await _deleteDirectoryIfExists(stagingDir);
      } on FileSystemException {
        // Startup recovery retries private staging cleanup.
      }
      return ImportVaultBackupResult.invalidFile;
    }

    try {
      await _deleteDirectoryIfExists(stagingDir);
    } on FileSystemException {
      // The restore is already committed; stale staging is startup-cleaned.
    }
    return ImportVaultBackupResult.success;
  }

  Future<void> _validateStagedVault({
    required Directory stagingDir,
    required VaultBackupManifest manifest,
    required Uint8List masterKeyBytes,
  }) async {
    final stagedDb = File(p.join(stagingDir.path, manifest.dbFile.name));
    final stagedBlobs = Directory(p.join(stagingDir.path, 'blobs'));
    if (!await stagedDb.exists() || !await stagedBlobs.exists()) {
      throw const FormatException(
        'La copia extraída no contiene la estructura esperada.',
      );
    }

    final headerSchemaVersion = await _readSqliteSchemaVersion(stagedDb);
    if (headerSchemaVersion != manifest.databaseSchemaVersion ||
        headerSchemaVersion > _db.schemaVersion) {
      throw const FormatException(
        'La versión interna de SQLite no coincide con el manifiesto.',
      );
    }

    final manifestBlobNames = {
      for (final entry in manifest.blobFiles) entry.name,
    };
    final stagedDatabase = AppDatabase.withExecutor(NativeDatabase(stagedDb));
    try {
      final integrityRows = await stagedDatabase
          .customSelect('PRAGMA integrity_check;')
          .get();
      if (integrityRows.length != 1 ||
          integrityRows.single.data.values.length != 1 ||
          integrityRows.single.data.values.single != 'ok') {
        throw const FormatException('SQLite no superó PRAGMA integrity_check.');
      }

      final foreignKeyRows = await stagedDatabase
          .customSelect('PRAGMA foreign_key_check;')
          .get();
      if (foreignKeyRows.isNotEmpty) {
        throw const FormatException(
          'SQLite contiene referencias relacionales inválidas.',
        );
      }

      final countRows = await stagedDatabase.customSelect('''
        SELECT COUNT(*) AS file_count
        FROM vault_files
      ''').get();
      final fileCount = countRows.length == 1
          ? countRows.single.data['file_count']
          : null;
      if (fileCount is! int ||
          fileCount < 0 ||
          fileCount > VaultBackupCodec.maxFileCount) {
        throw const FormatException(
          'SQLite contiene demasiados archivos para esta versión.',
        );
      }

      final rows = await stagedDatabase.customSelect('''
        SELECT
          encrypted_file_name,
          file_salt_base64,
          nonce_prefix_base64,
          size_bytes,
          sha256_hash,
          status,
          thumbnail_file_name,
          thumbnail_nonce_prefix_base64
        FROM vault_files
      ''').get();

      final restoredMasterKey = SecretKey(masterKeyBytes);
      final referencedNames = <String>{};
      for (final row in rows) {
        final data = row.data;
        final status = _requiredDbString(data, 'status');
        if (status == 'importing') {
          throw const FormatException(
            'La copia contiene una importación incompleta.',
          );
        }
        if (status != 'verified' && status != 'completed') {
          throw const FormatException(
            'SQLite contiene un estado de importación desconocido.',
          );
        }

        final encryptedName = _requiredDbString(data, 'encrypted_file_name');
        _validateLeafName(encryptedName);
        if (!manifestBlobNames.contains(encryptedName) ||
            !referencedNames.add(encryptedName)) {
          throw const FormatException(
            'SQLite referencia un blob ausente o duplicado.',
          );
        }
        final encryptedFile = File(p.join(stagedBlobs.path, encryptedName));
        if (!await encryptedFile.exists()) {
          throw const FormatException(
            'SQLite referencia un blob que no fue extraído.',
          );
        }

        final plainSize = _requiredDbInt(data, 'size_bytes');
        if (plainSize < 0 || plainSize > VaultBackupCodec.maxFileSize) {
          throw const FormatException(
            'SQLite declara un tamaño de archivo fuera de límites.',
          );
        }
        final expectedEncryptedSize =
            plainSize + (_chunkCount(plainSize, StreamCipher.chunkSize) * 16);
        if (await encryptedFile.length() != expectedEncryptedSize) {
          throw const FormatException(
            'La longitud de un blob no coincide con SQLite.',
          );
        }

        final salt = _decodeDbBase64(
          _requiredDbString(data, 'file_salt_base64'),
          16,
          'salt de archivo',
        );
        final noncePrefix = _decodeDbBase64(
          _requiredDbString(data, 'nonce_prefix_base64'),
          8,
          'nonce de archivo',
        );
        final expectedHash = _requiredDbString(data, 'sha256_hash');
        if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedHash)) {
          throw const FormatException(
            'SQLite contiene un hash SHA-256 inválido.',
          );
        }
        final fileKey = await _keyManager.deriveFileKey(
          restoredMasterKey,
          salt,
        );
        final actualHash = await StreamCipher.hashDecryptedContent(
          input: encryptedFile,
          fileKey: fileKey,
          noncePrefix: noncePrefix,
          plainFileSize: plainSize,
        );
        if (actualHash != expectedHash) {
          throw const FormatException(
            'Un blob no corresponde con el hash guardado en SQLite.',
          );
        }

        final thumbnailName = data['thumbnail_file_name'];
        final thumbnailNonceText = data['thumbnail_nonce_prefix_base64'];
        if (thumbnailName == null && thumbnailNonceText == null) {
          continue;
        }
        if (thumbnailName is! String ||
            thumbnailNonceText is! String ||
            thumbnailName.isEmpty) {
          throw const FormatException(
            'SQLite contiene metadatos de miniatura incompletos.',
          );
        }
        _validateLeafName(thumbnailName);
        if (!manifestBlobNames.contains(thumbnailName) ||
            !referencedNames.add(thumbnailName)) {
          throw const FormatException(
            'SQLite referencia una miniatura ausente o duplicada.',
          );
        }
        final thumbnail = File(p.join(stagedBlobs.path, thumbnailName));
        if (!await thumbnail.exists()) {
          throw const FormatException(
            'SQLite referencia una miniatura que no fue extraída.',
          );
        }
        final thumbnailEncryptedSize = await thumbnail.length();
        final thumbnailPlainSize = _plainSizeFromEncryptedLength(
          thumbnailEncryptedSize,
        );
        final thumbnailNonce = _decodeDbBase64(
          thumbnailNonceText,
          8,
          'nonce de miniatura',
        );
        final thumbnailKey = await _keyManager.deriveThumbnailKey(
          restoredMasterKey,
          salt,
        );
        await for (final _ in StreamCipher.decryptStream(
          input: thumbnail,
          fileKey: thumbnailKey,
          noncePrefix: thumbnailNonce,
          plainFileSize: thumbnailPlainSize,
        )) {
          // Draining the stream authenticates every GCM block without
          // persisting decrypted thumbnail bytes.
        }
      }
      if (referencedNames.length != manifestBlobNames.length ||
          !referencedNames.containsAll(manifestBlobNames)) {
        throw const FormatException(
          'La copia contiene blobs huérfanos que SQLite no referencia.',
        );
      }

      await stagedDatabase.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } finally {
      await stagedDatabase.close();
    }

    // Drift may migrate an older authenticated DB in staging. Flush it to
    // the main file and remove only its now-obsolete local sidecars.
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('${stagedDb.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }
  }

  Future<void> _swapWithRollback({
    required Directory supportDir,
    required String operationId,
    required Directory stagingDir,
    required Directory rollbackDir,
    required Uint8List restoredMasterKeyBytes,
    required Uint8List? oldMasterKeyBytes,
  }) async {
    final liveDb = File(p.join(supportDir.path, 'vault.sqlite'));
    final liveBlobs = Directory(p.join(supportDir.path, 'vault_blobs'));
    final stagedDb = File(p.join(stagingDir.path, 'vault.sqlite'));
    final stagedBlobs = Directory(p.join(stagingDir.path, 'blobs'));
    if (!await stagedDb.exists() || !await stagedBlobs.exists()) {
      throw const FormatException(
        'La bóveda preparada desapareció antes del reemplazo.',
      );
    }

    final journal = await VaultRestoreRecovery.begin(
      supportDirectory: supportDir,
      operationId: operationId,
      oldKeyFingerprint: oldMasterKeyBytes == null
          ? null
          : VaultRestoreRecovery.fingerprint(oldMasterKeyBytes),
      newKeyFingerprint: VaultRestoreRecovery.fingerprint(
        restoredMasterKeyBytes,
      ),
    );
    var restoredKeyAttempted = false;
    var newDbInstalled = false;
    var newBlobsInstalled = false;
    try {
      for (final suffix in const ['', '-wal', '-shm', '-journal']) {
        final source = File('${liveDb.path}$suffix');
        if (await source.exists()) {
          await source.rename(p.join(rollbackDir.path, 'vault.sqlite$suffix'));
        }
      }
      if (await liveBlobs.exists()) {
        await liveBlobs.rename(p.join(rollbackDir.path, 'vault_blobs'));
      }
      await journal.markOldMoved();

      await stagedDb.rename(liveDb.path);
      newDbInstalled = true;
      await stagedBlobs.rename(liveBlobs.path);
      newBlobsInstalled = true;
      await journal.markNewInstalled();

      restoredKeyAttempted = true;
      await _keyManager.importMasterKeyBytes(restoredMasterKeyBytes);
      await journal.markKeyInstalled();

      // The new files and their matching key are now durable. Rollback data
      // is deliberately deleted only after that commit point.
      try {
        await journal.retire();
      } catch (_) {
        // A leftover rollback directory is private and harmless; failure to
        // clean it must not undo a successfully committed restore.
      }
    } catch (error, stackTrace) {
      Object? rollbackError;
      var canRollBackFiles = true;
      if (restoredKeyAttempted && oldMasterKeyBytes != null) {
        try {
          await _keyManager.importMasterKeyBytes(oldMasterKeyBytes);
        } catch (error) {
          rollbackError = error;
          canRollBackFiles = false;
        }
      } else if (restoredKeyAttempted) {
        // The old Keystore key was already missing. Leave both complete file
        // sets and the journal intact; startup can inspect the key that
        // actually committed and choose the matching set without guessing.
        canRollBackFiles = false;
      }
      if (canRollBackFiles) {
        try {
          await _removeInstalledVault(
            liveDb,
            liveBlobs,
            removeDb: newDbInstalled,
            removeBlobs: newBlobsInstalled,
          );
        } catch (error) {
          rollbackError ??= error;
        }
        try {
          await _restoreRollbackFiles(
            rollbackDir: rollbackDir,
            liveDb: liveDb,
            liveBlobs: liveBlobs,
          );
          await journal.retire();
        } catch (error) {
          rollbackError ??= error;
        }
      }
      if (rollbackError != null) {
        throw StateError(
          'Falló el reemplazo y no se pudo completar el rollback: '
          '$rollbackError',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _restoreRollbackFiles({
    required Directory rollbackDir,
    required File liveDb,
    required Directory liveBlobs,
  }) async {
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final rollbackFile = File(
        p.join(rollbackDir.path, 'vault.sqlite$suffix'),
      );
      if (await rollbackFile.exists()) {
        await rollbackFile.rename('${liveDb.path}$suffix');
      }
    }
    final rollbackBlobs = Directory(p.join(rollbackDir.path, 'vault_blobs'));
    if (await rollbackBlobs.exists()) {
      await rollbackBlobs.rename(liveBlobs.path);
    }
  }

  Future<void> _removeInstalledVault(
    File liveDb,
    Directory liveBlobs, {
    required bool removeDb,
    required bool removeBlobs,
  }) async {
    if (removeDb) {
      for (final suffix in const ['', '-wal', '-shm', '-journal']) {
        final file = File('${liveDb.path}$suffix');
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    if (removeBlobs && await liveBlobs.exists()) {
      await liveBlobs.delete(recursive: true);
    }
  }

  Future<int> _readSqliteSchemaVersion(File dbFile) async {
    final raf = await dbFile.open();
    try {
      if (await dbFile.length() < 100) {
        throw const FormatException('El archivo SQLite está truncado.');
      }
      final header = Uint8List.fromList(await raf.read(100));
      final expectedMagic = Uint8List.fromList(
        utf8.encode('SQLite format 3\u0000'),
      );
      for (var i = 0; i < expectedMagic.length; i++) {
        if (header[i] != expectedMagic[i]) {
          throw const FormatException(
            'La entrada de base de datos no es SQLite.',
          );
        }
      }
      return ByteData.sublistView(header).getUint32(60, Endian.big);
    } finally {
      await raf.close();
    }
  }

  int _plainSizeFromEncryptedLength(int encryptedLength) {
    if (encryptedLength <= 16) {
      throw const FormatException(
        'Un blob de miniatura tiene una longitud inválida.',
      );
    }
    final chunkCount = _chunkCount(
      encryptedLength,
      StreamCipher.chunkSize + 16,
    );
    final plainLength = encryptedLength - (chunkCount * 16);
    if (plainLength <= 0 ||
        _chunkCount(plainLength, StreamCipher.chunkSize) != chunkCount) {
      throw const FormatException(
        'No se puede derivar la longitud de una miniatura cifrada.',
      );
    }
    return plainLength;
  }

  int _chunkCount(int length, int perChunkCapacity) =>
      length == 0 ? 0 : ((length - 1) ~/ perChunkCapacity) + 1;

  Uint8List _decodeDbBase64(String encoded, int expectedLength, String field) {
    final expectedEncodedLength = ((expectedLength + 2) ~/ 3) * 4;
    if (encoded.length != expectedEncodedLength) {
      throw FormatException('Longitud inválida para $field.');
    }
    try {
      final decoded = Uint8List.fromList(base64Decode(encoded));
      if (decoded.length != expectedLength ||
          base64Encode(decoded) != encoded) {
        throw FormatException('Longitud inválida para $field.');
      }
      return decoded;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException('Base64 inválido para $field.');
    }
  }

  String _requiredDbString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('SQLite contiene un valor inválido para $key.');
    }
    return value;
  }

  int _requiredDbInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! int) {
      throw FormatException('SQLite contiene un valor inválido para $key.');
    }
    return value;
  }

  void _validateLeafName(String name) {
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains(r'\') ||
        name.contains('\u0000') ||
        p.isAbsolute(name) ||
        p.basename(name) != name ||
        utf8.encode(name).length > VaultBackupCodec.maxFileNameBytes) {
      throw const FormatException(
        'SQLite contiene un nombre de blob no seguro.',
      );
    }
  }

  Future<void> _deleteDirectoryIfExists(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
