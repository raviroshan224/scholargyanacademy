import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/login_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

final isResetPasswordVisibleProvider = StateProvider<bool>((Ref ref) => false);
final isResetConfirmPasswordVisibleProvider = StateProvider<bool>(
  (Ref ref) => false,
);

class ResetPasswordState {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  ResetPasswordState({
    GlobalKey<FormState>? formKey,
    TextEditingController? passwordController,
    TextEditingController? confirmPasswordController,
  }) : formKey = formKey ?? GlobalKey<FormState>(),
       passwordController = passwordController ?? TextEditingController(),
       confirmPasswordController =
           confirmPasswordController ?? TextEditingController();

  factory ResetPasswordState.initial() => ResetPasswordState();

  ResetPasswordState copyWith({
    GlobalKey<FormState>? formKey,
    TextEditingController? passwordController,
    TextEditingController? confirmPasswordController,
  }) {
    return ResetPasswordState(
      formKey: formKey ?? this.formKey,
      passwordController: passwordController ?? this.passwordController,
      confirmPasswordController:
          confirmPasswordController ?? this.confirmPasswordController,
    );
  }
}

class ResetPasswordViewModel extends StateNotifier<ResetPasswordState> {
  final Ref ref;
  final String? email;
  final String? otp;

  ResetPasswordViewModel(this.ref, this.email, this.otp)
    : super(ResetPasswordState.initial());

  bool get isLoading =>
      ref.watch(authNotifierProvider).status == AuthStatus.loading;
  GlobalKey<FormState> get formKey => state.formKey;
  TextEditingController get passwordController => state.passwordController;
  TextEditingController get confirmPasswordController =>
      state.confirmPasswordController;

  Future<void> submitResetPassword(BuildContext context) async {
    final password = state.passwordController.text.trim();
    final confirm = state.confirmPasswordController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Please fill out both password fields',
        isError: true,
      );
      return;
    }

    if (password != confirm) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Passwords do not match',
        isError: true,
      );
      return;
    }

    if (email == null || otp == null) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Email or OTP is missing for password reset.',
        isError: true,
      );
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(email!, otp!, password);
  }

  void listenToAuthChanges(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.unauthenticated) {
        AppMethods.showCustomSnackBar(
          context: context,
          message: 'Password reset successful.',
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.error) {
        AppMethods.showCustomSnackBar(
          context: context,
          message: next.error ?? 'Failed to reset password. Please try again.',
          isError: true,
        );
      }
    });
  }

  @override
  void dispose() {
    state.passwordController.dispose();
    state.confirmPasswordController.dispose();
    super.dispose();
  }
}

class ResetPasswordParams {
  final String? email;
  final String? otp;

  const ResetPasswordParams({this.email, this.otp});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResetPasswordParams &&
        other.email == email &&
        other.otp == otp;
  }

  @override
  int get hashCode => Object.hash(email, otp);
}

final resetPasswordViewModelProvider =
    StateNotifierProvider.family<
      ResetPasswordViewModel,
      ResetPasswordState,
      ResetPasswordParams
    >((Ref ref, ResetPasswordParams params) {
      return ResetPasswordViewModel(ref, params.email, params.otp);
    });
