import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/platform/original_location_channel.dart';
import '../../infrastructure/storage/vault_paths.dart';

enum RestoreResult { restoredToOriginal, needsDestination }

/// Tries to put a file back exactly where it came from: gallery-sourced
/// files are recreated in their original MediaStore folder (their content
/// URI is gone once deleted, so it can't be reused), file-explorer-sourced
/// files are written back to their original document URI if it's still
/// valid. Only asks the user for a destination when neither is possible.
///
/// A successful restore also removes the file from the vault — once it's
/// back in the regular gallery/folder, keeping an encrypted duplicate
/// inside the vault would defeat the point of "restoring" it.
class RestoreUseCase {
  final KeyManager _keyManager;
  final OriginalLocationChannel _originalLocationChannel;
  final ActivityRepository _activityRepository;
  final VaultRepository _vaultRepository;
  static const _uuid = Uuid();

  RestoreUseCase(
    this._keyManager,
    this._originalLocationChannel,
    this._activityRepository,
    this._vaultRepository,
  );

  Future<RestoreResult> call(VaultFile file) async {
    // Exactly one of these is ever set on a given file, by construction at
    // import time — this dispatches on which import path produced the
    // record, it doesn't try each in turn hoping one works.
    final relativePath = file.originalRelativePath;
    final treeUri = file.originalTreeUri;
    final treeRelativePath = file.originalTreeRelativePath;
    final originalUri = file.originalContentUri;
    if (relativePath == null && (treeUri == null || treeRelativePath == null) && originalUri == null) {
      return RestoreResult.needsDestination;
    }

    final decrypted = await _decryptToTemp(file);
    try {
      final bool restored;
      if (relativePath != null) {
        restored = await _originalLocationChannel.recreateInMediaStore(
          relativePath: relativePath,
          displayName: file.originalName,
          mimeType: file.mimeType,
          sourcePath: decrypted.path,
        );
      } else if (treeUri != null && treeRelativePath != null) {
        restored = await _originalLocationChannel.recreateInDocumentTree(
          treeUri: treeUri,
          relativeFolderPath: treeRelativePath,
          displayName: file.originalName,
          mimeType: file.mimeType,
          sourcePath: decrypted.path,
        );
      } else {
        restored = await _originalLocationChannel.restoreToUri(originalUri!, decrypted.path);
      }
      if (!restored) return RestoreResult.needsDestination;
    } finally {
      if (await decrypted.exists()) {
        await decrypted.delete();
      }
    }

    await _removeFromVault(file);

    await _activityRepository.logEvent(ActivityEvent(
      id: _uuid.v4(),
      type: ActivityEventType.exported,
      fileName: file.originalName,
      timestamp: DateTime.now(),
      success: true,
      detail: 'Restaurado en su ubicación original',
    ));
    return RestoreResult.restoredToOriginal;
  }

  Future<void> _removeFromVault(VaultFile file) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();

    final blob = File(p.join(blobsDir.path, file.encryptedFileName));
    if (await blob.exists()) {
      await blob.delete();
    }

    final thumbnailFileName = file.thumbnailFileName;
    if (thumbnailFileName != null) {
      final thumbBlob = File(p.join(blobsDir.path, thumbnailFileName));
      if (await thumbBlob.exists()) {
        await thumbBlob.delete();
      }
    }

    await _vaultRepository.deleteFile(file.id);
  }

  Future<File> _decryptToTemp(VaultFile file) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(masterKey, base64Decode(file.fileSaltBase64));

    final tempDir = await VaultPaths.tempPlaybackDir();
    final tempFile = File(p.join(tempDir.path, 'restore_${file.id}'));
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
    } catch (_) {
      // A decryption failure partway through (corrupt ciphertext, I/O
      // error) would otherwise leave a partial plaintext file sitting in
      // the temp dir — delete it rather than let the caller's cleanup miss
      // it because `tempFile` was never actually returned.
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      await sink.close();
    }
    return tempFile;
  }
}
