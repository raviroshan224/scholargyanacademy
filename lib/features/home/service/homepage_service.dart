import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../models/homepage_models.dart';

abstract class HomepageService {
  Future<Either<Failure, HomepageResponse>> fetchHomepage();
  Future<Either<Failure, UpdateCategoryResponse>> updateLatestCategory(
    UpdateCategoryRequest request,
  );
}

class HomepageServiceImpl implements HomepageService {
  HomepageServiceImpl(this._httpService);

  final HttpService _httpService;

  @override
  Future<Either<Failure, HomepageResponse>> fetchHomepage() async {
    final response =
        await _httpService.get(ApiEndPoints.homepage, requiresAuth: true);
    // Debug logs: print request/response details for troubleshooting
    try {
      // best-effort base url if exposed by the http service implementation
      final base = ((_httpService as dynamic).baseUrl ?? '');
      print('[log] ✅ Request [GET] $base${ApiEndPoints.homepage}');
    } catch (_) {}
    return response.fold(
      Left.new,
      (success) {
        final data = success.data;
        try {
          // final uri = success.requestOptions.uri;
          // final status = success.statusCode;
          // final headersMap = success.headers.map;
          // print('[log] ✅ Response [${status}] ${uri.toString()}');
        } catch (_) {}
        if (data is Map<String, dynamic>) {
          return Right(HomepageResponse.fromJson(data));
        }
        if (data is Map) {
          return Right(
            HomepageResponse.fromJson(Map<String, dynamic>.from(data)),
          );
        }
        return Left(
          Failure(message: 'Unexpected homepage response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, UpdateCategoryResponse>> updateLatestCategory(
    UpdateCategoryRequest request,
  ) async {
    final response = await _httpService.put(
      ApiEndPoints.homepageLatestCategory,
      requiresAuth: true,
      data: request.toJson(),
    );
    return response.fold(
      Left.new,
      (success) {
        final data = success.data;
        if (data is Map<String, dynamic>) {
          return Right(UpdateCategoryResponse.fromJson(data));
        }
        if (data is Map) {
          return Right(
            UpdateCategoryResponse.fromJson(
              Map<String, dynamic>.from(data),
            ),
          );
        }
        return Left(
          Failure(message: 'Unexpected update category response format'),
        );
      },
    );
  }
}

final homepageServiceProvider = Provider<HomepageService>((ref) {
  final http = ref.read(httpServiceProvider);
  return HomepageServiceImpl(http);
});
