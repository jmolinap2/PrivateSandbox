import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/application/import/import_progress.dart';
import 'package:mobile_flutter/application/import/import_use_case.dart';
import 'package:mobile_flutter/application/import/picked_file.dart';
import 'package:mobile_flutter/application/thumbnails/thumbnail_use_case.dart';
import 'package:mobile_flutter/domain/entities/activity_event.dart';
import 'package:mobile_flutter/domain/entities/file_category.dart';
import 'package:mobile_flutter/domain/entities/import_status.dart';
import 'package:mobile_flutter/domain/entities/vault_file.dart';
import 'package:mobile_flutter/domain/repositories/activity_repository.dart';
import 'package:mobile_flutter/domain/repositories/vault_repository.dart';
import 'package:mobile_flutter/infrastructure/encryption/key_manager.dart';
import 'package:mobile_flutter/infrastructure/platform/original_location_channel.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory blobs;
  late Directory playback;
  late File source;
  late _FakeVaultRepository repository;
  late _FakeKeyManager keyManager;
  late _FakeActivityRepository activities;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('import_use_case_test_');
    blobs = await Directory(p.join(root.path, 'blobs')).create();
    playback = await Directory(p.join(root.path, 'playback')).create();
    source = await File(
      p.join(root.path, 'original.txt'),
    ).writeAsString('contenido');
    repository = _FakeVaultRepository();
    keyManager = _FakeKeyManager();
    activities = _FakeActivityRepository();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ImportUseCase buildUseCase(OriginalFileDeleter deleter) {
    return ImportUseCase(
      repository,
      keyManager,
      OriginalLocationChannel(),
      _NoThumbnailUseCase(keyManager),
      activities,
      blobsDirectory: () async => blobs,
      playbackTempDirectory: () async => playback,
      originalFileDeleter: deleter,
    );
  }

  PickedFile pickedFile() {
    return PickedFile(
      path: source.path,
      name: 'original.txt',
      size: source.lengthSync(),
    );
  }

  test(
    'durably verifies the vault copy before deleting the original',
    () async {
      final useCase = buildUseCase((_, readableFile) async {
        repository.events.add('delete-original');
        final record = repository.records[repository.lastInsertedId];
        expect(record?.status, ImportStatus.verified);
        expect(await readableFile.exists(), isTrue);
        return true;
      });

      final progress = await useCase
          .call(pickedFile: pickedFile(), deleteOriginal: true)
          .toList();

      expect(repository.events, <String>[
        'insert',
        'verified',
        'delete-original',
        'completed',
      ]);
      expect(progress.last.stage, ImportStage.done);
      final stored = repository.records[repository.lastInsertedId]!;
      expect(stored.status, ImportStatus.completed);
      expect(stored.originalDeleted, isTrue);
      expect(stored.sha256Hash, isNotEmpty);

      final metadata =
          jsonDecode(stored.originalMetadataJson!) as Map<String, dynamic>;
      expect(metadata['schemaVersion'], 1);
      expect(
        (metadata['fileStat'] as Map<String, dynamic>)['modifiedAt'],
        isNotNull,
      );
    },
  );

  test(
    'a failure after source deletion preserves and completes the verified copy',
    () async {
      repository.completeFailuresRemaining = 1;
      final useCase = buildUseCase((_, _) async {
        repository.events.add('delete-original');
        return true;
      });

      final progress = await useCase
          .call(pickedFile: pickedFile(), deleteOriginal: true)
          .toList();

      final stored = repository.records[repository.lastInsertedId]!;
      expect(progress.last.stage, ImportStage.done);
      expect(stored.status, ImportStatus.completed);
      // The retry cannot prove whether the external delete committed, so it
      // records the conservative value while keeping all bytes recoverable.
      expect(stored.originalDeleted, isFalse);
      expect(
        await File(p.join(blobs.path, stored.encryptedFileName)).exists(),
        isTrue,
      );
    },
  );

  test(
    'a failure before verification rolls back without touching the source',
    () async {
      repository.failMarkVerified = true;
      var deleteOriginalCalled = false;
      final useCase = buildUseCase((_, _) async {
        deleteOriginalCalled = true;
        return true;
      });

      await expectLater(
        useCase
            .call(pickedFile: pickedFile(), deleteOriginal: true)
            .drain<void>(),
        throwsStateError,
      );

      expect(deleteOriginalCalled, isFalse);
      expect(await source.exists(), isTrue);
      expect(repository.records, isEmpty);
      expect(await blobs.list().toList(), isEmpty);
    },
  );

  test('cancelling the progress subscription rolls back the draft', () async {
    final useCase = buildUseCase((_, _) async => true);
    final iterator = StreamIterator(
      useCase.call(pickedFile: pickedFile(), deleteOriginal: false),
    );

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.stage, ImportStage.encrypting);
    await iterator.cancel();

    expect(repository.records, isEmpty);
    expect(await blobs.list().toList(), isEmpty);
    expect(await source.exists(), isTrue);
  });
}

