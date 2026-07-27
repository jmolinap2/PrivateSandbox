import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/utils/random_bytes.dart';

/// Stores only a salted PBKDF2 hash of the vault PIN — never the PIN itself
/// — inside Keystore-backed secure storage. 120k iterations is deliberately
/// expensive to slow down offline brute force against a short numeric PIN.
class PinStorage {
  final FlutterSecureStorage _secureStorage;
  static const _pinHashKey = 'vault_pin_hash_v1';
  static const _pinSaltKey = 'vault_pin_salt_v1';
  static const _failedAttemptsKey = 'vault_pin_failed_attempts_v1';
  static const _retryAfterKey = 'vault_pin_retry_after_v1';
  static const _freeAttempts = 5;
  static const _initialBackoffSeconds = 30;
  static const _maximumBackoffSeconds = 60 * 60;
  static final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256);

  PinStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<bool> hasPin() async => (await _secureStorage.read(key: _pinHashKey)) != null;

  Future<void> setPin(String pin) async {
    final salt = randomBytes(16);
    final hash = await _derive(pin, salt);
    await _secureStorage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _secureStorage.write(key: _pinHashKey, value: base64Encode(hash));
    await _clearFailures();
  }

  Future<bool> verifyPin(String pin) async {
    if (await getRetryDelay() != null) return false;

    final saltB64 = await _secureStorage.read(key: _pinSaltKey);
    final hashB64 = await _secureStorage.read(key: _pinHashKey);
    if (saltB64 == null || hashB64 == null) return false;
    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final actual = await _derive(pin, salt);
    final matches = _constantTimeEquals(actual, expected);
    if (matches) {
      await _clearFailures();
    } else {
      await _recordFailure();
    }
    return matches;
  }

  /// Returns the remaining persistent backoff after repeated invalid PINs.
  /// The timestamp lives in secure storage, so restarting the process does
  /// not reset the throttle.
  Future<Duration?> getRetryDelay() async {
    final raw = await _secureStorage.read(key: _retryAfterKey);
    if (raw == null) return null;
    final retryAfterMs = int.tryParse(raw);
    if (retryAfterMs == null) {
      await _secureStorage.delete(key: _retryAfterKey);
      return null;
    }
    final remainingMs = retryAfterMs - DateTime.now().toUtc().millisecondsSinceEpoch;
    if (remainingMs <= 0) {
      await _secureStorage.delete(key: _retryAfterKey);
      return null;
    }
    return Duration(milliseconds: remainingMs);
  }

  Future<Uint8List> _derive(String pin, Uint8List salt) async {
    final key = await _pbkdf2.deriveKeyFromPassword(password: pin, nonce: salt);
    return Uint8List.fromList(await key.extractBytes());
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<void> _recordFailure() async {
    final stored = await _secureStorage.read(key: _failedAttemptsKey);
    final failures = (int.tryParse(stored ?? '') ?? 0) + 1;
    await _secureStorage.write(key: _failedAttemptsKey, value: failures.toString());
    if (failures < _freeAttempts) return;

    final exponent = (failures - _freeAttempts).clamp(0, 16).toInt();
    final seconds = (_initialBackoffSeconds * (1 << exponent)).clamp(
      _initialBackoffSeconds,
      _maximumBackoffSeconds,
    ).toInt();
    final retryAfter = DateTime.now().toUtc().add(Duration(seconds: seconds));
    await _secureStorage.write(
      key: _retryAfterKey,
      value: retryAfter.millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _clearFailures() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _retryAfterKey);
  }
}
