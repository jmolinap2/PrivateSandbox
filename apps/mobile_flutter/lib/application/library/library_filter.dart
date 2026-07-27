import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_category.dart';
import '../../domain/entities/vault_file.dart';
import '../providers.dart';

enum LibrarySort { recent, favorite, name }

class LibraryFilter {
  final FileCategory? category;
  final bool favoritesOnly;
  final String query;
  final LibrarySort sort;

  const LibraryFilter({
    this.category,
    this.favoritesOnly = false,
    this.query = '',
    this.sort = LibrarySort.recent,
  });

  LibraryFilter copyWith({
    FileCategory? category,
    bool clearCategory = false,
    bool? favoritesOnly,
    String? query,
    LibrarySort? sort,
  }) {
    return LibraryFilter(
      category: clearCategory ? null : (category ?? this.category),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();

  void setCategory(FileCategory? category) {
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setFavoritesOnly(bool value) => state = state.copyWith(favoritesOnly: value);

  void setQuery(String value) => state = state.copyWith(query: value);

  void setSort(LibrarySort sort) => state = state.copyWith(sort: sort);

  void reset() => state = const LibraryFilter();
}

final libraryFilterProvider = NotifierProvider<LibraryFilterNotifier, LibraryFilter>(LibraryFilterNotifier.new);

/// The raw vault file stream, filtered and sorted according to
/// [libraryFilterProvider] — kept as a pure transformation in the
/// application layer so screens don't each reimplement filtering.
final filteredLibraryProvider = Provider<List<VaultFile>>((ref) {
  final files = ref.watch(vaultFilesStreamProvider).value ?? const <VaultFile>[];
  final filter = ref.watch(libraryFilterProvider);

  var result = files;
  final category = filter.category;
  if (category != null) {
    result = result.where((f) => f.category == category).toList();
  }
  if (filter.favoritesOnly) {
    result = result.where((f) => f.isFavorite).toList();
  }
  final query = filter.query.trim().toLowerCase();
  if (query.isNotEmpty) {
    result = result.where((f) => f.originalName.toLowerCase().contains(query)).toList();
  }

  final sorted = [...result];
  switch (filter.sort) {
    case LibrarySort.recent:
      sorted.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    case LibrarySort.favorite:
      sorted.sort((a, b) {
        if (a.isFavorite == b.isFavorite) return b.importedAt.compareTo(a.importedAt);
        return a.isFavorite ? -1 : 1;
      });
    case LibrarySort.name:
      sorted.sort((a, b) => a.originalName.toLowerCase().compareTo(b.originalName.toLowerCase()));
  }
  return sorted;
});
