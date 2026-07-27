import 'package:flutter/services.dart';

/// Bridges to native window/activity operations that have no `dart:io`
/// equivalent: overriding this window's brightness for the video player's
/// brightness gesture, and handing a decrypted temp file to the Android
/// share sheet ("compartición controlada").
///
/// Brightness is a *window* override — it never writes the global system
/// setting, so it needs no special permission and is released automatically
/// when the player closes.
class SystemChannel {
  static const _channel = MethodChannel('privatesandbox.app/system');

  /// The brightness the user currently sees, 0..1 (window override if set,
  /// otherwise the system setting) — so a gesture starts without a jump.
  Future<double> getScreenBrightness() async {
    try {
      final value = await _channel.invokeMethod<double>('getScreenBrightness');
      return (value ?? 0.5).clamp(0.0, 1.0);
    } on PlatformException {
      return 0.5;
    }
  }

  Future<void> setScreenBrightness(double level) async {
    try {
      await _channel.invokeMethod<void>('setScreenBrightness', {'level': level.clamp(0.0, 1.0)});
    } on PlatformException {
      // Best-effort — a failed brightness set just leaves the previous value.
    }
  }

  /// Releases this window's brightness override, handing control back to the
  /// system setting. Called when the player closes so the vault doesn't leave
  /// the whole device dimmed.
  Future<void> clearScreenBrightness() async {
    try {
      await _channel.invokeMethod<void>('clearScreenBrightness');
    } on PlatformException {
      // Best-effort.
    }
  }

  /// Opens the system share sheet for the already-decrypted file at
  /// [sourcePath], granting the chosen app one-shot read access via the app's
  /// private FileProvider. Returns false if no share could be started.
  Future<bool> shareFile({
    required String sourcePath,
    required String mimeType,
    required String displayName,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('shareFile', {
        'sourcePath': sourcePath,
        'mimeType': mimeType,
        'displayName': displayName,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }
}
