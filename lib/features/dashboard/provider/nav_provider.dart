import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';

class NavigationState {
  final int selectedIndex;

  NavigationState({
    required this.selectedIndex,
  });

  factory NavigationState.initial() => NavigationState(selectedIndex: 0);

  NavigationState copyWith({int? selectedIndex}) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
  (Ref ref) => NavigationNotifier(),
);

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState.initial());

  void navigate(int index) {
    state = state.copyWith(selectedIndex: index);
  }
}
