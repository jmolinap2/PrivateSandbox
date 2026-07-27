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

  /// The original content:// URI, if the app still holds a persisted
  /// read/write permission grant on it (only possible for files picked via
  /// the file explorer, not the Photo Picker). Deleting the original also
  /// deletes this URI's underlying document, so it's only reusable for
  /// restore when the original was kept (deleteOriginal was false).
  final String? originalContentUri;

  /// MediaStore `RELATIVE_PATH` the file lived in before import (gallery
  /// picks only, e.g. `DCIM/Camera/`). Since deleting a gallery asset
  /// invalidates [originalContentUri] permanently, restore uses this to
  /// recreate the file in the same folder instead of writing back to a
  /// URI that no longer exists.
  final String? originalRelativePath;

  /// Persisted SAF folder-tree grant covering the file's original folder —
  /// explorer-sourced imports whose original was deleted, only. Lets restore
  /// recreate the file in that folder even though [originalContentUri]'s
  /// document is gone (deleting a SAF document invalidates only that
  /// document's own URI, not a separately granted folder tree).
  final String? originalTreeUri;

  /// The file's folder path relative to [originalTreeUri]'s root. Only
  /// meaningful together with [originalTreeUri].
  final String? originalTreeRelativePath;

  final DateTime importedAt;
  final DateTime? fileModifiedAt;

  /// Source timestamps captured before the original is removed. Android and
  /// some document providers don't always allow restoring these values, so
  /// they are retained as authoritative informational metadata even when the
  /// exported file system can only accept [fileModifiedAt].
  final DateTime? originalCreatedAt;
  final DateTime? originalAccessedAt;

  /// Versioned JSON object with source attributes that cannot be represented
  /// portably by the public fields (provider, mode, original stat values,
  /// platform-specific identifiers, and future metadata additions).
  final String? originalMetadataJson;

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

  final bool isFavorite;

  /// Last time this file was opened in a viewer/player — doubles as the
  /// "history" signal for the library's "recientes"/"más vistos" sorting.
  final DateTime? lastOpenedAt;

  /// Last playback position for video/audio, so playback can resume where
  /// the user left off.
  final int? playbackPositionMs;

  /// File name of the encrypted thumbnail blob, if one was generated at
  /// import time (images and videos; other categories fall back to a
  /// category icon).
  final String? thumbnailFileName;

  /// Base64-encoded nonce prefix for the thumbnail blob — independent from
  /// the main content's, even though both are derived from the same salt.
  final String? thumbnailNoncePrefixBase64;

  /// When set, the file is in the private trash: hidden from the library,
  /// not yet permanently deleted, and can still be recovered.
  final DateTime? deletedAt;

  bool get isTrashed => deletedAt != null;

  /// Virtual folder this file is filed under. Null means "unfiled".
  final String? folderId;

  const VaultFile({
    required this.id,
    required this.originalName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.originalPath,
    this.originalContentUri,
    this.originalRelativePath,
    this.originalTreeUri,
    this.originalTreeRelativePath,
    required this.importedAt,
    required this.fileModifiedAt,
    this.originalCreatedAt,
    this.originalAccessedAt,
    this.originalMetadataJson,
    required this.category,
    required this.status,
    required this.encryptedFileName,
    required this.fileSaltBase64,
    required this.noncePrefixBase64,
    required this.sha256Hash,
    required this.originalDeleted,
    this.isFavorite = false,
    this.lastOpenedAt,
    this.playbackPositionMs,
    this.thumbnailFileName,
    this.thumbnailNoncePrefixBase64,
    this.deletedAt,
    this.folderId,
  });

  bool get hasThumbnail => thumbnailFileName != null && thumbnailNoncePrefixBase64 != null;

  VaultFile copyWith({
    ImportStatus? status,
    String? sha256Hash,
    bool? originalDeleted,
    bool? isFavorite,
    DateTime? lastOpenedAt,
    int? playbackPositionMs,
    String? thumbnailFileName,
    String? thumbnailNoncePrefixBase64,
    DateTime? deletedAt,
  }) {
    return VaultFile(
      id: id,
      originalName: originalName,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      originalPath: originalPath,
      originalContentUri: originalContentUri,
      originalRelativePath: originalRelativePath,
      originalTreeUri: originalTreeUri,
      originalTreeRelativePath: originalTreeRelativePath,
      importedAt: importedAt,
      fileModifiedAt: fileModifiedAt,
      originalCreatedAt: originalCreatedAt,
      originalAccessedAt: originalAccessedAt,
      originalMetadataJson: originalMetadataJson,
      category: category,
      status: status ?? this.status,
      encryptedFileName: encryptedFileName,
      fileSaltBase64: fileSaltBase64,
      noncePrefixBase64: noncePrefixBase64,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      originalDeleted: originalDeleted ?? this.originalDeleted,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      playbackPositionMs: playbackPositionMs ?? this.playbackPositionMs,
      thumbnailFileName: thumbnailFileName ?? this.thumbnailFileName,
      thumbnailNoncePrefixBase64: thumbnailNoncePrefixBase64 ?? this.thumbnailNoncePrefixBase64,
      deletedAt: deletedAt ?? this.deletedAt,
      folderId: folderId,
    );
  }
}
