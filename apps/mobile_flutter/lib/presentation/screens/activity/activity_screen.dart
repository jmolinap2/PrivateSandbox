import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/activity_event.dart';
import '../../widgets/empty_state.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  (IconData, Color) _iconFor(ActivityEventType type, bool success, ColorScheme colors) {
    if (type == ActivityEventType.accessDenied) return (Icons.gpp_bad_outlined, colors.error);
    if (!success) return (Icons.error_outline, colors.error);
    return switch (type) {
      ActivityEventType.imported => (Icons.file_upload_outlined, colors.primary),
      ActivityEventType.exported => (Icons.file_download_outlined, colors.secondary),
      ActivityEventType.deleted => (Icons.delete_outline, colors.error),
      ActivityEventType.accessDenied => (Icons.gpp_bad_outlined, colors.error),
    };
  }

  String _labelFor(ActivityEventType type, bool success) {
    if (type == ActivityEventType.accessDenied) return 'Intento de acceso fallido';
    final action = switch (type) {
      ActivityEventType.imported => 'Archivo importado',
      ActivityEventType.exported => 'Archivo exportado',
      ActivityEventType.deleted => 'Archivo eliminado',
      ActivityEventType.accessDenied => 'Intento de acceso fallido',
    };
    return success ? action : '$action (falló)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activityEventsStreamProvider);
    final dateFormat = DateFormat('d MMM, HH:mm', 'es');

    return Scaffold(
      appBar: AppBar(title: const Text('Actividad')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icons.history_outlined,
              title: 'Sin actividad todavía',
              subtitle: 'Aquí verás el historial de importaciones, exportaciones, eliminaciones e intentos de acceso.',
            );
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final theme = Theme.of(context);
              final (icon, color) = _iconFor(event.type, event.success, theme.colorScheme);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(_labelFor(event.type, event.success)),
                subtitle: Text(
                  event.detail == null ? event.fileName : '${event.fileName} · ${event.detail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(dateFormat.format(event.timestamp), style: theme.textTheme.bodySmall),
              );
            },
          );
        },
      ),
    );
  }
}
