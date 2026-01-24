import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';

class TabIndexNotifier extends StateNotifier<int> {
  TabIndexNotifier() : super(0);

  void selectTab(int index) {
    state = index;
  }
}

final tabIndexProvider =
    StateNotifierProvider<TabIndexNotifier, int>((Ref ref) {
  return TabIndexNotifier();
});
