import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/infrastructure/backup/vault_restore_recovery.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory supportDirectory;
  late String oldFingerprint;
  late String newFingerprint;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'vault_restore_recovery_',
    );
    oldFingerprint = VaultRestoreRecovery.fingerprint(
      Uint8List.fromList(List<int>.filled(32, 1)),
    );
    newFingerprint = VaultRestoreRecovery.fingerprint(
      Uint8List.fromList(List<int>.filled(32, 2)),
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test(
    'clave anterior restaura DB/blobs y la recuperación es idempotente',
    () async {
      const operationId = 'rollback_case';
      final fixture = await _prepareInstalledNewVault(
        supportDirectory,
        operationId: operationId,
        oldFingerprint: oldFingerprint,
        newFingerprint: newFingerprint,
      );
      final keyMarker = File(
        p.join(supportDirectory.path, VaultRestoreRecovery.keyMarkerFileName),
      );
      await keyMarker.writeAsString(newFingerprint, flush: true);

      final recovered = await VaultRestoreRecovery.recoverAll(
        supportDirectory: supportDirectory,
        readStoredKeyFingerprint: () async => oldFingerprint,
      );
      expect(recovered, 1);
      expect(await fixture.liveDb.readAsString(), 'old-db');
      expect(
        await File('${fixture.liveDb.path}-wal').readAsString(),
        'old-wal',
      );
      expect(
        await File(p.join(fixture.liveBlobs.path, 'old.bin')).readAsString(),
        'old-blob',
      );
      expect(await fixture.rollbackDirectory.exists(), isFalse);
      expect(await fixture.stagingDirectory.exists(), isFalse);
      expect(await keyMarker.readAsString(), oldFingerprint);

      var keyReaderCalled = false;
      final repeated = await VaultRestoreRecovery.recoverAll(
        supportDirectory: supportDirectory,
        readStoredKeyFingerprint: () async {
          keyReaderCalled = true;
          return oldFingerprint;
        },
      );
      expect(repeated, 0);
      expect(keyReaderCalled, isFalse);
      expect(await fixture.liveDb.readAsString(), 'old-db');
    },
  );

  test(
    'clave restaurada conserva la bóveda nueva y elimina rollback',
    () async {
      const operationId = 'commit_case';
      final fixture = await _prepareInstalledNewVault(
        supportDirectory,
        operationId: operationId,
        oldFingerprint: oldFingerprint,
        newFingerprint: newFingerprint,
      );
      final keyMarker = File(
        p.join(supportDirectory.path, VaultRestoreRecovery.keyMarkerFileName),
      );
      await keyMarker.writeAsString(oldFingerprint, flush: true);
      await fixture.journal.markKeyInstalled();

      final recovered = await VaultRestoreRecovery.recoverAll(
        supportDirectory: supportDirectory,
        readStoredKeyFingerprint: () async => newFingerprint,
      );
      expect(recovered, 1);
      expect(await fixture.liveDb.readAsString(), 'new-db');
      expect(
        await File(p.join(fixture.liveBlobs.path, 'new.bin')).readAsString(),
        'new-blob',
      );
      expect(
        await File(p.join(fixture.liveBlobs.path, 'old.bin')).exists(),
        isFalse,
      );
      expect(await fixture.rollbackDirectory.exists(), isFalse);
      expect(await fixture.stagingDirectory.exists(), isFalse);
      expect(await keyMarker.readAsString(), newFingerprint);
    },
  );

  test(
    'staging anterior al swap se limpia sin consultar Secure Storage',
    () async {
      final orphan = VaultRestoreRecovery.stagingDirectory(
        supportDirectory,
        'orphan_case',
      );
      await orphan.create();
      await File(p.join(orphan.path, 'vault.sqlite')).writeAsString('staged');

      var keyReaderCalled = false;
      final recovered = await VaultRestoreRecovery.recoverAll(
        supportDirectory: supportDirectory,
        readStoredKeyFingerprint: () async {
          keyReaderCalled = true;
          return null;
        },
      );
      expect(recovered, 0);
      expect(keyReaderCalled, isFalse);
      expect(await orphan.exists(), isFalse);
    },
  );
}

Future<_RestoreFixture> _prepareInstalledNewVault(
  Directory supportDirectory, {
  required String operationId,
  required String oldFingerprint,
  required String newFingerprint,
}) async {
  final liveDb = File(p.join(supportDirectory.path, 'vault.sqlite'));
  final liveWal = File('${liveDb.path}-wal');
  final liveBlobs = Directory(p.join(supportDirectory.path, 'vault_blobs'));
  await liveDb.writeAsString('old-db', flush: true);
  await liveWal.writeAsString('old-wal', flush: true);
  await liveBlobs.create();
  await File(
    p.join(liveBlobs.path, 'old.bin'),
  ).writeAsString('old-blob', flush: true);

  final staging = VaultRestoreRecovery.stagingDirectory(
    supportDirectory,
    operationId,
  );
  final stagedBlobs = Directory(p.join(staging.path, 'blobs'));
  await stagedBlobs.create(recursive: true);
  final stagedDb = File(p.join(staging.path, 'vault.sqlite'));
  await stagedDb.writeAsString('new-db', flush: true);
  await File(
    p.join(stagedBlobs.path, 'new.bin'),
  ).writeAsString('new-blob', flush: true);

  final journal = await VaultRestoreRecovery.begin(
    supportDirectory: supportDirectory,
    operationId: operationId,
    oldKeyFingerprint: oldFingerprint,
    newKeyFingerprint: newFingerprint,
  );
  await liveDb.rename(p.join(journal.rollbackDirectory.path, 'vault.sqlite'));
  await liveWal.rename(
    p.join(journal.rollbackDirectory.path, 'vault.sqlite-wal'),
  );
  await liveBlobs.rename(p.join(journal.rollbackDirectory.path, 'vault_blobs'));
  await journal.markOldMoved();
  await stagedDb.rename(liveDb.path);
  await stagedBlobs.rename(liveBlobs.path);
  await journal.markNewInstalled();

  return _RestoreFixture(
    journal: journal,
    liveDb: liveDb,
    liveBlobs: liveBlobs,
    stagingDirectory: staging,
    rollbackDirectory: journal.rollbackDirectory,
  );
}

class _RestoreFixture {
  final VaultRestoreJournalHandle journal;
  final File liveDb;
  final Directory liveBlobs;
  final Directory stagingDirectory;
  final Directory rollbackDirectory;

  const _RestoreFixture({
    required this.journal,
    required this.liveDb,
    required this.liveBlobs,
    required this.stagingDirectory,
    required this.rollbackDirectory,
  });
}
