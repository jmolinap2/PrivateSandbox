import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/import/picked_file.dart';
import '../../../application/providers.dart';

/// For an explorer-sourced [file] whose original will be deleted, resolves
/// folder-tree access so restore can later recreate it in the same folder —
/// the same guarantee gallery-sourced imports already have via MediaStore's
/// relative path.
///
/// Gallery-sourced files (no [PickedFile.contentUri]) are returned
/// unchanged: they use MediaStore's own relative-path mechanism instead.
///
/// If a persisted grant already covers the file's folder (from a previous
/// import, this session or an earlier one), it's reused silently — no
/// prompt. Otherwise the user is asked once whether to grant access to that
/// folder; declining, or picking a folder that turns out not to contain the
/// file, leaves the file unchanged — restore will ask for a destination
/// folder instead, exactly as it did before this feature existed.
Future<PickedFile> resolveFolderAccessIfNeeded(
  BuildContext context,
  WidgetRef ref,
  PickedFile file,
) async {
  final contentUri = file.contentUri;
  if (contentUri == null || contentUri.isEmpty) return file;

  final channel = ref.read(originalLocationChannelProvider);
  final preferences = ref.read(importPreferencesProvider);

  final existing = await channel.findCoveringTree(contentUri);
  if (existing != null) {
    return file.withTreeGrant(treeUri: existing.treeUri, relativeFolderPath: existing.relativeFolderPath);
  }

  if (await preferences.getSkipFolderAccessPrompt()) return file;

  if (!context.mounted) return file;
  final choice = await showDialog<_FolderAccessChoice>(
    context: context,
    builder: (context) => _FolderAccessDialog(fileName: file.name),
  );
  if (choice == null) return file;
  if (choice.dontAskAgain) await preferences.setSkipFolderAccessPrompt(true);
  if (!choice.grant) return file;

  final treeUri = await channel.requestFolderAccess();
  if (treeUri == null) return file;

  final coverage = await channel.findCoveringTree(contentUri);
  if (coverage == null) return file;

  return file.withTreeGrant(treeUri: coverage.treeUri, relativeFolderPath: coverage.relativeFolderPath);
}

class _FolderAccessChoice {
  const _FolderAccessChoice({required this.grant, required this.dontAskAgain});

  final bool grant;
  final bool dontAskAgain;
}

class _FolderAccessDialog extends StatefulWidget {
  const _FolderAccessDialog({required this.fileName});

  final String fileName;

  @override
  State<_FolderAccessDialog> createState() => _FolderAccessDialogState();
}

class _FolderAccessDialogState extends State<_FolderAccessDialog> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acceso a carpeta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para poder restaurar "${widget.fileName}" en su carpeta exacta si más adelante lo eliminas de la '
            'bóveda, la app necesita acceso a esa carpeta. Puedes omitir esto: si lo haces, restaurar te pedirá '
            'elegir una carpeta de destino en su lugar.',
          ),
          CheckboxListTile(
            value: _dontAskAgain,
            onChanged: (value) => setState(() => _dontAskAgain = value ?? false),
            title: const Text('No volver a preguntar'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(_FolderAccessChoice(grant: false, dontAskAgain: _dontAskAgain)),
          child: const Text('Omitir'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(_FolderAccessChoice(grant: true, dontAskAgain: _dontAskAgain)),
          child: const Text('Conceder acceso'),
        ),
      ],
    );
  }
}
