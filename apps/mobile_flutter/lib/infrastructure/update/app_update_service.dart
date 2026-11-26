import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A newer build published as a GitHub Release by `tool/release.sh`.
class AvailableUpdate {
  final int buildNumber;
  final String downloadUrl;
  final int sizeBytes;

  const AvailableUpdate({
    required this.buildNumber,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}

/// Self-update from GitHub Releases (the repo is public, so no token is
/// needed; unauthenticated API calls allow 60/hour per IP, plenty here).
///
/// Releases are tagged `build-N`, where N is the git commit count that
/// the release workflow also uses as the APK's versionCode, so "newer" is simply
/// N > installed versionCode.
class AppUpdateService {
  static const repository = 'jmolinap2/PrivateSandbox';
  static const _channel = MethodChannel('privatesandbox.app/system');

  Future<int> installedBuildNumber() async {
    final value = await _channel.invokeMethod<int>('getAppBuildNumber');
    return value ?? 0;
  }

  /// Returns the latest release if it is newer than the installed build,
  /// null if up to date. Throws [AppUpdateException] on
  /// network or API errors.
  Future<AvailableUpdate?> checkForUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repository/releases/latest'),
      );
      _headers(request);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 404) return null; // No release published yet.
      if (response.statusCode == 403) {
        throw const AppUpdateException('GitHub limitó las consultas; reintenta más tarde.');
      }
      if (response.statusCode != 200) {
        throw AppUpdateException('GitHub respondió ${response.statusCode}.');
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String? ?? '';
      final latest = int.tryParse(tag.replaceFirst('build-', ''));
      if (latest == null) return null;
      if (latest <= await installedBuildNumber()) return null;
      final assets =
          (json['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final apks = assets.where((a) => (a['name'] as String? ?? '').endsWith('.apk'));
      if (apks.isEmpty) return null;
      return AvailableUpdate(
        buildNumber: latest,
        downloadUrl: apks.first['browser_download_url'] as String,
        sizeBytes: (apks.first['size'] as num?)?.toInt() ?? 0,
      );
    } on SocketException {
      throw const AppUpdateException('Sin conexión.');
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads the APK and returns its local path (under cache/app_update/).
  Future<String> download(AvailableUpdate update) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/app_update');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final target = File('${dir.path}/update-${update.buildNumber}.apk');

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(update.downloadUrl));
      _headers(request);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw AppUpdateException('La descarga falló (${response.statusCode}).');
      }
      await response.pipe(target.openWrite());
      if (update.sizeBytes > 0 && target.lengthSync() != update.sizeBytes) {
        target.deleteSync();
        throw const AppUpdateException('Descarga incompleta, reintenta.');
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
      await _channel.invokeMethod<bool>('installApk', {'sourcePath': apkPath}) ?? false;

  void _headers(HttpClientRequest request) {
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    request.headers.set(HttpHeaders.userAgentHeader, 'PrivateSandbox-updater');
  }
}

class AppUpdateException implements Exception {
  final String message;
  const AppUpdateException(this.message);

  @override
  String toString() => message;
}
