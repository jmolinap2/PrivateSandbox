import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/encryption/stream_cipher.dart';
import 'package:mobile_flutter/infrastructure/sharing/encrypted_share_package_codec.dart';

void main() {
  late Directory root;
  late Directory packages;
  late Directory temporary;
  late Directory output;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pshare-test-');
    packages = await Directory('${root.path}/packages').create();
    temporary = await Directory('${root.path}/private').create();
    output = await Directory('${root.path}/output').create();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('round-trip streams multiple chunks and keeps metadata encrypted',
      () async {
    final bytes = List<int>.generate(
      StreamCipher.chunkSize + 137,
      (index) => index % 251,
    );
    final source = File('${root.path}/source.bin');
    await source.writeAsBytes(bytes);
    final created = await EncryptedSharePackageCodec.create(
      plaintextFile: source,
      originalName: 'secreto.bin',
      mimeType: 'application/octet-stream',
      destinationDirectory: packages,
      privateTemporaryDirectory: temporary,
      lifetime: const Duration(hours: 1),
      modifiedAt: DateTime.utc(2026, 7, 1),
      now: DateTime.utc(2026, 7, 2),
    );

    final packageBytes = await created.packageFile.readAsBytes();
    expect(String.fromCharCodes(packageBytes), isNot(contains('secreto.bin')));
    expect(
      String.fromCharCodes(packageBytes),
      isNot(contains(created.capabilityKey)),
    );

    final opened = await EncryptedSharePackageCodec.open(
      packageFile: created.packageFile,
      capabilityKey: created.capabilityKey,
      destinationDirectory: output,
      privateTemporaryDirectory: temporary,
      now: DateTime.utc(2026, 7, 2, 0, 30),
    );
    expect(opened.originalName, 'secreto.bin');
    expect(opened.mimeType, 'application/octet-stream');
    expect(await opened.plaintextFile.readAsBytes(), bytes);
  });

  test('wrong capability and altered ciphertext never publish plaintext',
      () async {
    final source = File('${root.path}/source.txt');
    await source.writeAsString('contenido privado');
    final created = await EncryptedSharePackageCodec.create(
      plaintextFile: source,
      originalName: 'nota.txt',
      mimeType: 'text/plain',
      destinationDirectory: packages,
      privateTemporaryDirectory: temporary,
      lifetime: const Duration(hours: 1),
      now: DateTime.utc(2026, 7, 2),
    );
    const wrongKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    await expectLater(
      EncryptedSharePackageCodec.open(
        packageFile: created.packageFile,
        capabilityKey: wrongKey,
        destinationDirectory: output,
        privateTemporaryDirectory: temporary,
        now: DateTime.utc(2026, 7, 2, 0, 10),
      ),
      throwsA(isA<SyncIntegrityException>()),
    );
    expect(await output.list().toList(), isEmpty);

    final altered = await created.packageFile.readAsBytes();
    altered[altered.length - 1] ^= 0xff;
    await created.packageFile.writeAsBytes(altered, flush: true);
    await expectLater(
      EncryptedSharePackageCodec.open(
        packageFile: created.packageFile,
        capabilityKey: created.capabilityKey,
        destinationDirectory: output,
        privateTemporaryDirectory: temporary,
        now: DateTime.utc(2026, 7, 2, 0, 10),
      ),
      throwsA(anything),
    );
    expect(await output.list().toList(), isEmpty);
  });

  test('expired package is rejected before plaintext publication', () async {
    final source = File('${root.path}/source.txt');
    await source.writeAsString('efímero');
    final created = await EncryptedSharePackageCodec.create(
      plaintextFile: source,
      originalName: 'efimero.txt',
      mimeType: 'text/plain',
      destinationDirectory: packages,
      privateTemporaryDirectory: temporary,
      lifetime: const Duration(minutes: 5),
      now: DateTime.utc(2026, 7, 2),
    );

    await expectLater(
      EncryptedSharePackageCodec.open(
        packageFile: created.packageFile,
        capabilityKey: created.capabilityKey,
        destinationDirectory: output,
        privateTemporaryDirectory: temporary,
        now: DateTime.utc(2026, 7, 2, 0, 6),
      ),
      throwsA(isA<SyncAuthorizationException>()),
    );
    expect(await output.list().toList(), isEmpty);
  });
}
