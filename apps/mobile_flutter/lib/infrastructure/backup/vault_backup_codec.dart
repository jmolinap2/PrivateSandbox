import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

import 'backup_key_wrapper.dart';

/// Authenticated, streaming container for a complete portable vault backup.
///
/// PSVB2 deliberately keeps only the password KDF and key-envelope bootstrap
/// data in the clear. The database, blob names, sizes, hashes, and every file
/// byte are encrypted and authenticated:
///
/// ```
/// [5 bytes]  magic "PSVB2"
/// [4 bytes]  big-endian public-header length N
/// [N bytes]  strict JSON bootstrap header
/// [...]      AES-256-GCM records for DB + blobs in encrypted-manifest order
/// ```
///
/// Each payload record is `nonce(12) || ciphertext(chunk length) || tag(16)`.
/// Chunk AAD binds it to the backup, encrypted manifest, entry, index, name,
/// and expected length. This makes truncation, reordering, substitution, and
/// trailing bytes detectable without buffering large vaults in memory.
class VaultBackupCodec {
  const VaultBackupCodec._();

  static const magic = 'PSVB2';
  static const legacyMagic = 'PSVB1';
  static const formatVersion = 2;
  static const manifestSchemaVersion = 1;
  static const chunkSize = 1 << 20;

  static const maxHeaderBytes = 16 * 1024 * 1024;
  static const maxManifestCipherTextBytes = 8 * 1024 * 1024;
  static const maxFileCount = 100000;
  static const maxFileNameBytes = 255;
  static const maxFileSize = 1 << 40; // 1 TiB per entry.
  static const maxTotalPlaintextSize = 8 << 40; // 8 TiB per backup.

  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _recordOverhead = _nonceLength + _macLength;
  static final _aesGcm = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Creates a new PSVB2 backup atomically. Existing destinations are never
  /// overwritten. Source files are hashed once before the header is written
  /// and again while encrypting, so a concurrent mutation fails the export
  /// instead of producing a self-inconsistent backup.
  static Future<void> write({
    required File destination,
    required DateTime createdAt,
    required int databaseSchemaVersion,
    required BackupKeyEnvelope keyEnvelope,
    required Uint8List masterKeyBytes,
    required File dbFile,
    required List<File> blobFiles,
  }) async {
    _validateMasterKey(masterKeyBytes);
    _validateKeyEnvelope(keyEnvelope);
    if (databaseSchemaVersion < 1 || databaseSchemaVersion > 1000000) {
      throw ArgumentError.value(
        databaseSchemaVersion,
        'databaseSchemaVersion',
        'Versión de SQLite fuera de límites.',
      );
    }
    if (!await dbFile.exists()) {
      throw StateError(
        'No se encontró la base de datos que se intentó respaldar.',
      );
    }
    if (await destination.exists()) {
      throw StateError('Ya existe un archivo en el destino de la copia.');
    }
    if (blobFiles.length > maxFileCount) {
      throw const FormatException(
        'La bóveda contiene demasiados blobs para una sola copia.',
      );
    }

    final sortedBlobs = List<File>.from(blobFiles)
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    final dbEntry = await _entryForFile(dbFile, logicalName: 'vault.sqlite');
    final blobEntries = <VaultBackupFileEntry>[];
    final seenNames = <String>{'vault.sqlite'};
    for (final blob in sortedBlobs) {
      if (!await blob.exists()) {
        throw StateError(
          'Un blob desapareció durante la preparación de la copia.',
        );
      }
      final name = p.basename(blob.path);
      _validateSafeName(name, allowDatabaseName: false);
      if (!seenNames.add(name.toLowerCase())) {
        throw const FormatException(
          'La bóveda contiene nombres de blob duplicados.',
        );
      }
      blobEntries.add(await _entryForFile(blob, logicalName: name));
    }

    final totalSize = _sumSizes([dbEntry, ...blobEntries]);
    final manifest = VaultBackupManifest(
      schemaVersion: manifestSchemaVersion,
      databaseSchemaVersion: databaseSchemaVersion,
      chunkSize: chunkSize,
      totalPlaintextSize: totalSize,
      dbFile: dbEntry,
      blobFiles: blobEntries,
    );
    manifest.validate();

    final salt = _decodeBase64Exact(
      keyEnvelope.saltBase64,
      BackupKeyWrapper.saltLength,
      'salt KDF',
    );
    final manifestKey = await _deriveContentKey(
      masterKeyBytes,
      salt,
      'PrivateSandbox/PSVB2/encrypted-manifest',
    );
    final payloadKey = await _deriveContentKey(
      masterKeyBytes,
      salt,
      'PrivateSandbox/PSVB2/encrypted-payload',
    );

    final createdAtText = createdAt.toUtc().toIso8601String();
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    if (manifestBytes.length > maxManifestCipherTextBytes) {
      throw const FormatException(
        'El manifiesto de la copia excede el límite permitido.',
      );
    }

    final manifestAad = _manifestAad(
      createdAt: createdAtText,
      keyEnvelope: keyEnvelope,
    );
    final manifestBox = await _aesGcm.encrypt(
      manifestBytes,
      secretKey: manifestKey,
      aad: manifestAad,
    );
    final header = VaultBackupHeader(
      version: formatVersion,
      createdAt: createdAtText,
      keyEnvelope: keyEnvelope,
      encryptedManifestNonceBase64: base64Encode(manifestBox.nonce),
      encryptedManifestCipherTextBase64: base64Encode(manifestBox.cipherText),
      encryptedManifestMacBase64: base64Encode(manifestBox.mac.bytes),
    );
    header.validate();

    final headerBytes = utf8.encode(jsonEncode(header.toJson()));
    if (headerBytes.length > maxHeaderBytes) {
      throw const FormatException(
        'El encabezado de la copia excede el límite permitido.',
      );
    }
    final manifestDigest = crypto.sha256.convert(manifestBytes).toString();

    final partial = File('${destination.path}.partial');
    if (await partial.exists()) {
      await partial.delete();
    }

    RandomAccessFile? output;
    var completed = false;
    try {
      output = await partial.open(mode: FileMode.write);
      await output.writeFrom(utf8.encode(magic));
      final lengthBytes = ByteData(4)
        ..setUint32(0, headerBytes.length, Endian.big);
      await output.writeFrom(lengthBytes.buffer.asUint8List());
      await output.writeFrom(headerBytes);

      await _encryptFile(
        source: dbFile,
        expected: dbEntry,
        entryIndex: 0,
        payloadKey: payloadKey,
        manifestDigest: manifestDigest,
        destination: output,
      );
      for (var i = 0; i < sortedBlobs.length; i++) {
        await _encryptFile(
          source: sortedBlobs[i],
          expected: blobEntries[i],
          entryIndex: i + 1,
          payloadKey: payloadKey,
          manifestDigest: manifestDigest,
          destination: output,
        );
      }

      await output.flush();
      await output.close();
      output = null;
      await partial.rename(destination.path);
      completed = true;
    } finally {
      if (output != null) {
        await output.close();
      }
      if (!completed && await partial.exists()) {
        await partial.delete();
      }
    }
  }

