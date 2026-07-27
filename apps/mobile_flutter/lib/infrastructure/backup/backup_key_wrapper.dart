import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../shared/utils/random_bytes.dart';

/// Password-derived envelope that protects the 256-bit vault master key in
/// a portable backup. The KDF parameters are deliberately explicit so the
/// backup reader can reject unsupported or abusive values before doing any
/// expensive work.
class BackupKeyEnvelope {
  final String saltBase64;
  final int kdfIterations;
  final String nonceBase64;
  final String cipherTextBase64;
  final String macBase64;

  const BackupKeyEnvelope({
    required this.saltBase64,
    required this.kdfIterations,
    required this.nonceBase64,
    required this.cipherTextBase64,
    required this.macBase64,
  });
}

/// Wraps/unwraps the vault master key under a backup password, so a
/// portable backup file never contains the key in a form usable without
/// that password — independent of the device's Keystore, which is the
/// whole point (Keystore-wrapped storage doesn't survive a device change).
class BackupKeyWrapper {
  const BackupKeyWrapper._();

  static const iterations = 200000;
  static const saltLength = 16;
  static const nonceLength = 12;
  static const macLength = 16;
  static const masterKeyLength = 32;
  static const kdfAlgorithm = 'PBKDF2-HMAC-SHA256';
  static const _envelopeContext = 'PrivateSandbox/PSVB2/master-key-envelope';
  static final _aesGcm = AesGcm.with256bits();

  static Future<BackupKeyEnvelope> wrap({
    required String password,
    required Uint8List masterKeyBytes,
  }) async {
    if (masterKeyBytes.length != masterKeyLength) {
      throw ArgumentError.value(
        masterKeyBytes.length,
        'masterKeyBytes',
        'La clave maestra debe tener exactamente $masterKeyLength bytes.',
      );
    }

    final salt = randomBytes(saltLength);
    final saltBase64 = base64Encode(salt);
    final kek = await _deriveKek(password, salt, iterations);
    final secretBox = await _aesGcm.encrypt(
      masterKeyBytes,
      secretKey: kek,
      aad: _aad(saltBase64, iterations),
    );
    return BackupKeyEnvelope(
      saltBase64: base64Encode(salt),
      kdfIterations: iterations,
      nonceBase64: base64Encode(secretBox.nonce),
      cipherTextBase64: base64Encode(secretBox.cipherText),
      macBase64: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Returns null if [password] is wrong (AES-GCM authentication fails).
  static Future<Uint8List?> unwrap({
    required String password,
    required BackupKeyEnvelope envelope,
  }) async {
    try {
      if (envelope.kdfIterations != iterations) return null;

      final salt = base64Decode(envelope.saltBase64);
      final nonce = base64Decode(envelope.nonceBase64);
      final cipherText = base64Decode(envelope.cipherTextBase64);
      final mac = base64Decode(envelope.macBase64);
      if (salt.length != saltLength ||
          nonce.length != nonceLength ||
          cipherText.length != masterKeyLength ||
          mac.length != macLength) {
        return null;
      }

      final kek = await _deriveKek(password, salt, envelope.kdfIterations);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
      final decrypted = await _aesGcm.decrypt(
        secretBox,
        secretKey: kek,
        aad: _aad(envelope.saltBase64, envelope.kdfIterations),
      );
      if (decrypted.length != masterKeyLength) return null;
      return Uint8List.fromList(decrypted);
    } catch (_) {
      return null;
    }
  }

  static Future<SecretKey> _deriveKek(
    String password,
    Uint8List salt,
    int iterationCount,
  ) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterationCount,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
  }

  static List<int> _aad(String saltBase64, int iterationCount) => utf8.encode(
    '$_envelopeContext|$kdfAlgorithm|$iterationCount|$saltBase64',
  );
}
