import 'package:flutter/services.dart';

/// Bridges to native Android code that deletes the file the user originally
/// picked (outside the vault) once its encrypted copy has been verified.
///
/// A plain `dart:io File.delete()` on the path `file_picker` returns only
/// removes that plugin's cached copy, never the real file in the gallery/
/// downloads/etc. — actually hiding the original requires going through
/// `DocumentsContract`/`MediaStore` on the Android side, which may involve a
/// one-time system confirmation dialog under scoped storage.
class MediaStoreDeleteChannel {
  static const _channel = MethodChannel('privatesandbox.app/media_store');

  Future<bool> deleteContentUri(String uri) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteContentUri', {'uri': uri});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
