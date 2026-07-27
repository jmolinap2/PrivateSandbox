import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/entities/vault_file.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Removes a file from the vault entirely: its ciphertext blob, its
/// thumbnail blob (if any), and its DB row.
class DeleteFileUseCase {
  final VaultRepository _vaultRepository;
  final ActivityRepository _activityRepository;
  static const _uuid = Uuid();

  DeleteFileUseCase(this._vaultRepository, this._activityRepository);

  Future<void> call(VaultFile file) async {
    final blobsDir = await VaultPaths.vaultBlobsDir();

    final blob = File(p.join(blobsDir.path, file.encryptedFileName));
    if (await blob.exists()) {
      await blob.delete();
    }

    final thumbnailFileName = file.thumbnailFileName;
    if (thumbnailFileName != null) {
      final thumbBlob = File(p.join(blobsDir.path, thumbnailFileName));
      if (await thumbBlob.exists()) {
        await thumbBlob.delete();
      }
    }

    await _vaultRepository.deleteFile(file.id);
    await _activityRepository.logEvent(ActivityEvent(
      id: _uuid.v4(),
      type: ActivityEventType.deleted,
      fileName: file.originalName,
      timestamp: DateTime.now(),
      success: true,
    ));
  }
}