  /// Reads and strictly validates only the public bootstrap header. No KDF
  /// work or extraction is performed here.
  static Future<VaultBackupHeader> readHeader(File source) async {
    final parsed = await _readHeaderAndOffset(source);
    return parsed.header;
  }

  /// Compatibility alias for code that used the PSVB1 method name. The
  /// returned object is now the public header; file metadata is available
  /// only after authenticated decryption via [readPayloadManifest].
  static Future<VaultBackupHeader> readManifest(File source) =>
      readHeader(source);

  /// Decrypts and validates the private payload manifest without extracting
  /// file contents. This is useful for checking schema support before swap.
  static Future<VaultBackupManifest> readPayloadManifest({
    required File source,
    required VaultBackupHeader header,
    required Uint8List masterKeyBytes,
  }) async {
    final parsed = await _readHeaderAndOffset(source);
    _requireSameHeader(header, parsed.header);
    return _decryptManifest(parsed.header, masterKeyBytes);
  }

  /// Fully authenticates and extracts the backup under [outputDir]. The
  /// method checks the exact expected container length before writing,
  /// authenticates every chunk, re-hashes every extracted entry, rejects
  /// unsafe names, and removes files it created if any validation fails.
  static Future<VaultBackupManifest> extract({
    required File source,
    required VaultBackupHeader header,
    required Uint8List masterKeyBytes,
    required Directory outputDir,
  }) async {
    _validateMasterKey(masterKeyBytes);
    final parsed = await _readHeaderAndOffset(source);
    _requireSameHeader(header, parsed.header);
    final manifestResult = await _decryptManifestWithBytes(
      parsed.header,
      masterKeyBytes,
    );
    final manifest = manifestResult.manifest;

    final expectedLength = _expectedContainerLength(
      parsed.payloadOffset,
      manifest.allFiles,
    );
    final actualLength = await source.length();
    if (actualLength != expectedLength) {
      throw const FormatException(
        'La copia está truncada o contiene datos adicionales no declarados.',
      );
    }

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    final blobsDir = Directory(p.join(outputDir.path, 'blobs'));
    if (!await blobsDir.exists()) {
      await blobsDir.create(recursive: true);
    }

    final salt = _decodeBase64Exact(
      parsed.header.keyEnvelope.saltBase64,
      BackupKeyWrapper.saltLength,
      'salt KDF',
    );
    final payloadKey = await _deriveContentKey(
      masterKeyBytes,
      salt,
      'PrivateSandbox/PSVB2/encrypted-payload',
    );
    final manifestDigest = crypto.sha256
        .convert(manifestResult.plainBytes)
        .toString();

    final raf = await source.open();
    final createdFiles = <File>[];
    try {
      await raf.setPosition(parsed.payloadOffset);
      for (var i = 0; i < manifest.allFiles.length; i++) {
        final entry = manifest.allFiles[i];
        final destination = i == 0
            ? File(p.join(outputDir.path, entry.name))
            : File(p.join(blobsDir.path, entry.name));
        if (await destination.exists()) {
          throw const FileSystemException(
            'El directorio de extracción no está vacío.',
          );
        }

        await _decryptFile(
          source: raf,
          destination: destination,
          expected: entry,
          entryIndex: i,
          payloadKey: payloadKey,
          manifestDigest: manifestDigest,
        );
        createdFiles.add(destination);
      }
      if (await raf.position() != actualLength) {
        throw const FormatException(
          'La copia contiene bytes finales inesperados.',
        );
      }
      return manifest;
    } catch (_) {
      for (final file in createdFiles.reversed) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      rethrow;
    } finally {
      await raf.close();
    }
  }

