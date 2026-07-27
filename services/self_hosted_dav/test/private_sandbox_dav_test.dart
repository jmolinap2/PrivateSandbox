import 'dart:convert';
import 'dart:io';

import 'package:private_sandbox_dav/private_sandbox_dav.dart';
import 'package:test/test.dart';

void main() {
  group('PrivateSandboxDavServer', () {
    late Directory root;
    late PrivateSandboxDavServer service;
    late HttpServer server;
    late HttpClient client;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('private-sandbox-dav-test-');
      service = PrivateSandboxDavServer(
        root: root,
        username: 'vault',
        password: 'a-long-random-test-password',
        publicSharesEnabled: true,
      );
      server = await service.bind(
        address: InternetAddress.loopbackIPv4,
        port: 0,
        allowPlainHttpForLoopbackTesting: true,
      );
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('requires authentication and rejects traversal', () async {
      final unauthorized = await _request(client, server, 'GET', '/dav/a');
      expect(unauthorized.statusCode, HttpStatus.unauthorized);
      expect(
        unauthorized.headers.value(HttpHeaders.wwwAuthenticateHeader),
        contains('Basic'),
      );

      final traversal = await _request(
        client,
        server,
        'GET',
        '/dav/%2e%2e%2fsecret',
        authenticated: true,
      );
      expect(traversal.statusCode, HttpStatus.badRequest);
      expect(
        await File(
          '${root.parent.path}${Platform.pathSeparator}secret',
        ).exists(),
        isFalse,
      );
    });

    test('supports atomic PUT, ETag CAS, byte ranges, and PROPFIND', () async {
      final collection = await _request(
        client,
        server,
        'MKCOL',
        '/dav/objects',
        authenticated: true,
      );
      expect(collection.statusCode, HttpStatus.created);

      final created = await _request(
        client,
        server,
        'PUT',
        '/dav/objects/object.bin',
        authenticated: true,
        body: utf8.encode('abcdef'),
      );
      expect(created.statusCode, HttpStatus.created);
      final etag = created.headers.value(HttpHeaders.etagHeader);
      expect(etag, isNotNull);

      final range = await _request(
        client,
        server,
        'GET',
        '/dav/objects/object.bin',
        authenticated: true,
        headers: <String, String>{HttpHeaders.rangeHeader: 'bytes=1-3'},
      );
      expect(range.statusCode, HttpStatus.partialContent);
      expect(utf8.decode(range.body), 'bcd');
      expect(
        range.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 1-3/6',
      );

      final rejected = await _request(
        client,
        server,
        'PUT',
        '/dav/objects/object.bin',
        authenticated: true,
        body: utf8.encode('changed'),
        headers: <String, String>{
          HttpHeaders.ifMatchHeader: '"not-the-current-etag"',
        },
      );
      expect(rejected.statusCode, HttpStatus.preconditionFailed);

      final unchanged = await _request(
        client,
        server,
        'GET',
        '/dav/objects/object.bin',
        authenticated: true,
      );
      expect(utf8.decode(unchanged.body), 'abcdef');

      final propfind = await _request(
        client,
        server,
        'PROPFIND',
        '/dav/objects',
        authenticated: true,
        headers: <String, String>{'Depth': '1'},
      );
      expect(propfind.statusCode, 207);
      expect(utf8.decode(propfind.body), contains('object.bin'));
      expect(
        utf8.decode(propfind.body),
        contains(etag!.replaceAll('"', '&quot;')),
      );
    });

    test('serves only unexpired encrypted public shares', () async {
      final shares = Directory('${root.path}${Platform.pathSeparator}shares');
      await shares.create();
      final future = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      final active = File(
        '${shares.path}${Platform.pathSeparator}$future-active.pshare',
      );
      await active.writeAsBytes(<int>[1, 2, 3, 4], flush: true);

      final downloaded = await _request(
        client,
        server,
        'GET',
        '/public/shares/$future-active.pshare',
      );
      expect(downloaded.statusCode, HttpStatus.ok);
      expect(downloaded.body, <int>[1, 2, 3, 4]);
      expect(
        downloaded.headers.value(HttpHeaders.accessControlAllowOriginHeader),
        '*',
      );

      final past = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      final expired = File(
        '${shares.path}${Platform.pathSeparator}$past-expired.pshare',
      );
      await expired.writeAsBytes(<int>[5, 6], flush: true);
      final gone = await _request(
        client,
        server,
        'GET',
        '/public/shares/$past-expired.pshare',
      );
      expect(gone.statusCode, HttpStatus.gone);
      expect(await expired.exists(), isFalse);
    });

    test(
      'recovers interrupted atomic swaps before accepting requests',
      () async {
        client.close(force: true);
        await server.close(force: true);

        final old = File(
          '${root.path}${Platform.pathSeparator}manifest.psm.ps-dav-old',
        );
        await old.writeAsString('previous', flush: true);
        final abandoned = File(
          '${root.path}${Platform.pathSeparator}blob.ps-dav-upload',
        );
        await abandoned.writeAsString('partial', flush: true);
        final deleted = Directory(
          '${root.path}${Platform.pathSeparator}folder.ps-dav-delete',
        );
        await deleted.create();
        await File(
          '${deleted.path}${Platform.pathSeparator}cipher.bin',
        ).writeAsString('ciphertext');

        server = await service.bind(
          address: InternetAddress.loopbackIPv4,
          port: 0,
          allowPlainHttpForLoopbackTesting: true,
        );
        client = HttpClient();

        expect(
          await File(
            '${root.path}${Platform.pathSeparator}manifest.psm',
          ).readAsString(),
          'previous',
        );
        expect(await old.exists(), isFalse);
        expect(await abandoned.exists(), isFalse);
        expect(await deleted.exists(), isFalse);
      },
    );

    test(
      'refuses plaintext binding unless it is an explicit loopback test',
      () async {
        client.close(force: true);
        await server.close(force: true);

        expect(
          () => service.bind(address: InternetAddress.loopbackIPv4, port: 0),
          throwsA(isA<StateError>()),
        );

        server = await service.bind(
          address: InternetAddress.loopbackIPv4,
          port: 0,
          allowPlainHttpForLoopbackTesting: true,
        );
        client = HttpClient();
      },
    );
  });
}

Future<_Response> _request(
  HttpClient client,
  HttpServer server,
  String method,
  String path, {
  bool authenticated = false,
  List<int>? body,
  Map<String, String> headers = const <String, String>{},
}) async {
  final request = await client.openUrl(
    method,
    Uri.parse('http://127.0.0.1:${server.port}$path'),
  );
  if (authenticated) {
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Basic ${base64Encode(utf8.encode('vault:a-long-random-test-password'))}',
    );
  }
  headers.forEach(request.headers.set);
  if (body != null) {
    request.contentLength = body.length;
    request.add(body);
  }
  final response = await request.close();
  final responseBody = await response.fold<List<int>>(
    <int>[],
    (bytes, chunk) => bytes..addAll(chunk),
  );
  return _Response(response.statusCode, response.headers, responseBody);
}

class _Response {
  final int statusCode;
  final HttpHeaders headers;
  final List<int> body;

  const _Response(this.statusCode, this.headers, this.body);
}
