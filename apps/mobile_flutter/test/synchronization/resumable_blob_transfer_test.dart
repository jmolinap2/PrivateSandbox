import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/synchronization/in_memory_sync_transport.dart';
import 'package:mobile_flutter/infrastructure/synchronization/resumable_blob_transfer.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('private-sandbox-sync-');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('upload resumes without re-uploading verified chunks', () async {
    var uploadAttempt = 0;
    var injectFailure = true;
    final transport = InMemorySyncTransport(
      beforePut: (path, length) {
        if (!path.endsWith('.bin')) return;
        uploadAttempt++;
        if (injectFailure && uploadAttempt == 4) {
          throw const SyncTransportException('simulated disconnect');
        }
      },
    );
    final transfer = ResumableBlobTransfer(
      transport: transport,
      chunkSize: 1024,
    );
    final bytes = _bytes(10 * 1024 + 123);
    final source = File('${temp.path}/source.bin');
    await source.writeAsBytes(bytes);

    await expectLater(
      transfer.upload(vaultId: 'vault', encryptedFile: source),
      throwsA(isA<SyncTransportException>()),
    );
    expect(transport.putCount, 3);

    injectFailure = false;
    final descriptor = await transfer.upload(
      vaultId: 'vault',
      encryptedFile: source,
    );

    expect(transport.putCount, descriptor.chunks.length);
    expect(descriptor.size, bytes.length);
  });

  test('download resumes from validated local chunk boundary', () async {
    final transport = InMemorySyncTransport();
    final transfer = ResumableBlobTransfer(
      transport: transport,
      chunkSize: 512,
    );
    final bytes = _bytes(4096 + 17);
    final source = File('${temp.path}/source.bin');
    await source.writeAsBytes(bytes);
    final descriptor = await transfer.upload(
      vaultId: 'vault',
      encryptedFile: source,
    );
    var cancel = false;
    final target = File('${temp.path}/download.bin');

    await expectLater(
      transfer.download(
        descriptor: descriptor,
        target: target,
        isCancelled: () => cancel,
        onProgress: (progress) {
          if (progress.completedChunks == 2) cancel = true;
        },
      ),
      throwsA(isA<SyncCancelledException>()),
    );
    final partial = File('${target.path}.sync.part');
    expect(await partial.length(), 1024);

    final downloaded = await transfer.download(
      descriptor: descriptor,
      target: target,
    );
    expect(await downloaded.readAsBytes(), bytes);
    expect(await partial.exists(), isFalse);
  });

  test(
    'corrupted remote chunk is rejected without committing target',
    () async {
      final transport = InMemorySyncTransport();
      final transfer = ResumableBlobTransfer(
        transport: transport,
        chunkSize: 1024,
      );
      final source = File('${temp.path}/source.bin');
      await source.writeAsBytes(_bytes(2048));
      final descriptor = await transfer.upload(
        vaultId: 'vault',
        encryptedFile: source,
      );
      transport.corrupt(descriptor.chunks.first.path, 0);
      final target = File('${temp.path}/corrupt.bin');

      await expectLater(
        transfer.download(descriptor: descriptor, target: target),
        throwsA(isA<SyncIntegrityException>()),
      );
      expect(await target.exists(), isFalse);
    },
  );
}

Uint8List _bytes(int length) {
  return Uint8List.fromList(
    List<int>.generate(length, (index) => (index * 31 + 17) & 0xff),
  );
}
