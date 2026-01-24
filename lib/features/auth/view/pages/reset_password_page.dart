import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/reset_password_view_model.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.email, this.otp});

  final String? email;
  final String? otp;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(
            resetPasswordViewModelProvider(
              ResetPasswordParams(email: widget.email, otp: widget.otp),
            ).notifier,
          )
          .listenToAuthChanges(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resetPasswordState = ref.watch(
      resetPasswordViewModelProvider(
        ResetPasswordParams(email: widget.email, otp: widget.otp),
      ),
    );
    final resetPasswordViewModel = ref.read(
      resetPasswordViewModelProvider(
        ResetPasswordParams(email: widget.email, otp: widget.otp),
      ).notifier,
    );
    final authState = ref.watch(authNotifierProvider);
    final isPasswordVisible = ref.watch(isResetPasswordVisibleProvider);
    final isConfirmPasswordVisible = ref.watch(
      isResetConfirmPasswordVisibleProvider,
    );

    final bool buttonsDisabled = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: CustomAppBar(),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: resetPasswordViewModel.formKey,
          child: ListView(
            children: [
              CText(
                AppStrings.resetPassword,
                textAlign: TextAlign.center,
                type: TextType.headlineLarge,
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                'Create a new password for your account',
                textAlign: TextAlign.center,
                type: TextType.bodyMedium,
                color: AppColors.gray600,
              ),
              AppSpacing.verticalSpaceLarge,
              CustTextField(
                hintText: 'New Password',
                controller: resetPasswordState.passwordController,
                prefixIcon: const Icon(Icons.lock),
                obscureText: !isPasswordVisible,
                validator: FieldValidators.validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.gray600,
                  ),
                  onPressed: () {
                    ref
                        .read(isResetPasswordVisibleProvider.notifier)
                        .update((state) => !state);
                  },
                ),
              ),
              AppSpacing.verticalSpaceLarge,
              CustTextField(
                hintText: 'Confirm New Password',
                controller: resetPasswordState.confirmPasswordController,
                prefixIcon: const Icon(Icons.lock),
                obscureText: !isConfirmPasswordVisible,
                validator: (value) => FieldValidators.validateConfirmPassword(
                  value,
                  resetPasswordViewModel.passwordController.text,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.gray600,
                  ),
                  onPressed: () {
                    ref
                        .read(isResetConfirmPasswordVisibleProvider.notifier)
                        .update((state) => !state);
                  },
                ),
              ),
              AppSpacing.verticalSpaceLarge,
              SizedBox(
                width: double.infinity,
                child: ReusableButton(
                  text: AppStrings.confirm,
                  isLoading: buttonsDisabled,
                  onPressed: buttonsDisabled
                      ? null
                      : () {
                          if (resetPasswordViewModel.formKey.currentState!
                              .validate()) {
                            resetPasswordViewModel.submitResetPassword(context);
                          }
                        },
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.white,
                ),
              ),
              AppSpacing.verticalSpaceMedium,
              Center(
                child: TextButton(
                  onPressed: buttonsDisabled
                      ? null
                      : () => Navigator.pop(context),
                  child: CText(
                    'Cancel',
                    color: AppColors.gray600,
                    type: TextType.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
