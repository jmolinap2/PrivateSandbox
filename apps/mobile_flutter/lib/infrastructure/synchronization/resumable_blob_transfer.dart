// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import '../../domain/synchronization/sync_manifest.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../domain/synchronization/sync_transport.dart';

enum SyncTransferDirection { upload, download }

class SyncTransferProgress {
  final SyncTransferDirection direction;
  final String objectId;
  final int transferredBytes;
  final int totalBytes;
  final int completedChunks;
  final int totalChunks;

  const SyncTransferProgress({
    required this.direction,
    required this.objectId,
    required this.transferredBytes,
    required this.totalBytes,
    required this.completedChunks,
    required this.totalChunks,
  });

  double get fraction => totalBytes == 0 ? 1 : transferredBytes / totalBytes;
}

typedef SyncProgressCallback = void Function(SyncTransferProgress progress);

/// Chunk-addressed upload/download with integrity-checked restart support.
///
/// WebDAV has no portable append-upload extension. Using immutable,
/// content-addressed chunk objects provides resumability on every WebDAV
/// server: already verified chunks are skipped and the encrypted manifest is
/// committed only once the descriptor is complete.
class ResumableBlobTransfer {
  final SyncTransport _transport;
  final int chunkSize;

  const ResumableBlobTransfer({
    required SyncTransport transport,
    this.chunkSize = SyncProtocol.defaultChunkSize,
  }) : _transport = transport,
       assert(chunkSize > 0);

