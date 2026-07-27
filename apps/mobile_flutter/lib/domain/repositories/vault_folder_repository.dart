import '../entities/vault_folder.dart';

abstract interface class VaultFolderRepository {
  /// Direct subfolders of [parentId] (null for top-level folders), by name.
  Stream<List<VaultFolder>> watchFolders(String? parentId);

  Future<VaultFolder?> getById(String id);

  Future<String> createFolder({required String name, required String? parentId});

  Future<void> renameFolder(String id, String newName);

  /// Deletes the folder and, recursively, its subfolders. Files filed under
  /// any of them are never deleted — they fall back to "unfiled" (their
  /// `folderId` is cleared).
  Future<void> deleteFolder(String id);

  /// Every folder, for building a full path/breadcrumb without N+1 lookups.
  Future<List<VaultFolder>> getAllFolders();
}
