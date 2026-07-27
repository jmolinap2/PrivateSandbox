import 'dart:io';

import '../../domain/entities/vault_file.dart';
import '../../infrastructure/sharing/encrypted_share_package_codec.dart';
import '../../infrastructure/storage/vault_paths.dart';
import '../import/import_progress.dart';
import '../import/import_use_case.dart';
import '../import/picked_file.dart';
import '../playback/playback_use_case.dart';
import 'temporary_share_link_service.dart';

class ExportEncryptedSharePackageUseCase {
  final PlaybackUseCase playback;
  final TemporaryShareLinkService linkService;

  const ExportEncryptedSharePackageUseCase({
    required this.playback,
    required this.linkService,
  });

  Future<EncryptedSharePackageResult> exportPackage({
    required VaultFile file,
    required Directory destinationDirectory,
    required Duration lifetime,
  }) async {
    final plaintext = await playback.decryptToTemp(file);
    try {
      return await EncryptedSharePackageCodec.create(
        plaintextFile: plaintext,
        originalName: file.originalName,
        mimeType: file.mimeType,
        destinationDirectory: destinationDirectory,
        privateTemporaryDirectory: await VaultPaths.tempShareDir(),
        lifetime: lifetime,
        modifiedAt: file.fileModifiedAt,
      );
    } finally {
      await playback.cleanupTemp(plaintext);
    }
  }

  Future<Uri> createProtectedLink({
    required VaultFile file,
    required Duration lifetime,
  }) async {
    final package = await exportPackage(
      file: file,
      destinationDirectory: await VaultPaths.tempShareDir(),
      lifetime: lifetime,
    );
    try {
      return await linkService.upload(package);
    } finally {
      if (await package.packageFile.exists()) {
        await package.packageFile.delete();
      }
    }
  }
}

class ImportEncryptedSharePackageUseCase {
  final ImportUseCase importer;
  final TemporaryShareLinkService linkService;

  const ImportEncryptedSharePackageUseCase({
    required this.importer,
    required this.linkService,
  });

  Future<void> importPackage({
    required File package,
    required String capabilityKey,
  }) async {
    final opened = await EncryptedSharePackageCodec.open(
      packageFile: package,
      capabilityKey: capabilityKey,
      destinationDirectory: await VaultPaths.tempPlaybackDir(),
      privateTemporaryDirectory: await VaultPaths.tempShareDir(),
    );
    await _importOpened(opened);
  }

  Future<void> importLink(Uri link) async {
    final opened = await linkService.downloadAndOpen(
      link: link,
      privateTemporaryDirectory: await VaultPaths.tempShareDir(),
      plaintextDestination: await VaultPaths.tempPlaybackDir(),
    );
    await _importOpened(opened);
  }

  Future<void> _importOpened(OpenedSharePackage opened) async {
    try {
      final size = await opened.plaintextFile.length();
      await for (final progress in importer.call(
        pickedFile: PickedFile(
          path: opened.plaintextFile.path,
          name: opened.originalName,
          size: size,
        ),
        deleteOriginal: true,
      )) {
        if (progress.stage == ImportStage.failed) {
          throw StateError('No se pudo importar el paquete a la bóveda.');
        }
      }
    } finally {
      if (await opened.plaintextFile.exists()) {
        await opened.plaintextFile.delete();
      }
    }
  }
}
