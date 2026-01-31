import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

import '../../../core/methods/app_methods.dart';
import 'auth_state.dart';

class OtpState {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final bool canResend;
  final int currentTimerSeconds;

  OtpState({
    GlobalKey<FormState>? formKey,
    TextEditingController? otpController,
    this.canResend = true,
    this.currentTimerSeconds = 0,
  }) : formKey = formKey ?? GlobalKey<FormState>(),
       otpController = otpController ?? TextEditingController();

  factory OtpState.initial() => OtpState();

  OtpState copyWith({
    GlobalKey<FormState>? formKey,
    TextEditingController? otpController,
    bool? canResend,
    int? currentTimerSeconds,
  }) {
    return OtpState(
      formKey: formKey ?? this.formKey,
      otpController: otpController ?? this.otpController,
      canResend: canResend ?? this.canResend,
      currentTimerSeconds: currentTimerSeconds ?? this.currentTimerSeconds,
    );
  }
}

class OtpViewModel extends StateNotifier<OtpState> {
  final Ref ref;
  final String email;
  Timer? _timer;

  OtpViewModel(this.ref, this.email) : super(OtpState.initial());

  void resetState() {
    _timer?.cancel();
    state = OtpState.initial();
  }

  bool get isLoading =>
      ref.watch(authNotifierProvider).status == AuthStatus.loading;

  GlobalKey<FormState> get formKey => state.formKey;
  TextEditingController get otpController => state.otpController;
  bool get canResend => state.canResend;
  int get currentTimerSeconds => state.currentTimerSeconds;

  void clearOtp() {
    state.otpController.clear();
  }

  Future<void> submitOtpCode(BuildContext context) async {
    final otp = state.otpController.text.trim();

    if (otp.isEmpty) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Please enter OTP',
        isError: true,
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).verifyOtp(email, otp);
  }

  Future<void> resendOtp(BuildContext context) async {
    if (!state.canResend) return;

    await ref.read(authNotifierProvider.notifier).forgotPassword(email);
    _startResendTimer();
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

final otpViewModelProvider = StateNotifierProvider.family
    .autoDispose<OtpViewModel, OtpState, String>((Ref ref, String email) {
      return OtpViewModel(ref, email);
    });

class OtpValidators {
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter OTP';
    if (value.trim().length != 6) return 'OTP must be 6 digits';
    return null;
  }
}
