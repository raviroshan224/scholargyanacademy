import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';
import 'package:scholarsgyanacademy/features/before_auth/presentation/pages/course_selection.dart';
import 'package:scholarsgyanacademy/features/dashboard/presentation/pages/dashboard.dart';

final loginViewModelProvider = Provider<LoginViewModel>((Ref ref) {
  return LoginViewModel(ref);
});

class LoginViewModel {
  final Ref ref;

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _inProgress = false;

  LoginViewModel(this.ref);

  bool get isLoading =>
      _inProgress ||
      ref.read(authNotifierProvider).status == AuthStatus.loading;

  Future<void> handleLogin(BuildContext context) async {
    if (_inProgress) return;
    final email = userNameController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Please enter email and password',
        isError: true,
      );
      return;
    }

    _inProgress = true;
    try {
      await ref.read(authNotifierProvider.notifier).login(email, password);
    } finally {
      Future.microtask(() {
        _inProgress = false;
      });
    }
  }

  void listenToAuthChanges(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!context.mounted || previous == null) {
        return;
      }

      final becameAuthenticated =
          previous.status != AuthStatus.authenticated &&
          next.status == AuthStatus.authenticated;
      if (becameAuthenticated) {
        final hasSelectedCategories = next.user?.hasSelectedCategories ?? false;
        final welcomeMessage = hasSelectedCategories
            ? 'Welcome back!'
            : "Welcome! Let's personalize your courses.";

        AppMethods.showCustomSnackBar(
          context: context,
          message: welcomeMessage,
        );

        final Widget destination = hasSelectedCategories
            ? const Dashboard()
            : CourseSelection(
                userName: next.user?.fullName ?? next.user?.email,
              );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
        return;
      }

      final loadingFailed =
          previous.status == AuthStatus.loading &&
          next.status == AuthStatus.error;
      if (loadingFailed) {
        final throttle = next.throttleSeconds;
        AppMethods.showCustomSnackBar(
          context: context,
          message: _composeErrorMessage(next),
          isError: true,
          duration: throttle != null
              ? Duration(
                  seconds: throttle < 3
                      ? 3
                      : throttle > 10
                      ? 10
                      : throttle,
                )
              : const Duration(milliseconds: 2500),
        );
        return;
      }

      final loggedOut =
          previous.status == AuthStatus.authenticated &&
          next.status == AuthStatus.unauthenticated;
      if (loggedOut) {
        userNameController.clear();
        passwordController.clear();
        final message = next.error;
        if (message != null && message.isNotEmpty) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: message,
            isError: true,
          );
        }
      }
    });
  }

  String _composeErrorMessage(AuthState state) {
    final buffer = StringBuffer(
      state.error ?? 'Login failed. Please try again.',
    );
    if (state.throttleSeconds != null) {
      buffer.write(
        ' Please wait ${state.throttleSeconds} seconds before retrying.',
      );
    }
    return buffer.toString();
  }

  void dispose() {
    // Controllers intentionally kept for lifecycle; disposal handled by app shutdown.
  }
}
