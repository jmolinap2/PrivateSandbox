import 'dart:async';

import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth/auth_controller.dart';
import '../application/auth/lock_state.dart';
import '../application/providers.dart';
import '../domain/entities/auto_lock_timeout.dart';

/// Re-locks the vault when the app returns from the background, if it was
/// away for at least the configured [AutoLockTimeout] — an unlocked vault
/// sitting in the app switcher defeats the point of a "bóveda privada".
///
/// Only [AppLifecycleState.paused] starts the away-timer, not `inactive`:
/// `inactive` also fires for transient system overlays (share sheet,
/// permission dialogs, and — critically — the biometric prompt itself),
/// so keying off it would re-lock the app while the user is mid-unlock.
class AppLifecycleLockGate extends ConsumerStatefulWidget {
  const AppLifecycleLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLifecycleLockGate> createState() => _AppLifecycleLockGateState();
}

class _AppLifecycleLockGateState extends ConsumerState<AppLifecycleLockGate> with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;
    if (ref.read(authControllerProvider) != LockState.unlocked) return;

    unawaited(_maybeLock(DateTime.now().difference(pausedAt)));
  }

  Future<void> _maybeLock(Duration awayFor) async {
    final threshold = (await ref.read(authRepositoryProvider).getAutoLockTimeout()).threshold;
    if (threshold == null) return;
    if (awayFor >= threshold) {
      ref.read(authControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
