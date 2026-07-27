import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'encrypted_share_use_cases.dart';
import 'temporary_share_link_service.dart';

final temporaryShareLinkServiceProvider =
    Provider<TemporaryShareLinkService>((ref) {
  return TemporaryShareLinkService(
    configurationStore: ref.watch(syncConfigurationStoreProvider),
  );
});

final exportEncryptedSharePackageUseCaseProvider =
    Provider<ExportEncryptedSharePackageUseCase>((ref) {
  return ExportEncryptedSharePackageUseCase(
    playback: ref.watch(playbackUseCaseProvider),
    linkService: ref.watch(temporaryShareLinkServiceProvider),
  );
});

final importEncryptedSharePackageUseCaseProvider =
    Provider<ImportEncryptedSharePackageUseCase>((ref) {
  return ImportEncryptedSharePackageUseCase(
    importer: ref.watch(importUseCaseProvider),
    linkService: ref.watch(temporaryShareLinkServiceProvider),
  );
});
