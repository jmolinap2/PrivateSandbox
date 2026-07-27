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

  /// Scratch space for files decrypted only to be handed to the system share
  /// sheet ("compartición controlada"). Must stay under `vault_share/` in the
  /// cache dir so the native FileProvider (provider_paths.xml) can expose it.
  /// We can't delete a shared file the instant `shareFile` returns — the
  /// receiving app reads it asynchronously afterwards — so it's wiped on the
  /// next app start instead, same as the playback temp dir.
  static Future<Directory> tempShareDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'vault_share'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> clearTempShareDir() async {
    final dir = await tempShareDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }
}
