import 'dart:io';
import 'dart:typed_data';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_manifest.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../infrastructure/storage/atomic_file_writer.dart';
import '../../infrastructure/synchronization/device_enrollment_package.dart';
import '../../infrastructure/synchronization/device_identity_store.dart';
import '../../infrastructure/synchronization/device_key_grant.dart';
import '../../infrastructure/synchronization/sync_checkpoint_store.dart';
import '../../infrastructure/synchronization/sync_crypto.dart';
import 'configured_synchronization_service.dart';
import 'device_grant_recovery_coordinator.dart';
import 'synchronization_engine.dart';

class DeviceAdministrationSnapshot {
  final SyncManifest manifest;
  final String currentDeviceId;

  const DeviceAdministrationSnapshot({
    required this.manifest,
    required this.currentDeviceId,
  });

  DeviceRegistration get currentDevice =>
      manifest.requireAuthorizedDevice(currentDeviceId);

  bool get canAdminister => currentDevice.role == DeviceRole.owner;

  List<DeviceRegistration> get registrations {
    final values = manifest.devices.values.toList()
      ..sort((left, right) {
        if (left.isAuthorized != right.isAuthorized) {
          return left.isAuthorized ? -1 : 1;
        }
        return left.identity.displayName.compareTo(right.identity.displayName);
      });
    return values;
  }

  List<RemoteDeviceDirective> get pendingForCurrentDevice {
    final now = DateTime.now().toUtc();
    final directives =
        manifest.directives.values
            .where((directive) => directive.isPendingFor(currentDeviceId, now))
            .toList()
          ..sort((left, right) => right.issuedAt.compareTo(left.issuedAt));
    return directives;
  }
}

/// Application facade for the complete two-file device enrollment flow.
///
/// Pairing requests and grants are user-moved files; the WebDAV server only
/// ever sees the encrypted manifest after the owner has authorized the new
/// public identity.
class DeviceEnrollmentService {
  static const int maximumPackageBytes = 1024 * 1024;

  final ConfiguredSynchronizationService synchronization;
  final DateTime Function() _clock;

