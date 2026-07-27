import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/synchronization/sync_protocol.dart';
import '../../shared/utils/random_bytes.dart';
import '../encryption/stream_cipher.dart';
import '../storage/atomic_file_writer.dart';

class EncryptedSharePackageResult {
  final File packageFile;
  final String packageId;
  final String capabilityKey;
  final DateTime expiresAt;

  const EncryptedSharePackageResult({
    required this.packageFile,
    required this.packageId,
    required this.capabilityKey,
    required this.expiresAt,
  });
}

class OpenedSharePackage {
  final File plaintextFile;
  final String originalName;
  final String mimeType;
  final DateTime? modifiedAt;

  const OpenedSharePackage({
    required this.plaintextFile,
    required this.originalName,
    required this.mimeType,
    required this.modifiedAt,
  });
}

/// Streaming encrypted package used for direct transfer and temporary links.
///
/// The package can be hosted by an untrusted server. Its capability key is
/// kept outside the file (normally in the URL fragment, which browsers do not
/// send to the server). Both metadata and content use independent HKDF keys.
abstract final class EncryptedSharePackageCodec {
  static const _uuid = Uuid();
  static const _version = 1;
  static const _magic = <int>[0x50, 0x53, 0x48, 0x41, 0x52, 0x45, 0x31, 0x0a];
  static const _maximumHeaderBytes = 64 * 1024;
  static const _maximumPlainBytes = 8 * 1024 * 1024 * 1024 * 1024;
  static const _macBytes = 16;
  static final _metadataCipher = AesGcm.with256bits();
  static final _contentKdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _metadataKdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static Future<EncryptedSharePackageResult> create({
    required File plaintextFile,
    required String originalName,
    required String mimeType,
    required Directory destinationDirectory,
    required Directory privateTemporaryDirectory,
    required Duration lifetime,
    DateTime? modifiedAt,
    DateTime? now,
  }) async {
    if (lifetime <= Duration.zero || lifetime > const Duration(days: 30)) {
      throw ArgumentError.value(
        lifetime,
        'lifetime',
        'Debe estar entre un instante y 30 días.',
      );
    }
    final plainSize = await plaintextFile.length();
    if (plainSize < 0 || plainSize > _maximumPlainBytes) {
      throw const FormatException(
        'El archivo excede el tamaño máximo del paquete.',
      );
    }
    final safeName = AtomicFileWriter.sanitizeFileName(originalName);
    final packageId = _uuid.v4();
    final capabilityBytes = randomBytes(32);
    final salt = randomBytes(16);
    final contentNonce = randomBytes(8);
    final capability = SecretKey(capabilityBytes);
    final contentKey = await _deriveContentKey(capability, salt);
    final metadataKey = await _deriveMetadataKey(capability, salt);
    final createdAt = (now ?? DateTime.now()).toUtc();
    final expiresAt = createdAt.add(lifetime);
    if (!await privateTemporaryDirectory.exists()) {
      await privateTemporaryDirectory.create(recursive: true);
    }
    final encryptedContent =
        File(p.join(privateTemporaryDirectory.path, '.$packageId.content'));
    try {
      final plainHash = await StreamCipher.encryptFile(
        input: plaintextFile,
        output: encryptedContent,
        fileKey: contentKey,
        noncePrefix: contentNonce,
      );
      final cipherSize = await encryptedContent.length();
      final publicHeader = <String, Object?>{
        'version': _version,
        'packageId': packageId,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'salt': base64Encode(salt),
        'contentNonce': base64Encode(contentNonce),
        'plainSize': plainSize,
        'cipherSize': cipherSize,
      };
      final privateMetadata = <String, Object?>{
        'name': safeName,
        'mimeType': mimeType,
        if (modifiedAt != null)
          'modifiedAt': modifiedAt.toUtc().toIso8601String(),
        'sha256': plainHash,
      };
      final metadataBox = await _metadataCipher.encrypt(
        utf8.encode(canonicalJson(privateMetadata)),
        secretKey: metadataKey,
        aad: utf8.encode(canonicalJson(publicHeader)),
      );
      final header = <String, Object?>{
        ...publicHeader,
        'metadataNonce': base64Encode(metadataBox.nonce),
        'metadataCipherText': base64Encode(metadataBox.cipherText),
        'metadataMac': base64Encode(metadataBox.mac.bytes),
      };
      final headerBytes = utf8.encode(canonicalJson(header));
      if (headerBytes.length > _maximumHeaderBytes) {
        throw const FormatException('Los metadatos del paquete son demasiado grandes.');
      }
      final prefix = BytesBuilder(copy: false)
        ..add(_magic)
        ..add(_uint32(headerBytes.length))
        ..add(headerBytes);
      final prefixBytes = prefix.takeBytes();
      final package = await AtomicFileWriter.writeStream(
        destinationDirectory: destinationDirectory,
        preferredName: '$safeName.pshare',
        bytes: _concat(prefixBytes, encryptedContent),
        expectedLength: prefixBytes.length + cipherSize,
      );
      return EncryptedSharePackageResult(
        packageFile: package,
        packageId: packageId,
        capabilityKey: _encodeCapability(capabilityBytes),
        expiresAt: expiresAt,
      );
    } finally {
      capabilityBytes.fillRange(0, capabilityBytes.length, 0);
      if (await encryptedContent.exists()) {
        await encryptedContent.delete();
      }
    }
  }

