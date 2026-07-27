import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/providers.dart';
import '../../../shared/errors/vault_exceptions.dart';
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
    try {
      await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
    } on KeyMaterialMissingException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_current.length >= _pinLength || _checking) return;
    setState(() {
      _current += digit;
      _error = null;
    });
    if (_current.length == _pinLength) {
      setState(() => _checking = true);
      bool ok;
      try {
        ok = await ref.read(authControllerProvider.notifier).unlockWithPin(_current);
      } on KeyMaterialMissingException catch (error) {
        if (!mounted) return;
        setState(() {
          _error = error.message;
          _current = '';
          _checking = false;
        });
        return;
      }
      if (!ok && mounted) {
        final retryDelay = await ref.read(authRepositoryProvider).getPinRetryDelay();
        if (!mounted) return;
        setState(() {
          _error = retryDelay == null
              ? 'PIN incorrecto'
              : 'Demasiados intentos. Vuelve a intentarlo en ${_formatRetryDelay(retryDelay)}.';
          _current = '';
          _checking = false;
        });
      }
    }
  }

  String _formatRetryDelay(Duration duration) {
    final seconds = duration.inSeconds + 1;
    if (seconds < 60) return '$seconds s';
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
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
