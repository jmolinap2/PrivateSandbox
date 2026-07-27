import 'package:flutter/material.dart';

import '../application/companion_controller.dart';
import 'pages/catalog_page.dart';
import 'pages/pairing_page.dart';
import 'pages/setup_page.dart';

class DesktopShell extends StatefulWidget {
  final CompanionController controller;

  const DesktopShell({super.key, required this.controller});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final extended = width >= 1050;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() => _selectedIndex = value);
                  },
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 22),
                    child: extended
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Private Sandbox',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          )
                        : const Icon(Icons.shield_outlined, size: 28),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.cloud_outlined),
                      selectedIcon: Icon(Icons.cloud),
                      label: Text('WebDAV'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.devices_other_outlined),
                      selectedIcon: Icon(Icons.devices_other),
                      label: Text('Emparejamiento'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Catálogo'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(controller: widget.controller),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: [
                            SetupPage(controller: widget.controller),
                            PairingPage(controller: widget.controller),
                            CatalogPage(controller: widget.controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final CompanionController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final error = controller.errorMessage;
    final status = controller.statusMessage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Companion de escritorio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                _StateChip(
                  icon: controller.identity == null
                      ? Icons.key_off_outlined
                      : Icons.key_outlined,
                  label: controller.identity == null
                      ? 'Sin identidad'
                      : 'Identidad lista',
                  active: controller.identity != null,
                ),
                const SizedBox(width: 8),
                _StateChip(
                  icon: controller.hasMasterKey
                      ? Icons.lock
                      : Icons.lock_open_outlined,
                  label: controller.hasMasterKey
                      ? 'Bóveda inscrita'
                      : 'Sin inscripción',
                  active: controller.hasMasterKey,
                ),
              ],
            ),
          ),
        ),
        if (controller.busy) const LinearProgressIndicator(minHeight: 2),
        if (error != null || status != null)
          MaterialBanner(
            backgroundColor: error == null
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            content: Text(error ?? status!),
            leading: Icon(
              error == null ? Icons.check_circle_outline : Icons.error_outline,
            ),
            actions: [
              TextButton(
                onPressed: controller.clearMessage,
                child: const Text('CERRAR'),
              ),
            ],
          ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _StateChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: BorderSide(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
