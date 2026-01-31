import '../model/auth_models.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  passwordResetEmailSent,
  passwordResetOtpVerified,
  emailVerificationOtpSent,
  emailVerified,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final Map<String, List<String>>? fieldErrors;
  final int? statusCode;
  final int? throttleSeconds;
  final bool hasCompletedStartupCheck;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.fieldErrors,
    this.statusCode,
    this.throttleSeconds,
    this.hasCompletedStartupCheck = false,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    Map<String, List<String>>? fieldErrors,
    int? statusCode,
    int? throttleSeconds,
    bool? hasCompletedStartupCheck,
    bool clearUser = false,
    bool clearError = false,
    bool clearFieldErrors = false,
    bool clearFailureMetadata = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
      fieldErrors: clearFieldErrors ? null : fieldErrors ?? this.fieldErrors,
      statusCode: clearFailureMetadata ? null : statusCode ?? this.statusCode,
      throttleSeconds: clearFailureMetadata
          ? null
          : throttleSeconds ?? this.throttleSeconds,
      hasCompletedStartupCheck:
          hasCompletedStartupCheck ?? this.hasCompletedStartupCheck,
    );
  }
}
