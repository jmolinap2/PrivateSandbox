import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/backup/import_vault_backup_use_case.dart';
import '../../../application/providers.dart';

/// Fase 3's "copias de seguridad cifradas locales" + "importación/
/// exportación de una bóveda completa" — bundles DB + every blob + a
/// password-wrapped copy of the master key into one portable `.psvb` file.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  Future<String?> _promptNewPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Contraseña de la copia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Esta contraseña protege el archivo de copia de seguridad — sin ella no se puede restaurar.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6 caracteres)'),
                ),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                ),
                if (error != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  if (passwordController.text.length < 6) {
                    setState(() => error = 'Mínimo 6 caracteres.');
                    return;
                  }
                  if (passwordController.text != confirmController.text) {
                    setState(() => error = 'Las contraseñas no coinciden.');
                    return;
                  }
                  Navigator.of(context).pop(passwordController.text);
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _promptExistingPassword(BuildContext context, {String? error}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contraseña de la copia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            if (error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Continuar')),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final password = await _promptNewPassword(context);
    if (password == null || !context.mounted) return;

    final destinationPath = await FilePicker.getDirectoryPath();
    if (destinationPath == null || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Expanded(child: Text('Creando copia de seguridad…')),
          ],
        ),
      ),
    );

    String message;
    try {
      final file = await ref.read(exportVaultBackupUseCaseProvider).call(
            password: password,
            destinationDir: Directory(destinationPath),
          );
      message = 'Copia de seguridad creada: ${file.path}';
    } catch (e) {
      message = 'No se pudo crear la copia de seguridad: $e';
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<bool> _confirmReplaceEverything(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar bóveda completa'),
        content: const Text(
          'Esto reemplazará TODO el contenido actual de la bóveda (archivos, carpetas, etiquetas, colecciones, '
          'actividad) con lo que haya en la copia de seguridad. No se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reemplazar todo'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    if (!await _confirmReplaceEverything(context)) return;
    if (!context.mounted) return;

    final picked = await FilePicker.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;
    final backupFile = File(path);

    String? passwordError;
    while (true) {
      if (!context.mounted) return;
      final password = await _promptExistingPassword(context, error: passwordError);
      if (password == null || !context.mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Expanded(child: Text('Restaurando…')),
            ],
          ),
        ),
      );

      ImportVaultBackupResult result;
      try {
        result = await ref.read(importVaultBackupUseCaseProvider).call(backupFile: backupFile, password: password);
      } catch (_) {
        result = ImportVaultBackupResult.invalidFile;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();

      switch (result) {
        case ImportVaultBackupResult.wrongPassword:
          passwordError = 'Contraseña incorrecta.';
          continue;
        case ImportVaultBackupResult.invalidFile:
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No se pudo restaurar'),
              content: const Text('El archivo no es una copia de seguridad válida o está dañado.'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
            ),
          );
          return;
        case ImportVaultBackupResult.success:
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Restauración completa'),
              content: const Text(
                'La bóveda se reemplazó correctamente. Cierra esta aplicación por completo (desde apps recientes) '
                'y vuelve a abrirla para continuar.',
              ),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
            ),
          );
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Exportar bóveda completa'),
            subtitle: const Text('Crea un archivo cifrado con todo el contenido de la bóveda.'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_outlined),
            title: const Text('Importar bóveda completa'),
            subtitle: const Text('Reemplaza todo el contenido actual con una copia de seguridad.'),
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }
}
