import 'package:desktop_companion_flutter/src/storage/companion_secure_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/sync_configuration.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_identity_store.dart';

void main() {
  test('secure configuration round-trips all WebDAV fields', () async {
    final secrets = _FakeSecretStore();
    final store = CompanionSecureStore(secrets);
    final configuration = SyncConfiguration(
      endpoint: Uri.parse('https://vault.example.test/webdav/private/'),
      authenticationKind: SyncAuthenticationKind.basic,
      username: 'alice',
      secret: r'a-strong\password',
      deviceDisplayName: 'Desktop Alice',
      backgroundSyncEnabled: false,
    );

    await store.saveConfiguration(configuration);
    final loaded = await store.loadConfiguration();

    expect(loaded, isNotNull);
    expect(loaded!.endpoint, configuration.endpoint);
    expect(loaded.authenticationKind, SyncAuthenticationKind.basic);
    expect(loaded.username, 'alice');
    expect(loaded.secret, configuration.secret);
    expect(loaded.deviceDisplayName, 'Desktop Alice');
    expect(loaded.backgroundSyncEnabled, isFalse);
    expect(
      secrets.values.keys,
      contains(CompanionSecureStore.configurationKey),
    );
  });

  test('refuses non-HTTPS WebDAV configuration', () async {
    final store = CompanionSecureStore(_FakeSecretStore());
    final configuration = SyncConfiguration(
      endpoint: Uri.parse('http://vault.example.test/webdav/'),
      deviceDisplayName: 'Desktop',
    );

    expect(
      () => store.saveConfiguration(configuration),
      throwsA(isA<FormatException>()),
    );
  });
}

class _FakeSecretStore implements SyncSecretStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
