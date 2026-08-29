import 'package:flutter/services.dart';

/// Bridges to native Android code that manages the file the user originally
/// picked from outside the vault (gallery, downloads, a document picker,
/// etc.): deleting it once its encrypted copy is verified, retaining access
/// to it for a later restore, and writing back to it.
///
/// None of this can be plain `dart:io` file operations — `PlatformFile.path`
/// is only a cached copy this app made to get a readable path; the real
/// location is a `content://` URI, which under scoped storage requires
/// `DocumentsContract`/`MediaStore` APIs on the Android side (sometimes with
/// a one-time system confirmation dialog).
class OriginalLocationChannel {
  static const _mediaStoreChannel = MethodChannel(
    'privatesandbox.app/media_store',
  );

  Future<bool> deleteContentUri(String uri) async {
    try {
      final result = await _mediaStoreChannel.invokeMethod<bool>(
        'deleteContentUri',
        {'uri': uri},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Retains read/write access to a SAF document URI beyond the picker
  /// result, so the file can be restored to its exact original location
  /// later. Only works for URIs from the file explorer (ACTION_OPEN_DOCUMENT)
  /// — Photo Picker URIs never support this, by Android design.
  Future<bool> takePersistableUriPermission(String uri) async {
    try {
      final result = await _mediaStoreChannel.invokeMethod<bool>(
        'takePersistableUriPermission',
        {'uri': uri},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Overwrites the file at [uri] with the bytes at [sourcePath]. Returns
  /// false if the original location no longer exists or isn't writable —
  /// callers should fall back to asking the user for a destination.
  Future<bool> restoreToUri(
    String uri,
    String sourcePath, {
    DateTime? modifiedAt,
    DateTime? createdAt,
    DateTime? accessedAt,
  }) async {
    try {
      final result = await _mediaStoreChannel
          .invokeMethod<bool>('restoreToUri', {
            'uri': uri,
            'sourcePath': sourcePath,
            'modifiedAtEpochMs': modifiedAt?.millisecondsSinceEpoch,
            'createdAtEpochMs': createdAt?.millisecondsSinceEpoch,
            'accessedAtEpochMs': accessedAt?.millisecondsSinceEpoch,
          });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Re-creates a MediaStore entry for a gallery-sourced file that was
  /// deleted after import, in the same folder it came from. Deleting a
  /// gallery asset removes its content URI for good, so restoring can't
  /// reuse it the way [restoreToUri] does for file-explorer picks — this
  /// inserts a new row with the same relative path/name/mime type instead.
  Future<bool> recreateInMediaStore({
    required String relativePath,
    required String displayName,
    required String mimeType,
    required String sourcePath,
    DateTime? modifiedAt,
    DateTime? createdAt,
    DateTime? accessedAt,
  }) async {
    try {
      final result = await _mediaStoreChannel
          .invokeMethod<bool>('recreateInMediaStore', {
            'relativePath': relativePath,
            'displayName': displayName,
            'mimeType': mimeType,
            'sourcePath': sourcePath,
            'modifiedAtEpochMs': modifiedAt?.millisecondsSinceEpoch,
            'createdAtEpochMs': createdAt?.millisecondsSinceEpoch,
            'accessedAtEpochMs': accessedAt?.millisecondsSinceEpoch,
          });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Extracts a JPEG preview frame from a video file, for the vault's own
  /// library grid (`photo_manager`'s thumbnails only cover its picker screen
  /// — nothing else in the app touches that package). Returns null if the
  /// video can't be decoded.
  Future<Uint8List?> generateVideoThumbnail(String sourcePath) async {
    try {
      return await _mediaStoreChannel.invokeMethod<Uint8List>(
        'generateVideoThumbnail',
        {'sourcePath': sourcePath},
      );
    } on PlatformException {
      return null;
    }
  }

  /// Checks whether the app already holds a persisted folder-tree grant
  /// covering [documentUri] — granted at some point, by this app or through
  /// Android's own document-tree UI, this session or an earlier one
  /// (Android remembers these across restarts). Returns null if no granted
  /// tree covers it; otherwise the covering tree's URI and the document's
  /// folder path relative to that tree.
  Future<TreeCoverage?> findCoveringTree(String documentUri) async {
    try {
      final result = await _mediaStoreChannel.invokeMapMethod<String, String>(
        'findCoveringTree',
        {'uri': documentUri},
      );
      if (result == null) return null;
      return TreeCoverage(
        treeUri: result['treeUri']!,
        relativeFolderPath: result['relativeFolderPath']!,
      );
    } on PlatformException {
      return null;
    }
  }

  /// Creates [displayName] under [relativeFolderPath] inside the granted
  /// [treeUri] (creating that subfolder if needed) and writes the bytes at
  /// [sourcePath] into it. Used to restore an explorer-imported file whose
  /// original document was deleted, into the exact folder it came from.
  Future<bool> recreateInDocumentTree({
    required String treeUri,
    required String relativeFolderPath,
    required String displayName,
    required String mimeType,
    required String sourcePath,
    DateTime? modifiedAt,
    DateTime? createdAt,
    DateTime? accessedAt,
  }) async {
    try {
      final result = await _mediaStoreChannel
          .invokeMethod<bool>('recreateInDocumentTree', {
            'treeUri': treeUri,
            'relativeFolderPath': relativeFolderPath,
            'displayName': displayName,
            'mimeType': mimeType,
            'sourcePath': sourcePath,
            'modifiedAtEpochMs': modifiedAt?.millisecondsSinceEpoch,
            'createdAtEpochMs': createdAt?.millisecondsSinceEpoch,
            'accessedAtEpochMs': accessedAt?.millisecondsSinceEpoch,
          });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}

/// A persisted SAF folder-tree grant that covers a given document, and where
/// that document sits relative to the tree's root.
class TreeCoverage {
  final String treeUri;
  final String relativeFolderPath;

  const TreeCoverage({required this.treeUri, required this.relativeFolderPath});
}
