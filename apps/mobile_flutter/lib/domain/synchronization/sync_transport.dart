import 'dart:async';

import 'sync_protocol.dart';

class RemoteObjectMetadata {
  final String path;
  final int length;
  final String? etag;
  final DateTime? lastModified;
  final String? contentType;

  const RemoteObjectMetadata({
    required this.path,
    required this.length,
    this.etag,
    this.lastModified,
    this.contentType,
  });
}

class RemoteReadHandle {
  final RemoteObjectMetadata metadata;
  final Stream<List<int>> bytes;
  final int rangeStart;
  final int? rangeEndExclusive;

  const RemoteReadHandle({
    required this.metadata,
    required this.bytes,
    this.rangeStart = 0,
    this.rangeEndExclusive,
  });
}

/// Provider-neutral storage surface required by synchronization.
///
/// Conditional writes are essential: the manifest is committed with an ETag
/// compare-and-swap so concurrent devices merge instead of overwriting.
abstract interface class SyncTransport {
  Future<RemoteObjectMetadata?> head(String path);

  Future<RemoteReadHandle> get(String path, {int start = 0, int? endExclusive});

  Future<RemoteObjectMetadata> put(
    String path,
    Stream<List<int>> bytes, {
    required int length,
    String contentType = SyncProtocol.blobContentType,
    String? ifMatch,
    bool ifNoneMatch = false,
  });

  Future<void> delete(String path, {String? ifMatch});

  Future<void> ensureDirectory(String path);

  Future<List<RemoteObjectMetadata>> list(String directory);
}
