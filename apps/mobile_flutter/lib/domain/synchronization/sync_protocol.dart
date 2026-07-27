import 'dart:convert';

/// Wire-level constants for the encrypted synchronization protocol.
///
/// Version numbers are explicit on every remotely persisted envelope. Readers
/// must reject versions they do not understand instead of attempting a
/// best-effort parse that could silently lose fields.
abstract final class SyncProtocol {
  static const int currentVersion = 1;
  static const int minimumSupportedVersion = 1;
  static const int maximumManifestBytes = 16 * 1024 * 1024;
  static const int defaultChunkSize = 4 * 1024 * 1024;

  static const String manifestContentType =
      'application/vnd.private-sandbox.sync-manifest+json;version=1';
  static const String blobContentType = 'application/octet-stream';

  static void requireSupported(int version) {
    if (version < minimumSupportedVersion || version > currentVersion) {
      throw SyncProtocolException(
        'Unsupported sync protocol version $version '
        '(supported: $minimumSupportedVersion..$currentVersion)',
      );
    }
  }
}

/// Produces stable JSON bytes for hashes, signatures and AEAD associated data.
///
/// JSON object keys are sorted recursively. Lists preserve their order and
/// numeric/string values retain normal [jsonEncode] semantics.
String canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries =
        value.entries
            .map((entry) => MapEntry(entry.key.toString(), entry.value))
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key));
    return <String, Object?>{
      for (final entry in entries) entry.key: _canonicalize(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value is String || value is num || value is bool || value == null) {
    return value;
  }
  throw ArgumentError.value(
    value,
    'value',
    'Not representable as canonical JSON',
  );
}

/// Normalizes an opaque path used by a remote transport.
///
/// Paths are always relative, slash-separated and traversal-free. Remote
/// transport implementations must call this before resolving a path against
/// their base URI.
String normalizeRemotePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    throw ArgumentError.value(path, 'path', 'Remote path cannot be empty');
  }
  if (parts.any((part) => part == '.' || part == '..')) {
    throw ArgumentError.value(
      path,
      'path',
      'Remote path traversal is forbidden',
    );
  }
  return parts.join('/');
}

sealed class SyncException implements Exception {
  final String message;
  final Object? cause;

  const SyncException(this.message, [this.cause]);

  @override
  String toString() {
    final suffix = cause == null ? '' : ': $cause';
    return '$runtimeType: $message$suffix';
  }
}

final class SyncProtocolException extends SyncException {
  const SyncProtocolException(super.message, [super.cause]);
}

final class SyncIntegrityException extends SyncException {
  const SyncIntegrityException(super.message, [super.cause]);
}

final class SyncAuthorizationException extends SyncException {
  const SyncAuthorizationException(super.message, [super.cause]);
}

final class SyncTransportException extends SyncException {
  final int? statusCode;

  const SyncTransportException(String message, {this.statusCode, Object? cause})
    : super(message, cause);
}

/// Signals an optimistic-concurrency failure (HTTP 412 or its equivalent).
final class SyncPreconditionFailed extends SyncException {
  const SyncPreconditionFailed(super.message);
}

final class SyncCancelledException extends SyncException {
  const SyncCancelledException() : super('Synchronization was cancelled');
}
