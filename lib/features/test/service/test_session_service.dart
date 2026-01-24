import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../models/test_session_models.dart';

abstract class TestSessionService {
  Future<Either<Failure, TestSession>> startSession(String mockTestId);
  Future<Either<Failure, TestSession>> getSession(String sessionId);
  Future<Either<Failure, TestQuestion>> getQuestion(
    String sessionId,
    int questionIndex,
  );
  Future<Either<Failure, AnswerState?>> submitAnswer(
    String sessionId,
    AnswerSubmitRequest request,
  );
  Future<Either<Failure, AnswerState?>> toggleReview(
    String sessionId,
    MarkReviewRequest request,
  );
  Future<Either<Failure, TestQuestion?>> navigate(
    String sessionId,
    NavigateRequest request,
  );
  Future<Either<Failure, TestSummary>> getSummary(String sessionId);
  Future<Either<Failure, TestResult>> submitTest(String sessionId);
  Future<Either<Failure, TestResult>> getResult(String sessionId);
  Future<Either<Failure, List<TestSolution>>> getSolutions(String sessionId);
  Future<Either<Failure, List<TestHistoryItem>>> getHistory({
    String? courseId,
  });
}

class TestSessionServiceImpl implements TestSessionService {
  TestSessionServiceImpl(this._httpService);

  final HttpService _httpService;

  @override
  Future<Either<Failure, TestSession>> startSession(String mockTestId) async {
    final response = await _httpService.post(
      ApiEndPoints.testSessionsStart,
      requiresAuth: true,
      data: {'mockTestId': mockTestId},
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestSession.fromJson(data));
        }
        return Left(
          Failure(message: 'Unexpected start session response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, TestSession>> getSession(String sessionId) async {
    final response = await _httpService.get(
      '${ApiEndPoints.testSessions}/$sessionId',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestSession.fromJson(data));
        }
        return Left(
          Failure(message: 'Unexpected test session response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, TestQuestion>> getQuestion(
    String sessionId,
    int questionIndex,
  ) async {
    final response = await _httpService.get(
      '${ApiEndPoints.testSessions}/$sessionId/question/$questionIndex',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestQuestion.fromJson(data));
        }
        return Left(
          Failure(message: 'Unexpected test question response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, AnswerState?>> submitAnswer(
    String sessionId,
    AnswerSubmitRequest request,
  ) async {
    final response = await _httpService.patch(
      '${ApiEndPoints.testSessions}/$sessionId/answer',
      requiresAuth: true,
      data: request.toJson(),
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(AnswerState.fromJson(data));
        }
        final fallback = _asMap(success.data);
        if (fallback != null) {
          return Right(AnswerState.fromJson(fallback));
        }
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, AnswerState?>> toggleReview(
    String sessionId,
    MarkReviewRequest request,
  ) async {
    final response = await _httpService.patch(
      '${ApiEndPoints.testSessions}/$sessionId/mark-review',
      requiresAuth: true,
      data: request.toJson(),
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(AnswerState.fromJson(data));
        }
        final fallback = _asMap(success.data);
        if (fallback != null) {
          return Right(AnswerState.fromJson(fallback));
        }
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, TestQuestion?>> navigate(
    String sessionId,
    NavigateRequest request,
  ) async {
    final response = await _httpService.patch(
      '${ApiEndPoints.testSessions}/$sessionId/navigate',
      requiresAuth: true,
      data: request.toJson(),
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestQuestion.fromJson(data));
        }
        final fallback = _asMap(success.data);
        if (fallback != null) {
          return Right(TestQuestion.fromJson(fallback));
        }
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, TestSummary>> getSummary(String sessionId) async {
    final response = await _httpService.get(
      '${ApiEndPoints.testSessions}/$sessionId/summary',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestSummary.fromJson(data));
        }
        return Left(
          Failure(message: 'Unexpected summary response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, TestResult>> submitTest(String sessionId) async {
    final response = await _httpService.post(
      '${ApiEndPoints.testSessions}/$sessionId/submit',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestResult.fromJson(data));
        }
        return Left(
          Failure(message: 'Unexpected submit test response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, TestResult>> getResult(String sessionId) async {
    final response = await _httpService.get(
      '${ApiEndPoints.testSessions}/$sessionId/result',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final data = _asMap(_unwrapData(success.data));
        if (data != null) {
          return Right(TestResult.fromJson(data));
        }
        return Left(
          Failure(message: 'Unexpected result response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<TestSolution>>> getSolutions(
    String sessionId,
  ) async {
    final response = await _httpService.get(
      '${ApiEndPoints.testSessions}/$sessionId/solutions',
      requiresAuth: true,
    );

    return response.fold(
      Left.new,
      (success) {
        final raw = _unwrapData(success.data);
        final list = _asList(raw);
        if (list != null) {
          final solutions = list
              .map((item) => _asMap(item))
              .whereType<Map<String, dynamic>>()
              .map(TestSolution.fromJson)
              .toList();
          return Right(solutions);
        }
        final map = _asMap(raw);
        if (map != null && map['items'] is List) {
          final items = (map['items'] as List)
              .map((item) => _asMap(item))
              .whereType<Map<String, dynamic>>()
              .map(TestSolution.fromJson)
              .toList();
          return Right(items);
        }
        return Left(
          Failure(message: 'Unexpected solutions response format'),
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<TestHistoryItem>>> getHistory({
    String? courseId,
  }) async {
    final queryParams = courseId != null ? {'courseId': courseId} : null;
    
    final response = await _httpService.get(
      ApiEndPoints.testSessionsHistoryMe,
      requiresAuth: true,
      queryParameters: queryParams,
    );

    return response.fold(
      Left.new,
      (success) {
        final raw = _unwrapData(success.data);
        final list = _asList(raw) ?? _asList(raw is Map ? raw['data'] : null);
        if (list != null) {
          final history = list
              .map((item) => _asMap(item))
              .whereType<Map<String, dynamic>>()
              .map(TestHistoryItem.fromJson)
              .toList();
          return Right(history);
        }
        return Left(
          Failure(message: 'Unexpected history response format'),
        );
      },
    );
  }
}

final testSessionServiceProvider = Provider<TestSessionService>((ref) {
  final http = ref.read(httpServiceProvider);
  return TestSessionServiceImpl(http);
});

dynamic _unwrapData(dynamic data) {
  if (data is Map) {
    if (data.containsKey('data')) {
      return data['data'];
    }
    if (data.containsKey('result')) {
      return data['result'];
    }
  }
  return data;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return null;
}
