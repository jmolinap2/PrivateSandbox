import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/storage/vault_paths.dart';

typedef DirectoryResolver = Future<Directory> Function();

/// Coordinates the durable metadata record with its on-disk artifacts.
///
/// Destructive operations always commit the database removal first. A crash
/// can therefore leave only an unreachable encrypted orphan (which recovery
/// can safely retry deleting), never a visible DB row whose only ciphertext
/// has already disappeared.
class VaultFileLifecycle {
  final VaultRepository _vaultRepository;
  final DirectoryResolver _blobsDirectory;
  final DirectoryResolver _playbackTempDirectory;

  VaultFileLifecycle(
    this._vaultRepository, {
    DirectoryResolver? blobsDirectory,
    DirectoryResolver? playbackTempDirectory,
  }) : _blobsDirectory = blobsDirectory ?? VaultPaths.vaultBlobsDir,
       _playbackTempDirectory =
           playbackTempDirectory ?? VaultPaths.tempPlaybackDir;

  Future<ArtifactCleanupResult> deleteRecordThenArtifacts(
    VaultFile file,
  ) async {
    await _vaultRepository.deleteFile(file.id);
    return deleteArtifacts(file);
  }

  /// Performs the structural checks available without opening the master key.
  /// AES-GCM authentication is still verified whenever the file is decrypted;
  /// this check prevents promoting a visibly partial ciphertext after a crash.
  Future<bool> hasCompleteCiphertext(VaultFile file) async {
    try {
      final blobsDir = await _blobsDirectory();
      final blob = _safeChildFile(blobsDir, file.encryptedFileName);
      if (blob == null || !await blob.exists()) return false;
      final chunks = file.sizeBytes == 0
          ? 0
          : (file.sizeBytes + StreamCipher.chunkSize - 1) ~/
                StreamCipher.chunkSize;
      final expectedCiphertextLength = file.sizeBytes + (chunks * 16);
      return await blob.length() == expectedCiphertextLength;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Deletes artifacts after their metadata is no longer reachable.
  ///
  /// Failures are returned instead of thrown because the logical deletion has
  /// already committed. Startup orphan cleanup will retry encrypted blobs.
  Future<ArtifactCleanupResult> deleteArtifacts(VaultFile file) async {
    final failures = <String>[];
    var removed = 0;
    try {
      final blobsDir = await _blobsDirectory();
      final encryptedNames = <String>{
        file.encryptedFileName,
        if (file.thumbnailFileName != null) file.thumbnailFileName!,
        // Covers a thumbnail encrypted successfully just before setThumbnail
        // failed, leaving no filename recorded in the draft row.
        '${file.id}.thumb.bin',
      };
      for (final name in encryptedNames) {
        final artifact = _safeChildFile(blobsDir, name);
        if (artifact == null) {
          failures.add(name);
          continue;
        }
        final attempt = await _deleteIfPresent(artifact);
        if (attempt == _DeletionAttempt.removed) {
          removed++;
        } else if (attempt == _DeletionAttempt.failed) {
          failures.add(artifact.path);
        }
      }
    } catch (_) {
      failures.add('vault_blobs/${file.id}');
    }

    try {
      final tempDir = await _playbackTempDirectory();
      if (await tempDir.exists() && _looksLikeVaultId(file.id)) {
        await for (final entity in tempDir.list(followLinks: false)) {
          if (entity is! File) continue;
          final name = p.basename(entity.path);
          final belongsToFile =
              name == file.id ||
              name.startsWith('${file.id}.') ||
              name == 'restore_${file.id}' ||
              name.startsWith('restore_${file.id}.');
          if (!belongsToFile) continue;
          final attempt = await _deleteIfPresent(entity);
          if (attempt == _DeletionAttempt.removed) {
            removed++;
          } else if (attempt == _DeletionAttempt.failed) {
            failures.add(entity.path);
          }
        }
      }
    } catch (_) {
      failures.add('vault_playback/${file.id}');
    }

    return ArtifactCleanupResult(removed: removed, failedPaths: failures);
  }

  /// Deletes encrypted files whose UUID no longer has a database record.
  /// Unknown filenames are left untouched: recovery only removes artifacts
  /// produced by the vault's own canonical naming scheme.
  Future<int> cleanupOrphanedBlobs() async {
    late final Directory blobsDir;
    try {
      blobsDir = await _blobsDirectory();
      if (!await blobsDir.exists()) return 0;
    } catch (_) {
      return 0;
    }

    var removed = 0;
    await for (final entity in blobsDir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      final id = _idFromCanonicalBlobName(name);
      if (id == null) continue;

      VaultFile? record;
      try {
        record = await _vaultRepository.getById(id);
      } catch (_) {
        // Never delete when the database could not confirm orphan status.
        continue;
      }
      final referenced =
          record != null &&
          (record.status != ImportStatus.completed ||
              record.encryptedFileName == name ||
              record.thumbnailFileName == name);
      if (referenced) continue;

      if (await _deleteIfPresent(entity) == _DeletionAttempt.removed) removed++;
    }
    return removed;
  }

  static File? _safeChildFile(Directory parent, String name) {
    if (name.isEmpty ||
        p.basename(name) != name ||
        name == '.' ||
        name == '..') {
      return null;
    }
    return File(p.join(parent.path, name));
  }

  static Future<_DeletionAttempt> _deleteIfPresent(File file) async {
    try {
      if (!await file.exists()) return _DeletionAttempt.absent;
      await file.delete();
      return _DeletionAttempt.removed;
    } catch (_) {
      return _DeletionAttempt.failed;
    }
  }

  static String? _idFromCanonicalBlobName(String name) {
    final match = RegExp(
      r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})(?:\.thumb)?\.bin$',
    ).firstMatch(name);
    return match?.group(1);
  }

  static bool _looksLikeVaultId(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

enum _DeletionAttempt { absent, removed, failed }

class ArtifactCleanupResult {
  final int removed;
  final List<String> failedPaths;

  const ArtifactCleanupResult({
    required this.removed,
    required this.failedPaths,
  });

  bool get isComplete => failedPaths.isEmpty;
}
