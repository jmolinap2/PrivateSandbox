import '../entities/file_category.dart';
import '../entities/vault_file.dart';
import '../entities/vault_smart_album.dart';

abstract interface class VaultSmartAlbumRepository {
  Stream<List<VaultSmartAlbum>> watchSmartAlbums();

  Future<void> createSmartAlbum({
    required String name,
    required FileCategory? categoryFilter,
    required bool favoritesOnly,
    required String? tagId,
  });

  Future<void> deleteSmartAlbum(String id);

  /// Live-recomputed members of [album], most recent first.
  Stream<List<VaultFile>> watchFilesFor(VaultSmartAlbum album);
}
