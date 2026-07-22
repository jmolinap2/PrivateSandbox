import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'infrastructure/storage/vault_paths.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Any file left in the playback temp dir from a previous run (e.g. the
  // process was killed while a viewer was open) is stale and unencrypted;
  // drop it before anything else runs.
  await VaultPaths.clearTempPlaybackDir();
  runApp(const ProviderScope(child: VaultApp()));
}
