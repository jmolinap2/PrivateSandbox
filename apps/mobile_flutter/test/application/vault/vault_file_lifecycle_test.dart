import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/application/import/active_import_registry.dart';
import 'package:mobile_flutter/application/recovery/recovery_use_case.dart';
import 'package:mobile_flutter/application/vault/vault_file_lifecycle.dart';
import 'package:mobile_flutter/domain/entities/file_category.dart';
import 'package:mobile_flutter/domain/entities/import_status.dart';
import 'package:mobile_flutter/domain/entities/vault_file.dart';
import 'package:mobile_flutter/domain/repositories/vault_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory blobs;
  late Directory playback;
  late _FakeVaultRepository repository;
  late VaultFileLifecycle lifecycle;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vault_file_lifecycle_test_');
    blobs = await Directory(p.join(root.path, 'blobs')).create();
    playback = await Directory(p.join(root.path, 'playback')).create();
    repository = _FakeVaultRepository();
    lifecycle = VaultFileLifecycle(
      repository,
      blobsDirectory: () async => blobs,
      playbackTempDirectory: () async => playback,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('keeps every artifact when the metadata deletion fails', () async {
    final file = _vaultFile();
    final blob = await File(
      p.join(blobs.path, file.encryptedFileName),
    ).writeAsBytes(List<int>.filled(20, 1));
    final thumb = await File(
      p.join(blobs.path, file.thumbnailFileName!),
    ).writeAsBytes(<int>[2]);
    repository.records[file.id] = file;
    repository.failDelete = true;

    await expectLater(
      lifecycle.deleteRecordThenArtifacts(file),
      throwsStateError,
    );

    expect(await blob.exists(), isTrue);
    expect(await thumb.exists(), isTrue);
    expect(repository.records[file.id], same(file));
  });

  test(
    'commits metadata deletion before removing blobs and plaintext temps',
    () async {
      final file = _vaultFile();
      final blob = await File(
        p.join(blobs.path, file.encryptedFileName),
      ).writeAsBytes(List<int>.filled(20, 1));
      final thumb = await File(
        p.join(blobs.path, file.thumbnailFileName!),
      ).writeAsBytes(<int>[2]);
      final playbackCopy = await File(
        p.join(playback.path, '${file.id}.txt'),
      ).writeAsBytes(<int>[3]);
      final restoreCopy = await File(
        p.join(playback.path, 'restore_${file.id}'),
      ).writeAsBytes(<int>[4]);
      repository.records[file.id] = file;
      repository.onDelete = () {
        expect(blob.existsSync(), isTrue);
        expect(thumb.existsSync(), isTrue);
      };

      final result = await lifecycle.deleteRecordThenArtifacts(file);

      expect(result.isComplete, isTrue);
      expect(repository.records.containsKey(file.id), isFalse);
      expect(await blob.exists(), isFalse);
      expect(await thumb.exists(), isFalse);
      expect(await playbackCopy.exists(), isFalse);
      expect(await restoreCopy.exists(), isFalse);
    },
  );

  test(
    'removes canonical unreferenced thumbnails and UUID orphans only',
    () async {
      final referenced = _vaultFile(withThumbnail: false);
      final orphan = _vaultFile(id: '22222222-2222-4222-8222-222222222222');
      repository.records[referenced.id] = referenced;

      final referencedBlob = await File(
        p.join(blobs.path, referenced.encryptedFileName),
      ).writeAsBytes(List<int>.filled(20, 1));
      final unreferencedThumb = await File(
        p.join(blobs.path, '${referenced.id}.thumb.bin'),
      ).writeAsBytes(<int>[2]);
      final orphanBlob = await File(
        p.join(blobs.path, orphan.encryptedFileName),
      ).writeAsBytes(<int>[3]);
      final unknown = await File(
        p.join(blobs.path, 'manual-backup.bin'),
      ).writeAsBytes(<int>[4]);

      final removed = await lifecycle.cleanupOrphanedBlobs();

      expect(removed, 2);
      expect(await referencedBlob.exists(), isTrue);
      expect(await unreferencedThumb.exists(), isFalse);
      expect(await orphanBlob.exists(), isFalse);
      expect(await unknown.exists(), isTrue);
    },
  );

  test('recognizes only a structurally complete ciphertext', () async {
    final file = _vaultFile();
    final blob = File(p.join(blobs.path, file.encryptedFileName));

    await blob.writeAsBytes(List<int>.filled(20, 1));
    expect(await lifecycle.hasCompleteCiphertext(file), isTrue);

    await blob.writeAsBytes(List<int>.filled(19, 1));
    expect(await lifecycle.hasCompleteCiphertext(file), isFalse);
  });

  test('recovery rolls back drafts but promotes verified ciphertext', () async {
    final draft = _vaultFile(status: ImportStatus.importing);
    final verified = _vaultFile(
      id: '22222222-2222-4222-8222-222222222222',
      status: ImportStatus.verified,
    ).copyWith(sha256Hash: 'verified-hash');
    repository.records[draft.id] = draft;
    repository.records[verified.id] = verified;

    final draftBlob = await File(
      p.join(blobs.path, draft.encryptedFileName),
    ).writeAsBytes(<int>[1]);
    final verifiedBlob = await File(
      p.join(blobs.path, verified.encryptedFileName),
    ).writeAsBytes(List<int>.filled(20, 2));

    final recovered = await RecoveryUseCase(
      repository,
      lifecycle: lifecycle,
    ).recoverInterruptedImports();

    expect(recovered, 2);
    expect(repository.records.containsKey(draft.id), isFalse);
    expect(await draftBlob.exists(), isFalse);
    expect(repository.records[verified.id]!.status, ImportStatus.completed);
    expect(repository.records[verified.id]!.sha256Hash, 'verified-hash');
    expect(repository.records[verified.id]!.originalDeleted, isFalse);
    expect(await verifiedBlob.exists(), isTrue);
  });

  test(
    'recovery preserves a verified record whose blob is incomplete',
    () async {
      final verified = _vaultFile(status: ImportStatus.verified);
      repository.records[verified.id] = verified;
      final partial = await File(
        p.join(blobs.path, verified.encryptedFileName),
      ).writeAsBytes(List<int>.filled(19, 1));

      final recovered = await RecoveryUseCase(
        repository,
        lifecycle: lifecycle,
      ).recoverInterruptedImports();

      expect(recovered, 0);
      expect(repository.records[verified.id]!.status, ImportStatus.verified);
      expect(await partial.exists(), isTrue);
    },
  );

  test(
    'recovery removes UUID orphans even without interrupted imports',
    () async {
      final orphan = _vaultFile();
      final orphanBlob = await File(
        p.join(blobs.path, orphan.encryptedFileName),
      ).writeAsBytes(<int>[1]);

      final recovered = await RecoveryUseCase(
        repository,
        lifecycle: lifecycle,
      ).recoverInterruptedImports();

      expect(recovered, 0);
      expect(await orphanBlob.exists(), isFalse);
    },
  );

  test(
    'recovery never rolls back an import still active in this process',
    () async {
      final active = _vaultFile(status: ImportStatus.importing);
      repository.records[active.id] = active;
      final activeBlob = await File(
        p.join(blobs.path, active.encryptedFileName),
      ).writeAsBytes(<int>[1]);
      ActiveImportRegistry.register(active.id);
      addTearDown(() => ActiveImportRegistry.unregister(active.id));

      final recovered = await RecoveryUseCase(
        repository,
        lifecycle: lifecycle,
      ).recoverInterruptedImports();

      expect(recovered, 0);
      expect(repository.records[active.id], same(active));
      expect(await activeBlob.exists(), isTrue);
    },
  );
}

