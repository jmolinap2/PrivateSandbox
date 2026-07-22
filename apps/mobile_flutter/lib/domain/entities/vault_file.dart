import 'file_category.dart';
import 'import_status.dart';

/// A file stored inside the encrypted vault. Mirrors the metadata the plan
/// requires to be tracked: original identity (name/extension/mime/size/path),
/// dates, integrity hash and the encryption parameters needed to decrypt it.
class VaultFile {
  final String id;
  final String originalName;
  final String extension;
  final String mimeType;
  final int sizeBytes;
  final String? originalPath;
  final DateTime importedAt;
  final DateTime? fileModifiedAt;
  final FileCategory category;
  final ImportStatus status;

  /// File name of the ciphertext blob inside the private vault directory.
  final String encryptedFileName;

  /// Base64-encoded HKDF salt used to derive this file's encryption key
  /// from the vault master key.
  final String fileSaltBase64;

  /// Base64-encoded 8-byte random prefix used together with a per-chunk
  /// counter to build each chunk's 12-byte AES-GCM nonce.
  final String noncePrefixBase64;

  /// SHA-256 hex digest of the original plaintext, used to verify integrity
  /// at import time and on demand afterwards.
  final String sha256Hash;

  /// Whether the original file was deleted from its source location after
  /// a verified import (best-effort; not all sources are deletable).
  final bool originalDeleted;

  const VaultFile({
    required this.id,
    required this.originalName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.originalPath,
    required this.importedAt,
    required this.fileModifiedAt,
    required this.category,
    required this.status,
    required this.encryptedFileName,
    required this.fileSaltBase64,
    required this.noncePrefixBase64,
    required this.sha256Hash,
    required this.originalDeleted,
  });

  VaultFile copyWith({
    ImportStatus? status,
    String? sha256Hash,
    bool? originalDeleted,
  }) {
    return VaultFile(
      id: id,
      originalName: originalName,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      originalPath: originalPath,
      importedAt: importedAt,
      fileModifiedAt: fileModifiedAt,
      category: category,
      status: status ?? this.status,
      encryptedFileName: encryptedFileName,
      fileSaltBase64: fileSaltBase64,
      noncePrefixBase64: noncePrefixBase64,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      originalDeleted: originalDeleted ?? this.originalDeleted,
    );
  }
}
