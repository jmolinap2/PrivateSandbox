import '../entities/vault_file.dart';
import '../entities/vault_tag.dart';

abstract interface class VaultTagRepository {
  Stream<List<VaultTag>> watchTags();

  /// Dedupes by (case-insensitive) name — tagging with an existing name
  /// reuses the same tag instead of creating a duplicate.
  Future<VaultTag> getOrCreateTag(String name);

  Future<void> renameTag(String id, String newName);

  /// Deletes the tag and its assignments; never touches the files themselves.
  Future<void> deleteTag(String id);

  Future<void> addTagToFile(String fileId, String tagId);
  Future<void> removeTagFromFile(String fileId, String tagId);

  Stream<List<VaultTag>> watchTagsForFile(String fileId);

  /// Non-trashed files carrying [tagId], most recent first.
  Stream<List<VaultFile>> watchFilesWithTag(String tagId);
}
