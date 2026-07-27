import 'dart:io';

import '../../domain/synchronization/sync_configuration.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../infrastructure/sharing/encrypted_share_package_codec.dart';
import '../../infrastructure/storage/atomic_file_writer.dart';
import '../../infrastructure/synchronization/sync_configuration_store.dart';
import '../../infrastructure/synchronization/webdav_sync_transport.dart';

class TemporaryShareLinkService {
  static const _maximumDownloadBytes = 1024 * 1024 * 1024 * 1024;

  final SyncConfigurationStore configurationStore;

  const TemporaryShareLinkService({required this.configurationStore});

  Future<Uri> upload(EncryptedSharePackageResult package) async {
    final configuration = await configurationStore.load();
    if (configuration == null) {
      throw const SyncAuthorizationException(
        'Configura un servidor antes de crear un enlace.',
      );
    }
    final publicBase = configuration.publicShareBaseUri ??
        (configuration.authenticationKind == SyncAuthenticationKind.none
            ? configuration.endpoint
            : null);
    if (publicBase == null) {
      throw const SyncAuthorizationException(
        'El servidor autenticado necesita una base pública para enlaces.',
      );
    }
    final credentials = _credentials(configuration);
    final transport = WebDavSyncTransport(
      baseUri: configuration.endpoint,
      credentials: credentials,
    );
    final expiresMillis = package.expiresAt.millisecondsSinceEpoch;
    final name = '$expiresMillis-${package.packageId}.pshare';
    try {
      await transport.ensureDirectory('shares');
      final length = await package.packageFile.length();
      await transport.put(
        'shares/$name',
        package.packageFile.openRead(),
        length: length,
        ifNoneMatch: true,
      );
      await _cleanupExpired(transport, DateTime.now().toUtc());
    } finally {
      transport.close(force: true);
    }
    final base = _directoryUri(publicBase);
    final publicObject = base.resolve('shares/$name');
    final fragment = Uri(
      queryParameters: <String, String>{
        'psk': package.capabilityKey,
        'expires': package.expiresAt.toUtc().toIso8601String(),
      },
    ).query;
    return publicObject.replace(fragment: fragment);
  }

  Future<OpenedSharePackage> downloadAndOpen({
    required Uri link,
    required Directory privateTemporaryDirectory,
    required Directory plaintextDestination,
    DateTime? now,
  }) async {
    if (link.scheme != 'https' || link.host.isEmpty) {
      throw const FormatException('El enlace compartido debe usar HTTPS.');
    }
    final fragment = Uri.splitQueryString(link.fragment);
    final capability = fragment['psk'];
    if (capability == null) {
      throw const FormatException('El enlace no contiene la clave privada.');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 45);
    File? downloaded;
    try {
      final request = await client.getUrl(link.replace(fragment: ''));
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'PrivateSandbox-Share/1',
      );
      final response = await request.close().timeout(
            const Duration(seconds: 45),
          );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw SyncTransportException(
          'El servidor respondió ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      final length = response.contentLength;
      if (length <= 0 || length > _maximumDownloadBytes) {
        await response.drain<void>();
        throw const FormatException(
          'El tamaño remoto es desconocido o excede el límite.',
        );
      }
      if (!await privateTemporaryDirectory.exists()) {
        await privateTemporaryDirectory.create(recursive: true);
      }
      downloaded = await AtomicFileWriter.writeStream(
        destinationDirectory: privateTemporaryDirectory,
        preferredName: 'remote-${DateTime.now().microsecondsSinceEpoch}.pshare',
        bytes: response,
        expectedLength: length,
      );
      return await EncryptedSharePackageCodec.open(
        packageFile: downloaded,
        capabilityKey: capability,
        destinationDirectory: plaintextDestination,
        privateTemporaryDirectory: privateTemporaryDirectory,
        now: now,
      );
    } finally {
      client.close(force: true);
      if (downloaded != null && await downloaded.exists()) {
        await downloaded.delete();
      }
    }
  }

  Future<void> _cleanupExpired(
    WebDavSyncTransport transport,
    DateTime now,
  ) async {
    try {
      final objects = await transport.list('shares');
      for (final object in objects) {
        final name = object.path.split('/').last;
        final separator = name.indexOf('-');
        if (separator <= 0) continue;
        final expires = int.tryParse(name.substring(0, separator));
        if (expires != null && expires <= now.millisecondsSinceEpoch) {
          await transport.delete(object.path, ifMatch: object.etag);
        }
      }
    } on SyncException {
      // Cleanup is best-effort and cannot invalidate a successfully uploaded
      // encrypted capability object.
    }
  }

  WebDavCredentials _credentials(SyncConfiguration configuration) {
    return switch (configuration.authenticationKind) {
      SyncAuthenticationKind.none => const WebDavCredentials.none(),
      SyncAuthenticationKind.basic => WebDavCredentials.basic(
          username: configuration.username,
          password: configuration.secret,
        ),
      SyncAuthenticationKind.bearer =>
        WebDavCredentials.bearer(configuration.secret),
    };
  }

  Uri _directoryUri(Uri value) {
    final path = value.path.endsWith('/') ? value.path : '${value.path}/';
    return value.replace(path: path, query: null, fragment: null);
  }
}
