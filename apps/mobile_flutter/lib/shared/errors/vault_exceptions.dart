/// Base class for all recoverable errors raised by the vault's use cases.
sealed class VaultException implements Exception {
  final String message;
  const VaultException(this.message);

  @override
  String toString() => message;
}

class ImportException extends VaultException {
  const ImportException(super.message);
}

class ExportException extends VaultException {
  const ExportException(super.message);
}

/// Raised when a decrypted file's hash does not match the hash recorded at
/// import time, i.e. the ciphertext could not be round-tripped faithfully.
class IntegrityException extends VaultException {
  const IntegrityException(super.message);
}

class AuthException extends VaultException {
  const AuthException(super.message);
}

/// The app has durable evidence that a vault already exists, but the
/// Keystore-backed master key is absent, malformed, or no longer matches it.
/// Generating a replacement would make every existing blob permanently
/// unreadable, so callers must stop and offer backup recovery instead.
class KeyMaterialMissingException extends VaultException {
  const KeyMaterialMissingException([
    super.message = 'La clave maestra de esta bóveda no está disponible. Restaura una copia de seguridad.',
  ]);
}

/// Raised when a long-running operation (currently an import) is aborted by
/// the user partway through. Callers treat this as a clean cancellation —
/// roll back partial state — rather than a failure to report.
class CancelledException extends VaultException {
  const CancelledException([super.message = 'Operación cancelada.']);
}
