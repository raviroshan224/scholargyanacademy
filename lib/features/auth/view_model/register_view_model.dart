import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/model/register_request.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/email_verification_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

final registerViewModelProvider = Provider<RegisterViewModel>((Ref ref) {
  return RegisterViewModel(ref);
});

class RegisterViewModel {
  final Ref ref;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  RegisterViewModel(this.ref);

  bool get isLoading =>
      ref.read(authNotifierProvider).status == AuthStatus.loading;

  Future<void> submitRegistration(BuildContext context) async {
    final req = RegisterRequest(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      mobileNumber: phoneController.text.trim(),
      password: passwordController.text,
      confirmPassword: confirmPasswordController.text,
      hasConfirmedToTerms: true,
    );

    await ref.read(authNotifierProvider.notifier).register(req);
  }

  void listenToAuthChanges(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.emailVerificationOtpSent) {
        final email = emailController.text.trim();
        AppMethods.showCustomSnackBar(
          context: context,
          message:
              'Registration successful. Please verify your email to continue.',
        );
        if (context.mounted && email.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(email: email),
            ),
          );
        }
      } else if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.error) {
        AppMethods.showCustomSnackBar(
          context: context,
          message: next.error ?? 'Registration failed. Please try again.',
          isError: true,
        );
      }
    });
  }

  void dispose() {}
}
