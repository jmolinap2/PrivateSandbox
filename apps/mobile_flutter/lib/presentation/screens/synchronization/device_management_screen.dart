import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/providers.dart';
import '../../../application/synchronization/background_sync_scheduler.dart';
import '../../../application/synchronization/device_enrollment_service.dart';
import '../../../domain/synchronization/device_identity.dart';
import '../../../domain/synchronization/sync_protocol.dart';
import '../../../infrastructure/synchronization/device_enrollment_package.dart';
import '../../../infrastructure/synchronization/device_key_grant.dart';

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends ConsumerState<DeviceManagementScreen> {
  DeviceAdministrationSnapshot? _snapshot;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  DeviceEnrollmentService get _service =>
      ref.read(deviceEnrollmentServiceProvider);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await _service.loadAdministration();
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<T?> _whileBusy<T>(Future<T> Function() operation) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      return await operation();
    } catch (error) {
      if (mounted) _showError(_friendlyError(error));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportPairingRequest() async {
    final destinationPath = await FilePicker.getDirectoryPath();
    if (destinationPath == null || !mounted) return;
    final output = await _whileBusy(
      () => _service.exportPairingRequest(Directory(destinationPath)),
    );
    if (output != null && mounted) {
      _showMessage(
        'Solicitud creada. Llévala al dispositivo propietario:\n'
        '${output.path}',
      );
    }
  }

  Future<void> _authorizeRequest() async {
    final picked = await FilePicker.pickFiles(type: FileType.any);
    final sourcePath = picked?.files.single.path;
    if (sourcePath == null || !mounted) return;

    final request = await _whileBusy(
      () => _service.readPairingRequest(File(sourcePath)),
    );
    if (request == null || !mounted) return;
    final confirmed = await _confirmNewDevice(request);
    if (!confirmed || !mounted) return;

    // Pick the output before publishing the authorization. Cancelling this
    // chooser therefore never leaves a remotely-authorized device without
    // its key grant.
    final destinationPath = await FilePicker.getDirectoryPath();
    if (destinationPath == null || !mounted) return;
    final output = await _whileBusy(() async {
      final grant = await _service.authorizeAndCreateGrant(request);
      return _service.exportGrant(grant, Directory(destinationPath));
    });
    if (output == null || !mounted) return;
    await _refresh();
    if (!mounted) return;
    _showMessage(
      '${request.identity.displayName} quedó autorizado.\n\n'
      'Entrega este archivo sólo a ese dispositivo; caduca pronto:\n'
      '${output.path}',
    );
  }

  Future<void> _importGrant() async {
    final picked = await FilePicker.pickFiles(type: FileType.any);
    final sourcePath = picked?.files.single.path;
    if (sourcePath == null || !mounted) return;
    final grant = await _whileBusy(() => _service.readGrant(File(sourcePath)));
    if (grant == null || !mounted) return;
    if (!await _confirmGrant(grant) || !mounted) return;

    final result = await _whileBusy(
      () => _service.importGrantAndSynchronize(grant),
    );
    if (result == null || !mounted) return;
    await _refresh();
    if (!mounted) return;
    _showMessage(
      'Dispositivo enlazado y sincronizado. '
      '${result.downloadedVersions} versión(es) descargada(s).',
    );
  }

  Future<void> _revoke(DeviceRegistration registration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revocar ${registration.identity.displayName}'),
        content: const Text(
          'Ese dispositivo perderá acceso en el próximo contacto con el '
          'servidor. Sus copias locales no se borran automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revocar acceso'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final completed = await _whileBusy(() async {
      await _service.revokeDevice(registration.identity.deviceId);
      return true;
    });
    if (completed == true && mounted) await _refresh();
  }

  Future<void> _issueDirective(
    DeviceRegistration registration,
    RemoteDirectiveType type,
  ) async {
    if (!await _confirmIssuedDirective(registration, type) || !mounted) return;
    final directive = await _whileBusy(
      () => _service.issueDirective(
        type: type,
        targetDeviceId: registration.identity.deviceId,
      ),
    );
    if (directive == null || !mounted) return;
    await _refresh();
    if (mounted) {
      _showMessage(
        'Orden ${_directiveLabel(type).toLowerCase()} publicada. '
        'El dispositivo deberá recibirla y acusarla.',
      );
    }
  }

  Future<void> _handlePendingDirective(RemoteDeviceDirective directive) async {
    switch (directive.type) {
      case RemoteDirectiveType.lock:
        final confirmed = await _confirmReceivedDirective(
          title: 'Solicitud de bloqueo',
          body:
              'Un propietario solicitó bloquear esta aplicación. Al '
              'confirmar se enviará el acuse y se bloqueará ahora.',
          confirmLabel: 'Acusar y bloquear',
        );
        if (!confirmed || !mounted) return;
        final acknowledged = await _whileBusy(
          () => _service.acknowledgeDirective(directive.directiveId),
        );
        if (acknowledged == true && mounted) {
          ref.read(authControllerProvider.notifier).lock();
        }
        return;
      case RemoteDirectiveType.logout:
        final confirmed = await _confirmReceivedDirective(
          title: 'Solicitud de cierre remoto',
          body:
              'Al confirmar se enviará el acuse, se eliminarán de este '
              'dispositivo la identidad y las credenciales de sincronización, '
              'y la app se bloqueará. Los archivos cifrados locales se '
              'conservan.',
          confirmLabel: 'Desconectar y bloquear',
          destructive: true,
        );
        if (!confirmed || !mounted) return;
        final acknowledged = await _whileBusy(
          () => _service.acknowledgeDirective(directive.directiveId),
        );
        if (acknowledged == true && mounted) {
          await _service.logoutSynchronizationIdentity();
          await BackgroundSyncScheduler.configure(enabled: false);
          if (mounted) ref.read(authControllerProvider.notifier).lock();
        }
        return;
      case RemoteDirectiveType.wipeLocalData:
        final confirmed = await _confirmReceivedDirective(
          title: 'Solicitud de borrado remoto',
          body:
              'Un propietario solicitó borrar los datos locales. Por '
              'seguridad, Private Sandbox nunca ejecuta ese borrado '
              'automáticamente. Confirmar sólo marca la solicitud como '
              'recibida; ningún archivo será eliminado.',
          confirmLabel: 'Acusar sin borrar',
          destructive: true,
        );
        if (!confirmed || !mounted) return;
        final acknowledged = await _whileBusy(
          () => _service.acknowledgeDirective(directive.directiveId),
        );
        if (acknowledged == true && mounted) await _refresh();
        return;
    }
  }

  Future<bool> _confirmNewDevice(DevicePairingRequest request) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Autorizar nuevo dispositivo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.identity.displayName),
                const SizedBox(height: 8),
                const Text('Huella pública:'),
                SelectableText(_formatId(request.identity.deviceId)),
                const SizedBox(height: 12),
                const Text(
                  'Compara esta huella en ambos dispositivos antes de '
                  'continuar. La autorización concede acceso a la bóveda.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Autorizar y crear concesión'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmGrant(DeviceKeyGrant grant) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Importar concesión de dispositivo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Propietario: ${grant.sender.displayName}'),
                Text('Caduca: ${grant.expiresAt.toLocal()}'),
                const SizedBox(height: 12),
                const Text(
                  'La firma, el destinatario y el checkpoint se verificarán '
                  'antes de instalar la clave. No continúes si no solicitaste '
                  'este enlace.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Verificar, enlazar y sincronizar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmIssuedDirective(
    DeviceRegistration registration,
    RemoteDirectiveType type,
  ) async {
    if (type == RemoteDirectiveType.wipeLocalData) {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Solicitar borrado local'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Se enviará a ${registration.identity.displayName} una '
                  'solicitud de borrado. El dispositivo remoto exigirá una '
                  'confirmación local y no borrará datos automáticamente.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Escribe BORRAR para confirmar',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: controller.text.trim() == 'BORRAR'
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('Publicar solicitud'),
              ),
            ],
          ),
        ),
      );
      controller.dispose();
      return result == true;
    }

    final isLogout = type == RemoteDirectiveType.logout;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_directiveLabel(type)),
            content: Text(
              isLogout
                  ? 'Se solicitará a ${registration.identity.displayName} '
                        'desconectarse de la sincronización. Sus archivos '
                        'locales se conservarán.'
                  : 'Se solicitará a ${registration.identity.displayName} '
                        'bloquear la aplicación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Publicar orden'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmReceivedDirective({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null) _buildConfigurationError(),
                  if (_snapshot == null) ...[
                    const SizedBox(height: 12),
                    _buildEnrollmentCard(canAdminister: false),
                  ],
                  if (_snapshot != null) ...[
                    ..._buildPendingDirectives(_snapshot!),
                    _buildEnrollmentCard(
                      canAdminister: _snapshot!.canAdminister,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Registro autorizado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final registration in _snapshot!.registrations)
                      _buildDeviceCard(_snapshot!, registration),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildConfigurationError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'En un dispositivo nuevo, guarda el servidor y las '
              'credenciales sin sincronizar; luego crea la solicitud aquí.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPendingDirectives(DeviceAdministrationSnapshot snapshot) {
    final pending = snapshot.pendingForCurrentDevice;
    if (pending.isEmpty) return const <Widget>[];
    return <Widget>[
      Text('Órdenes recibidas', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final directive in pending)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(_directiveIcon(directive.type)),
            title: Text(_directiveLabel(directive.type)),
            subtitle: Text(
              'Emitida ${directive.issuedAt.toLocal()}. '
              'Requiere confirmación en este dispositivo.',
            ),
            trailing: FilledButton(
              onPressed: _busy
                  ? null
                  : () => _handlePendingDirective(directive),
              child: const Text('Revisar'),
            ),
          ),
        ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildEnrollmentCard({required bool canAdminister}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enlazar otro dispositivo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. El nuevo dispositivo exporta una solicitud .psdr.\n'
              '2. Un propietario la autoriza y entrega una concesión .psdg.\n'
              '3. El nuevo dispositivo importa la concesión y sincroniza.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportPairingRequest,
              icon: const Icon(Icons.outbox_outlined),
              label: const Text('Exportar solicitud de este dispositivo'),
            ),
            if (canAdminister)
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _authorizeRequest,
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Autorizar solicitud y crear .psdg'),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importGrant,
              icon: const Icon(Icons.move_to_inbox_outlined),
              label: const Text('Importar concesión .psdg'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    DeviceAdministrationSnapshot snapshot,
    DeviceRegistration registration,
  ) {
    final isCurrent =
        registration.identity.deviceId == snapshot.currentDeviceId;
    final issued = snapshot.manifest.directives.values
        .where(
          (directive) =>
              directive.targetDeviceId == registration.identity.deviceId,
        )
        .toList();
    final pendingCount = issued
        .where(
          (directive) => !directive.acknowledgedByDeviceIds.contains(
            registration.identity.deviceId,
          ),
        )
        .length;
    return Card(
      child: ListTile(
        leading: Icon(
          registration.isAuthorized
              ? Icons.devices_outlined
              : Icons.phonelink_erase_outlined,
        ),
        title: Text(
          '${registration.identity.displayName}${isCurrent ? ' (este)' : ''}',
        ),
        subtitle: Text(
          '${registration.role == DeviceRole.owner ? 'Propietario' : 'Miembro'}'
          ' · ${registration.isAuthorized ? 'Autorizado' : 'Revocado'}\n'
          '${_formatId(registration.identity.deviceId)}'
          '${issued.isEmpty ? '' : '\nÓrdenes: ${issued.length}; pendientes: $pendingCount'}',
        ),
        isThreeLine: true,
        trailing:
            snapshot.canAdminister && !isCurrent && registration.isAuthorized
            ? PopupMenuButton<String>(
                enabled: !_busy,
                onSelected: (action) {
                  switch (action) {
                    case 'lock':
                      _issueDirective(registration, RemoteDirectiveType.lock);
                      return;
                    case 'logout':
                      _issueDirective(registration, RemoteDirectiveType.logout);
                      return;
                    case 'wipe':
                      _issueDirective(
                        registration,
                        RemoteDirectiveType.wipeLocalData,
                      );
                      return;
                    case 'revoke':
                      _revoke(registration);
                      return;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'lock',
                    child: Text('Solicitar bloqueo'),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text('Solicitar desconexión'),
                  ),
                  PopupMenuItem(
                    value: 'wipe',
                    child: Text('Solicitar borrado local'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'revoke', child: Text('Revocar acceso')),
                ],
              )
            : null,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(message),
      ),
    );
  }

  void _showMessage(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is SyncException) return error.message;
    if (error is FormatException) {
      return error.message.toString();
    }
    return 'No se pudo completar la operación: $error';
  }

  static String _formatId(String id) {
    if (id.length <= 24) return id;
    return '${id.substring(0, 12)}…${id.substring(id.length - 12)}';
  }

  static String _directiveLabel(RemoteDirectiveType type) {
    return switch (type) {
      RemoteDirectiveType.lock => 'Bloquear aplicación',
      RemoteDirectiveType.logout => 'Desconectar sincronización',
      RemoteDirectiveType.wipeLocalData => 'Solicitar borrado local',
    };
  }

  static IconData _directiveIcon(RemoteDirectiveType type) {
    return switch (type) {
      RemoteDirectiveType.lock => Icons.lock_outline,
      RemoteDirectiveType.logout => Icons.logout,
      RemoteDirectiveType.wipeLocalData => Icons.delete_forever_outlined,
    };
  }
}
