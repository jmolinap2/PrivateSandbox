import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_smart_album.dart';
import 'organization_file_list.dart';

class SmartAlbumFilesScreen extends ConsumerWidget {
  const SmartAlbumFilesScreen({required this.album, super.key});

  final VaultSmartAlbum album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesForSmartAlbumStreamProvider(album));
    return Scaffold(
      appBar: AppBar(title: Text(album.name)),
      body: buildOrganizationFileList(context, filesAsync),
    );
  }
}