  static Future<({VaultBackupHeader header, int payloadOffset})>
  _readHeaderAndOffset(File source) async {
    if (!await source.exists()) {
      throw const FormatException('No se encontró la copia de seguridad.');
    }
    final fileLength = await source.length();
    if (fileLength < magic.length + 4) {
      throw const FormatException('La copia de seguridad está truncada.');
    }

    final raf = await source.open();
    try {
      final magicBytes = await _readExact(raf, magic.length, 'magic');
      final foundMagic = utf8.decode(magicBytes, allowMalformed: true);
      if (foundMagic == legacyMagic) {
        throw const UnsupportedVaultBackupVersionException(
          'El formato PSVB1 ya no se puede restaurar de forma segura. '
          'Exporta una copia PSVB2 desde una versión actualizada.',
        );
      }
      if (foundMagic != magic) {
        throw const FormatException(
          'No es un archivo de copia de seguridad válido.',
        );
      }

      final lengthBytes = await _readExact(raf, 4, 'longitud del encabezado');
      final headerLength = ByteData.sublistView(
        lengthBytes,
      ).getUint32(0, Endian.big);
      if (headerLength < 2 || headerLength > maxHeaderBytes) {
        throw const FormatException(
          'La longitud del encabezado está fuera de límites.',
        );
      }
      final payloadOffset = magic.length + 4 + headerLength;
      if (payloadOffset > fileLength) {
        throw const FormatException('La copia de seguridad está truncada.');
      }

      final headerBytes = await _readExact(raf, headerLength, 'encabezado');
      final dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(headerBytes));
      } catch (_) {
        throw const FormatException(
          'El encabezado de la copia no contiene JSON UTF-8 válido.',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'El encabezado de la copia tiene una estructura inválida.',
        );
      }
      final header = VaultBackupHeader.fromJson(decoded);
      header.validate();
      return (header: header, payloadOffset: payloadOffset);
    } finally {
      await raf.close();
    }
  }

  static Future<VaultBackupManifest> _decryptManifest(
    VaultBackupHeader header,
    Uint8List masterKeyBytes,
  ) async {
    final result = await _decryptManifestWithBytes(header, masterKeyBytes);
    return result.manifest;
  }

  static Future<({VaultBackupManifest manifest, Uint8List plainBytes})>
  _decryptManifestWithBytes(
    VaultBackupHeader header,
    Uint8List masterKeyBytes,
  ) async {
    _validateMasterKey(masterKeyBytes);
    final salt = _decodeBase64Exact(
      header.keyEnvelope.saltBase64,
      BackupKeyWrapper.saltLength,
      'salt KDF',
    );
    final key = await _deriveContentKey(
      masterKeyBytes,
      salt,
      'PrivateSandbox/PSVB2/encrypted-manifest',
    );
    final nonce = _decodeBase64Exact(
      header.encryptedManifestNonceBase64,
      _nonceLength,
      'nonce del manifiesto',
    );
    final cipherText = _decodeBase64Bounded(
      header.encryptedManifestCipherTextBase64,
      'manifiesto cifrado',
      maxManifestCipherTextBytes,
    );
    final mac = _decodeBase64Exact(
      header.encryptedManifestMacBase64,
      _macLength,
      'MAC del manifiesto',
    );

    final List<int> clear;
    try {
      clear = await _aesGcm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: _manifestAad(
          createdAt: header.createdAt,
          keyEnvelope: header.keyEnvelope,
        ),
      );
    } on SecretBoxAuthenticationError {
      throw const VaultBackupAuthenticationException(
        'La autenticación del manifiesto cifrado falló.',
      );
    } catch (_) {
      throw const VaultBackupAuthenticationException(
        'No se pudo descifrar el manifiesto de la copia.',
      );
    }

    final bytes = Uint8List.fromList(clear);
    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const FormatException(
        'El manifiesto descifrado no contiene JSON UTF-8 válido.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El manifiesto descifrado tiene una estructura inválida.',
      );
    }
    final manifest = VaultBackupManifest.fromJson(decoded);
    manifest.validate();
    return (manifest: manifest, plainBytes: bytes);
  }

  static Future<void> _encryptFile({
    required File source,
    required VaultBackupFileEntry expected,
    required int entryIndex,
    required SecretKey payloadKey,
    required String manifestDigest,
    required RandomAccessFile destination,
  }) async {
    if (await source.length() != expected.size) {
      throw StateError('Un archivo cambió mientras se creaba la copia.');
    }

    final raf = await source.open();
    final digestSink = _DigestSink();
    final hashConversion = crypto.sha256.startChunkedConversion(digestSink);
    try {
      var remaining = expected.size;
      var chunkIndex = 0;
      while (remaining > 0) {
        final plainLength = remaining < chunkSize ? remaining : chunkSize;
        final clear = await _readExact(
          raf,
          plainLength,
          'archivo de origen ${expected.name}',
        );
        hashConversion.add(clear);
        final box = await _aesGcm.encrypt(
          clear,
          secretKey: payloadKey,
          aad: _chunkAad(
            manifestDigest: manifestDigest,
            entryIndex: entryIndex,
            chunkIndex: chunkIndex,
            entryName: expected.name,
            plainLength: plainLength,
          ),
        );
        if (box.nonce.length != _nonceLength ||
            box.mac.bytes.length != _macLength ||
            box.cipherText.length != plainLength) {
          throw StateError(
            'El motor criptográfico produjo un registro inválido.',
          );
        }
        await destination.writeFrom(box.nonce);
        await destination.writeFrom(box.cipherText);
        await destination.writeFrom(box.mac.bytes);
        remaining -= plainLength;
        chunkIndex++;
      }
      hashConversion.close();

      if (await source.length() != expected.size ||
          digestSink.value.toString() != expected.sha256) {
        throw StateError('Un archivo cambió mientras se creaba la copia.');
      }
    } finally {
      await raf.close();
    }
  }

  static Future<void> _decryptFile({
    required RandomAccessFile source,
    required File destination,
    required VaultBackupFileEntry expected,
    required int entryIndex,
    required SecretKey payloadKey,
    required String manifestDigest,
  }) async {
    final partial = File('${destination.path}.partial');
    if (await partial.exists()) {
      await partial.delete();
    }

    RandomAccessFile? output;
    var completed = false;
    final digestSink = _DigestSink();
    final hashConversion = crypto.sha256.startChunkedConversion(digestSink);
    try {
      output = await partial.open(mode: FileMode.write);
      var remaining = expected.size;
      var chunkIndex = 0;
      while (remaining > 0) {
        final plainLength = remaining < chunkSize ? remaining : chunkSize;
        final nonce = await _readExact(
          source,
          _nonceLength,
          'nonce del payload',
        );
        final cipherText = await _readExact(
          source,
          plainLength,
          'payload cifrado',
        );
        final mac = await _readExact(source, _macLength, 'MAC del payload');

        final List<int> clear;
        try {
          clear = await _aesGcm.decrypt(
            SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
            secretKey: payloadKey,
            aad: _chunkAad(
              manifestDigest: manifestDigest,
              entryIndex: entryIndex,
              chunkIndex: chunkIndex,
              entryName: expected.name,
              plainLength: plainLength,
            ),
          );
        } on SecretBoxAuthenticationError {
          throw const VaultBackupAuthenticationException(
            'La autenticación de un bloque del payload falló.',
          );
        } catch (_) {
          throw const VaultBackupAuthenticationException(
            'No se pudo descifrar un bloque del payload.',
          );
        }
        if (clear.length != plainLength) {
          throw const FormatException(
            'Un bloque descifrado tiene una longitud inesperada.',
          );
        }
        hashConversion.add(clear);
        await output.writeFrom(clear);
        remaining -= plainLength;
        chunkIndex++;
      }
      hashConversion.close();
      if (digestSink.value.toString() != expected.sha256) {
        throw const VaultBackupAuthenticationException(
          'El hash de un archivo restaurado no coincide con el manifiesto.',
        );
      }

      await output.flush();
      await output.close();
      output = null;
      await partial.rename(destination.path);
      completed = true;
    } finally {
      if (output != null) {
        await output.close();
      }
      if (!completed && await partial.exists()) {
        await partial.delete();
      }
    }
  }

  static Future<VaultBackupFileEntry> _entryForFile(
    File file, {
    required String logicalName,
  }) async {
    _validateSafeName(
      logicalName,
      allowDatabaseName: logicalName == 'vault.sqlite',
    );
    final size = await file.length();
    _validateSize(size, logicalName);
    return VaultBackupFileEntry(
      name: logicalName,
      size: size,
      sha256: await _hashFile(file),
    );
  }

  static Future<String> _hashFile(File file) async {
    final digestSink = _DigestSink();
    final conversion = crypto.sha256.startChunkedConversion(digestSink);
    await for (final chunk in file.openRead()) {
      conversion.add(chunk);
    }
    conversion.close();
    return digestSink.value.toString();
  }

  static Future<SecretKey> _deriveContentKey(
    Uint8List masterKeyBytes,
    Uint8List salt,
    String context,
  ) {
    return _hkdf.deriveKey(
      secretKey: SecretKey(masterKeyBytes),
      nonce: salt,
      info: utf8.encode(context),
    );
  }

  static Uint8List _manifestAad({
    required String createdAt,
    required BackupKeyEnvelope keyEnvelope,
  }) {
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'magic': magic,
          'formatVersion': formatVersion,
          'createdAt': createdAt,
          'kdf': {
            'algorithm': BackupKeyWrapper.kdfAlgorithm,
            'saltBase64': keyEnvelope.saltBase64,
            'iterations': keyEnvelope.kdfIterations,
          },
          'wrappedMasterKey': {
            'nonceBase64': keyEnvelope.nonceBase64,
            'cipherTextBase64': keyEnvelope.cipherTextBase64,
            'macBase64': keyEnvelope.macBase64,
          },
        }),
      ),
    );
  }

  static Uint8List _chunkAad({
    required String manifestDigest,
    required int entryIndex,
    required int chunkIndex,
    required String entryName,
    required int plainLength,
  }) {
    return Uint8List.fromList(
      utf8.encode(
        '$magic|$manifestDigest|entry=$entryIndex|chunk=$chunkIndex|'
        'name=$entryName|length=$plainLength',
      ),
    );
  }

  static int _expectedContainerLength(
    int payloadOffset,
    List<VaultBackupFileEntry> entries,
  ) {
    var total = payloadOffset;
    for (final entry in entries) {
      final chunks = entry.size == 0 ? 0 : ((entry.size - 1) ~/ chunkSize) + 1;
      total += entry.size + (chunks * _recordOverhead);
    }
    return total;
  }

  static int _sumSizes(Iterable<VaultBackupFileEntry> entries) {
    var total = 0;
    for (final entry in entries) {
      total += entry.size;
      if (total > maxTotalPlaintextSize) {
        throw const FormatException(
          'El tamaño total declarado excede el límite permitido.',
        );
      }
    }
    return total;
  }

  static Future<Uint8List> _readExact(
    RandomAccessFile source,
    int length,
    String field,
  ) async {
    if (length < 0) {
      throw FormatException('Longitud negativa para $field.');
    }
    final bytes = BytesBuilder(copy: false);
    var remaining = length;
    while (remaining > 0) {
      final chunk = await source.read(remaining);
      if (chunk.isEmpty) {
        throw FormatException('La copia está truncada al leer $field.');
      }
      bytes.add(chunk);
      remaining -= chunk.length;
    }
    return bytes.takeBytes();
  }

  static void _requireSameHeader(
    VaultBackupHeader expected,
    VaultBackupHeader actual,
  ) {
    if (jsonEncode(expected.toJson()) != jsonEncode(actual.toJson())) {
      throw const FormatException(
        'El encabezado cambió durante la lectura de la copia.',
      );
    }
  }

  static void _validateMasterKey(Uint8List bytes) {
    if (bytes.length != BackupKeyWrapper.masterKeyLength) {
      throw const FormatException(
        'La copia no contiene una clave maestra de 256 bits.',
      );
    }
  }

  static void _validateKeyEnvelope(BackupKeyEnvelope envelope) {
    if (envelope.kdfIterations != BackupKeyWrapper.iterations) {
      throw const FormatException(
        'La copia usa parámetros KDF no compatibles.',
      );
    }
    _decodeBase64Exact(
      envelope.saltBase64,
      BackupKeyWrapper.saltLength,
      'salt KDF',
    );
    _decodeBase64Exact(
      envelope.nonceBase64,
      BackupKeyWrapper.nonceLength,
      'nonce de clave',
    );
    _decodeBase64Exact(
      envelope.cipherTextBase64,
      BackupKeyWrapper.masterKeyLength,
      'clave maestra cifrada',
    );
    _decodeBase64Exact(
      envelope.macBase64,
      BackupKeyWrapper.macLength,
      'MAC de clave',
    );
  }

  static void _validateSafeName(
    String name, {
    required bool allowDatabaseName,
  }) {
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains(r'\') ||
        name.contains('\u0000') ||
        p.isAbsolute(name) ||
        p.basename(name) != name ||
        utf8.encode(name).length > maxFileNameBytes) {
      throw FormatException('Nombre de archivo no seguro en la copia: $name');
    }
    if (!allowDatabaseName && name.toLowerCase() == 'vault.sqlite') {
      throw const FormatException(
        'Un blob no puede usar el nombre reservado de la base de datos.',
      );
    }
  }

  static void _validateSize(int size, String name) {
    if (size < 0 || size > maxFileSize) {
      throw FormatException('Tamaño fuera de límites para la entrada $name.');
    }
  }

  static Uint8List _decodeBase64Exact(
    String encoded,
    int expectedLength,
    String field,
  ) {
    final decoded = _decodeBase64Bounded(encoded, field, expectedLength);
    if (decoded.length != expectedLength) {
      throw FormatException('Longitud inválida para $field.');
    }
    return decoded;
  }

  static Uint8List _decodeBase64Bounded(
    String encoded,
    String field,
    int maxLength,
  ) {
    if (encoded.isEmpty || encoded.length > ((maxLength + 2) ~/ 3) * 4 + 4) {
      throw FormatException('Longitud inválida para $field.');
    }
    try {
      final decoded = base64Decode(encoded);
      if (decoded.length > maxLength || base64Encode(decoded) != encoded) {
        throw FormatException('Codificación base64 no canónica para $field.');
      }
      return Uint8List.fromList(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException('Codificación base64 inválida para $field.');
    }
  }
}

