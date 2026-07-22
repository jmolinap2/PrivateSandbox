import 'dart:math';
import 'dart:typed_data';

/// Cryptographically secure random byte generation, shared by the PIN
/// storage (salts) and the import flow (per-file salt/nonce prefix).
Uint8List randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
}
