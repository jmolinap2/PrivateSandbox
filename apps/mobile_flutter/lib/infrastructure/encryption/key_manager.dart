import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/errors/vault_exceptions.dart';

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
  static const _keyMarkerFileName = '.vault-key-fingerprint-v1';
  static final _aesGcm = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  KeyManager({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<SecretKey> getOrCreateMasterKey() async {
    final existing = await _secureStorage.read(key: _masterKeyStorageKey);
    if (existing != null) {
      final bytes = _decodeAndValidate(existing);
      await _validateOrCreateMarker(bytes);
      return SecretKey(bytes);
    }

    // A marker survives alongside the database and ciphertext. If it exists
    // while secure storage no longer contains the key (for example after an
    // invalid Android Auto Backup restore), silently creating a new key would
    // destroy the only useful signal that recovery is still possible.
    if (await _readMarker() != null) {
      throw const KeyMaterialMissingException();
    }
    final newKey = await _aesGcm.newSecretKey();
    final bytes = Uint8List.fromList(await newKey.extractBytes());
    await _secureStorage.write(
      key: _masterKeyStorageKey,
      value: base64Encode(bytes),
    );
    await _writeMarker(bytes);
    return newKey;
  }

  /// Loads an already-provisioned master key and never creates a replacement.
  ///
  /// Use this whenever vault records already exist. Generating a fresh key in
  /// that situation would make every ciphertext permanently unreadable while
  /// making the failure look like ordinary corruption.
  Future<SecretKey> getExistingMasterKey() async {
    final encoded = await _secureStorage.read(key: _masterKeyStorageKey);
    if (encoded == null) {
      throw const KeyMaterialMissingException();
    }
    final bytes = _decodeAndValidate(encoded);
    await _validateOrCreateMarker(bytes);
    return SecretKey(bytes);
  }

  /// Raw master key bytes, for wrapping into a portable backup. Never
  /// written anywhere in this form — callers must encrypt it before it
  /// leaves the process.
  Future<Uint8List> exportMasterKeyBytes() async {
    final key = await getOrCreateMasterKey();
    return Uint8List.fromList(await key.extractBytes());
  }

  /// Reads the key that is actually present in Secure Storage and returns
  /// only its SHA-256 fingerprint, without consulting or rewriting the
  /// filesystem marker. Full-vault restore recovery uses this before opening
  /// SQLite to decide whether an interrupted cross-store swap committed the
  /// old or the restored key.
  Future<String?> readStoredMasterKeyFingerprint() async {
    final encoded = await _secureStorage.read(key: _masterKeyStorageKey);
    if (encoded == null) return null;
    return _fingerprint(_decodeAndValidate(encoded));
  }

  /// Overwrites the master key with [bytes] recovered from a backup. Every
  /// existing file's key is derived from the master key, so this only
  /// makes sense as part of a full vault restore (DB + blobs replaced to
  /// match), never on its own.
  Future<void> importMasterKeyBytes(Uint8List bytes) async {
    if (bytes.length != 32) {
      throw const FormatException(
        'La clave maestra debe tener exactamente 32 bytes.',
      );
    }
    await _secureStorage.write(
      key: _masterKeyStorageKey,
      value: base64Encode(bytes),
    );
    await _writeMarker(bytes);
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

  /// Derives the key used for a file's thumbnail — same salt as the main
  /// content, but a different HKDF `info` context, so it's a fully
  /// independent key (no nonce-space bookkeeping needed between the two).
  Future<SecretKey> deriveThumbnailKey(
    SecretKey masterKey,
    Uint8List fileSalt,
  ) {
    return _hkdf.deriveKey(
      secretKey: masterKey,
      nonce: fileSalt,
      info: utf8.encode('private-sandbox-vault-thumbnail-key-v1'),
    );
  }

  Uint8List _decodeAndValidate(String encoded) {
    try {
      final bytes = Uint8List.fromList(base64Decode(encoded));
      if (bytes.length != 32) throw const FormatException();
      return bytes;
    } on FormatException {
      throw const KeyMaterialMissingException(
        'La clave maestra almacenada está dañada.',
      );
    }
  }

  Future<File> _markerFile() async {
    final support = await getApplicationSupportDirectory();
    return File(p.join(support.path, _keyMarkerFileName));
  }

  Future<String?> _readMarker() async {
    final marker = await _markerFile();
    if (!await marker.exists()) return null;
    final value = (await marker.readAsString()).trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _validateOrCreateMarker(Uint8List bytes) async {
    final expected = _fingerprint(bytes);
    final existing = await _readMarker();
    if (existing == null) {
      await _writeMarker(bytes);
      return;
    }
    if (!_constantTimeStringEquals(existing, expected)) {
      throw const KeyMaterialMissingException(
        'La clave maestra no corresponde a los datos de esta bóveda.',
      );
    }
  }

  Future<void> _writeMarker(Uint8List bytes) async {
    final marker = await _markerFile();
    final pending = File('${marker.path}.pending');
    await pending.writeAsString(_fingerprint(bytes), flush: true);
    if (await marker.exists()) await marker.delete();
    await pending.rename(marker.path);
  }

  String _fingerprint(Uint8List bytes) =>
      crypto.sha256.convert(bytes).toString();

  bool _constantTimeStringEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
