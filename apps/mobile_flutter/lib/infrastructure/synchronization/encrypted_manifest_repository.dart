// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_manifest.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../domain/synchronization/sync_transport.dart';
import 'device_identity_store.dart';
import 'sync_crypto.dart';

class StoredSyncManifest {
  final SyncManifest manifest;
  final String etag;
  final String envelopeDigest;

  const StoredSyncManifest({
    required this.manifest,
    required this.etag,
    required this.envelopeDigest,
  });
}

/// Reads and conditionally publishes the single encrypted remote manifest.
class EncryptedManifestRepository {
  final SyncTransport _transport;
  final SyncCrypto _crypto;
  final SyncVaultKeys _keys;

  EncryptedManifestRepository({
    required SyncTransport transport,
    required SyncCrypto crypto,
    required SyncVaultKeys keys,
  }) : _transport = transport,
       _crypto = crypto,
       _keys = keys;

  String get manifestDirectory => 'vaults/${_keys.vaultId}';

  String get manifestPath => '$manifestDirectory/manifest.psm';

  Future<StoredSyncManifest?> load({
    Map<String, DeviceRegistration>? trustedDevices,
    int? minimumGeneration,
  }) async {
    final metadata = await _transport.head(manifestPath);
    if (metadata == null) return null;
    final etag = metadata.etag;
    if (etag == null || etag.isEmpty) {
      throw const SyncProtocolException(
        'Remote provider must expose an ETag for manifest CAS',
      );
    }
    if (metadata.length > SyncProtocol.maximumManifestBytes) {
      throw const SyncProtocolException('Remote manifest exceeds size limit');
    }
    final read = await _transport.get(manifestPath);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in read.bytes) {
      builder.add(chunk);
      if (builder.length > SyncProtocol.maximumManifestBytes) {
        throw const SyncProtocolException('Remote manifest exceeds size limit');
      }
    }
    final envelopeBytes = builder.takeBytes();
    final envelope = _crypto.decodeEnvelope(envelopeBytes);
    final manifest = await _crypto.decryptManifest(
      envelope: envelope,
      keys: _keys,
      trustedDevices: trustedDevices,
    );
    if (minimumGeneration != null && manifest.generation < minimumGeneration) {
      throw const SyncIntegrityException(
        'Remote manifest rollback was detected',
      );
    }
    return StoredSyncManifest(
      manifest: manifest,
      etag: etag,
      envelopeDigest: _digest(envelopeBytes),
    );
  }

  Future<StoredSyncManifest> publish({
    required SyncManifest manifest,
    required DeviceCredentials signer,
    required String? expectedEtag,
  }) async {
    final envelope = await _crypto.encryptManifest(
      manifest: manifest,
      keys: _keys,
      signer: signer,
    );
    final bytes = _crypto.encodeEnvelope(envelope);
    await _transport.ensureDirectory('vaults');
    await _transport.ensureDirectory(manifestDirectory);
    final metadata = await _transport.put(
      manifestPath,
      Stream<List<int>>.value(bytes),
      length: bytes.length,
      contentType: SyncProtocol.manifestContentType,
      ifMatch: expectedEtag,
      ifNoneMatch: expectedEtag == null,
    );
    final etag = metadata.etag;
    if (etag == null || etag.isEmpty) {
      throw const SyncProtocolException(
        'Remote provider did not return an ETag after manifest write',
      );
    }
    return StoredSyncManifest(
      manifest: manifest,
      etag: etag,
      envelopeDigest: _digest(bytes),
    );
  }

  static String _digest(List<int> bytes) {
    return crypto.sha256.convert(bytes).toString();
  }
}
