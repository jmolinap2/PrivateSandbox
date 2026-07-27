import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/sync_configuration.dart';
import 'package:mobile_flutter/domain/synchronization/sync_selection.dart';

void main() {
  test('round-trips selective and bandwidth policy', () {
    const policy = SelectiveSyncPolicy(
      mode: VaultSyncMode.synchronized,
      downloadMode: RemoteDownloadMode.eager,
      excludedLogicalIds: <String>{'local-only'},
      maximumBlobBytes: 1024,
      bandwidthLimitBytesPerSecond: 512,
    );
    final configuration = SyncConfiguration(
      endpoint: Uri.parse('https://dav.example.test/private/'),
      authenticationKind: SyncAuthenticationKind.basic,
      username: 'alice',
      secret: 'correct horse battery staple',
      deviceDisplayName: 'Portátil',
      policy: policy,
    );

    final restored = SyncConfiguration.fromJson(configuration.toJson());

    expect(restored.endpoint, configuration.endpoint);
    expect(restored.authenticationKind, SyncAuthenticationKind.basic);
    expect(restored.policy.downloadMode, RemoteDownloadMode.eager);
    expect(restored.policy.excludedLogicalIds, contains('local-only'));
    expect(restored.policy.maximumBlobBytes, 1024);
    expect(restored.policy.bandwidthLimitBytesPerSecond, 512);
  });

  test('refuses clear-text remotes and incomplete credentials', () {
    expect(
      () => SyncConfiguration(
        endpoint: Uri.parse('http://dav.example.test/'),
        deviceDisplayName: 'Equipo',
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => SyncConfiguration(
        endpoint: Uri.parse('https://dav.example.test/'),
        authenticationKind: SyncAuthenticationKind.basic,
        username: 'alice',
        deviceDisplayName: 'Equipo',
      ).validate(),
      throwsFormatException,
    );
  });
}
