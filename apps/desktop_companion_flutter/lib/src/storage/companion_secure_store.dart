import 'dart:convert';

import 'package:mobile_flutter/domain/synchronization/sync_configuration.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_identity_store.dart';

import '../models/stored_enrollment.dart';

/// Desktop state persisted through the platform credential vault.
///
/// On Windows the production [SyncSecretStore] is backed by
/// `flutter_secure_storage` and Windows Credential Manager.
class CompanionSecureStore {
  static const String configurationKey = 'desktop_companion_configuration_v1';
  static const String enrollmentKey = 'desktop_companion_enrollment_v1';

  final SyncSecretStore _secrets;

  const CompanionSecureStore(this._secrets);

  Future<SyncConfiguration?> loadConfiguration() async {
    final serialized = await _secrets.read(configurationKey);
    if (serialized == null) return null;
    try {
      return SyncConfiguration.fromJson(
        Map<String, Object?>.from(jsonDecode(serialized) as Map),
      );
    } catch (error) {
      throw SyncIntegrityException(
        'La configuración segura del companion está dañada.',
        error,
      );
    }
  }

  Future<void> saveConfiguration(SyncConfiguration configuration) async {
    configuration.validate();
    await _secrets.write(
      configurationKey,
      canonicalJson(configuration.toJson()),
    );
  }

  Future<StoredEnrollment?> loadEnrollment() async {
    final serialized = await _secrets.read(enrollmentKey);
    if (serialized == null) return null;
    try {
      return StoredEnrollment.fromJson(
        Map<String, Object?>.from(jsonDecode(serialized) as Map),
      );
    } on SyncException {
      rethrow;
    } catch (error) {
      throw SyncIntegrityException(
        'La inscripción segura de la bóveda está dañada.',
        error,
      );
    }
  }

  Future<void> saveEnrollment(StoredEnrollment enrollment) {
    return _secrets.write(enrollmentKey, canonicalJson(enrollment.toJson()));
  }

  Future<void> clearEnrollment() => _secrets.delete(enrollmentKey);
}
