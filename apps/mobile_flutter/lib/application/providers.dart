import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/vault_file.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/vault_repository.dart';
import '../infrastructure/auth/auth_repository_impl.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/database/vault_repository_impl.dart';
import '../infrastructure/encryption/key_manager.dart';
import '../infrastructure/platform/media_store_delete_channel.dart';
import 'export/export_use_case.dart';
import 'import/import_use_case.dart';
import 'playback/playback_use_case.dart';
import 'recovery/recovery_use_case.dart';

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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(secureStorage: ref.watch(secureStorageProvider));
});

final mediaStoreDeleteChannelProvider = Provider<MediaStoreDeleteChannel>((ref) {
  return MediaStoreDeleteChannel();
});

final importUseCaseProvider = Provider<ImportUseCase>((ref) {
  return ImportUseCase(
    ref.watch(vaultRepositoryProvider),
    ref.watch(keyManagerProvider),
    ref.watch(mediaStoreDeleteChannelProvider),
  );
});

final exportUseCaseProvider = Provider<ExportUseCase>((ref) {
  return ExportUseCase(ref.watch(keyManagerProvider));
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
