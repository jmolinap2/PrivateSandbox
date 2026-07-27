// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_protocol.dart';

abstract interface class SyncSecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureSyncSecretStore implements SyncSecretStore {
  final FlutterSecureStorage _storage;

  FlutterSecureSyncSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Test/desktop-friendly secret store. Production mobile wiring should use
/// [FlutterSecureSyncSecretStore].
class MemorySyncSecretStore implements SyncSecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class DeviceCredentials {
  final DeviceIdentity identity;
  final SimpleKeyPairData signingKeyPair;
  final SimpleKeyPairData exchangeKeyPair;

  const DeviceCredentials({
    required this.identity,
    required this.signingKeyPair,
    required this.exchangeKeyPair,
  });

  void destroy() {
    signingKeyPair.destroy();
    exchangeKeyPair.destroy();
  }
}

/// Generates and persists one Ed25519/X25519 identity per installation.
///
/// Corrupted or incomplete key material is rejected. It is never silently
/// replaced, because doing so would turn an authorized device into a different
/// identity and could strand pending synchronized data.
class DeviceIdentityManager {
  static const String storageKey = 'sync_device_identity_v1';
  static const int _storageFormatVersion = 1;

  final SyncSecretStore _secretStore;
  final DateTime Function() _clock;
  final Ed25519 _signing = Ed25519();
  final X25519 _exchange = X25519();

  DeviceIdentityManager({
    required SyncSecretStore secretStore,
    DateTime Function()? clock,
  }) : _secretStore = secretStore,
       _clock = clock ?? DateTime.now;

  Future<DeviceCredentials> loadOrCreate({required String displayName}) async {
    final serialized = await _secretStore.read(storageKey);
    if (serialized != null) return _decode(serialized);

    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName', 'Cannot be blank');
    }
    final signing = await _signing.newKeyPair();
    final exchange = await _exchange.newKeyPair();
    final signingData = await signing.extract();
    final exchangeData = await exchange.extract();
    final identity = DeviceIdentity.fromPublicKeys(
      displayName: normalizedName,
      signingPublicKey: signingData.publicKey.bytes,
      exchangePublicKey: exchangeData.publicKey.bytes,
      createdAt: _clock().toUtc(),
    );
    final credentials = DeviceCredentials(
      identity: identity,
      signingKeyPair: signingData,
      exchangeKeyPair: exchangeData,
    );
    await _secretStore.write(storageKey, _encode(credentials));
    return credentials;
  }

  Future<DeviceCredentials?> load() async {
    final serialized = await _secretStore.read(storageKey);
    return serialized == null ? null : _decode(serialized);
  }

  /// Explicit destructive reset for logout/wipe flows. Callers must first
  /// remove/revoke this device from the encrypted registry where possible.
  Future<void> deleteIdentity() => _secretStore.delete(storageKey);

  String _encode(DeviceCredentials credentials) {
    return jsonEncode(<String, Object?>{
      'formatVersion': _storageFormatVersion,
      'identity': credentials.identity.toJson(),
      'signingPrivateKey': base64Encode(credentials.signingKeyPair.bytes),
      'exchangePrivateKey': base64Encode(credentials.exchangeKeyPair.bytes),
    });
  }

  DeviceCredentials _decode(String serialized) {
    try {
      final json = Map<String, Object?>.from(jsonDecode(serialized) as Map);
      if (json['formatVersion'] != _storageFormatVersion) {
        throw const SyncProtocolException(
          'Unsupported stored device identity format',
        );
      }
      final identity = DeviceIdentity.fromJson(
        Map<String, Object?>.from(json['identity']! as Map),
      );
      final signingPublic = base64Decode(identity.signingPublicKeyBase64);
      final exchangePublic = base64Decode(identity.exchangePublicKeyBase64);
      final recomputed = DeviceIdentity.fromPublicKeys(
        displayName: identity.displayName,
        signingPublicKey: signingPublic,
        exchangePublicKey: exchangePublic,
        createdAt: identity.createdAt,
      );
      if (recomputed.deviceId != identity.deviceId) {
        throw const SyncIntegrityException(
          'Device identity fingerprint mismatch',
        );
      }
      return DeviceCredentials(
        identity: identity,
        signingKeyPair: SimpleKeyPairData(
          base64Decode(json['signingPrivateKey']! as String),
          publicKey: SimplePublicKey(signingPublic, type: KeyPairType.ed25519),
          type: KeyPairType.ed25519,
        ),
        exchangeKeyPair: SimpleKeyPairData(
          base64Decode(json['exchangePrivateKey']! as String),
          publicKey: SimplePublicKey(exchangePublic, type: KeyPairType.x25519),
          type: KeyPairType.x25519,
        ),
      );
    } on SyncException {
      rethrow;
    } catch (error) {
      throw SyncIntegrityException(
        'Stored device identity is corrupted',
        error,
      );
    }
  }
}
