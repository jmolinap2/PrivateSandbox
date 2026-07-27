import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'infrastructure/storage/vault_paths.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  // Any file left in the playback/share temp dirs from a previous run (e.g.
  // the process was killed while a viewer was open, or right after a share)
  // is stale and unencrypted; drop it before anything else runs.
  await VaultPaths.clearTempPlaybackDir();
  await VaultPaths.clearTempShareDir();
  runApp(const ProviderScope(child: VaultApp()));
}
