/// A file chosen for import, regardless of which picker produced it.
/// Decouples the import pipeline from any specific picker package's data
/// class (`file_picker`'s `PlatformFile`, `photo_manager`'s `AssetEntity`).
class PickedFile {
  /// Real, readable path — always present, used for streaming encryption.
  final String path;

  final String name;
  final int size;

  /// SAF document URI (explorer-sourced picks only) — used to delete the
  /// original and, later, to restore to the exact same location.
  final String? contentUri;

  /// `photo_manager` asset id (gallery-sourced picks only) — used to
  /// delete the original via `PhotoManager.editor.deleteWithIds`.
  final String? galleryAssetId;

  /// MediaStore `RELATIVE_PATH` of the asset (e.g. `DCIM/Camera/`),
  /// gallery-sourced picks only. Deleting a gallery asset removes its
  /// content URI permanently, so restoring later can't reuse that URI —
  /// this is captured up front so restore can recreate the file in the
  /// same folder instead.
  final String? galleryRelativePath;

  /// A persisted SAF folder-tree grant covering this file's parent folder,
  /// resolved up front (before import starts) for explorer-sourced picks
  /// that will have their original deleted — same purpose as
  /// [galleryRelativePath], but for the explorer source: lets restore
  /// recreate the file in the same folder even after its original document
  /// URI is gone. Null means no such grant was resolved (kept original, or
  /// the user declined/no covering folder was granted).
  final String? treeUri;

  /// The file's folder path relative to [treeUri]'s root (e.g. "" if it
  /// sits directly in the granted folder, "Sub" if one level deeper). Only
  /// meaningful together with [treeUri].
  final String? treeRelativeFolderPath;

  const PickedFile({
    required this.path,
    required this.name,
    required this.size,
    this.contentUri,
    this.galleryAssetId,
    this.galleryRelativePath,
    this.treeUri,
    this.treeRelativeFolderPath,
  });

  /// Returns a copy with the folder-tree grant fields set, leaving
  /// everything else unchanged.
  PickedFile withTreeGrant({required String treeUri, required String relativeFolderPath}) {
    return PickedFile(
      path: path,
      name: name,
      size: size,
      contentUri: contentUri,
      galleryAssetId: galleryAssetId,
      galleryRelativePath: galleryRelativePath,
      treeUri: treeUri,
      treeRelativeFolderPath: relativeFolderPath,
    );
  }
}
