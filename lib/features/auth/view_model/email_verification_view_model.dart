import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

import '../../../core/methods/app_methods.dart';
import 'auth_state.dart';

class EmailVerificationState {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final bool canResend;
  final int currentTimerSeconds;

  EmailVerificationState({
    GlobalKey<FormState>? formKey,
    TextEditingController? otpController,
    this.canResend = true,
    this.currentTimerSeconds = 0,
  }) : formKey = formKey ?? GlobalKey<FormState>(),
       otpController = otpController ?? TextEditingController();

  factory EmailVerificationState.initial() => EmailVerificationState();

  EmailVerificationState copyWith({
    GlobalKey<FormState>? formKey,
    TextEditingController? otpController,
    bool? canResend,
    int? currentTimerSeconds,
  }) {
    return EmailVerificationState(
      formKey: formKey ?? this.formKey,
      otpController: otpController ?? this.otpController,
      canResend: canResend ?? this.canResend,
      currentTimerSeconds: currentTimerSeconds ?? this.currentTimerSeconds,
    );
  }
}

class EmailVerificationViewModel extends StateNotifier<EmailVerificationState> {
  final Ref ref;
  final String email;
  Timer? _timer;

  EmailVerificationViewModel(this.ref, this.email)
    : super(EmailVerificationState.initial());

  bool get isLoading =>
      ref.watch(authNotifierProvider).status == AuthStatus.loading;

  GlobalKey<FormState> get formKey => state.formKey;
  TextEditingController get otpController => state.otpController;
  bool get canResend => state.canResend;
  int get currentTimerSeconds => state.currentTimerSeconds;

  void initialize() {
    _timer?.cancel();
    state.otpController.clear();
    _startResendTimer();
  }

  Future<void> verifyCode(BuildContext context) async {
    final code = state.otpController.text.trim();
    if (code.isEmpty) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Please enter the verification code.',
        isError: true,
      );
      return;
    }

    if (code.length != 6) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Verification code must be 6 digits.',
        isError: true,
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).verifyEmail(email, code);
  }

  Future<void> resendCode() async {
    if (!state.canResend) return;
    await ref.read(authNotifierProvider.notifier).sendEmailVerification(email);
  }

  void handleCodeSent() {
    state.otpController.clear();
    _startResendTimer();
  }

  void clearOtp() {
    state.otpController.clear();
  }

  void _startResendTimer() {
    _timer?.cancel();
    int seconds = 60;
    state = state.copyWith(canResend: false, currentTimerSeconds: seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds -= 1;
      if (seconds <= 0) {
        timer.cancel();
        state = state.copyWith(canResend: true, currentTimerSeconds: 0);
      } else {
        state = state.copyWith(currentTimerSeconds: seconds);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    state.otpController.dispose();
    super.dispose();
  }
}

final emailVerificationViewModelProvider = StateNotifierProvider.family
    .autoDispose<EmailVerificationViewModel, EmailVerificationState, String>((
      Ref ref,
      String email,
    ) {
      return EmailVerificationViewModel(ref, email);
    });

class EmailVerificationValidators {
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the verification code.';
    }
    if (value.trim().length != 6) {
      return 'Verification code must be 6 digits.';
    }
    return null;
  }
}
