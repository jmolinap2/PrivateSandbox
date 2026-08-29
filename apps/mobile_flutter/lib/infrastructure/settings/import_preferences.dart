import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted "don't ask again" choice for the import flow's "¿Eliminar
/// originales?" dialog. Reuses the app's existing secure storage instance
/// rather than adding a new preferences package — this value isn't a
/// secret, but a second storage mechanism would be one more thing that
/// could break for no benefit, and the app already depends on
/// `flutter_secure_storage`.
class ImportPreferences {
  final FlutterSecureStorage _secureStorage;

  ImportPreferences(this._secureStorage);

  static const _deleteOriginalDefaultKey = 'import_delete_original_default';

  /// The remembered answer to "¿Eliminar originales?", or null if the user
  /// hasn't chosen to remember it — meaning the dialog should keep asking.
  Future<bool?> getDeleteOriginalDefault() async {
    final stored = await _secureStorage.read(key: _deleteOriginalDefaultKey);
    if (stored == null) return null;
    return stored == 'true';
  }

  Future<void> setDeleteOriginalDefault(bool value) {
    return _secureStorage.write(key: _deleteOriginalDefaultKey, value: value.toString());
  }

  Future<void> resetAll() async {
    await _secureStorage.delete(key: _deleteOriginalDefaultKey);
  }
}
