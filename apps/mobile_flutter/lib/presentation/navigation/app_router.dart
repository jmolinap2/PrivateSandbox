import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth/auth_controller.dart';
import '../../application/auth/lock_state.dart';
import '../screens/auth/pin_setup_screen.dart';
import '../screens/auth/pin_unlock_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/viewer/viewer_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier(ref.read(authControllerProvider));
  ref.listen<LockState>(authControllerProvider, (previous, next) {
    refreshNotifier.value = next;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    // Each lock state owns exactly one "resting" location, checked
    // independently — a previous version grouped pin-setup and pin-unlock
    // under one `isAuthRoute` check, which meant `needsSetup` on a cold
    // start (landing on pin-unlock while still `checking`) was mistaken for
    // already being on a valid screen and never redirected to pin-setup.
    redirect: (context, state) {
      final lockState = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      switch (lockState) {
        case LockState.checking:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case LockState.needsSetup:
          return location == AppRoutes.pinSetup ? null : AppRoutes.pinSetup;
        case LockState.locked:
          return location == AppRoutes.pinUnlock ? null : AppRoutes.pinUnlock;
        case LockState.unlocked:
          final isAuthRoute = location == AppRoutes.splash ||
              location == AppRoutes.pinSetup ||
              location == AppRoutes.pinUnlock;
          return isAuthRoute ? AppRoutes.gallery : null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.pinSetup, builder: (context, state) => const PinSetupScreen()),
      GoRoute(path: AppRoutes.pinUnlock, builder: (context, state) => const PinUnlockScreen()),
      GoRoute(path: AppRoutes.gallery, builder: (context, state) => const AppShell()),
      GoRoute(
        path: '${AppRoutes.viewer}/:id',
        // `extra` carries the ordered ids of the list the file was opened from,
        // so video/audio players can use them as a playback queue.
        builder: (context, state) => ViewerScreen(
          fileId: state.pathParameters['id']!,
          queueIds: state.extra is List<String> ? state.extra as List<String> : null,
        ),
      ),
    ],
  );
});
