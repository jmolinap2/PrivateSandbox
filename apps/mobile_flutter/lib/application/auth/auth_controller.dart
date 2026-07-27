import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_event.dart';
import '../providers.dart';
import 'lock_state.dart';

const _uuid = Uuid();

/// Drives the app's single lock gate: whether a PIN still needs to be
/// created, the vault is locked, or it has been unlocked for this session.
/// Interrupted-import cleanup runs right after every successful unlock, so
/// the gallery never shows a partially-imported file.
class AuthController extends Notifier<LockState> {
  @override
  LockState build() {
    Future.microtask(_checkInitialState);
    return LockState.checking;
  }

  Future<void> _checkInitialState() async {
    final hasPin = await ref.read(authRepositoryProvider).hasPin();
    state = hasPin ? LockState.locked : LockState.needsSetup;
  }

  Future<void> setupPin(String pin) async {
    await ref.read(authRepositoryProvider).setPin(pin);
    await ref.read(recoveryUseCaseProvider).recoverInterruptedImports();
    state = LockState.unlocked;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await ref.read(authRepositoryProvider).verifyPin(pin);
    if (ok) {
      await ref.read(recoveryUseCaseProvider).recoverInterruptedImports();
      state = LockState.unlocked;
    } else {
      await _logAccessDenied('PIN incorrecto');
    }
    return ok;
  }

  Future<bool> unlockWithBiometrics() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (!await authRepo.isBiometricEnabled() || !await authRepo.isBiometricAvailable()) {
      return false;
    }
    final ok = await authRepo.authenticateWithBiometrics();
    if (ok) {
      await ref.read(recoveryUseCaseProvider).recoverInterruptedImports();
      state = LockState.unlocked;
    } else {
      await _logAccessDenied('Biometría fallida o cancelada');
    }
    return ok;
  }

  Future<void> _logAccessDenied(String reason) {
    return ref.read(activityRepositoryProvider).logEvent(ActivityEvent(
          id: _uuid.v4(),
          type: ActivityEventType.accessDenied,
          fileName: reason,
          timestamp: DateTime.now(),
          success: false,
        ));
  }

  void lock() {
    state = LockState.locked;
  }
}

final authControllerProvider = NotifierProvider<AuthController, LockState>(AuthController.new);
