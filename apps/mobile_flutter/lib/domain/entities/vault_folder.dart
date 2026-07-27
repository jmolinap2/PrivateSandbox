/// A virtual folder — purely organizational, doesn't move ciphertext blobs
/// on disk. [parentId] null means a top-level folder.
class VaultFolder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  const VaultFolder({
    required this.id,
    required this.name,
    required this.parentId,
    required this.createdAt,
  });
}
