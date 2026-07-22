import 'package:flutter/material.dart';

/// Shown only for the instant it takes [AuthController] to check whether a
/// PIN already exists. Kept separate from the unlock/setup screens so the
/// router never has to guess which of those two a not-yet-known state
/// should land on.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
