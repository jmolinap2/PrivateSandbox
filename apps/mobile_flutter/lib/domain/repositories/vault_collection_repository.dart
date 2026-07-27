import '../entities/vault_collection.dart';
import '../entities/vault_file.dart';

abstract interface class VaultCollectionRepository {
  Stream<List<VaultCollection>> watchCollections();

  Future<String> createCollection(String name);
  Future<void> renameCollection(String id, String newName);

  /// Deletes the collection; never touches the files it contained.
  Future<void> deleteCollection(String id);

  Future<void> addFileToCollection(String fileId, String collectionId);
  Future<void> removeFileFromCollection(String fileId, String collectionId);

  Stream<List<VaultCollection>> watchCollectionsForFile(String fileId);

  /// Non-trashed files in [collectionId], most recent first.
  Stream<List<VaultFile>> watchFilesInCollection(String collectionId);
}
