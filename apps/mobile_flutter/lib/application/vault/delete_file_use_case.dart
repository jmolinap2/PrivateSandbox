import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/vault_repository.dart';
import 'vault_file_lifecycle.dart';

/// Removes a file from the vault entirely: its ciphertext blob, its
/// thumbnail blob (if any), and its DB row.
class DeleteFileUseCase {
  final ActivityRepository _activityRepository;
  final VaultFileLifecycle _lifecycle;
  static const _uuid = Uuid();

  DeleteFileUseCase(
    VaultRepository vaultRepository,
    this._activityRepository, {
    VaultFileLifecycle? lifecycle,
  }) : _lifecycle = lifecycle ?? VaultFileLifecycle(vaultRepository);

  Future<void> call(VaultFile file) async {
    final cleanup = await _lifecycle.deleteRecordThenArtifacts(file);
    try {
      await _activityRepository.logEvent(
        ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.deleted,
          fileName: file.originalName,
          timestamp: DateTime.now(),
          success: cleanup.isComplete,
          detail: cleanup.isComplete
              ? null
              : 'El registro se eliminó; ${cleanup.failedPaths.length} artefacto(s) esperan limpieza automática',
        ),
      );
    } catch (_) {
      // Audit logging must not turn a committed deletion into a reported
      // application failure.
    }
  }
}
