// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_configuration.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_identity_store.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_key_grant.dart';
import 'package:mobile_flutter/infrastructure/synchronization/encrypted_manifest_repository.dart';
import 'package:mobile_flutter/infrastructure/synchronization/resumable_blob_transfer.dart';
import 'package:mobile_flutter/infrastructure/synchronization/sync_crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/pairing_request_codec.dart';
import '../models/stored_enrollment.dart';
import '../models/trusted_remote_state.dart';
import '../services/webdav_factory.dart';
import '../storage/companion_secure_store.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

class CompanionController extends ChangeNotifier {
  final DeviceIdentityManager _identityManager;
  final CompanionSecureStore _secureStore;
  final ApplicationSupportDirectoryProvider _applicationSupportDirectory;
  final SyncCrypto _syncCrypto;

  SyncConfiguration? _configuration;
  DeviceCredentials? _credentials;
  StoredEnrollment? _enrollment;
  StoredSyncManifest? _remoteManifest;
  bool _initialized = false;
  bool _busy = false;
  String? _errorMessage;
  String? _statusMessage;
  SyncTransferProgress? _transferProgress;
  String? _lastDownloadedPath;

  CompanionController({
    required DeviceIdentityManager identityManager,
    required CompanionSecureStore secureStore,
    ApplicationSupportDirectoryProvider? applicationSupportDirectory,
    SyncCrypto? syncCrypto,
  }) : _identityManager = identityManager,
       _secureStore = secureStore,
       _applicationSupportDirectory =
           applicationSupportDirectory ?? getApplicationSupportDirectory,
       _syncCrypto = syncCrypto ?? SyncCrypto();

  factory CompanionController.production() {
    final secrets = FlutterSecureSyncSecretStore();
    return CompanionController(
      identityManager: DeviceIdentityManager(secretStore: secrets),
      secureStore: CompanionSecureStore(secrets),
    );
  }

  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  SyncTransferProgress? get transferProgress => _transferProgress;
  String? get lastDownloadedPath => _lastDownloadedPath;
  SyncConfiguration? get configuration => _configuration;
  DeviceIdentity? get identity => _credentials?.identity;
  bool get hasMasterKey => _enrollment != null;
  String? get vaultId => _enrollment?.trust.vaultId;
  TrustedRemoteState? get trust => _enrollment?.trust;
  SyncManifest? get remoteManifest => _remoteManifest?.manifest;

  List<SyncObjectRecord> get catalog {
    final values =
        _remoteManifest?.manifest.records.values.toList() ??
        <SyncObjectRecord>[];
    values.sort((left, right) => left.logicalId.compareTo(right.logicalId));
    return values;
  }

  Future<void> initialize() async {
    if (_initialized || _busy) return;
    await _execute(() async {
      _configuration = await _secureStore.loadConfiguration();
      _credentials = await _identityManager.load();
      _enrollment = await _secureStore.loadEnrollment();
      _statusMessage = 'Companion listo.';
      _initialized = true;
    }, failurePrefix: 'No se pudo abrir el estado seguro');
  }

  Future<bool> saveConfiguration(SyncConfiguration configuration) {
    return _execute(() async {
      configuration.validate();
      await _secureStore.saveConfiguration(configuration);
      _configuration = configuration;
      _statusMessage = 'Configuración WebDAV guardada de forma segura.';
    }, failurePrefix: 'No se pudo guardar la configuración');
  }

  Future<bool> createOrLoadIdentity(String displayName) {
    return _execute(() async {
      _credentials = await _identityManager.loadOrCreate(
        displayName: displayName,
      );
      _statusMessage = 'Identidad de dispositivo disponible.';
    }, failurePrefix: 'No se pudo crear la identidad');
  }

  String createPairingRequestJson() {
    final current = identity;
    if (current == null) {
      throw StateError('Primero crea una identidad de dispositivo.');
    }
    return PairingRequestCodec.encode(current);
  }

