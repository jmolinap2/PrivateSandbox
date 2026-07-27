import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/vault_file.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// On-demand version of the round-trip hash check already done once at
/// import time — lets the user confirm a file's ciphertext still decrypts
/// to exactly what was imported, e.g. after suspecting disk corruption.
class VerifyIntegrityUseCase {
  final KeyManager _keyManager;

  VerifyIntegrityUseCase(this._keyManager);

  Future<bool> call(VaultFile file) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(masterKey, base64Decode(file.fileSaltBase64));
    final hash = await StreamCipher.hashDecryptedContent(
      input: encryptedFile,
      fileKey: fileKey,
      noncePrefix: base64Decode(file.noncePrefixBase64),
      plainFileSize: file.sizeBytes,
    );
    return hash == file.sha256Hash;
  }
}
