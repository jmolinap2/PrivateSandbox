import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/repositories/vault_repository.dart';
import '../../infrastructure/storage/vault_paths.dart';

/// Cleans up files left in [ImportStatus.importing] by a previous run that
/// never reached the "verified and recorded" completion gate — deletes any
/// partial ciphertext blob and the draft DB row, per the plan's
/// "recuperación ante cierres inesperados durante una importación".
class RecoveryUseCase {
  final VaultRepository _vaultRepository;

  RecoveryUseCase(this._vaultRepository);

  Future<int> recoverInterruptedImports() async {
    final interrupted = await _vaultRepository.getInterruptedImports();
    if (interrupted.isEmpty) return 0;

    final blobsDir = await VaultPaths.vaultBlobsDir();
    for (final file in interrupted) {
      final blob = File(p.join(blobsDir.path, file.encryptedFileName));
      if (await blob.exists()) {
        await blob.delete();
      }
      await _vaultRepository.deleteFile(file.id);
    }
    return interrupted.length;
  }
}
