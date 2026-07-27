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
import '../../infrastructure/storage/atomic_file_writer.dart';
import '../../infrastructure/storage/vault_paths.dart';
import 'vault_file_lifecycle.dart';

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
  final VaultFileLifecycle _lifecycle;
  static const _uuid = Uuid();

  RestoreUseCase(
    this._keyManager,
    this._originalLocationChannel,
    this._activityRepository,
    VaultRepository vaultRepository, {
    VaultFileLifecycle? lifecycle,
  }) : _lifecycle = lifecycle ?? VaultFileLifecycle(vaultRepository);

  Future<RestoreResult> call(VaultFile file) async {
    // Exactly one of these is ever set on a given file, by construction at
    // import time — this dispatches on which import path produced the
    // record, it doesn't try each in turn hoping one works.
    final relativePath = file.originalRelativePath;
    final treeUri = file.originalTreeUri;
    final treeRelativePath = file.originalTreeRelativePath;
    final originalUri = file.originalContentUri;
    if (relativePath == null &&
        (treeUri == null || treeRelativePath == null) &&
        originalUri == null) {
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
          modifiedAt: file.fileModifiedAt,
          createdAt: file.originalCreatedAt,
          accessedAt: file.originalAccessedAt,
        );
      } else if (treeUri != null && treeRelativePath != null) {
        restored = await _originalLocationChannel.recreateInDocumentTree(
          treeUri: treeUri,
          relativeFolderPath: treeRelativePath,
          displayName: file.originalName,
          mimeType: file.mimeType,
          sourcePath: decrypted.path,
          modifiedAt: file.fileModifiedAt,
          createdAt: file.originalCreatedAt,
          accessedAt: file.originalAccessedAt,
        );
      } else {
        restored = await _originalLocationChannel.restoreToUri(
          originalUri!,
          decrypted.path,
          modifiedAt: file.fileModifiedAt,
          createdAt: file.originalCreatedAt,
          accessedAt: file.originalAccessedAt,
        );
      }
      if (!restored) return RestoreResult.needsDestination;
    } finally {
      if (await decrypted.exists()) {
        await decrypted.delete();
      }
    }

    final cleanup = await finalizeRestore(file);

    try {
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.exported,
          fileName: file.originalName,
          timestamp: DateTime.now(),
          success: cleanup.isComplete,
          detail: cleanup.isComplete
              ? 'Restaurado en su ubicación original'
              : 'Restaurado; ${cleanup.failedPaths.length} artefacto(s) cifrado(s) esperan limpieza automática',
        ),
      );
    } catch (_) {
      // The restore and metadata commit already succeeded. An unavailable
      // audit trail must not make the caller retry the external write.
    }
    return RestoreResult.restoredToOriginal;
  }

  /// Finalizes a restore performed through an explicitly chosen destination.
  ///
  /// The DB record is removed before its encrypted artifacts, so a failed
  /// metadata commit always leaves the vault copy fully usable.
  Future<ArtifactCleanupResult> finalizeRestore(VaultFile file) {
    return _lifecycle.deleteRecordThenArtifacts(file);
  }

  Future<File> _decryptToTemp(VaultFile file) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFile = File(p.join(blobsDir.path, file.encryptedFileName));
    final masterKey = await _keyManager.getOrCreateMasterKey();
    final fileKey = await _keyManager.deriveFileKey(
      masterKey,
      base64Decode(file.fileSaltBase64),
    );

    final tempDir = await VaultPaths.tempPlaybackDir();
    return AtomicFileWriter.writeStream(
      destinationDirectory: tempDir,
      preferredName: 'restore_${file.id}',
      expectedLength: file.sizeBytes,
      modifiedAt: file.fileModifiedAt,
      bytes: StreamCipher.decryptStream(
        input: encryptedFile,
        fileKey: fileKey,
        noncePrefix: base64Decode(file.noncePrefixBase64),
        plainFileSize: file.sizeBytes,
      ),
    );
  }
}
