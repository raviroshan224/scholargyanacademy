import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

final confirmEmailLoadingProvider = StateProvider<bool>((Ref ref) => false);

final confirmEmailViewModelProvider =
    Provider.autoDispose<ConfirmEmailViewModel>((Ref ref) {
      final ctrl = ConfirmEmailViewModel(ref);
      ref.onDispose(() {
        ctrl.dispose();
      });
      return ctrl;
    });

class ConfirmEmailViewModel {
  final Ref ref;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final Map<String, String?> _fieldErrors = {};

  ConfirmEmailViewModel(this.ref);

  bool get isLoading => ref.read(confirmEmailLoadingProvider);

  String? getFieldErrorText(String key) => _fieldErrors[key];

  Future<bool> submitConfirmEmail(BuildContext context) async {
    _fieldErrors.clear();
    final email = emailController.text.trim();

    if (email.isEmpty) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Please enter an email',
        isError: true,
      );
      return false;
    }

    ref.read(confirmEmailLoadingProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.forgotPassword(email);
      bool isSuccess = false;
      res.fold(
        (failure) {
          final fieldErrors = failure?.fieldErrors;
          if (fieldErrors != null && fieldErrors.isNotEmpty) {
            fieldErrors.forEach((key, value) {
              if (value.isNotEmpty) {
                _fieldErrors[key] = value.first;
              }
            });
          }

          AppMethods.showCustomSnackBar(
            context: context,
            message: failure!.message,
            isError: true,
          );
        },
        (_) async {
          AppMethods.showCustomSnackBar(
            context: context,
            message: 'OTP sent to your email',
          );
          isSuccess = true;
        },
      );
      return isSuccess;
    } catch (e) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: 'Failed to request OTP. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      ref.read(confirmEmailLoadingProvider.notifier).state = false;
    }
  }

  void dispose() {
    emailController.dispose();
  }
}
