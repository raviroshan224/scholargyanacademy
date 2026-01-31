import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../model/live_class_models.dart';

/// Service for Live Class operations
/// Handles API calls for live class details and join tokens
abstract class LiveClassService {
  /// Get live class detail by ID
  Future<Either<Failure, LiveClassModel>> getLiveClassDetail(String id);

  /// Get Zoom SDK join token from backend
  /// Backend generates JWT token and validates enrollment/timing
  Future<Either<Failure, LiveClassJoinToken>> getJoinToken(String id);

  /// Get user's live classes for a specific course
  /// Requires enrollment - backend validates eligibility
  /// Returns ongoing classes by default
  Future<Either<Failure, List<LiveClassModel>>> getMyClasses({
    String? courseId,
    String status = 'ongoing',
    int page = 1,
    int limit = 10,
  });
}

class LiveClassServiceImpl implements LiveClassService {
  final HttpService _http;

  LiveClassServiceImpl(this._http);

  @override
  Future<Either<Failure, LiveClassModel>> getLiveClassDetail(String id) async {
    final response = await _http.get(
      '${ApiEndPoints.liveClassesMyClasses}/$id',
      requiresAuth: true,
    );

    return response.fold(
      (failure) => Left(failure),
      (result) {
        try {
          final data = result.data;
          if (data is! Map) {
            return Left(Failure(message: 'Invalid live class data format'));
          }
          final liveClass = LiveClassModel.fromJson(
            Map<String, dynamic>.from(data),
          );
          return Right(liveClass);
        } catch (e) {
          return Left(Failure(message: 'Failed to parse live class details'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, LiveClassJoinToken>> getJoinToken(String id) async {
    // CRITICAL: Use correct endpoint from Swagger
    // ✅ Correct: POST /live-classes/{id}/join-token
    // ❌ Wrong: POST /live-classes/my-classes/{id}/join-token
    final response = await _http.post(
      'live-classes/$id/join-token',  // Fixed: removed /my-classes
      requiresAuth: true,
    );

    return response.fold(
      (failure) => Left(failure),
      (result) {
        try {
          final data = result.data;
          if (data is! Map) {
            return Left(Failure(message: 'Invalid join token response'));
          }
          final token = LiveClassJoinToken.fromJson(
            Map<String, dynamic>.from(data),
          );
          
          // Validate token is not empty
          if (token.token.isEmpty) {
            return Left(Failure(message: 'Invalid join token received'));
          }
          
          return Right(token);
        } catch (e) {
          return Left(Failure(message: 'Failed to parse join token'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<LiveClassModel>>> getMyClasses({
    String? courseId,
    String status = 'ongoing',
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {
      'status': status,
      'page': page,
      'limit': limit,
    };
    if (courseId != null) {
      queryParams['courseId'] = courseId;
    }

    final response = await _http.get(
      ApiEndPoints.liveClassesMyClasses,
      queryParameters: queryParams,
      requiresAuth: true,
    );

    return response.fold(
      (failure) => Left(failure),
      (result) {
        try {
          final data = result.data;
          
          // Handle both array and object responses
          List<dynamic> classesData;
          if (data is List) {
            classesData = data;
          } else if (data is Map && data['data'] is List) {
            classesData = data['data'] as List;
          } else if (data is Map && data['classes'] is List) {
            classesData = data['classes'] as List;
          } else {
            return Left(Failure(message: 'Invalid live classes response format'));
          }

          final classes = classesData
              .whereType<Map>()
              .map((item) => LiveClassModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList();

          return Right(classes);
        } catch (e) {
          return Left(Failure(message: 'Failed to parse live classes: $e'));
        }
      },
    );
  }
}

final liveClassServiceProvider = Provider<LiveClassService>((ref) {
  final http = ref.watch(httpServiceProvider);
  return LiveClassServiceImpl(http);
});
