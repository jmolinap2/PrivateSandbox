import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/entities/file_category.dart';
import 'package:mobile_flutter/domain/entities/import_status.dart';
import 'package:mobile_flutter/domain/entities/vault_file.dart';
import 'package:mobile_flutter/domain/synchronization/sync_manifest.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/database/app_database.dart';
import 'package:mobile_flutter/infrastructure/database/vault_repository_impl.dart';
import 'package:mobile_flutter/infrastructure/synchronization/drift_vault_sync_store.dart';

void main() {
  late AppDatabase database;
  late VaultRepositoryImpl repository;
  late Directory blobs;
  late DriftVaultSyncStore store;

  setUp(() async {
    database = AppDatabase.withExecutor(NativeDatabase.memory());
    repository = VaultRepositoryImpl(database);
    blobs = await Directory.systemTemp.createTemp('ps-sync-store-test-');
    store = DriftVaultSyncStore(
      database: database,
      vaultRepository: repository,
      deviceId: 'device-a',
      blobsDirectory: () async => blobs,
    );
  });

  tearDown(() async {
    await database.close();
    if (await blobs.exists()) await blobs.delete(recursive: true);
  });

  test(
    'acknowledged local revision is idempotent and deletion becomes tombstone',
    () async {
      final blob = File('${blobs.path}/file-a.bin');
      await blob.writeAsBytes(List<int>.generate(48, (index) => index));
      await repository.insertFile(_file(id: 'file-a', blobName: 'file-a.bin'));

      final first = await store.listPendingCandidates();
      expect(first, hasLength(1));
      expect(first.single.isTombstone, isFalse);
      expect(first.single.privateMetadata['originalName'], 'foto.jpg');

      final descriptor = _descriptor(blob);
      final version = SyncObjectVersion.create(
        authorDeviceId: 'device-a',
        createdAt: first.single.createdAt,
        vector: first.single.vector,
        parentVersionIds: const <String>{},
        isTombstone: false,
        blob: await descriptor,
        privateMetadata: first.single.privateMetadata,
      );
      await store.acknowledgePublished(
        logicalId: first.single.logicalId,
        localRevisionId: first.single.localRevisionId,
        version: version,
      );
      expect(await store.listPendingCandidates(), isEmpty);

      await repository.deleteFile('file-a');
      final afterDelete = await store.listPendingCandidates();
      expect(afterDelete, hasLength(1));
      expect(afterDelete.single.isTombstone, isTrue);
      expect(afterDelete.single.parentVersionIds, contains(version.versionId));
    },
  );

  test(
    'commits a verified remote ciphertext without losing private metadata',
    () async {
      final source = File('${blobs.path}/source.bin');
    await source.writeAsBytes(List<int>.generate(48, (index) => 255 - index));
      final descriptor = await _descriptor(source);
      final metadata = <String, Object?>{
        'schema': 1,
        'originalName': 'remoto.pdf',
        'extension': 'pdf',
        'mimeType': 'application/pdf',
        'sizeBytes': 32,
        'importedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      'category': FileCategory.pdf.name,
        'fileSalt': 'AAAAAAAAAAAAAAAAAAAAAA==',
        'noncePrefix': 'AAAAAAAAAAA=',
        'plainSha256': List<String>.filled(64, 'a').join(),
        'originalDeleted': true,
        'favorite': true,
      };
      final version = SyncObjectVersion.create(
        authorDeviceId: 'device-b',
        createdAt: DateTime.utc(2026, 7, 2),
        vector: VersionVector(const <String, int>{'device-b': 1}),
        parentVersionIds: const <String>{},
        isTombstone: false,
        blob: descriptor,
        privateMetadata: metadata,
      );

      await store.commitRemoteVersion(
        logicalId: 'remote-logical-id',
        version: version,
        encryptedBlob: source,
        isConflict: false,
      );

      final imported = await repository.getById('remote-logical-id');
      expect(imported, isNotNull);
      expect(imported!.originalName, 'remoto.pdf');
    expect(imported.category, FileCategory.pdf);
      expect(imported.isFavorite, isTrue);
      expect(
        await store.hasVersion('remote-logical-id', version.versionId),
        isTrue,
      );
      expect(await store.listPendingCandidates(), isEmpty);
    },
  );

  test(
    'rejects traversal-like names even inside an authenticated manifest',
    () async {
      final source = File('${blobs.path}/hostile.bin');
      await source.writeAsBytes(List<int>.filled(32, 7));
      final descriptor = await _descriptor(source);
      final version = SyncObjectVersion.create(
        authorDeviceId: 'device-b',
        createdAt: DateTime.utc(2026, 7, 2),
        vector: VersionVector(const <String, int>{'device-b': 1}),
        parentVersionIds: const <String>{},
        isTombstone: false,
        blob: descriptor,
        privateMetadata: <String, Object?>{
          'schema': 1,
          'originalName': '../escape.jpg',
          'extension': 'jpg',
          'mimeType': 'image/jpeg',
          'sizeBytes': 16,
          'importedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
          'category': FileCategory.image.name,
          'fileSalt': 'AAAAAAAAAAAAAAAAAAAAAA==',
          'noncePrefix': 'AAAAAAAAAAA=',
          'plainSha256': List<String>.filled(64, 'b').join(),
        },
      );

      await expectLater(
        store.commitRemoteVersion(
          logicalId: 'hostile',
          version: version,
          encryptedBlob: source,
          isConflict: false,
        ),
        throwsA(isA<SyncProtocolException>()),
      );
    },
  );
}

VaultFile _file({required String id, required String blobName}) {
  return VaultFile(
    id: id,
    originalName: 'foto.jpg',
    extension: 'jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 16,
    originalPath: null,
    importedAt: DateTime.utc(2026, 7, 1),
    fileModifiedAt: DateTime.utc(2026, 6, 30),
    category: FileCategory.image,
    status: ImportStatus.completed,
    encryptedFileName: blobName,
    fileSaltBase64: 'AAAAAAAAAAAAAAAAAAAAAA==',
    noncePrefixBase64: 'AAAAAAAAAAA=',
    sha256Hash: List<String>.filled(64, 'c').join(),
    originalDeleted: true,
  );
}

Future<SyncBlobDescriptor> _descriptor(File file) async {
  final bytes = await file.readAsBytes();
  final hash = crypto.sha256.convert(bytes).toString();
  return SyncBlobDescriptor(
    objectId: hash,
    size: bytes.length,
    sha256: hash,
    chunkSize: bytes.length,
    chunks: <SyncBlobChunk>[
      SyncBlobChunk(
        index: 0,
        path: 'vaults/test/objects/$hash/chunks/00000000-$hash.bin',
        size: bytes.length,
        sha256: hash,
      ),
    ],
  );
}
