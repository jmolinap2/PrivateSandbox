import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/providers.dart';
import '../../widgets/numeric_keypad.dart';
import '../../widgets/pin_dots.dart';

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  static const _pinLength = 6;
  String _current = '';
  String? _error;
  bool _checking = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final authRepo = ref.read(authRepositoryProvider);
    final enabled = await authRepo.isBiometricEnabled();
    final available = await authRepo.isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = enabled && available);
    if (!enabled || !available) return;
    await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _onDigit(String digit) async {
    if (_current.length >= _pinLength || _checking) return;
    setState(() {
      _current += digit;
      _error = null;
    });
    if (_current.length == _pinLength) {
      setState(() => _checking = true);
      final ok = await ref.read(authControllerProvider.notifier).unlockWithPin(_current);
      if (!ok && mounted) {
        setState(() {
          _error = 'PIN incorrecto';
          _current = '';
          _checking = false;
        });
      }
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Ingresa tu PIN', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 32),
              PinDots(length: _pinLength, filled: _current.length),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const Spacer(),
              NumericKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onBiometric: _biometricAvailable ? _tryBiometric : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