class VaultBackupFileEntry {
  final String name;
  final int size;
  final String sha256;

  const VaultBackupFileEntry({
    required this.name,
    required this.size,
    required this.sha256,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'sha256': sha256,
  };

  factory VaultBackupFileEntry.fromJson(Map<String, dynamic> json) {
    _expectExactKeys(json, const {'name', 'size', 'sha256'}, 'entrada');
    return VaultBackupFileEntry(
      name: _requiredString(json, 'name', 'entrada'),
      size: _requiredInt(json, 'size', 'entrada'),
      sha256: _requiredString(json, 'sha256', 'entrada'),
    );
  }

  void validate({required bool isDatabase}) {
    VaultBackupCodec._validateSafeName(name, allowDatabaseName: isDatabase);
    if (isDatabase && name != 'vault.sqlite') {
      throw const FormatException(
        'La entrada de base de datos debe llamarse vault.sqlite.',
      );
    }
    VaultBackupCodec._validateSize(size, name);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) {
      throw FormatException('Hash SHA-256 inválido para la entrada $name.');
    }
  }
}

class VaultBackupManifest {
  final int schemaVersion;
  final int databaseSchemaVersion;
  final int chunkSize;
  final int totalPlaintextSize;
  final VaultBackupFileEntry dbFile;
  final List<VaultBackupFileEntry> blobFiles;

