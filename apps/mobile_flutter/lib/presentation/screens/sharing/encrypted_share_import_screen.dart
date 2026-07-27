import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/sharing/sharing_providers.dart';

class EncryptedShareImportScreen extends ConsumerWidget {
  const EncryptedShareImportScreen({super.key});

  Future<String?> _prompt(
    BuildContext context, {
    required String title,
    required String label,
    int minLines = 1,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 4,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importPackage(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pshare'],
    );
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;
    final key = await _prompt(
      context,
      title: 'Abrir paquete cifrado',
      label: 'Clave de compartición',
    );
    if (key == null || key.isEmpty || !context.mounted) return;
    await _run(
      context,
      () => ref.read(importEncryptedSharePackageUseCaseProvider).importPackage(
            package: File(path),
            capabilityKey: key,
          ),
    );
  }

  Future<void> _importLink(BuildContext context, WidgetRef ref) async {
    final value = await _prompt(
      context,
      title: 'Importar enlace protegido',
      label: 'Enlace completo',
      minLines: 2,
    );
    if (value == null || value.isEmpty || !context.mounted) return;
    final link = Uri.tryParse(value);
    if (link == null) {
      _message(context, 'El enlace no es válido.');
      return;
    }
    await _run(
      context,
      () => ref.read(importEncryptedSharePackageUseCaseProvider).importLink(link),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Expanded(
              child: Text('Verificando, descifrando e importando…'),
            ),
          ],
        ),
      ),
    );
    String message;
    try {
      await operation();
      message = 'El archivo se importó correctamente a la bóveda.';
    } catch (error) {
      message = 'No se pudo importar: $error';
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    _message(context, message);
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recibir contenido cifrado')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'El contenido se autentica antes de entrar en la bóveda. '
              'Un paquete alterado, vencido o con clave incorrecta no publica '
              'ningún archivo.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.enhanced_encryption_outlined),
            title: const Text('Importar paquete .pshare'),
            subtitle: const Text('Selecciona el archivo y escribe su clave.'),
            onTap: () => _importPackage(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.link_outlined),
            title: const Text('Abrir enlace protegido'),
            subtitle: const Text(
              'La clave viaja en el fragmento y no se envía al servidor.',
            ),
            onTap: () => _importLink(context, ref),
          ),
        ],
      ),
    );
  }
}
