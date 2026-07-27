import 'dart:convert';
import 'dart:typed_data';

import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';

import 'trusted_remote_state.dart';

/// One atomically persisted secure-storage value containing the vault key and
/// its trust checkpoint.
class StoredEnrollment {
  static const int formatVersion = 1;

  final Uint8List masterKeyBytes;
  final TrustedRemoteState trust;

  StoredEnrollment({required Uint8List masterKeyBytes, required this.trust})
    : masterKeyBytes = Uint8List.fromList(masterKeyBytes) {
    if (masterKeyBytes.length != 32) {
      throw ArgumentError.value(
        masterKeyBytes.length,
        'masterKeyBytes',
        'Se esperaba una clave maestra de 256 bits.',
      );
    }
  }

  StoredEnrollment withTrust(TrustedRemoteState value) {
    if (value.vaultId != trust.vaultId) {
      throw const SyncIntegrityException(
        'No se puede cambiar el identificador de la bóveda inscrita.',
      );
    }
    return StoredEnrollment(masterKeyBytes: masterKeyBytes, trust: value);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'formatVersion': formatVersion,
    'masterKey': base64Encode(masterKeyBytes),
    'trust': trust.toJson(),
  };

  factory StoredEnrollment.fromJson(Map<String, Object?> json) {
    if (json['formatVersion'] != formatVersion) {
      throw const SyncProtocolException(
        'Versión de inscripción local no compatible.',
      );
    }
    return StoredEnrollment(
      masterKeyBytes: Uint8List.fromList(
        base64Decode(json['masterKey']! as String),
      ),
      trust: TrustedRemoteState.fromJson(
        Map<String, Object?>.from(json['trust']! as Map),
      ),
    );
  }
}
