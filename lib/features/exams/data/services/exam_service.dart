import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/services/remote_services/api_endpoints.dart';
import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../config/services/remote_services/http_service.dart';
import '../../../../config/services/remote_services/http_service_provider.dart';
import '../models/exam_models.dart';

abstract class ExamService {
  Future<Either<Failure, ExamListResponse>> getExamList({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
  });

  Future<Either<Failure, ExamDetail>> getExamDetail({
    required String examId,
    CancelToken? cancelToken,
  });
}

class ExamServiceImpl implements ExamService {
  ExamServiceImpl(this._httpService);

  final HttpService _httpService;

  @override
  Future<Either<Failure, ExamListResponse>> getExamList({
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
        final raw = success.data;
        if (raw is Map<String, dynamic>) {
          return Right(ExamListResponse.fromJson(raw));
        }
        if (raw is Map) {
          return Right(
            ExamListResponse.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
        return Left(
          Failure(message: 'Unexpected exam list response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, ExamDetail>> getExamDetail({
    required String examId,
    CancelToken? cancelToken,
  }) async {
    final response = await _httpService.get(
      '${ApiEndPoints.exams}/$examId',
      cancelToken: cancelToken,
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final raw = success.data;
        if (raw is Map<String, dynamic>) {
          final payload = raw['data'];
          if (payload is Map<String, dynamic>) {
            return Right(ExamDetail.fromJson(payload));
          }
          if (payload is Map) {
            return Right(
              ExamDetail.fromJson(Map<String, dynamic>.from(payload)),
            );
          }
          return Right(ExamDetail.fromJson(raw));
        }
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          final payload = map['data'];
          if (payload is Map<String, dynamic>) {
            return Right(ExamDetail.fromJson(payload));
          }
          if (payload is Map) {
            return Right(
              ExamDetail.fromJson(Map<String, dynamic>.from(payload)),
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
