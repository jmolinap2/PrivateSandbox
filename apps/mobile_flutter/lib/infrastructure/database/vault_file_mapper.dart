import '../../domain/entities/file_category.dart';
import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import 'app_database.dart';

/// Shared by every repository that reads [VaultFiles] rows (tags,
/// collections, smart albums, in addition to [VaultRepositoryImpl] itself),
/// so the row→entity mapping lives in exactly one place.
VaultFile mapVaultFileRow(VaultFileRow row) {
  return VaultFile(
    id: row.id,
    originalName: row.originalName,
    extension: row.extension,
    mimeType: row.mimeType,
    sizeBytes: row.sizeBytes,
    originalPath: row.originalPath,
    originalContentUri: row.originalContentUri,
    originalRelativePath: row.originalRelativePath,
    originalTreeUri: row.originalTreeUri,
    originalTreeRelativePath: row.originalTreeRelativePath,
    importedAt: row.importedAt,
    fileModifiedAt: row.fileModifiedAt,
    category: FileCategory.values.byName(row.category),
    status: ImportStatus.values.byName(row.status),
    encryptedFileName: row.encryptedFileName,
    fileSaltBase64: row.fileSaltBase64,
    noncePrefixBase64: row.noncePrefixBase64,
    sha256Hash: row.sha256Hash,
    originalDeleted: row.originalDeleted,
    isFavorite: row.isFavorite,
    lastOpenedAt: row.lastOpenedAt,
    playbackPositionMs: row.playbackPositionMs,
    thumbnailFileName: row.thumbnailFileName,
    thumbnailNoncePrefixBase64: row.thumbnailNoncePrefixBase64,
    deletedAt: row.deletedAt,
    folderId: row.folderId,
  );
}
