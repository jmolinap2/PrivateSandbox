import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class PrivateSandboxDavServer {
  static const _uuid = Uuid();
  static const int defaultMaximumObjectBytes = 8 * 1024 * 1024 * 1024 * 1024;

  final Directory root;
  final String username;
  final String password;
  final bool publicSharesEnabled;
  final int maximumObjectBytes;
  final Map<String, Future<void>> _pathLocks = <String, Future<void>>{};

  PrivateSandboxDavServer({
    required this.root,
    required this.username,
    required this.password,
    this.publicSharesEnabled = false,
    this.maximumObjectBytes = defaultMaximumObjectBytes,
  }) {
    if (username.isEmpty || password.length < 12) {
      throw ArgumentError(
        'WebDAV requires a username and a password of at least 12 characters.',
      );
    }
    if (maximumObjectBytes <= 0) {
      throw ArgumentError.value(maximumObjectBytes, 'maximumObjectBytes');
    }
  }

  Future<HttpServer> bind({
    required InternetAddress address,
    required int port,
    SecurityContext? securityContext,
    bool allowPlainHttpForLoopbackTesting = false,
  }) async {
    await root.create(recursive: true);
    await _recoverInterruptedOperations(root);
    final HttpServer server;
    if (securityContext != null) {
      server = await HttpServer.bindSecure(address, port, securityContext);
    } else {
      if (!allowPlainHttpForLoopbackTesting || !address.isLoopback) {
        throw StateError('TLS is mandatory outside explicit loopback tests.');
      }
      server = await HttpServer.bind(address, port);
    }
    server.autoCompress = false;
    unawaited(
      server.forEach((request) async {
        try {
          await handle(request);
        } catch (error, stackTrace) {
          stderr.writeln('Request failed: $error\n$stackTrace');
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          } on StateError {
            // The response was already committed or closed.
          } on HttpException {
            // The peer disconnected while the error was being reported.
          }
        }
      }),
    );
    return server;
  }

  Future<void> handle(HttpRequest request) async {
    _securityHeaders(request.response);
    if (request.uri.path == '/healthz' && request.method == 'GET') {
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"status":"ok"}');
      await request.response.close();
      return;
    }
    if (request.uri.path.startsWith('/public/shares/')) {
      await _handlePublicShare(request);
      return;
    }
    if (!request.uri.path.startsWith('/dav/')) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    if (!_authorized(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.set(
        HttpHeaders.wwwAuthenticateHeader,
        'Basic realm="PrivateSandbox DAV", charset="UTF-8"',
      );
      await request.response.close();
      return;
    }
    final relative = _safeRelativePath(
      request.uri.path.substring('/dav/'.length),
    );
    if (relative == null) {
      await _status(request, HttpStatus.badRequest);
      return;
    }
    final entity = _resolve(relative);
    switch (request.method) {
      case 'OPTIONS':
        request.response.statusCode = HttpStatus.noContent;
        request.response.headers
          ..set('DAV', '1')
          ..set('Allow', 'OPTIONS, HEAD, GET, PUT, DELETE, MKCOL, PROPFIND');
        await request.response.close();
      case 'HEAD':
        await _head(request, entity, relative);
      case 'GET':
        await _get(request, entity, relative);
      case 'PUT':
        await _withPathLock(
          entity.path,
          () => _put(request, File(entity.path)),
        );
      case 'DELETE':
        await _withPathLock(entity.path, () => _delete(request, entity));
      case 'MKCOL':
        await _mkcol(request, Directory(entity.path));
      case 'PROPFIND':
        await _propfind(request, entity, relative);
      default:
        await _status(request, HttpStatus.methodNotAllowed);
    }
  }

  Future<void> _handlePublicShare(HttpRequest request) async {
    if (!publicSharesEnabled ||
        (request.method != 'GET' && request.method != 'HEAD')) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    final name = request.uri.path.substring('/public/shares/'.length);
    if (name.contains('/') || _safeRelativePath('shares/$name') == null) {
      await _status(request, HttpStatus.badRequest);
      return;
    }
    final separator = name.indexOf('-');
    final expiration = separator <= 0
        ? null
        : int.tryParse(name.substring(0, separator));
    if (expiration == null) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    final file = File(_resolve('shares/$name').path);
    if (expiration <= DateTime.now().toUtc().millisecondsSinceEpoch) {
      if (await file.exists()) {
        try {
          await file.delete();
        } on FileSystemException {
          // It remains unusable because clients authenticate package expiry.
        }
      }
      await _status(request, HttpStatus.gone);
      return;
    }
    request.response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..set(
        HttpHeaders.contentDisposition,
        'attachment; filename="PrivateSandbox.pshare"',
      );
    if (request.method == 'HEAD') {
      await _head(request, file, 'shares/$name');
    } else {
      await _get(request, file, 'shares/$name');
    }
  }

  Future<void> _head(
    HttpRequest request,
    FileSystemEntity entity,
    String relative,
  ) async {
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    if (type == FileSystemEntityType.link) {
      await _status(request, HttpStatus.forbidden);
      return;
    }
    request.response.statusCode = HttpStatus.ok;
    if (type == FileSystemEntityType.file) {
      await _fileHeaders(request.response, File(entity.path), relative);
    }
    await request.response.close();
  }

  Future<void> _get(
    HttpRequest request,
    FileSystemEntity entity,
    String relative,
  ) async {
    if (await FileSystemEntity.type(entity.path, followLinks: false) !=
        FileSystemEntityType.file) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    final file = File(entity.path);
    final length = await file.length();
    final range = _parseRange(
      request.headers.value(HttpHeaders.rangeHeader),
      length,
    );
    if (range == null &&
        request.headers.value(HttpHeaders.rangeHeader) != null) {
      request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes */$length',
      );
      await request.response.close();
      return;
    }
    await _fileHeaders(request.response, file, relative);
    final start = range?.$1 ?? 0;
    final endExclusive = range?.$2 ?? length;
    if (range != null) {
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers
        ..set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-${endExclusive - 1}/$length',
        )
        ..contentLength = endExclusive - start;
    } else {
      request.response.statusCode = HttpStatus.ok;
      request.response.contentLength = length;
    }
    await request.response.addStream(file.openRead(start, endExclusive));
    await request.response.close();
  }

  Future<void> _put(HttpRequest request, File target) async {
    final length = request.contentLength;
    if (length < 0 || length > maximumObjectBytes) {
      await _status(request, HttpStatus.lengthRequired);
      return;
    }
    if (!await target.parent.exists()) {
      await _status(request, HttpStatus.conflict);
      return;
    }
    final existingType = await FileSystemEntity.type(
      target.path,
      followLinks: false,
    );
    if (existingType == FileSystemEntityType.directory ||
        existingType == FileSystemEntityType.link) {
      await _status(request, HttpStatus.conflict);
      return;
    }
    final exists = existingType == FileSystemEntityType.file;
    final currentEtag = exists ? await _etag(target) : null;
    if (!_preconditionsPass(request, currentEtag)) {
      await _status(request, HttpStatus.preconditionFailed);
      return;
    }
    final pending = File('${target.path}.${_uuid.v4()}.ps-dav-upload');
    RandomAccessFile? writer;
    try {
      writer = await pending.open(mode: FileMode.writeOnly);
      var received = 0;
      await for (final chunk in request) {
        received += chunk.length;
        if (received > length || received > maximumObjectBytes) {
          throw const HttpException('Request body exceeds declared length');
        }
        await writer.writeFrom(chunk);
      }
      if (received != length) {
        throw const HttpException('Incomplete request body');
      }
      await writer.flush();
      await writer.close();
      writer = null;
      await _publishAtomically(pending, target);
      request.response.statusCode = exists
          ? HttpStatus.noContent
          : HttpStatus.created;
      request.response.headers.set(HttpHeaders.etagHeader, await _etag(target));
      await request.response.close();
    } on HttpException {
      await _status(request, HttpStatus.badRequest);
    } finally {
      await writer?.close();
      if (await pending.exists()) {
        await pending.delete();
      }
    }
  }

  Future<void> _delete(HttpRequest request, FileSystemEntity entity) async {
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    if (type == FileSystemEntityType.link) {
      await _status(request, HttpStatus.forbidden);
      return;
    }
    final currentEtag = type == FileSystemEntityType.file
        ? await _etag(File(entity.path))
        : null;
    if (!_preconditionsPass(request, currentEtag)) {
      await _status(request, HttpStatus.preconditionFailed);
      return;
    }
    final deleted = '${entity.path}.ps-dav-delete';
    await _deleteEntityIfPresent(deleted);
    await entity.rename(deleted);
    await _deleteEntityIfPresent(deleted);
    await _status(request, HttpStatus.noContent);
  }

  Future<void> _mkcol(HttpRequest request, Directory directory) async {
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.notFound) {
      await _status(request, HttpStatus.methodNotAllowed);
      return;
    }
    if (!await directory.parent.exists()) {
      await _status(request, HttpStatus.conflict);
      return;
    }
    await directory.create();
    await _status(request, HttpStatus.created);
  }

  Future<void> _propfind(
    HttpRequest request,
    FileSystemEntity entity,
    String relative,
  ) async {
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await _status(request, HttpStatus.notFound);
      return;
    }
    if (type == FileSystemEntityType.link) {
      await _status(request, HttpStatus.forbidden);
      return;
    }
    final depth = request.headers.value('Depth') ?? '0';
    if (depth != '0' && depth != '1') {
      await _status(request, HttpStatus.forbidden);
      return;
    }
    final entities = <FileSystemEntity>[entity];
    if (depth == '1' && type == FileSystemEntityType.directory) {
      await for (final child in Directory(
        entity.path,
      ).list(followLinks: false)) {
        if (p.basename(child.path).contains('.ps-dav-')) continue;
        entities.add(child);
      }
    }
    final xml = StringBuffer(
      '<?xml version="1.0" encoding="utf-8"?><d:multistatus xmlns:d="DAV:">',
    );
    for (final item in entities) {
      final itemType = await FileSystemEntity.type(
        item.path,
        followLinks: false,
      );
      if (itemType == FileSystemEntityType.link) continue;
      final itemRelative = p
          .relative(item.path, from: root.path)
          .replaceAll(p.separator, '/');
      final href =
          '/dav/${itemRelative.split('/').map(Uri.encodeComponent).join('/')}'
          '${itemType == FileSystemEntityType.directory ? '/' : ''}';
      final stat = await item.stat();
      final length = itemType == FileSystemEntityType.file ? stat.size : 0;
      final etag = itemType == FileSystemEntityType.file
          ? await _etag(File(item.path))
          : null;
      xml
        ..write('<d:response><d:href>${_xml(href)}</d:href>')
        ..write('<d:propstat><d:prop>')
        ..write('<d:getcontentlength>$length</d:getcontentlength>')
        ..write(
          '<d:getlastmodified>${HttpDate.format(stat.modified.toUtc())}</d:getlastmodified>',
        );
      if (etag != null) xml.write('<d:getetag>${_xml(etag)}</d:getetag>');
      if (itemType == FileSystemEntityType.directory) {
        xml.write('<d:resourcetype><d:collection/></d:resourcetype>');
      } else {
        xml.write('<d:resourcetype/>');
        xml.write(
          '<d:getcontenttype>application/octet-stream</d:getcontenttype>',
        );
      }
      xml.write(
        '</d:prop><d:status>HTTP/1.1 200 OK</d:status>'
        '</d:propstat></d:response>',
      );
    }
    xml.write('</d:multistatus>');
    final bytes = utf8.encode(xml.toString());
    request.response
      ..statusCode = 207
      ..headers.contentType = ContentType(
        'application',
        'xml',
        charset: 'utf-8',
      )
      ..contentLength = bytes.length
      ..add(bytes);
    await request.response.close();
  }

  bool _authorized(HttpRequest request) {
    final value = request.headers.value(HttpHeaders.authorizationHeader);
    if (value == null || !value.startsWith('Basic ')) return false;
    try {
      final decoded = utf8.decode(base64Decode(value.substring(6)));
      return _constantTimeEquals(decoded, '$username:$password');
    } on FormatException {
      return false;
    }
  }

  bool _preconditionsPass(HttpRequest request, String? currentEtag) {
    final ifNone = request.headers.value(HttpHeaders.ifNoneMatchHeader);
    if (ifNone == '*' && currentEtag != null) return false;
    final ifMatch = request.headers.value(HttpHeaders.ifMatchHeader);
    if (ifMatch != null && ifMatch != currentEtag) return false;
    return true;
  }

  Future<void> _fileHeaders(
    HttpResponse response,
    File file,
    String relative,
  ) async {
    final stat = await file.stat();
    response.headers
      ..set(HttpHeaders.etagHeader, await _etag(file))
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..set(
        HttpHeaders.lastModifiedHeader,
        HttpDate.format(stat.modified.toUtc()),
      )
      ..set(HttpHeaders.contentTypeHeader, _contentType(relative));
    response.contentLength = stat.size;
  }

  String _contentType(String relative) {
    if (relative.endsWith('.psm')) {
      return 'application/vnd.private-sandbox.sync-manifest+json;version=1';
    }
    if (relative.endsWith('.pshare')) {
      return 'application/vnd.private-sandbox.share+octet-stream;version=1';
    }
    return 'application/octet-stream';
  }

  Future<String> _etag(File file) async {
    final digest = await crypto.sha256.bind(file.openRead()).first;
    return '"$digest"';
  }

  Future<void> _publishAtomically(File pending, File target) async {
    if (!await target.exists()) {
      await pending.rename(target.path);
      return;
    }
    final old = File('${target.path}.ps-dav-old');
    if (await old.exists()) await old.delete();
    await target.rename(old.path);
    try {
      await pending.rename(target.path);
    } catch (_) {
      if (!await target.exists() && await old.exists()) {
        await old.rename(target.path);
      }
      rethrow;
    }
    if (await old.exists()) await old.delete();
  }

  Future<void> _recoverInterruptedOperations(Directory directory) async {
    final pendingDeletes = <FileSystemEntity>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity.path.endsWith('.ps-dav-delete')) {
        pendingDeletes.add(entity);
      } else if (entity is File && entity.path.endsWith('.ps-dav-old')) {
        final target = File(
          entity.path.substring(0, entity.path.length - '.ps-dav-old'.length),
        );
        if (await target.exists()) {
          await entity.delete();
        } else {
          await entity.rename(target.path);
        }
      } else if (entity is File && entity.path.contains('.ps-dav-upload')) {
        await entity.delete();
      }
    }
    pendingDeletes.sort(
      (left, right) => right.path.length.compareTo(left.path.length),
    );
    for (final entity in pendingDeletes) {
      await _deleteEntityIfPresent(entity.path);
    }
  }

  Future<T> _withPathLock<T>(
    String path,
    Future<T> Function() operation,
  ) async {
    final previous = _pathLocks[path] ?? Future<void>.value();
    final completer = Completer<void>();
    final queued = previous.then((_) => completer.future);
    _pathLocks[path] = queued;
    await previous;
    try {
      return await operation();
    } finally {
      completer.complete();
      if (identical(_pathLocks[path], queued)) {
        _pathLocks.remove(path);
      }
    }
  }

  FileSystemEntity _resolve(String relative) {
    final resolved = p.normalize(p.join(root.absolute.path, relative));
    if (!p.equals(root.absolute.path, resolved) &&
        !p.isWithin(root.absolute.path, resolved)) {
      throw const FileSystemException('Path traversal rejected');
    }
    return File(resolved);
  }

  String? _safeRelativePath(String raw) {
    if (raw.isEmpty) return '';
    final segments = <String>[];
    try {
      for (final encoded in raw.split('/')) {
        segments.add(Uri.decodeComponent(encoded));
      }
    } on FormatException {
      return null;
    }
    if (segments.any(
      (segment) =>
          segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.contains('/') ||
          segment.contains('\\') ||
          segment.contains(':') ||
          segment.codeUnits.any((unit) => unit < 32),
    )) {
      return null;
    }
    return segments.join(p.separator);
  }

  Future<void> _deleteEntityIfPresent(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    switch (type) {
      case FileSystemEntityType.file:
        await File(path).delete();
      case FileSystemEntityType.directory:
        await Directory(path).delete(recursive: true);
      case FileSystemEntityType.link:
        await Link(path).delete();
      case FileSystemEntityType.notFound:
        return;
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        throw FileSystemException('Unsupported filesystem entity', path);
    }
  }

  (int, int)? _parseRange(String? header, int length) {
    if (header == null) return null;
    final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(header);
    if (match == null) return null;
    final start = int.tryParse(match.group(1)!);
    final endInclusive = match.group(2)!.isEmpty
        ? length - 1
        : int.tryParse(match.group(2)!);
    if (start == null ||
        endInclusive == null ||
        start < 0 ||
        start >= length ||
        endInclusive < start ||
        endInclusive >= length) {
      return null;
    }
    return (start, endInclusive + 1);
  }

  void _securityHeaders(HttpResponse response) {
    response.headers
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer')
      ..set('Cache-Control', 'no-store')
      ..set('Content-Security-Policy', "default-src 'none'");
  }

  Future<void> _status(HttpRequest request, int status) async {
    request.response.statusCode = status;
    await request.response.close();
  }

  bool _constantTimeEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    var difference = leftBytes.length ^ rightBytes.length;
    final maximum = leftBytes.length > rightBytes.length
        ? leftBytes.length
        : rightBytes.length;
    for (var index = 0; index < maximum; index++) {
      final a = index < leftBytes.length ? leftBytes[index] : 0;
      final b = index < rightBytes.length ? rightBytes[index] : 0;
      difference |= a ^ b;
    }
    return difference == 0;
  }

  String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
