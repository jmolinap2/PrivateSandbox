import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/synchronization/sync_protocol.dart';
import '../../domain/synchronization/sync_transport.dart';

class WebDavCredentials {
  final String? authorizationHeader;

  const WebDavCredentials._(this.authorizationHeader);

  const WebDavCredentials.none() : this._(null);

  factory WebDavCredentials.basic({
    required String username,
    required String password,
  }) {
    return WebDavCredentials._(
      'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    );
  }

  factory WebDavCredentials.bearer(String token) {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, 'token', 'Cannot be blank');
    }
    return WebDavCredentials._('Bearer $token');
  }
}

/// Dependency-free WebDAV transport backed by [HttpClient].
class WebDavSyncTransport implements SyncTransport {
  final Uri baseUri;
  final WebDavCredentials credentials;
  final HttpClient _client;
  final Duration requestTimeout;

  WebDavSyncTransport({
    required Uri baseUri,
    this.credentials = const WebDavCredentials.none(),
    HttpClient? client,
    this.requestTimeout = const Duration(seconds: 45),
    bool allowInsecureHttpForTesting = false,
  }) : baseUri = _normalizeBaseUri(baseUri),
       _client = client ?? HttpClient() {
    if (baseUri.scheme != 'https' &&
        !(allowInsecureHttpForTesting && baseUri.scheme == 'http')) {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'WebDAV requires HTTPS outside explicit local tests',
      );
    }
    _client.connectionTimeout = requestTimeout;
  }

  void close({bool force = false}) => _client.close(force: force);

  @override
  Future<RemoteObjectMetadata?> head(String path) async {
    final normalized = normalizeRemotePath(path);
    final request = await _open('HEAD', normalized);
    final response = await request.close().timeout(requestTimeout);
    await response.drain<void>();
    if (response.statusCode == HttpStatus.notFound) return null;
    _requireStatus(response, const <int>[HttpStatus.ok, HttpStatus.noContent]);
    return _metadata(normalized, response);
  }

  @override
  Future<RemoteReadHandle> get(
    String path, {
    int start = 0,
    int? endExclusive,
  }) async {
    if (start < 0 || (endExclusive != null && endExclusive < start)) {
      throw ArgumentError('Invalid byte range');
    }
    final normalized = normalizeRemotePath(path);
    final request = await _open('GET', normalized);
    if (start != 0 || endExclusive != null) {
      final end = endExclusive == null ? '' : '${endExclusive - 1}';
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
    }
    final response = await request.close().timeout(requestTimeout);
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      throw SyncTransportException(
        'WebDAV object not found: $normalized',
        statusCode: response.statusCode,
      );
    }
    final ranged = start != 0 || endExclusive != null;
    _requireStatus(
      response,
      ranged
          ? const <int>[HttpStatus.partialContent]
          : const <int>[HttpStatus.ok],
    );
    return RemoteReadHandle(
      metadata: _metadata(normalized, response),
      bytes: response,
      rangeStart: start,
      rangeEndExclusive: endExclusive,
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
    final request = await _open('PUT', normalized);
    request.contentLength = length;
    request.headers.contentType = ContentType.parse(contentType);
    if (ifMatch != null) {
      request.headers.set(HttpHeaders.ifMatchHeader, ifMatch);
    }
    if (ifNoneMatch) request.headers.set(HttpHeaders.ifNoneMatchHeader, '*');
    await request.addStream(bytes);
    final response = await request.close().timeout(requestTimeout);
    if (response.statusCode == HttpStatus.preconditionFailed) {
      await response.drain<void>();
      throw SyncPreconditionFailed(
        'WebDAV precondition failed for $normalized',
      );
    }
    _requireStatus(response, const <int>[
      HttpStatus.ok,
      HttpStatus.created,
      HttpStatus.noContent,
    ]);
    final responseMetadata = _metadata(normalized, response);
    await response.drain<void>();
    if (responseMetadata.etag != null) return responseMetadata;
    final persisted = await head(normalized);
    if (persisted == null) {
      throw SyncTransportException(
        'WebDAV PUT succeeded but object cannot be read: $normalized',
      );
    }
    return persisted;
  }

  @override
  Future<void> delete(String path, {String? ifMatch}) async {
    final normalized = normalizeRemotePath(path);
    final request = await _open('DELETE', normalized);
    if (ifMatch != null) {
      request.headers.set(HttpHeaders.ifMatchHeader, ifMatch);
    }
    final response = await request.close().timeout(requestTimeout);
    await response.drain<void>();
    if (response.statusCode == HttpStatus.notFound) return;
    if (response.statusCode == HttpStatus.preconditionFailed) {
      throw SyncPreconditionFailed(
        'WebDAV precondition failed for $normalized',
      );
    }
    _requireStatus(response, const <int>[
      HttpStatus.ok,
      HttpStatus.accepted,
      HttpStatus.noContent,
    ]);
  }

  @override
  Future<void> ensureDirectory(String path) async {
    final normalized = normalizeRemotePath(path);
    final segments = normalized.split('/');
    for (var index = 1; index <= segments.length; index++) {
      final current = segments.take(index).join('/');
      final request = await _open('MKCOL', current);
      final response = await request.close().timeout(requestTimeout);
      await response.drain<void>();
      if (response.statusCode == HttpStatus.created ||
          response.statusCode == HttpStatus.ok ||
          response.statusCode == HttpStatus.noContent ||
          response.statusCode == HttpStatus.methodNotAllowed) {
        continue;
      }
      _requireStatus(response, const <int>[HttpStatus.created]);
    }
  }

  @override
  Future<List<RemoteObjectMetadata>> list(String directory) async {
    final normalized = normalizeRemotePath(directory);
    final request = await _open('PROPFIND', normalized);
    request.headers.set('Depth', '1');
    request.headers.contentType = ContentType(
      'application',
      'xml',
      charset: 'utf-8',
    );
    const body =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<d:propfind xmlns:d="DAV:"><d:prop>'
        '<d:getcontentlength/><d:getetag/><d:getlastmodified/>'
        '<d:getcontenttype/></d:prop></d:propfind>';
    request.contentLength = utf8.encode(body).length;
    request.write(body);
    final response = await request.close().timeout(requestTimeout);
    _requireStatus(response, const <int>[207]);
    final xml = await utf8.decoder.bind(response).join();
    return _parseMultiStatus(normalized, xml);
  }

  Future<HttpClientRequest> _open(String method, String path) async {
    final request = await _client
        .openUrl(method, _resolve(path))
        .timeout(requestTimeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.userAgentHeader, 'PrivateSandbox-Sync/1');
    final authorization = credentials.authorizationHeader;
    if (authorization != null) {
      request.headers.set(HttpHeaders.authorizationHeader, authorization);
    }
    return request;
  }

  Uri _resolve(String path) {
    final encoded = normalizeRemotePath(
      path,
    ).split('/').map(Uri.encodeComponent).join('/');
    return baseUri.resolve(encoded);
  }

  RemoteObjectMetadata _metadata(String path, HttpClientResponse response) {
    var length = response.contentLength;
    final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null) {
      final match = RegExp(r'/(\d+)$').firstMatch(contentRange);
      if (match != null) length = int.parse(match.group(1)!);
    }
    return RemoteObjectMetadata(
      path: path,
      length: length < 0 ? 0 : length,
      etag: response.headers.value(HttpHeaders.etagHeader),
      lastModified:
          response.headers.value(HttpHeaders.lastModifiedHeader) == null
          ? null
          : HttpDate.parse(
              response.headers.value(HttpHeaders.lastModifiedHeader)!,
            ).toUtc(),
      contentType: response.headers.contentType?.toString(),
    );
  }

  List<RemoteObjectMetadata> _parseMultiStatus(String directory, String xml) {
    final responsePattern = RegExp(
      r'<(?:[A-Za-z0-9_-]+:)?response\b[^>]*>(.*?)'
      r'</(?:[A-Za-z0-9_-]+:)?response>',
      caseSensitive: false,
      dotAll: true,
    );
    final result = <RemoteObjectMetadata>[];
    for (final match in responsePattern.allMatches(xml)) {
      final block = match.group(1)!;
      final href = _xmlValue(block, 'href');
      if (href == null) continue;
      final absolute = baseUri.resolve(_decodeXml(href));
      final relativeSegments = absolute.pathSegments.skip(
        baseUri.pathSegments.where((segment) => segment.isNotEmpty).length,
      );
      final relative = relativeSegments
          .where((segment) => segment.isNotEmpty)
          .map(Uri.decodeComponent)
          .join('/');
      if (relative.isEmpty || relative == directory) continue;
      final length = int.tryParse(_xmlValue(block, 'getcontentlength') ?? '');
      if (length == null) continue;
      final modifiedRaw = _xmlValue(block, 'getlastmodified');
      result.add(
        RemoteObjectMetadata(
          path: normalizeRemotePath(relative),
          length: length,
          etag: _xmlValue(block, 'getetag'),
          lastModified: modifiedRaw == null
              ? null
              : HttpDate.parse(modifiedRaw).toUtc(),
          contentType: _xmlValue(block, 'getcontenttype'),
        ),
      );
    }
    result.sort((left, right) => left.path.compareTo(right.path));
    return result;
  }

  static String? _xmlValue(String xml, String localName) {
    final match = RegExp(
      '<(?:[A-Za-z0-9_-]+:)?$localName\\b[^>]*>(.*?)'
      '</(?:[A-Za-z0-9_-]+:)?$localName>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(xml);
    return match == null ? null : _decodeXml(match.group(1)!.trim());
  }

  static String _decodeXml(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  static Uri _normalizeBaseUri(Uri value) {
    final path = value.path.endsWith('/') ? value.path : '${value.path}/';
    return value.replace(path: path, query: null, fragment: null);
  }

  static void _requireStatus(HttpClientResponse response, List<int> accepted) {
    if (response.statusCode == HttpStatus.preconditionFailed) {
      throw const SyncPreconditionFailed('WebDAV precondition failed');
    }
    if (!accepted.contains(response.statusCode)) {
      throw SyncTransportException(
        'Unexpected WebDAV response ${response.statusCode} '
        '${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }
  }
}
