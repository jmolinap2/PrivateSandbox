import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected bottom-nav tab in [AppShell]. A plain provider (not go_router
/// state) so screens like Home can jump to Library pre-filtered without
/// round-tripping through route params.
class SelectedTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final selectedTabIndexProvider = NotifierProvider<SelectedTabIndex, int>(SelectedTabIndex.new);
