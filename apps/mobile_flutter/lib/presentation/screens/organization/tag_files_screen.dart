import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_tag.dart';
import 'organization_file_list.dart';

class TagFilesScreen extends ConsumerWidget {
  const TagFilesScreen({required this.tag, super.key});

  final VaultTag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesWithTagStreamProvider(tag.id));
    return Scaffold(
      appBar: AppBar(title: Text(tag.name)),
      body: buildOrganizationFileList(context, filesAsync),
    );
  }
}
