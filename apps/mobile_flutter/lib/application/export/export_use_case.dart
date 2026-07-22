import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/vault_file.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Restores a vault file's original bytes to a chosen destination directory,
/// decrypting it in the same streaming fashion it was imported with.
class ExportUseCase {
  final KeyManager _keyManager;

  ExportUseCase(this._keyManager);

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
    } finally {
      await sink.close();
    }
    return outputFile;
  }
}
