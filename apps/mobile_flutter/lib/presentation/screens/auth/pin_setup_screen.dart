import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../widgets/numeric_keypad.dart';
import '../../widgets/pin_dots.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  static const _pinLength = 6;
  String _firstPin = '';
  String _current = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String digit) {
    if (_current.length >= _pinLength) return;
    setState(() {
      _current += digit;
      _error = null;
    });
    if (_current.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _firstPin = _current;
        _current = '';
        _confirming = true;
      });
      return;
    }
    if (_current == _firstPin) {
      await ref.read(authControllerProvider.notifier).setupPin(_current);
    } else {
      setState(() {
        _error = 'Los PIN no coinciden. Inténtalo de nuevo.';
        _firstPin = '';
        _current = '';
        _confirming = false;
      });
    }
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
              Text(
                'Protege tu bóveda',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _confirming ? 'Confirma tu PIN' : 'Crea un PIN de $_pinLength dígitos',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinDots(length: _pinLength, filled: _current.length),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const Spacer(),
              NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            ],
          ),
        ),
      ),
    );
  }
}
