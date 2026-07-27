import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/vault_file.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vault_file_list_tile.dart';

/// Shared by the tag/collection/smart-album "members" screens — they only
/// differ in which provider feeds the list.
Widget buildOrganizationFileList(BuildContext context, AsyncValue<List<VaultFile>> filesAsync) {
  return filesAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text('Error: $error')),
    data: (files) {
      if (files.isEmpty) {
        return const EmptyState(
          icon: Icons.folder_open_outlined,
          title: 'Sin archivos',
          subtitle: 'Todavía no hay archivos aquí.',
        );
      }
      final queueIds = [for (final f in files) f.id];
      return ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return VaultFileListTile(
            file: file,
            onTap: () => context.push(AppRoutes.viewerFor(file.id), extra: queueIds),
          );
        },
      );
    },
  );
}
