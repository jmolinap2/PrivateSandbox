import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../infrastructure/update/app_update_service.dart';

/// Checks for a newer release once per session, when first shown, and offers
/// to install it. Silent when there is no network or nothing new.
class UpdateCheckOnStart extends ConsumerStatefulWidget {
  final Widget child;
  const UpdateCheckOnStart({super.key, required this.child});

  @override
  ConsumerState<UpdateCheckOnStart> createState() => _UpdateCheckOnStartState();
}

class _UpdateCheckOnStartState extends ConsumerState<UpdateCheckOnStart> {
  static bool _checkedThisSession = false;

  @override
  void initState() {
    super.initState();
    if (_checkedThisSession) return;
    _checkedThisSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final service = ref.read(appUpdateServiceProvider);
    try {
      final update = await service.checkForUpdate();
      if (update == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          content: Text(
            update.message.isEmpty
                ? 'Hay una versión nueva (build ${update.buildNumber}).'
                : 'Versión nueva: ${update.message}',
          ),
          action: SnackBarAction(
            label: 'Actualizar',
            onPressed: () => downloadAndInstallUpdate(context, service, update),
          ),
        ),
      );
    } catch (_) {
      // Startup check is best-effort; Settings reports errors explicitly.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Downloads [update] with a progress dialog, then opens Android's installer.
Future<void> downloadAndInstallUpdate(
  BuildContext context,
  AppUpdateService service,
  AvailableUpdate update,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  if (!await service.canInstallPackages()) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Permite "instalar apps desconocidas" para PrivateSandbox y vuelve a pulsar Actualizar.',
        ),
      ),
    );
    await service.openInstallPermissionSettings();
    return;
  }
  if (!context.mounted) return;
  final progress = ValueNotifier<double>(0);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Descargando actualización'),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (_, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: value > 0 ? value : null),
            const SizedBox(height: 8),
            Text('${(value * 100).clamp(0, 100).toStringAsFixed(0)} %'),
          ],
        ),
      ),
    ),
  );
  try {
    final path = await service.download(
      update,
      onProgress: (value) => progress.value = value,
    );
    navigator.pop();
    if (!await service.install(path)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el instalador.')),
      );
    }
  } on AppUpdateException catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
  } finally {
    progress.dispose();
  }
}
