import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/synchronization/sync_configuration.dart';
import '../../domain/synchronization/sync_protocol.dart';

class SyncConfigurationStore {
  static const storageKey = 'sync_configuration_v1';

  final FlutterSecureStorage _storage;

  const SyncConfigurationStore(this._storage);

  Future<SyncConfiguration?> load() async {
    final serialized = await _storage.read(key: storageKey);
    if (serialized == null) return null;
    try {
      return SyncConfiguration.fromJson(
        Map<String, Object?>.from(jsonDecode(serialized) as Map),
      );
    } catch (error) {
      throw SyncIntegrityException(
        'La configuración de sincronización está dañada.',
        error,
      );
    }
  }

  Future<void> save(SyncConfiguration configuration) async {
    configuration.validate();
    await _storage.write(
      key: storageKey,
      value: jsonEncode(configuration.toJson()),
    );
  }

  Future<void> clear() => _storage.delete(key: storageKey);
}