class _FakeKeyManager extends KeyManager {
  final SecretKey _key = SecretKey(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateMasterKey() async => _key;

  @override
  Future<SecretKey> deriveFileKey(
    SecretKey masterKey,
    Uint8List fileSalt,
  ) async => _key;

  @override
  Future<SecretKey> deriveThumbnailKey(
    SecretKey masterKey,
    Uint8List fileSalt,
  ) async => _key;
}

class _NoThumbnailUseCase extends ThumbnailUseCase {
  _NoThumbnailUseCase(KeyManager keyManager)
    : super(keyManager, OriginalLocationChannel());

  @override
  Future<GeneratedThumbnail?> generateAndStore({
    required File sourceFile,
    required FileCategory category,
    required String id,
    required SecretKey masterKey,
    required Uint8List fileSalt,
  }) async {
    return null;
  }
}

class _FakeActivityRepository implements ActivityRepository {
  final events = <ActivityEvent>[];

  @override
  Future<void> logEvent(ActivityEvent event) async {
    events.add(event);
  }

  @override
  Stream<List<ActivityEvent>> watchEvents() => Stream.value(events);
}

class _FakeVaultRepository implements VaultRepository {
  final records = <String, VaultFile>{};
  final events = <String>[];
  late String lastInsertedId;
  bool failMarkVerified = false;
  int completeFailuresRemaining = 0;

  @override
  Future<void> insertFile(VaultFile file) async {
    lastInsertedId = file.id;
    records[file.id] = file;
    events.add('insert');
  }

  @override
  Future<void> markImportVerified({
    required String id,
    required String sha256Hash,
  }) async {
    if (failMarkVerified) throw StateError('fallo verified inyectado');
    records[id] = records[id]!.copyWith(
      status: ImportStatus.verified,
      sha256Hash: sha256Hash,
    );
    events.add('verified');
  }

  @override
  Future<void> completeImport({
    required String id,
    required String sha256Hash,
    required bool originalDeleted,
  }) async {
    if (completeFailuresRemaining > 0) {
      completeFailuresRemaining--;
      throw StateError('fallo complete inyectado');
    }
    records[id] = records[id]!.copyWith(
      status: ImportStatus.completed,
      sha256Hash: sha256Hash,
      originalDeleted: originalDeleted,
    );
    events.add('completed');
  }

  @override
  Future<void> deleteFile(String id) async {
    records.remove(id);
    events.add('delete-record');
  }

  @override
  Future<VaultFile?> getById(String id) async => records[id];

  @override
  Future<bool> hasStoredFiles() async => records.isNotEmpty;

  @override
  Future<List<VaultFile>> getInterruptedImports() async {
    return records.values
        .where((file) => file.status != ImportStatus.completed)
        .toList();
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
