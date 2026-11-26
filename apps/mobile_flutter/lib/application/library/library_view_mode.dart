import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LibraryViewMode { list, grid }

class LibraryViewModeNotifier extends Notifier<LibraryViewMode> {
  @override
  LibraryViewMode build() => LibraryViewMode.list;

  void toggle() => state = state == LibraryViewMode.list ? LibraryViewMode.grid : LibraryViewMode.list;
}

final libraryViewModeProvider = NotifierProvider<LibraryViewModeNotifier, LibraryViewMode>(LibraryViewModeNotifier.new);
