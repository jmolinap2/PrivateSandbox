import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/synchronization/device_identity.dart';
import '../../domain/synchronization/sync_protocol.dart';
import '../../infrastructure/synchronization/resumable_blob_transfer.dart';
import '../providers.dart';
import 'synchronization_engine.dart';

enum SyncRunPhase { idle, running, succeeded, failed, cancelled }

class SyncRunState {
  final SyncRunPhase phase;
  final SyncTransferProgress? progress;
  final SynchronizationResult? result;
  final String? error;
  final DateTime? lastRunAt;

  const SyncRunState({
    this.phase = SyncRunPhase.idle,
    this.progress,
    this.result,
    this.error,
    this.lastRunAt,
  });

  List<RemoteDeviceDirective> get pendingDirectives =>
      result?.pendingDirectives ?? const <RemoteDeviceDirective>[];
}

class SyncController extends Notifier<SyncRunState> {
  bool _cancelRequested = false;

  @override
  SyncRunState build() => const SyncRunState();

  Future<SynchronizationResult?> synchronize({
    Set<String> requestedDownloads = const <String>{},
  }) async {
    if (state.phase == SyncRunPhase.running) return null;
    _cancelRequested = false;
    state = const SyncRunState(phase: SyncRunPhase.running);
    try {
      final result = await ref
          .read(configuredSynchronizationServiceProvider)
          .run(
            requestedDownloads: requestedDownloads,
            isCancelled: () => _cancelRequested,
            onProgress: (progress) {
              state = SyncRunState(
                phase: SyncRunPhase.running,
                progress: progress,
              );
            },
          );
      state = SyncRunState(
        phase: SyncRunPhase.succeeded,
        result: result,
        lastRunAt: DateTime.now(),
      );
      return result;
    } on SyncCancelledException {
      state = SyncRunState(
        phase: SyncRunPhase.cancelled,
        lastRunAt: DateTime.now(),
      );
      return null;
    } catch (error) {
      state = SyncRunState(
        phase: SyncRunPhase.failed,
        error: _friendlyMessage(error),
        lastRunAt: DateTime.now(),
      );
      return null;
    }
  }

  void cancel() => _cancelRequested = true;

  void resetStatus() => state = const SyncRunState();

  String _friendlyMessage(Object error) {
    if (error is SyncAuthorizationException) {
      return 'Este dispositivo todavía no está autorizado o fue revocado.';
    }
    if (error is SyncIntegrityException) {
      return 'Se detectó una alteración o retroceso en los datos remotos: '
          '${error.message}';
    }
    if (error is SyncTransportException) {
      final status = error.statusCode == null ? '' : ' (${error.statusCode})';
      return 'No se pudo acceder al servidor$status: ${error.message}';
    }
    if (error is SyncException) return error.message;
    return 'La sincronización falló: $error';
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncRunState>(
  SyncController.new,
);
