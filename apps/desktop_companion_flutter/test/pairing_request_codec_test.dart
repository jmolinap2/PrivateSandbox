import 'dart:convert';

import 'package:desktop_companion_flutter/src/models/pairing_request_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/domain/synchronization/device_identity.dart';
import 'package:mobile_flutter/domain/synchronization/sync_protocol.dart';

void main() {
  DeviceIdentity identity() => DeviceIdentity.fromPublicKeys(
    displayName: 'Desktop seguro',
    signingPublicKey: List<int>.generate(32, (index) => index),
    exchangePublicKey: List<int>.generate(32, (index) => 255 - index),
    createdAt: DateTime.utc(2026, 7, 26, 12),
  );

  test('DeviceIdentity JSON round-trips without private material', () {
    final original = identity();
    final serialized = PairingRequestCodec.encode(original);
    final decoded = PairingRequestCodec.decode(serialized);

    expect(decoded.deviceId, original.deviceId);
    expect(decoded.displayName, original.displayName);
    expect(decoded.signingPublicKeyBase64, original.signingPublicKeyBase64);
    expect(decoded.exchangePublicKeyBase64, original.exchangePublicKeyBase64);
    expect(serialized, isNot(contains('PrivateKey')));
  });

  test('rejects an altered device fingerprint', () {
    final json = identity().toJson();
    json['deviceId'] = '0' * 64;

    expect(
      () => PairingRequestCodec.decode(jsonEncode(json)),
      throwsA(isA<SyncIntegrityException>()),
    );
  });
}
