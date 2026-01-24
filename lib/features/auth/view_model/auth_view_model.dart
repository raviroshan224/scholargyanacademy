import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/config/local_db/hive/hive_data_source.dart';
import 'package:scholarsgyanacademy/config/services/secure_storage_service.dart';
import 'package:scholarsgyanacademy/features/auth/model/auth_models.dart';
import 'package:scholarsgyanacademy/features/auth/model/email_verification_request.dart';
import 'package:scholarsgyanacademy/features/auth/model/login_request.dart';
import 'package:scholarsgyanacademy/features/auth/model/register_request.dart';
import 'package:scholarsgyanacademy/features/auth/service/auth_service.dart';
import 'package:scholarsgyanacademy/features/auth/service/user_service.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/network_layer/src/api_config.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(this._authService, this._userService, this._secureStorage)
    : super(AuthState.initial());

  final AuthService _authService;
  final UserService _userService;
  final SecureStorageService _secureStorage;

  static const String _userCacheKey = 'cached_user_profile';

  bool _isPerformingStartupCheck = false;
  Timer? _refreshTimer;

  VoidCallback? _onLogout;

  /// Called by MyApp / RootApp to register provider reset callback
  void setLogoutCallback(VoidCallback callback) {
    _onLogout = callback;
  }

  Future<void> checkAuthenticationOnStartup() async {
    if (_isPerformingStartupCheck) return;
    _isPerformingStartupCheck = true;

    state = state.copyWith(
      status: AuthStatus.loading,
      hasCompletedStartupCheck: false,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    try {
      final token = await _secureStorage.read('token');
      if (token == null || token.isEmpty) {
        await _clearCachedUser();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasCompletedStartupCheck: true,
          clearUser: true,
        );
        return;
      }

      await _hydrateLegacyClients(token);

      // Check token expiry but DON'T logout immediately
      // Let the interceptor handle refresh on first API call
      final expiresAt = await _readTokenExpiry();
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        // Token is expired, but we have a refresh token
        // Log this and continue - interceptor will refresh on first API call
        print(
          '⚠️ Access token expired on startup. Will refresh via interceptor on first API call.',
        );
      }

      final cachedUser = await _readCachedUser();
      if (cachedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: cachedUser,
          hasCompletedStartupCheck: true,
          clearError: true,
          clearFieldErrors: true,
          clearFailureMetadata: true,
        );
      }

      final response = await _userService.getMe();
      if (response.isLeft) {
        final failure = response.left;

        if (failure.statusCode == 401 || failure.statusCode == 403) {
          await logout();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            hasCompletedStartupCheck: true,
            error: failure.message,
            clearFieldErrors: true,
            clearFailureMetadata: true,
          );
          return;
        }

        if (cachedUser == null) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            error: failure.message,
            fieldErrors: failure.fieldErrors,
            statusCode: failure.statusCode,
            throttleSeconds: failure.throttleSeconds,
            hasCompletedStartupCheck: true,
            clearUser: true,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            error: failure.message,
            statusCode: failure.statusCode,
            throttleSeconds: failure.throttleSeconds,
            hasCompletedStartupCheck: true,
          );
        }
        return;
      }

      final user = response.right;
      await _persistUser(user);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasCompletedStartupCheck: true,
        clearError: true,
        clearFieldErrors: true,
        clearFailureMetadata: true,
      );
    } catch (_) {
      await _clearCachedUser();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCompletedStartupCheck: true,
        error: 'We could not restore your session. Please log in again.',
        clearFieldErrors: true,
        clearFailureMetadata: true,
        clearUser: true,
      );
    } finally {
      _isPerformingStartupCheck = false;
    }

    // Schedule proactive token refresh after successful startup
    _scheduleTokenRefresh();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final result = await _authService.login(
      LoginRequest(email: email, password: password),
    );

    if (result.isLeft) {
      final failure = result.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    final authResponse = result.right;
    await _persistUser(authResponse.user);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: authResponse.user,
      hasCompletedStartupCheck: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    // Schedule proactive token refresh after successful login
    _scheduleTokenRefresh();
  }

  Future<void> register(RegisterRequest request) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _authService.register(request);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    final verificationResponse = await _authService.sendEmailVerification(
      SendEmailVerificationRequest(email: request.email),
    );

    if (verificationResponse.isLeft) {
      final failure = verificationResponse.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
        clearUser: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.emailVerificationOtpSent,
      hasCompletedStartupCheck: true,
      clearUser: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> sendEmailVerification(String email) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _authService.sendEmailVerification(
      SendEmailVerificationRequest(email: email),
    );

    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
        clearUser: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.emailVerificationOtpSent,
      hasCompletedStartupCheck: true,
      clearUser: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> verifyEmail(String email, String otp) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _authService.verifyEmailOtp(
      VerifyEmailOtpRequest(email: email, otp: otp),
    );

    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
        clearUser: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.emailVerified,
      hasCompletedStartupCheck: true,
      clearUser: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _authService.forgotPassword(email);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.passwordResetEmailSent,
      hasCompletedStartupCheck: true,
      clearFailureMetadata: true,
      clearError: true,
      clearFieldErrors: true,
    );
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _authService.verifyOtp(email, otp);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.passwordResetOtpVerified,
      hasCompletedStartupCheck: true,
      clearFailureMetadata: true,
      clearError: true,
      clearFieldErrors: true,
    );
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _authService.resetPassword(email, otp, password);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      hasCompletedStartupCheck: true,
      clearUser: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> getMe() async {
    final previousUser = state.user;

    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _userService.getMe();
    if (response.isLeft) {
      final failure = response.left;
      if (failure.statusCode == 401 || failure.statusCode == 403) {
        await logout();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasCompletedStartupCheck: true,
          error: failure.message,
          clearFieldErrors: true,
          clearFailureMetadata: true,
        );
        return;
      }

      state = state.copyWith(
        status: previousUser != null
            ? AuthStatus.authenticated
            : AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    final user = response.right;
    await _persistUser(user);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      hasCompletedStartupCheck: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> updateProfile(ProfileUpdateModel profile) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _userService.updateProfile(profile);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    final user = response.right;
    await _persistUser(user);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      hasCompletedStartupCheck: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> updatePassword(PasswordUpdateModel passwordUpdate) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _userService.updatePassword(passwordUpdate);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      hasCompletedStartupCheck: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> uploadProfilePicture(File image) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );

    final response = await _userService.uploadProfilePicture(image);
    if (response.isLeft) {
      final failure = response.left;
      state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
        fieldErrors: failure.fieldErrors,
        statusCode: failure.statusCode,
        throttleSeconds: failure.throttleSeconds,
        hasCompletedStartupCheck: true,
      );
      return;
    }

    final user = response.right;
    await _persistUser(user);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      hasCompletedStartupCheck: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
  }

  Future<void> logout() async {
    _isPerformingStartupCheck = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _authService.logout();
    await _clearCachedUser();

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      hasCompletedStartupCheck: true,
      clearUser: true,
      clearError: true,
      clearFieldErrors: true,
      clearFailureMetadata: true,
    );
    _onLogout?.call();
  }

  Future<void> _persistUser(UserModel user) async {
    try {
      final serialized = jsonEncode(user.toJson());
      await _secureStorage.write(_userCacheKey, serialized);
    } catch (_) {}
  }

  Future<UserModel?> _readCachedUser() async {
    final raw = await _secureStorage.read(_userCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    try {
      await _secureStorage.delete(_userCacheKey);
    } catch (_) {}
  }

  Future<DateTime?> _readTokenExpiry() async {
    final expiresAtStr = await _secureStorage.read('tokenExpires');
    if (expiresAtStr == null || expiresAtStr.isEmpty) {
      return null;
    }

    // Try parsing as integer (Unix timestamp in seconds)
    final numeric = int.tryParse(expiresAtStr);
    if (numeric != null) {
      // Backend sends Unix timestamp in SECONDS
      // Convert to milliseconds for DateTime
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
    }

    // Fallback: try parsing as ISO 8601 string
    return DateTime.tryParse(expiresAtStr);
  }

  Future<void> _hydrateLegacyClients(String token) async {
    try {
      await HiveDataSource().updateAccessToken(token);
    } catch (_) {}
    try {
      await ApiConfig().setAccessToken(value: token);
    } catch (_) {}

    final refreshToken = await _secureStorage.read('refreshToken');
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await HiveDataSource().updateRefreshToken(refreshToken);
      } catch (_) {}
      try {
        await ApiConfig().setRefreshToken(refreshToken: refreshToken);
      } catch (_) {}
    }

    final expiryRaw = await _secureStorage.read('tokenExpires');
    if (expiryRaw != null && expiryRaw.isNotEmpty) {
      try {
        await HiveDataSource().setTokenExpiration(expiryRaw);
      } catch (_) {}
    }
  }

  /// Schedules a proactive token refresh 5 minutes before expiration
  /// This prevents visible session drops and improves UX
  Future<void> _scheduleTokenRefresh() async {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    _refreshTimer = null;

    try {
      final expiresAt = await _readTokenExpiry();
      if (expiresAt == null) {
        print('⚠️ Cannot schedule token refresh: no expiry time available');
        return;
      }

      // Schedule refresh 5 minutes before expiration
      final refreshAt = expiresAt.subtract(const Duration(minutes: 5));
      final delay = refreshAt.difference(DateTime.now());

      if (delay.isNegative) {
        // Token already expired or will expire in less than 5 minutes
        // It will be refreshed on the next API call via interceptor
        print(
          '⚠️ Token expires soon or already expired. Will refresh via interceptor.',
        );
        return;
      }

      print(
        '✅ Scheduled token refresh in ${delay.inMinutes} minutes (at $refreshAt)',
      );

      _refreshTimer = Timer(delay, () async {
        print('⏰ Proactive token refresh triggered');
        final result = await _authService.refreshToken();

        result.fold(
          (failure) {
            print('❌ Proactive token refresh failed: ${failure.message}');
            // Don't logout here - let the interceptor handle it on next API call
          },
          (tokens) {
            print('✅ Proactive token refresh succeeded');
            // Schedule the next refresh
            _scheduleTokenRefresh();
          },
        );
      });
    } catch (e) {
      print('❌ Error scheduling token refresh: $e');
    }
  }
}
