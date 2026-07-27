import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../shared/utils/random_bytes.dart';
import 'vault_backup_codec.dart';

/// Wraps/unwraps the vault master key under a backup password, so a
/// portable backup file never contains the key in a form usable without
/// that password — independent of the device's Keystore, which is the
/// whole point (Keystore-wrapped storage doesn't survive a device change).
class BackupKeyWrapper {
  const BackupKeyWrapper._();

  static const iterations = 200000;
  static final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
  static final _aesGcm = AesGcm.with256bits();

  static Future<({String saltBase64, String nonceBase64, String cipherTextBase64, String macBase64})> wrap({
    required String password,
    required Uint8List masterKeyBytes,
  }) async {
    final salt = randomBytes(16);
    final kek = await _deriveKek(password, salt);
    final secretBox = await _aesGcm.encrypt(masterKeyBytes, secretKey: kek);
    return (
      saltBase64: base64Encode(salt),
      nonceBase64: base64Encode(secretBox.nonce),
      cipherTextBase64: base64Encode(secretBox.cipherText),
      macBase64: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Returns null if [password] is wrong (AES-GCM authentication fails).
  static Future<Uint8List?> unwrap({
    required String password,
    required VaultBackupManifest manifest,
  }) async {
    try {
      final salt = base64Decode(manifest.kdfSaltBase64);
      final kek = await _deriveKek(password, salt);
      final secretBox = SecretBox(
        base64Decode(manifest.wrappedKeyCipherTextBase64),
        nonce: base64Decode(manifest.wrappedKeyNonceBase64),
        mac: Mac(base64Decode(manifest.wrappedKeyMacBase64)),
      );
      final decrypted = await _aesGcm.decrypt(secretBox, secretKey: kek);
      return Uint8List.fromList(decrypted);
    } catch (_) {
      return null;
    }
  }

  static Future<SecretKey> _deriveKek(String password, Uint8List salt) {
    return _pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
  }
}
