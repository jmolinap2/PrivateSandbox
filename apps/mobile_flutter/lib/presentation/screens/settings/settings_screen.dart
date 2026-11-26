import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/auto_lock_timeout.dart';
import '../../../infrastructure/update/app_update_service.dart';
import '../../widgets/app_update_flow.dart';
import '../backup/backup_screen.dart';
import '../organization/organization_screen.dart';
import '../sharing/encrypted_share_import_screen.dart';
import '../storage/storage_screen.dart';
import '../synchronization/sync_screen.dart';
import '../trash/trash_screen.dart';
import 'change_pin_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  AutoLockTimeout _autoLockTimeout = AutoLockTimeout.immediate;
  bool _loading = true;
  bool _checkingForUpdate = false;
  int? _installedBuild;
  AvailableUpdate? _availableUpdate;
  String _updateStatus = 'Comprueba si hay una versión nueva.';

  @override
  void initState() {
    super.initState();
    _load();
    _loadInstalledBuild();
  }

  Future<void> _loadInstalledBuild() async {
    try {
      final build = await ref
          .read(appUpdateServiceProvider)
          .installedBuildNumber();
      if (mounted) setState(() => _installedBuild = build);
    } catch (_) {
      // The update check can still report its own error.
    }
  }

  Future<void> _load() async {
    final authRepo = ref.read(authRepositoryProvider);
    final available = await authRepo.isBiometricAvailable();
    final enabled = await authRepo.isBiometricEnabled();
    final autoLockTimeout = await authRepo.getAutoLockTimeout();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _autoLockTimeout = autoLockTimeout;
      _loading = false;
    });
  }

  Future<void> _checkForUpdate() async {
    if (_checkingForUpdate) return;
    setState(() {
      _checkingForUpdate = true;
      _availableUpdate = null;
      _updateStatus = 'Buscando actualizaciones...';
    });
    final service = ref.read(appUpdateServiceProvider);
    try {
      final update = await service.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _availableUpdate = update;
        _updateStatus = update == null
            ? 'Ya tienes la última versión publicada.'
            : 'Hay una versión nueva disponible: ${update.name} (compilación ${update.buildNumber}).';
      });
    } on AppUpdateException catch (e) {
      if (!mounted) return;
      setState(() => _updateStatus = 'No se pudo comprobar: ${e.message}');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _updateStatus = 'No se pudo comprobar si hay actualizaciones.',
      );
    } finally {
      if (mounted) setState(() => _checkingForUpdate = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    await ref.read(authRepositoryProvider).setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _pickAutoLockTimeout() async {
    final chosen = await showModalBottomSheet<AutoLockTimeout>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<AutoLockTimeout>(
          groupValue: _autoLockTimeout,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in AutoLockTimeout.values)
                RadioListTile<AutoLockTimeout>(
                  title: Text(option.label),
                  value: option,
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await ref.read(authRepositoryProvider).setAutoLockTimeout(chosen);
    setState(() => _autoLockTimeout = chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Desbloqueo biométrico'),
                  subtitle: Text(
                    _biometricAvailable
                        ? 'Usa tu huella o rostro además del PIN.'
                        : 'No disponible en este dispositivo.',
                  ),
                  value: _biometricEnabled,
                  onChanged: _biometricAvailable ? _toggleBiometric : null,
                ),
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Cambiar PIN'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePinScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Bloqueo automático'),
                  subtitle: Text(
                    'Al volver a la app tras: ${_autoLockTimeout.label}',
                  ),
                  onTap: _pickAutoLockTimeout,
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Bloquear ahora'),
                  onTap: () => ref.read(authControllerProvider.notifier).lock(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: const Text('Organización'),
                  subtitle: const Text(
                    'Etiquetas, colecciones y álbumes inteligentes',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrganizationScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Papelera'),
                  trailing: ref
                      .watch(vaultTrashedFilesStreamProvider)
                      .maybeWhen(
                        data: (files) => files.isEmpty
                            ? null
                            : CircleAvatar(
                                radius: 12,
                                child: Text(
                                  '${files.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                        orElse: () => null,
                      ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.pie_chart_outline),
                  title: const Text('Almacenamiento'),
                  subtitle: const Text(
                    'Espacio usado, duplicados, limpiar caché',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StorageScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Copia de seguridad'),
                  subtitle: const Text(
                    'Exportar o restaurar la bóveda completa',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Sincronización cifrada'),
                  subtitle: const Text(
                    'WebDAV, varios dispositivos y modo sólo local',
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const SyncScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_outlined),
                  title: const Text('Recibir contenido cifrado'),
                  subtitle: const Text(
                    'Importar un paquete o enlace temporal protegido',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EncryptedShareImportScreen(),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Actualizaciones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _installedBuild == null
                              ? 'Versión instalada no disponible'
                              : 'Compilación instalada: $_installedBuild',
                        ),
                        const SizedBox(height: 8),
                        Text(_updateStatus),
                        if (_availableUpdate case final update?) ...[
                          if (update.message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(update.message),
                          ],
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _checkingForUpdate
                                ? null
                                : () => downloadAndInstallUpdate(
                                    context,
                                    ref.read(appUpdateServiceProvider),
                                    update,
                                  ),
                            icon: const Icon(Icons.download),
                            label: const Text('Descargar e instalar'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _checkingForUpdate
                              ? null
                              : _checkForUpdate,
                          icon: _checkingForUpdate
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('Buscar actualizaciones'),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_outlined),
                  title: const Text('Restablecer preguntas de importación'),
                  subtitle: const Text(
                    'Vuelve a preguntar "Eliminar originales"',
                  ),
                  onTap: () async {
                    await ref.read(importPreferencesProvider).resetAll();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Preferencias de importación restablecidas.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
