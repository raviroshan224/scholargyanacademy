import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'api_config.dart';

var logger = Logger();
void initLogger() {
  if (kReleaseMode) {
    // Disable all logs in release mode
    logger = Logger(
      level: Level.off, // turns off all logging
    );
  } else {
    // Enable logging in debug/profile mode
    logger = Logger(
      printer: PrettyPrinter(), // or your preferred printer
      level: Level.debug, // log everything from debug and up
    );
  }
}

class HttpMiddleware {
  late Dio dio;
  late CacheOptions cacheOptions;
  late bool enableCache;
// 👈 add Alice
// Private constructor with parameters
  HttpMiddleware._privateConstructor({
    bool? enableCache = false,
  }) {
    this.enableCache = enableCache!;
    _initializeDio();
  }

// Factory constructor to create a singleton instance
  factory HttpMiddleware({
    bool enableCache = true,
  }) {
    return _instance ??=
        HttpMiddleware._privateConstructor(enableCache: enableCache);
  }

  static HttpMiddleware? _instance;

  // Initializes the Dio instance, sets up cache options if enabled, and adds interceptors for caching and logging.
  /// Initializes the Dio instance, sets up cache options if enabled, and adds
  /// interceptors for caching and logging.
  ///
  /// This method is used to initialize the Dio instance with the necessary
  /// interceptors and cache options. If caching is enabled, it sets up the
  /// cache options and adds interceptors for caching and logging. If caching
  /// is not enabled, it only adds the logging interceptor.
  void _initializeDio() async {
    dio = Dio();
  }

  // Function to get an instance of Dio HttpClient with specified configurations.
  /// Returns an instance of Dio HttpClient with specified configurations.
  ///
  /// The returned instance of Dio client is configured with the following:
  ///
  /// - The base URL is set to [baseUrl].
  /// - The connect timeout is set to 60 seconds.
  /// - The receive timeout is set to 60 seconds.
  /// - A interceptor is added to handle token based authentication.
  ///   - If the token is null, it rejects the request with a 404 error.
  ///   - If the token is not null, it adds the token to the 'Authorization' header of the request.
  /// - A interceptor is added to handle error responses.
  ///   - If the response status code is 401, it refreshes the access token and retries the request.
  ///   - If the response status code is not 401, it returns the error as is.
  Future<Dio> getHttpClient(
    baseUrl, {
    responseSerializer,
  }) async {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 60); //60s
    dio.options.receiveTimeout = const Duration(seconds: 60);

    dio.interceptors.add(QueuedInterceptorsWrapper(onRequest:
        (RequestOptions options, RequestInterceptorHandler handler) async {
      // Do something before request is sent
      // Do something before request is sent

      String requestUrl = options.baseUrl + options.path;
      logger.d(requestUrl);
      String? accessToken = await ApiConfig().getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      // if (tokenRequired) {
      //   if (accessToken == null) {
      //     return handler.reject(DioException(
      //         requestOptions: RequestOptions(
      //           path: options.path,
      //         ),
      //         type: DioExceptionType.unknown,
      //         error: ApiFailure(404, "Token is null"))); //continue
      //   } else {
      //     options.headers['Authorization'] = 'Bearer $accessToken';
      //   }
      // }
      return handler.next(options);
    }, onResponse:
        (Response<dynamic> response, ResponseInterceptorHandler handler) async {
      // Do something with response data

      return handler.next(response); // continue
    }, onError: (DioException error, ErrorInterceptorHandler handler) async {
      if (error.response?.statusCode == 401) {
        // Prevent infinite retry loops
        final alreadyRetried = error.requestOptions.extra['retried'] == true;
        if (alreadyRetried) {
          return handler.next(error);
        }

        // If a 401 response is received, attempt to refresh the access token
        String? oldRefreshToken = await ApiConfig().getRefreshToken();
        if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
          return handler.next(error);
        }

        try {
          // Use a plain Dio instance to call the refresh endpoint (avoid interceptors)
          final refreshDio = Dio(BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
          ));

          final refreshResp = await refreshDio.post(
            '/api/v1/auth/refresh',
            options:
                Options(headers: {'Authorization': 'Bearer $oldRefreshToken'}),
          );

          if (refreshResp.statusCode == 200 || refreshResp.statusCode == 201) {
            final data = refreshResp.data;
            logger.d('refresh response: $data');

            // Try several common keys for tokens
            String? newAccessToken;
            String? newRefreshToken;
            if (data is Map) {
              // Explicit mappings for expected response shape
              newAccessToken = data['accessToken'] ??
                  data['access_token'] ??
                  data['token'] ??
                  data['access'];
              newRefreshToken = data['refreshToken'] ??
                  data['refresh_token'] ??
                  data['refresh'];
              // Some APIs wrap payload inside `data` key
              if ((newAccessToken == null || newRefreshToken == null) &&
                  data['data'] is Map) {
                final nested = data['data'] as Map;
                newAccessToken = newAccessToken ??
                    nested['accessToken'] ??
                    nested['access_token'];
                newRefreshToken = newRefreshToken ??
                    nested['refreshToken'] ??
                    nested['refresh_token'];
              }
            }

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await ApiConfig().setAccessToken(value: newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await ApiConfig()
                    .setRefreshToken(refreshToken: newRefreshToken);
              }

              // Mark request as retried to avoid loops and retry original request
              error.requestOptions.extra['retried'] = true;

              // Update authorization header and retry original request
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';

              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );

              final retryResp = await dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: opts,
              );
              return handler.resolve(retryResp);
            }
          }
        } catch (e, st) {
          logger.d('refresh token failed', error: e, stackTrace: st);
          // Fall through to return the original error
        }
      }
      return handler.next(error);
    }));
    return dio;
  }
}
