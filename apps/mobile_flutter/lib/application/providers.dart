import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/activity_event.dart';
import '../domain/entities/vault_collection.dart';
import '../domain/entities/vault_file.dart';
import '../domain/entities/vault_folder.dart';
import '../domain/entities/vault_smart_album.dart';
import '../domain/entities/vault_tag.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/vault_collection_repository.dart';
import '../domain/repositories/vault_folder_repository.dart';
import '../domain/repositories/vault_repository.dart';
import '../domain/repositories/vault_smart_album_repository.dart';
import '../domain/repositories/vault_tag_repository.dart';
import '../infrastructure/auth/auth_repository_impl.dart';
import '../infrastructure/database/activity_repository_impl.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/database/vault_collection_repository_impl.dart';
import '../infrastructure/database/vault_folder_repository_impl.dart';
import '../infrastructure/database/vault_repository_impl.dart';
import '../infrastructure/database/vault_smart_album_repository_impl.dart';
import '../infrastructure/database/vault_tag_repository_impl.dart';
import '../infrastructure/encryption/key_manager.dart';
import '../infrastructure/platform/original_location_channel.dart';
import '../infrastructure/platform/system_channel.dart';
import '../infrastructure/settings/import_preferences.dart';
import '../infrastructure/synchronization/sync_configuration_store.dart';
import '../media_engine/abstractions/audio_engine.dart';
import '../media_engine/abstractions/video_engine.dart';
import '../media_engine/media3/media3_audio_engine.dart';
import '../media_engine/media3/media3_video_engine.dart';
import 'backup/export_vault_backup_use_case.dart';
import 'backup/import_vault_backup_use_case.dart';
import 'export/export_use_case.dart';
import 'export/share_use_case.dart';
import 'import/import_use_case.dart';
import 'playback/playback_use_case.dart';
import 'recovery/recovery_use_case.dart';
import 'synchronization/configured_synchronization_service.dart';
import 'synchronization/device_enrollment_service.dart';
import 'thumbnails/thumbnail_use_case.dart';
import 'vault/delete_file_use_case.dart';
import 'vault/restore_use_case.dart';
import 'vault/trash_use_cases.dart';
import 'vault/verify_integrity_use_case.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager(secureStorage: ref.watch(secureStorageProvider));
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepositoryImpl(ref.watch(appDatabaseProvider));
});

final vaultFolderRepositoryProvider = Provider<VaultFolderRepository>((ref) {
  return VaultFolderRepositoryImpl(ref.watch(appDatabaseProvider));
});

final vaultTagRepositoryProvider = Provider<VaultTagRepository>((ref) {
  return VaultTagRepositoryImpl(ref.watch(appDatabaseProvider));
});

final vaultCollectionRepositoryProvider = Provider<VaultCollectionRepository>((
  ref,
) {
  return VaultCollectionRepositoryImpl(ref.watch(appDatabaseProvider));
});