  DeviceEnrollmentService({
    required this.synchronization,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  Future<File> exportPairingRequest(Directory destination) async {
    final identity = await synchronization.loadOrCreateDeviceIdentity();
    final request = DevicePairingRequest(
      requestedAt: _clock().toUtc(),
      identity: identity,
    );
    final bytes = DeviceEnrollmentPackageCodec.encodePairingRequest(request);
    return AtomicFileWriter.writeStream(
      destinationDirectory: destination,
      preferredName:
          'private-sandbox-${_shortId(identity.deviceId)}-solicitud.psdr',
      bytes: Stream<List<int>>.value(bytes),
      expectedLength: bytes.length,
      modifiedAt: _clock(),
    );
  }

  Future<DevicePairingRequest> readPairingRequest(File file) async {
    final bytes = await _readBounded(file);
    return DeviceEnrollmentPackageCodec.decodePairingRequest(bytes);
  }

  /// Authorizes a verified public identity, anchors the resulting registry in
  /// a trust checkpoint and wraps the vault master key for that identity.
  Future<DeviceKeyGrant> authorizeAndCreateGrant(DevicePairingRequest request) {
    return synchronization.withEngine((engine, device, _) async {
      var manifest = await engine.loadManifest();
      final actor = manifest.requireAuthorizedDevice(device.identity.deviceId);
      if (actor.role != DeviceRole.owner) {
        throw const SyncAuthorizationException(
          'Sólo un propietario puede autorizar dispositivos.',
        );
      }

      final existing = manifest.devices[request.identity.deviceId];
      if (existing == null) {
        manifest = await engine.authorizeDevice(request.identity);
      } else {
        if (!existing.isAuthorized) {
          throw const SyncAuthorizationException(
            'Este dispositivo ya fue revocado y no se puede reutilizar.',
          );
        }
        if (!_samePublicIdentity(existing.identity, request.identity)) {
          throw const SyncIntegrityException(
            'La identidad solicitada no coincide con el registro remoto.',
          );
        }
      }

      final registration = manifest.requireAuthorizedDevice(
        request.identity.deviceId,
      );
      if (!_samePublicIdentity(registration.identity, request.identity)) {
        throw const SyncIntegrityException(
          'La autorización publicada no coincide con la solicitud.',
        );
      }

      final masterKey = await synchronization.keyManager.exportMasterKeyBytes();
      try {
        return await engine.createDeviceKeyGrant(
          recipient: request.identity,
          masterKeyBytes: masterKey,
        );
      } finally {
        masterKey.fillRange(0, masterKey.length);
      }
    });
  }

  Future<File> exportGrant(DeviceKeyGrant grant, Directory destination) async {
    final bytes = DeviceEnrollmentPackageCodec.encodeGrant(grant);
    return AtomicFileWriter.writeStream(
      destinationDirectory: destination,
      preferredName:
          'private-sandbox-${_shortId(grant.recipientDeviceId)}.psdg',
      bytes: Stream<List<int>>.value(bytes),
      expectedLength: bytes.length,
      modifiedAt: _clock(),
    );
  }

  Future<DeviceKeyGrant> readGrant(File file) async {
    final bytes = await _readBounded(file);
    return DeviceEnrollmentPackageCodec.decodeGrant(bytes);
  }

  /// Verifies and installs a grant, then performs the receiver's first sync.
  ///
  /// The checkpoint is saved before [KeyManager.importMasterKeyBytes] by
  /// [DeviceGrantRecoveryCoordinator]. Do not reorder those calls.
  Future<SynchronizationResult> importGrantAndSynchronize(
    DeviceKeyGrant grant,
  ) async {
    final configuration = await synchronization.requireConfiguration();
    final secretStore = FlutterSecureSyncSecretStore(
      storage: synchronization.secureStorage,
    );
    final identityManager = DeviceIdentityManager(secretStore: secretStore);
    final recipient = await identityManager.loadOrCreate(
      displayName: configuration.deviceDisplayName,
    );
    late RecoveredDeviceGrant recovered;
    try {
      recovered = await DeviceKeyGrantCodec.open(
        grant: grant,
        recipient: recipient,
        now: _clock().toUtc(),
      );
    } finally {
      recipient.destroy();
    }

    await _guardExistingVault(recovered);
    late SynchronizationResult result;
    final coordinator = DeviceGrantRecoveryCoordinator(
      checkpointStore: SecureSyncTrustCheckpointStore(secretStore: secretStore),
      importMasterKey: synchronization.keyManager.importMasterKeyBytes,
      synchronize: () async {
        result = await synchronization.runWithConfiguration(configuration);
      },
    );
    try {
      await coordinator.install(recovered);
      return result;
    } finally {
      recovered.masterKeyBytes.fillRange(0, recovered.masterKeyBytes.length);
    }
  }

  Future<DeviceAdministrationSnapshot> loadAdministration() {
    return synchronization.withEngine((engine, device, _) async {
      final manifest = await engine.loadManifest();
      return DeviceAdministrationSnapshot(
        manifest: manifest,
        currentDeviceId: device.identity.deviceId,
      );
    });
  }

  Future<void> revokeDevice(String deviceId) {
    return synchronization.withEngine((engine, _, _) async {
      await engine.revokeDevice(deviceId);
    });
  }

  Future<RemoteDeviceDirective> issueDirective({
    required RemoteDirectiveType type,
    required String targetDeviceId,
  }) {
    return synchronization.withEngine((engine, _, _) {
      return engine.issueDirective(
        type: type,
        targetDeviceId: targetDeviceId,
        expiresAt: _clock().toUtc().add(const Duration(days: 7)),
      );
    });
  }

  Future<bool> acknowledgeDirective(String directiveId) {
    return synchronization.withEngine((engine, _, _) {
      return engine.acknowledgeDirective(directiveId);
    });
  }

  /// Local logout keeps the encrypted vault data, but removes this
  /// installation's synchronization identity and remote credentials.
  ///
  /// Call this only after the remote logout directive was acknowledged.
  Future<void> logoutSynchronizationIdentity() async {
    final secretStore = FlutterSecureSyncSecretStore(
      storage: synchronization.secureStorage,
    );
    await DeviceIdentityManager(secretStore: secretStore).deleteIdentity();
    await synchronization.configurationStore.clear();
  }

  Future<Uint8List> _readBounded(File file) async {
    final length = await file.length();
    if (length <= 0 || length > maximumPackageBytes) {
      throw const FormatException(
        'El paquete de dispositivo está vacío o excede 1 MiB.',
      );
    }
    return Uint8List.fromList(await file.readAsBytes());
  }

  Future<void> _guardExistingVault(RecoveredDeviceGrant recovered) async {
    if (!await synchronization.vaultRepository.hasStoredFiles()) return;
    final currentMaster = await synchronization.keyManager
        .getExistingMasterKey();
    final currentKeys = await SyncCrypto().deriveVaultKeys(currentMaster);
    if (currentKeys.vaultId != recovered.vaultId) {
      throw const SyncAuthorizationException(
        'Este dispositivo ya contiene otra bóveda. Expórtala o bórrala '
        'manualmente antes de enlazar una bóveda diferente.',
      );
    }
  }

  static bool _samePublicIdentity(DeviceIdentity left, DeviceIdentity right) {
    return left.deviceId == right.deviceId &&
        left.signingPublicKeyBase64 == right.signingPublicKeyBase64 &&
        left.exchangePublicKeyBase64 == right.exchangePublicKeyBase64;
  }

  static String _shortId(String value) {
    final normalized = value.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
    return normalized.length <= 12 ? normalized : normalized.substring(0, 12);
  }
}
