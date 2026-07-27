import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/vault_collection.dart';
import 'organization_file_list.dart';

class CollectionFilesScreen extends ConsumerWidget {
  const CollectionFilesScreen({required this.collection, super.key});

  final VaultCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(vaultFilesInCollectionStreamProvider(collection.id));
    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: buildOrganizationFileList(context, filesAsync),
    );
  }
}
