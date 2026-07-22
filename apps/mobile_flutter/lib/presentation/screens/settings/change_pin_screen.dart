import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../widgets/numeric_keypad.dart';
import '../../widgets/pin_dots.dart';

enum _Step { verifyCurrent, enterNew, confirmNew }

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  static const _pinLength = 6;
  _Step _step = _Step.verifyCurrent;
  String _newPin = '';
  String _current = '';
  String? _error;

  void _onDigit(String digit) {
    if (_current.length >= _pinLength) return;
    setState(() {
      _current += digit;
      _error = null;
    });
    if (_current.length == _pinLength) _handleComplete();
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _handleComplete() async {
    switch (_step) {
      case _Step.verifyCurrent:
        final ok = await ref.read(authRepositoryProvider).verifyPin(_current);
        if (!ok) {
          setState(() {
            _error = 'PIN incorrecto';
            _current = '';
          });
          return;
        }
        setState(() {
          _step = _Step.enterNew;
          _current = '';
        });
      case _Step.enterNew:
        setState(() {
          _newPin = _current;
          _current = '';
          _step = _Step.confirmNew;
        });
      case _Step.confirmNew:
        if (_current == _newPin) {
          await ref.read(authRepositoryProvider).setPin(_current);
          if (mounted) Navigator.of(context).pop();
        } else {
          setState(() {
            _error = 'Los PIN no coinciden.';
            _current = '';
            _newPin = '';
            _step = _Step.enterNew;
          });
        }
    }
  }

  String get _title => switch (_step) {
        _Step.verifyCurrent => 'Ingresa tu PIN actual',
        _Step.enterNew => 'Ingresa tu nuevo PIN',
        _Step.confirmNew => 'Confirma tu nuevo PIN',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
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
