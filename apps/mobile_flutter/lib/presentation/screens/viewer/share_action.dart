import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';

/// Fase 3's "compartición controlada": decrypts [file] to a private temp file
/// and opens the system share sheet for it. Shared by every viewer's app-bar
/// action and the file-details screen.
Future<void> shareVaultFile(BuildContext context, WidgetRef ref, VaultFile file) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 24),
          Expanded(child: Text('Preparando para compartir…')),
        ],
      ),
    ),
  );

  bool shared;
  try {
    shared = await ref.read(shareUseCaseProvider).call(file);
  } catch (_) {
    shared = false;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();
  if (!shared) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo compartir el archivo.')),
    );
  }
}

/// App-bar share button reused across the viewers that have an app bar.
class ShareActionButton extends ConsumerWidget {
  const ShareActionButton({required this.file, super.key});

  final VaultFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.share_outlined),
      tooltip: 'Compartir',
      onPressed: () => shareVaultFile(context, ref, file),
    );
  }
}
