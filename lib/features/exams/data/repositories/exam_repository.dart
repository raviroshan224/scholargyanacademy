import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/services/remote_services/errors/failure.dart';
import '../models/exam_models.dart';
import '../services/exam_service.dart';

abstract class ExamRepository {
  Future<Either<Failure, ExamListResponse>> fetchExamList({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
  });

  Future<Either<Failure, ExamDetail>> fetchExamDetail({
    required String examId,
    CancelToken? cancelToken,
  });
}

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl(this._service);

  final ExamService _service;

  @override
  Future<Either<Failure, ExamListResponse>> fetchExamList({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) {
    return _service.getExamList(
      page: page,
      limit: limit,
      search: search,
      status: status,
      category: category,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<Either<Failure, ExamDetail>> fetchExamDetail({
    required String examId,
    CancelToken? cancelToken,
  }) {
    return _service.getExamDetail(examId: examId, cancelToken: cancelToken);
  }
}

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final service = ref.read(examServiceProvider);
  return ExamRepositoryImpl(service);
});
