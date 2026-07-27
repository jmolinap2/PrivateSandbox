import 'sync_selection.dart';

enum SyncAuthenticationKind { none, basic, bearer }

/// User-owned remote configuration. It is persisted only in Keystore-backed
/// secure storage because it may contain a WebDAV password or bearer token.
class SyncConfiguration {
  final Uri endpoint;
  final SyncAuthenticationKind authenticationKind;
  final String username;
  final String secret;
  final String deviceDisplayName;
  final Uri? publicShareBaseUri;
  final bool backgroundSyncEnabled;
  final SelectiveSyncPolicy policy;

  const SyncConfiguration({
    required this.endpoint,
    this.authenticationKind = SyncAuthenticationKind.none,
    this.username = '',
    this.secret = '',
    required this.deviceDisplayName,
    this.publicShareBaseUri,
    this.backgroundSyncEnabled = true,
    this.policy = const SelectiveSyncPolicy(),
  });

  void validate() {
    if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
      throw const FormatException(
        'La sincronización requiere una dirección WebDAV HTTPS válida.',
      );
    }
    if (deviceDisplayName.trim().isEmpty) {
      throw const FormatException('El dispositivo necesita un nombre.');
    }
    final shareBase = publicShareBaseUri;
    if (shareBase != null &&
        (shareBase.scheme != 'https' || shareBase.host.isEmpty)) {
      throw const FormatException(
        'La base pública para enlaces debe usar HTTPS.',
      );
    }
    if (authenticationKind == SyncAuthenticationKind.basic &&
        (username.isEmpty || secret.isEmpty)) {
      throw const FormatException(
        'El usuario y la contraseña WebDAV son obligatorios.',
      );
    }
    if (authenticationKind == SyncAuthenticationKind.bearer && secret.isEmpty) {
      throw const FormatException('El token de acceso es obligatorio.');
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'endpoint': endpoint.toString(),
    'authenticationKind': authenticationKind.name,
    'username': username,
    'secret': secret,
        'deviceDisplayName': deviceDisplayName,
        if (publicShareBaseUri != null)
          'publicShareBaseUri': publicShareBaseUri.toString(),
    'backgroundSyncEnabled': backgroundSyncEnabled,
    'policy': policy.toJson(),
  };

  factory SyncConfiguration.fromJson(Map<String, Object?> json) {
    final configuration = SyncConfiguration(
      endpoint: Uri.parse(json['endpoint']! as String),
      authenticationKind: SyncAuthenticationKind.values.byName(
        json['authenticationKind']! as String,
      ),
      username: json['username'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
      deviceDisplayName: json['deviceDisplayName']! as String,
      publicShareBaseUri: json['publicShareBaseUri'] == null
          ? null
          : Uri.parse(json['publicShareBaseUri']! as String),
      backgroundSyncEnabled: json['backgroundSyncEnabled'] as bool? ?? true,
      policy: SelectiveSyncPolicy.fromJson(
        Map<String, Object?>.from(json['policy']! as Map),
      ),
    );
    configuration.validate();
    return configuration;
  }
}
