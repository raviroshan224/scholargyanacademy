import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../models/search_models.dart';

/// Service for handling homepage search API calls.
abstract class HomeSearchService {
  /// Search for courses and mock tests.
  ///
  /// [query] - Search keyword (required, min 2 characters recommended)
  /// [limit] - Max results per type (default: 10)
  /// [cancelToken] - Optional token to cancel pending requests
  Future<Either<Failure, HomeSearchResponse>> search({
    required String query,
    int limit = 10,
    CancelToken? cancelToken,
  });
}

class HomeSearchServiceImpl implements HomeSearchService {
  HomeSearchServiceImpl(this._httpService);

  final HttpService _httpService;

  @override
  Future<Either<Failure, HomeSearchResponse>> search({
    required String query,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    final response = await _httpService.get(
      ApiEndPoints.homepageSearch,
      queryParameters: {
        'search': query,
        'limit': limit,
      },
      cancelToken: cancelToken,
      // Note: requiresAuth is optional - the HTTP service will attach
      // auth token if available, allowing personalized ranking
      requiresAuth: false,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = success.data;

        if (data is Map<String, dynamic>) {
          return Right(HomeSearchResponse.fromJson(data));
        }
        if (data is Map) {
          return Right(
            HomeSearchResponse.fromJson(Map<String, dynamic>.from(data)),
          );
        }
        return Left(
          Failure(message: 'Unexpected search response format'),
        );
      },
    );
  }
}

final homeSearchServiceProvider = Provider<HomeSearchService>((ref) {
  final http = ref.read(httpServiceProvider);
  return HomeSearchServiceImpl(http);
});
