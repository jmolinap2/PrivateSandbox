import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/storage/atomic_file_writer.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Restores a vault file's original bytes to a chosen destination directory,
/// decrypting it in the same streaming fashion it was imported with.
class ExportUseCase {
  final KeyManager _keyManager;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  ExportUseCase(this._keyManager, this._activityRepository);

  Future<File> call({
    required VaultFile file,
    required Directory destinationDir,
  }) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(
      masterKey,
      base64Decode(file.fileSaltBase64),
    );

    try {
      await AtomicFileWriter.cleanupStalePartials(destinationDir);
      final outputFile = await AtomicFileWriter.writeStream(
        destinationDirectory: destinationDir,
        preferredName: file.originalName,
        expectedLength: file.sizeBytes,
        modifiedAt: file.fileModifiedAt,
        bytes: StreamCipher.decryptStream(
          input: encryptedFile,
          fileKey: fileKey,
          noncePrefix: base64Decode(file.noncePrefixBase64),
          plainFileSize: file.sizeBytes,
        ),
      );
      await _logBestEffort(success: true, fileName: file.originalName);
      return outputFile;
    } catch (_) {
      await _logBestEffort(success: false, fileName: file.originalName);
      rethrow;
    }
  }

  Future<void> _logBestEffort({
    required bool success,
    required String fileName,
  }) async {
    try {
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.exported,
          fileName: fileName,
          timestamp: DateTime.now(),
          success: success,
        ),
      );
    } catch (_) {
      // Export durability does not depend on the audit trail.
    }
  }
}
