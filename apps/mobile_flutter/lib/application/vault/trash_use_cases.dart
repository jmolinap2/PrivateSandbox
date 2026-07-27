import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/vault_repository.dart';

/// Everyday "eliminar" from the library: hides the file behind the private
/// trash instead of touching its ciphertext, so it can still be recovered —
/// distinct from [PermanentlyDeleteFileUseCase] (`DeleteFileUseCase`), which
/// actually wipes the blob and DB row.
class MoveToTrashUseCase {
  final VaultRepository _vaultRepository;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  MoveToTrashUseCase(this._vaultRepository, this._activityRepository);

  Future<void> call(VaultFile file) async {
    await _vaultRepository.moveToTrash(file.id);
    try {
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.deleted,
          fileName: file.originalName,
          timestamp: DateTime.now(),
          success: true,
          detail: 'Movido a la papelera',
        ),
      );
    } catch (_) {
      // The trash transition already committed.
    }
  }
}

/// Brings a file back from the trash into the active library. Named
/// "recover", not "restore", to avoid confusion with [RestoreUseCase]
/// (`restaurar a su ubicación original`), a completely different operation
/// that removes the file from the vault entirely.
class RecoverFromTrashUseCase {
  final VaultRepository _vaultRepository;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  RecoverFromTrashUseCase(this._vaultRepository, this._activityRepository);

  Future<void> call(VaultFile file) async {
    await _vaultRepository.restoreFromTrash(file.id);
    try {
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.imported,
          fileName: file.originalName,
          timestamp: DateTime.now(),
          success: true,
          detail: 'Recuperado de la papelera',
        ),
      );
    } catch (_) {
      // The recovery transition already committed.
    }
  }
}