  const VaultBackupManifest({
    required this.schemaVersion,
    required this.databaseSchemaVersion,
    required this.chunkSize,
    required this.totalPlaintextSize,
    required this.dbFile,
    required this.blobFiles,
  });

  List<VaultBackupFileEntry> get allFiles => [dbFile, ...blobFiles];

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'databaseSchemaVersion': databaseSchemaVersion,
    'chunkSize': chunkSize,
    'totalPlaintextSize': totalPlaintextSize,
    'dbFile': dbFile.toJson(),
    'blobFiles': [for (final blob in blobFiles) blob.toJson()],
  };

  factory VaultBackupManifest.fromJson(Map<String, dynamic> json) {
    _expectExactKeys(json, const {
      'schemaVersion',
      'databaseSchemaVersion',
      'chunkSize',
      'totalPlaintextSize',
      'dbFile',
      'blobFiles',
    }, 'manifiesto');
    final dbJson = _requiredMap(json, 'dbFile', 'manifiesto');
    final blobsJson = _requiredList(json, 'blobFiles', 'manifiesto');
    if (blobsJson.length > VaultBackupCodec.maxFileCount) {
      throw const FormatException('El manifiesto declara demasiados blobs.');
    }
    final blobs = <VaultBackupFileEntry>[];
    for (final value in blobsJson) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException(
          'Una entrada de blob no tiene una estructura válida.',
        );
      }
      blobs.add(VaultBackupFileEntry.fromJson(value));
    }
    return VaultBackupManifest(
      schemaVersion: _requiredInt(json, 'schemaVersion', 'manifiesto'),
      databaseSchemaVersion: _requiredInt(
        json,
        'databaseSchemaVersion',
        'manifiesto',
      ),
      chunkSize: _requiredInt(json, 'chunkSize', 'manifiesto'),
      totalPlaintextSize: _requiredInt(
        json,
        'totalPlaintextSize',
        'manifiesto',
      ),
      dbFile: VaultBackupFileEntry.fromJson(dbJson),
      blobFiles: blobs,
    );
  }

  void validate() {
    if (schemaVersion != VaultBackupCodec.manifestSchemaVersion) {
      throw UnsupportedVaultBackupVersionException(
        'Versión de manifiesto no compatible: $schemaVersion.',
      );
    }
    if (databaseSchemaVersion < 1 || databaseSchemaVersion > 1000000) {
      throw const FormatException(
        'La versión declarada de SQLite está fuera de límites.',
      );
    }
    if (chunkSize != VaultBackupCodec.chunkSize) {
      throw const FormatException(
        'El tamaño de bloque declarado no es compatible.',
      );
    }
    if (blobFiles.length > VaultBackupCodec.maxFileCount) {
      throw const FormatException('El manifiesto declara demasiados blobs.');
    }

    dbFile.validate(isDatabase: true);
    final seen = <String>{dbFile.name.toLowerCase()};
    for (final blob in blobFiles) {
      blob.validate(isDatabase: false);
      if (!seen.add(blob.name.toLowerCase())) {
        throw const FormatException(
          'El manifiesto contiene nombres de archivo duplicados.',
        );
      }
    }
    final calculated = VaultBackupCodec._sumSizes(allFiles);
    if (totalPlaintextSize != calculated) {
      throw const FormatException(
        'El tamaño total no coincide con las entradas del manifiesto.',
      );
    }
  }
}

