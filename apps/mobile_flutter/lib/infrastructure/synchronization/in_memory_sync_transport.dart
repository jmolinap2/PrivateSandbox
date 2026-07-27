import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../domain/synchronization/sync_protocol.dart';
import '../../domain/synchronization/sync_transport.dart';

typedef BeforeMemoryPut = FutureOr<void> Function(String path, int length);

class _MemoryRemoteObject {
  final Uint8List bytes;
  final String etag;
  final DateTime lastModified;
  final String contentType;

  const _MemoryRemoteObject({
    required this.bytes,
    required this.etag,
    required this.lastModified,
    required this.contentType,
  });
}

/// Deterministic transport used by tests and offline peer-transfer adapters.
class InMemorySyncTransport implements SyncTransport {
  final Map<String, _MemoryRemoteObject> _objects =
      <String, _MemoryRemoteObject>{};
  final Set<String> _directories = <String>{};
  final DateTime Function() _clock;
  final BeforeMemoryPut? beforePut;

  int putCount = 0;

  InMemorySyncTransport({DateTime Function()? clock, this.beforePut})
    : _clock = clock ?? DateTime.now;

  @override
  Future<RemoteObjectMetadata?> head(String path) async {
    final normalized = normalizeRemotePath(path);
    final object = _objects[normalized];
    return object == null ? null : _metadata(normalized, object);
  }

  @override
  Future<RemoteReadHandle> get(
    String path, {
    int start = 0,
    int? endExclusive,
  }) async {
    final normalized = normalizeRemotePath(path);
    final object = _objects[normalized];
    if (object == null) {
      throw SyncTransportException(
        'Remote object does not exist: $normalized',
        statusCode: 404,
      );
    }
    final end = endExclusive ?? object.bytes.length;
    if (start < 0 ||
        start > object.bytes.length ||
        end < start ||
        end > object.bytes.length) {
      throw SyncTransportException(
        'Invalid byte range $start..$end for ${object.bytes.length} bytes',
        statusCode: 416,
      );
    }
    final bytes = Uint8List.fromList(object.bytes.sublist(start, end));
    return RemoteReadHandle(
      metadata: _metadata(normalized, object),
      bytes: Stream<List<int>>.value(bytes),
      rangeStart: start,
      rangeEndExclusive: end,
    );
  }

  @override
  Future<RemoteObjectMetadata> put(
    String path,
    Stream<List<int>> bytes, {
    required int length,
    String contentType = SyncProtocol.blobContentType,
    String? ifMatch,
    bool ifNoneMatch = false,
  }) async {
    final normalized = normalizeRemotePath(path);
    final existing = _objects[normalized];
    if (ifNoneMatch && existing != null) {
      throw SyncPreconditionFailed('$normalized already exists');
    }
    if (ifMatch != null && (existing == null || existing.etag != ifMatch)) {
      throw SyncPreconditionFailed('ETag changed for $normalized');
    }
    await beforePut?.call(normalized, length);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in bytes) {
      builder.add(chunk);
      if (builder.length > length) {
        throw SyncTransportException(
          'Upload exceeded declared length for $normalized',
        );
      }
    }
    final value = builder.takeBytes();
    if (value.length != length) {
      throw SyncTransportException(
        'Upload length mismatch for $normalized: '
        'expected $length, received ${value.length}',
      );
    }
    final digest = crypto.sha256.convert(value).toString();
    final stored = _MemoryRemoteObject(
      bytes: value,
      etag: '"sha256-$digest"',
      lastModified: _clock().toUtc(),
      contentType: contentType,
    );
    _objects[normalized] = stored;
    putCount++;
    return _metadata(normalized, stored);
  }

  @override
  Future<void> delete(String path, {String? ifMatch}) async {
    final normalized = normalizeRemotePath(path);
    final existing = _objects[normalized];
    if (existing == null) return;
    if (ifMatch != null && existing.etag != ifMatch) {
      throw SyncPreconditionFailed('ETag changed for $normalized');
    }
    _objects.remove(normalized);
  }

  @override
  Future<void> ensureDirectory(String path) async {
    final normalized = normalizeRemotePath(path);
    final parts = normalized.split('/');
    for (var index = 1; index <= parts.length; index++) {
      _directories.add(parts.take(index).join('/'));
    }
  }

  @override
  Future<List<RemoteObjectMetadata>> list(String directory) async {
    final normalized = normalizeRemotePath(directory);
    final prefix = '$normalized/';
    final result =
        _objects.entries
            .where((entry) => entry.key.startsWith(prefix))
            .map((entry) => _metadata(entry.key, entry.value))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    return result;
  }

  /// Deliberate corruption hook for integrity tests.
  void corrupt(String path, int offset) {
    final normalized = normalizeRemotePath(path);
    final current = _objects[normalized];
    if (current == null) throw StateError('No object at $normalized');
    if (offset < 0 || offset >= current.bytes.length) {
      throw RangeError.index(offset, current.bytes);
    }
    final changed = Uint8List.fromList(current.bytes);
    changed[offset] ^= 0xff;
    _objects[normalized] = _MemoryRemoteObject(
      bytes: changed,
      etag: current.etag,
      lastModified: current.lastModified,
      contentType: current.contentType,
    );
  }

  RemoteObjectMetadata _metadata(String path, _MemoryRemoteObject object) {
    return RemoteObjectMetadata(
      path: path,
      length: object.bytes.length,
      etag: object.etag,
      lastModified: object.lastModified,
      contentType: object.contentType,
    );
  }
}
