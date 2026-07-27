import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/metadata/metadata_extractor.dart';
import '../../infrastructure/platform/original_location_channel.dart';
import '../../infrastructure/storage/vault_paths.dart';
import '../../shared/errors/vault_exceptions.dart';
import '../../shared/utils/random_bytes.dart';
import '../thumbnails/thumbnail_use_case.dart';
import 'import_progress.dart';
import 'picked_file.dart';

/// Implements the plan's import pipeline end to end: register a draft row
/// (so an interrupted import is detectable), stream-encrypt the file,
/// verify the ciphertext round-trips to the same hash, only then mark the
/// row complete and optionally delete the original.
class ImportUseCase {
  final VaultRepository _vaultRepository;
  final KeyManager _keyManager;
  final OriginalLocationChannel _originalLocationChannel;
  final ThumbnailUseCase _thumbnailUseCase;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  ImportUseCase(
    this._vaultRepository,
    this._keyManager,
    this._originalLocationChannel,
    this._thumbnailUseCase,
    this._activityRepository,
  );

  Stream<ImportProgress> call({
    required PickedFile pickedFile,
    required bool deleteOriginal,
    bool Function()? isCancelled,
  }) async* {
    final id = _uuid.v4();
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFileName = '$id.bin';
    final outputFile = File(p.join(blobsDir.path, encryptedFileName));
    final sourceFile = File(pickedFile.path);

    final sizeBytes = await sourceFile.length();
    final extension = p.extension(pickedFile.name).replaceFirst('.', '');
    final mimeType = MetadataExtractor.mimeTypeFor(pickedFile.name);
    final category = MetadataExtractor.categoryFor(mimeType);
    final fileSalt = randomBytes(16);
    final noncePrefix = randomBytes(8);
    DateTime? fileModifiedAt;
    try {
      fileModifiedAt = await sourceFile.lastModified();
    } catch (_) {
      fileModifiedAt = null;
    }

    // A document URI's persisted permission is only useful for restore when
    // the original is kept: deleting it invalidates that same URI, so
    // there's no point persisting/storing it when deleteOriginal is true —
    // the folder-tree grant (resolved up front, carried on pickedFile) is
    // what restore uses for that case instead.
    String? originalContentUri;
    final contentUri = pickedFile.contentUri;
    if (!deleteOriginal && contentUri != null && contentUri.isNotEmpty) {
      final persisted = await _originalLocationChannel.takePersistableUriPermission(contentUri);
      if (persisted) originalContentUri = contentUri;
    }
    // Gallery picks capture the MediaStore folder instead, so restore can
    // recreate the file there even after the original asset is deleted.
    final originalRelativePath = pickedFile.galleryAssetId != null ? pickedFile.galleryRelativePath : null;

    final draft = VaultFile(
      id: id,
      originalName: pickedFile.name,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      originalPath: pickedFile.path,
      originalContentUri: originalContentUri,
      originalRelativePath: originalRelativePath,
      originalTreeUri: pickedFile.treeUri,
      originalTreeRelativePath: pickedFile.treeRelativeFolderPath,
      importedAt: DateTime.now(),
      fileModifiedAt: fileModifiedAt,
      category: category,
      status: ImportStatus.importing,
      encryptedFileName: encryptedFileName,
      fileSaltBase64: base64Encode(fileSalt),
      noncePrefixBase64: base64Encode(noncePrefix),
      sha256Hash: '',
      originalDeleted: false,
    );
    await _vaultRepository.insertFile(draft);

    try {
      yield ImportProgress(ImportStage.encrypting, pickedFile.name);
      final masterKey = await _keyManager.getOrCreateMasterKey();
      final fileKey = await _keyManager.deriveFileKey(masterKey, fileSalt);

      final sourceHash = await StreamCipher.encryptFile(
        input: sourceFile,
        output: outputFile,
        fileKey: fileKey,
        noncePrefix: noncePrefix,
        isCancelled: isCancelled,
      );

      yield ImportProgress(ImportStage.verifying, pickedFile.name);
      final verifyHash = await StreamCipher.hashDecryptedContent(
        input: outputFile,
        fileKey: fileKey,
        noncePrefix: noncePrefix,
        plainFileSize: sizeBytes,
      );
      if (verifyHash != sourceHash) {
        throw const IntegrityException('La verificación de integridad falló tras el cifrado.');
      }

      // Must run before any "delete original" step: for gallery-sourced
      // picks, sourceFile IS the real on-disk asset, not a cache copy —
      // deleting the MediaStore entry can delete that file too, leaving
      // nothing left to read a thumbnail from.
      final thumbnail = await _thumbnailUseCase.generateAndStore(
        sourceFile: sourceFile,
        category: category,
        id: id,
        masterKey: masterKey,
        fileSalt: fileSalt,
      );
      if (thumbnail != null) {
        await _vaultRepository.setThumbnail(
          id,
          fileName: thumbnail.fileName,
          noncePrefixBase64: thumbnail.noncePrefixBase64,
        );
      }

      var originalDeleted = false;
      if (deleteOriginal) {
        originalDeleted = await _tryDeleteOriginal(pickedFile, sourceFile);
      }

      yield ImportProgress(ImportStage.savingMetadata, pickedFile.name);
      await _vaultRepository.completeImport(
        id: id,
        sha256Hash: sourceHash,
        originalDeleted: originalDeleted,
      );
      await _activityRepository.logEvent(ActivityEvent(
        id: _uuid.v4(),
        type: ActivityEventType.imported,
        fileName: pickedFile.name,
        timestamp: DateTime.now(),
        success: true,
      ));

      yield ImportProgress(ImportStage.done, pickedFile.name);
    } on CancelledException {
      // User aborted mid-import: roll the draft back exactly like a failure,
      // but report it as a clean cancellation — no "failed" activity entry,
      // nothing rethrown for the batch runner to treat as an error.
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await _vaultRepository.deleteFile(id);
      yield ImportProgress(ImportStage.cancelled, pickedFile.name);
    } catch (_) {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await _vaultRepository.deleteFile(id);
      await _activityRepository.logEvent(ActivityEvent(
        id: _uuid.v4(),
        type: ActivityEventType.imported,
        fileName: pickedFile.name,
        timestamp: DateTime.now(),
        success: false,
      ));
      yield ImportProgress(ImportStage.failed, pickedFile.name);
      rethrow;
    }
  }

  /// [pickedFile.path] is only a copy made to give this process a readable
  /// path — deleting it does nothing to the real file the user sees in
  /// their gallery/downloads. Which real API removes the original depends
  /// on how it was picked: `photo_manager` asset deletion for gallery
  /// picks (genuine MediaStore URIs, so the system consent flow works),
  /// `OriginalLocationChannel` for file-explorer picks (SAF document
  /// URIs). Falls back to a plain filesystem delete for the rare case
  /// where a real, writable path was picked directly.
  Future<bool> _tryDeleteOriginal(PickedFile pickedFile, File cachedCopy) async {
    final assetId = pickedFile.galleryAssetId;
    if (assetId != null && assetId.isNotEmpty) {
      final deletedIds = await PhotoManager.editor.deleteWithIds([assetId]);
      return deletedIds.contains(assetId);
    }
    final contentUri = pickedFile.contentUri;
    if (contentUri != null && contentUri.isNotEmpty) {
      return _originalLocationChannel.deleteContentUri(contentUri);
    }
    try {
      await cachedCopy.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