class VaultBackupHeader {
  final int version;
  final String createdAt;
  final BackupKeyEnvelope keyEnvelope;
  final String encryptedManifestNonceBase64;
  final String encryptedManifestCipherTextBase64;
  final String encryptedManifestMacBase64;

  const VaultBackupHeader({
    required this.version,
    required this.createdAt,
    required this.keyEnvelope,
    required this.encryptedManifestNonceBase64,
    required this.encryptedManifestCipherTextBase64,
    required this.encryptedManifestMacBase64,
  });

  Map<String, dynamic> toJson() => {
    'formatVersion': version,
    'createdAt': createdAt,
    'kdf': {
      'algorithm': BackupKeyWrapper.kdfAlgorithm,
      'saltBase64': keyEnvelope.saltBase64,
      'iterations': keyEnvelope.kdfIterations,
    },
    'wrappedMasterKey': {
      'nonceBase64': keyEnvelope.nonceBase64,
      'cipherTextBase64': keyEnvelope.cipherTextBase64,
      'macBase64': keyEnvelope.macBase64,
    },
    'encryptedManifest': {
      'nonceBase64': encryptedManifestNonceBase64,
      'cipherTextBase64': encryptedManifestCipherTextBase64,
      'macBase64': encryptedManifestMacBase64,
    },
  };

