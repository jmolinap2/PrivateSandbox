import '../entities/auto_lock_timeout.dart';

abstract interface class AuthRepository {
  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<Duration?> getPinRetryDelay();

  Future<bool> isBiometricAvailable();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> authenticateWithBiometrics();

  Future<AutoLockTimeout> getAutoLockTimeout();
  Future<void> setAutoLockTimeout(AutoLockTimeout value);
}
