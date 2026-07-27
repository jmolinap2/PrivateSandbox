import 'dart:async';
import 'dart:io';

import 'package:private_sandbox_dav/private_sandbox_dav.dart';

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final username = Platform.environment['PS_DAV_USERNAME'];
  final password = Platform.environment['PS_DAV_PASSWORD'];
  if (username == null || password == null) {
    stderr.writeln(
      'Define PS_DAV_USERNAME and PS_DAV_PASSWORD in the process environment.',
    );
    exitCode = 64;
    return;
  }
  final service = PrivateSandboxDavServer(
    root: Directory(options.rootPath),
    username: username,
    password: password,
    publicSharesEnabled: options.publicShares,
  );
  SecurityContext? context;
  if (options.certificatePath != null && options.privateKeyPath != null) {
    context = SecurityContext()
      ..useCertificateChain(options.certificatePath!)
      ..usePrivateKey(options.privateKeyPath!);
  }
  final address = InternetAddress(options.host);
  final server = await service.bind(
    address: address,
    port: options.port,
    securityContext: context,
    allowPlainHttpForLoopbackTesting: options.allowHttp,
  );
  stdout.writeln(
    'PrivateSandbox DAV listening on '
    '${context == null ? 'http' : 'https'}://${server.address.address}:${server.port}/dav/',
  );
  final stopping = Completer<void>();
  Future<void> stop(ProcessSignal signal) async {
    if (stopping.isCompleted) return;
    await server.close(force: false);
    stopping.complete();
  }

  ProcessSignal.sigint.watch().listen(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);
  await stopping.future;
}

class _Options {
  final String rootPath;
  final String host;
  final int port;
  final String? certificatePath;
  final String? privateKeyPath;
  final bool allowHttp;
  final bool publicShares;

  const _Options({
    required this.rootPath,
    required this.host,
    required this.port,
    required this.certificatePath,
    required this.privateKeyPath,
    required this.allowHttp,
    required this.publicShares,
  });

  factory _Options.parse(List<String> arguments) {
    String value(String name, String fallback) {
      final prefix = '--$name=';
      final match = arguments.where((arg) => arg.startsWith(prefix));
      return match.isEmpty ? fallback : match.last.substring(prefix.length);
    }

    String? optional(String name) {
      final result = value(name, '');
      return result.isEmpty ? null : result;
    }

    final certificate = optional('cert');
    final privateKey = optional('key');
    if ((certificate == null) != (privateKey == null)) {
      throw const FormatException('--cert and --key must be provided together.');
    }
    return _Options(
      rootPath: value('root', './private-sandbox-data'),
      host: value('host', '0.0.0.0'),
      port: int.parse(value('port', '8443')),
      certificatePath: certificate,
      privateKeyPath: privateKey,
      allowHttp: arguments.contains('--allow-http'),
      publicShares: arguments.contains('--public-shares'),
    );
  }
}