  factory VaultBackupHeader.fromJson(Map<String, dynamic> json) {
    _expectExactKeys(json, const {
      'formatVersion',
      'createdAt',
      'kdf',
      'wrappedMasterKey',
      'encryptedManifest',
    }, 'encabezado');
    final kdf = _requiredMap(json, 'kdf', 'encabezado');
    final wrapped = _requiredMap(json, 'wrappedMasterKey', 'encabezado');
    final encryptedManifest = _requiredMap(
      json,
      'encryptedManifest',
      'encabezado',
    );
    _expectExactKeys(kdf, const {
      'algorithm',
      'saltBase64',
      'iterations',
    }, 'KDF');
    _expectExactKeys(wrapped, const {
      'nonceBase64',
      'cipherTextBase64',
      'macBase64',
    }, 'clave envuelta');
    _expectExactKeys(encryptedManifest, const {
      'nonceBase64',
      'cipherTextBase64',
      'macBase64',
    }, 'manifiesto cifrado');
    final algorithm = _requiredString(kdf, 'algorithm', 'KDF');
    if (algorithm != BackupKeyWrapper.kdfAlgorithm) {
      throw UnsupportedVaultBackupVersionException(
        'Algoritmo KDF no compatible: $algorithm.',
      );
    }

    return VaultBackupHeader(
      version: _requiredInt(json, 'formatVersion', 'encabezado'),
      createdAt: _requiredString(json, 'createdAt', 'encabezado'),
      keyEnvelope: BackupKeyEnvelope(
        saltBase64: _requiredString(kdf, 'saltBase64', 'KDF'),
        kdfIterations: _requiredInt(kdf, 'iterations', 'KDF'),
        nonceBase64: _requiredString(wrapped, 'nonceBase64', 'clave envuelta'),
        cipherTextBase64: _requiredString(
          wrapped,
          'cipherTextBase64',
          'clave envuelta',
        ),
        macBase64: _requiredString(wrapped, 'macBase64', 'clave envuelta'),
      ),
      encryptedManifestNonceBase64: _requiredString(
        encryptedManifest,
        'nonceBase64',
        'manifiesto cifrado',
      ),
      encryptedManifestCipherTextBase64: _requiredString(
        encryptedManifest,
        'cipherTextBase64',
        'manifiesto cifrado',
      ),
      encryptedManifestMacBase64: _requiredString(
        encryptedManifest,
        'macBase64',
        'manifiesto cifrado',
      ),
    );
  }