  static Future<OpenedSharePackage> open({
    required File packageFile,
    required String capabilityKey,
    required Directory destinationDirectory,
    required Directory privateTemporaryDirectory,
    DateTime? now,
  }) async {
    final packageLength = await packageFile.length();
    if (packageLength < _magic.length + 4) {
      throw const FormatException('El paquete está truncado.');
    }
    final reader = await packageFile.open();
    File? encryptedContent;
    File? published;
    var succeeded = false;
    final capabilityBytes = _decodeCapability(capabilityKey);
    try {
      final magic = await reader.read(_magic.length);
      if (!_constantTimeEquals(magic, _magic)) {
        throw const FormatException('El archivo no es un paquete PrivateSandbox.');
      }
      final lengthBytes = await reader.read(4);
      if (lengthBytes.length != 4) {
        throw const FormatException('El encabezado está truncado.');
      }
      final headerLength = ByteData.sublistView(
        Uint8List.fromList(lengthBytes),
      ).getUint32(0, Endian.big);
      if (headerLength <= 0 || headerLength > _maximumHeaderBytes) {
        throw const FormatException('El tamaño del encabezado no es válido.');
      }
      final headerBytes = await reader.read(headerLength);
      if (headerBytes.length != headerLength) {
        throw const FormatException('El encabezado está truncado.');
      }
      final header = _strictHeader(headerBytes);
      final publicHeader = <String, Object?>{
        'version': header['version'],
        'packageId': header['packageId'],
        'createdAt': header['createdAt'],
        'expiresAt': header['expiresAt'],
        'salt': header['salt'],
        'contentNonce': header['contentNonce'],
        'plainSize': header['plainSize'],
        'cipherSize': header['cipherSize'],
      };
      final createdAt = DateTime.parse(header['createdAt']! as String).toUtc();
      final expiresAt = DateTime.parse(header['expiresAt']! as String).toUtc();
      if (!expiresAt.isAfter(createdAt) ||
          expiresAt.difference(createdAt) > const Duration(days: 30)) {
        throw const FormatException('La vigencia del paquete no es válida.');
      }
      final plainSize = (header['plainSize']! as num).toInt();
      final cipherSize = (header['cipherSize']! as num).toInt();
      if (plainSize < 0 ||
          plainSize > _maximumPlainBytes ||
          cipherSize != _cipherLengthFor(plainSize) ||
          packageLength != _magic.length + 4 + headerLength + cipherSize) {
        throw const FormatException('Los tamaños del paquete no son coherentes.');
      }
      final capability = SecretKey(capabilityBytes);
      final salt = _decodeExact(header['salt']! as String, 16, 'salt');
      final contentNonce = _decodeExact(
        header['contentNonce']! as String,
        8,
        'contentNonce',
      );
      final metadataKey = await _deriveMetadataKey(capability, salt);
      Map<String, Object?> metadata;
      try {
        final clear = await _metadataCipher.decrypt(
          SecretBox(
            _decodeBounded(
              header['metadataCipherText']! as String,
              _maximumHeaderBytes,
              'metadataCipherText',
            ),
            nonce: _decodeExact(
              header['metadataNonce']! as String,
              12,
              'metadataNonce',
            ),
            mac: Mac(
              _decodeExact(
                header['metadataMac']! as String,
                _macBytes,
                'metadataMac',
              ),
            ),
          ),
          secretKey: metadataKey,
          aad: utf8.encode(canonicalJson(publicHeader)),
        );
        metadata = Map<String, Object?>.from(
          jsonDecode(utf8.decode(clear)) as Map,
        );
      } catch (error) {
        throw SyncIntegrityException(
          'La clave es incorrecta o el paquete fue alterado.',
          error,
        );
      }
      final current = (now ?? DateTime.now()).toUtc();
      if (!current.isBefore(expiresAt)) {
        throw const SyncAuthorizationException('El paquete compartido expiró.');
      }
      final name = _safeName(metadata['name']);
      final mimeType = metadata['mimeType'];
      final expectedHash = metadata['sha256'];
      if (mimeType is! String ||
          mimeType.isEmpty ||
          mimeType.length > 255 ||
          expectedHash is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedHash)) {
        throw const FormatException('Los metadatos privados no son válidos.');
      }
      DateTime? modifiedAt;
      if (metadata['modifiedAt'] != null) {
        modifiedAt = DateTime.parse(metadata['modifiedAt']! as String);
      }

      if (!await privateTemporaryDirectory.exists()) {
        await privateTemporaryDirectory.create(recursive: true);
      }
      final encryptedName = '.${header['packageId']}.cipher';
      final contentOffset = _magic.length + 4 + headerLength;
      final remaining = packageFile.openRead(
        contentOffset,
        contentOffset + cipherSize,
      );
      final contentCipherFile = await AtomicFileWriter.writeStream(
        destinationDirectory: privateTemporaryDirectory,
        preferredName: encryptedName,
        bytes: remaining,
        expectedLength: cipherSize,
      );
      encryptedContent = contentCipherFile;

      final contentKey = await _deriveContentKey(capability, salt);
      final plaintextOutput = await AtomicFileWriter.writeStream(
        destinationDirectory: destinationDirectory,
        preferredName: name,
        bytes: StreamCipher.decryptStream(
          input: contentCipherFile,
          fileKey: contentKey,
          noncePrefix: contentNonce,
          plainFileSize: plainSize,
        ),
        expectedLength: plainSize,
        modifiedAt: modifiedAt,
      );
      published = plaintextOutput;
      final digest = await crypto.sha256.bind(plaintextOutput.openRead()).first;
      if (!_constantTimeStringEquals(digest.toString(), expectedHash)) {
        await plaintextOutput.delete();
        published = null;
        throw const SyncIntegrityException(
          'El contenido no coincide con el hash autenticado.',
        );
      }
      succeeded = true;
      return OpenedSharePackage(
        plaintextFile: plaintextOutput,
        originalName: name,
        mimeType: mimeType,
        modifiedAt: modifiedAt,
      );
    } finally {
      capabilityBytes.fillRange(0, capabilityBytes.length, 0);
      await reader.close();
      final cipherToDelete = encryptedContent;
      if (cipherToDelete != null && await cipherToDelete.exists()) {
        await cipherToDelete.delete();
      }
      final plaintextToDelete = published;
      if (!succeeded &&
          plaintextToDelete != null &&
          await plaintextToDelete.exists()) {
        await plaintextToDelete.delete();
      }
    }
  }

  static Map<String, Object?> _strictHeader(List<int> bytes) {
    try {
      final header = Map<String, Object?>.from(
        jsonDecode(utf8.decode(bytes)) as Map,
      );
      const keys = <String>{
        'version',
        'packageId',
        'createdAt',
        'expiresAt',
        'salt',
        'contentNonce',
        'plainSize',
        'cipherSize',
        'metadataNonce',
        'metadataCipherText',
        'metadataMac',
      };
      if (header.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(header.keys.toSet()).isNotEmpty ||
          header['version'] != _version ||
          header['packageId'] is! String ||
          (header['packageId']! as String).length > 64 ||
          header['createdAt'] is! String ||
          header['expiresAt'] is! String ||
          header['salt'] is! String ||
          header['contentNonce'] is! String ||
          header['plainSize'] is! num ||
          header['cipherSize'] is! num ||
          header['metadataNonce'] is! String ||
          header['metadataCipherText'] is! String ||
          header['metadataMac'] is! String) {
        throw const FormatException();
      }
      return header;
    } catch (_) {
      throw const FormatException('El encabezado del paquete no es válido.');
    }
  }

  static Future<SecretKey> _deriveContentKey(
    SecretKey capability,
    Uint8List salt,
  ) {
    return _contentKdf.deriveKey(
      secretKey: capability,
      nonce: salt,
      info: utf8.encode('PrivateSandbox/share/content/v1'),
    );
  }

  static Future<SecretKey> _deriveMetadataKey(
    SecretKey capability,
    Uint8List salt,
  ) {
    return _metadataKdf.deriveKey(
      secretKey: capability,
      nonce: salt,
      info: utf8.encode('PrivateSandbox/share/metadata/v1'),
    );
  }

  static int _cipherLengthFor(int plainSize) {
    if (plainSize == 0) return 0;
    final chunks =
        (plainSize + StreamCipher.chunkSize - 1) ~/ StreamCipher.chunkSize;
    return plainSize + chunks * _macBytes;
  }

  static Uint8List _uint32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    return data.buffer.asUint8List();
  }

  static Stream<List<int>> _concat(
    Uint8List prefix,
    File encryptedContent,
  ) async* {
    yield prefix;
    yield* encryptedContent.openRead();
  }

  static String _encodeCapability(Uint8List bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');

  static Uint8List _decodeCapability(String encoded) {
    if (encoded.length < 40 || encoded.length > 48) {
      throw const FormatException('La clave de compartición no es válida.');
    }
    final padded = encoded.padRight((encoded.length + 3) ~/ 4 * 4, '=');
    try {
      final bytes = Uint8List.fromList(base64Url.decode(padded));
      if (bytes.length != 32) throw const FormatException();
      return bytes;
    } on FormatException {
      throw const FormatException('La clave de compartición no es válida.');
    }
  }

  static Uint8List _decodeExact(
    String encoded,
    int length,
    String field,
  ) {
    final bytes = _decodeBounded(encoded, length * 2, field);
    if (bytes.length != length) {
      throw FormatException('$field tiene una longitud incorrecta.');
    }
    return bytes;
  }

  static Uint8List _decodeBounded(
    String encoded,
    int maximumBytes,
    String field,
  ) {
    if (encoded.length > maximumBytes * 2) {
      throw FormatException('$field excede el tamaño permitido.');
    }
    try {
      final bytes = Uint8List.fromList(base64Decode(encoded));
      if (bytes.length > maximumBytes) throw const FormatException();
      return bytes;
    } on FormatException {
      throw FormatException('$field no es Base64 válido.');
    }
  }

  static String _safeName(Object? value) {
    if (value is! String ||
        value.isEmpty ||
        value.length > 255 ||
        value.contains('/') ||
        value.contains('\\') ||
        value.codeUnits.any((unit) => unit < 32)) {
      throw const FormatException('El nombre contenido no es seguro.');
    }
    return value;
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  static bool _constantTimeStringEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
