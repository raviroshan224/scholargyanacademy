import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints.dart';
import 'errors/failure.dart';
import 'http_service.dart';
import 'interceptors/api_interceptor.dart';

/// HttpServiceImpl class implements the HttpService interface
class HttpServiceImpl implements HttpService {
  late final Dio dio;
  final Ref ref;

  /// Constructor for HttpServiceImpl
  HttpServiceImpl(this.ref) {
    dio = Dio(baseOptions);
    dio.interceptors.add(NetworkInterceptor(ref));
  }

  /// Base URL getter
  @override
  String get baseUrl => ApiEndPoints.baseUrl;

  // Provider for generating dynamic headers
  final dynamicHeadersProvider = Provider<Map<String, String>>((Ref ref) {
    // final language = ref.watch(languageProvider);

    return {
      'accept': 'application/json',
      'content-type': 'application/json',
      'x-custom-lang': 'en',
      // 'Accept-Language': language,
    };
  });

  /// Dynamic headers with user location information
  Map<String, String> get dynamicHeaders => ref.read(dynamicHeadersProvider);

  /// Base options for Dio configuration
  BaseOptions get baseOptions => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 8),
      );

  /// Method to create Dio options
  Options _createOptions(
      {bool? requiresAuth, String contentType = 'application/json'}) {
    final headers = Map<String, String>.from(dynamicHeaders);
    headers['Content-Type'] = contentType;
    return Options(
      headers: headers,
      extra: {'requiresAuth': requiresAuth},
    );
  }

  /// HTTP GET request method
  @override
  Future<Either<Failure, Response<dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? customBaseUrl,
    CancelToken? cancelToken,
    bool? requiresAuth = false,
  }) async {
    try {
      final Response<dynamic> response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: _createOptions(requiresAuth: requiresAuth),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  /// HTTP POST request method
  @override
  Future<Either<Failure, Response>> post(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    FormData? formData,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool? requiresAuth = false,
    String? contentType,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers, // Added headers param
  }) async {
    try {
      // Merge default headers with custom headers, ensuring all values are String
      final mergedHeaders = <String, String>{}
        ..addAll(dynamicHeaders)
        ..addAll((headers ?? {})
            .map((key, value) => MapEntry(key, value.toString())));
      if (contentType != null) {
        mergedHeaders['Content-Type'] = contentType;
      }
      // Log the outgoing POST request for debugging (endpoint, headers, body)
      try {
        final body =
            formData != null ? formData.toString() : jsonEncode(data ?? {});
        debugPrint('HTTP POST -> $endpoint');
        debugPrint('Headers: $mergedHeaders');
        debugPrint('Body: $body');
      } catch (e) {
        debugPrint('Failed to encode POST body for $endpoint: $e');
      }
      final Response<dynamic> response = await dio.post(
        endpoint,
        data: formData ?? data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(
            headers: mergedHeaders, extra: {'requiresAuth': requiresAuth}),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  /// HTTP DELETE request method
  @override
  Future<Either<Failure, Response<dynamic>>> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool? requiresAuth,
  }) async {
    try {
      final Response<dynamic> response = await dio.delete(
        endpoint,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: _createOptions(requiresAuth: requiresAuth),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  /// HTTP PATCH request method
  @override
  Future<Either<Failure, Response>> patch(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    FormData? formData,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool? requiresAuth = false,
    String? contentType,
  }) async {
    try {
      final Response<dynamic> response = await dio.patch(
        endpoint,
        cancelToken: cancelToken,
        data: formData ?? data,
        // queryParameters: queryParameters,
        options: _createOptions(
          requiresAuth: requiresAuth,
          contentType:
              formData != null ? 'multipart/form-data' : 'application/json',
        ),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Response>> put(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    FormData? formData,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool? requiresAuth = false,
    String? contentType,
  }) async {
    try {
      final Response<dynamic> response = await dio.put(
        endpoint,
        cancelToken: cancelToken,
        data: formData ?? data,
        queryParameters: queryParameters,
        options: _createOptions(
          requiresAuth: requiresAuth,
          contentType:
              formData != null ? 'multipart/form-data' : 'application/json',
        ),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
