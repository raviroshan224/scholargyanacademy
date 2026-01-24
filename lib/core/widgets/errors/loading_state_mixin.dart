import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/core/core.dart';

/// A mixin that provides common loading state management for controllers
mixin LoadingStateMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      AppMethods.showCustomSnackBar(
        context: context,
        message: message,
        isError: true,
      );
    }
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      AppMethods.showCustomSnackBar(context: context, message: message);
    }
  }
}
