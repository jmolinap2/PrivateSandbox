import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/import/picked_file.dart';
import '../../../application/providers.dart';

/// For an explorer-sourced [file] whose original will be deleted, silently
/// reuses any folder-tree permission the app already holds for this file's
/// folder (granted at some earlier point — by this app or through Android's
/// own document-tree UI) so restore can later recreate the file in that
/// exact folder.
///
/// Never asks for a new grant: restoring already has a fully working
/// fallback (letting the user choose a destination folder at that point),
/// so interrupting import — once per file, with a whole-screen system folder
/// picker — to maybe improve on that later isn't worth it. This also means a
/// batch import of many files from the same folder never asks anything here,
/// no matter how many files there are.
///
/// Gallery-sourced files (no [PickedFile.contentUri]) are returned
/// unchanged: they use MediaStore's own relative-path mechanism instead.
Future<PickedFile> resolveFolderAccessIfNeeded(WidgetRef ref, PickedFile file) async {
  final contentUri = file.contentUri;
  if (contentUri == null || contentUri.isEmpty) return file;

  final coverage = await ref.read(originalLocationChannelProvider).findCoveringTree(contentUri);
  if (coverage == null) return file;

  return file.withTreeGrant(treeUri: coverage.treeUri, relativeFolderPath: coverage.relativeFolderPath);
}
