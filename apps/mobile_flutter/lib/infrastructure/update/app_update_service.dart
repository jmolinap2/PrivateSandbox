import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Lo que publica el CI en `version.json` junto a cada APK.
class AvailableUpdate {
  final int buildNumber;
  final String name;
  final String message;
  final Uri apkUrl;
  final int sizeBytes;
  final String certificateSha256;

  const AvailableUpdate({
    required this.buildNumber,
    required this.name,
    required this.message,
    required this.apkUrl,
    required this.sizeBytes,
    required this.certificateSha256,
  });
}

/// Self-update from the fixed GitHub release `latest`, where
/// `.github/workflows/release.yml` publishes `PrivateSandbox.apk` and a
/// `version.json` ({build, name, message, apk, bytes}) on every push to master.
///
/// `build` is the git commit count, which the workflow (and tool/deploy.sh)
/// also use as the APK's versionCode, so "newer" is simply build > installed.
/// The repo is public, so no credentials (and no GitHub API rate limit) are
/// involved: both files are plain downloads.
class AppUpdateService {
  static final Uri baseUrl = Uri.parse(
    'https://github.com/jmolinap2/PrivateSandbox/releases/download/latest/',
  );
  static const _channel = MethodChannel('privatesandbox.app/system');

  Future<int> installedBuildNumber() async {
    final value = await _channel.invokeMethod<int>('getAppBuildNumber');
    return value ?? 0;
  }

  Future<String?> installedCertificateSha256() =>
      _channel.invokeMethod<String>('getSigningCertificateSha256');

  /// Returns the published update if it is newer than the installed build,
  /// null if up to date. Throws [AppUpdateException] on network/server errors.
  Future<AvailableUpdate?> checkForUpdate() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      // The query string keeps an intermediate cache from serving an old manifest.
      final uri = baseUrl.resolve(
        'version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 404) {
        throw const AppUpdateException(
          'No se encontró la información de actualización en GitHub.',
        );
      }
      if (response.statusCode != 200) {
        throw AppUpdateException(
          'El servidor respondió ${response.statusCode}.',
        );
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final build = json['build'] as int;
      if (build <= await installedBuildNumber()) return null;
      final publishedCertificate = (json['certificateSha256'] as String? ?? '')
          .toLowerCase();
      if (publishedCertificate.isNotEmpty) {
        final installedCertificate = (await installedCertificateSha256() ?? '')
            .toLowerCase();
        if (installedCertificate.isEmpty ||
            !_sameCertificate(installedCertificate, publishedCertificate)) {
          throw const AppUpdateException(
            'Esta actualización fue firmada con otra clave y Android no puede instalarla. '
            'El canal de GitHub debe usar la misma clave que la app instalada.',
          );
        }
      }
      return AvailableUpdate(
        buildNumber: build,
        name: json['name'] as String? ?? '',
        message: json['message'] as String? ?? '',
        apkUrl: baseUrl.resolve(json['apk'] as String),
        sizeBytes: json['bytes'] as int,
        certificateSha256: publishedCertificate,
      );
    } on SocketException {
      throw const AppUpdateException('Sin conexión.');
    } on FormatException {
      throw const AppUpdateException('Respuesta de actualización inválida.');
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads the APK (progress 0..1 via [onProgress]) and returns its local
  /// path under cache/app_update/. Fails if the size differs from the
  /// published one, so a truncated download never reaches the installer.
  Future<String> download(
    AvailableUpdate update, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/app_update');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final target = File('${dir.path}/update-${update.buildNumber}.apk');

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(update.apkUrl);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw AppUpdateException('La descarga falló (${response.statusCode}).');
      }
      final sink = target.openWrite();
      var received = 0;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (update.sizeBytes > 0) onProgress?.call(received / update.sizeBytes);
      }
      await sink.close();
      if (received != update.sizeBytes) {
        target.deleteSync();
        throw AppUpdateException(
          'Descarga incompleta: $received de ${update.sizeBytes} bytes.',
        );
      }
      return target.path;
    } on SocketException {
      throw const AppUpdateException('Sin conexión.');
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> canInstallPackages() async =>
      await _channel.invokeMethod<bool>('canInstallPackages') ?? false;

  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod<void>('openInstallPermissionSettings');

  Future<bool> install(String apkPath) async =>
      await _channel.invokeMethod<bool>('installApk', {
        'sourcePath': apkPath,
      }) ??
      false;

  static bool _sameCertificate(String left, String right) =>
      left.replaceAll(':', '') == right.replaceAll(':', '');
}

class AppUpdateException implements Exception {
  final String message;
  const AppUpdateException(this.message);

  @override
  String toString() => message;
}
