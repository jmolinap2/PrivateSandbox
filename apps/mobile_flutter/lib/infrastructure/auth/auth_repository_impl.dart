import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auto_lock_timeout.dart';
import '../../domain/repositories/auth_repository.dart';
import 'biometric_service.dart';
import 'pin_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final PinStorage _pinStorage;
  final BiometricService _biometricService;
  final FlutterSecureStorage _secureStorage;
  static const _biometricEnabledKey = 'vault_biometric_enabled_v1';
  static const _autoLockTimeoutKey = 'vault_auto_lock_timeout_v1';

  AuthRepositoryImpl({
    PinStorage? pinStorage,
    BiometricService? biometricService,
    FlutterSecureStorage? secureStorage,
  })  : _pinStorage = pinStorage ?? PinStorage(),
        _biometricService = biometricService ?? BiometricService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<bool> hasPin() => _pinStorage.hasPin();

  @override
  Future<void> setPin(String pin) => _pinStorage.setPin(pin);

  @override
  Future<bool> verifyPin(String pin) => _pinStorage.verifyPin(pin);

  @override
  Future<bool> isBiometricAvailable() => _biometricService.isAvailable();

  @override
  Future<bool> isBiometricEnabled() async => (await _secureStorage.read(key: _biometricEnabledKey)) == 'true';

  @override
  Future<void> setBiometricEnabled(bool enabled) {
    return _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  @override
  Future<bool> authenticateWithBiometrics() => _biometricService.authenticate();

  @override
  Future<AutoLockTimeout> getAutoLockTimeout() async {
    final stored = await _secureStorage.read(key: _autoLockTimeoutKey);
    return AutoLockTimeout.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => AutoLockTimeout.immediate,
    );
  }

  @override
  Future<void> setAutoLockTimeout(AutoLockTimeout value) {
    return _secureStorage.write(key: _autoLockTimeoutKey, value: value.name);
  }
}
