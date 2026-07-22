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
  static final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256);

  PinStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<bool> hasPin() async => (await _secureStorage.read(key: _pinHashKey)) != null;

  Future<void> setPin(String pin) async {
    final salt = randomBytes(16);
    final hash = await _derive(pin, salt);
    await _secureStorage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _secureStorage.write(key: _pinHashKey, value: base64Encode(hash));
  }

  Future<bool> verifyPin(String pin) async {
    final saltB64 = await _secureStorage.read(key: _pinSaltKey);
    final hashB64 = await _secureStorage.read(key: _pinHashKey);
    if (saltB64 == null || hashB64 == null) return false;
    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final actual = await _derive(pin, salt);
    return _constantTimeEquals(actual, expected);
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
}
