import 'package:flutter/material.dart';
import 'package:mobile_flutter/domain/synchronization/sync_configuration.dart';
import 'package:mobile_flutter/domain/synchronization/sync_selection.dart';

import '../../application/companion_controller.dart';
import '../widgets/section_card.dart';

class SetupPage extends StatefulWidget {
  final CompanionController controller;

  const SetupPage({super.key, required this.controller});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _endpoint = TextEditingController();
  final _username = TextEditingController();
  final _secret = TextEditingController();
  final _deviceName = TextEditingController();
  SyncAuthenticationKind _authentication = SyncAuthenticationKind.basic;
  SyncConfiguration? _seededConfiguration;
  bool _backgroundSync = true;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _seed(widget.controller.configuration);
  }

  @override
  void didUpdateWidget(covariant SetupPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_seededConfiguration != widget.controller.configuration) {
      _seed(widget.controller.configuration);
    }
  }

  void _seed(SyncConfiguration? configuration) {
    if (configuration == null) {
      _seededConfiguration = null;
      return;
    }
    _endpoint.text = configuration.endpoint.toString();
    _username.text = configuration.username;
    _secret.text = configuration.secret;
    _deviceName.text = configuration.deviceDisplayName;
    _authentication = configuration.authenticationKind;
    _backgroundSync = configuration.backgroundSyncEnabled;
    _seededConfiguration = configuration;
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _username.dispose();
    _secret.dispose();
    _deviceName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Conexión WebDAV',
      subtitle:
          'El servidor almacena únicamente manifiestos y blobs cifrados. '
          'Las credenciales se guardan en el almacén seguro del sistema.',
      children: [
        SectionCard(
          title: 'Servidor remoto',
          subtitle:
              'Solo se aceptan endpoints HTTPS. Los certificados inválidos '
              'o las redirecciones no se ignoran.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _endpoint,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint WebDAV HTTPS',
                    hintText: 'https://cloud.example.com/dav/private-sandbox/',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final uri = Uri.tryParse(value?.trim() ?? '');
                    if (uri == null ||
                        uri.scheme != 'https' ||
                        uri.host.isEmpty) {
                      return 'Ingresa una dirección HTTPS válida.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SyncAuthenticationKind>(
                  initialValue: _authentication,
                  decoration: const InputDecoration(
                    labelText: 'Autenticación',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SyncAuthenticationKind.basic,
                      child: Text('Usuario y contraseña'),
                    ),
                    DropdownMenuItem(
                      value: SyncAuthenticationKind.bearer,
                      child: Text('Bearer token'),
                    ),
                    DropdownMenuItem(
                      value: SyncAuthenticationKind.none,
                      child: Text('Sin autenticación'),
                    ),
                  ],
                  onChanged: widget.controller.busy
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _authentication = value);
                          }
                        },
                ),
                if (_authentication == SyncAuthenticationKind.basic) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Obligatorio.' : null,
                  ),
                ],
                if (_authentication != SyncAuthenticationKind.none) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secret,
                    obscureText: _obscureSecret,
                    decoration: InputDecoration(
                      labelText:
                          _authentication == SyncAuthenticationKind.bearer
                          ? 'Token'
                          : 'Contraseña',
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        tooltip: _obscureSecret ? 'Mostrar' : 'Ocultar',
                        onPressed: () {
                          setState(() => _obscureSecret = !_obscureSecret);
                        },
                        icon: Icon(
                          _obscureSecret
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Obligatorio.' : null,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceName,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de este equipo',
                    hintText: 'PC de trabajo',
                    prefixIcon: Icon(Icons.computer),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'El equipo necesita un nombre.'
                      : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permitir sincronización en segundo plano'),
                  subtitle: const Text(
                    'La ejecución real depende de las políticas de Windows.',
                  ),
                  value: _backgroundSync,
                  onChanged: widget.controller.busy
                      ? null
                      : (value) => setState(() => _backgroundSync = value),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.controller.busy
                          ? null
                          : () => _save(testAfterSave: true),
                      icon: const Icon(Icons.network_check),
                      label: const Text('Guardar y probar'),
                    ),
                    FilledButton.icon(
                      onPressed: widget.controller.busy
                          ? null
                          : () => _save(testAfterSave: false),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionCard(
          title: 'Modelo de seguridad',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecurityLine(
                icon: Icons.https,
                text: 'Transporte HTTPS obligatorio y sin downgrade a HTTP.',
              ),
              _SecurityLine(
                icon: Icons.enhanced_encryption_outlined,
                text:
                    'AES-256-GCM para el manifiesto; Ed25519 para autenticidad.',
              ),
              _SecurityLine(
                icon: Icons.sync_lock,
                text:
                    'ETag compare-and-swap evita sobrescribir cambios concurrentes.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save({required bool testAfterSave}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = widget.controller.configuration;
    final configuration = SyncConfiguration(
      endpoint: Uri.parse(_endpoint.text.trim()),
      authenticationKind: _authentication,
      username: _authentication == SyncAuthenticationKind.basic
          ? _username.text
          : '',
      secret: _authentication == SyncAuthenticationKind.none
          ? ''
          : _secret.text,
      deviceDisplayName: _deviceName.text.trim(),
      backgroundSyncEnabled: _backgroundSync,
      policy: current?.policy ?? const SelectiveSyncPolicy(),
    );
    final saved = await widget.controller.saveConfiguration(configuration);
    if (saved && testAfterSave) {
      await widget.controller.testWebDav();
    }
  }
}

class _SecurityLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SecurityLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
