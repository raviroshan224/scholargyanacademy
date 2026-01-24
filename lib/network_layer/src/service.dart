import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:scholarsgyanacademy/network_layer/src/error_handler.dart';

import 'api_config.dart';
import 'enum.dart';
import 'error.dart';
import 'middleware.dart';

enum HttpMethod { get, post, put, patch, delete }

enum DataRequestMethod { GET, POST, PUT, PATCH, DELETE }

typedef ResponseSerializer = dynamic Function(Map<String, dynamic> json);

class ApiLayer {
  static String _generateCacheKey(
    String url,
    Map<String, String>? queryParams,
    Map<String, dynamic>? postData,
    String lang,
  ) {
    final base = {
      "url": url,
      "query": queryParams ?? {},
      "post": postData ?? {},
      "lang": lang,
    };
    return base.toString().hashCode.toString();
  }

  /// Sends an HTTP request using the specified method and returns the response.
  ///
  /// [requestUrl] is the URL endpoint to which the request is sent.
  ///
  /// [method] specifies the HTTP method to be used (GET, POST, PUT, PATCH, DELETE).
  ///
  /// [responseSerializer] is a function that converts the JSON response into the desired object.
  ///
  /// Optional named parameters:
  /// - [queryParams]: Map of query parameters to include in the request.
  /// - [postData]: Map of data to be sent in the request body for POST, PUT, PATCH, or DELETE methods.
  /// - [enableCache]: If true, enables caching of the response.
  /// - [authority]: Optional authority (base URL) to override the default.
  /// - [isForm]: If true, sends the request body as `application/x-www-form-urlencoded`.
  /// - [returnRaw]: If true, returns the raw response data and status code.
  ///
  /// Throws a [ServerError] if the request fails with a server error.
  /// Throws an [ApiFailure] if the request fails due to other types of errors.
  ///
  /// Returns the deserialized response object if successful.

