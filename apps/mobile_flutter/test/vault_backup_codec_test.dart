import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/infrastructure/backup/backup_key_wrapper.dart';
import 'package:mobile_flutter/infrastructure/backup/vault_backup_codec.dart';

void main() {
  late Directory suiteDir;
  late File sourceDb;
  late File sourceBlob;
  late File validBackup;
  late Uint8List masterKey;
  late Uint8List dbBytes;
  late Uint8List blobBytes;
  late BackupKeyEnvelope envelope;

  setUpAll(() async {
    suiteDir = await Directory.systemTemp.createTemp('psvb2_codec_test_');
    final sourceDir = Directory(
      '${suiteDir.path}${Platform.pathSeparator}source',
    );
    await sourceDir.create();

    dbBytes = Uint8List.fromList([
      ...utf8.encode('SQLite format 3\u0000'),
      ...List<int>.filled(64, 0),
      ...utf8.encode('nombre-y-ruta-super-secretos.db'),
    ]);
    blobBytes = Uint8List.fromList([
      ...utf8.encode('BLOB-PLAINTEXT-SENTINEL:'),
      ...List<int>.generate(
        VaultBackupCodec.chunkSize + 257,
        (index) => index % 251,
      ),
    ]);
    sourceDb = File('${sourceDir.path}${Platform.pathSeparator}vault.sqlite');
    sourceBlob = File('${sourceDir.path}${Platform.pathSeparator}abc-123.bin');
    await sourceDb.writeAsBytes(dbBytes, flush: true);
    await sourceBlob.writeAsBytes(blobBytes, flush: true);

    masterKey = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    envelope = await BackupKeyWrapper.wrap(
      password: 'contraseña correcta',
      masterKeyBytes: masterKey,
    );
    validBackup = File('${suiteDir.path}${Platform.pathSeparator}valid.psvb');
    await VaultBackupCodec.write(
      destination: validBackup,
      createdAt: DateTime.utc(2026, 7, 26, 12, 30),
      databaseSchemaVersion: 8,
      keyEnvelope: envelope,
      masterKeyBytes: masterKey,
      dbFile: sourceDb,
      blobFiles: [sourceBlob],
    );
  });

  tearDownAll(() async {
    if (await suiteDir.exists()) {
      await suiteDir.delete(recursive: true);
    }
  });

  test(
    'round-trip cifra metadatos, DB y blobs y recupera bytes exactos',
    () async {
      final backupBytes = await validBackup.readAsBytes();
      expect(
        _containsSubsequence(backupBytes, utf8.encode('vault.sqlite')),
        isFalse,
      );
      expect(
        _containsSubsequence(
          backupBytes,
          utf8.encode('nombre-y-ruta-super-secretos.db'),
        ),
        isFalse,
      );
      expect(
        _containsSubsequence(
          backupBytes,
          utf8.encode('BLOB-PLAINTEXT-SENTINEL:'),
        ),
        isFalse,
      );

      final header = await VaultBackupCodec.readHeader(validBackup);
      final unwrapped = await BackupKeyWrapper.unwrap(
        password: 'contraseña correcta',
        envelope: header.keyEnvelope,
      );
      expect(unwrapped, orderedEquals(masterKey));

      final privateManifest = await VaultBackupCodec.readPayloadManifest(
        source: validBackup,
        header: header,
        masterKeyBytes: unwrapped!,
      );
      expect(privateManifest.databaseSchemaVersion, 8);
      expect(privateManifest.dbFile.name, 'vault.sqlite');
      expect(privateManifest.blobFiles.single.name, 'abc-123.bin');

      final output = Directory(
        '${suiteDir.path}${Platform.pathSeparator}roundtrip',
      );
      final extracted = await VaultBackupCodec.extract(
        source: validBackup,
        header: header,
        masterKeyBytes: unwrapped,
        outputDir: output,
      );
      expect(extracted.totalPlaintextSize, dbBytes.length + blobBytes.length);
      expect(
        await File(
          '${output.path}${Platform.pathSeparator}vault.sqlite',
        ).readAsBytes(),
        orderedEquals(dbBytes),
      );
      expect(
        await File(
          '${output.path}${Platform.pathSeparator}blobs'
          '${Platform.pathSeparator}abc-123.bin',
        ).readAsBytes(),
        orderedEquals(blobBytes),
      );
    },
  );

  test(
    'contraseña incorrecta no revela la clave ni permite extracción',
    () async {
      final header = await VaultBackupCodec.readHeader(validBackup);
      final unwrapped = await BackupKeyWrapper.unwrap(
        password: 'contraseña equivocada',
        envelope: header.keyEnvelope,
      );
      expect(unwrapped, isNull);

      final wrongKey = Uint8List.fromList(List<int>.filled(32, 7));
      expect(
        () => VaultBackupCodec.readPayloadManifest(
          source: validBackup,
          header: header,
          masterKeyBytes: wrongKey,
        ),
        throwsA(isA<VaultBackupAuthenticationException>()),
      );
    },
  );

  test(
    'corrupción de payload se detecta y limpia archivos parciales',
    () async {
      final bytes = Uint8List.fromList(await validBackup.readAsBytes());
      final payloadOffset = _payloadOffset(bytes);
      final dbRecordLength = 12 + dbBytes.length + 16;
      bytes[payloadOffset + dbRecordLength + 12 + 3] ^= 0x40;

      final corrupt = File(
        '${suiteDir.path}${Platform.pathSeparator}corrupt-payload.psvb',
      );
      await corrupt.writeAsBytes(bytes, flush: true);
      final header = await VaultBackupCodec.readHeader(corrupt);
      final output = Directory(
        '${suiteDir.path}${Platform.pathSeparator}corrupt-output',
      );

      expect(
        () => VaultBackupCodec.extract(
          source: corrupt,
          header: header,
          masterKeyBytes: masterKey,
          outputDir: output,
        ),
        throwsA(isA<VaultBackupAuthenticationException>()),
      );
      expect(
        await File(
          '${output.path}${Platform.pathSeparator}vault.sqlite',
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          '${output.path}${Platform.pathSeparator}blobs'
          '${Platform.pathSeparator}abc-123.bin.partial',
        ).exists(),
        isFalse,
      );
    },
  );

  test(
    'corrupción del manifiesto cifrado se detecta antes de extraer',
    () async {
      final bytes = await validBackup.readAsBytes();
      final headerLength = _uint32(bytes, 5);
      final headerJson =
          jsonDecode(utf8.decode(bytes.sublist(9, 9 + headerLength)))
              as Map<String, dynamic>;
      final encryptedManifest =
          headerJson['encryptedManifest'] as Map<String, dynamic>;
      final cipher = encryptedManifest['cipherTextBase64'] as String;
      encryptedManifest['cipherTextBase64'] =
          '${cipher[0] == 'A' ? 'B' : 'A'}${cipher.substring(1)}';
      final modifiedHeader = utf8.encode(jsonEncode(headerJson));
      expect(modifiedHeader.length, headerLength);

      final corruptBytes = Uint8List.fromList([
        ...utf8.encode(VaultBackupCodec.magic),
        ..._uint32Bytes(modifiedHeader.length),
        ...modifiedHeader,
        ...bytes.sublist(9 + headerLength),
      ]);
      final corrupt = File(
        '${suiteDir.path}${Platform.pathSeparator}corrupt-manifest.psvb',
      );
      await corrupt.writeAsBytes(corruptBytes, flush: true);
      final header = await VaultBackupCodec.readHeader(corrupt);

      expect(
        () => VaultBackupCodec.readPayloadManifest(
          source: corrupt,
          header: header,
          masterKeyBytes: masterKey,
        ),
        throwsA(isA<VaultBackupAuthenticationException>()),
      );
    },
  );

  test('truncación y bytes finales adicionales se rechazan', () async {
    final bytes = await validBackup.readAsBytes();
    final truncated = File(
      '${suiteDir.path}${Platform.pathSeparator}truncated.psvb',
    );
    await truncated.writeAsBytes(bytes.sublist(0, bytes.length - 1));
    final truncatedHeader = await VaultBackupCodec.readHeader(truncated);
    expect(
      () => VaultBackupCodec.extract(
        source: truncated,
        header: truncatedHeader,
        masterKeyBytes: masterKey,
        outputDir: Directory(
          '${suiteDir.path}${Platform.pathSeparator}truncated-output',
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    final appended = File(
      '${suiteDir.path}${Platform.pathSeparator}appended.psvb',
    );
    await appended.writeAsBytes([...bytes, 1]);
    final appendedHeader = await VaultBackupCodec.readHeader(appended);
    expect(
      () => VaultBackupCodec.extract(
        source: appended,
        header: appendedHeader,
        masterKeyBytes: masterKey,
        outputDir: Directory(
          '${suiteDir.path}${Platform.pathSeparator}appended-output',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'encabezados truncados, sobredimensionados y PSVB1 fallan explícitamente',
    () async {
      final tiny = File('${suiteDir.path}${Platform.pathSeparator}tiny.psvb');
      await tiny.writeAsBytes(utf8.encode('PSV'));
      expect(
        () => VaultBackupCodec.readHeader(tiny),
        throwsA(isA<FormatException>()),
      );

      final oversized = File(
        '${suiteDir.path}${Platform.pathSeparator}oversized-header.psvb',
      );
      await oversized.writeAsBytes([
        ...utf8.encode(VaultBackupCodec.magic),
        ..._uint32Bytes(VaultBackupCodec.maxHeaderBytes + 1),
      ]);
      expect(
        () => VaultBackupCodec.readHeader(oversized),
        throwsA(isA<FormatException>()),
      );

      final legacy = File(
        '${suiteDir.path}${Platform.pathSeparator}legacy.psvb',
      );
      await legacy.writeAsBytes([
        ...utf8.encode(VaultBackupCodec.legacyMagic),
        ..._uint32Bytes(2),
        ...utf8.encode('{}'),
      ]);
      expect(
        () => VaultBackupCodec.readHeader(legacy),
        throwsA(isA<UnsupportedVaultBackupVersionException>()),
      );
    },
  );

  group('manifiesto hostil', () {
    Map<String, dynamic> validManifestJson() => {
      'schemaVersion': VaultBackupCodec.manifestSchemaVersion,
      'databaseSchemaVersion': 8,
      'chunkSize': VaultBackupCodec.chunkSize,
      'totalPlaintextSize': 11,
      'dbFile': {
        'name': 'vault.sqlite',
        'size': 10,
        'sha256': _repeatedHex('0'),
      },
      'blobFiles': [
        {'name': 'safe.bin', 'size': 1, 'sha256': _repeatedHex('1')},
      ],
    };

    test('rechaza traversal y rutas absolutas', () {
      for (final hostileName in [
        '../escape.bin',
        r'..\escape.bin',
        '/absolute.bin',
        r'C:\absolute.bin',
      ]) {
        final json = validManifestJson();
        (json['blobFiles'] as List).first['name'] = hostileName;
        expect(
          () => VaultBackupManifest.fromJson(json).validate(),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('rechaza tamaños negativos, excesivos o totales falsos', () {
      final negative = validManifestJson();
      (negative['blobFiles'] as List).first['size'] = -1;
      expect(
        () => VaultBackupManifest.fromJson(negative).validate(),
        throwsA(isA<FormatException>()),
      );

      final huge = validManifestJson();
      (huge['blobFiles'] as List).first['size'] =
          VaultBackupCodec.maxFileSize + 1;
      huge['totalPlaintextSize'] = VaultBackupCodec.maxFileSize + 11;
      expect(
        () => VaultBackupManifest.fromJson(huge).validate(),
        throwsA(isA<FormatException>()),
      );

      final falseTotal = validManifestJson()..['totalPlaintextSize'] = 12;
      expect(
        () => VaultBackupManifest.fromJson(falseTotal).validate(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza duplicados, hashes inválidos y campos desconocidos', () {
      final duplicate = validManifestJson();
      (duplicate['blobFiles'] as List).add({
        'name': 'SAFE.BIN',
        'size': 0,
        'sha256': _repeatedHex('2'),
      });
      expect(
        () => VaultBackupManifest.fromJson(duplicate).validate(),
        throwsA(isA<FormatException>()),
      );

      final invalidHash = validManifestJson();
      (invalidHash['dbFile'] as Map<String, dynamic>)['sha256'] = 'abc';
      expect(
        () => VaultBackupManifest.fromJson(invalidHash).validate(),
        throwsA(isA<FormatException>()),
      );

      final extraField = validManifestJson()..['unexpected'] = true;
      expect(
        () => VaultBackupManifest.fromJson(extraField),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('parámetros KDF abusivos se rechazan antes de derivar clave', () {
    final headerJson = {
      'formatVersion': VaultBackupCodec.formatVersion,
      'createdAt': DateTime.utc(2026).toIso8601String(),
      'kdf': {
        'algorithm': BackupKeyWrapper.kdfAlgorithm,
        'saltBase64': envelope.saltBase64,
        'iterations': 2147483647,
      },
      'wrappedMasterKey': {
        'nonceBase64': envelope.nonceBase64,
        'cipherTextBase64': envelope.cipherTextBase64,
        'macBase64': envelope.macBase64,
      },
      'encryptedManifest': {
        'nonceBase64': base64Encode(List<int>.filled(12, 1)),
        'cipherTextBase64': base64Encode([1]),
        'macBase64': base64Encode(List<int>.filled(16, 2)),
      },
    };
    expect(
      () => VaultBackupHeader.fromJson(headerJson).validate(),
      throwsA(isA<FormatException>()),
    );
  });
}

int _payloadOffset(Uint8List bytes) => 9 + _uint32(bytes, 5);

int _uint32(List<int> bytes, int offset) => ByteData.sublistView(
  Uint8List.fromList(bytes),
  offset,
  offset + 4,
).getUint32(0, Endian.big);

List<int> _uint32Bytes(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.big)).buffer.asUint8List();

bool _containsSubsequence(List<int> haystack, List<int> needle) {
  if (needle.isEmpty) return true;
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var matches = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

String _repeatedHex(String digit) => List.filled(64, digit).join();