final vaultSmartAlbumRepositoryProvider = Provider<VaultSmartAlbumRepository>((
  ref,
) {
  return VaultSmartAlbumRepositoryImpl(ref.watch(appDatabaseProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(ref.watch(appDatabaseProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(secureStorage: ref.watch(secureStorageProvider));
});

final originalLocationChannelProvider = Provider<OriginalLocationChannel>((
  ref,
) {
  return OriginalLocationChannel();
});

final importPreferencesProvider = Provider<ImportPreferences>((ref) {
  return ImportPreferences(ref.watch(secureStorageProvider));
});

final syncConfigurationStoreProvider = Provider<SyncConfigurationStore>((ref) {
  return SyncConfigurationStore(ref.watch(secureStorageProvider));
});

final configuredSynchronizationServiceProvider =
    Provider<ConfiguredSynchronizationService>((ref) {
      return ConfiguredSynchronizationService(
        database: ref.watch(appDatabaseProvider),
        vaultRepository: ref.watch(vaultRepositoryProvider),
        keyManager: ref.watch(keyManagerProvider),
        secureStorage: ref.watch(secureStorageProvider),
        configurationStore: ref.watch(syncConfigurationStoreProvider),
      );
    });

final deviceEnrollmentServiceProvider = Provider<DeviceEnrollmentService>((
  ref,
) {
  return DeviceEnrollmentService(
    synchronization: ref.watch(configuredSynchronizationServiceProvider),
  );
});

final thumbnailUseCaseProvider = Provider<ThumbnailUseCase>((ref) {
  return ThumbnailUseCase(
    ref.watch(keyManagerProvider),
    ref.watch(originalLocationChannelProvider),
  );
});

final importUseCaseProvider = Provider<ImportUseCase>((ref) {
  return ImportUseCase(
    ref.watch(vaultRepositoryProvider),
    ref.watch(keyManagerProvider),
    ref.watch(originalLocationChannelProvider),
    ref.watch(thumbnailUseCaseProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final exportUseCaseProvider = Provider<ExportUseCase>((ref) {
  return ExportUseCase(
    ref.watch(keyManagerProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final systemChannelProvider = Provider<SystemChannel>((ref) {
  return SystemChannel();
});

final shareUseCaseProvider = Provider<ShareUseCase>((ref) {
  return ShareUseCase(
    ref.watch(keyManagerProvider),
    ref.watch(systemChannelProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final restoreUseCaseProvider = Provider<RestoreUseCase>((ref) {
  return RestoreUseCase(
    ref.watch(keyManagerProvider),
    ref.watch(originalLocationChannelProvider),
    ref.watch(activityRepositoryProvider),
    ref.watch(vaultRepositoryProvider),
  );
});

final deleteFileUseCaseProvider = Provider<DeleteFileUseCase>((ref) {
  return DeleteFileUseCase(
    ref.watch(vaultRepositoryProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final moveToTrashUseCaseProvider = Provider<MoveToTrashUseCase>((ref) {
  return MoveToTrashUseCase(
    ref.watch(vaultRepositoryProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final recoverFromTrashUseCaseProvider = Provider<RecoverFromTrashUseCase>((
  ref,
) {
  return RecoverFromTrashUseCase(
    ref.watch(vaultRepositoryProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final verifyIntegrityUseCaseProvider = Provider<VerifyIntegrityUseCase>((ref) {
  return VerifyIntegrityUseCase(ref.watch(keyManagerProvider));
});

final exportVaultBackupUseCaseProvider = Provider<ExportVaultBackupUseCase>((
  ref,
) {
  return ExportVaultBackupUseCase(
    ref.watch(appDatabaseProvider),
    ref.watch(keyManagerProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final importVaultBackupUseCaseProvider = Provider<ImportVaultBackupUseCase>((
  ref,
) {
  return ImportVaultBackupUseCase(
    ref.watch(appDatabaseProvider),
    ref.watch(keyManagerProvider),
  );
});

final playbackUseCaseProvider = Provider<PlaybackUseCase>((ref) {
  return PlaybackUseCase(ref.watch(keyManagerProvider));
});

final recoveryUseCaseProvider = Provider<RecoveryUseCase>((ref) {
  return RecoveryUseCase(ref.watch(vaultRepositoryProvider));
});

final vaultFilesStreamProvider = StreamProvider<List<VaultFile>>((ref) {
  return ref.watch(vaultRepositoryProvider).watchFiles();
});

final vaultTrashedFilesStreamProvider = StreamProvider<List<VaultFile>>((ref) {
  return ref.watch(vaultRepositoryProvider).watchTrashedFiles();
});

final vaultFoldersStreamProvider =
    StreamProvider.family<List<VaultFolder>, String?>((ref, parentId) {
      return ref.watch(vaultFolderRepositoryProvider).watchFolders(parentId);
    });

final vaultFilesInFolderStreamProvider =
    StreamProvider.family<List<VaultFile>, String?>((ref, folderId) {
      return ref.watch(vaultRepositoryProvider).watchFilesInFolder(folderId);
    });

final vaultTagsStreamProvider = StreamProvider<List<VaultTag>>((ref) {
  return ref.watch(vaultTagRepositoryProvider).watchTags();
});

final vaultTagsForFileStreamProvider =
    StreamProvider.family<List<VaultTag>, String>((ref, fileId) {
      return ref.watch(vaultTagRepositoryProvider).watchTagsForFile(fileId);
    });

final vaultFilesWithTagStreamProvider =
    StreamProvider.family<List<VaultFile>, String>((ref, tagId) {
      return ref.watch(vaultTagRepositoryProvider).watchFilesWithTag(tagId);
    });

final vaultCollectionsStreamProvider = StreamProvider<List<VaultCollection>>((
  ref,
) {
  return ref.watch(vaultCollectionRepositoryProvider).watchCollections();
});

final vaultCollectionsForFileStreamProvider =
    StreamProvider.family<List<VaultCollection>, String>((ref, fileId) {
      return ref
          .watch(vaultCollectionRepositoryProvider)
          .watchCollectionsForFile(fileId);
    });

final vaultFilesInCollectionStreamProvider =
    StreamProvider.family<List<VaultFile>, String>((ref, collectionId) {
      return ref
          .watch(vaultCollectionRepositoryProvider)
          .watchFilesInCollection(collectionId);
    });

final vaultSmartAlbumsStreamProvider = StreamProvider<List<VaultSmartAlbum>>((
  ref,
) {
  return ref.watch(vaultSmartAlbumRepositoryProvider).watchSmartAlbums();
});

final vaultFilesForSmartAlbumStreamProvider =
    StreamProvider.family<List<VaultFile>, VaultSmartAlbum>((ref, album) {
      return ref.watch(vaultSmartAlbumRepositoryProvider).watchFilesFor(album);
    });

final activityEventsStreamProvider = StreamProvider<List<ActivityEvent>>((ref) {
  return ref.watch(activityRepositoryProvider).watchEvents();
});

/// Non-trashed files sharing the same content hash, grouped — each group
/// has 2+ entries. Derived client-side from [vaultFilesStreamProvider]
/// rather than a dedicated query, since every active file is already
/// loaded there for the library.
final duplicateFileGroupsProvider = Provider<List<List<VaultFile>>>((ref) {
  final files =
      ref.watch(vaultFilesStreamProvider).value ?? const <VaultFile>[];
  final byHash = <String, List<VaultFile>>{};
  for (final file in files) {
    if (file.sha256Hash.isEmpty) continue;
    byHash.putIfAbsent(file.sha256Hash, () => []).add(file);
  }
  return [
    for (final group in byHash.values)
      if (group.length > 1) group,
  ];
});

/// Engine factories, not singletons — each viewer session needs its own
/// instance. The concrete implementation (Media3 today) is the only place
/// that knows which package backs it; swapping to libVLC later only means
/// changing these two lines.
final videoEngineFactoryProvider = Provider<VideoEngine Function()>(
  (ref) => Media3VideoEngine.new,
);
final audioEngineFactoryProvider = Provider<AudioEngine Function()>(
  (ref) => Media3AudioEngine.new,
);

typedef ThumbnailKey = ({
  String fileSaltBase64,
  String thumbnailFileName,
  String thumbnailNoncePrefixBase64,
});

/// Cached (per key) decrypted thumbnail bytes, so scrolling a list doesn't
/// re-decrypt the same thumbnail on every rebuild.
final thumbnailBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, ThumbnailKey>((ref, key) {
      return ref
          .watch(thumbnailUseCaseProvider)
          .loadDecrypted(
            fileSaltBase64: key.fileSaltBase64,
            thumbnailFileName: key.thumbnailFileName,
            thumbnailNoncePrefixBase64: key.thumbnailNoncePrefixBase64,
          );
    });
