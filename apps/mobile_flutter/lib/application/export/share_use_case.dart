import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/platform/system_channel.dart';
import '../../infrastructure/storage/atomic_file_writer.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Fase 3's "compartición controlada": decrypts a vault file into the private
/// share temp dir (never public storage) under its original name, then hands
/// exactly that one file to the Android share sheet with a one-shot read
/// grant. The plaintext lives only in app-private cache and is wiped on the
/// next app start; the receiving app only ever sees the single URI it was
/// granted.
class ShareUseCase {
  final KeyManager _keyManager;
  final SystemChannel _systemChannel;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  ShareUseCase(this._keyManager, this._systemChannel, this._activityRepository);

  Future<bool> call(VaultFile file) async {
    final shareDir = await VaultPaths.tempShareDir();

    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(
      masterKey,
      base64Decode(file.fileSaltBase64),
    );

    File? outputFile;
    try {
      outputFile = await AtomicFileWriter.writeStream(
        destinationDirectory: shareDir,
        preferredName: file.originalName,
        expectedLength: file.sizeBytes,
        bytes: StreamCipher.decryptStream(
          input: encryptedFile,
          fileKey: fileKey,
          noncePrefix: base64Decode(file.noncePrefixBase64),
          plainFileSize: file.sizeBytes,
        ),
      );

      final shared = await _systemChannel.shareFile(
        sourcePath: outputFile.path,
        mimeType: file.mimeType,
        displayName: file.originalName,
      );
      if (!shared) {
        await _deleteBestEffort(outputFile);
      }
      await _logBestEffort(file.originalName, shared);
      return shared;
    } catch (_) {
      if (outputFile != null) await _deleteBestEffort(outputFile);
      await _logBestEffort(file.originalName, false);
      rethrow;
    }
  }

  Future<void> _deleteBestEffort(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Startup cleanup is the final fallback for private share temporaries.
    }
  }

  Future<void> _logBestEffort(String fileName, bool success) async {
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
      // Sharing already succeeded or failed independently from the audit log.
    }
  }
}