  void validate() {
    if (version != VaultBackupCodec.formatVersion) {
      throw UnsupportedVaultBackupVersionException(
        'Versión de copia no compatible: $version.',
      );
    }
    if (createdAt.length > 64 || DateTime.tryParse(createdAt) == null) {
      throw const FormatException(
        'La fecha de creación del encabezado es inválida.',
      );
    }
    VaultBackupCodec._validateKeyEnvelope(keyEnvelope);
    VaultBackupCodec._decodeBase64Exact(
      encryptedManifestNonceBase64,
      VaultBackupCodec._nonceLength,
      'nonce del manifiesto',
    );
    VaultBackupCodec._decodeBase64Bounded(
      encryptedManifestCipherTextBase64,
      'manifiesto cifrado',
      VaultBackupCodec.maxManifestCipherTextBytes,
    );
    VaultBackupCodec._decodeBase64Exact(
      encryptedManifestMacBase64,
      VaultBackupCodec._macLength,
      'MAC del manifiesto',
    );
  }
}

class VaultBackupAuthenticationException implements Exception {
  final String message;

  const VaultBackupAuthenticationException(this.message);

  @override
  String toString() => message;
}

class UnsupportedVaultBackupVersionException implements Exception {
  final String message;

  const UnsupportedVaultBackupVersionException(this.message);

  @override
  String toString() => message;
}

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _value;

  crypto.Digest get value {
    final result = _value;
    if (result == null) {
      throw StateError('No se pudo calcular SHA-256.');
    }
    return result;
  }

  @override
  void add(crypto.Digest data) => _value = data;

  @override
  void close() {}
}

void _expectExactKeys(
  Map<String, dynamic> json,
  Set<String> expected,
  String context,
) {
  if (json.length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw FormatException('Campos inesperados o ausentes en $context.');
  }
}

String _requiredString(Map<String, dynamic> json, String key, String context) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('El campo $key de $context debe ser texto.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key, String context) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('El campo $key de $context debe ser entero.');
  }
  return value;
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String key,
  String context,
) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('El campo $key de $context debe ser un objeto.');
  }
  return value;
}

List<dynamic> _requiredList(
  Map<String, dynamic> json,
  String key,
  String context,
) {
  final value = json[key];
  if (value is! List<dynamic>) {
    throw FormatException('El campo $key de $context debe ser una lista.');
  }
  return value;
}
