import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/providers.dart';
import 'change_pin_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authRepo = ref.read(authRepositoryProvider);
    final available = await authRepo.isBiometricAvailable();
    final enabled = await authRepo.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    await ref.read(authRepositoryProvider).setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
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
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Bloquear ahora'),
                  onTap: () {
                    ref.read(authControllerProvider.notifier).lock();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
    );
  }
}