  static Future sendRequest(
    String requestUrl,
    DataRequestMethod method,
    ResponseSerializer responseSerializer, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? postData,
    bool enableCache = false,
    String? authority,
    bool isForm = false,
    VoidCallback? onCacheLoad,
    Duration? ttl = const Duration(hours: 5),
    bool returnRaw = false,
  }) async {
    final HttpMiddleware httpMiddleware = HttpMiddleware(
      enableCache: enableCache,
    );
    Response? httpResponse;
    //postData ={
    //  "image": await MultipartFile.fromFile(selectedImagePath!.path,
    //               filename: "File${DateTime.now()}.jpeg"),
    // }

    // "eng" or "np"
    var encodedBody = postData != null
        ? isForm == false
              ? json.encode(postData)
              : FormData.fromMap(postData)
        : null;

    authority ??= ApiConfig().getApiAuthority();
    // logger.d(authority);
    // final cacheKey =
    //     _generateCacheKey(requestUrl, queryParams, postData, langCode);
    bool isConnected = await InternetConnection().hasInternetAccess;

    // if (!isConnected && enableCache) {
    //   final cachedData = CacheManager.instance.get(cacheKey);
    //   if (cachedData != null) {
    //     logger.d('Returning cached data for $requestUrl');
    //     onCacheLoad?.call();
    //     return responseSerializer(jsonDecode(cachedData));
    //   } else {
    //     throw Exception('No internet connection and no cached data available');
    //   }
    // }

    try {
      final Dio http = await httpMiddleware.getHttpClient(authority);
      // http.options.headers["Access-Control-Allow-Origin"] = "*";
      // http.options.headers["Access-Control-Allow-Methods"] =
      //     "GET, POST, OPTIONS";
      // http.options.headers["Access-Control-Allow-Headers"] =
      //         "Content-Type, Authorization";
      //         http.options.headers['Device-Info'] = await getDeviceInfo();
      // http.options.headers['Origin'] =
      // Platform.isAndroid ? "Android" : "IOS";

      switch (method) {
        case DataRequestMethod.GET:
          httpResponse = await http.get(
            requestUrl,
            queryParameters: queryParams,
          );
          break;

        case DataRequestMethod.POST:
          httpResponse = await http.post(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case DataRequestMethod.PUT:
          httpResponse = await http.put(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case DataRequestMethod.PATCH:
          httpResponse = await http.patch(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case DataRequestMethod.DELETE:
          httpResponse = await http.delete(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;
      }

      if (httpResponse.data != null) {
        bool isJson =
            (httpResponse.headers['content-type'] != null) &&
            httpResponse.headers['content-type']!.contains('application/json');

        final int? httpStatusCode = httpResponse.statusCode;
        final responseJson = httpResponse.data;
        logger.d("$authority$requestUrl");
        logger.d("$responseJson");
        if (returnRaw) {
          return {
            'responseJson': responseJson,
            'httpStatusCode': httpStatusCode,
          };
        } else {
          if ((httpStatusCode! ~/ 100 == 2) || (httpStatusCode ~/ 100 == 3)) {
            if (responseJson['statusCode'] ~/ 100 != 2) {
              dynamic message = responseJson['message'];
              throw ServerError(
                responseJson['statusCode'],
                message: message,
                errorMessages: message,
              );
            }

            if (responseJson is Map<String, dynamic>) {
              // if (enableCache) {
              //   // Set custom TTL (e.g., 30 minutes)
              //
              //   CacheManager.instance
              //       .put(cacheKey, jsonEncode(responseJson), ttl!);
              // }

              return Isolate.run(() => responseSerializer(responseJson));
              // return responseSerializer(responseJson);
            } else {
              Map<String, dynamic> response = {
                'data': responseJson,
                'success': httpResponse.statusMessage ?? 'Ok',
                'statusCode': httpResponse.statusCode,
                'statusMessage': httpResponse.statusMessage,
                'message': httpResponse.statusMessage ?? 'Ok',
              };
              // if (enableCache) {
              //   // Set custom TTL (e.g., 30 minutes)
              //
              //   CacheManager.instance
              //       .put(cacheKey, jsonEncode(responseJson), ttl!);
              // }
              final responseObject = responseSerializer(response);

              return responseObject;
            }
          }
        }
      }
    } on DioException catch (error) {
      if (error is ServerError) {
        return error;
      }
      if (error.response != null) {
        logger.e(error.message);
        ServerError serverError = ServerError(
          error.response!.statusCode,
          dioErrorMessage: error.message,
          message: error.response?.data['message'] == null
              ? 'Check ErrorData plz'
              : error.response?.data['message'] ?? 'Check ErrorData plz',
          dioErrorType: error.type,
          errorData: error.response,
        );
        throw serverError;
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        logger.e(error);
        ApiFailure failure = _handleError(error);
        logger.e('${failure.message} ${failure.code}');
        logger.e(failure.toString());

        throw failure;
      }
    }
  }
}

// Handles different types of Dio exceptions and throws corresponding ApiFailure.
/// Handles Dio exceptions by mapping them to corresponding ApiFailure objects.
///
/// Depending on the type of DioException, this function throws or returns an
/// ApiFailure with an appropriate error code and message. The mapping is as follows:
///
/// - `DioExceptionType.connectionTimeout`: Throws a failure for connection timeout.
/// - `DioExceptionType.sendTimeout`: Throws a failure for send timeout.
/// - `DioExceptionType.receiveTimeout`: Throws a failure for receive timeout.
/// - `DioExceptionType.badResponse`: Returns a failure with the status code and
///   message from the response, if available. Otherwise, throws a default failure.
/// - `DioExceptionType.cancel`: Throws a failure for a cancelled request.
/// - `DioExceptionType.connectionError`: Throws a failure for no internet connection.
/// - Other types: Throws a default failure.
///
/// This function ensures that all Dio exceptions are appropriately handled and
/// translated into ApiFailure objects, facilitating error management throughout the network layer.

ApiFailure _handleError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      throw DataSource.CONNECT_TIMEOUT.getFailure();
    case DioExceptionType.sendTimeout:
      throw DataSource.SEND_TIMEOUT.getFailure();
    case DioExceptionType.receiveTimeout:
      throw DataSource.RECIEVE_TIMEOUT.getFailure();
    case DioExceptionType.badResponse:
      if (error.response != null &&
          error.response?.statusCode != null &&
          error.response?.statusMessage != null) {
        return ApiFailure(
          error.response?.statusCode ?? 0,
          error.response?.statusMessage ?? "",
        );
      } else {
        throw DataSource.DEFAULT.getFailure();
      }
    case DioExceptionType.cancel:
      throw DataSource.CANCEL.getFailure();
    case DioExceptionType.connectionError:
      throw DataSource.NO_INTERNET_CONNECTION.getFailure();
    default:
      throw DataSource.DEFAULT.getFailure();
  }
}
