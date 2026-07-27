import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/infrastructure/storage/atomic_file_writer.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('atomic_file_writer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('publishes complete bytes without replacing an existing file', () async {
    final existing = File(p.join(tempDir.path, 'informe.txt'));
    await existing.writeAsString('contenido anterior');

    final result = await AtomicFileWriter.writeStream(
      destinationDirectory: tempDir,
      preferredName: 'informe.txt',
      bytes: Stream<List<int>>.value(<int>[1, 2, 3, 4]),
      expectedLength: 4,
    );

    expect(await existing.readAsString(), 'contenido anterior');
    expect(p.basename(result.path), 'informe (1).txt');
    expect(await result.readAsBytes(), <int>[1, 2, 3, 4]);
  });

  test('removes the partial when the source stream fails', () async {
    Stream<List<int>> failingBytes() async* {
      yield <int>[1, 2];
      throw StateError('fallo inyectado');
    }

    await expectLater(
      AtomicFileWriter.writeStream(
        destinationDirectory: tempDir,
        preferredName: 'fallido.bin',
        bytes: failingBytes(),
        expectedLength: 4,
      ),
      throwsStateError,
    );

    final names = await tempDir
        .list()
        .map((entity) => p.basename(entity.path))
        .toList();
    expect(names, isEmpty);
  });

  test('does not publish a stream with an unexpected length', () async {
    await expectLater(
      AtomicFileWriter.writeStream(
        destinationDirectory: tempDir,
        preferredName: 'truncado.bin',
        bytes: Stream<List<int>>.value(<int>[1, 2]),
        expectedLength: 3,
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(await tempDir.list().toList(), isEmpty);
  });

  test(
    'sanitizes path separators instead of escaping the destination',
    () async {
      final result = await AtomicFileWriter.writeStream(
        destinationDirectory: tempDir,
        preferredName: '../subdir\\secreto.txt',
        bytes: Stream<List<int>>.value(<int>[7]),
        expectedLength: 1,
      );

      expect(p.dirname(result.path), tempDir.path);
      expect(p.basename(result.path), '.._subdir_secreto.txt');
    },
  );
}
