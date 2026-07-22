import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the private, app-scoped directories used to store ciphertext
/// blobs and transient decrypted files for playback. Nothing here is ever
/// written to public/shared storage.
class VaultPaths {
  const VaultPaths._();

  static Future<Directory> vaultBlobsDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'vault_blobs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Scratch space for files decrypted only long enough to be played or
  /// viewed. Cleared on every app start in addition to being cleaned up
  /// right after each viewer closes.
  static Future<Directory> tempPlaybackDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'vault_playback'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> clearTempPlaybackDir() async {
    final dir = await tempPlaybackDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }
}
