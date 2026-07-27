import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';
import 'package:mobile_flutter/infrastructure/synchronization/webdav_sync_transport.dart';

void main() {
  late HttpServer server;
  late StreamSubscription<HttpRequest> subscription;
  late _MiniWebDav dav;
  late WebDavSyncTransport transport;

  setUp(() async {
    dav = _MiniWebDav();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    subscription = server.listen(dav.handle);
    transport = WebDavSyncTransport(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}/dav/'),
      allowInsecureHttpForTesting: true,
    );
  });

  tearDown(() async {
    transport.close(force: true);
    await subscription.cancel();
    await server.close(force: true);
  });

  test('supports conditional PUT, HEAD and ranged GET', () async {
    await transport.ensureDirectory('vaults/id');
    final bytes = utf8.encode('encrypted-payload');
    final first = await transport.put(
      'vaults/id/blob.bin',
      Stream<List<int>>.value(bytes),
      length: bytes.length,
      ifNoneMatch: true,
    );

    expect(first.etag, isNotNull);
    expect((await transport.head('vaults/id/blob.bin'))!.length, bytes.length);
    final range = await transport.get(
      'vaults/id/blob.bin',
      start: 2,
      endExclusive: 7,
    );
    final rangeBytes = await range.bytes.expand((chunk) => chunk).toList();
    expect(rangeBytes, bytes.sublist(2, 7));
    expect(range.metadata.length, bytes.length);

    await expectLater(
      transport.put(
        'vaults/id/blob.bin',
        Stream<List<int>>.value(bytes),
        length: bytes.length,
        ifMatch: '"wrong"',
      ),
      throwsA(isA<SyncPreconditionFailed>()),
    );
    final replacement = utf8.encode('replacement');
    final updated = await transport.put(
      'vaults/id/blob.bin',
      Stream<List<int>>.value(replacement),
      length: replacement.length,
      ifMatch: first.etag,
    );
    expect(updated.etag, isNot(first.etag));
  });

  test('requires TLS unless explicitly enabled for a local test', () {
    expect(
      () => WebDavSyncTransport(
        baseUri: Uri.parse('http://example.invalid/dav/'),
      ),
      throwsArgumentError,
    );
  });
}

class _Stored {
  final Uint8List bytes;
  final String etag;

  const _Stored(this.bytes, this.etag);
}

class _MiniWebDav {
  final Map<String, _Stored> objects = <String, _Stored>{};
  final Set<String> directories = <String>{};

  Future<void> handle(HttpRequest request) async {
    final path = request.uri.path;
    switch (request.method) {
      case 'MKCOL':
        directories.add(path);
        request.response.statusCode = HttpStatus.created;
        await request.response.close();
        return;
      case 'PUT':
        final current = objects[path];
        final ifNone = request.headers.value(HttpHeaders.ifNoneMatchHeader);
        final ifMatch = request.headers.value(HttpHeaders.ifMatchHeader);
        if ((ifNone == '*' && current != null) ||
            (ifMatch != null && current?.etag != ifMatch)) {
          await request.drain<void>();
          request.response.statusCode = HttpStatus.preconditionFailed;
          await request.response.close();
          return;
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in request) {
          builder.add(chunk);
        }
        final bytes = builder.takeBytes();
        final etag = '"${crypto.sha256.convert(bytes)}"';
        objects[path] = _Stored(bytes, etag);
        request.response
          ..statusCode = current == null
              ? HttpStatus.created
              : HttpStatus.noContent
          ..headers.set(HttpHeaders.etagHeader, etag);
        await request.response.close();
        return;
      case 'HEAD':
        final current = objects[path];
        if (current == null) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..contentLength = current.bytes.length
            ..headers.set(HttpHeaders.etagHeader, current.etag);
        }
        await request.response.close();
        return;
      case 'GET':
        final current = objects[path];
        if (current == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final range = request.headers.value(HttpHeaders.rangeHeader);
        var start = 0;
        var endExclusive = current.bytes.length;
        if (range != null) {
          final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(range)!;
          start = int.parse(match.group(1)!);
          if (match.group(2)!.isNotEmpty) {
            endExclusive = int.parse(match.group(2)!) + 1;
          }
          request.response
            ..statusCode = HttpStatus.partialContent
            ..headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-${endExclusive - 1}/${current.bytes.length}',
            );
        } else {
          request.response.statusCode = HttpStatus.ok;
        }
        final selected = current.bytes.sublist(start, endExclusive);
        request.response
          ..contentLength = selected.length
          ..headers.set(HttpHeaders.etagHeader, current.etag)
          ..add(selected);
        await request.response.close();
        return;
      default:
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
    }
  }
}
