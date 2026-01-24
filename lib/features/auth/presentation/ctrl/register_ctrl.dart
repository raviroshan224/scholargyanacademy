import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/features/auth/model/register_request.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/login_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

import '../../../../core/core.dart';

// Provider for the register controller used by the registration page.
// Removed autoDispose & manual dispose so field values persist across error rebuilds.
final registerCtrlProvider = Provider<RegisterCtrl>((Ref ref) {
  return RegisterCtrl(ref);
});

class RegisterCtrl {
  final Ref ref;

  // Text controllers used by the UI
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  RegisterCtrl(this.ref);

  // Expose isLoading without watching to prevent provider recreation clearing inputs
  bool get isLoading =>
      ref.read(authNotifierProvider).status == AuthStatus.loading;

  /// Submit registration.
  Future<void> submitRegistration(BuildContext context) async {
    final req = RegisterRequest(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      mobileNumber: phoneController.text.trim(),
      password: passwordController.text,
      confirmPassword: confirmPasswordController.text,
      hasConfirmedToTerms: true,
    );

    // Trigger register action
    await ref.read(authNotifierProvider.notifier).register(req);
  }

  void listenToAuthChanges(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.unauthenticated) {
        // Successful registration
        AppMethods.showCustomSnackBar(
          context: context,
          message: 'Registration successful. Please log in.',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.error) {
        // Registration failed
        AppMethods.showCustomSnackBar(
          context: context,
          message: next.error ?? 'Registration failed. Please try again.',
          isError: true,
        );
      }
    });
  }

  void dispose() {
    // Intentionally left empty; controllers persist for auth flow.
  }
}
