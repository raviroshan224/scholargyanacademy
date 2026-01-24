// Create an authentication state notifier
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class AuthStateNotifier extends StateNotifier<bool> {
  AuthStateNotifier() : super(true);

  void setAuthenticated(bool isAuthenticated) {
    state = isAuthenticated;
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, bool>((Ref ref) {
  return AuthStateNotifier();
});
