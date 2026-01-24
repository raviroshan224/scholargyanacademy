import 'dart:developer';

import 'package:dio/dio.dart';

/// A structured error object to encapsulate API or connection failures
class Failure {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;
  final int? throttleSeconds;

  Failure({
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.throttleSeconds,
  });

  factory Failure.fromException(DioException e) {
    try {
      final response = e.response;
      final statusCode = response?.statusCode;
      final data = response?.data;

      // Log useful debug info if needed
      log('[Failure] DioException: $e');
      log('[Failure] StatusCode: $statusCode');
      log('[Failure] Response Data: $data');

      // No response = connection issue
      if (response == null) {
        return Failure(
          message: 'No internet connection',
          statusCode: e.error?.toString().contains('SocketException') ?? false
              ? 503
              : null,
        );
      }

      // 429: Throttled
      if (statusCode == 429) {
        String message = 'Too many requests, please try again later.';
        int? throttleSeconds;

        if (data is Map<String, dynamic> && data['detail'] != null) {
          final detail = data['detail'].toString();
          message = detail;
          final match = RegExp(r'(\d+)\s*seconds').firstMatch(detail);
          if (match != null) {
            throttleSeconds = int.tryParse(match.group(1) ?? '');
          }
        }

        return Failure(
          message: message,
          statusCode: statusCode,
          throttleSeconds: throttleSeconds,
        );
      }

      // 403: Forbidden
      if (statusCode == 403) {
        String errorMessage =
            'You do not have permission to perform this action.';
        if (data is Map<String, dynamic>) {
          if (data['detail'] != null) {
            errorMessage = data['detail'].toString();
          } else if (data['error'] != null) {
            errorMessage = data['error'].toString();
          }
        }
        return Failure(message: errorMessage, statusCode: statusCode);
      }

      // 404: Not Found
      if (statusCode == 404) {
        String errorMessage = 'Resource not found.';
        if (data is Map<String, dynamic> && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        }
        return Failure(message: errorMessage, statusCode: statusCode);
      }

      // 5xx: Server errors
      if (statusCode != null && statusCode >= 500) {
        String errorMessage =
            'A server error occurred. Please try again later.';
        if (data is Map<String, dynamic>) {
          if (data['detail'] != null) {
            errorMessage = data['detail'].toString();
          } else if (data['error'] != null) {
            errorMessage = data['error'].toString();
          }
        }
        return Failure(message: errorMessage, statusCode: statusCode);
      }

      // 413: Payload too large
      if (statusCode == 413) {
        return Failure(
          message:
              'Uploaded file is too large. Please select an image smaller than 5MB.',
          statusCode: statusCode,
        );
      }

      // Try to extract validation / field errors for 4xx responses
      if (data is Map<String, dynamic>) {
        final parsedFieldErrors = <String, List<String>>{};

        // Case A: data contains 'errors' key with structure {message:..., field:...}
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map<String, dynamic>) {
            // If errors is like {message: '...', field: 'mobileNumber'}
            if (errors.containsKey('message') && errors.containsKey('field')) {
              final field = errors['field']?.toString() ?? 'error';
              final msg = errors['message']?.toString() ?? '';
              if (msg.isNotEmpty) parsedFieldErrors[field] = [msg];
            } else {
              // If errors is a map of field -> messages (list or string)
              errors.forEach((k, v) {
                if (v is List) {
                  parsedFieldErrors[k] = v.map((e) => e.toString()).toList();
                } else if (v is String) {
                  parsedFieldErrors[k] = [v];
                } else if (v is Map && v['message'] != null) {
                  parsedFieldErrors[k] = [v['message'].toString()];
                }
              });
            }
          }
        }

        // Case B: top-level 'field' and 'message'
        if (parsedFieldErrors.isEmpty) {
          if (data.containsKey('field') && data.containsKey('message')) {
            final field = data['field']?.toString() ?? 'error';
            final msg = data['message']?.toString() ?? '';
            if (msg.isNotEmpty) parsedFieldErrors[field] = [msg];
          }
        }

        // Case C: standard DRF-like validation: field: ["msg"]
        if (parsedFieldErrors.isEmpty) {
          data.forEach((k, v) {
            if (v is List) {
              parsedFieldErrors[k] = v.map((e) => e.toString()).toList();
            } else if (v is String) {
              // don't treat generic 'detail' or 'message' as field errors
              final lower = k.toLowerCase();
              if (lower != 'detail' &&
                  lower != 'message' &&
                  lower != 'status') {
                parsedFieldErrors[k] = [v];
              }
            }
          });
        }

        if (parsedFieldErrors.isNotEmpty) {
          // Build a friendly message from the first field error
          final firstField = parsedFieldErrors.entries.first;
          final friendly = firstField.value.isNotEmpty
              ? firstField.value.first
              : 'Validation failed';
          return Failure(
            message: friendly,
            statusCode: statusCode,
            fieldErrors: parsedFieldErrors,
          );
        }
      }

      // Generic fallback
      String message = e.message ?? 'An unknown error occurred';
      if (data != null && data.toString().isNotEmpty) {
        message += ' - ${data.toString()}';
      }

      return Failure(message: message, statusCode: statusCode);
    } catch (ex, stackTrace) {
      log('[Failure] Exception in parsing error: $ex');
      log('[Failure] Stacktrace: $stackTrace');
      return Failure(
        message: 'An unexpected error occurred while handling error.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  static Map<String, List<String>> _parseFieldErrors(
    Map<String, dynamic> response,
  ) {
    final fieldErrors = <String, List<String>>{};
    response.forEach((key, value) {
      if (value is List) {
        fieldErrors[key] = value.map((e) => e.toString()).toList();
      }
    });
    return fieldErrors;
  }

  @override
  String toString() {
    return 'Failure(message: $message, statusCode: $statusCode, throttleSeconds: $throttleSeconds, fieldErrors: $fieldErrors)';
  }
}
