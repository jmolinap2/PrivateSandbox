import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/companion_controller.dart';
import '../widgets/section_card.dart';

class PairingPage extends StatefulWidget {
  final CompanionController controller;

  const PairingPage({super.key, required this.controller});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  final _deviceName = TextEditingController();
  final _ownerFingerprint = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deviceName.text = widget.controller.configuration?.deviceDisplayName ?? '';
  }

  @override
  void dispose() {
    _deviceName.dispose();
    _ownerFingerprint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.controller.identity;
    return PageFrame(
      title: 'Emparejamiento seguro',
      subtitle:
          'La identidad pública se entrega al móvil. El móvil devuelve un '
          'grant corto, cifrado para este equipo y firmado por el propietario.',
      children: [
        SectionCard(
          title: '1. Identidad de este equipo',
          subtitle:
              'Las claves privadas Ed25519 y X25519 permanecen en el almacén '
              'seguro de Windows.',
          child: identity == null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _deviceName,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del equipo',
                          hintText: 'PC de trabajo',
                          prefixIcon: Icon(Icons.computer),
                        ),
                        onSubmitted: (_) => _createIdentity(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: widget.controller.busy
                          ? null
                          : _createIdentity,
                      icon: const Icon(Icons.key),
                      label: const Text('Crear identidad'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            identity.displayName.characters.first.toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                identity.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Creada ${_formatDate(identity.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Huella del dispositivo'),
                    const SizedBox(height: 6),
                    SelectableText(
                      identity.deviceId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _exportPairingRequest,
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('Exportar DeviceIdentity'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: widget.controller
                                    .createPairingRequestJson(),
                              ),
                            );
                            if (mounted) {
                              _show('DeviceIdentity copiado al portapapeles.');
                            }
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar JSON'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        SectionCard(
          title: '2. Importar grant firmado',
          subtitle:
              'Confirma la huella del propietario por un canal distinto al '
              'archivo (por ejemplo, comparándola en persona).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _ownerFingerprint,
                maxLength: 64,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Huella Ed25519/X25519 del propietario',
                  helperText:
                      '64 caracteres hexadecimales; nunca se deduce del grant.',
                  prefixIcon: Icon(Icons.fingerprint),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: identity == null || widget.controller.busy
                      ? null
                      : _pickAndImportGrant,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Seleccionar grant'),
                ),
              ),
              if (widget.controller.hasMasterKey) ...[
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Bóveda inscrita'),
                  subtitle: SelectableText(
                    'Vault ID: ${widget.controller.vaultId}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: widget.controller.busy
                        ? null
                        : _confirmClearEnrollment,
                    icon: const Icon(Icons.logout),
                    label: const Text('Desinscribir'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SectionCard(
          title: 'Qué nunca se exporta',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Chip(
                avatar: Icon(Icons.block, size: 16),
                label: Text('Clave privada Ed25519'),
              ),
              Chip(
                avatar: Icon(Icons.block, size: 16),
                label: Text('Clave privada X25519'),
              ),
              Chip(
                avatar: Icon(Icons.block, size: 16),
                label: Text('Clave maestra en texto plano'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createIdentity() async {
    final name = _deviceName.text.trim();
    if (name.isEmpty) {
      _show('Escribe un nombre para este equipo.', error: true);
      return;
    }
    await widget.controller.createOrLoadIdentity(name);
  }

  Future<void> _exportPairingRequest() async {
    try {
      final selectedPath = await FilePicker.saveFile(
        dialogTitle: 'Guardar solicitud de emparejamiento',
        fileName: 'private-sandbox-device.pspair.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (selectedPath == null) return;
      final target = File(selectedPath);
      if (await target.exists()) {
        _show(
          'Elige un nombre nuevo; no se sobrescriben archivos existentes.',
          error: true,
        );
        return;
      }
      await target.writeAsString(
        widget.controller.createPairingRequestJson(),
        flush: true,
      );
      if (mounted) _show('DeviceIdentity exportado.');
    } catch (error) {
      if (mounted) _show('No se pudo exportar: $error', error: true);
    }
  }

  Future<void> _pickAndImportGrant() async {
    final owner = _ownerFingerprint.text.trim();
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(owner)) {
      _show('La huella del propietario no es válida.', error: true);
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Seleccionar grant firmado',
        type: FileType.custom,
        allowedExtensions: const ['json', 'psgrant'],
        allowMultiple: false,
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null) return;
      final file = File(path);
      if (await file.length() > 1024 * 1024) {
        throw const FormatException('El grant excede el límite de 1 MiB.');
      }
      await widget.controller.importGrantJson(
        serializedGrant: await file.readAsString(),
        expectedOwnerDeviceId: owner,
      );
    } catch (error) {
      if (mounted) _show('No se pudo leer el grant: $error', error: true);
    }
  }

  Future<void> _confirmClearEnrollment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desinscribir este equipo?'),
        content: const Text(
          'Se eliminarán la clave maestra y el checkpoint remoto de este '
          'companion. La identidad del dispositivo se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desinscribir'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await widget.controller.clearEnrollment();
  }

  void _show(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
