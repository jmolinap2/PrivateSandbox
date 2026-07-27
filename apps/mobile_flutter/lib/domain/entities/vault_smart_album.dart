import 'file_category.dart';

/// A saved filter — its members are recomputed live from [categoryFilter] /
/// [favoritesOnly] / [tagId] every time it's opened, not a fixed list.
class VaultSmartAlbum {
  final String id;
  final String name;
  final FileCategory? categoryFilter;
  final bool favoritesOnly;
  final String? tagId;
  final DateTime createdAt;

  const VaultSmartAlbum({
    required this.id,
    required this.name,
    required this.categoryFilter,
    required this.favoritesOnly,
    required this.tagId,
    required this.createdAt,
  });
}