  Future<SyncBlobDescriptor> describe({
    required String vaultId,
    required File encryptedFile,
    bool Function()? isCancelled,
  }) async {
    final fileSize = await encryptedFile.length();
    final reader = await encryptedFile.open();
    final fullDigestSink = _DigestSink();
    final fullHash = crypto.sha256.startChunkedConversion(fullDigestSink);
    final chunks = <({int index, int size, String sha256})>[];
    try {
      var index = 0;
      var remaining = fileSize;
      while (remaining > 0) {
        if (isCancelled?.call() ?? false) {
          throw const SyncCancelledException();
        }
        final expected = remaining < chunkSize ? remaining : chunkSize;
        final bytes = await reader.read(expected);
        if (bytes.length != expected) {
          throw const SyncIntegrityException(
            'Encrypted file changed while it was being described',
          );
        }
        fullHash.add(bytes);
        chunks.add((
          index: index,
          size: bytes.length,
          sha256: crypto.sha256.convert(bytes).toString(),
        ));
        remaining -= bytes.length;
        index++;
      }
      fullHash.close();
    } finally {
      await reader.close();
    }
    final digest = fullDigestSink.value.toString();
    final objectId = digest;
    return SyncBlobDescriptor(
      objectId: objectId,
      size: fileSize,
      sha256: digest,
      chunkSize: chunkSize,
      chunks: chunks
          .map(
            (chunk) => SyncBlobChunk(
              index: chunk.index,
              path: _chunkPath(vaultId, objectId, chunk.index, chunk.sha256),
              size: chunk.size,
              sha256: chunk.sha256,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<SyncBlobDescriptor> upload({
    required String vaultId,
    required File encryptedFile,
    SyncBlobDescriptor? descriptor,
    bool verifyExistingChunks = true,
    int? bandwidthLimitBytesPerSecond,
    bool Function()? isCancelled,
    SyncProgressCallback? onProgress,
  }) async {
    final prepared =
        descriptor ??
        await describe(
          vaultId: vaultId,
          encryptedFile: encryptedFile,
          isCancelled: isCancelled,
        );
    if (prepared.sha256 != prepared.objectId) {
      throw const SyncIntegrityException(
        'Blob object identifier is not content-addressed',
      );
    }
    final currentDescription = descriptor == null
        ? prepared
        : await describe(
            vaultId: vaultId,
            encryptedFile: encryptedFile,
            isCancelled: isCancelled,
          );
    if (currentDescription.sha256 != prepared.sha256 ||
        currentDescription.size != prepared.size) {
      throw const SyncIntegrityException(
        'Encrypted file no longer matches its sync descriptor',
      );
    }

    final objectDirectory = 'vaults/$vaultId/objects/${prepared.objectId}';
    await _transport.ensureDirectory('vaults');
    await _transport.ensureDirectory('vaults/$vaultId');
    await _transport.ensureDirectory('vaults/$vaultId/objects');
    await _transport.ensureDirectory(objectDirectory);
    await _transport.ensureDirectory('$objectDirectory/chunks');

    var transferred = 0;
    var completed = 0;
    for (final chunk in prepared.chunks) {
      if (isCancelled?.call() ?? false) {
        throw const SyncCancelledException();
      }
      final existing = await _transport.head(chunk.path);
      var skip = false;
      if (existing != null && existing.length == chunk.size) {
        skip =
            !verifyExistingChunks ||
            await _remoteChunkMatches(chunk, isCancelled: isCancelled);
      }
      if (!skip) {
        final start = chunk.index * prepared.chunkSize;
        final clearStream = encryptedFile.openRead(start, start + chunk.size);
        final uploadStream = _throttle(
          clearStream,
          bytesPerSecond: bandwidthLimitBytesPerSecond,
          isCancelled: isCancelled,
        );
        try {
          await _transport.put(
            chunk.path,
            uploadStream,
            length: chunk.size,
            ifMatch: existing?.etag,
            ifNoneMatch: existing == null,
          );
        } on SyncPreconditionFailed {
          if (!await _remoteChunkMatches(chunk, isCancelled: isCancelled)) {
            rethrow;
          }
        }
      }
      transferred += chunk.size;
      completed++;
      onProgress?.call(
        SyncTransferProgress(
          direction: SyncTransferDirection.upload,
          objectId: prepared.objectId,
          transferredBytes: transferred,
          totalBytes: prepared.size,
          completedChunks: completed,
          totalChunks: prepared.chunks.length,
        ),
      );
    }
    if (prepared.chunks.isEmpty) {
      onProgress?.call(
        SyncTransferProgress(
          direction: SyncTransferDirection.upload,
          objectId: prepared.objectId,
          transferredBytes: 0,
          totalBytes: 0,
          completedChunks: 0,
          totalChunks: 0,
        ),
      );
    }
    final finalDescription = await describe(
      vaultId: vaultId,
      encryptedFile: encryptedFile,
      isCancelled: isCancelled,
    );
    if (finalDescription.sha256 != prepared.sha256 ||
        finalDescription.size != prepared.size ||
        !_sameChunks(finalDescription.chunks, prepared.chunks)) {
      throw const SyncIntegrityException(
        'Encrypted file changed while it was being uploaded',
      );
    }
    return prepared;
  }

  Future<File> download({
    required SyncBlobDescriptor descriptor,
    required File target,
    int? bandwidthLimitBytesPerSecond,
    bool Function()? isCancelled,
    SyncProgressCallback? onProgress,
  }) async {
    if (await target.exists()) {
      if (await _fileMatches(target, descriptor.sha256, descriptor.size)) {
        return target;
      }
      throw SyncIntegrityException(
        'Refusing to overwrite an unrelated local file: ${target.path}',
      );
    }
    final parent = target.parent;
    if (!await parent.exists()) await parent.create(recursive: true);
    final partial = File('${target.path}.sync.part');
    if (!await partial.exists()) await partial.create();

    final completedPrefix = await _validatedPartialPrefix(partial, descriptor);
    var completed = completedPrefix.completedChunks;
    var transferred = completedPrefix.bytes;
    onProgress?.call(
      SyncTransferProgress(
        direction: SyncTransferDirection.download,
        objectId: descriptor.objectId,
        transferredBytes: transferred,
        totalBytes: descriptor.size,
        completedChunks: completed,
        totalChunks: descriptor.chunks.length,
      ),
    );

    for (final chunk in descriptor.chunks.skip(completed)) {
      if (isCancelled?.call() ?? false) {
        throw const SyncCancelledException();
      }
      final chunkStart = transferred;
      final output = await partial.open(mode: FileMode.append);
      final digestSink = _DigestSink();
      final hash = crypto.sha256.startChunkedConversion(digestSink);
      var received = 0;
      try {
        final remote = await _transport.get(chunk.path);
        await for (final bytes in _throttle(
          remote.bytes,
          bytesPerSecond: bandwidthLimitBytesPerSecond,
          isCancelled: isCancelled,
        )) {
          received += bytes.length;
          if (received > chunk.size) {
            throw const SyncIntegrityException(
              'Remote chunk exceeded its declared size',
            );
          }
          hash.add(bytes);
          await output.writeFrom(bytes);
        }
        hash.close();
        if (received != chunk.size ||
            digestSink.value.toString() != chunk.sha256) {
          throw const SyncIntegrityException(
            'Remote encrypted chunk failed SHA-256 validation',
          );
        }
      } catch (_) {
        await output.truncate(chunkStart);
        rethrow;
      } finally {
        await output.close();
      }
      transferred += chunk.size;
      completed++;
      onProgress?.call(
        SyncTransferProgress(
          direction: SyncTransferDirection.download,
          objectId: descriptor.objectId,
          transferredBytes: transferred,
          totalBytes: descriptor.size,
          completedChunks: completed,
          totalChunks: descriptor.chunks.length,
        ),
      );
    }
    if (!await _fileMatches(partial, descriptor.sha256, descriptor.size)) {
      throw const SyncIntegrityException(
        'Downloaded encrypted blob failed final SHA-256 validation',
      );
    }
    return partial.rename(target.path);
  }

  Future<bool> _remoteChunkMatches(
    SyncBlobChunk chunk, {
    bool Function()? isCancelled,
  }) async {
    try {
      final remote = await _transport.get(chunk.path);
      final sink = _DigestSink();
      final hash = crypto.sha256.startChunkedConversion(sink);
      var length = 0;
      await for (final bytes in remote.bytes) {
        if (isCancelled?.call() ?? false) {
          throw const SyncCancelledException();
        }
        length += bytes.length;
        if (length > chunk.size) return false;
        hash.add(bytes);
      }
      hash.close();
      return length == chunk.size && sink.value.toString() == chunk.sha256;
    } on SyncCancelledException {
      rethrow;
    } on SyncException {
      return false;
    }
  }

  Future<({int completedChunks, int bytes})> _validatedPartialPrefix(
    File partial,
    SyncBlobDescriptor descriptor,
  ) async {
    final fileLength = await partial.length();
    if (fileLength > descriptor.size) {
      await partial.open(mode: FileMode.write).then((file) async {
        await file.truncate(0);
        await file.close();
      });
      return (completedChunks: 0, bytes: 0);
    }
    final reader = await partial.open();
    var validBytes = 0;
    var validChunks = 0;
    try {
      for (final chunk in descriptor.chunks) {
        if (fileLength - validBytes < chunk.size) break;
        final bytes = await reader.read(chunk.size);
        if (bytes.length != chunk.size ||
            crypto.sha256.convert(bytes).toString() != chunk.sha256) {
          break;
        }
        validBytes += chunk.size;
        validChunks++;
      }
    } finally {
      await reader.close();
    }
    if (fileLength != validBytes) {
      final writer = await partial.open(mode: FileMode.append);
      await writer.truncate(validBytes);
      await writer.close();
    }
    return (completedChunks: validChunks, bytes: validBytes);
  }

  Future<bool> _fileMatches(File file, String expectedHash, int size) async {
    if (!await file.exists() || await file.length() != size) return false;
    final digest = await crypto.sha256.bind(file.openRead()).first;
    return digest.toString() == expectedHash;
  }

  Stream<List<int>> _throttle(
    Stream<List<int>> source, {
    required int? bytesPerSecond,
    required bool Function()? isCancelled,
  }) async* {
    if (bytesPerSecond == null) {
      await for (final bytes in source) {
        if (isCancelled?.call() ?? false) {
          throw const SyncCancelledException();
        }
        yield bytes;
      }
      return;
    }
    final watch = Stopwatch()..start();
    var bytesSoFar = 0;
    await for (final bytes in source) {
      if (isCancelled?.call() ?? false) {
        throw const SyncCancelledException();
      }
      bytesSoFar += bytes.length;
      final expectedMicros =
          (bytesSoFar * Duration.microsecondsPerSecond) ~/ bytesPerSecond;
      final remainingMicros = expectedMicros - watch.elapsedMicroseconds;
      if (remainingMicros > 0) {
        await Future<void>.delayed(Duration(microseconds: remainingMicros));
      }
      yield bytes;
    }
  }

  static String _chunkPath(
    String vaultId,
    String objectId,
    int index,
    String chunkHash,
  ) {
    final number = index.toString().padLeft(8, '0');
    return normalizeRemotePath(
      'vaults/$vaultId/objects/$objectId/chunks/$number-$chunkHash.bin',
    );
  }

  static bool _sameChunks(List<SyncBlobChunk> left, List<SyncBlobChunk> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].size != right[index].size ||
          left[index].sha256 != right[index].sha256 ||
          left[index].path != right[index].path) {
        return false;
      }
    }
    return true;
  }
}

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _digest;

  crypto.Digest get value {
    final value = _digest;
    if (value == null) {
      throw StateError('Digest is not available before the sink is closed');
    }
    return value;
  }

  @override
  void add(crypto.Digest data) => _digest = data;

  @override
  void close() {}
}
