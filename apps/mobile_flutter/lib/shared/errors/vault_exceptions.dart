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

/// Raised when a long-running operation (currently an import) is aborted by
/// the user partway through. Callers treat this as a clean cancellation —
/// roll back partial state — rather than a failure to report.
class CancelledException extends VaultException {
  const CancelledException([super.message = 'Operación cancelada.']);
}
