import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/reset_password_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/otp_view_model.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpViewModelProvider(widget.email).notifier).resetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.passwordResetOtpVerified) {
        final otpViewModel = ref.read(
          otpViewModelProvider(widget.email).notifier,
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordPage(
                email: widget.email,
                otp: otpViewModel.otpController.text,
              ),
            ),
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

    final otpState = ref.watch(otpViewModelProvider(widget.email));
    final otpViewModel = ref.read(otpViewModelProvider(widget.email).notifier);
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
          key: otpState.formKey,
          child: ListView(
            children: [
              CText(
                AppStrings.resetPassword,
                textAlign: TextAlign.center,
                type: TextType.headlineLarge,
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                'Enter the 6-digit OTP sent to:',
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
                controller: otpState.otpController,
                length: 6,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                errorPinTheme: errorPinTheme,
                keyboardType: TextInputType.number,
                showCursor: true,
                validator: OtpValidators.validateOtp,
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
                          if (otpState.formKey.currentState!.validate()) {
                            otpViewModel.submitOtpCode(context);
                          }
                        },
                ),
              ),
              AppSpacing.verticalSpaceLarge,
              _buildResendSection(otpState, otpViewModel, buttonsDisabled),
              AppSpacing.verticalSpaceSmall,
              Center(
                child: TextButton(
                  onPressed: buttonsDisabled ? null : otpViewModel.clearOtp,
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
    OtpState otpState,
    OtpViewModel otpViewModel,
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
          if (!otpState.canResend && otpState.currentTimerSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: CText(
                '${otpState.currentTimerSeconds}s',
                color: AppColors.gray600,
                type: TextType.bodySmall,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            GestureDetector(
              onTap: otpState.canResend && !authLoading
                  ? () => otpViewModel.resendOtp(context)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: otpState.canResend && !authLoading
                      ? AppColors.secondary.withAlpha((0.1 * 255).round())
                      : AppColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CText(
                  AppStrings.resend,
                  color: otpState.canResend && !authLoading
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
