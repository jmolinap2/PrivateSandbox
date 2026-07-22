import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/vault_file.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Decrypts a vault file into the app's private temporary directory just
/// long enough for a viewer/player to open it, and removes it again
/// afterwards. Plaintext is never written outside app-private storage.
class PlaybackUseCase {
  final KeyManager _keyManager;

  PlaybackUseCase(this._keyManager);

  Future<File> decryptToTemp(VaultFile file) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(masterKey, base64Decode(file.fileSaltBase64));

    final tempDir = await VaultPaths.tempPlaybackDir();
    final suffix = file.extension.isEmpty ? '' : '.${file.extension}';
    final tempFile = File(p.join(tempDir.path, '${file.id}$suffix'));

    final sink = tempFile.openWrite();
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
    } finally {
      await sink.close();
    }
    return tempFile;
  }

  Future<void> cleanupTemp(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
