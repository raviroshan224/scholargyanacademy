import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:scholarsgyanacademy/core/core.dart';

import '../../view_model/auth_state.dart';
import '../../view_model/email_verification_view_model.dart';
import '../../view_model/providers/auth_providers.dart';
import 'login_page.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(emailVerificationViewModelProvider(widget.email).notifier)
          .initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final viewModel = ref.read(
        emailVerificationViewModelProvider(widget.email).notifier,
      );

      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.emailVerificationOtpSent) {
        if (mounted) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: 'We sent a new verification code to your email.',
          );
          viewModel.handleCodeSent();
        }
      } else if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.emailVerified) {
        if (mounted) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: 'Email verified successfully. Please log in.',
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.error &&
          next.error != null) {
        if (mounted) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: next.error!,
            isError: true,
          );
        }
      }
    });

    final viewState = ref.watch(
      emailVerificationViewModelProvider(widget.email),
    );
    final viewModel = ref.read(
      emailVerificationViewModelProvider(widget.email).notifier,
    );
    final authState = ref.watch(authNotifierProvider);
    final bool buttonsDisabled = authState.status == AuthStatus.loading;

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray400),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.red.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: viewState.formKey,
          child: ListView(
            children: [
              CText(
                AppStrings.verifyYourEmail,
                textAlign: TextAlign.center,
                type: TextType.headlineLarge,
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                'Enter the 6-digit code sent to:',
                color: AppColors.gray600,
                type: TextType.bodyMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                widget.email,
                color: AppColors.secondary,
                type: TextType.bodyMedium,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
              ),
              AppSpacing.verticalSpaceLarge,
              Pinput(
                controller: viewState.otpController,
                length: 6,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                errorPinTheme: errorPinTheme,
                keyboardType: TextInputType.number,
                showCursor: true,
                validator: EmailVerificationValidators.validateOtp,
              ),
              AppSpacing.verticalSpaceSmall,
              SizedBox(
                width: double.infinity,
                child: ReusableButton(
                  text: AppStrings.verify,
                  isLoading: buttonsDisabled,
                  onPressed: buttonsDisabled
                      ? null
                      : () {
                          if (viewState.formKey.currentState!.validate()) {
                            viewModel.verifyCode(context);
                          }
                        },
                ),
              ),
              AppSpacing.verticalSpaceLarge,
              _buildResendSection(viewState, viewModel, buttonsDisabled),
              AppSpacing.verticalSpaceSmall,
              Center(
                child: TextButton(
                  onPressed: buttonsDisabled ? null : viewModel.clearOtp,
                  child: CText(
                    'Clear OTP',
                    color: AppColors.gray600,
                    type: TextType.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(
    EmailVerificationState viewState,
    EmailVerificationViewModel viewModel,
    bool authLoading,
  ) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CText(
            AppStrings.didntReceiveOtp,
            color: AppColors.gray600,
            type: TextType.bodyMedium,
          ),
          AppSpacing.horizontalSpaceSmall,
          if (!viewState.canResend && viewState.currentTimerSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: CText(
                '${viewState.currentTimerSeconds}s',
                color: AppColors.gray600,
                type: TextType.bodySmall,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            GestureDetector(
              onTap: viewState.canResend && !authLoading
                  ? () async {
                      await viewModel.resendCode();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: viewState.canResend && !authLoading
                      ? AppColors.secondary.withAlpha((0.1 * 255).round())
                      : AppColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CText(
                  AppStrings.resend,
                  color: viewState.canResend && !authLoading
                      ? AppColors.secondary
                      : AppColors.gray600,
                  type: TextType.bodyMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
