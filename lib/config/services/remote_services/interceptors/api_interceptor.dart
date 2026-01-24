import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/config/services/navigation_service.dart';
import 'package:scholarsgyanacademy/features/auth/model/auth_models.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

import '../../secure_storage_provider.dart';
import '../api_endpoints.dart';
import '../navigation_service.dart';

class NetworkInterceptor extends Interceptor {
  final Ref ref;

  bool _isRefreshing = false;
  Completer<String>? _refreshCompleter;

  NetworkInterceptor(this.ref);

  // =========================
  // REQUEST
  // =========================
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _attachAuthHeader(options);

    log('➡️ REQUEST [${options.method}] ${options.uri}');
    log('➡️ HEADERS: ${options.headers}');

    handler.next(options);
  }

  // =========================
  // RESPONSE
  // =========================
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('✅ RESPONSE [${response.statusCode}] ${response.requestOptions.uri}');
    handler.next(response);
  }

  // =========================
  // ERROR (401 HANDLING)
  // =========================
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    log('❌ ERROR [$statusCode] ${err.requestOptions.uri}');

    if (statusCode != 401) {
      return handler.next(err);
    }

    // 1️⃣ Skip refresh if request explicitly does NOT require auth
    final requiresAuth = err.requestOptions.extra['requiresAuth'] ?? true;
    if (!requiresAuth) {
      return handler.reject(err);
    }

    // 1.5️⃣ Skip refresh if this is already a retry (prevent infinite loop)
    final isRetry = err.requestOptions.extra['_isRetry'] ?? false;
    if (isRetry) {
      log(
        '⚠️ Retry also got 401 → endpoint always returns 401 or token invalid',
      );
      return handler.reject(err);
    }

    // 2️⃣ Skip refresh if 401 happened immediately after login
    final loginTsStr = await ref
        .read(secureStorageServiceProvider)
        .read('loginTimestamp');

    if (loginTsStr != null) {
      final loginTs = DateTime.tryParse(loginTsStr);
      if (loginTs != null &&
          DateTime.now().difference(loginTs) < const Duration(seconds: 5)) {
        log('⚠️ 401 within 5s of login → skipping refresh');
        return handler.reject(err);
      }
    }

    try {
      // 3️⃣ Wait for a valid token (refresh if needed)
      final newToken = await _getValidAccessToken();

      // 4️⃣ Retry original request
      final response = await _retryRequest(err.requestOptions, newToken);

      log('🔁 RETRY SUCCESS [${response.statusCode}]');
      return handler.resolve(response);
    } catch (e) {
      log('❌ TOKEN REFRESH FAILED → LOGOUT');
      await _handleTokenRefreshFailure();
      return handler.reject(err);
    }
  }

  // =========================
  // ATTACH TOKEN
  // =========================
  Future<void> _attachAuthHeader(RequestOptions options) async {
    final requiresAuth = options.extra['requiresAuth'] ?? true;

    if (!requiresAuth) {
      options.headers.remove('Authorization');
      return;
    }

    final token = await ref.read(secureStorageServiceProvider).read('token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // =========================
  // TOKEN REFRESH QUEUE
  // =========================
  Future<String> _getValidAccessToken() async {
    if (_isRefreshing) {
      log('⏳ Waiting for ongoing refresh');
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String>();

    try {
      log('🔄 REFRESHING TOKEN');
      final newTokens = await _performTokenRefresh();
      _refreshCompleter!.complete(newTokens.token);
      return newTokens.token;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // =========================
  // REFRESH TOKEN API
  // =========================
  Future<AuthTokensModel> _performTokenRefresh() async {
    final refreshToken = await ref
        .read(secureStorageServiceProvider)
        .read('refreshToken');

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndPoints.baseUrl));
    refreshDio.options.headers['Authorization'] = 'Bearer $refreshToken';
    final response = await refreshDio.post(ApiEndPoints.refreshTokenUrl);

    final newTokens = AuthTokensModel.fromJson(response.data);

    final storage = ref.read(secureStorageServiceProvider);
    await storage.write('token', newTokens.token);
    await storage.write('refreshToken', newTokens.refreshToken);
    await storage.write('tokenExpires', newTokens.tokenExpires.toString());

    log('✅ TOKEN REFRESH SUCCESS');
    return newTokens;
  }

  // =========================
  // RETRY FAILED REQUEST
  // =========================
  Future<Response<dynamic>> _retryRequest(
    RequestOptions options,
    String newAccessToken,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: ApiEndPoints.baseUrl));

    final headers = Map<String, dynamic>.from(options.headers);
    headers['Authorization'] = 'Bearer $newAccessToken';

    // Mark as retry to prevent infinite refresh loop
    final extra = Map<String, dynamic>.from(options.extra);
    extra['_isRetry'] = true;

    return dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(method: options.method, headers: headers, extra: extra),
    );
  }

  // =========================
  // LOGOUT + NAVIGATION
  // =========================
  Future<void> _handleTokenRefreshFailure() async {
    log('🚪 LOGGING OUT USER');

    Future.microtask(() => ref.read(authNotifierProvider.notifier).logout());

    final navigationService = ref.read(navigationServiceProvider);

    navigationService.navigateToLogin(
      errorMessage: 'Session expired. Please login again.',
    );
  }
}
