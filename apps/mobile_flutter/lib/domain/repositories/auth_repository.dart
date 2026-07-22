abstract interface class AuthRepository {
  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);

  Future<bool> isBiometricAvailable();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> authenticateWithBiometrics();
}
