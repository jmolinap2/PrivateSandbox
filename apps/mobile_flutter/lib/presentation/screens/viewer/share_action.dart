import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../application/providers.dart';
import '../../../application/sharing/sharing_providers.dart';
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

Future<Duration?> _pickLifetime(BuildContext context) {
  return showModalBottomSheet<Duration>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Vigencia del contenido compartido'),
          ),
          for (final option in const <(String, Duration)>[
            ('1 hora', Duration(hours: 1)),
            ('1 día', Duration(days: 1)),
            ('7 días', Duration(days: 7)),
            ('30 días', Duration(days: 30)),
          ])
            ListTile(
              title: Text(option.$1),
              onTap: () => Navigator.of(context).pop(option.$2),
            ),
        ],
      ),
    ),
  );
}

Future<void> exportEncryptedSharePackage(
  BuildContext context,
  WidgetRef ref,
  VaultFile file,
) async {
  final lifetime = await _pickLifetime(context);
  if (lifetime == null || !context.mounted) return;
  final destination = await FilePicker.getDirectoryPath();
  if (destination == null || !context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 24),
          Expanded(child: Text('Creando paquete cifrado…')),
        ],
      ),
    ),
  );
  try {
    final result = await ref
        .read(exportEncryptedSharePackageUseCaseProvider)
        .exportPackage(
          file: file,
          destinationDirectory: Directory(destination),
          lifetime: lifetime,
        );
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paquete cifrado creado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.packageFile.path),
            const SizedBox(height: 12),
            const Text(
              'Envía esta clave por un canal separado:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(result.capabilityKey),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.capabilityKey),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar clave'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo crear el paquete: $error')),
    );
  }
}

Future<void> createProtectedShareLink(
  BuildContext context,
  WidgetRef ref,
  VaultFile file,
) async {
  final lifetime = await _pickLifetime(context);
  if (lifetime == null || !context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 24),
          Expanded(child: Text('Cifrando y subiendo…')),
        ],
      ),
    ),
  );
  try {
    final link = await ref
        .read(exportEncryptedSharePackageUseCaseProvider)
        .createProtectedLink(file: file, lifetime: lifetime);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enlace protegido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La clave está en el fragmento del enlace y no se envía al servidor.',
            ),
            const SizedBox(height: 12),
            SelectableText(link.toString()),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link.toString()));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo crear el enlace: $error')),
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
      onPressed: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Compartición controlada'),
                  subtitle: const Text(
                    'Entrega temporal a otra aplicación instalada.',
                  ),
                  onTap: () => Navigator.of(context).pop('direct'),
                ),
                ListTile(
                  leading: const Icon(Icons.enhanced_encryption_outlined),
                  title: const Text('Paquete cifrado'),
                  subtitle: const Text(
                    'Archivo portable con clave y expiración.',
                  ),
                  onTap: () => Navigator.of(context).pop('package'),
                ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Enlace protegido'),
                  subtitle: const Text(
                    'Sube sólo ciphertext; la clave queda en el fragmento.',
                  ),
                  onTap: () => Navigator.of(context).pop('link'),
                ),
              ],
            ),
          ),
        );
        if (!context.mounted) return;
        switch (action) {
          case 'direct':
            await shareVaultFile(context, ref, file);
          case 'package':
            await exportEncryptedSharePackage(context, ref, file);
          case 'link':
            await createProtectedShareLink(context, ref, file);
        }
      },
    );
  }
}
