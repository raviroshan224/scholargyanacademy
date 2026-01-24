import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../models/exam_models.dart';

abstract class ExamService {
  Future<Either<Failure, ExamListResponse>> getExams({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
  });

  Future<Either<Failure, ExamDetail>> getExamDetails(String examId);
}

class ExamServiceImpl implements ExamService {
  ExamServiceImpl(this._httpService);

  final HttpService _httpService;

  @override
  Future<Either<Failure, ExamListResponse>> getExams({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) async {
    final params = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (sortBy != null && sortBy.trim().isNotEmpty) 'sortBy': sortBy.trim(),
      if (sortOrder != null && sortOrder.trim().isNotEmpty)
        'sortOrder': sortOrder.trim(),
    };

    final response = await _httpService.get(
      ApiEndPoints.exams,
      queryParameters: params.isEmpty ? null : params,
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = success.data;
        if (data is Map<String, dynamic>) {
          return Right(ExamListResponse.fromJson(data));
        }
        if (data is Map) {
          return Right(
            ExamListResponse.fromJson(Map<String, dynamic>.from(data)),
          );
        }
        return Left(
          Failure(message: 'Unexpected exams response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, ExamDetail>> getExamDetails(String examId) async {
    final response = await _httpService.get(
      '${ApiEndPoints.exams}/$examId',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = success.data;
        if (data is Map<String, dynamic>) {
          return Right(ExamDetail.fromJson(data['data'] is Map
              ? Map<String, dynamic>.from(data['data'] as Map)
              : data));
        }
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final detailData = map['data'];
          if (detailData is Map<String, dynamic>) {
            return Right(ExamDetail.fromJson(detailData));
          }
          if (detailData is Map) {
            return Right(
              ExamDetail.fromJson(Map<String, dynamic>.from(detailData)),
            );
          }
          return Right(ExamDetail.fromJson(map));
        }
        return Left(
          Failure(message: 'Unexpected exam detail response format'),
        );
      },
    );
  }
}

final examServiceProvider = Provider<ExamService>((ref) {
  final http = ref.read(httpServiceProvider);
  return ExamServiceImpl(http);
});
