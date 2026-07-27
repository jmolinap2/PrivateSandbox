import 'package:flutter/material.dart';

import 'src/application/companion_controller.dart';
import 'src/presentation/desktop_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    PrivateSandboxDesktopApp(controller: CompanionController.production()),
  );
}

class PrivateSandboxDesktopApp extends StatelessWidget {
  final CompanionController controller;

  const PrivateSandboxDesktopApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF080D12);
    const surface = Color(0xFF101820);
    const accent = Color(0xFF5DE2B8);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Private Sandbox Companion',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B1219),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: DesktopShell(controller: controller),
    );
  }
}