VaultFile _vaultFile({
  String id = '11111111-1111-4111-8111-111111111111',
  ImportStatus status = ImportStatus.completed,
  bool withThumbnail = true,
}) {
  return VaultFile(
    id: id,
    originalName: 'archivo.txt',
    extension: 'txt',
    mimeType: 'text/plain',
    sizeBytes: 4,
    originalPath: null,
    importedAt: DateTime.utc(2026),
    fileModifiedAt: null,
    category: FileCategory.generic,
    status: status,
    encryptedFileName: '$id.bin',
    fileSaltBase64: '',
    noncePrefixBase64: '',
    sha256Hash: 'hash',
    originalDeleted: false,
    thumbnailFileName: withThumbnail ? '$id.thumb.bin' : null,
    thumbnailNoncePrefixBase64: withThumbnail ? 'nonce' : null,
  );
}

class _FakeVaultRepository implements VaultRepository {
  final records = <String, VaultFile>{};
  bool failDelete = false;
  void Function()? onDelete;

  @override
  Future<void> deleteFile(String id) async {
    onDelete?.call();
    if (failDelete) throw StateError('fallo DB inyectado');
    records.remove(id);
  }

  @override
  Future<VaultFile?> getById(String id) async => records[id];

  @override
  Future<bool> hasStoredFiles() async => records.isNotEmpty;

  @override
  Future<void> completeImport({
    required String id,
    required String sha256Hash,
    required bool originalDeleted,
  }) async {
    records[id] = records[id]!.copyWith(
      status: ImportStatus.completed,
      sha256Hash: sha256Hash,
      originalDeleted: originalDeleted,
    );
  }

  @override
  Future<List<VaultFile>> getInterruptedImports() async {
    return records.values
        .where((file) => file.status != ImportStatus.completed)
        .toList();
  }

  @override
  Future<void> insertFile(VaultFile file) async {
    records[file.id] = file;
  }

  @override
  Future<void> markImportVerified({
    required String id,
    required String sha256Hash,
  }) async {
    records[id] = records[id]!.copyWith(
      status: ImportStatus.verified,
      sha256Hash: sha256Hash,
    );
  }

  @override
  Future<void> moveFileToFolder(String id, String? folderId) async {}

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> recordOpened(String id, {int? playbackPositionMs}) async {}

  @override
  Future<void> restoreFromTrash(String id) async {}

  @override
  Future<void> setFavorite(String id, bool isFavorite) async {}

  @override
  Future<void> setThumbnail(
    String id, {
    required String fileName,
    required String noncePrefixBase64,
  }) async {}

  @override
  Stream<List<VaultFile>> watchFiles() => const Stream.empty();

  @override
  Stream<List<VaultFile>> watchFilesInFolder(String? folderId) =>
      const Stream.empty();

  @override
  Stream<List<VaultFile>> watchTrashedFiles() => const Stream.empty();
}
