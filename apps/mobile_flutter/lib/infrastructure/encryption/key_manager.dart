import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Owns the vault master key and derives per-file keys from it.
///
/// The master key is generated once and stored via [FlutterSecureStorage],
/// which on Android wraps stored values with a cipher key held in the
/// Android Keystore — the master key itself is never written to SQLite or
/// plain application storage, satisfying the plan's "claves protegidas por
/// Android Keystore" requirement without hand-rolling a Keystore platform
/// channel.
class KeyManager {
  final FlutterSecureStorage _secureStorage;
  static const _masterKeyStorageKey = 'vault_master_key_v1';
  static final _aesGcm = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  KeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<SecretKey> getOrCreateMasterKey() async {
    final existing = await _secureStorage.read(key: _masterKeyStorageKey);
    if (existing != null) {
      return SecretKey(base64Decode(existing));
    }
    final newKey = await _aesGcm.newSecretKey();
    final bytes = await newKey.extractBytes();
    await _secureStorage.write(
      key: _masterKeyStorageKey,
      value: base64Encode(bytes),
    );
    return newKey;
  }

  /// Derives a unique per-file key via HKDF-SHA256, using the file's random
  /// salt as the HKDF salt. No two files share a key, so compromising one
  /// file's key cannot be used to decrypt another.
  Future<SecretKey> deriveFileKey(SecretKey masterKey, Uint8List fileSalt) {
    return _hkdf.deriveKey(
      secretKey: masterKey,
      nonce: fileSalt,
      info: utf8.encode('private-sandbox-vault-file-key-v1'),
    );
  }
}
