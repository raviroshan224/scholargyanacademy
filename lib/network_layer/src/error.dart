// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';

//TODO: Must be extending error class and also stackTrace should be available

class ApiFailure extends Error {
  int code; // 200, 201, 400, 303..500 and so on
  String message; // error , success

  ApiFailure(this.code, this.message);
  @override

  /// Returns a string that describes this ApiFailure.
  ///
  /// The returned string is of the form:
  /// ApiFailure(code: $code, message: $message)
  ///
  /// This string is used when calling [toString] on this object.
  String toString() {
    return 'ApiFailure(code: $code, message: $message)';
  }
}

class ServerError extends Error {
  final int? statusCode;
  final DioExceptionType? dioErrorType;
  final String? message;
  final String? dioErrorMessage;
  Response<dynamic>? errorData;
  dynamic errorMessages; //TODO: Must be List<String>

  ServerError(this.statusCode,
      {this.dioErrorType,
      this.message,
      this.errorData,
      this.dioErrorMessage,
      this.errorMessages});

  @override

  /// Returns a string that contains a meaningful error message.
  ///
  /// It will take the following format:
  ///
  /// * If [message] and [statusCode] are not null:
  ///   `$message. Code($statusCode)`
  /// * If [message] and [dioErrorType] are not null:
  ///   - If [dioErrorType] is [DioExceptionType.connectionTimeout]:
  ///     `Check your internet connection`
  ///   - Otherwise: `$message. Type($dioErrorTypeStr)`
  /// * If [message] is not null:
  ///   `$message. HTTP($statusCode)`
  /// * Otherwise: `Something went wrong! Error($statusCode)}`
  String toString() {
    if (message != null && statusCode != null) {
      return '$message. Code($statusCode)';
    } else if (message != null && dioErrorType != null) {
      if (dioErrorType == DioExceptionType.connectionTimeout) {
        return 'Check your internet connection';
      }
      String dioErrorTypeStr = getDioErrorType();
      return '$message. Type($dioErrorTypeStr)';
    } else if (message != null) {
      return '$message. HTTP($statusCode)';
    }
    return 'Something went wrong! Error($statusCode})';
  }

  /// Returns a string representation of the [dioErrorType].
  ///
  /// Splits the [dioErrorType] by '.' and returns the last part,
  /// which represents the specific error type as a string.

  String getDioErrorType() {
    return dioErrorType.toString().split(".").last;
  }
}
