import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A minimal, dependency-free container format for a full vault backup:
///
/// ```
/// [5 bytes]  magic "PSVB1"
/// [4 bytes]  big-endian manifest length N
/// [N bytes]  manifest JSON (utf8) — see [VaultBackupManifest]
/// [...]      each file's raw bytes, back-to-back, in manifest order
/// ```
///
/// No general-purpose archive library is pulled in for this — the format
/// only ever needs to round-trip through this app, and hand-rolling it
/// avoids adding a new dependency for what's otherwise ~80 lines.
class VaultBackupCodec {
  const VaultBackupCodec._();

  static const magic = 'PSVB1';

  static Future<void> write({
    required File destination,
    required VaultBackupManifest manifest,
    required File dbFile,
    required List<File> blobFiles,
  }) async {
    final sink = destination.openWrite();
    try {
      sink.add(utf8.encode(magic));
      final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
      final lengthBytes = ByteData(4)..setUint32(0, manifestBytes.length, Endian.big);
      sink.add(lengthBytes.buffer.asUint8List());
      sink.add(manifestBytes);

      await sink.addStream(dbFile.openRead());
      for (final blob in blobFiles) {
        await sink.addStream(blob.openRead());
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Reads just the manifest, without extracting any file contents — used
  /// to validate a backup (and unwrap its key) before committing to
  /// overwriting anything.
  static Future<VaultBackupManifest> readManifest(File source) async {
    final raf = await source.open();
    try {
      final magicBytes = await raf.read(magic.length);
      if (utf8.decode(magicBytes) != magic) {
        throw const FormatException('No es un archivo de copia de seguridad válido.');
      }
      final lengthBytes = await raf.read(4);
      final length = ByteData.sublistView(Uint8List.fromList(lengthBytes)).getUint32(0, Endian.big);
      final manifestBytes = await raf.read(length);
      return VaultBackupManifest.fromJson(jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>);
    } finally {
      await raf.close();
    }
  }

  /// Extracts every file listed in [manifest] from [source] into [outputDir],
  /// using the same layout: the DB file directly in [outputDir], blobs under
  /// `outputDir/blobs/`.
  static Future<void> extract({
    required File source,
    required VaultBackupManifest manifest,
    required Directory outputDir,
  }) async {
    final raf = await source.open();
    try {
      // Read the real manifest length from disk rather than re-encoding
      // [manifest] and trusting it matches byte-for-byte.
      await raf.setPosition(magic.length);
      final lengthBytes = await raf.read(4);
      final manifestLength = ByteData.sublistView(Uint8List.fromList(lengthBytes)).getUint32(0, Endian.big);
      await raf.setPosition(magic.length + 4 + manifestLength);

      final dbOut = File('${outputDir.path}${Platform.pathSeparator}${manifest.dbFile.name}');
      await _copyBytes(raf, dbOut, manifest.dbFile.size);

      final blobsDir = Directory('${outputDir.path}${Platform.pathSeparator}blobs');
      if (!await blobsDir.exists()) await blobsDir.create(recursive: true);
      for (final blob in manifest.blobFiles) {
        final blobOut = File('${blobsDir.path}${Platform.pathSeparator}${blob.name}');
        await _copyBytes(raf, blobOut, blob.size);
      }
    } finally {
      await raf.close();
    }
  }

  static Future<void> _copyBytes(RandomAccessFile source, File destination, int length) async {
    final sink = destination.openWrite();
    try {
      var remaining = length;
      const chunkSize = 1024 * 1024;
      while (remaining > 0) {
        final toRead = remaining < chunkSize ? remaining : chunkSize;
        final chunk = await source.read(toRead);
        if (chunk.isEmpty) break;
        sink.add(chunk);
        remaining -= chunk.length;
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }
}

class VaultBackupFileEntry {
  final String name;
  final int size;

  const VaultBackupFileEntry({required this.name, required this.size});

  Map<String, dynamic> toJson() => {'name': name, 'size': size};

  factory VaultBackupFileEntry.fromJson(Map<String, dynamic> json) =>
      VaultBackupFileEntry(name: json['name'] as String, size: json['size'] as int);
}

class VaultBackupManifest {
  final String createdAt;
  final String kdfSaltBase64;
  final int kdfIterations;
  final String wrappedKeyNonceBase64;
  final String wrappedKeyCipherTextBase64;
  final String wrappedKeyMacBase64;
  final VaultBackupFileEntry dbFile;
  final List<VaultBackupFileEntry> blobFiles;

  const VaultBackupManifest({
    required this.createdAt,
    required this.kdfSaltBase64,
    required this.kdfIterations,
    required this.wrappedKeyNonceBase64,
    required this.wrappedKeyCipherTextBase64,
    required this.wrappedKeyMacBase64,
    required this.dbFile,
    required this.blobFiles,
  });

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt,
        'kdfSaltBase64': kdfSaltBase64,
        'kdfIterations': kdfIterations,
        'wrappedKeyNonceBase64': wrappedKeyNonceBase64,
        'wrappedKeyCipherTextBase64': wrappedKeyCipherTextBase64,
        'wrappedKeyMacBase64': wrappedKeyMacBase64,
        'dbFile': dbFile.toJson(),
        'blobFiles': [for (final b in blobFiles) b.toJson()],
      };

  factory VaultBackupManifest.fromJson(Map<String, dynamic> json) => VaultBackupManifest(
        createdAt: json['createdAt'] as String,
        kdfSaltBase64: json['kdfSaltBase64'] as String,
        kdfIterations: json['kdfIterations'] as int,
        wrappedKeyNonceBase64: json['wrappedKeyNonceBase64'] as String,
        wrappedKeyCipherTextBase64: json['wrappedKeyCipherTextBase64'] as String,
        wrappedKeyMacBase64: json['wrappedKeyMacBase64'] as String,
        dbFile: VaultBackupFileEntry.fromJson(json['dbFile'] as Map<String, dynamic>),
        blobFiles: [
          for (final b in json['blobFiles'] as List<dynamic>) VaultBackupFileEntry.fromJson(b as Map<String, dynamic>),
        ],
      );
}
