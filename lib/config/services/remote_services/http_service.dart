import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';

import 'errors/failure.dart';

/// Http Service Interface
abstract class HttpService {
  /// Http base url
  String get baseUrl;

  /// Http get request
  ///
  /// Makes a GET request to the specified [endpoint].
  ///
  /// [queryParameters] - Optional query parameters.
  /// [cancelToken] - Optional token to cancel the request.
  ///
  /// Returns an [Either] containing [Failure] on the left or [Response] on the right.
  Future<Either<Failure, Response<dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool? requiresAuth,
  });

  /// Http post request
  ///
  /// Makes a POST request to the specified [endpoint].
  ///
  /// [queryParameters] - Optional query parameters.
  /// [cancelToken] - Optional token to cancel the request.
  /// [formData] - Optional form data for the request.
  /// [onSendProgress] - Optional callback for tracking upload progress.
  /// [requiresAuth] - Optional flag indicating if the request requires authentication.
  /// [contentType] - Optional content type for the request.
  ///
  /// Returns an [Either] containing [Failure] on the left or [Response] on the right.
  Future<Either<Failure, Response<dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    FormData? formData,
    ProgressCallback? onSendProgress,
    bool? requiresAuth,
    String contentType,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
  });

  /// Http patch request
  ///
  /// Makes a PATCH request to the specified [endpoint].
  ///
  /// [queryParameters] - Optional query parameters.
  /// [cancelToken] - Optional token to cancel the request.
  /// [formData] - Optional form data for the request.
  /// [onSendProgress] - Optional callback for tracking upload progress.
  /// [requiresAuth] - Optional flag indicating if the request requires authentication.
  /// [contentType] - Optional content type for the request.
  ///
  /// Returns an [Either] containing [Failure] on the left or [Response] on the right.
  Future<Either<Failure, Response<dynamic>>> patch(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    FormData? formData,
    ProgressCallback? onSendProgress,
    bool? requiresAuth,
    String contentType,
  });

  /// Http put request
  ///
  /// Makes a PUT request to the specified [endpoint].
  ///
  /// [queryParameters] - Optional query parameters.
  /// [cancelToken] - Optional token to cancel the request.
  /// [formData] - Optional form data for the request.
  /// [onSendProgress] - Optional callback for tracking upload progress.
  /// [requiresAuth] - Optional flag indicating if the request requires authentication.
  /// [contentType] - Optional content type for the request.
  ///
  /// Returns an [Either] containing [Failure] on the left or [Response] on the right.
  Future<Either<Failure, Response<dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    FormData? formData,
    ProgressCallback? onSendProgress,
    bool? requiresAuth,
    String contentType,
  });

  /// Http delete request
  ///
  /// Makes a DELETE request to the specified [endpoint].
  ///
  /// [cancelToken] - Optional token to cancel the request.
  ///
  /// Returns an [Either] containing [Failure] on the left or [Response] on the right.
  Future<Either<Failure, Response<dynamic>>> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool? requiresAuth,
  });
}
