import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/file_category.dart';
import '../../domain/entities/import_status.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/synchronization/sync_local_store.dart';
import '../../domain/synchronization/sync_manifest.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../database/app_database.dart';
import '../encryption/stream_cipher.dart';

/// Production [LocalSyncStore] adapter for the mobile vault.
///
/// It synchronizes ciphertext blobs as-is. All names, timestamps, encryption
/// parameters and organization identifiers live only in the encrypted
/// manifest. A durable mapping row remains after permanent deletion so the
/// next run can publish an authenticated tombstone.
class DriftVaultSyncStore implements LocalSyncStore {
  static const _uuid = Uuid();
  static const _metadataSchema = 1;

  final AppDatabase database;
  final VaultRepository vaultRepository;
  final String deviceId;
  final Future<Directory> Function() blobsDirectory;

  const DriftVaultSyncStore({
    required this.database,
    required this.vaultRepository,
    required this.deviceId,
    required this.blobsDirectory,
  });

  @override
  Future<List<LocalSyncCandidate>> listPendingCandidates() async {
    final files = await (database.select(
      database.vaultFiles,
    )..where((row) => row.status.equals(ImportStatus.completed.name))).get();
    final states = await database.select(database.vaultSyncStates).get();
    final stateByLocalId = <String, VaultSyncStateRow>{
      for (final state in states) state.localFileId: state,
    };
    final existingIds = files.map((row) => row.id).toSet();
    final pending = <LocalSyncCandidate>[];

    for (final row in files) {
      final state = stateByLocalId[row.id];
      final metadata = _metadataFor(row);
      final revision = _revisionFor(metadata);
      if (state?.lastPublishedRevisionId == revision) continue;
      final vector = _vectorFrom(state?.vectorJson).increment(deviceId);
      pending.add(
        LocalSyncCandidate(
          logicalId: state?.logicalId ?? row.id,
          localRevisionId: revision,
          authorDeviceId: deviceId,
          createdAt: row.importedAt.toUtc(),
          vector: vector,
          parentVersionIds: state?.latestVersionId == null
              ? const <String>{}
              : <String>{state!.latestVersionId!},
          isTombstone: false,
          encryptedBlob: File(
            p.join(
              (await blobsDirectory()).path,
              row.encryptedFileName,
            ),
          ),
          privateMetadata: metadata,
        ),
      );
    }

    // State rows whose local records disappeared are deliberate deletion
    // candidates. Never infer tombstones for an unpublished/unknown object.
    for (final state in states) {
      if (existingIds.contains(state.localFileId) ||
          state.latestVersionId == null) {
        continue;
      }
      final revision = 'tombstone:${state.latestVersionId}';
      if (state.lastPublishedRevisionId == revision) continue;
      pending.add(
        LocalSyncCandidate(
          logicalId: state.logicalId,
          localRevisionId: revision,
          authorDeviceId: deviceId,
          createdAt:
              (state.lastPublishedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .toUtc(),
          vector: _vectorFrom(state.vectorJson).increment(deviceId),
          parentVersionIds: <String>{state.latestVersionId!},
          isTombstone: true,
          encryptedBlob: null,
          privateMetadata: const <String, Object?>{},
        ),
      );
    }
    return pending;
  }

  @override
  Future<bool> hasVersion(String logicalId, String versionId) async {
    final rows = await (database.select(
      database.vaultSyncStates,
    )..where((row) => row.logicalId.equals(logicalId))).get();
    for (final row in rows) {
      if (row.latestVersionId == versionId ||
          _knownVersions(row.knownVersionIdsJson).contains(versionId)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<File> createStagingTarget(
    String logicalId,
    SyncObjectVersion version,
  ) async {
    final blobs = await blobsDirectory();
    for (var attempt = 0; attempt < 20; attempt++) {
      final candidate = File(p.join(blobs.path, 'sync_${_uuid.v4()}.bin'));
      if (!await candidate.exists() &&
          !await File('${candidate.path}.sync.part').exists()) {
        return candidate;
      }
    }
    throw FileSystemException(
      'No se pudo reservar un destino para la descarga cifrada.',
      blobs.path,
    );
  }

  @override
  Future<void> commitRemoteVersion({
    required String logicalId,
    required SyncObjectVersion version,
    required File encryptedBlob,
    required bool isConflict,
  }) async {
    final blob = version.blob;
    if (blob == null ||
        !await encryptedBlob.exists() ||
        await encryptedBlob.length() != blob.size) {
      throw const SyncIntegrityException(
        'La descarga remota no coincide con su descriptor cifrado.',
      );
    }
    final metadata = _validatedMetadata(version.privateMetadata);
    final plainSize = (metadata['sizeBytes']! as num).toInt();
    final authenticatedChunks = plainSize == 0
        ? 0
        : (plainSize + StreamCipher.chunkSize - 1) ~/ StreamCipher.chunkSize;
    final expectedCipherSize = plainSize + authenticatedChunks * 16;
    if (blob.size != expectedCipherSize) {
      throw const SyncIntegrityException(
        'El tamaño cifrado no corresponde al tamaño original declarado.',
      );
    }
    final currentStates = await (database.select(
      database.vaultSyncStates,
    )..where((row) => row.logicalId.equals(logicalId))).get();
    VaultSyncStateRow? canonical;
    for (final state in currentStates) {
      if (!state.isConflict) {
        canonical = state;
        break;
      }
    }
    final replaceExisting = !isConflict && canonical != null;
    final localFileId = replaceExisting
        ? canonical.localFileId
        : (isConflict ? _uuid.v4() : logicalId);
    final previous = replaceExisting
        ? await vaultRepository.getById(localFileId)
        : null;
    final originalName = _safeName(metadata['originalName']! as String);
    final visibleName = isConflict
        ? _conflictName(originalName, version.authorDeviceId)
        : originalName;
    final entity = _entityFromMetadata(
      localFileId: localFileId,
      encryptedFileName: p.basename(encryptedBlob.path),
      visibleName: visibleName,
      metadata: metadata,
    );
    final revision = _revisionFor(_metadataForEntity(entity));
    final known = <String>{
      for (final state in currentStates)
        ..._knownVersions(state.knownVersionIdsJson),
      version.versionId,
    };

    await database.transaction(() async {
      if (replaceExisting) {
        await (database.delete(
          database.vaultFiles,
        )..where((row) => row.id.equals(localFileId))).go();
      }
      await vaultRepository.insertFile(entity);
      await database
          .into(database.vaultSyncStates)
          .insertOnConflictUpdate(
            VaultSyncStatesCompanion.insert(
              localFileId: localFileId,
              logicalId: logicalId,
              latestVersionId: Value(version.versionId),
              knownVersionIdsJson: Value(jsonEncode(known.toList()..sort())),
              vectorJson: Value(jsonEncode(version.vector.toJson())),
              lastPublishedRevisionId: Value(revision),
              lastPublishedAt: Value(version.createdAt.toUtc()),
              isConflict: Value(isConflict),
            ),
          );
    });

    // Publish the new DB mapping before removing superseded ciphertext. A
    // crash here leaves only an orphan that startup recovery can safely reap.
    if (previous != null &&
        previous.encryptedFileName != entity.encryptedFileName) {
      final blobs = await blobsDirectory();
      final old = File(p.join(blobs.path, previous.encryptedFileName));
      if (await old.exists()) {
        try {
          await old.delete();
        } on FileSystemException {
          // Deferred orphan cleanup is safe and idempotent.
        }
      }
    }
  }

  @override
  Future<void> recordRemoteTombstone({
    required String logicalId,
    required SyncObjectVersion tombstone,
    required bool isConflict,
  }) async {
    final states = await (database.select(
      database.vaultSyncStates,
    )..where((row) => row.logicalId.equals(logicalId))).get();
    for (final state in states) {
      final known = <String>{
        ..._knownVersions(state.knownVersionIdsJson),
        tombstone.versionId,
      };
      await (database.update(
        database.vaultSyncStates,
      )..where((row) => row.localFileId.equals(state.localFileId))).write(
        VaultSyncStatesCompanion(
          latestVersionId: Value(tombstone.versionId),
          knownVersionIdsJson: Value(jsonEncode(known.toList()..sort())),
          vectorJson: Value(jsonEncode(tombstone.vector.toJson())),
          lastPublishedAt: Value(tombstone.createdAt.toUtc()),
        ),
      );
      // A remote deletion is recoverable locally: it enters private trash,
      // never triggers immediate byte deletion.
      if (!isConflict &&
          await vaultRepository.getById(state.localFileId) != null) {
        await vaultRepository.moveToTrash(state.localFileId);
      }
    }
  }

  @override
  Future<void> acknowledgePublished({
    required String logicalId,
    required String localRevisionId,
    required SyncObjectVersion version,
  }) async {
    final states = await (database.select(
      database.vaultSyncStates,
    )..where((row) => row.logicalId.equals(logicalId))).get();
    VaultSyncStateRow? target;
    for (final state in states) {
      if (!state.isConflict) {
        target = state;
        break;
      }
    }
    final localFileId = target?.localFileId ?? logicalId;
    final known = <String>{
      if (target != null) ..._knownVersions(target.knownVersionIdsJson),
      version.versionId,
    };
    await database
        .into(database.vaultSyncStates)
        .insertOnConflictUpdate(
          VaultSyncStatesCompanion.insert(
            localFileId: localFileId,
            logicalId: logicalId,
            latestVersionId: Value(version.versionId),
            knownVersionIdsJson: Value(jsonEncode(known.toList()..sort())),
            vectorJson: Value(jsonEncode(version.vector.toJson())),
            lastPublishedRevisionId: Value(localRevisionId),
            lastPublishedAt: Value(DateTime.now().toUtc()),
            isConflict: Value(target?.isConflict ?? false),
          ),
        );
  }

  Map<String, Object?> _metadataFor(VaultFileRow row) {
    return <String, Object?>{
      'schema': _metadataSchema,
      'originalName': row.originalName,
      'extension': row.extension,
      'mimeType': row.mimeType,
      'sizeBytes': row.sizeBytes,
      'importedAt': row.importedAt.toUtc().toIso8601String(),
      if (row.fileModifiedAt != null)
        'fileModifiedAt': row.fileModifiedAt!.toUtc().toIso8601String(),
      if (row.originalCreatedAt != null)
        'originalCreatedAt': row.originalCreatedAt!.toUtc().toIso8601String(),
      if (row.originalAccessedAt != null)
        'originalAccessedAt': row.originalAccessedAt!.toUtc().toIso8601String(),
      if (row.originalMetadataJson != null)
        'originalMetadataJson': row.originalMetadataJson,
      'category': row.category,
      'fileSalt': row.fileSaltBase64,
      'noncePrefix': row.noncePrefixBase64,
      'plainSha256': row.sha256Hash,
      'originalDeleted': row.originalDeleted,
      'favorite': row.isFavorite,
      if (row.lastOpenedAt != null)
        'lastOpenedAt': row.lastOpenedAt!.toUtc().toIso8601String(),
      if (row.playbackPositionMs != null)
        'playbackPositionMs': row.playbackPositionMs,
      if (row.deletedAt != null)
        'deletedAt': row.deletedAt!.toUtc().toIso8601String(),
      if (row.folderId != null) 'folderId': row.folderId,
    };
  }

  Map<String, Object?> _metadataForEntity(VaultFile file) {
    return <String, Object?>{
      'schema': _metadataSchema,
      'originalName': file.originalName,
      'extension': file.extension,
      'mimeType': file.mimeType,
      'sizeBytes': file.sizeBytes,
      'importedAt': file.importedAt.toUtc().toIso8601String(),
      if (file.fileModifiedAt != null)
        'fileModifiedAt': file.fileModifiedAt!.toUtc().toIso8601String(),
      if (file.originalCreatedAt != null)
        'originalCreatedAt': file.originalCreatedAt!.toUtc().toIso8601String(),
      if (file.originalAccessedAt != null)
        'originalAccessedAt': file.originalAccessedAt!
            .toUtc()
            .toIso8601String(),
      if (file.originalMetadataJson != null)
        'originalMetadataJson': file.originalMetadataJson,
      'category': file.category.name,
      'fileSalt': file.fileSaltBase64,
      'noncePrefix': file.noncePrefixBase64,
      'plainSha256': file.sha256Hash,
      'originalDeleted': file.originalDeleted,
      'favorite': file.isFavorite,
      if (file.lastOpenedAt != null)
        'lastOpenedAt': file.lastOpenedAt!.toUtc().toIso8601String(),
      if (file.playbackPositionMs != null)
        'playbackPositionMs': file.playbackPositionMs,
      if (file.deletedAt != null)
        'deletedAt': file.deletedAt!.toUtc().toIso8601String(),
      if (file.folderId != null) 'folderId': file.folderId,
    };
  }

  Map<String, Object?> _validatedMetadata(Map<String, Object?> input) {
    if (input['schema'] != _metadataSchema ||
        input['originalName'] is! String ||
        input['extension'] is! String ||
        input['mimeType'] is! String ||
        input['sizeBytes'] is! num ||
        input['importedAt'] is! String ||
        input['category'] is! String ||
        input['fileSalt'] is! String ||
        input['noncePrefix'] is! String ||
        input['plainSha256'] is! String) {
      throw const SyncProtocolException(
        'Los metadatos privados remotos están incompletos.',
      );
    }
    final size = (input['sizeBytes']! as num).toInt();
    final salt = _decodeBounded(input['fileSalt']! as String, 16, 'fileSalt');
    final nonce = _decodeBounded(
      input['noncePrefix']! as String,
      8,
      'noncePrefix',
    );
    if (size < 0 ||
        salt.length != 16 ||
        nonce.length != 8 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(input['plainSha256']! as String)) {
      throw const SyncProtocolException(
        'Los metadatos criptográficos remotos no son válidos.',
      );
    }
    FileCategory.values.byName(input['category']! as String);
    DateTime.parse(input['importedAt']! as String);
    _safeName(input['originalName']! as String);
    return Map<String, Object?>.unmodifiable(input);
  }

  VaultFile _entityFromMetadata({
    required String localFileId,
    required String encryptedFileName,
    required String visibleName,
    required Map<String, Object?> metadata,
  }) {
    DateTime? optionalDate(String key) {
      final raw = metadata[key] as String?;
      return raw == null ? null : DateTime.parse(raw).toLocal();
    }

    return VaultFile(
      id: localFileId,
      originalName: visibleName,
      extension: metadata['extension']! as String,
      mimeType: metadata['mimeType']! as String,
      sizeBytes: (metadata['sizeBytes']! as num).toInt(),
      originalPath: null,
      importedAt: DateTime.parse(metadata['importedAt']! as String).toLocal(),
      fileModifiedAt: optionalDate('fileModifiedAt'),
      originalCreatedAt: optionalDate('originalCreatedAt'),
      originalAccessedAt: optionalDate('originalAccessedAt'),
      originalMetadataJson: metadata['originalMetadataJson'] as String?,
      category: FileCategory.values.byName(metadata['category']! as String),
      status: ImportStatus.completed,
      encryptedFileName: encryptedFileName,
      fileSaltBase64: metadata['fileSalt']! as String,
      noncePrefixBase64: metadata['noncePrefix']! as String,
      sha256Hash: metadata['plainSha256']! as String,
      originalDeleted: metadata['originalDeleted'] as bool? ?? true,
      isFavorite: metadata['favorite'] as bool? ?? false,
      lastOpenedAt: optionalDate('lastOpenedAt'),
      playbackPositionMs: (metadata['playbackPositionMs'] as num?)?.toInt(),
      deletedAt: optionalDate('deletedAt'),
      folderId: metadata['folderId'] as String?,
    );
  }

  String _revisionFor(Map<String, Object?> metadata) {
    return crypto.sha256
        .convert(utf8.encode(canonicalJson(metadata)))
        .toString();
  }

  VersionVector _vectorFrom(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return const VersionVector.empty();
    }
    try {
      return VersionVector.fromJson(
        Map<String, Object?>.from(jsonDecode(encoded) as Map),
      );
    } catch (error) {
      throw SyncIntegrityException(
        'El vector de sincronización local está dañado.',
        error,
      );
    }
  }

  Set<String> _knownVersions(String encoded) {
    try {
      return Set<String>.from((jsonDecode(encoded) as List).cast<String>());
    } catch (error) {
      throw SyncIntegrityException(
        'El historial local de versiones está dañado.',
        error,
      );
    }
  }

  Uint8List _decodeBounded(String value, int expected, String field) {
    if (value.length > 128) {
      throw SyncProtocolException('$field excede el tamaño permitido.');
    }
    try {
      final decoded = Uint8List.fromList(base64Decode(value));
      if (decoded.length != expected) throw const FormatException();
      return decoded;
    } on FormatException {
      throw SyncProtocolException('$field no es Base64 válido.');
    }
  }

  String _safeName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 255 ||
        trimmed.contains('/') ||
        trimmed.contains('\\') ||
        trimmed.codeUnits.any((unit) => unit < 32)) {
      throw const SyncProtocolException(
        'El nombre remoto no es seguro para el sistema local.',
      );
    }
    return trimmed;
  }

  String _conflictName(String original, String deviceId) {
    final extension = p.extension(original);
    final stem = extension.isEmpty
        ? original
        : original.substring(0, original.length - extension.length);
    return _safeName('$stem (conflicto ${deviceId.substring(0, 8)})$extension');
  }
}
