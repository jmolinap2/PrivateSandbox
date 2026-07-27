import 'package:flutter/material.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';

import '../../application/companion_controller.dart';
import '../widgets/section_card.dart';

class CatalogPage extends StatelessWidget {
  final CompanionController controller;

  const CatalogPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final manifest = controller.remoteManifest;
    final progress = controller.transferProgress;
    return PageFrame(
      title: 'Catálogo remoto autenticado',
      subtitle:
          'Los nombres, metadatos e historial se descifran localmente. '
          'Las descargas bajo demanda conservan los blobs cifrados.',
      children: [
        SectionCard(
          title: 'Estado de la bóveda',
          subtitle: controller.hasMasterKey
              ? 'Vault ID ${controller.vaultId}'
              : 'Importa un grant firmado antes de acceder al catálogo.',
          trailing: FilledButton.icon(
            onPressed:
                controller.hasMasterKey &&
                    controller.configuration != null &&
                    !controller.busy
                ? controller.refreshCatalog
                : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
          child: manifest == null
              ? const _EmptyCatalog()
              : Wrap(
                  spacing: 28,
                  runSpacing: 18,
                  children: [
                    _Metric(
                      label: 'Generación',
                      value: manifest.generation.toString(),
                    ),
                    _Metric(
                      label: 'Objetos',
                      value: manifest.records.length.toString(),
                    ),
                    _Metric(
                      label: 'Dispositivos',
                      value: manifest.devices.length.toString(),
                    ),
                    _Metric(
                      label: 'Conflictos',
                      value: manifest.records.values
                          .where((record) => record.heads.length > 1)
                          .length
                          .toString(),
                    ),
                  ],
                ),
        ),
        if (progress != null)
          SectionCard(
            title: 'Descarga cifrada',
            subtitle:
                '${progress.completedChunks}/${progress.totalChunks} chunks '
                'verificados',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: progress.fraction),
                const SizedBox(height: 8),
                Text(
                  '${_formatBytes(progress.transferredBytes)} de '
                  '${_formatBytes(progress.totalBytes)}',
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        if (controller.lastDownloadedPath != null)
          SectionCard(
            title: 'Última descarga',
            subtitle:
                'Directorio privado de datos de la aplicación. El contenido '
                'sigue cifrado.',
            child: SelectableText(
              controller.lastDownloadedPath!,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        if (manifest != null)
          SectionCard(
            title: 'Objetos e historial',
            subtitle:
                'Cada versión conserva su vector causal, autor y descriptor '
                'de integridad SHA-256.',
            child: controller.catalog.isEmpty
                ? const Text('La bóveda remota no contiene objetos.')
                : Column(
                    children: [
                      for (final record in controller.catalog)
                        _RecordTile(
                          record: record,
                          busy: controller.busy,
                          onDownload: controller.downloadEncryptedBlob,
                        ),
                    ],
                  ),
          ),
        if (manifest != null)
          SectionCard(
            title: 'Registro de dispositivos',
            subtitle:
                'Este registro fue descifrado y su manifiesto fue autenticado.',
            child: Column(
              children: [
                for (final registration
                    in (manifest.devices.values.toList()..sort(
                      (left, right) => left.identity.displayName.compareTo(
                        right.identity.displayName,
                      ),
                    )))
                  _DeviceTile(registration: registration),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_sync_outlined, size: 36),
          SizedBox(width: 18),
          Expanded(
            child: Text(
              'Configura WebDAV, crea la identidad e importa el grant. '
              'Después podrás autenticar el manifiesto remoto.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final SyncObjectRecord record;
  final bool busy;
  final Future<bool> Function(SyncBlobDescriptor descriptor) onDownload;

  const _RecordTile({
    required this.record,
    required this.busy,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final versions = record.versions.values.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final heads = record.heads;
    final name = _displayName(heads.isEmpty ? versions : heads);
    final conflict = heads.length > 1;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          conflict ? Icons.call_split : Icons.insert_drive_file_outlined,
          color: conflict ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text(name),
        subtitle: Text(
          '${versions.length} ${versions.length == 1 ? 'versión' : 'versiones'}'
          '${conflict ? ' · conflicto concurrente' : ''}',
        ),
        trailing: conflict
            ? Tooltip(
                message: 'Hay varias versiones cabeza concurrentes.',
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            : null,
        children: [
          for (final version in versions)
            _VersionTile(
              version: version,
              isHead: heads.any((head) => head.versionId == version.versionId),
              busy: busy,
              onDownload: onDownload,
            ),
        ],
      ),
    );
  }

  String _displayName(List<SyncObjectVersion> versions) {
    for (final version in versions) {
      for (final key in const ['originalName', 'name', 'displayName']) {
        final value = version.privateMetadata[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return 'Objeto ${_short(record.logicalId)}';
  }
}

class _VersionTile extends StatelessWidget {
  final SyncObjectVersion version;
  final bool isHead;
  final bool busy;
  final Future<bool> Function(SyncBlobDescriptor descriptor) onDownload;

  const _VersionTile({
    required this.version,
    required this.isHead,
    required this.busy,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final blob = version.blob;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      leading: Icon(version.isTombstone ? Icons.delete_outline : Icons.history),
      title: Row(
        children: [
          Flexible(
            child: Text(
              version.isTombstone
                  ? 'Eliminación'
                  : '${_formatDate(version.createdAt)} · '
                        '${blob == null ? 'sin blob' : _formatBytes(blob.size)}',
            ),
          ),
          if (isHead) ...[
            const SizedBox(width: 8),
            const Chip(
              visualDensity: VisualDensity.compact,
              label: Text('actual'),
            ),
          ],
        ],
      ),
      subtitle: SelectableText(
        'Autor ${_short(version.authorDeviceId)} · '
        'Versión ${_short(version.versionId)}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
      trailing: blob == null
          ? null
          : OutlinedButton.icon(
              onPressed: busy ? null : () => onDownload(blob),
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text('Descargar cifrado'),
            ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceRegistration registration;

  const _DeviceTile({required this.registration});

  @override
  Widget build(BuildContext context) {
    final authorized = registration.isAuthorized;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        registration.role == DeviceRole.owner
            ? Icons.admin_panel_settings_outlined
            : Icons.devices_other,
        color: authorized ? null : Theme.of(context).colorScheme.error,
      ),
      title: Text(registration.identity.displayName),
      subtitle: SelectableText(
        registration.identity.deviceId,
        maxLines: 1,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
      trailing: Chip(
        avatar: Icon(
          authorized ? Icons.check_circle_outline : Icons.block,
          size: 16,
        ),
        label: Text(
          authorized
              ? registration.role == DeviceRole.owner
                    ? 'propietario'
                    : 'autorizado'
              : 'revocado',
        ),
      ),
    );
  }
}

String _short(String value) {
  return value.length <= 12 ? value : '${value.substring(0, 12)}…';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
}
