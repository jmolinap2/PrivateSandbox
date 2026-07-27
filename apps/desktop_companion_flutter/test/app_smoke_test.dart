import 'dart:io';

import 'package:desktop_companion_flutter/main.dart';
import 'package:desktop_companion_flutter/src/application/companion_controller.dart';
import 'package:desktop_companion_flutter/src/storage/companion_secure_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/infrastructure/synchronization/device_identity_store.dart';

void main() {
  testWidgets('desktop shell renders its three primary workflows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final secrets = MemorySyncSecretStore();
    final controller = CompanionController(
      identityManager: DeviceIdentityManager(secretStore: secrets),
      secureStore: CompanionSecureStore(secrets),
      applicationSupportDirectory: () async => Directory.systemTemp,
    );

    await tester.pumpWidget(PrivateSandboxDesktopApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Companion de escritorio'), findsOneWidget);
    expect(find.text('Conexión WebDAV'), findsOneWidget);
    expect(find.text('Emparejamiento'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
