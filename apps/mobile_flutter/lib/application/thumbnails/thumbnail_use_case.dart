import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/file_category.dart';
import '../../infrastructure/encryption/key_manager.dart';
import '../../infrastructure/encryption/stream_cipher.dart';
import '../../infrastructure/platform/original_location_channel.dart';
import '../../infrastructure/storage/vault_paths.dart';
import '../../infrastructure/thumbnails/thumbnail_generator.dart';
import '../../shared/utils/random_bytes.dart';

class GeneratedThumbnail {
  final String fileName;
  final String noncePrefixBase64;

  const GeneratedThumbnail({required this.fileName, required this.noncePrefixBase64});
}

/// Bridges raw JPEG preview bytes — [ThumbnailGenerator] for images,
/// [OriginalLocationChannel.generateVideoThumbnail] (native
/// `MediaMetadataRetriever`) for videos — with the vault's streaming cipher,
/// so thumbnails are stored encrypted like everything else — never in a
/// public/plaintext location.
class ThumbnailUseCase {
  final KeyManager _keyManager;
  final OriginalLocationChannel _originalLocationChannel;

  ThumbnailUseCase(this._keyManager, this._originalLocationChannel);

  /// Best-effort: returns null if the category has no thumbnail support or
  /// generation fails for any reason. Never throws — a missing thumbnail
  /// just means the UI falls back to a category icon.
  Future<GeneratedThumbnail?> generateAndStore({
    required File sourceFile,
    required FileCategory category,
    required String id,
    required SecretKey masterKey,
    required Uint8List fileSalt,
  }) async {
    final bytes = switch (category) {
      FileCategory.image => await ThumbnailGenerator.generate(source: sourceFile, category: category),
      FileCategory.video => await _originalLocationChannel.generateVideoThumbnail(sourceFile.path),
      _ => null,
    };
    if (bytes == null) return null;

    final tempDir = await VaultPaths.tempPlaybackDir();
    final tempPlain = File(p.join(tempDir.path, '$id.thumb.tmp'));
    try {
      await tempPlain.writeAsBytes(bytes);

      final thumbKey = await _keyManager.deriveThumbnailKey(masterKey, fileSalt);
      final noncePrefix = randomBytes(8);
      final blobsDir = await VaultPaths.vaultBlobsDir();
      final fileName = '$id.thumb.bin';
      final outputFile = File(p.join(blobsDir.path, fileName));

      await StreamCipher.encryptFile(
        input: tempPlain,
        output: outputFile,
        fileKey: thumbKey,
        noncePrefix: noncePrefix,
      );

      return GeneratedThumbnail(fileName: fileName, noncePrefixBase64: base64Encode(noncePrefix));
    } catch (_) {
      return null;
    } finally {
      if (await tempPlain.exists()) {
        await tempPlain.delete();
      }
    }
  }

  Future<Uint8List?> loadDecrypted({
    required String fileSaltBase64,
    required String thumbnailFileName,
    required String thumbnailNoncePrefixBase64,
  }) async {
    try {
      final blobsDir = await VaultPaths.vaultBlobsDir();
      final thumbFile = File(p.join(blobsDir.path, thumbnailFileName));
      if (!await thumbFile.exists()) return null;

      final masterKey = await _keyManager.getOrCreateMasterKey();
      final thumbKey = await _keyManager.deriveThumbnailKey(masterKey, base64Decode(fileSaltBase64));
      // Thumbnails are always well under one chunk (1 MiB), so the plain
      // size is just the encrypted length minus the single 16-byte MAC.
      final plainSize = await thumbFile.length() - 16;
      if (plainSize <= 0) return null;

      final bytes = BytesBuilder(copy: false);
      await for (final chunk in StreamCipher.decryptStream(
        input: thumbFile,
        fileKey: thumbKey,
        noncePrefix: base64Decode(thumbnailNoncePrefixBase64),
        plainFileSize: plainSize,
      )) {
        bytes.add(chunk);
      }
      return bytes.toBytes();
    } catch (_) {
      return null;
    }
  }
}
