import 'package:mobile_flutter/domain/synchronization/sync_configuration.dart';
import 'package:mobile_flutter/infrastructure/synchronization/webdav_sync_transport.dart';

abstract final class WebDavFactory {
  static WebDavSyncTransport create(SyncConfiguration configuration) {
    configuration.validate();
    final credentials = switch (configuration.authenticationKind) {
      SyncAuthenticationKind.none => const WebDavCredentials.none(),
      SyncAuthenticationKind.basic => WebDavCredentials.basic(
        username: configuration.username,
        password: configuration.secret,
      ),
      SyncAuthenticationKind.bearer => WebDavCredentials.bearer(
        configuration.secret,
      ),
    };
    return WebDavSyncTransport(
      baseUri: configuration.endpoint,
      credentials: credentials,
    );
  }
}
