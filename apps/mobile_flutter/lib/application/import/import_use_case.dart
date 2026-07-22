import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/metadata/metadata_extractor.dart';
import '../../infrastructure/platform/media_store_delete_channel.dart';
import '../../infrastructure/storage/vault_paths.dart';
import '../../shared/errors/vault_exceptions.dart';
import '../../shared/utils/random_bytes.dart';
import 'import_progress.dart';

/// Implements the plan's import pipeline end to end: register a draft row
/// (so an interrupted import is detectable), stream-encrypt the file,
/// verify the ciphertext round-trips to the same hash, only then mark the
/// row complete and optionally delete the original.
class ImportUseCase {
  final VaultRepository _vaultRepository;
  final KeyManager _keyManager;
  final MediaStoreDeleteChannel _mediaStoreDeleteChannel;
  static const _uuid = Uuid();

  ImportUseCase(this._vaultRepository, this._keyManager, this._mediaStoreDeleteChannel);

  Stream<ImportProgress> call({
    required PlatformFile pickedFile,
    required bool deleteOriginal,
  }) async* {
    final sourcePath = pickedFile.path;
    if (sourcePath == null) {
      throw const ImportException('No se pudo acceder al archivo seleccionado.');
    }

    final id = _uuid.v4();
    final blobsDir = await VaultPaths.vaultBlobsDir();
    final encryptedFileName = '$id.bin';
    final outputFile = File(p.join(blobsDir.path, encryptedFileName));
    final sourceFile = File(sourcePath);

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

    final draft = VaultFile(
      id: id,
      originalName: pickedFile.name,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      originalPath: sourcePath,
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

      yield ImportProgress(ImportStage.done, pickedFile.name);
    } catch (_) {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await _vaultRepository.deleteFile(id);
      yield ImportProgress(ImportStage.failed, pickedFile.name);
      rethrow;
    }
  }

  /// [pickedFile.path] is only a cached copy `file_picker` made to give this
  /// process a readable path — deleting it does nothing to the real file
  /// the user sees in their gallery/downloads. The actual source is
  /// [pickedFile.identifier] (the original content:// URI on Android),
  /// which requires the native `MediaStoreDeleteChannel` to remove under
  /// scoped storage. Falls back to a plain filesystem delete for the rare
  /// case where a real, writable path was picked directly.
  Future<bool> _tryDeleteOriginal(PlatformFile pickedFile, File cachedCopy) async {
    final identifier = pickedFile.identifier;
    if (identifier != null && identifier.isNotEmpty) {
      return _mediaStoreDeleteChannel.deleteContentUri(identifier);
    }
    try {
      await cachedCopy.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
