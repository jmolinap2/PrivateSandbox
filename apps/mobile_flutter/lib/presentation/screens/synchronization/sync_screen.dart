import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../application/synchronization/background_sync_scheduler.dart';
import '../../../application/synchronization/sync_controller.dart';
import '../../../application/synchronization/synchronization_engine.dart';
import '../../../domain/entities/vault_file.dart';
import '../../../domain/synchronization/sync_configuration.dart';
import '../../../domain/synchronization/sync_selection.dart';
import '../../../infrastructure/synchronization/resumable_blob_transfer.dart';
import 'device_management_screen.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _formKey = GlobalKey<FormState>();
  final _endpoint = TextEditingController();
  final _username = TextEditingController();
  final _secret = TextEditingController();
  final _deviceName = TextEditingController(text: 'Mi dispositivo');
  final _publicShareBase = TextEditingController();

  bool _loading = true;
  bool _synchronized = false;
  bool _background = true;
  SyncAuthenticationKind _authentication = SyncAuthenticationKind.basic;
  RemoteDownloadMode _downloadMode = RemoteDownloadMode.onDemand;
  int? _bandwidthLimit;
  Set<String> _excludedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _username.dispose();
    _secret.dispose();
    _deviceName.dispose();
    _publicShareBase.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final configuration = await ref
          .read(syncConfigurationStoreProvider)
          .load();
      if (configuration != null) {
        _endpoint.text = configuration.endpoint.toString();
        _username.text = configuration.username;
        _secret.text = configuration.secret;
        _deviceName.text = configuration.deviceDisplayName;
        _publicShareBase.text =
            configuration.publicShareBaseUri?.toString() ?? '';
        _synchronized = configuration.policy.mode == VaultSyncMode.synchronized;
        _background = configuration.backgroundSyncEnabled;
        _authentication = configuration.authenticationKind;
        _downloadMode = configuration.policy.downloadMode;
        _bandwidthLimit = configuration.policy.bandwidthLimitBytesPerSecond;
        _excludedIds = {...configuration.policy.excludedLogicalIds};
      }
    } catch (error) {
      if (mounted) _showError('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({bool synchronizeNow = false}) async {
    if (!_synchronized) {
      await ref.read(syncConfigurationStoreProvider).clear();
      await BackgroundSyncScheduler.configure(enabled: false);
      ref.read(syncControllerProvider.notifier).resetStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modo solo local activado.')),
        );
      }
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final configuration = SyncConfiguration(
        endpoint: Uri.parse(_endpoint.text.trim()),
        authenticationKind: _authentication,
        username: _username.text.trim(),
        secret: _secret.text,
        deviceDisplayName: _deviceName.text.trim(),
        publicShareBaseUri: _publicShareBase.text.trim().isEmpty
            ? null
            : Uri.parse(_publicShareBase.text.trim()),
        backgroundSyncEnabled: _background,
        policy: SelectiveSyncPolicy(
          mode: VaultSyncMode.synchronized,
          downloadMode: _downloadMode,
          excludedLogicalIds: _excludedIds,
          bandwidthLimitBytesPerSecond: _bandwidthLimit,
        ),
      );
      await ref.read(syncConfigurationStoreProvider).save(configuration);
      await BackgroundSyncScheduler.configure(enabled: _background);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada en almacenamiento seguro.'),
        ),
      );
      if (synchronizeNow) {
        await ref.read(syncControllerProvider.notifier).synchronize();
      }
    } catch (error) {
      if (mounted) _showError('$error');
    }
  }

  Future<void> _pickExcludedFiles() async {
    final files =
        ref.read(vaultFilesStreamProvider).value ?? const <VaultFile>[];
    final working = {..._excludedIds};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sincronización selectiva'),
          content: SizedBox(
            width: double.maxFinite,
            child: files.isEmpty
                ? const Text('No hay archivos locales para seleccionar.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final enabled = !working.contains(file.id);
                      return CheckboxListTile(
                        value: enabled,
                        title: Text(
                          file.originalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          enabled
                              ? 'Se sincroniza'
                              : 'Sólo en este dispositivo',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value ?? false) {
                              working.remove(file.id);
                            } else {
                              working.add(file.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(working),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _excludedIds = result);
  }

  Future<void> _openDeviceManagement() async {
    if (_synchronized) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      // A receiver must be able to persist WebDAV credentials before it has
      // the owner's master-key grant, without attempting a sync under the
      // installation's temporary local key.
      await _save(synchronizeNow: false);
    }
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DeviceManagementScreen()));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(syncControllerProvider);
    final running = runState.phase == SyncRunPhase.running;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sincronización cifrada')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización cifrada')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.phonelink_lock_outlined),
                  label: Text('Sólo local'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.cloud_sync_outlined),
                  label: Text('Sincronizado'),
                ),
              ],
              selected: {_synchronized},
              onSelectionChanged: running
                  ? null
                  : (selection) =>
                        setState(() => _synchronized = selection.single),
            ),
            const SizedBox(height: 12),
            const Text(
              'Los archivos, nombres y catálogo salen del dispositivo '
              'únicamente cifrados. El servidor nunca recibe la clave maestra.',
            ),
            if (_synchronized) ...[
              const SizedBox(height: 20),
              TextFormField(
                controller: _endpoint,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Servidor WebDAV o compatible',
                  hintText: 'https://nube.ejemplo.com/dav/boveda/',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: (value) {
                  final uri = Uri.tryParse(value?.trim() ?? '');
                  if (uri == null ||
                      uri.scheme != 'https' ||
                      uri.host.isEmpty) {
                    return 'Usa una dirección HTTPS válida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deviceName,
                decoration: const InputDecoration(
                  labelText: 'Nombre de este dispositivo',
                  prefixIcon: Icon(Icons.devices_outlined),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Escribe un nombre.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _publicShareBase,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Base pública para enlaces (opcional)',
                  hintText: 'https://compartir.ejemplo.com/private-sandbox/',
                  helperText:
                      'Debe servir de forma anónima los paquetes cifrados.',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null ||
                      uri.scheme != 'https' ||
                      uri.host.isEmpty) {
                    return 'Usa una dirección HTTPS válida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SyncAuthenticationKind>(
                initialValue: _authentication,
                decoration: const InputDecoration(
                  labelText: 'Autenticación remota',
                ),
                items: const [
                  DropdownMenuItem(
                    value: SyncAuthenticationKind.none,
                    child: Text('Sin autenticación'),
                  ),
                  DropdownMenuItem(
                    value: SyncAuthenticationKind.basic,
                    child: Text('Usuario y contraseña'),
                  ),
                  DropdownMenuItem(
                    value: SyncAuthenticationKind.bearer,
                    child: Text('Token Bearer'),
                  ),
                ],
                onChanged: running
                    ? null
                    : (value) => setState(() => _authentication = value!),
              ),
              if (_authentication == SyncAuthenticationKind.basic) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'El usuario es obligatorio.'
                      : null,
                ),
              ],
              if (_authentication != SyncAuthenticationKind.none) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secret,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: _authentication == SyncAuthenticationKind.basic
                        ? 'Contraseña'
                        : 'Token',
                  ),
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'Este valor es obligatorio.'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<RemoteDownloadMode>(
                initialValue: _downloadMode,
                decoration: const InputDecoration(
                  labelText: 'Descargas remotas',
                ),
                items: const [
                  DropdownMenuItem(
                    value: RemoteDownloadMode.onDemand,
                    child: Text('Bajo demanda'),
                  ),
                  DropdownMenuItem(
                    value: RemoteDownloadMode.eager,
                    child: Text('Descargar todo lo seleccionado'),
                  ),
                ],
                onChanged: running
                    ? null
                    : (value) => setState(() => _downloadMode = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _bandwidthLimit,
                decoration: const InputDecoration(
                  labelText: 'Límite de ancho de banda',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Sin límite')),
                  DropdownMenuItem(value: 1024 * 1024, child: Text('1 MiB/s')),
                  DropdownMenuItem(
                    value: 5 * 1024 * 1024,
                    child: Text('5 MiB/s'),
                  ),
                  DropdownMenuItem(
                    value: 10 * 1024 * 1024,
                    child: Text('10 MiB/s'),
                  ),
                ],
                onChanged: running
                    ? null
                    : (value) => setState(() => _bandwidthLimit = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _background,
                title: const Text('Carga y reintentos en segundo plano'),
                subtitle: const Text(
                  'El sistema programa trabajo sólo con conexión de red.',
                ),
                onChanged: running
                    ? null
                    : (value) => setState(() => _background = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.rule_folder_outlined),
                title: const Text('Archivos incluidos'),
                subtitle: Text(
                  _excludedIds.isEmpty
                      ? 'Todos los archivos locales'
                      : '${_excludedIds.length} archivo(s) quedan sólo locales',
                ),
                onTap: running ? null : _pickExcludedFiles,
              ),
            ],
            const SizedBox(height: 20),
            if (runState.progress != null) ...[
              LinearProgressIndicator(value: runState.progress!.fraction),
              const SizedBox(height: 8),
              Text(
                '${runState.progress!.direction == SyncTransferDirection.upload ? 'Subiendo' : 'Descargando'} '
                '${runState.progress!.completedChunks}/${runState.progress!.totalChunks} bloques',
              ),
            ],
            if (runState.phase == SyncRunPhase.failed)
              Text(
                runState.error ?? 'Error desconocido',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (runState.phase == SyncRunPhase.succeeded &&
                runState.result != null)
              _ResultCard(result: runState.result!),
            const SizedBox(height: 12),
            if (_synchronized) ...[
              OutlinedButton.icon(
                onPressed: running ? null : () => _save(synchronizeNow: false),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar sin sincronizar (para enlazar)'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_other_outlined),
                title: const Text('Dispositivos autorizados'),
                subtitle: const Text(
                  'Enlazar, revocar y revisar órdenes remotas',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: running ? null : _openDeviceManagement,
              ),
            ],
            FilledButton.icon(
              onPressed: running
                  ? () => ref.read(syncControllerProvider.notifier).cancel()
                  : () => _save(synchronizeNow: _synchronized),
              icon: Icon(running ? Icons.stop : Icons.sync),
              label: Text(
                running
                    ? 'Cancelar'
                    : (_synchronized
                          ? 'Guardar y sincronizar ahora'
                          : 'Activar modo sólo local'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SynchronizationResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.skippedBecauseLocalOnly) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.phonelink_lock_outlined),
          title: Text('La bóveda permanece sólo en este dispositivo.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sincronización completada',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Versiones subidas: ${result.uploadedVersions}'),
            Text('Versiones descargadas: ${result.downloadedVersions}'),
            Text('Conflictos conservados: ${result.preservedConflicts}'),
            Text(
              'Eliminaciones remotas a papelera: ${result.recordedTombstones}',
            ),
            if (result.pendingDirectives.isNotEmpty)
              Text(
                'Órdenes remotas pendientes: '
                '${result.pendingDirectives.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
