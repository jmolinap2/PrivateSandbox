import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Restores a vault file's original bytes to a chosen destination directory,
/// decrypting it in the same streaming fashion it was imported with.
class ExportUseCase {
  final KeyManager _keyManager;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  ExportUseCase(this._keyManager, this._activityRepository);

  Future<File> call({required VaultFile file, required Directory destinationDir}) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(masterKey, base64Decode(file.fileSaltBase64));

    final outputFile = File(p.join(destinationDir.path, file.originalName));
    final sink = outputFile.openWrite();
    try {
      await for (final chunk in StreamCipher.decryptStream(
        input: encryptedFile,
        fileKey: fileKey,
        noncePrefix: base64Decode(file.noncePrefixBase64),
        plainFileSize: file.sizeBytes,
      )) {
        sink.add(chunk);
      }
      await sink.flush();
      final modifiedAt = file.fileModifiedAt;
      if (modifiedAt != null) {
        try {
          await outputFile.setLastModified(modifiedAt);
        } catch (_) {
          // Not all destinations (e.g. some SAF-backed folders) support
          // setting mtime — the content is still byte-exact regardless.
        }
      }
      await _activityRepository.logEvent(ActivityEvent(
        id: _uuid.v4(),
        type: ActivityEventType.exported,
        fileName: file.originalName,
        timestamp: DateTime.now(),
        success: true,
      ));
    } catch (_) {
      await _activityRepository.logEvent(ActivityEvent(
        id: _uuid.v4(),
        type: ActivityEventType.exported,
        fileName: file.originalName,
        timestamp: DateTime.now(),
        success: false,
      ));
      rethrow;
    } finally {
      await sink.close();
      // An export interrupted partway (app killed, disk full, permission
      // revoked mid-write) would otherwise leave a truncated, undecodable
      // file sitting in the user's chosen folder looking like a real one.
      if (await outputFile.exists()) {
        final expectedSize = file.sizeBytes;
        final actualSize = await outputFile.length();
        if (actualSize != expectedSize) {
          try {
            await outputFile.delete();
          } catch (_) {
            // Best-effort — some destinations (e.g. certain SAF-backed
            // folders) may not allow deleting right after a failed write.
          }
        }
      }
    }
    return outputFile;
  }
}
