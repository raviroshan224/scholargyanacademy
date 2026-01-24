import 'package:flutter/material.dart';
import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../core/core.dart';

class ErrorHandlingService {
  static Map<String, List<String>> handleFieldErrorsForForms(
    Failure error,
    BuildContext context, {
    bool showSnackBar = true,
  }) {
    Map<String, List<String>> fieldErrors = {};

    if (error.fieldErrors?.isNotEmpty ?? false) {
      fieldErrors = Map.from(error.fieldErrors!);

      if (showSnackBar) {
        AppMethods.showCustomSnackBar(
          context: context,
          message: AppStrings.validationErrorTxt,
          isError: true,
        );
      }
    } else if (showSnackBar) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: error.message,
        isError: true,
      );
    }

    return fieldErrors;
  }

  static void handleGeneralErrors(Failure error, BuildContext context) {
    AppMethods.showCustomSnackBar(
      context: context,
      message: error.message,
      isError: true,
    );
  }

  // Helper method to format error messages for display
  static String? formatFieldErrors(List<String>? errors) {
    if (errors == null || errors.isEmpty) return null;
    return errors.length == 1 ? errors.first : '• ${errors.join('\n• ')}';
  }
}