  Future<bool> importGrantJson({
    required String serializedGrant,
    required String expectedOwnerDeviceId,
  }) {
    return _execute(() async {
      final credentials = _credentials;
      if (credentials == null) {
        throw StateError('Primero crea una identidad de dispositivo.');
      }
      final pinnedOwner = expectedOwnerDeviceId.trim().toLowerCase();
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(pinnedOwner)) {
        throw const FormatException(
          'La huella del propietario debe tener 64 caracteres hexadecimales.',
        );
      }
      final grant = DeviceKeyGrant.fromJson(
        Map<String, Object?>.from(jsonDecode(serializedGrant) as Map),
      );
      final recovered = await DeviceKeyGrantCodec.open(
        grant: grant,
        recipient: credentials,
        now: DateTime.now().toUtc(),
        expectedSenderDeviceId: pinnedOwner,
      );
      try {
        final keys = await _syncCrypto.deriveVaultKeys(
          SecretKey(recovered.masterKeyBytes),
        );
        if (keys.vaultId != recovered.vaultId) {
          throw const SyncIntegrityException(
            'La clave entregada no corresponde a la bóveda declarada.',
          );
        }
        final enrollment = StoredEnrollment(
          masterKeyBytes: recovered.masterKeyBytes,
          trust: TrustedRemoteState.fromCheckpoint(
            checkpoint: recovered.trustCheckpoint,
            ownerDeviceId: recovered.sender.deviceId,
          ),
        );
        await _secureStore.saveEnrollment(enrollment);
        _enrollment = enrollment;
        _remoteManifest = null;
        _statusMessage =
            'Grant autenticado. La clave de la bóveda quedó protegida.';
      } finally {
        recovered.masterKeyBytes.fillRange(0, recovered.masterKeyBytes.length);
      }
    }, failurePrefix: 'No se pudo importar el grant');
  }

  Future<bool> testWebDav() {
    return _execute(() async {
      final configuration = _requireConfiguration();
      final transport = WebDavFactory.create(configuration);
      try {
        await transport.ensureDirectory('vaults');
        await transport.list('vaults');
        _statusMessage = 'WebDAV HTTPS respondió correctamente.';
      } finally {
        transport.close();
      }
    }, failurePrefix: 'La prueba WebDAV falló');
  }

  Future<bool> refreshCatalog() {
    return _execute(() async {
      final configuration = _requireConfiguration();
      final enrollment = _requireEnrollment();
      final keys = await _syncCrypto.deriveVaultKeys(
        SecretKey(enrollment.masterKeyBytes),
      );
      if (keys.vaultId != enrollment.trust.vaultId) {
        throw const SyncIntegrityException(
          'La clave local ya no coincide con la bóveda inscrita.',
        );
      }
      final transport = WebDavFactory.create(configuration);
      try {
        final repository = EncryptedManifestRepository(
          transport: transport,
          crypto: _syncCrypto,
          keys: keys,
        );
        final stored = await repository.load(
          trustedDevices: enrollment.trust.trustedDevices,
          minimumGeneration: enrollment.trust.minimumGeneration,
        );
        if (stored == null) {
          throw const SyncProtocolException(
            'La bóveda todavía no tiene un manifiesto remoto.',
          );
        }
        final nextTrust = enrollment.trust.advance(
          manifest: stored.manifest,
          newEnvelopeDigest: stored.envelopeDigest,
        );
        final nextEnrollment = enrollment.withTrust(nextTrust);
        await _secureStore.saveEnrollment(nextEnrollment);
        _enrollment = nextEnrollment;
        _remoteManifest = stored;
        _statusMessage =
            'Catálogo autenticado: generación ${stored.manifest.generation}.';
      } finally {
        transport.close();
      }
    }, failurePrefix: 'No se pudo autenticar el catálogo remoto');
  }

  Future<bool> downloadEncryptedBlob(SyncBlobDescriptor descriptor) {
    return _execute(
      () async {
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(descriptor.objectId) ||
            descriptor.sha256 != descriptor.objectId) {
          throw const SyncIntegrityException(
            'El identificador del blob remoto no es seguro.',
          );
        }
        final configuration = _requireConfiguration();
        final enrollment = _requireEnrollment();
        final support = await _applicationSupportDirectory();
        final directory = Directory(
          p.join(
            support.path,
            'PrivateSandbox',
            'EncryptedRemoteCache',
            enrollment.trust.vaultId,
          ),
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final target = File(
          p.join(directory.path, '${descriptor.objectId}.psblob'),
        );
        final transport = WebDavFactory.create(configuration);
        try {
          final transfer = ResumableBlobTransfer(transport: transport);
          final downloaded = await transfer.download(
            descriptor: descriptor,
            target: target,
            onProgress: (progress) {
              _transferProgress = progress;
              notifyListeners();
            },
          );
          _lastDownloadedPath = downloaded.path;
          _statusMessage =
              'Blob cifrado descargado y verificado en el directorio privado.';
        } finally {
          transport.close();
        }
      },
      failurePrefix: 'No se pudo descargar el blob cifrado',
      clearProgressAfter: true,
    );
  }

  Future<bool> clearEnrollment() {
    return _execute(() async {
      await _secureStore.clearEnrollment();
      _enrollment = null;
      _remoteManifest = null;
      _lastDownloadedPath = null;
      _statusMessage = 'Inscripción local eliminada.';
    }, failurePrefix: 'No se pudo eliminar la inscripción');
  }

  void clearMessage() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  SyncConfiguration _requireConfiguration() {
    final value = _configuration;
    if (value == null) {
      throw StateError('Configura primero un servidor WebDAV HTTPS.');
    }
    value.validate();
    return value;
  }

  StoredEnrollment _requireEnrollment() {
    final value = _enrollment;
    if (value == null) {
      throw StateError('Importa primero un grant de clave firmado.');
    }
    return value;
  }

  Future<bool> _execute(
    Future<void> Function() operation, {
    required String failurePrefix,
    bool clearProgressAfter = false,
  }) async {
    if (_busy) return false;
    _busy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } catch (error) {
      _errorMessage = '$failurePrefix: ${_displayError(error)}';
      return false;
    } finally {
      _busy = false;
      if (clearProgressAfter) _transferProgress = null;
      notifyListeners();
    }
  }

  String _displayError(Object error) {
    if (error is SyncException) return error.message;
    if (error is FormatException) return error.message;
    if (error is StateError) return error.message;
    return error.toString();
  }

  @override
  void dispose() {
    _credentials?.destroy();
    super.dispose();
  }
}
