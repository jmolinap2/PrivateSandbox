import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_file.dart';
import '../../../domain/entities/vault_folder.dart';
import 'share_action.dart';

/// Fase 3's "conservación de metadatos internos" + "registro de metadatos
/// que Android no permita restaurar": a single place to see everything the
/// vault knows about a file, including origin info that's informational
/// only when Android's scoped storage rules mean it can't be acted on
/// (e.g. a document-provider folder we never got write access to).
class FileDetailsScreen extends ConsumerWidget {
  const FileDetailsScreen({required this.file, super.key});

  final VaultFile file;

  String _sizeLabel(int bytes) {
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _verifyIntegrity(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Expanded(child: Text('Verificando…')),
          ],
        ),
      ),
    );
    final ok = await ref.read(verifyIntegrityUseCaseProvider).call(file);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ok ? 'Integridad verificada' : 'Problema de integridad'),
        content: Text(
          ok
              ? 'El contenido cifrado coincide exactamente con el hash calculado al importar.'
              : 'El contenido descifrado ya no coincide con el hash original. El archivo podría estar dañado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM y, HH:mm', 'es');
    final tagsAsync = ref.watch(vaultTagsForFileStreamProvider(file.id));
    final collectionsAsync = ref.watch(vaultCollectionsForFileStreamProvider(file.id));
    final folderId = file.folderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del archivo'),
        actions: [ShareActionButton(file: file)],
      ),
      body: ListView(
        children: [
          _Section(title: 'Identidad'),
          _Row('Nombre', file.originalName),
          _Row('Tipo', file.mimeType),
          _Row('Extensión', file.extension.toUpperCase()),
          _Row('Tamaño', _sizeLabel(file.sizeBytes)),
          _Section(title: 'Fechas'),
          _Row('Importado', dateFormat.format(file.importedAt)),
          _Row(
            'Modificado (original)',
            file.fileModifiedAt == null ? 'Desconocido' : dateFormat.format(file.fileModifiedAt!),
          ),
          _Row(
            'Creado (original)',
            file.originalCreatedAt == null
                ? 'No disponible'
                : dateFormat.format(file.originalCreatedAt!),
          ),
          _Row(
            'Accedido (original)',
            file.originalAccessedAt == null
                ? 'No disponible'
                : dateFormat.format(file.originalAccessedAt!),
          ),
          _Section(title: 'Integridad'),
          _Row('SHA-256', file.sha256Hash, selectable: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _verifyIntegrity(context, ref),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verificar integridad ahora'),
            ),
          ),
          _Section(title: 'Origen'),
          _Row('Original eliminado del dispositivo', file.originalDeleted ? 'Sí' : 'No'),
          _OriginRow(file: file),
          if (file.originalMetadataJson != null)
            _Row(
              'Metadata conservada',
              file.originalMetadataJson!,
              selectable: true,
            ),
          if (folderId != null) _FolderRow(folderId: folderId),
          _Section(title: 'Etiquetas'),
          tagsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
            error: (error, stack) => _Row('Error', '$error'),
            data: (tags) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: tags.isEmpty
                  ? const Text('Sin etiquetas')
                  : Wrap(
                      spacing: 8,
                      children: [for (final tag in tags) Chip(label: Text(tag.name))],
                    ),
            ),
          ),
          _Section(title: 'Colecciones'),
          collectionsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
            error: (error, stack) => _Row('Error', '$error'),
            data: (collections) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: collections.isEmpty
                  ? const Text('Sin colecciones')
                  : Wrap(
                      spacing: 8,
                      children: [for (final collection in collections) Chip(label: Text(collection.name))],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OriginRow extends StatelessWidget {
  const _OriginRow({required this.file});

  final VaultFile file;

  @override
  Widget build(BuildContext context) {
    if (file.originalRelativePath != null) {
      return _Row('Carpeta original', file.originalRelativePath!);
    }
    if (file.originalTreeUri != null) {
      return const _Row('Ubicación original', 'Disponible para restaurar (carpeta con acceso concedido)');
    }
    if (file.originalContentUri != null) {
      return const _Row('Ubicación original', 'Disponible para restaurar (explorador de archivos)');
    }
    return const _Row(
      'Ubicación original',
      'No registrada — Android no permite recuperarla automáticamente para este archivo',
    );
  }
}

class _FolderRow extends ConsumerWidget {
  const _FolderRow({required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<VaultFolder?>(
      future: ref.read(vaultFolderRepositoryProvider).getById(folderId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '…';
        return _Row('Carpeta', name);
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.selectable = false});

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: selectable ? SelectableText(value) : Text(value),
          ),
        ],
      ),
    );
  }
}
